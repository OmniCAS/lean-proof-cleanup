#!/usr/bin/env python3
"""Sample the Lean processes of the current user every few seconds until a stop file appears.

Usage: memsample.py OUT.jsonl STOPFILE [INTERVAL_SECONDS]
Each line: time, number of `lean` processes, sum and max of their resident memory (MB, shared
file mappings are counted once per process, so the sum overstates), system memory in use (MB,
MemTotal - MemAvailable) and the 1-minute load average.
"""
import json
import os
import sys
import time

out, stop = sys.argv[1], sys.argv[2]
interval = float(sys.argv[3]) if len(sys.argv) > 3 else 10
uid = os.getuid()
page = os.sysconf("SC_PAGE_SIZE")
with open(out, "a") as fh:
    while not os.path.exists(stop):
        rss = []
        for pid in os.listdir("/proc"):
            if not pid.isdigit():
                continue
            try:
                if os.stat("/proc/" + pid).st_uid != uid:
                    continue
                if os.path.basename(os.readlink("/proc/%s/exe" % pid)) != "lean":
                    continue
                rss.append(int(open("/proc/%s/statm" % pid).read().split()[1]) * page // (1 << 20))
            except OSError:
                continue
        mem = {}
        for l in open("/proc/meminfo"):
            k, v = l.split(":")
            mem[k] = int(v.split()[0]) // 1024
        fh.write(json.dumps({"t": round(time.time()), "lean_procs": len(rss), "rss_sum_mb": sum(rss),
                             "rss_max_mb": max(rss) if rss else 0,
                             "system_used_mb": mem["MemTotal"] - mem["MemAvailable"],
                             "load1": float(open("/proc/loadavg").read().split()[0])}) + "\n")
        fh.flush()
        time.sleep(interval)
