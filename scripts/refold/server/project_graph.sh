#!/usr/bin/env bash
# Declaration graph of a built project, from its environment.
# Usage: project_graph.sh WORKSPACE NAME TOOLCHAIN_DIR CPUSET LIBS OUTPREFIX ROOT_DECL [ROOT_DECL...]
#   LIBS       comma-separated top-level module prefixes that make up the project (e.g. NavierStokes,Euler)
#   OUTPREFIX  writes OUTPREFIX.jsonl (graph) and OUTPREFIX.summary.json
# Imports every built module under LIBS (so unreachable declarations are counted too).
set -euo pipefail
WS=$1; NAME=$2; TC=$3; CPUS=$4; LIBS=$5; OUT=$6; shift 6
ROOT="$WS/work/$NAME"; export PATH="$TC/bin:$PATH"
TMP="$WS/tools/graph-$NAME.lean"; mkdir -p "$WS/tools"
cd "$ROOT"
: > "$TMP.imports"
for lib in ${LIBS//,/ }; do
  for base in .lake/build/lib/lean .lake/packages/*/.lake/build/lib/lean; do
    [ -d "$base" ] || continue
    ( cd "$base" && find . -name '*.olean' ! -name '*.server.olean' ! -name '*.private.olean' \
        \( -path "./$lib/*" -o -path "./$lib.olean" \) | sed -e 's#^\./##' -e 's#\.olean$##' -e 's#/#.#g' ) >> "$TMP.imports"
  done
done
sort -u "$TMP.imports" | sed 's/^/import /' > "$TMP"
sed -e '/^import Lean$/d' "$WS/tools/ProjectGraph.lean" >> "$TMP"
PREF=$(echo "$LIBS" | sed -e 's/,/, `/g' -e 's/^/`/')
echo "#eval ProjectGraph.dump [$PREF] \"$OUT.jsonl\"" >> "$TMP"
# `import` lines must come first: move the tool's own header comment below them is unnecessary,
# Lean accepts comments only after imports, so strip the leading block comment of the tool.
python3 - "$TMP" <<'PY'
import re, sys
p = sys.argv[1]; s = open(p, encoding="utf-8").read()
imports = re.findall(r"^import .*$", s, re.M)
body = re.sub(r"^import .*\n", "", s, flags=re.M)
open(p, "w", encoding="utf-8").write("\n".join(imports) + "\nimport Lean\n" + body)
print("modules imported:", len(imports))
PY
START=$(date +%s)
unshare -r -n taskset -c "$CPUS" nice -n 10 lake env lean "$TMP" 2>&1 | grep -v "^$" | tail -5
echo "graph seconds: $(( $(date +%s) - START ))"
python3 "$WS/tools/graph_summary.py" "$OUT.jsonl" "$OUT.summary.json" "$@"
