#!/usr/bin/env bash
# Fetch prebuilt Mathlib oleans for a project laid out by setup_project.py.
# Usage: cache_get.sh WORKSPACE NAME TOOLCHAIN_DIR [CPUSET]
# Mathlib's cache tool refuses to run when the project manifest pins dependencies at other
# revisions than Mathlib's manifest; our manifest names local snapshot commits (same content,
# different commit ids). So: build the tool and capture Lake's environment with the snapshot
# manifest, then run the tool directly with the upstream manifest swapped in, then swap back.
# Hashes are computed from file contents, which are identical to upstream.
set -euo pipefail
WS=$1; NAME=$2; TC=$3; CPUS=${4:-32-63}
ROOT="$WS/work/$NAME"; cd "$ROOT"
export PATH="$TC/bin:$PATH"
export MATHLIB_CACHE_DIR="$WS/mathlib-cache"; mkdir -p "$MATHLIB_CACHE_DIR"
taskset -c "$CPUS" nice -n 10 lake build cache > "$WS/logs/cache-$NAME.log" 2>&1
lake env printenv > "$WS/logs/cache-$NAME.env"
restore() { cp lake-manifest.snapshot.json lake-manifest.json; }
cp lake-manifest.json lake-manifest.snapshot.json
trap restore EXIT
cp lake-manifest.upstream.json lake-manifest.json
set +e
env -i HOME="$HOME" MATHLIB_CACHE_DIR="$MATHLIB_CACHE_DIR" $(grep -E '^(PATH|LEAN_PATH|LEAN_SRC_PATH|LEAN_SYSROOT|LEAN_AR|LEAN_CC|LEAN|LAKE|LAKE_HOME|LAKE_CACHE_DIR|LD_LIBRARY_PATH|ELAN_TOOLCHAIN)=' "$WS/logs/cache-$NAME.env" | tr '\n' ' ') \
  taskset -c "$CPUS" nice -n 10 .lake/packages/mathlib/.lake/build/bin/cache get >> "$WS/logs/cache-$NAME.log" 2>&1
RC=$?
set -e
restore; trap - EXIT
N=$(find .lake/packages/mathlib/.lake/build/lib/lean/Mathlib -name '*.olean' 2>/dev/null | wc -l)
tail -4 "$WS/logs/cache-$NAME.log" | cut -c1-200
echo "CACHE_DONE $NAME rc=$RC mathlib_oleans=$N"
