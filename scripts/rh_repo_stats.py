#!/usr/bin/env python3
"""Size statistics for the community Lean RH repository, computed from Git objects only.

Nothing is built and no Lean code is run. The script reads a local clone of
https://github.com/leanprover-community/riemann-hypothesis and writes three files:

  rh_revision_stats.csv   per revision: .lean files, total lines, body lines, import lines,
                          theorem/lemma lines, Lean toolchain
  rh_mainline_merges.csv  every first-parent commit of each line (the alpoge cleanup line and
                          the new main): date, PR number, files changed, lines added and
                          deleted (no renames detected)
  rh_statements.json      SHA-256 of each of the five final statements (whitespace collapsed),
                          per revision, and whether they equal the original archive's

Definitions:
  body lines        lines that are not blank, not an `import` line (with any of the
                    modifiers `public`, `meta`, `private`) and not a bare `module` line
  theorem/lemma     lines that start (after optional `@[...]`, `private`, `protected`) with
                    `theorem` or `lemma`; this is a line count for before/after comparison,
                    not the kernel's declaration count

Usage:
  git clone https://github.com/leanprover-community/riemann-hypothesis.git rh
  python3 scripts/rh_repo_stats.py --repo rh --out data
  python3 scripts/rh_repo_stats.py --repo rh --out data \
      --rev 40e56bab:original --rev origin/alpoge:alpoge --rev origin/main:main \
      --line alpoge:7cce738:origin/alpoge

Revisions given with --rev are written in the order given; with none, a default list of
the commits discussed in docs/rh-community-cleanup.md is used. In a fresh clone the alpoge
line is the remote branch origin/alpoge; the old main is no longer the default branch.
"""
import argparse
import csv
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_REVS = [
    ("40e56bab", "original archive"),
    ("7cce738", "alpoge line: 2026-11-22 snapshot (after #93)"),
    ("14f383e5ede", "alpoge line: #66, Lean 4.36, module system, unreachable files deleted"),
    ("ecc801f3f81^", "alpoge line: after #185 (Lean 4.37.0-rc1) and #221"),
    ("ecc801f3f81", "alpoge line: #324, thin wrappers deleted, modules clumped"),
    ("75e2012dcc6", "alpoge line: 2026-11-25 morning (then main)"),
    ("756a70250dc", "alpoge line: batch 23 (branch alpoge)"),
    ("47fcde57c49", "new main: grh-lean readable edition moved to the root"),
    ("b7642ae1317", "new main: after batches m1-m4 and the Lean 4.37.0-rc1 bump"),
]
DEFAULT_LINES = [
    ("alpoge", "7cce738", "756a70250dc"),
    ("main", "47fcde57c49", "b7642ae1317"),
]
FINAL = [
    "riemannHypothesis",
    "riemannZeta_eq_zero_re",
    "LFunction_ne_zero_of_half_lt_re",
    "LFunction_eq_zero_re",
    "LFunction_eq_zero_re_of_isPrimitive",
]
BODY_EXCLUDE = r"^[[:space:]]*$|^(public |meta |private )*import |^module[[:space:]]*$"
IMPORT = r"^(public |meta |private )*import "
THEOREM = r"^\s*(@\[[^]]*\]\s*)?(private |protected )?(theorem|lemma) "


def git(repo, *args):
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if r.returncode not in (0, 1):  # git grep exits 1 when nothing matches
        sys.exit(f"git {' '.join(args)} failed: {r.stderr.strip()}")
    return r.stdout


def utc(epoch):
    return datetime.fromtimestamp(int(epoch), timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def grep_count(repo, rev, pattern, invert=False):
    args = ["grep", "-c", "-E"] + (["-v"] if invert else []) + [pattern, rev, "--", "*.lean"]
    total = 0
    for line in git(repo, *args).splitlines():
        total += int(line.rsplit(":", 1)[1])
    return total


def revision_row(repo, rev, label):
    commit = git(repo, "rev-parse", "--short=11", rev).strip()
    date = utc(git(repo, "log", "-1", "--format=%ct", rev).strip())
    files = sum(1 for p in git(repo, "ls-tree", "-r", "--name-only", rev).splitlines()
                if p.endswith(".lean"))
    toolchain = git(repo, "cat-file", "-p", f"{rev}:lean-toolchain").strip()
    return {
        "revision": commit if len(rev) == 40 else rev,
        "commit": commit,
        "committer_date_utc": date,
        "label": label,
        "lean_files": files,
        "total_lines": grep_count(repo, rev, ""),
        "body_lines": grep_count(repo, rev, BODY_EXCLUDE, invert=True),
        "import_lines": grep_count(repo, rev, IMPORT),
        "theorem_lemma_lines": grep_count(repo, rev, THEOREM),
        "lean_toolchain": toolchain,
    }


def mainline_merges(repo, line_name, base, head):
    out = git(repo, "-c", "diff.renameLimit=0", "log", "--first-parent", "--no-renames",
              "--format=@@%H|%ct|%s", "--shortstat", f"{base}..{head}")
    rows, cur = [], None
    for line in out.splitlines():
        if line.startswith("@@"):
            sha, date, subject = line[2:].split("|", 2)
            m = re.search(r"(?:pull request #|PR #|\(#)(\d+)", subject)
            cur = {"line": line_name, "commit": sha[:11], "committer_date_utc": utc(date),
                   "pr_number": int(m.group(1)) if m else "",
                   "files_changed": 0, "insertions": 0, "deletions": 0}
            rows.append(cur)
        elif "changed" in line and cur is not None:
            for key, pat in (("files_changed", r"(\d+) files? changed"),
                             ("insertions", r"(\d+) insertions?"),
                             ("deletions", r"(\d+) deletions?")):
                m = re.search(pat, line)
                cur[key] = int(m.group(1)) if m else 0
    rows.reverse()  # oldest first
    return rows


def statements(repo, rev):
    src = git(repo, "cat-file", "-p", f"{rev}:src/Main.lean")
    out = {}
    for name in FINAL:
        m = re.search(r"theorem\s+" + re.escape(name) + r"\b(.*?):=", src, re.S)
        text = " ".join(m.group(1).split()) if m else None
        out[name] = hashlib.sha256(text.encode()).hexdigest() if text else None
    return out


def write_csv(path, rows):
    with open(path, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--repo", required=True, help="local clone of the community repository")
    ap.add_argument("--out", required=True, help="output directory")
    ap.add_argument("--rev", action="append", default=[],
                    help="REV:LABEL, repeatable; default: the commits in the report")
    ap.add_argument("--line", action="append", default=[],
                    help="NAME:BASE:HEAD, repeatable; first-parent commits of BASE..HEAD; "
                         "default: the alpoge line and the new main")
    a = ap.parse_args()
    repo, out = Path(a.repo), Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    revs = [tuple(r.split(":", 1)) if ":" in r else (r, r) for r in a.rev] or DEFAULT_REVS
    rows = [revision_row(repo, r, label) for r, label in revs]
    write_csv(out / "rh_revision_stats.csv", rows)

    lines = [tuple(x.split(":", 2)) for x in a.line] or DEFAULT_LINES
    merges = [m for name, base, head in lines for m in mainline_merges(repo, name, base, head)]
    write_csv(out / "rh_mainline_merges.csv", merges)

    original = statements(repo, revs[0][0])
    st = {"definition": "sha256 of the statement text between the theorem name and `:=`, "
                        "whitespace collapsed, read from src/Main.lean",
          "reference_revision": revs[0][0], "revisions": {}}
    for r, _ in revs:
        h = statements(repo, r)
        st["revisions"][git(repo, "rev-parse", "--short=11", r).strip()] = {
            "hashes": h, "all_equal_to_reference": h == original}
    (out / "rh_statements.json").write_text(json.dumps(st, indent=2) + "\n")
    print(f"wrote {len(rows)} revisions and the mainline merges to {out}")


if __name__ == "__main__":
    main()
