#!/usr/bin/env bash
# Build a Lake project on the build server: pinned cores, low priority, no network, timed, with a
# memory sampler. Usage: build_project.sh WORKSPACE NAME TOOLCHAIN_DIR CPUSET LABEL TARGET [TARGET...]
#   TOOLCHAIN_DIR  directory holding bin/lake and bin/lean
#   CPUSET         e.g. 32-63 (taskset list); the number of CPUs in it becomes LEAN_NUM_THREADS
# Writes logs/build-NAME-LABEL.log, .mem.jsonl and .summary.json under WORKSPACE.
set -uo pipefail
WS=$1; NAME=$2; TC=$3; CPUS=$4; LABEL=$5; shift 5
ROOT="$WS/work/$NAME"; LOG="$WS/logs/build-$NAME-$LABEL"
export PATH="$TC/bin:$PATH"
NCPU=$(taskset -c "$CPUS" nproc)
export LEAN_NUM_THREADS=$NCPU
ulimit -n 65536 2>/dev/null || ulimit -n 4096 2>/dev/null || true
rm -f "$LOG.stop"; : > "$LOG.mem.jsonl"
python3 "$WS/memsample.py" "$LOG.mem.jsonl" "$LOG.stop" 10 &
SAMPLER=$!
cd "$ROOT"
START=$(date +%s)
echo "=== $(date '+%F %T') lake build $* (cpus $CPUS, $NCPU threads, $(lean --version | cut -c1-40))" > "$LOG.log"
/usr/bin/time -v unshare -r -n taskset -c "$CPUS" nice -n 10 lake build "$@" >> "$LOG.log" 2> "$LOG.time"
RC=$?
END=$(date +%s)
touch "$LOG.stop"; wait $SAMPLER 2>/dev/null
python3 - "$LOG" "$RC" "$((END-START))" "$NCPU" "$ROOT" <<'PY'
import json, os, re, sys
log, rc, wall, ncpu, root = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
text = open(log + ".log", encoding="utf-8", errors="replace").read()
tm = open(log + ".time", encoding="utf-8", errors="replace").read()
def g(p):
    m = re.search(p, tm)
    return float(m.group(1)) if m else None
mem = [json.loads(l) for l in open(log + ".mem.jsonl") if l.strip()]
built = len(re.findall(r"^[✔⚠] \[\d+/\d+\] Built ", text, re.M))
failed = sorted(set(re.findall(r"^✖ \[\d+/\d+\] Building (\S+)", text, re.M)))
errs = re.findall(r"^error: \S+?\.lean:\d+:\d+: (.*)$", text, re.M)
times = [float(a) * (0.001 if u == "ms" else 1 if u == "s" else 60) for a, u in re.findall(r"Built \S+ \((\d+(?:\.\d+)?)(ms|s|m)\)", text)]
sz = 0
for d, _, fs in os.walk(os.path.join(root, ".lake", "build")):
    sz += sum(os.path.getsize(os.path.join(d, f)) for f in fs)
s = {"exit_code": rc, "wall_seconds": wall, "threads": ncpu, "user_cpu_seconds": g(r"User time \(seconds\): ([\d.]+)"),
     "system_cpu_seconds": g(r"System time \(seconds\): ([\d.]+)"), "modules_built": built,
     "modules_failed": len(failed), "failed_modules": failed[:50], "error_messages": len(errs),
     "sum_module_seconds": round(sum(times)), "max_module_seconds": round(max(times, default=0)),
     "lean_procs_max": max((m["lean_procs"] for m in mem), default=0),
     "lean_rss_sum_mb_max": max((m["rss_sum_mb"] for m in mem), default=0),
     "lean_rss_single_mb_max": max((m["rss_max_mb"] for m in mem), default=0),
     "system_used_mb_before": mem[0]["system_used_mb"] if mem else None,
     "system_used_mb_max": max((m["system_used_mb"] for m in mem), default=None),
     "load1_max": max((m["load1"] for m in mem), default=None), "build_dir_mb": sz >> 20}
json.dump(s, open(log + ".summary.json", "w"), indent=1)
print(json.dumps({k: v for k, v in s.items() if k != "failed_modules"}))
PY
echo "BUILD_DONE $NAME $LABEL rc=$RC"
