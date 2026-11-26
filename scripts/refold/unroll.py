"""Unroll stage: inline single-use theorems into their only user as local `have` blocks.

A theorem T is a candidate when, in the declaration graph read from the built environment,
exactly one declaration U uses it, U is a theorem, and T does not occur in U's statement.
`theorem T binders : type := body` becomes `have T binders : type := body`, placed at the start
of U's proof (U's proof is turned into a tactic block if it was a term). Section `variable`s that
T's signature mentions are copied in front of its binders, so the local statement is as general
as the original. Inlining is nested: if T's own single-use lemmas were inlined into T, they move
with it.

Not every inline survives elaboration (heartbeat budget of the enlarged declaration, universe
levels, name resolution). The script therefore loops: build, attribute each error to the
innermost inlined lemma covering the error line, undo that inline (or raise the heartbeat limit
of the enclosing declaration when the error is a timeout), rebuild, until the file compiles.

Usage:
  python3 -I unroll.py FILE.lean DEPGRAPH.jsonl --headlines NAME[,NAME...] --build "CMD" \
      [--max-rounds 30] [--report OUT.json] [--skip NAME,...] [--dry-run]
FILE.lean is rewritten in place (keep it under version control). CMD must build the file and
print Lean diagnostics as `...FILE.lean:LINE:COL: error: ...` on stdout or stderr.
"""
import argparse
import json
import os
import re
import subprocess
import sys

OPEN, CLOSE = "([{⟨⦃", ")]}⟩⦄"
KEYWORD = re.compile(r"(?:(?:private|protected|noncomputable|nonrec)\s+)*(theorem|lemma)\s+(\S+)")


def mask(src):
    """Replace comments and string literals by spaces (newlines kept), so that structure can be
    scanned by position. Nested block comments are handled."""
    out, i, n = list(src), 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("--", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif src.startswith("/-", i):
            depth, j = 1, i + 2
            while j < n and depth:
                if src.startswith("/-", j):
                    depth, j = depth + 1, j + 2
                elif src.startswith("-/", j):
                    depth, j = depth - 1, j + 2
                else:
                    j += 1
            for k in range(i, j):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        elif c == '"':
            j = i + 1
            while j < n and src[j] != '"':
                j += 2 if src[j] == "\\" else 1
            for k in range(i + 1, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j + 1
        else:
            i += 1
    return "".join(out)


def sig_end(masked, start=0):
    """Offset of the first `:=` at bracket depth 0 at or after `start`, or -1 (also -1 when a
    top-level `|` alternative comes first: pattern-matching definitions are left alone)."""
    depth, i, n = 0, start, len(masked)
    while i < n:
        c = masked[i]
        if c in OPEN:
            depth += 1
        elif c in CLOSE:
            depth -= 1
        elif depth == 0 and masked.startswith(":=", i):
            return i
        elif depth == 0 and c == "|" and masked[i - 1] == "\n":
            return -1
        i += 1
    return -1


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def shift(text, k):
    pad = " " * k
    return "\n".join((pad + l) if l.strip() else l for l in text.split("\n"))


class Decl:
    def __init__(self, row, lines):
        self.name, self.kind = row["name"], row["kind"]
        self.l0, self.l1 = row["line0"], row["line1"]          # 1-based, inclusive
        self.uses, self.type_uses = row["uses"], row["typeUses"]
        self.text = "\n".join(lines[self.l0 - 1:self.l1])
        self.children = []        # inlined lemma names, in source order
        self.heartbeats = None
        # `X in` lines directly above the declaration belong to it but are outside its range
        self.prefix = []
        i = self.l0 - 2
        while i >= 0 and re.match(r"(omit|open|set_option|include)\b.* in$", lines[i].strip()) and indent_of(lines[i]) == 0:
            self.prefix.insert(0, lines[i].strip())
            i -= 1
        self.l0x = self.l0 - len(self.prefix)
        self.wrap_opens = []      # namespaces/opens to re-open around the inlined block


class Unroller:
    def __init__(self, path, graph_path, headlines, skip):
        self.path = path
        self.src = open(path, encoding="utf-8").read()
        self.lines = self.src.split("\n")
        rows = [json.loads(l) for l in open(graph_path, encoding="utf-8") if l.strip()]
        rows = [r for r in rows if r["line0"] > 0]
        rows.sort(key=lambda r: r["line0"])
        self.decls = {r["name"]: Decl(r, self.lines) for r in rows}
        self.order = [r["name"] for r in rows]
        self.headlines = set(headlines)
        self.users = {n: set() for n in self.decls}
        for d in self.decls.values():
            for u in d.uses:
                if u in self.users:
                    self.users[u].add(d.name)
        # users in other files of a multi-file project (rows may carry "extUsers": count)
        for r in rows:
            for k in range(int(r.get("extUsers", 0))):
                self.users[r["name"]].add("<external %d>" % k)
        self.scopes = self.scan_scopes()
        self.reasons = {}
        self.parent = {}
        self.skip = set(skip)
        self.choose()

    # ---- scopes: namespace/section/open stack and variables in effect at each line -------------
    def scan_scopes(self):
        masked = mask(self.src).split("\n")
        stack = [{"tag": "<file>", "opens": [], "vars": [], "complex": False}]
        at = {}
        i = 0
        while i < len(masked):
            t = masked[i].strip()
            m = re.match(r"(noncomputable\s+)?(namespace|section)\b\s*(\S*)", t)
            if m and indent_of(masked[i]) == 0:
                stack.append({"tag": m.group(2) + " " + m.group(3), "opens": [], "vars": [], "complex": False})
            elif re.match(r"end\b", t) and indent_of(masked[i]) == 0 and len(stack) > 1:
                stack.pop()
            elif re.match(r"open\b", t) and indent_of(masked[i]) == 0 and not t.endswith(" in"):
                stack[-1]["opens"].append(t)
            elif re.match(r"variable\b", t) and indent_of(masked[i]) == 0:
                j = i
                text = self.lines[i]
                while j + 1 < len(masked) and masked[j + 1].startswith(" ") and masked[j + 1].strip():
                    j += 1
                    text += "\n" + self.lines[j]
                groups = self.binder_groups(text[text.index("variable") + len("variable"):])
                if groups is None:
                    stack[-1]["complex"] = True
                else:
                    stack[-1]["vars"] += groups
                i = j
            elif re.match(r"(universe|local|scoped|notation|attribute|omit|include|set_option)\b", t) \
                    and indent_of(masked[i]) == 0 and not t.endswith(" in"):
                stack[-1]["complex"] = stack[-1]["complex"] or t.split()[0] in ("omit", "include")
            ns, cur = [], ""
            for s_ in stack:
                if s_["tag"].startswith("namespace "):
                    for part in s_["tag"][len("namespace "):].split("."):
                        cur = (cur + "." + part) if cur else part
                        ns.append(cur)
            at[i + 1] = {"key": tuple((s["tag"], tuple(s["opens"])) for s in stack),
                         "ns": ns, "opens": [o for s_ in stack for o in s_["opens"]],
                         "vars": [g for s in stack for g in s["vars"]],
                         "complex": any(s["complex"] for s in stack)}
            i += 1
        return at

    @staticmethod
    def binder_groups(text):
        """Split `{a b : T} [C a] (x : U)` into groups; None if a group has no type (update form)."""
        m, groups, i = mask(text), [], 0
        while i < len(m):
            if m[i] in "([{⦃":
                depth, j = 1, i + 1
                while j < len(m) and depth:
                    depth += (m[j] in OPEN) - (m[j] in CLOSE)
                    j += 1
                g = text[i:j]
                inner = g[1:-1]
                if m[i] == "[":
                    names = []
                elif ":" not in mask(inner):
                    return None
                else:
                    names = inner[:mask(inner).index(":")].split()
                groups.append({"text": g, "names": names, "inst": m[i] == "["})
                i = j
            else:
                i += 1
        return groups

    # ---- candidate selection ---------------------------------------------------------------
    def choose(self):
        for name in self.order:
            d = self.decls[name]
            why = self.blocked(d)
            if why:
                self.reasons[name] = why
            else:
                self.parent[name] = next(iter(self.users[name]))
        self.rebuild_children()

    def blocked(self, d):
        if d.kind != "theorem":
            return "not a theorem"
        if d.name in self.headlines:
            return "headline"
        us = self.users[d.name]
        if len(us) != 1:
            return "used by %d declarations" % len(us)
        only = next(iter(us))
        if only not in self.decls:
            return "used in another file"
        u = self.decls[only]
        if u.kind != "theorem":
            return "user is a %s" % u.kind
        if d.name in u.type_uses:
            return "occurs in the user's statement"
        if d.name in self.skip:
            return "skipped by request"
        first = d.text.lstrip()
        if first.startswith("@["):
            return "has attributes"
        mm = mask(d.text)
        k = KEYWORD.search(mm)
        if not k or mm[:k.start()].strip():
            return "unrecognised header"
        if "." in k.group(2):
            return "dotted name"
        for pl in d.prefix:
            if pl.startswith("include"):
                return "has an `include … in` prefix"
            if pl.startswith("omit") and self.binder_groups(pl[len("omit"):-len(" in")]) is None:
                return "has an `omit … in` prefix that is not a list of binders"
            if pl.startswith("set_option") and "maxHeartbeats" not in pl:
                return "has a `set_option … in` prefix"
        if sig_end(mm, k.end()) < 0:
            return "no `:=` (pattern matching)"
        if re.search(r"\b(termination_by|decreasing_by)\b", mm):
            return "recursive"
        short = k.group(2)
        body = mm[sig_end(mm, k.end()):]
        if re.search(r"(?<![\w.'])" + re.escape(short) + r"(?![\w'])", body):
            return "refers to itself"
        mu = mask(u.text)
        ku = KEYWORD.search(mu)
        if not ku or sig_end(mu, ku.end()) < 0:
            return "user has no `:=` (pattern matching)"
        sd, su = self.scopes[d.l0], self.scopes[u.l0]
        if sd["complex"] or su["complex"]:
            return "scope uses omit/include or binder updates"
        need = [n for n in sd["ns"] if n not in su["ns"]]
        opens = [o for o in sd["opens"] if o not in su["opens"]]
        opens += [pl[:-len(" in")] for pl in d.prefix if pl.startswith("open")]
        if need or opens:
            # names in T may resolve through namespaces that are not open at U: re-open them
            # around the inlined block (only possible in a tactic proof)
            rest = mu[sig_end(mu, ku.end()) + 2:].lstrip()
            if not (rest.startswith("by") and not re.match(r"by[\w']", rest)):
                return "user is in a different namespace or open scope and has a term proof"
            if any(re.search(r"\b(hiding|renaming)\b|\(", o) for o in opens):
                return "scope has a selective open"
            d.wrap_opens = (["open " + " ".join(need)] if need else []) + opens
        else:
            d.wrap_opens = []
        return None

    def rebuild_children(self):
        for d in self.decls.values():
            d.children = []
        for name in self.order:
            if name in self.parent:
                self.decls[self.parent[name]].children.append(name)

    # ---- text generation -------------------------------------------------------------------
    def as_have(self, d):
        """Text of d as a `have` block at indentation 0 (children already inlined)."""
        text = self.expanded(d)
        mm = mask(text)
        k = KEYWORD.search(mm)
        short = k.group(2)
        sig = mm[k.end():sig_end(mm, k.end())]
        used = set(re.findall(r"[^\W\d][\w']*", sig))
        extra = []
        included = set()
        omitted = set()
        for pl in d.prefix:
            if pl.startswith("omit"):
                omitted |= {re.sub(r"\s+", "", g["text"]) for g in self.binder_groups(pl[len("omit"):-len(" in")])}
        for g in self.scopes[d.l0]["vars"]:
            if not g["inst"] and any(n in used for n in g["names"]):
                extra.append(g["text"])
                included |= set(g["names"])
                used |= set(re.findall(r"[^\W\d][\w']*", mask(g["text"])))
        all_var_names = {n for g in self.scopes[d.l0]["vars"] for n in g["names"]}
        ordered = []
        for g in self.scopes[d.l0]["vars"]:
            if g["inst"]:
                ids = set(re.findall(r"[^\W\d][\w']*", mask(g["text"]))) & all_var_names
                if ids and ids <= included and re.sub(r"\s+", "", g["text"]) not in omitted:
                    ordered.append(g["text"])
            elif g["text"] in extra:
                ordered.append(g["text"])
        binders = (" " + " ".join(ordered)) if ordered else ""
        e = sig_end(mm, k.end())
        sig_text = re.sub(r"\b(Type|Sort)\*", r"\1 _", text[k.end():e])
        binders = re.sub(r"\b(Type|Sort)\*", r"\1 _", binders)
        block = "have " + short + binders + sig_text + text[e:]
        if d.wrap_opens:
            lines_ = shift(block, 2).split("\n")
            j = len(lines_) - 1
            while not lines_[j].split(self.MARK)[0].strip():
                j -= 1
            parts = lines_[j].split(self.MARK, 1)
            lines_[j] = parts[0].rstrip() + ")" + ((self.MARK + parts[1]) if len(parts) > 1 else "")
            head = "(" + " in\n".join(d.wrap_opens[:-1] + [d.wrap_opens[-1]]) + " in"
            block = head + "\n" + "\n".join(lines_)
        return block, short

    def expanded(self, d):
        """Text of d with its children inlined at the start of its proof."""
        root = d.name not in self.parent
        hb = root and d.heartbeats is not None and not any("maxHeartbeats" in q for q in d.prefix)
        if not d.children:
            return d.text if not hb else "set_option maxHeartbeats %d in\n%s" % (d.heartbeats, d.text)
        text = d.text
        mm = mask(text)
        k = KEYWORD.search(mm)
        e = sig_end(mm, k.end())
        head, rest = text[:e + 2], text[e + 2:]
        rest_m = mm[e + 2:]
        blocks = []
        for c in d.children:
            block, short = self.as_have(self.decls[c])
            blocks.append((c, block, short))
            full = self.decls[c].name
            # qualified references to the lemma inside the user become the local name
            rest = re.sub(r"(?<![\w.'])(?:[\w']+\.)+" + re.escape(short) + r"(?![\w'])",
                          lambda m: short if full.endswith(m.group(0)) else m.group(0), rest)
        rest_m = mask(rest)
        if rest_m.lstrip().startswith("by") and not re.match(r"by[\w']", rest_m.lstrip()):
            b = rest_m.index("by")
            after = rest[b + 2:]
            if rest_m[b + 2:].split("\n", 1)[0].strip():      # `by tac` on the same line
                first, _, tail = after.partition("\n")
                ind = 2
                body_lines = [" " * ind + first.strip()] + ([tail] if tail else [])
                after = "\n" + "\n".join(body_lines)
            else:
                ind = next((indent_of(l) for l in after.split("\n")[1:] if l.strip()), 2)
            have_text = "\n".join(shift(self.tag(c, block), ind) for c, block, _ in blocks)
            new = head + rest[:b + 2] + "\n" + have_text + after
        else:                                                   # term-mode proof: term-mode `have`
            first, nl, tail = rest.partition("\n")
            if first.strip():                                   # term starts on the `:=` line
                ind = 2
                body = " " * ind + first.strip() + (nl + tail if nl else "")
            else:
                ind = next((indent_of(l) for l in tail.split("\n") if l.strip()), 2)
                body = tail
            have_text = "\n".join(shift(self.tag(c, block), ind) for c, block, _ in blocks)
            new = head + "\n" + have_text + "\n" + body
        if hb:
            new = "set_option maxHeartbeats %d in\n%s" % (d.heartbeats, new)
        return new

    MARK = "\u0001"

    def tag(self, name, block):
        """Mark every line of an inlined block with its lemma name (stripped before writing)."""
        return "\n".join(l + self.MARK + name for l in block.split("\n"))

    def render(self):
        out, owner, top, pos = [], [], [], 1
        roots = [n for n in self.order if n not in self.parent]
        removed = {n for n in self.parent}
        for name in self.order:
            d = self.decls[name]
            if d.l0 < pos:
                continue                     # nested inside a previous declaration's range
            gap = self.lines[pos - 1:(d.l0x if name in removed else d.l0) - 1]
            if name in removed and gap and not gap[-1].strip():
                gap = gap[:-1]               # drop one blank line with the removed declaration
            for l in gap:
                out.append(l); owner.append(None); top.append(None)
            if name not in removed:
                for l in self.expanded(d).split("\n"):
                    parts = l.split(self.MARK)
                    out.append(parts[0]); owner.append(parts[1] if len(parts) > 1 else None); top.append(name)
            pos = d.l1 + 1
        for l in self.lines[pos - 1:]:
            out.append(l); owner.append(None); top.append(None)
        return "\n".join(out), owner, top

    def root_of(self, name):
        while name in self.parent:
            name = self.parent[name]
        return name

    def carry_heartbeats(self):
        """`set_option maxHeartbeats N in` on an inlined lemma is applied to the declaration it ends up in."""
        for name in self.parent:
            for pl in self.decls[name].prefix:
                m = re.match(r"set_option maxHeartbeats (\d+) in$", pl)
                if m:
                    r = self.decls[self.root_of(name)]
                    n = int(m.group(1))
                    own = next((int(x.group(1)) for x in (re.match(r"set_option maxHeartbeats (\d+) in$", q) for q in r.prefix) if x), 0)
                    want = 0 if (n == 0 or (own == 0 and any("maxHeartbeats" in q for q in r.prefix))) else max(n, own, r.heartbeats or 0)
                    if not any("maxHeartbeats" in q for q in r.prefix):
                        r.heartbeats = want if want else 0

    def revert(self, name, why):
        self.reasons[name] = "reverted: " + why
        del self.parent[name]
        self.rebuild_children()


def build(cmd, path):
    p = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    out = p.stdout.decode("utf-8", "replace")
    base = os.path.basename(path)
    errs = []
    for m in re.finditer(r"^(?:error: )?\S*" + re.escape(base) + r":(\d+):\d+: (?:error: )?(.*)$", out, re.M):
        head = out[m.start():m.end()]
        if "error" not in head:
            continue
        nxt = re.search(r"^(?:error|warning|info|⚠|✖|✔|ℹ)", out[m.end():], re.M)
        tail = out[m.end():m.end() + (nxt.start() if nxt else 600)]
        errs.append((int(m.group(1)), (m.group(2) + " " + " ".join(tail.split()))[:400]))
    return p.returncode, errs, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("file"); ap.add_argument("graph")
    ap.add_argument("--headlines", required=True); ap.add_argument("--build", default="")
    ap.add_argument("--max-rounds", type=int, default=30); ap.add_argument("--report")
    ap.add_argument("--skip", default=""); ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--retry", action="store_true", help="re-try each reverted inline on its own at the end")
    a = ap.parse_args()
    u = Unroller(a.file, a.graph, a.headlines.split(","), [s for s in a.skip.split(",") if s])
    theorems = [d for d in u.decls.values() if d.kind == "theorem"]
    initial = len(u.parent)
    print("theorems %d, inline candidates %d" % (len(theorems), initial), flush=True)
    rounds, log = 0, []
    while True:
        u.carry_heartbeats()
        text, owner, top = u.render()
        if a.dry_run:
            open(a.file + ".unrolled", "w", encoding="utf-8").write(text)
            break
        open(a.file, "w", encoding="utf-8").write(text)
        rc, errs, out = build(a.build, a.file)
        rounds += 1
        print("round %d: inlined %d, exit %d, errors %d" % (rounds, len(u.parent), rc, len(errs)), flush=True)
        if rc == 0 and not errs:
            break
        if not errs or rounds >= a.max_rounds:
            print(out[-3000:])
            sys.exit("build failed without attributable errors" if not errs else "too many rounds")
        acted = set()
        seen_top = set()
        for line, msg in errs:
            t = top[line - 1] if line - 1 < len(top) else None
            o = owner[line - 1] if line - 1 < len(owner) else None
            if t is None or "unknown constant" in msg:
                continue
            mu = re.match(r"Unknown (?:identifier|constant) `([^`]+)`", msg)
            if mu:
                # a declaration that mentions an inlined lemma in its source without using it in
                # its proof term (so the graph did not list it as a user): undo that inline
                parts = mu.group(1).split(".")
                hit = [n for n in u.parent if any(n.split(".")[-1] == q for q in parts)]
                if hit:
                    for v in hit:
                        if (v, "rv") not in acted:
                            u.revert(v, "mentioned in the source of another declaration"); acted.add((v, "rv"))
                            log.append({"round": rounds, "decl": v, "action": "revert", "in": t, "error": msg[:200]})
                    continue
            if t in seen_top:
                continue                     # later errors in the same declaration are often consequences
            seen_top.add(t)
            if "maximum number of heartbeats" in msg or "deterministic) timeout" in msg:
                d = u.decls[t]
                if (t, "hb") not in acted:
                    d.heartbeats = 400000 if d.heartbeats is None else d.heartbeats * 2
                    acted.add((t, "hb")); log.append({"round": rounds, "decl": t, "action": "heartbeats", "value": d.heartbeats})
                continue
            if o is None:
                # error in the user's own text: undo the children mentioned on that line, else all
                d = u.decls[t]
                src_line = text.split("\n")[line - 1]
                hit = [c for c in d.children if re.search(r"(?<![\w.'])" + re.escape(c.split(".")[-1]) + r"(?![\w'])", src_line)]
                victims = hit or list(d.children)
            else:
                victims = [o]
            for v in victims:
                if v in u.parent and (v, "rv") not in acted:
                    u.revert(v, msg[:80]); acted.add((v, "rv"))
                    log.append({"round": rounds, "decl": v, "action": "revert", "in": t, "error": msg[:400],
                                "source_line": text.split("\n")[line - 1].strip()[:160]})
        if not acted:
            print(out[-3000:])
            sys.exit("errors could not be attributed to an inline")
    # Reverts are attributed by error position and can hit a neighbour of the real culprit:
    # try each reverted candidate once more, on its own, and keep it if the file still builds.
    retried = []
    if a.retry and not a.dry_run:
        for e in list(log):
            n = e["decl"]
            if e["action"] != "revert" or n in u.parent or n in retried:
                continue
            retried.append(n)
            users = u.users[n]
            if len(users) != 1 or next(iter(users)) not in u.decls:
                continue
            saved = dict(u.parent), u.reasons.get(n)
            u.parent[n] = next(iter(users))
            u.rebuild_children()
            u.carry_heartbeats()
            text, owner, top = u.render()
            open(a.file, "w", encoding="utf-8").write(text)
            rc, errs, out = build(a.build, a.file)
            ok = rc == 0 and not errs
            print("retry %s: %s" % (n.split(".")[-1], "kept" if ok else "still fails"), flush=True)
            if ok:
                u.reasons.pop(n, None)
                log.append({"round": "retry", "decl": n, "action": "reinstated"})
            else:
                u.parent = saved[0]
                u.rebuild_children()
        text, owner, top = u.render()
        open(a.file, "w", encoding="utf-8").write(text)
    kept = len(u.parent)
    why = {}
    for n, r in u.reasons.items():
        if u.decls[n].kind == "theorem":
            key = re.sub(r"\d+", "N", r.split(":")[0])
            why[key] = why.get(key, 0) + 1
    rep = {"file": a.file, "theorems_before": len(theorems), "candidates": initial, "inlined": kept,
           "theorems_after": len(theorems) - kept, "rounds": rounds, "not_inlined_reasons": why,
           "heartbeat_raises": {d.name: d.heartbeats for d in u.decls.values() if d.heartbeats},
           "max_nesting": max((len(chain(u, n)) for n in u.parent), default=0), "log": log,
           "inlined_into": {n: p for n, p in u.parent.items()}}
    if a.report:
        json.dump(rep, open(a.report, "w"), indent=1, ensure_ascii=False)
    print(json.dumps({k: v for k, v in rep.items() if k not in ("log", "inlined_into")}, ensure_ascii=False))


def chain(u, n):
    c = []
    while n in u.parent:
        n = u.parent[n]
        c.append(n)
    return c


if __name__ == "__main__":
    main()
