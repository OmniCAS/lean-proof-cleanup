"""Source-level estimate of how often each theorem of a tree is referenced (by short name).

Usage: python3 -I scripts/reference_counts.py LABEL=DIR [...]
Approximate: counts occurrences of a declaration's last name component as a token anywhere in the
tree; duplicate short names and namespaces blur it. The exact count needs a built environment.
"""
import collections
import os
import re
import sys

DECL = re.compile(r"^(?:@\[[^\]]*\]\s*)*(?:(?:private|protected|noncomputable|nonrec|scoped|local|unsafe|partial)\s+)*"
                  r"(theorem|lemma|def|abbrev|structure|class|inductive|instance)\s+([^\s:({\[⦃]+)", re.M)
TOK = re.compile(r"[A-Za-z_][A-Za-z0-9_'!?]*")

for a in sys.argv[1:]:
    label, root = a.split("=", 1)
    tok = collections.Counter()
    decls = []
    for d, dirs, fs in os.walk(root):
        dirs[:] = [x for x in dirs if x not in (".lake", ".git")]
        for f in fs:
            if f.endswith(".lean"):
                s = open(os.path.join(d, f), encoding="utf-8", errors="replace").read()
                s = re.sub(r"/-.*?-/", "", s, flags=re.S)
                s = re.sub(r"--[^\n]*", "", s)
                tok.update(TOK.findall(s))
                decls += [(m.group(1), m.group(2).split(".")[-1]) for m in DECL.finditer(s)]
    names = collections.Counter(n for _, n in decls)
    th = [n for k, n in decls if k in ("theorem", "lemma")]
    uniq = [n for n in th if names[n] == 1]
    z = sum(1 for n in uniq if tok[n] <= 1)
    o = sum(1 for n in uniq if tok[n] == 2)
    m = sum(1 for n in uniq if tok[n] >= 3)
    print("%-16s theorems %6d (unique short names %6d) | never referenced %5.1f%% | referenced once %5.1f%% | "
          "twice or more %5.1f%% | duplicated short names %d" % (
              label, len(th), len(uniq), 100 * z / len(uniq), 100 * o / len(uniq), 100 * m / len(uniq),
              len(th) - len(uniq)))
