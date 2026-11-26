"""Unroll stage for a multi-file project: run unroll.py on every module, in parallel.

Only lemmas whose single user is in the same module are inlined, so a module's exported
statements lose exactly the inlined lemmas and nothing else changes for its importers. Each
module can therefore be checked on its own against the already-built oleans of its imports:
the candidate text is written to a scratch file and compiled with a plain `lean` call, no Lake
build, no interference between workers. A full project build afterwards is the real check.

Usage:
  python3 unroll_project.py PROJECT_DIR GRAPH.jsonl --roots NAME [NAME ...] --work SCRATCH_DIR
      --lean "CMD with {opts} and {file}" [--opts PREFIX="-Dfoo=true ..."]... [--jobs 16]
      [--report OUT.json] [--apply] [--only PREFIX]
  GRAPH.jsonl   project declaration graph (lean/ProjectGraph.lean) of the *current* sources
  --lean        how to compile one file against the project's built oleans, e.g.
                "cd PROJECT_DIR && unshare -r -n lake env lean {opts} {file}"
  --opts        extra lean options for modules under a prefix (those of the lakefile's lean_lib)
  --apply       write the unrolled modules back into PROJECT_DIR (otherwise they stay in SCRATCH_DIR)
"""
import argparse
import collections
import concurrent.futures
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project"); ap.add_argument("graph")
    ap.add_argument("--roots", nargs="+", required=True); ap.add_argument("--work", required=True)
    ap.add_argument("--lean", required=True); ap.add_argument("--opts", action="append", default=[])
    ap.add_argument("--jobs", type=int, default=16); ap.add_argument("--report")
    ap.add_argument("--apply", action="store_true"); ap.add_argument("--only", default="")
    ap.add_argument("--max-rounds", type=int, default=25)
    a = ap.parse_args()
    root = os.path.abspath(a.project)
    opts = dict(o.split("=", 1) for o in a.opts)
    rows = [json.loads(l) for l in open(a.graph, encoding="utf-8") if l.startswith("{")]
    by_i = {r["i"]: r for r in rows}
    users = collections.defaultdict(set)
    for r in rows:
        for u in r["u"]:
            users[u].add(r["i"])
    by_mod = collections.defaultdict(list)
    for r in rows:
        by_mod[r["m"]].append(r)
    os.makedirs(a.work, exist_ok=True)
    jobs = []
    for m, rs in sorted(by_mod.items()):
        if a.only and not m.startswith(a.only):
            continue
        local = {r["i"] for r in rs}
        cand = 0
        out_rows = []
        for r in rs:
            us = users[r["i"]]
            ext = sum(1 for u in us if u not in local)
            out_rows.append({"name": r["n"], "kind": r["k"], "line0": r["l0"], "line1": r["l1"],
                             "uses": [by_i[u]["n"] for u in r["u"] if u in local],
                             "typeUses": [by_i[u]["n"] for u in r["t"] if u in local], "extUsers": ext})
            if r["k"] == "theorem" and r["n"] not in a.roots and len(us) == 1 and ext == 0:
                cand += 1
        if not cand:
            continue
        d = os.path.join(a.work, m)
        os.makedirs(d, exist_ok=True)
        src = os.path.join(root, m.replace(".", os.sep) + ".lean")
        dst = os.path.join(d, os.path.basename(src))
        with open(dst, "w", encoding="utf-8") as fh:
            fh.write(open(src, encoding="utf-8").read())
        g = os.path.join(d, "graph.jsonl")
        with open(g, "w", encoding="utf-8") as fh:
            for r in out_rows:
                fh.write(json.dumps(r) + "\n")
        o = next((v for k, v in opts.items() if m == k or m.startswith(k + ".")), "")
        jobs.append((m, src, dst, g, a.lean.format(opts=o, file=dst), cand))
    print("modules %d, with candidates %d, candidate inlines %d" % (len(by_mod), len(jobs), sum(j[5] for j in jobs)),
          flush=True)

    def run(job):
        m, src, dst, g, cmd, cand = job
        rep = os.path.join(os.path.dirname(dst), "report.json")
        p = subprocess.run([sys.executable, os.path.join(HERE, "unroll.py"), dst, g, "--headlines", ",".join(a.roots),
                            "--build", cmd, "--report", rep, "--max-rounds", str(a.max_rounds)],
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ok = p.returncode == 0 and os.path.exists(rep)
        r = json.load(open(rep)) if ok else {}
        if not ok:
            # leave the module as it was
            with open(dst, "w", encoding="utf-8") as fh:
                fh.write(open(src, encoding="utf-8").read())
        return {"module": m, "ok": ok, "candidates": r.get("candidates", cand), "inlined": r.get("inlined", 0),
                "rounds": r.get("rounds"), "heartbeat_raises": len(r.get("heartbeat_raises", {})),
                "theorems_before": r.get("theorems_before"), "theorems_after": r.get("theorems_after"),
                "tail": "" if ok else p.stdout.decode("utf-8", "replace")[-300:]}

    res = []
    with concurrent.futures.ThreadPoolExecutor(a.jobs) as ex:
        for k, r in enumerate(ex.map(run, jobs), 1):
            res.append(r)
            if k % 50 == 0 or k == len(jobs):
                print("done %d/%d modules, inlined so far %d" % (k, len(jobs), sum(x["inlined"] for x in res)), flush=True)
    if a.apply:
        for (m, src, dst, g, cmd, cand), r in zip(jobs, res):
            if r["ok"] and r["inlined"]:
                with open(src, "w", encoding="utf-8") as fh:
                    fh.write(open(dst, encoding="utf-8").read())
    summary = {"modules": len(by_mod), "modules_with_candidates": len(jobs),
               "candidates": sum(r["candidates"] for r in res), "inlined": sum(r["inlined"] for r in res),
               "modules_failed": sum(1 for r in res if not r["ok"]),
               "declarations_with_raised_heartbeats": sum(r["heartbeat_raises"] for r in res),
               "applied": bool(a.apply)}
    if a.report:
        json.dump({"summary": summary, "modules": res}, open(a.report, "w"), indent=1)
    print(json.dumps(summary))


if __name__ == "__main__":
    main()
