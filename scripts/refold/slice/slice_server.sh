#!/usr/bin/env bash
# Server side of the block workflow on a multi-file project: one working copy per block.
# Reads slice.conf next to this script (see slice.conf.example).
# Usage: slice_server.sh NAME setup CONTRACT CPUS [--free-dead-users]
#                                                   copy the project at the base tag, write the block file, record the contract
#        slice_server.sh NAME build                 build the modules that use the contract; print the errors
#        slice_server.sh NAME lean REL/PATH.lean    elaborate one file of the working copy (scratch files)
#        slice_server.sh NAME gate STAGE            block gate: incremental full build, headline gate, contract, locality
#        slice_server.sh NAME commit TAG "MESSAGE"  commit the working copy and tag it
#        slice_server.sh NAME size                  block size on the base and now
#        slice_server.sh NAME rm Scratch*.lean      remove a scratch file
#        slice_server.sh NAME grep REGEX [DIR]      grep the working copy
set -uo pipefail
NAME=$1; CMD=$2; shift 2
. "$(dirname "$0")/slice.conf"   # WS, PROJECT, TOOLCHAIN, BASE_REF, GRAPH, ROOTS, COPY_PREFIX, SUBJECT_OF
T=$WS/tools/refold; BASE=$WS/work/$PROJECT; R=$WS/work/$COPY_PREFIX$NAME
BD=$WS/results/$PROJECT/blocks; B=$BD/$NAME.json
export PATH=$TOOLCHAIN/bin:$PATH LEAN_NUM_THREADS=${LEAN_NUM_THREADS:-16}
if [ "$CMD" = setup ]; then
  CONTRACT=$1; CPUS=$2; EXTRA=${3:-}
  mkdir -p $BD/$NAME-out; echo "$CPUS" > $BD/$NAME.cpus
  python3 -I $T/dominators.py $GRAPH $BD/$NAME.dom.json --roots $ROOTS --top 0 \
     --show "$CONTRACT" --block $B $EXTRA | grep -vE "^reachable"
  if [ ! -d $R ]; then
    # sources and the project's own build products are copied; the dependencies' build products are shared
    mkdir -p $R/.lake
    rsync -a --exclude .lake $BASE/ $R/
    rsync -a $BASE/.lake/build $R/.lake/
    ln -s $BASE/.lake/packages $R/.lake/packages
  fi
  [ -f $WS/results/$PROJECT/frozen.sha256 ] && cp $WS/results/$PROJECT/frozen.sha256 $BD/$NAME-out/frozen.sha256
fi
CPUS=$(cat $BD/$NAME.cpus)
ISO="unshare -r -n taskset -c $CPUS nice -n 10"
export REFOLD_REPO=$R REFOLD_OUT=$BD/$NAME-out REFOLD_ISOLATE="$ISO"
cd $R
SUBJ=$(SUBJECT_OF "$(python3 -I -c "import json,sys; print(json.load(open(sys.argv[1]))['contract'])" $B)")
case $CMD in
  setup)
    git status --short | head -3; git describe --tags --always
    python3 -I $T/block_gate.py $B --record-base
    python3 -I - $B <<'PY'
import json, sys
b = json.load(open(sys.argv[1]))
d = b["declarations"]
print("block: %d declarations (%d theorems), %d lines, %d files, %d ranges; users: %s" % (
    len(d), sum(x["kind"] == "theorem" for x in d), sum(x["line1"] - x["line0"] + 1 for x in d),
    len(b["ranges"]), sum(len(v) for v in b["ranges"].values()), ", ".join(b["users_of_contract"])))
dd = [x for x in d if x.get("dead")]
print("of which dead-code users put into the block: %d declarations, %d lines; pinned without them: %d" % (
    len(dd), sum(x["line1"] - x["line0"] + 1 for x in dd), len(b.get("pinned_by_dead_code", []))))
for f, rs in sorted(b["ranges"].items()):
    print("  %-70s %s" % (f, rs))
PY
    ;;
  build)
    START=$(date +%s)
    MODS=$(python3 -I -c "import json,sys; print(' '.join(json.load(open(sys.argv[1]))['user_modules']))" $B)
    OUT=$($ISO lake build $MODS 2>&1); RC=$?
    echo "$OUT" | grep -A14 -E "^error: .*\.lean" | cut -c1-600 | head -150
    echo "BUILD rc=$RC seconds=$(( $(date +%s) - START )) errors=$(echo "$OUT" | grep -c '^error: .*\.lean') (targets: $MODS)"
    ;;
  lean)
    START=$(date +%s)
    $ISO lake env lean "$1" 2>&1 | cut -c1-600 | head -200
    echo "LEAN rc=${PIPESTATUS[0]} seconds=$(( $(date +%s) - START ))"
    ;;
  gate)
    python3 -I $T/block_gate.py $B "$1" --base $BASE_REF --subject $SUBJ --keep-build
    ;;
  commit)
    # uses the identity configured in the working copy (git config user.name / user.email)
    git add -A && git commit -q -m "$2" && git tag "$1" && git log --oneline -1
    ;;
  rm) case "$1" in Scratch*.lean) rm -f "$R/$1"; echo "removed $1" ;; *) echo "only Scratch*.lean files can be removed"; exit 2 ;; esac ;;
  grep) grep -rnE --include='*.lean' -- "$1" "${2:-.}" | cut -c1-260 | head -120 ;;
  size)
    python3 -I - $B $R $BASE_REF <<'PY'
import json, subprocess, sys
b = json.load(open(sys.argv[1])); r = sys.argv[2]; ref = sys.argv[3]
blk = sum(x["line1"] - x["line0"] + 1 for x in b["declarations"]); delta = 0
for f in b["ranges"]:
    base = len(subprocess.run(["git", "show", ref + ":" + f], cwd=r, stdout=subprocess.PIPE).stdout.decode().split("\n")) - 1
    delta += sum(1 for _ in open(r + "/" + f)) - base
print("block lines: base %d, now %d" % (blk, blk + delta))
PY
    ;;
  *) echo "usage: slice_server.sh NAME setup|build|lean|gate|commit|size|rm|grep ..."; exit 2 ;;
esac
