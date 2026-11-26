"""Simplify stage, automated part: find proof blocks that a one-line automation call can replace.

Two commands.

  instrument  FILE.lean OUT.lean [--min-lines 2]
      Wrap every multi-line tactic block that follows `:= by` (inside theorems and lemmas) as
      `golf "ID" => block`, add `import Golf`, and write OUT.lean plus OUT.lean.blocks.json
      (ID -> original line range). Compile OUT.lean where the `Golf` library is available; every
      block that some menu tactic closes prints `GOLF ID tactic`.

  apply  FILE.lean BLOCKS.json LOG [--build "CMD"] [--report OUT.json]
      Replace each successful outermost block in FILE.lean by its tactic, then (with --build)
      rebuild and undo replacements that break the build, until the file compiles.

The `golf` tactic lives in Golf.lean (our tool). Nested blocks are only tried by the tactic when
the enclosing attempt failed, so one compilation gives the outermost replaceable blocks.
"""
import argparse
import json
import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from unroll import mask, indent_of  # noqa: E402

TOP = re.compile(r"(?:@\[[^\]]*\]\s*)*(?:(?:private|protected|noncomputable|nonrec|scoped|local|unsafe|partial)\s+)*"
                 r"(theorem|lemma|def|abbrev|instance|structure|class|inductive|example|opaque|axiom)\b")


def find_blocks(src, min_lines):
    lines = src.split("\n")
    m = mask(src).split("\n")
    kind, blocks = None, []
    for i, ml in enumerate(m):
        if ml.strip() and indent_of(ml) == 0:
            k = TOP.match(ml)
            if k:
                kind = k.group(1)
            elif re.match(r"(namespace|section|end|open|variable|universe|set_option|omit|include|attribute)\b", ml):
                kind = None if not ml.rstrip().endswith(" in") else kind
        if kind not in ("theorem", "lemma"):
            continue
        if not re.search(r":=\s*by\s*$", ml):
            continue
        j = i + 1
        while j < len(m) and not m[j].strip():
            j += 1
        if j >= len(m):
            continue
        b = indent_of(lines[j])
        if b == 0:
            continue
        e = j
        k2 = j
        while k2 < len(m):
            if lines[k2].strip():
                if indent_of(lines[k2]) < b:
                    break
                e = k2
            k2 += 1
        n = sum(1 for x in range(j, e + 1) if lines[x].strip())
        if n >= min_lines:
            blocks.append({"id": "L%d" % (i + 1), "by_line": i + 1, "first": j + 1, "last": e + 1, "indent": b,
                           "lines": n})
    return blocks


def instrument(a):
    src = open(a.file, encoding="utf-8").read()
    blocks = find_blocks(src, a.min_lines)
    lines = src.split("\n")
    for blk in sorted(blocks, key=lambda x: -x["by_line"]):
        # blocks nested inside this one were wrapped already and each added one line
        inner = sum(1 for o in blocks if blk["by_line"] < o["by_line"] <= blk["last"])
        f, l, b = blk["first"] - 1, blk["last"] - 1 + inner, blk["indent"]
        body = [("  " + x) if x.strip() else x for x in lines[f:l + 1]]
        lines[f:l + 1] = [" " * b + 'golf "%s" =>' % blk["id"]] + body
    lines = [("-- " + x) if re.match(r"set_option maxHeartbeats \d+ in$", x.strip()) else x for x in lines]
    out = "\n".join(lines)
    # the probe file is not the deliverable: attempts consume the declaration's heartbeat budget
    out = re.sub(r"^import Mathlib\s*$", "import Mathlib\nimport Golf\nset_option maxHeartbeats 0", out,
                 count=1, flags=re.M)
    open(a.out, "w", encoding="utf-8").write(out)
    json.dump(blocks, open(a.out + ".blocks.json", "w"), indent=1)
    print("blocks instrumented: %d (lines in them, counting nesting once per block: %d)" % (
        len(blocks), sum(b["lines"] for b in blocks)))


def apply(a):
    src = open(a.file, encoding="utf-8").read()
    blocks = {b["id"]: b for b in json.load(open(a.blocks))}
    log = open(a.log, encoding="utf-8", errors="replace").read()
    wins = {}
    for mm in re.finditer(r"GOLF (L\d+) (.+)$", log, re.M):
        wins.setdefault(mm.group(1), mm.group(2).strip())
    # outermost only (the tactic never reports a nested block of a successful one, but be safe)
    chosen = []
    for i, t in wins.items():
        b = blocks[i]
        if not any(o != i and blocks[o]["by_line"] < b["by_line"] and blocks[o]["last"] >= b["last"] for o in wins):
            chosen.append((b, t))
    skip, rounds, undone = set(), 0, []
    while True:
        lines = src.split("\n")
        owner = {}
        for b, t in sorted(chosen, key=lambda x: -x[0]["by_line"]):
            if b["id"] in skip:
                continue
            i = b["by_line"] - 1
            head = lines[i].rstrip()
            if len(head) + 1 + len(t) <= 100:
                new = [head + " " + t]
            else:
                new = [head, " " * b["indent"] + t]
            lines[i:b["last"]] = new
        text = "\n".join(lines)
        if not a.build:
            open(a.file, "w", encoding="utf-8").write(text)
            break
        open(a.file, "w", encoding="utf-8").write(text)
        p = subprocess.run(a.build, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        out = p.stdout.decode("utf-8", "replace")
        rounds += 1
        base = os.path.basename(a.file)
        errl = sorted({int(x.group(1)) for x in re.finditer(re.escape(base) + r":(\d+):\d+: (?:error)", out)} |
                      {int(x.group(1)) for x in re.finditer(r"^error: \S*" + re.escape(base) + r":(\d+):\d+", out, re.M)})
        print("round %d: applied %d, exit %d, error lines %d" % (rounds, len(chosen) - len(skip), p.returncode, len(errl)))
        if p.returncode == 0 and not errl:
            break
        if rounds > 25:
            sys.exit("too many rounds")
        # map error lines in the new file back to replacements: recompute positions
        pos, delta = {}, 0
        for b, t in sorted(chosen, key=lambda x: x[0]["by_line"]):
            if b["id"] in skip:
                continue
            start = b["by_line"] + delta
            n_new = 1 if len(src.split("\n")[b["by_line"] - 1].rstrip()) + 1 + len(t) <= 100 else 2
            pos[b["id"]] = (start, start + n_new - 1)
            delta += n_new - (b["last"] - b["by_line"] + 1)
        hit = set()
        for el in errl:
            cands = [(i, r) for i, r in pos.items() if r[0] - 1 <= el <= r[1] + 1]
            if cands:
                hit.add(min(cands, key=lambda c: abs(c[1][0] - el))[0])
        if not hit:
            # an error elsewhere: undo the nearest replacement above each error line
            for el in errl[:3]:
                above = [(i, r) for i, r in pos.items() if r[0] <= el]
                if above:
                    hit.add(max(above, key=lambda c: c[1][0])[0])
        if not hit:
            print(out[-2000:])
            sys.exit("errors could not be attributed")
        skip |= hit
        undone += sorted(hit)
    kept = [(b, t) for b, t in chosen if b["id"] not in skip]
    tact = {}
    for b, t in kept:
        k = t.split(" ")[0]
        tact[k] = tact.get(k, 0) + 1
    rep = {"blocks": len(blocks), "closed_by_automation": len(wins), "outermost": len(chosen), "applied": len(kept),
           "undone_after_build": undone, "rounds": rounds,
           "lines_removed": sum(b["last"] - b["by_line"] for b, _ in kept) - sum(
               0 if len(src.split("\n")[b["by_line"] - 1].rstrip()) + 1 + len(t) <= 100 else 1 for b, t in kept),
           "by_tactic": dict(sorted(tact.items(), key=lambda x: -x[1])),
           "replacements": [{"line": b["by_line"], "block_lines": b["lines"], "tactic": t} for b, t in kept]}
    if a.report:
        json.dump(rep, open(a.report, "w"), indent=1, ensure_ascii=False)
    print(json.dumps({k: v for k, v in rep.items() if k != "replacements"}, ensure_ascii=False))


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    i = sub.add_parser("instrument")
    i.add_argument("file"); i.add_argument("out"); i.add_argument("--min-lines", type=int, default=2)
    p = sub.add_parser("apply")
    p.add_argument("file"); p.add_argument("blocks"); p.add_argument("log")
    p.add_argument("--build", default=""); p.add_argument("--report")
    a = ap.parse_args()
    instrument(a) if a.cmd == "instrument" else apply(a)


if __name__ == "__main__":
    main()
