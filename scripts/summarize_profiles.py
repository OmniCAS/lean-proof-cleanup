#!/usr/bin/env python3
"""Reduce the raw output of profile_lean_trees.py to per-tree counts and indicators.

The raw JSON also lists declaration names from each tree; the summary keeps only counts, so
it can be published even when a tree carries no licence.

Usage: python3 scripts/summarize_profiles.py --out data/tree_profiles.json --csv data/tree_profiles.csv RAW.json [RAW.json ...]
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
        "named_prop_definitions": st.get("prop_defs", 0),
        "option_overrides": st.get("option_overrides", 0),
        "option_overrides_per_kloc": round(1000 * st.get("option_overrides", 0) / code, 2),
        "tactics_per_kloc": {t: round(1000 * v["tactics"].get(t, 0) / code, 1) for t in TACTICS},
    }
    return out


def main():
    import argparse
    ap = argparse.ArgumentParser(description="Summarize profile_lean_trees.py output.")
    ap.add_argument("--out", required=True)
    ap.add_argument("--csv")
    ap.add_argument("raw", nargs="+")
    a = ap.parse_args()
    res = {
        "definition": "counts from profile_lean_trees.py over the .lean files of each tree; "
                      "code lines exclude comments, blank lines, imports and namespace/open/"
                      "section/variable/set_option lines; tactics are counted by word match "
                      "in code lines; named Prop definitions are single-line `def X ... : Prop :=`; "
                      "option overrides are set_option maxHeartbeats/maxRecDepth/synthInstance.*/"
                      "backward.* lines",
        "versions": {}, "names": {}, "shared_names": {},
    }
    for path in a.raw:
        raw = json.load(open(path, encoding="utf-8"))
        for k, v in raw.items():
            if isinstance(v, dict) and "stats" in v:
                res["versions"][k] = summarize(v)
        for k, v in raw.get("names", {}).items():
            if isinstance(v, dict):
                res["names"][k] = {"distinct": v["distinct"], "duplicated": v["duplicated_names"]}
            elif isinstance(v, int):
                res["shared_names"][k] = v
    for k, v in res["versions"].items():
        n = res["names"].get(k)
        if n:
            v["repeated_name_share"] = round(n["duplicated"] / n["distinct"], 3) if n["distinct"] else None
    json.dump(res, open(a.out, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print("wrote", a.out)
    if a.csv:
        cols = ["files", "code_lines", "theorems_and_lemmas", "lines_per_theorem",
                "declarations_per_file", "single_declaration_files_share", "import_share_of_lines",
                "comment_share_of_lines", "named_prop_definitions", "option_overrides_per_kloc",
                "repeated_name_share"]
        tac = ["have", "rw", "exact", "simp", "simp_all", "grind", "aesop", "omega"]
        with open(a.csv, "w", encoding="utf-8") as f:
            f.write(",".join(["tree"] + cols + [f"{t}_per_kloc" for t in tac]) + "\n")
            for k, v in res["versions"].items():
                row = [k] + [str(v.get(c, "")) for c in cols] + [str(v["tactics_per_kloc"].get(t, "")) for t in tac]
                f.write(",".join(row) + "\n")
        print("wrote", a.csv)


if __name__ == "__main__":
    main()
