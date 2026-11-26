#!/usr/bin/env python3
"""Lay out a Lean project and all its Lake dependencies from GitHub source tarballs.

`git clone` over HTTPS is slow and flaky from the build server, source tarballs are not. The
project is unpacked at the given commit; every git dependency in its lake-manifest.json is
unpacked at exactly the manifest revision into .lake/packages/<name>, committed there as a local
snapshot (with `origin` set to the manifest URL), and the manifest revision is replaced by the
snapshot commit, so Lake finds each package at the manifest revision and never fetches.
Sources are byte-identical to upstream at those revisions. The original manifest is kept as
lake-manifest.upstream.json; tarball checksums go to logs/sources-NAME.jsonl.

Usage: setup_project.py WORKSPACE NAME OWNER/REPO REV [SUBDIR]
  SUBDIR: the Lake project is a subdirectory of the repository (e.g. src/submission)
Result: WORKSPACE/work/NAME (the Lake project root). Python 3.8+.

Environment: TARBALL_BASE (default https://codeload.github.com) may point at a relay that
serves the same paths. Whatever the transport, every unpacked tree is accepted only if its git
tree hash equals the tree of that commit as reported by the GitHub API (queried directly);
answers are cached in logs/trees.json.
"""
import concurrent.futures
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tarfile
import time

WS, NAME, REPO, REV = sys.argv[1:5]
SUBDIR = sys.argv[5] if len(sys.argv) > 5 else ""
SRC = os.path.join(WS, "src")
ROOT = os.path.join(WS, "work", NAME)
LOG = os.path.join(WS, "logs", "sources-%s.jsonl" % NAME)
os.makedirs(SRC, exist_ok=True)
os.makedirs(os.path.dirname(LOG), exist_ok=True)
os.makedirs(os.path.join(WS, "work"), exist_ok=True)


def fetch(url, dest):
    if os.path.exists(dest):
        return
    for i in range(8):
        r = subprocess.run(["curl", "-sSfL", "--max-time", "3600", "-o", dest + ".part", url])
        if r.returncode == 0:
            os.replace(dest + ".part", dest)
            return
        time.sleep(10 * (i + 1))
    raise SystemExit("download failed: %s" % url)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for b in iter(lambda: fh.read(1 << 20), b""):
            h.update(b)
    return h.hexdigest()


def unpack(tgz, dest, subdir=""):
    tmp = dest + ".unpack"
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    with tarfile.open(tgz) as tf:
        tf.extractall(tmp)
    (top,) = os.listdir(tmp)
    shutil.rmtree(dest, ignore_errors=True)
    os.replace(os.path.join(tmp, top, subdir) if subdir else os.path.join(tmp, top), dest)
    shutil.rmtree(tmp, ignore_errors=True)


def git(cwd, *args):
    return subprocess.run(["git", "-c", "user.name=snapshot", "-c", "user.email=snapshot@localhost",
                           "-c", "init.defaultBranch=main", "-c", "core.autocrlf=false", *args], cwd=cwd,
                          check=True, capture_output=True, text=True).stdout.strip()


def owner_repo(url):
    u = url
    pre = "https://github.com/"
    if u.startswith(pre):
        u = u[len(pre):]
    return u[:-4] if u.endswith(".git") else u


BASE = os.environ.get("TARBALL_BASE", "https://codeload.github.com").rstrip("/")
TREES = os.path.join(WS, "logs", "trees.json")


def official_tree(repo, rev):
    cache = json.load(open(TREES)) if os.path.exists(TREES) else {}
    key = repo + "@" + rev
    if key not in cache:
        r = subprocess.run(["curl", "-sSf", "--max-time", "60", "https://api.github.com/repos/%s/commits/%s" % (repo, rev)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit("cannot read the official tree of %s: %s" % (key, r.stderr.strip()[:200]))
        cache[key] = json.loads(r.stdout)["commit"]["tree"]["sha"]
        json.dump(cache, open(TREES, "w"), indent=1)
    return cache[key]


def tree_of(directory):
    """Git tree hash of a directory's content (as `git add -A -f` would record it)."""
    gd = directory.rstrip("/") + ".treecheck.git"
    shutil.rmtree(gd, ignore_errors=True)
    env = dict(os.environ, GIT_DIR=gd, GIT_WORK_TREE=directory)
    run = lambda *a: subprocess.run(["git", "-c", "core.autocrlf=false", "-c", "core.fileMode=true", *a], env=env,
                                    check=True, capture_output=True, text=True).stdout.strip()
    run("init", "-q")
    run("add", "-A", "-f")
    t = run("write-tree")
    shutil.rmtree(gd, ignore_errors=True)
    return t


def blobs_of(directory):
    """path -> (mode, blob hash) of a directory's content, as git would record it."""
    gd = directory.rstrip("/") + ".treecheck.git"
    shutil.rmtree(gd, ignore_errors=True)
    env = dict(os.environ, GIT_DIR=gd, GIT_WORK_TREE=directory)
    run = lambda *a: subprocess.run(["git", "-c", "core.autocrlf=false", "-c", "core.fileMode=true", "-c",
                                     "core.quotePath=false", *a], env=env, check=True, capture_output=True,
                                    text=True).stdout
    run("init", "-q")
    run("add", "-A", "-f")
    out = {}
    for l in run("ls-tree", "-r", run("write-tree").strip()).splitlines():
        meta, path = l.split("\t", 1)
        mode, _, sha = meta.split()
        out[path] = (mode, sha)
    shutil.rmtree(gd, ignore_errors=True)
    return out


def verified_unpack(tgz, dest, repo, rev, subdir=""):
    full = dest + ".full" if subdir else dest
    unpack(tgz, full)
    got, want = tree_of(full), official_tree(repo, rev)
    if got != want:
        # A source archive omits submodule pointers (gitlinks). Compare file by file against the
        # official tree and accept only if every difference is a gitlink missing from the archive.
        r = subprocess.run(["curl", "-sSf", "--max-time", "120",
                            "https://api.github.com/repos/%s/git/trees/%s?recursive=1" % (repo, want)],
                           capture_output=True, text=True)
        if r.returncode != 0:
            raise SystemExit("TREE MISMATCH for %s@%s and the official listing is unreadable" % (repo, rev))
        listing = json.loads(r.stdout)
        if listing.get("truncated"):
            raise SystemExit("TREE MISMATCH for %s@%s (official listing truncated, cannot compare)" % (repo, rev))
        official = {e["path"]: (e["mode"], e["sha"]) for e in listing["tree"] if e["type"] != "tree"}
        mine = blobs_of(full)
        bad = [p for p in set(official) | set(mine)
               if official.get(p) != mine.get(p) and not (p in official and official[p][0] == "160000" and p not in mine)]
        if bad:
            raise SystemExit("TREE MISMATCH for %s@%s: %d differing paths, e.g. %s" % (repo, rev, len(bad), sorted(bad)[:3]))
        print("note: %s@%s matches the official tree except for %d submodule pointer(s)" % (
            repo, rev[:12], sum(1 for p in official if official[p][0] == "160000")))
    if subdir:
        shutil.rmtree(dest, ignore_errors=True)
        os.replace(os.path.join(full, subdir), dest)
        shutil.rmtree(full, ignore_errors=True)
    return got


log = open(LOG, "a")
tgz = os.path.join(SRC, "%s-%s.tar.gz" % (NAME, REV[:12]))
fetch("%s/%s/tar.gz/%s" % (BASE, REPO, REV), tgz)
if not os.path.exists(os.path.join(ROOT, "lake-manifest.json")):
    tree = verified_unpack(tgz, ROOT, REPO, REV, SUBDIR)
    log.write(json.dumps({"name": NAME, "repo": REPO, "rev": REV, "sha256": sha256(tgz), "tree": tree,
                          "tree_verified": True}) + "\n")

man_path = os.path.join(ROOT, "lake-manifest.json")
up_path = os.path.join(ROOT, "lake-manifest.upstream.json")
if not os.path.exists(up_path):
    shutil.copy(man_path, up_path)
man = json.load(open(up_path))
pkgs = [p for p in man["packages"] if p["type"] == "git"]


def get(p):
    t = os.path.join(SRC, "%s-%s.tar.gz" % (p["name"], p["rev"][:12]))
    fetch("%s/%s/tar.gz/%s" % (BASE, owner_repo(p["url"]), p["rev"]), t)
    return t


with concurrent.futures.ThreadPoolExecutor(4) as ex:
    tars = list(ex.map(get, pkgs))
for p, t in zip(pkgs, tars):
    dest = os.path.join(ROOT, ".lake", "packages", p["name"])
    if not os.path.isdir(os.path.join(dest, ".git")):
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        verified_unpack(t, dest, owner_repo(p["url"]), p["rev"])
        git(dest, "init", "-q")
        git(dest, "add", "-A", "-f")
        git(dest, "commit", "-q", "-m", "snapshot of %s@%s" % (owner_repo(p["url"]), p["rev"]))
        git(dest, "remote", "add", "origin", p["url"])
    snap = git(dest, "rev-parse", "HEAD")
    log.write(json.dumps({"name": p["name"], "url": p["url"], "rev": p["rev"], "sha256": sha256(t),
                          "snapshot": snap, "tree": git(dest, "rev-parse", "HEAD^{tree}"),
                          "tree_verified": True}) + "\n")
    log.flush()
    p["rev"] = snap
json.dump(man, open(man_path, "w"), indent=2)
print("SOURCES_DONE %s: %d packages" % (NAME, len(pkgs)))
