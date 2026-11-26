"""Compare Lean source trees: line classes, tactic use, declaration names, proof lengths.

Usage: python3 -I compare_versions.py OUT.json LABEL=SRC_DIR [LABEL=SRC_DIR ...]
Reads .lean files only; nothing is executed. The last tree may be large (streamed file by file).
"""
import collections
import json
import os
import re
import sys

DECL = re.compile(
    r"^\s*(?:@\[[^\]]*\]\s*)*(?:(?:private|protected|noncomputable|nonrec|scoped|local|unsafe|partial)\s+)*"
    r"(theorem|lemma|def|abbrev|structure|class|inductive|instance)\b\s*([^\s:({\[⦃]*)")
TACTICS = ["grind", "simp", "simp_all", "simpa", "omega", "linarith", "nlinarith", "positivity", "norm_num",
           "ring", "ring_nf", "field_simp", "field", "aesop", "exact", "refine", "apply", "intro", "intros",
           "rw", "rwa", "have", "obtain", "rcases", "rintro", "calc", "constructor", "use", "ext", "congr",
           "gcongr", "grw", "bound", "fun_prop", "decide", "tauto", "show", "unfold", "change", "convert",
           "induction", "cases", "by_contra", "infer_instance", "norm_cast", "push_cast", "exact_mod_cast",
           "mod_cast", "specialize", "by_cases", "subst", "filter_upwards", "trans", "nth_rewrite", "erw",
           "native_decide", "sorry", "by", "fun", "set_option"]
TAC_RE = re.compile(r"(?<![\w.'])(" + "|".join(sorted(TACTICS, key=len, reverse=True)) + r")(?![\w'?!])")
STRUCT_RE = re.compile(r"^(namespace|end|open|section|variable|universe|noncomputable section|public section|"
                       r"set_option|attribute|export|include|omit|@\[expose\] public section|module)\b")


BLOCK = re.compile(r"/-.*?-/", re.S)
LINE = re.compile(r"--[^\n]*")


def strip_comments(s):
    """Blank out comments, keeping line numbers. Nested block comments are treated as flat."""
    s = BLOCK.sub(lambda m: "\n" * m.group(0).count("\n"), s)
    return LINE.sub("", s)


def scan(root, keep_names=None):
    st = collections.Counter()
    tac = collections.Counter()
    names = collections.Counter()
    kinds = collections.Counter()
    proof_len = collections.Counter()   # bucketed theorem lengths
    decls_per_file = collections.Counter()
    where = {}
    thm_lines_total = 0
    for d, _, fs in os.walk(root):
        for f in sorted(fs):
            if not f.endswith(".lean"):
                continue
            p = os.path.join(d, f)
            raw = open(p, encoding="utf-8", errors="replace").read()
            st["files"] += 1
            st["bytes"] += len(raw.encode("utf-8", "replace"))
            lines = raw.split("\n")
            st["lines"] += len(lines)
            code = strip_comments(raw)
            clines = code.split("\n")
            cur = None
            ndecl = 0
            for i, l in enumerate(clines):
                t = l.strip()
                if not t:
                    if lines[i].strip() if i < len(lines) else False:
                        st["comment_lines"] += 1
                    else:
                        st["blank_lines"] += 1
                    continue
                if re.match(r"^(public |private |meta )*import\b", t):
                    st["import_lines"] += 1
                    continue
                if STRUCT_RE.match(t):
                    st["scaffold_lines"] += 1
                    continue
                st["code_lines"] += 1
                m = DECL.match(l)
                if m:
                    if cur and cur[0] in ("theorem", "lemma"):
                        n_ = i - cur[1]
                        thm_lines_total += n_
                        proof_len[min(n_, 200) // 5 * 5 if n_ > 10 else n_] += 1
                    kind, name = m.group(1), m.group(2)
                    kinds[kind] += 1
                    ndecl += 1
                    cur = (kind, i)
                    if name:
                        short = name.split(".")[-1]
                        names[short] += 1
                        if keep_names is not None and short in keep_names and short not in where:
                            where[short] = (os.path.relpath(p, root), i + 1)
                for m2 in TAC_RE.finditer(l):
                    tac[m2.group(1)] += 1
                st["semicolon_chains"] += l.count("<;>")
                st["bullets"] += 1 if t.startswith("·") else 0
            if cur and cur[0] in ("theorem", "lemma"):
                n_ = len(clines) - cur[1]
                thm_lines_total += n_
                proof_len[min(n_, 200) // 5 * 5 if n_ > 10 else n_] += 1
            decls_per_file[min(ndecl, 20)] += 1
    st["theorem_lines_total"] = thm_lines_total
    return dict(stats=dict(st), tactics=dict(tac), kinds=dict(kinds), proof_len={str(k): v for k, v in sorted(proof_len.items())},
                decls_per_file={str(k): v for k, v in sorted(decls_per_file.items())}), names, where


def main():
    out = sys.argv[1]
    trees = [a.split("=", 1) for a in sys.argv[2:]]
    res, nameset = {}, {}
    # small trees first, so that the large one only records where their names occur
    for label, root in trees[:-1]:
        r, names, _ = scan(root)
        res[label] = r
        nameset[label] = names
    keep = set()
    for names in nameset.values():
        keep |= set(names)
    label, root = trees[-1]
    r, names, where = scan(root, keep)
    res[label] = r
    nameset[label] = names
    res["names"] = {}
    for a in nameset:
        res["names"][a] = dict(distinct=len(nameset[a]), total=sum(nameset[a].values()),
                               duplicated_names=sum(1 for v in nameset[a].values() if v > 1),
                               top_dupes=nameset[a].most_common(8))
    labels = list(nameset)
    for i, a in enumerate(labels):
        for b in labels[i + 1:]:
            res["names"][a + "∩" + b] = len(set(nameset[a]) & set(nameset[b]))
    res["where_in_" + label] = where
    for a in labels[:-1]:
        res["shared_with_" + label + "_" + a] = sorted(n for n in nameset[a] if n in nameset[label] and len(n) >= 14)[:4000]
    json.dump(res, open(out, "w", encoding="utf-8"), ensure_ascii=False)
    print("wrote", out)


if __name__ == "__main__":
    main()
