"""Summarise a project declaration graph written by ProjectGraph.dump.

Usage: python3 graph_summary.py GRAPH.jsonl OUT.json ROOT_NAME [ROOT_NAME ...]
Reports, for user-level declarations: totals by kind, how many are reachable from the root
(headline) declarations, and how many theorems are used by 0 / 1 / 2+ other declarations, in the
whole project and inside the reachable part; plus per-top-level-directory reachability.
"""
import collections
import json
import sys

rows = [json.loads(l) for l in open(sys.argv[1], encoding="utf-8") if l.startswith("{")]
by_i = {r["i"]: r for r in rows}
name_i = {r["n"]: r["i"] for r in rows}
roots = [name_i[n] for n in sys.argv[3:] if n in name_i]
missing = [n for n in sys.argv[3:] if n not in name_i]
seen, st = set(), list(roots)
while st:
    x = st.pop()
    if x in seen:
        continue
    seen.add(x)
    st += by_i[x]["u"]
users = collections.defaultdict(set)
for r in rows:
    for u in r["u"]:
        users[u].add(r["i"])
kinds = collections.Counter(r["k"] for r in rows)
kinds_reach = collections.Counter(by_i[i]["k"] for i in seen)
th = [r for r in rows if r["k"] == "theorem"]
th_r = [r for r in th if r["i"] in seen]


def use_hist(rs, within=None):
    h = collections.Counter()
    for r in rs:
        us = users[r["i"]] if within is None else {u for u in users[r["i"]] if u in within}
        h["0" if not us else "1" if len(us) == 1 else "2+"] += 1
    return dict(h)


lines = lambda rs: sum(r["l1"] - r["l0"] + 1 for r in rs)
top = collections.defaultdict(lambda: [0, 0, 0, 0])
for r in rows:
    k = ".".join(r["m"].split(".")[:2])
    top[k][0] += 1
    top[k][2] += r["l1"] - r["l0"] + 1
    if r["i"] in seen:
        top[k][1] += 1
        top[k][3] += r["l1"] - r["l0"] + 1
mods_all = {r["m"] for r in rows}
mods_reach = {by_i[i]["m"] for i in seen}
out = {
    "roots_found": len(roots), "roots_missing": missing,
    "declarations": len(rows), "reachable": len(seen), "reachable_share": round(len(seen) / len(rows), 4),
    "by_kind": dict(kinds), "by_kind_reachable": dict(kinds_reach),
    "theorems": len(th), "theorems_reachable": len(th_r),
    "theorem_lines": lines(th), "theorem_lines_reachable": lines(th_r),
    "declaration_lines": lines(rows), "declaration_lines_reachable": lines([by_i[i] for i in seen]),
    "theorem_users_all": use_hist(th), "theorem_users_within_reachable": use_hist(th_r, seen),
    "modules_with_declarations": len(mods_all), "modules_with_reachable_declarations": len(mods_reach),
    "by_top_dir": {k: {"declarations": v[0], "reachable": v[1], "lines": v[2], "lines_reachable": v[3]}
                   for k, v in sorted(top.items(), key=lambda x: -x[1][2])[:25]},
}
json.dump(out, open(sys.argv[2], "w"), indent=1)
print(json.dumps({k: v for k, v in out.items() if k != "by_top_dir"}))
