#!/usr/bin/env python3
"""Reduce the raw output of compare_versions.py to per-version counts.

The raw JSON also lists declaration names from each tree; the summary keeps only counts, so
it can be published even when a tree carries no licence.

Usage: python3 scripts/summarize_versions.py RAW.json data/versions_summary.json
"""
import json
import sys

TACTICS = ["have", "rw", "exact", "intro", "unfold", "calc", "simp", "simpa", "simp_all", "grind",
           "aesop", "grw", "fun_prop", "field", "bound", "omega", "linarith", "nlinarith", "ring",
           "norm_num", "decide"]


def summarize(v):
    st, kinds = v["stats"], v["kinds"]
    thms = kinds.get("theorem", 0) + kinds.get("lemma", 0)
    decls = sum(kinds.values())
    code = st["code_lines"]
    out = {
        "files": st["files"],
        "bytes": st["bytes"],
        "lines": st["lines"],
        "code_lines": code,
        "import_lines": st.get("import_lines", 0),
        "scaffold_lines": st.get("scaffold_lines", 0),
        "comment_lines": st.get("comment_lines", 0),
        "blank_lines": st.get("blank_lines", 0),
        "theorems_and_lemmas": thms,
        "declarations": decls,
        "declarations_by_kind": kinds,
        "lines_per_theorem": round(st["theorem_lines_total"] / thms, 1) if thms else None,
        "declarations_per_file": round(decls / st["files"], 1),
        "single_declaration_files_share": round(v["decls_per_file"].get("1", 0) / st["files"], 3),
        "import_share_of_lines": round(st.get("import_lines", 0) / st["lines"], 3),
        "comment_share_of_lines": round(st.get("comment_lines", 0) / st["lines"], 3),
        "bullets_per_kloc": round(1000 * st.get("bullets", 0) / code, 1),
        "tactics_per_kloc": {t: round(1000 * v["tactics"].get(t, 0) / code, 1) for t in TACTICS},
    }
    return out


def main():
    raw = json.load(open(sys.argv[1], encoding="utf-8"))
    versions = [k for k, v in raw.items() if isinstance(v, dict) and "stats" in v]
    res = {
        "definition": "counts from compare_versions.py over the .lean files of each tree; "
                      "code lines exclude comments, blank lines, imports and namespace/open/"
                      "section/variable/set_option lines; tactics are counted by word match "
                      "in code lines",
        "versions": {k: summarize(raw[k]) for k in versions},
        "names": {k: {"distinct": v["distinct"], "duplicated": v["duplicated_names"]}
                  for k, v in raw["names"].items() if isinstance(v, dict)},
        "shared_names": {k: v for k, v in raw["names"].items() if isinstance(v, int)},
    }
    json.dump(res, open(sys.argv[2], "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("wrote", sys.argv[2])


if __name__ == "__main__":
    main()
