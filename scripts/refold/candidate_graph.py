"""Import-graph statistics of a candidate Lean tree, read from source only (nothing is built).

Usage: python3 -I scripts/candidate_graph.py OUT.json LABEL=DIR:ROOT[,ROOT...] [...]
  DIR   directory that module names are relative to
  ROOT  module(s) holding the headline theorem(s); "*" means every module
Prints one summary line per label and writes OUT.json (per label: counts, closure, layers,
the list of leaf modules of the closure with their line counts, and build-time-code hits).
"""
import collections
import json
import os
import re
import sys

IMP = re.compile(r"^\s*(?:public\s+|private\s+|meta\s+)*import\s+(?:all\s+)?([\w.«»']+)", re.M)
BUILD_CODE = re.compile(
    r"^\s*(?:#eval|#exit|run_cmd|run_meta|initialize|builtin_initialize|macro|macro_rules|syntax|elab|elab_rules|"
    r"declare_syntax_cat|open Lean|import Lean|unsafe)\b", re.M)
AXIOM = re.compile(r"^\s*(?:private\s+|protected\s+)?axiom\s", re.M)


def strip_comments(s):
    s = re.sub(r"/-.*?-/", lambda m: "\n" * m.group(0).count("\n"), s, flags=re.S)
    return re.sub(r"--[^\n]*", "", s)


def analyse(root_dir, roots):
    mods = {}
    for d, dirs, fs in os.walk(root_dir):
        dirs[:] = [x for x in dirs if x not in (".lake", ".git")]
        for f in fs:
            if f.endswith(".lean"):
                p = os.path.join(d, f)
                mods[os.path.relpath(p, root_dir)[:-5].replace(os.sep, ".")] = p
    imp, lines, hits, axioms, native = {}, {}, {}, {}, {}
    for m, p in mods.items():
        raw = open(p, encoding="utf-8", errors="replace").read()
        lines[m] = raw.count("\n") + 1
        s = strip_comments(raw)
        imp[m] = [i for i in IMP.findall(s) if i in mods]
        hits[m] = len(BUILD_CODE.findall(s))
        axioms[m] = len(AXIOM.findall(s))
        native[m] = len(re.findall(r"\bnative_decide\b", s))
    if roots == ["*"]:
        closure = set(mods)
    else:
        missing = [r for r in roots if r not in mods]
        if missing:
            sys.exit("root module not found: %s" % missing)
        closure, st = set(roots), list(roots)
        while st:
            x = st.pop()
            for u in imp[x]:
                if u not in closure:
                    closure.add(u)
                    st.append(u)
    indeg = {m: 0 for m in closure}
    ch = collections.defaultdict(list)
    for m in closure:
        for u in imp[m]:
            ch[u].append(m)
            indeg[m] += 1
    q = [m for m in closure if indeg[m] == 0]
    depth = {m: 1 for m in q}
    cost = {m: lines[m] for m in q}  # critical path weighted by lines
    i = 0
    while i < len(q):
        x = q[i]
        i += 1
        for y in ch[x]:
            depth[y] = max(depth.get(y, 0), depth[x] + 1)
            cost[y] = max(cost.get(y, 0), cost[x] + lines[y])
            indeg[y] -= 1
            if indeg[y] == 0:
                q.append(y)
    lay = collections.Counter(depth.values())
    sz = sorted(lines[m] for m in closure)
    tot, cl = sum(lines.values()), sum(lines[m] for m in closure)
    return {
        "modules": len(mods), "lines": tot, "closure_modules": len(closure), "closure_lines": cl,
        "closure_share_of_lines": round(cl / tot, 3), "edges": sum(len(imp[m]) for m in closure),
        "layers": max(depth.values()), "widest_layer": max(lay.values()),
        "critical_path_lines": max(cost.values()), "parallelism_by_lines": round(cl / max(cost.values()), 1),
        "module_lines_median": sz[len(sz) // 2], "module_lines_p90": sz[int(len(sz) * 0.9)], "module_lines_max": sz[-1],
        "modules_with_build_time_code": sum(1 for m in closure if hits[m]),
        "axiom_declarations_in_closure": sum(axioms[m] for m in closure),
        "native_decide_in_closure": sum(native[m] for m in closure),
        "leaves": sorted(([m, lines[m], hits[m]] for m in closure if depth[m] == 1), key=lambda x: x[0]),
        "paths": {m: mods[m] for m in closure if depth[m] == 1},
    }


def main():
    out = {}
    for a in sys.argv[2:]:
        label, rest = a.split("=", 1)
        d, roots = rest.rsplit(":", 1)
        r = analyse(d, roots.split(","))
        out[label] = r
        print("%-16s modules %6d lines %9d | closure %6d modules %9d lines (%.0f%%) | layers %4d widest %5d "
              "critical path %7d lines (parallelism %.1f) | module lines median %d p90 %d max %d | "
              "build-time-code modules %d, axioms %d, native_decide %d" % (
                  label, r["modules"], r["lines"], r["closure_modules"], r["closure_lines"],
                  100 * r["closure_share_of_lines"], r["layers"], r["widest_layer"], r["critical_path_lines"],
                  r["parallelism_by_lines"], r["module_lines_median"], r["module_lines_p90"], r["module_lines_max"],
                  r["modules_with_build_time_code"], r["axiom_declarations_in_closure"], r["native_decide_in_closure"]))
    json.dump(out, open(sys.argv[1], "w"), ensure_ascii=False)


if __name__ == "__main__":
    main()
