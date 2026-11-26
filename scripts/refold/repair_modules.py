"""Repair a project after a per-module rewrite: restore the modules that broke the build.

After unroll_project.py, a module can fail to build for two reasons: its own unrolled text does
not elaborate under the real build options, or it mentions (in source, not in its proof terms) a
lemma that was inlined away in another module. This loop builds the project, restores from the
git reference REF the modules that declared a now-unknown name and the modules whose own text
fails, and repeats until the build passes.

Usage: python3 repair_modules.py PROJECT_DIR GRAPH.jsonl REF --build "CMD" [--max-rounds 15] [--report OUT.json]
GRAPH.jsonl is the declaration graph of REF (before the rewrite).
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project"); ap.add_argument("graph"); ap.add_argument("ref")
    ap.add_argument("--build", required=True); ap.add_argument("--max-rounds", type=int, default=15)
    ap.add_argument("--report")
    a = ap.parse_args()
    root = os.path.abspath(a.project)
    rows = [json.loads(l) for l in open(a.graph, encoding="utf-8") if l.startswith("{")]
    by_last = collections.defaultdict(list)
    for r in rows:
        by_last[r["n"].split(".")[-1]].append(r)
    restored, rounds, log = set(), 0, []
    while True:
        p = subprocess.run(a.build, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=root)
        out = p.stdout.decode("utf-8", "replace")
        rounds += 1
        errs = re.findall(r"^error: (\S+?\.lean):(\d+):\d+: (.*)$", out, re.M)
        print("round %d: exit %d, errors %d, modules restored so far %d" % (rounds, p.returncode, len(errs), len(restored)),
              flush=True)
        if p.returncode == 0 and not errs:
            break
        if rounds >= a.max_rounds or not errs:
            print(out[-2000:])
            sys.exit("build failed and could not be repaired")
        want, named = set(), set()
        for path, _, msg in errs:
            m = re.match(r"Unknown (?:identifier|constant) `([^`]+)`", msg)
            if not m:
                continue
            named.add(path)
            parts = m.group(1).split(".")
            # the dotted name may end in a projection (`foo.le`): try each component as the declaration's last name
            for k in range(len(parts), 0, -1):
                cands = [r for r in by_last.get(parts[k - 1], []) if r["n"].endswith(".".join(parts[:k])) or len(parts[:k]) == 1]
                if cands:
                    for r in cands:
                        want.add(r["m"].replace(".", os.sep) + ".lean")
                    break
        for path, _, msg in errs:
            if path not in named:
                want.add(os.path.normpath(path))
        new = sorted(w for w in want if w not in restored)
        if not new:
            # nothing new to restore by name: restore the failing modules themselves
            new = sorted({os.path.normpath(path) for path, _, _ in errs} - restored)
        if not new:
            print(out[-2000:])
            sys.exit("errors remain in modules that are already restored")
        subprocess.run(["git", "checkout", a.ref, "--"] + new, cwd=root, check=True)
        restored |= set(new)
        log.append({"round": rounds, "errors": len(errs), "restored": new})
    rep = {"rounds": rounds, "modules_restored": sorted(restored), "log": log}
    if a.report:
        json.dump(rep, open(a.report, "w"), indent=1)
    print(json.dumps({"rounds": rounds, "modules_restored": len(restored)}))


if __name__ == "__main__":
    main()
