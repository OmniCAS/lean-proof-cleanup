#!/usr/bin/env python3
"""List and fetch the datasets catalogued in datasets/README.md.

Nothing here is redistributed: every entry is downloaded from its own host.

  python3 datasets/fetch.py list
  python3 datasets/fetch.py fetch minif2f-lean4 --dest downloads
  python3 datasets/fetch.py fetch leanpolish --dest downloads --dry-run
  python3 datasets/fetch.py fetch leanpolish --dest downloads --max-gb 2

Kinds: `git` entries are cloned (shallow unless --full), `hf` entries are downloaded file by
file from the Hugging Face Hub with the standard library, `link` entries only print where
to look. Hugging Face downloads stop before starting if the total exceeds --max-gb.
"""
import argparse
import json
import subprocess
import sys
import urllib.parse
import urllib.request
from pathlib import Path

CATALOG = {
    "leanpolish": {"kind": "hf", "id": "leanpolish-anon/lean-proof-compression",
                   "about": "LeanPolish verified local edits, failed same-site attempts, candidate pools"},
    "leanpolish-code": {"kind": "git", "url": "https://github.com/paulinebourigault/leanpolish.git",
                        "about": "LeanPolish pipeline, verifier, token counters, experiment scripts"},
    "rh-proof-dependencies": {"kind": "git", "url": "https://github.com/james-shore/rh-proof-dependencies.git",
                              "about": "kernel dependency closure of the five final RH theorems"},
    "rh-community": {"kind": "git", "url": "https://github.com/leanprover-community/riemann-hypothesis.git",
                     "about": "community cleanup repository (use --full for the history scripts/ needs)"},
    "grh-lean": {"kind": "git", "url": "https://github.com/lsernau/grh-lean.git",
                 "about": "two-edition rewrite of the Lean RH development (readable grh/, compact grh-compact/)"},
    "mit-short-verification": {"kind": "link", "url": "https://math.mit.edu/~drew/shortgrh/",
                               "about": "MIT verification logs for the two short editions (exports are several GB)"},
    "minif2f-lean4": {"kind": "git", "url": "https://github.com/yangky11/miniF2F-lean4.git",
                      "about": "miniF2F statements in Lean 4"},
    "putnambench": {"kind": "git", "url": "https://github.com/trishullab/PutnamBench.git",
                    "about": "PutnamBench statements"},
    "lean-workbook": {"kind": "hf", "id": "internlm/Lean-Workbook",
                      "about": "Lean Workbook statements"},
    "goedel-workbook-proofs": {"kind": "hf", "id": "Goedel-LM/Lean-workbook-proofs",
                               "about": "machine-generated Lean Workbook proofs (Goedel-Prover)"},
    "mathlib4": {"kind": "git", "url": "https://github.com/leanprover-community/mathlib4.git",
                 "about": "human-written baseline corpus"},
    "lean-refactor-arena": {"kind": "link", "url": "https://huggingface.co/spaces/delta-lab-ai/lean-refactor-arena",
                            "about": "competition leaderboard; data terms are set by the organisers"},
    "leanlean": {"kind": "link", "url": "https://openreview.net/forum?id=LssUgDHqQj",
                 "about": "repository-scale benchmark; no public data release found"},
    "leanify": {"kind": "link", "url": "https://openreview.net/forum?id=ikCmxFDkbM",
                "about": "proof-collection compression benchmark; no public data release found"},
}
HF_API = "https://huggingface.co/api/datasets/{id}?blobs=true"
HF_FILE = "https://huggingface.co/datasets/{id}/resolve/main/{path}"
UA = {"User-Agent": "lean-proof-cleanup-fetch"}


def hf_files(ds):
    req = urllib.request.Request(HF_API.format(id=ds), headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        info = json.load(r)
    return [(s["rfilename"], s.get("size") or 0) for s in info.get("siblings", [])]


def fetch_hf(ds, dest, dry_run, max_gb):
    files = hf_files(ds)
    total = sum(size for _, size in files)
    print(f"{ds}: {len(files)} files, {total / 1e9:.2f} GB")
    if dry_run:
        for path, size in files:
            print(f"  {size:>14,}  {path}")
        return
    if total > max_gb * 1e9:
        sys.exit(f"refusing: {total / 1e9:.2f} GB exceeds --max-gb {max_gb}")
    for path, _ in files:
        out = dest / path
        out.parent.mkdir(parents=True, exist_ok=True)
        url = HF_FILE.format(id=ds, path=urllib.parse.quote(path))
        req = urllib.request.Request(url, headers=UA)
        with urllib.request.urlopen(req, timeout=300) as r, open(out, "wb") as f:
            while chunk := r.read(1 << 20):
                f.write(chunk)
        print(f"  {path}")


def fetch_git(url, dest, dry_run, full):
    cmd = ["git", "clone"] + ([] if full else ["--depth", "1"]) + [url, str(dest)]
    print(" ".join(cmd))
    if not dry_run:
        subprocess.run(cmd, check=True)


def main():
    ap = argparse.ArgumentParser(description="List or fetch the catalogued datasets.")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    f = sub.add_parser("fetch")
    f.add_argument("name", choices=sorted(CATALOG))
    f.add_argument("--dest", required=True, type=Path)
    f.add_argument("--dry-run", action="store_true")
    f.add_argument("--full", action="store_true", help="full git history instead of depth 1")
    f.add_argument("--max-gb", type=float, default=2.0)
    a = ap.parse_args()
    if a.cmd == "list":
        for name, e in CATALOG.items():
            where = e.get("id") or e.get("url")
            print(f"{name:24} {e['kind']:5} {where}\n{'':30} {e['about']}")
        return
    e = CATALOG[a.name]
    target = a.dest / a.name
    if e["kind"] == "hf":
        fetch_hf(e["id"], target, a.dry_run, a.max_gb)
    elif e["kind"] == "git":
        fetch_git(e["url"], target, a.dry_run, a.full)
    else:
        print(f"{a.name}: not downloadable here; see {e['url']}")


if __name__ == "__main__":
    main()
