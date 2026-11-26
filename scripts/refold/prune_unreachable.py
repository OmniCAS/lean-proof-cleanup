"""Mechanical stage for a whole project: delete declarations the headline theorems do not reach.

Input is the declaration graph written by lean/ProjectGraph.lean (one line per user-level
declaration: module, line range, the project declarations its type or body mentions). Everything
outside the closure of the root declarations is removed from the source files. Because the graph
is read from proof terms, it cannot see a name that is only *mentioned* in source (an unused
`simp` argument, an `attribute [...]` line, a `deriving` clause, notation). So:

  1. before deleting, a declaration is kept if its short name still occurs as a token in the
     source that would remain (in its own module or in a module that imports it), or if it
     carries an attribute (`@[simp]`, `@[ext]`, `@[fun_prop]`, …): a `simp` lemma proved by `rfl`
     rewrites definitionally and leaves no trace in the proof terms that used it;
  2. after deleting, the project is built; every declaration named in an "unknown identifier /
     constant" error is restored together with everything it needs, other errors restore the
     deleted declarations around the error line; this repeats until the build passes.

Usage:
  python3 prune_unreachable.py PROJECT_DIR GRAPH.jsonl --roots NAME [NAME ...] --build "CMD"
      [--max-rounds 12] [--report OUT.json] [--dry-run]
PROJECT_DIR holds the source tree (module A.B.C is PROJECT_DIR/A/B/C.lean); files are rewritten
in place, so keep the tree under version control. CMD builds the project and prints Lean
diagnostics as `error: PATH.lean:LINE:COL: message`.
"""
import argparse
import collections
import json
import os
import re
import subprocess
import sys

IMPORT = re.compile(r"^\s*(?:public\s+|private\s+|meta\s+)*import\s+(?:all\s+)?([\w.«»']+)", re.M)
TOKEN = re.compile(r"[^\W\d][\w'!?]*")


def strip_comments(s):
    s = re.sub(r"/-.*?-/", lambda m: "\n" * m.group(0).count("\n"), s, flags=re.S)
    return re.sub(r"--[^\n]*", "", s)


class Project:
    def __init__(self, root, graph_path, roots):
        self.root = root
        self.rows = [json.loads(l) for l in open(graph_path, encoding="utf-8") if l.startswith("{")]
        self.by_i = {r["i"]: r for r in self.rows}
        name_i = {r["n"]: r["i"] for r in self.rows}
        missing = [n for n in roots if n not in name_i]
        if missing:
            sys.exit("root declarations not in the graph: %s" % missing)
        self.reach, st = set(), [name_i[n] for n in roots]
        while st:
            x = st.pop()
            if x not in self.reach:
                self.reach.add(x)
                st += self.by_i[x]["u"]
        self.files, self.src = {}, {}
        for r in self.rows:
            m = r["m"]
            if m not in self.files:
                p = os.path.join(root, m.replace(".", os.sep) + ".lean")
                self.files[m] = p
                self.src[m] = open(p, encoding="utf-8").read().split("\n")
        self.by_mod = collections.defaultdict(list)
        for r in self.rows:
            self.by_mod[r["m"]].append(r)
        # extend each range upward over `… in` prefix lines; mark declarations inside `mutual`
        for m, rs in self.by_mod.items():
            lines = self.src[m]
            mutual, depth = set(), 0
            for i, l in enumerate(lines):
                t = l.strip()
                if t == "mutual" and not l.startswith(" "):
                    depth += 1
                elif depth and t == "end" and not l.startswith(" "):
                    depth -= 1
                if depth:
                    mutual.add(i + 1)
            for r in rs:
                i = r["l0"] - 2
                while i >= 0 and re.match(r"(omit|open|set_option|include)\b.* in$", lines[i].strip()) \
                        and not lines[i].startswith(" "):
                    i -= 1
                r["x0"] = i + 2
                r["mutual"] = r["l0"] in mutual
        self.imports = {}
        for m, lines in self.src.items():
            self.imports[m] = [x for x in IMPORT.findall("\n".join(lines)) if x in self.src]
        self.keep = set(self.reach)          # indices that stay
        self.why_kept = {}

    def closure_keep(self, i, why):
        st = [i]
        while st:
            x = st.pop()
            if x in self.keep:
                continue
            self.keep.add(x)
            self.why_kept[x] = why
            st += self.by_i[x]["u"]

    def importers(self):
        """module -> set of modules that import it, transitively (including itself)."""
        rev = collections.defaultdict(set)
        for m, ims in self.imports.items():
            for i in ims:
                rev[i].add(m)
        out = {}
        for m in self.src:
            seen, st = {m}, [m]
            while st:
                for y in rev[st.pop()]:
                    if y not in seen:
                        seen.add(y)
                        st.append(y)
            out[m] = seen
        return out

    def pre_keep(self):
        """Keep unreachable declarations whose short name is still mentioned in remaining source."""
        for r in self.rows:
            if r["mutual"] and r["i"] not in self.keep:
                self.closure_keep(r["i"], "inside a mutual block")
        for r in self.rows:
            if r["i"] in self.keep:
                continue
            head = "\n".join(self.src[r["m"]][r["x0"] - 1:r["l0"] + 3])
            head = re.sub(r"/--.*?-/", "", head, flags=re.S).lstrip()
            if head.startswith("@["):
                self.closure_keep(r["i"], "has an attribute")
        down = self.importers()
        changed = True
        while changed:
            changed = False
            index = collections.defaultdict(set)      # token -> modules whose remaining text has it
            for m in self.src:
                text, _ = self.render(m)
                for t in set(TOKEN.findall(strip_comments(text))):
                    index[t].add(m)
            for r in self.rows:
                if r["i"] in self.keep:
                    continue
                short = r["n"].split(".")[-1]
                if index.get(short) and (index[short] & down[r["m"]]):
                    self.closure_keep(r["i"], "name still mentioned in source")
                    changed = True

    def render(self, m):
        """Text of module m without the deleted declarations, and a map new line -> old line."""
        lines = self.src[m]
        drop = set()
        for r in self.by_mod[m]:
            if r["i"] not in self.keep:
                rng = range(r["x0"], r["l1"] + 1)
                drop.update(rng)
                nxt = r["l1"] + 1
                if nxt <= len(lines) and not lines[nxt - 1].strip() and (r["x0"] < 2 or not lines[r["x0"] - 2].strip()):
                    drop.add(nxt)             # one of two blank lines around a removed declaration
        out, back = [], []
        for i, l in enumerate(lines, 1):
            if i not in drop:
                out.append(l)
                back.append(i)
        return "\n".join(out), back

    def write(self):
        self.back = {}
        for m, p in self.files.items():
            text, back = self.render(m)
            self.back[m] = back
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(text)

    def restore_original(self):
        for m, p in self.files.items():
            with open(p, "w", encoding="utf-8") as fh:
                fh.write("\n".join(self.src[m]))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("project"); ap.add_argument("graph")
    ap.add_argument("--roots", nargs="+", required=True); ap.add_argument("--build", default="")
    ap.add_argument("--max-rounds", type=int, default=12); ap.add_argument("--report")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--keep-list", help="file of declaration names to keep (read at start, rewritten after every round); "
                                        "lets an interrupted run resume from the original sources")
    a = ap.parse_args()
    pr = Project(os.path.abspath(a.project), a.graph, a.roots)
    if a.keep_list and os.path.exists(a.keep_list):
        names = {l.strip() for l in open(a.keep_list, encoding="utf-8") if l.strip()}
        for r in pr.rows:
            if r["n"] in names:
                pr.closure_keep(r["i"], "kept by an earlier run")
    total = len(pr.rows)
    print("declarations %d, reachable %d, unreachable %d" % (total, len(pr.reach), total - len(pr.reach)))
    pr.pre_keep()
    print("kept although unreachable (mentioned in source, attribute, mutual block, earlier run): %d" % (len(pr.keep) - len(pr.reach)))
    path_mod = {os.path.relpath(p, pr.root): m for m, p in pr.files.items()}
    rounds, log, level = 0, [], {}
    if not a.dry_run:
        while True:
            pr.write()
            if not a.build:
                break
            p = subprocess.run(a.build, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=pr.root)
            out = p.stdout.decode("utf-8", "replace")
            rounds += 1
            errs = re.findall(r"^error: (\S+?\.lean):(\d+):\d+: (.*)$", out, re.M)
            print("round %d: deleted %d, exit %d, errors %d" % (rounds, total - len(pr.keep), p.returncode, len(errs)), flush=True)
            if p.returncode == 0 and not errs:
                break
            if rounds >= a.max_rounds or not errs:
                print(out[-3000:])
                sys.exit("build failed and could not be repaired automatically")
            before = len(pr.keep)
            by_short = collections.defaultdict(list)
            for r in pr.rows:
                if r["i"] not in pr.keep:
                    by_short[r["n"].split(".")[-1]].append(r["i"])
            for path, line, msg in errs:
                m = path_mod.get(os.path.normpath(path))
                names = re.findall(r"`([^`]+)`", msg) if re.search(r"[Uu]nknown|not found|Invalid field|does not contain", msg) else []
                hit = False
                for nm in names:
                    for part in reversed(nm.split(".")):
                        for i in by_short.get(part, []):
                            pr.closure_keep(i, "build error: " + msg[:60])
                            hit = True
                        if hit:
                            break
                if hit or m is None:
                    continue
                # another kind of error (a proof that no longer goes through): something it relied
                # on implicitly was deleted. Restore, in widening circles on repeated failure, the
                # deleted declarations of this module, of the modules it imports, of everything
                # it imports transitively.
                level[m] = level.get(m, 0) + 1
                scope = {m}
                if level[m] >= 2:
                    scope |= set(pr.imports[m])
                if level[m] >= 3:
                    st = list(pr.imports[m])
                    while st:
                        x = st.pop()
                        if x not in scope:
                            scope.add(x)
                        for y in pr.imports[x]:
                            if y not in scope:
                                scope.add(y); st.append(y)
                for mm in scope:
                    for r in pr.by_mod[mm]:
                        if r["i"] not in pr.keep:
                            pr.closure_keep(r["i"], "build error in a dependent proof: " + msg[:40])
            log.append({"round": rounds, "errors": len(errs), "restored": len(pr.keep) - before})
            if a.keep_list:
                with open(a.keep_list, "w", encoding="utf-8") as fh:
                    fh.write("\n".join(sorted(pr.by_i[i]["n"] for i in pr.keep if i not in pr.reach)) + "\n")
            if len(pr.keep) == before:
                print(out[-3000:])
                sys.exit("errors could not be attributed to a deleted declaration")
    deleted = [r for r in pr.rows if r["i"] not in pr.keep]
    kinds = collections.Counter(r["k"] for r in deleted)
    why = collections.Counter(re.sub(r":.*", "", w) for w in pr.why_kept.values())
    empty = 0
    for m in pr.src:
        text, _ = pr.render(m)
        body = [l for l in strip_comments(text).split("\n")
                if l.strip() and not re.match(r"\s*(import|open|namespace|section|end|noncomputable section|variable|universe|set_option)\b", l)]
        empty += not body
    rep = {"declarations": total, "reachable": len(pr.reach), "deleted": len(deleted), "deleted_by_kind": dict(kinds),
           "kept_although_unreachable": len(pr.keep) - len(pr.reach), "kept_reasons": dict(why),
           "source_lines_deleted": sum(r["l1"] - r["x0"] + 1 for r in deleted),
           "modules": len(pr.src), "modules_left_without_declarations": empty, "rounds": rounds, "log": log}
    if a.report:
        json.dump(rep, open(a.report, "w"), indent=1)
    print(json.dumps({k: v for k, v in rep.items() if k != "log"}))


if __name__ == "__main__":
    main()
