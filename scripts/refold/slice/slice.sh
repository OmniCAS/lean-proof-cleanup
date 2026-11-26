#!/usr/bin/env bash
# Local side of the block workflow on a multi-file project that is built on a remote build server.
# The block's files are edited locally in $REFOLD_SLICES/NAME/files/ (a mirror of the project tree);
# builds and gates run on the server through slice_server.sh.
#   slice.sh NAME pull               fetch the block's files (and the block file) from the server
#   slice.sh NAME build              push changed files; build the modules that use the contract; print errors
#   slice.sh NAME lean REL/PATH      push changed files (scratch files included) and elaborate one file
#   slice.sh NAME gate STAGE         push; block gate on the server (incremental full build, headline gate, contract, locality)
#   slice.sh NAME commit TAG "MSG"   commit and tag the server working copy
#   slice.sh NAME size               block size on the base and now
#   slice.sh NAME rm REL/PATH        delete a scratch file locally and on the server
#   slice.sh NAME fetch REL/PATH     copy any project file into ./ref/ for reading (not pushed back)
#   slice.sh NAME grep REGEX [DIR]   grep the server working copy (Mathlib is under .lake/packages/mathlib/Mathlib)
# Environment: REFOLD_HOST (ssh alias of the build server), REFOLD_REMOTE (workspace directory under the
# remote home, default refold), REFOLD_PROJECT (name under results/), REFOLD_COPY_PREFIX (as in slice.conf),
# REFOLD_SLICES (local directory, default ./slices).
set -uo pipefail
NAME=$1; CMD=${2:-}; shift 2 || true
HOST=${REFOLD_HOST:?set REFOLD_HOST to the ssh alias of the build server}
REMOTE=${REFOLD_REMOTE:-refold}; PROJECT=${REFOLD_PROJECT:?set REFOLD_PROJECT}
SERVER_SCRIPT=${REFOLD_SERVER_SCRIPT:-slice_server.sh}
D="${REFOLD_SLICES:-$PWD/slices}/$NAME"
mkdir -p "$D/files" "$D/.pushed"; cd "$D"
OPTS=(-o BatchMode=yes -o ConnectTimeout=30 -o ServerAliveInterval=30)
RS=$REMOTE/work/${REFOLD_COPY_PREFIX:-$PROJECT-}$NAME
retry() { local n=0; until "$@"; do n=$((n+1)); [ $n -ge 5 ] && return 1; /bin/sleep 15; done; }
remote() { retry ssh "${OPTS[@]}" "$HOST" "~/$REMOTE/$SERVER_SCRIPT $NAME $*"; }
push() {
  (cd files && find . -name '*.lean' | sed 's#^\./##') | while read -r f; do
    if [ ! -f ".pushed/$f" ] || ! cmp -s "files/$f" ".pushed/$f"; then
      retry scp -q "${OPTS[@]}" "files/$f" "$HOST:$RS/$f" < /dev/null || { echo "push failed: $f"; exit 1; }
      mkdir -p ".pushed/$(dirname "$f")"; cp "files/$f" ".pushed/$f"; echo "pushed $f"
    fi
  done
}
case $CMD in
  pull)
    retry scp -q "${OPTS[@]}" "$HOST:$REMOTE/results/$PROJECT/blocks/$NAME.json" block.json
    python3 -I -c "import json; print('\n'.join(json.load(open('block.json'))['ranges']))" > files.txt
    while read -r f; do
      mkdir -p "files/$(dirname "$f")" ".pushed/$(dirname "$f")"
      retry scp -q "${OPTS[@]}" "$HOST:$RS/$f" "files/$f" < /dev/null; cp "files/$f" ".pushed/$f"
    done < files.txt
    echo "pulled $(wc -l < files.txt | tr -d ' ') files into $D/files" ;;
  build) push; remote build ;;
  lean) push; remote lean "$1" ;;
  gate) push; remote gate "$1" ;;
  commit) push; remote commit "$1" "'$2'" ;;
  size) remote size ;;
  rm) rm -f "files/$1" ".pushed/$1"; remote rm "$(printf %q "$1")" ;;
  fetch) mkdir -p "ref/$(dirname "$1")"; retry scp -q "${OPTS[@]}" "$HOST:$RS/$1" "ref/$1" && echo "fetched $D/ref/$1" ;;
  grep) remote grep "$(printf %q "$1")" "$(printf %q "${2:-.}")" ;;
  *) echo "usage: slice.sh NAME pull|build|lean FILE|gate STAGE|commit TAG MSG|size|rm FILE|fetch FILE|grep REGEX [DIR]"; exit 2 ;;
esac
