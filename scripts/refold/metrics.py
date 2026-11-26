"""Metrics for one subject at one stage. Requires a successful build (reads the environment).

Usage: python3 -I metrics.py SUBJECT STAGE [--note TEXT]
Writes REFOLD_OUT/depgraph/SUBJECT-STAGE.jsonl (declaration graph) and appends one JSON line to
REFOLD_OUT/metrics/SUBJECT.jsonl. Source counts use the same conventions as
../profile_lean_trees.py. Environment as for gate.py.
"""
import gzip
import importlib.util
import json
import os
import shutil
import statistics
import subprocess
import sys
import time

REPO = os.path.abspath(os.environ.get("REFOLD_REPO", os.getcwd()))
PROJ = os.path.abspath(os.environ.get("REFOLD_OUT", os.path.join(os.getcwd(), "refold-out")))
CLEAN = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "profile_lean_trees.py")

def _isolate():
    """Command prefix that denies network access to the build (override with REFOLD_ISOLATE)."""
    v = os.environ.get("REFOLD_ISOLATE")
    if v is not None:
        return v.split()
    if sys.platform == "darwin":
        return ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
    return ["unshare", "-r", "-n"]


def _subjects(repo):
    """Subjects of a working copy: name -> (solution module, [challenge modules]).
    Read from refold-subjects.json in the working copy (or the file named by REFOLD_SUBJECTS)."""
    path = os.environ.get("REFOLD_SUBJECTS", os.path.join(repo, "refold-subjects.json"))
    return {k: (v["solution"], v["challenges"]) for k, v in json.load(open(path)).items()}

NONET = _isolate()
SUBJECTS = _subjects(REPO)
TACTICS = ["have", "rw", "exact", "simp", "simpa", "simp_all", "omega", "grind", "aesop", "calc", "linarith",
           "nlinarith", "positivity", "norm_num", "refine", "intro", "obtain", "constructor", "by"]


def headline_names(challenges):
    out = []
    for ch in challenges:
        out += json.load(open(os.path.join(REPO, "ComparatorChallenges", ch + ".json")))["theorem_names"]
    return out


def dep_graph(solution, out_path):
    tmp = os.path.join(REPO, ".lake", "gate-tmp")
    os.makedirs(tmp, exist_ok=True)
    f = os.path.join(tmp, "DepGraph_" + solution + ".lean")
    open(f, "w").write("import %s\nimport Gate.Tools\n#eval Gate.depGraph `%s\n" % (solution, solution))
    p = subprocess.run(NONET + ["lake", "env", "lean", f], cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        sys.exit("depGraph failed: " + p.stdout.decode()[-2000:] + p.stderr.decode()[-2000:])
    rows = [json.loads(l) for l in p.stdout.decode().splitlines() if l.startswith("{")]
    with open(out_path, "w") as fh:
        for r in sorted(rows, key=lambda r: r["line0"]):
            fh.write(json.dumps(r, ensure_ascii=False) + "\n")
    return rows


def graph_stats(rows, heads):
    by = {r["name"]: r for r in rows}
    users = {n: set() for n in by}
    for r in rows:
        for u in r["uses"]:
            if u in users:
                users[u].add(r["name"])
    seen, st = set(), [h for h in heads if h in by]
    while st:
        x = st.pop()
        if x in seen:
            continue
        seen.add(x)
        st += [u for u in by[x]["uses"] if u in by]
    out = {"declarations_env": len(rows), "reachable_from_headlines": len(seen),
           "unreachable": len(rows) - len(seen), "headlines_found": sum(1 for h in heads if h in by)}
    for kind in ("theorem", "def"):
        ks = [r for r in rows if r["kind"] == kind and r["name"] not in heads]
        out[kind + "s_env"] = len(ks) + (sum(1 for h in heads if h in by) if kind == "theorem" else 0)
        out[kind + "s_unreachable"] = sum(1 for r in ks if r["name"] not in seen)
        out[kind + "s_used_0"] = sum(1 for r in ks if len(users[r["name"]]) == 0)
        out[kind + "s_used_1"] = sum(1 for r in ks if len(users[r["name"]]) == 1)
        out[kind + "s_used_2plus"] = sum(1 for r in ks if len(users[r["name"]]) >= 2)
    out["kinds"] = {}
    for r in rows:
        out["kinds"][r["kind"]] = out["kinds"].get(r["kind"], 0) + 1
    lens = [r["line1"] - r["line0"] + 1 for r in rows if r["kind"] == "theorem"]
    if lens:
        out["theorem_lines_mean"] = round(statistics.mean(lens), 1)
        out["theorem_lines_median"] = statistics.median(lens)
        out["theorem_lines_max"] = max(lens)
        out["theorem_lines_total"] = sum(lens)
    return out


def main():
    subject, stage = sys.argv[1], sys.argv[2]
    note = sys.argv[sys.argv.index("--note") + 1] if "--note" in sys.argv else ""
    solution, challenges = SUBJECTS[subject]
    src = os.path.join(REPO, solution + ".lean")
    raw = open(src, "rb").read()
    spec = importlib.util.spec_from_file_location("prof", CLEAN)
    prof = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(prof)
    tmp = os.path.join(PROJ, "metrics", "_scan_" + subject)
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(tmp)
    shutil.copyfile(src, os.path.join(tmp, solution + ".lean"))
    r, _, _ = prof.scan(tmp)
    shutil.rmtree(tmp)
    st, kinds, tac = r["stats"], r["kinds"], r["tactics"]
    code = st["code_lines"]
    m = {"subject": subject, "stage": stage, "time": time.strftime("%Y-%m-%d %H:%M:%S"), "note": note,
         "lines": st["lines"], "code_lines": code, "bytes": len(raw), "gzip_bytes": len(gzip.compress(raw, 9)),
         "theorems_src": kinds.get("theorem", 0) + kinds.get("lemma", 0),
         "defs_src": kinds.get("def", 0) + kinds.get("abbrev", 0),
         "declarations_src": sum(kinds.values()), "named_prop_defs": st.get("prop_defs", 0),
         "tactic_counts": {t: tac.get(t, 0) for t in TACTICS},
         "per_kloc": {t: round(1000 * tac.get(t, 0) / code, 1) for t in TACTICS}}
    os.makedirs(os.path.join(PROJ, "depgraph"), exist_ok=True)
    rows = dep_graph(solution, os.path.join(PROJ, "depgraph", subject + "-" + stage + ".jsonl"))
    m.update(graph_stats(rows, headline_names(challenges)))
    g = os.path.join(PROJ, "gate", subject + "-" + stage + ".json")
    if os.path.exists(g):
        gj = json.load(open(g))
        for k in ("pass", "build_seconds_module", "build_cpu_seconds", "build_peak_rss_mb", "olean_bytes", "warnings"):
            m["gate_" + k] = gj.get(k)
    with open(os.path.join(PROJ, "metrics", subject + ".jsonl"), "a") as fh:
        fh.write(json.dumps(m, ensure_ascii=False) + "\n")
    keys = ["lines", "code_lines", "gzip_bytes", "theorems_env", "defs_env", "declarations_env", "unreachable",
            "theorems_used_0", "theorems_used_1", "theorems_used_2plus", "defs_used_1", "theorem_lines_mean",
            "theorem_lines_median", "theorem_lines_max", "gate_build_seconds_module", "gate_olean_bytes"]
    print(subject, stage, " ".join("%s=%s" % (k, m.get(k)) for k in keys))


if __name__ == "__main__":
    main()
