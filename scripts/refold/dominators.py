"""Find sub-developments with a one-statement interface in a project declaration graph.

In the graph "declaration -> declarations it uses", rooted at the headline theorems, declaration
D dominates E when every path from a headline theorem to E passes through D. The declarations D
dominates are needed only for D: they can be reorganised, replaced or deleted freely as long as
D's statement stays, and a gate on D's statement plus a build of what uses D is enough to check
the change. A declaration that dominates a few thousand lines is a natural unit of work for the
stages that need an understanding of the mathematics.

Usage: python3 dominators.py GRAPH.jsonl OUT.json --roots NAME [NAME ...] [--min-lines 1500] [--top 40]
       [--show NAME]   also write the slice of NAME (the declarations it dominates, by module) to OUT.json.slice
       [--block FILE]  with --show: write the slice as a block file for block_gate.py (contract = NAME,
                       its declarations with line ranges, the merged line ranges per source file)
       [--free-dead-users]  with --block: also put into the block the declarations that the headline
                       theorems do not reach but that use a declaration of the block (directly or
                       through other such declarations). Left-over dead code otherwise pins the
                       statements it mentions; inside the block it may be changed or deleted.
GRAPH.jsonl is written by lean/ProjectGraph.lean. Prints the largest dominators, with nested
ones marked, and writes all dominators above the threshold to OUT.json.
"""
import argparse
import collections
import json


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("graph"); ap.add_argument("out")
    ap.add_argument("--roots", nargs="+", required=True)
    ap.add_argument("--min-lines", type=int, default=1500); ap.add_argument("--top", type=int, default=40)
    ap.add_argument("--show"); ap.add_argument("--block"); ap.add_argument("--free-dead-users", action="store_true")
    a = ap.parse_args()
    rows = [json.loads(l) for l in open(a.graph, encoding="utf-8") if l.startswith("{")]
    by_i = {r["i"]: r for r in rows}
    name_i = {r["n"]: r["i"] for r in rows}
    ROOT = -1
    succ = {ROOT: [name_i[n] for n in a.roots if n in name_i]}
    for r in rows:
        succ[r["i"]] = r["u"]
    # reverse postorder from the virtual root
    order, seen, stack = [], {ROOT}, [(ROOT, iter(succ[ROOT]))]
    while stack:
        v, it = stack[-1]
        for w in it:
            if w not in seen:
                seen.add(w)
                stack.append((w, iter(succ[w])))
                break
        else:
            order.append(v)
            stack.pop()
    rpo = order[::-1]
    num = {v: k for k, v in enumerate(rpo)}
    pred = collections.defaultdict(list)
    for v in rpo:
        for w in succ[v]:
            if w in num:
                pred[w].append(v)
    idom = {ROOT: ROOT}

    def intersect(x, y):
        while x != y:
            while num[x] > num[y]:
                x = idom[x]
            while num[y] > num[x]:
                y = idom[y]
        return x

    changed = True
    while changed:
        changed = False
        for v in rpo[1:]:
            ps = [p for p in pred[v] if p in idom]
            new = ps[0]
            for p in ps[1:]:
                new = intersect(new, p)
            if idom.get(v) != new:
                idom[v] = new
                changed = True
    # subtree sizes in the dominator tree
    lines = {v: by_i[v]["l1"] - by_i[v]["l0"] + 1 for v in rpo if v != ROOT}
    sub_lines = dict(lines)
    sub_thm = {v: int(by_i[v]["k"] == "theorem") for v in lines}
    sub_def = {v: int(by_i[v]["k"] in ("def", "structure", "inductive", "instance")) for v in lines}
    sub_mods = {v: {by_i[v]["m"]} for v in lines}
    for v in reversed(rpo):                      # children before parents
        if v == ROOT:
            continue
        p = idom[v]
        if p != ROOT:
            sub_lines[p] += sub_lines[v]
            sub_thm[p] += sub_thm[v]
            sub_def[p] += sub_def[v]
            sub_mods[p] |= sub_mods[v]
    users = collections.Counter()
    for v in lines:
        for w in succ[v]:
            if w in lines:
                users[w] += 1
    big = [v for v in lines if sub_lines[v] >= a.min_lines]
    big.sort(key=lambda v: -sub_lines[v])
    out = []
    for v in big:
        chain, p = [], idom[v]
        while p != ROOT:
            if sub_lines[p] >= a.min_lines:
                chain.append(by_i[p]["n"])
            p = idom[p]
        out.append({"name": by_i[v]["n"], "kind": by_i[v]["k"], "module": by_i[v]["m"], "own_lines": lines[v],
                    "dominated_lines": sub_lines[v], "dominated_theorems": sub_thm[v] - int(by_i[v]["k"] == "theorem"),
                    "dominated_definitions": sub_def[v], "modules": len(sub_mods[v]), "users": users[v],
                    "inside": chain[:3]})
    json.dump(out, open(a.out, "w"), indent=1)
    if a.show:
        d = name_i[a.show]
        members = []
        for v in lines:
            p = v
            while p != ROOT and p != d:
                p = idom[p]
            if p == d:
                members.append(v)
        mods = collections.defaultdict(lambda: {"declarations": 0, "lines": 0, "names": []})
        for v in members:
            m = mods[by_i[v]["m"]]
            m["declarations"] += 1
            m["lines"] += lines[v]
            m["names"].append(by_i[v]["n"])
        whole = collections.Counter(by_i[v]["m"] for v in lines)
        sl = {"interface": a.show, "declarations": len(members), "lines": sum(lines[v] for v in members),
              "theorems": sum(1 for v in members if by_i[v]["k"] == "theorem"),
              "users_of_interface": sorted({by_i[v]["n"] for v in lines if d in succ[v]}),
              "modules": {m: dict(x, reachable_declarations_in_module=whole[m]) for m, x in sorted(mods.items())}}
        json.dump(sl, open(a.out + ".slice", "w"), indent=1)
        if a.block:
            # declarations outside the headline closure that use a member of the block
            pinned = sorted({by_i[w]["n"] for r in rows if r["i"] not in lines for w in r["u"] if w in set(members) and w != d})
            dead = set()
            if a.free_dead_users:
                mem, grew = set(members), True
                while grew:
                    grew = False
                    for r in rows:
                        if r["i"] not in lines and r["i"] not in dead and any(w in mem or w in dead for w in r["u"]):
                            dead.add(r["i"])
                            grew = True
            live = list(members)
            members = live + sorted(dead)
            # line ranges per source file; neighbours separated by at most one line are merged
            # (lines between declarations may hold `variable`, `open` or `section` commands that
            # other declarations depend on, so wider gaps stay outside the block)
            ranges = collections.defaultdict(list)
            for v in sorted(members, key=lambda v: (by_i[v]["m"], by_i[v]["l0"])):
                r, f = by_i[v], by_i[v]["m"].replace(".", "/") + ".lean"
                if ranges[f] and r["l0"] - ranges[f][-1][1] <= 2:
                    ranges[f][-1][1] = max(ranges[f][-1][1], r["l1"])
                else:
                    ranges[f].append([r["l0"], r["l1"]])
            users = sorted(v for v in lines if d in succ[v])
            json.dump({"contract": a.show, "contract_module": by_i[d]["m"],
                       "declarations": [dict({"name": by_i[v]["n"], "kind": by_i[v]["k"], "module": by_i[v]["m"],
                                              "line0": by_i[v]["l0"], "line1": by_i[v]["l1"]},
                                             **({"dead": True} if v in dead else {}))
                                        for v in sorted(members, key=lambda v: (by_i[v]["m"], by_i[v]["l0"]))],
                       "pinned_by_dead_code": pinned,
                       "ranges": ranges,
                       "users_of_contract": [by_i[v]["n"] for v in users],
                       "user_modules": sorted({by_i[v]["m"] for v in users} | {by_i[v]["m"] for v in dead})},
                      open(a.block, "w"), indent=1)
            print("block file %s: %d line ranges in %d files" % (a.block, sum(len(x) for x in ranges.values()), len(ranges)))
            print("   declarations of the block used by dead code outside it: %d; dead users put into the block: %d (%d lines)" % (
                len(pinned), len(dead), sum(by_i[v]["l1"] - by_i[v]["l0"] + 1 for v in dead)))
        print("slice of %s: %d declarations, %d lines, %d theorems, in %d modules" % (
            a.show, sl["declarations"], sl["lines"], sl["theorems"], len(mods)))
        for m, x in sorted(mods.items()):
            print("   %-60s %4d of %4d reachable declarations, %5d lines" % (m, x["declarations"], whole[m], x["lines"]))
    total = sum(lines.values())
    print("reachable declarations %d, lines %d; dominators with >= %d lines: %d" % (len(lines), total, a.min_lines, len(out)))
    for o in out[:a.top]:
        print("%7d lines %5d thm %4d def %4d modules  users %3d  %-9s %s%s" % (
            o["dominated_lines"], o["dominated_theorems"], o["dominated_definitions"], o["modules"], o["users"],
            o["kind"], o["name"][-80:], "   [inside " + o["inside"][0].split(".")[-1] + "]" if o["inside"] else ""))


if __name__ == "__main__":
    main()
