"""Gate for rewriting one block (sub-development) behind a fixed contract.

A block is a contract theorem together with the declarations that are needed only for it
(dominators.py --show NAME --block FILE). Its rewrite is accepted when

  1. the ordinary gate of every subject named with --subject passes (gate.py: frozen statement
     files, headline statements, axioms, full offline build); with --quick this step is replaced
     by a build of the modules that use the contract;
  2. the contract holds: the statement fingerprint of the contract theorem (its type and every
     project constant the type mentions, with their bodies) equals the one recorded on the base,
     and its axioms are the three standard ones;
  3. the change is local: every hunk of `git diff BASE` lies inside the block's line ranges, so
     blocks rewritten in separate working copies can be merged.

Usage: python3 -I block_gate.py BLOCK.json STAGE --base REF [--subject NAME ...] [--quick] [--keep-build] [--slack 3]
       (--keep-build is passed to gate.py: incremental build instead of a build from scratch)
       python3 -I block_gate.py BLOCK.json --record-base        (on the built base; writes BLOCK.contract.base)
Environment: REFOLD_REPO, REFOLD_OUT, REFOLD_ISOLATE, REFOLD_SUBJECTS as for gate.py; the working
copy needs the Gate library (lean/GateTools.lean as Gate/Tools.lean).
Prints the block's size on the base and now, and BLOCK GATE PASS or FAIL; exit code 0/1.
"""
import argparse
import json
import os
import re
import subprocess
import sys

REPO = os.path.abspath(os.environ.get("REFOLD_REPO", os.getcwd()))
HERE = os.path.dirname(os.path.abspath(__file__))
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}


def isolate():
    v = os.environ.get("REFOLD_ISOLATE")
    if v is not None:
        return v.split()
    if sys.platform == "darwin":
        return ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
    return ["unshare", "-r", "-n"]


def fingerprint(block):
    """Statement fingerprint and axioms of the contract theorem, read from the built contract module."""
    tmp = os.path.join(REPO, ".lake", "gate-tmp")
    os.makedirs(tmp, exist_ok=True)
    f = os.path.join(tmp, "Contract.lean")
    with open(f, "w", encoding="utf-8") as h:
        h.write("import %s\nimport Gate.Tools\n#eval Gate.statementReport [`%s]\n#eval Gate.axiomReport [`%s]\n"
                % (block["contract_module"], block["contract"], block["contract"]))
    p = subprocess.run(isolate() + ["lake", "env", "lean", f], cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = p.stdout.decode("utf-8", "replace").splitlines()
    return ([l for l in out if l.startswith(("headline ", "const "))], [l for l in out if l.startswith("axioms ")],
            p.returncode)


def neutral_lines(lines):
    """1-based numbers of the lines that are blank or lie wholly inside comments."""
    out, depth = set(), 0
    for k, l in enumerate(lines, 1):
        t = l.strip()
        start = depth
        code = False
        i = 0
        while i < len(t):
            if t.startswith("/-", i):
                depth += 1; i += 2
            elif t.startswith("-/", i) and depth:
                depth -= 1; i += 2
            elif depth == 0 and t.startswith("--", i):
                break
            else:
                code = code or depth == 0
                i += 1
        if not t or not code:
            out.add(k)
    return out


def git(*args):
    return subprocess.run(("git",) + args, cwd=REPO, stdout=subprocess.PIPE).stdout.decode("utf-8", "replace")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("block"); ap.add_argument("stage", nargs="?", default="check")
    ap.add_argument("--base"); ap.add_argument("--subject", nargs="*", default=[])
    ap.add_argument("--quick", action="store_true"); ap.add_argument("--slack", type=int, default=3)
    ap.add_argument("--record-base", action="store_true"); ap.add_argument("--keep-build", action="store_true")
    a = ap.parse_args()
    block = json.load(open(a.block, encoding="utf-8"))
    base_fp = re.sub(r"\.json$", "", a.block) + ".contract.base"
    short = block["contract"].split(".")[-1]
    if a.record_base:
        fp, ax, rc = fingerprint(block)
        if rc != 0 or not fp:
            sys.exit("cannot fingerprint the contract (is %s built?)" % block["contract_module"])
        open(base_fp, "w", encoding="utf-8").write("\n".join(fp) + "\n")
        print("recorded %d fingerprint lines for %s" % (len(fp), block["contract"]))
        return
    if not a.base:
        sys.exit("--base REF is required")
    # 1. build
    if a.quick:
        p = subprocess.run(isolate() + ["lake", "build"] + block["user_modules"], cwd=REPO,
                           stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        ok_build = p.returncode == 0
        tail = [l for l in p.stdout.decode("utf-8", "replace").splitlines() if l.startswith("error")][:5]
        print("quick build of %d user modules: %s" % (len(block["user_modules"]), "ok" if ok_build else "FAILED"))
        for l in tail:
            print("   " + l[:200])
    else:
        ok_build = bool(a.subject)
        if not a.subject:
            print("no --subject given: nothing to gate")
        for s in a.subject:
            g = subprocess.run([sys.executable, "-I", os.path.join(HERE, "gate.py"), s, "block-%s-%s" % (short[:40], a.stage)]
                               + (["--keep-build"] if a.keep_build else []),
                               env=dict(os.environ, REFOLD_REPO=REPO), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
            print(g.stdout.decode("utf-8", "replace").strip())
            ok_build = ok_build and g.returncode == 0
    ok_contract = ok_local = False
    if ok_build:
        # 2. contract
        fp, ax, rc = fingerprint(block)
        std = bool(ax) and all(set(re.findall(r"[\w.]+", x.split("[", 1)[1])) <= ALLOWED for x in ax)
        ok_contract = rc == 0 and fp == open(base_fp, encoding="utf-8").read().splitlines() and std
        print("contract %s: %s" % (short, "unchanged" if ok_contract else "CHANGED, or axioms differ"))
        # 3. locality: every changed base line is inside a block range (within --slack lines of it),
        #    or is a blank or comment line; an insertion counts at the base line it follows
        bad, cur, neutral = [], None, {}
        for line in git("diff", "-U0", a.base).splitlines():
            m = re.match(r"^--- (?:a/)?(.*)$", line)
            if m:
                cur = m.group(1)
                continue
            m = re.match(r"^\+\+\+ (?:b/)?(.*)$", line)
            if m and cur == "/dev/null":
                cur = m.group(1)
                continue
            m = re.match(r"^@@ -(\d+)(?:,(\d+))? \+", line)
            if m:
                s, n = int(m.group(1)), int(m.group(2) or 1)
                lo, hi = (s, s + n - 1) if n else (s, s)
                rs = block["ranges"].get(cur, [])
                if cur not in neutral:
                    neutral[cur] = neutral_lines(git("show", "%s:%s" % (a.base, cur)).split("\n")) if rs else set()
                out = [x for x in range(lo, hi + 1) if x not in neutral[cur]
                       and not any(r0 - a.slack <= x <= r1 + a.slack for r0, r1 in rs)]
                if out:
                    bad.append("%s:%d-%d" % (cur, out[0], out[-1]))
        ok_local = not bad
        print("locality: %s" % ("all changes inside the block" if ok_local
                                else "changes OUTSIDE the block at base lines %s" % ", ".join(bad[:8])))
        # size
        blk = sum(d["line1"] - d["line0"] + 1 for d in block["declarations"])
        delta = 0
        for f in block["ranges"]:
            now = sum(1 for _ in open(os.path.join(REPO, f), encoding="utf-8")) if os.path.exists(os.path.join(REPO, f)) else 0
            delta += now - (len(git("show", "%s:%s" % (a.base, f)).split("\n")) - 1)
        print("block lines (with blank and comment lines): base %d, now %d" % (blk, blk + delta))
    ok = ok_build and ok_contract and ok_local
    print("BLOCK GATE %s" % ("PASS" if ok else "FAIL"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
