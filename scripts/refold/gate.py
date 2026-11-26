"""Gate for one subject of the unroll/refold experiment.

Usage: python3 -I gate.py SUBJECT STAGE [--keep-build]
  SUBJECT: a key of refold-subjects.json in the working copy
  STAGE:   free label, used for the log name (e.g. s0-baseline)
Environment: REFOLD_REPO (working copy, default: current directory), REFOLD_OUT (where logs go,
default: ./refold-out), REFOLD_ISOLATE (network-denying command prefix), REFOLD_SUBJECTS.
The working copy must contain the frozen challenge modules under ComparatorChallenges/ with one
JSON file per challenge (`theorem_names`), and the Gate library (lean/GateTools.lean as
Gate/Tools.lean) declared in its lakefile.

Checks (all must hold):
  G1  frozen files (challenge statements, gate code) have their recorded SHA-256
  G2  statement fingerprint of the headline theorems: challenge module == solution module
  G3  axioms of every headline theorem within {propext, Classical.choice, Quot.sound}
  G4  full offline build of the solution module from scratch, zero errors
Writes REFOLD_OUT/gate/SUBJECT-STAGE.log and .json, prints a one-line verdict, exit code 0/1.
"""
import hashlib
import json
import os
import re
import resource
import subprocess
import sys
import time

REPO = os.path.abspath(os.environ.get("REFOLD_REPO", os.getcwd()))
PROJ = os.path.abspath(os.environ.get("REFOLD_OUT", os.path.join(os.getcwd(), "refold-out")))
ALLOWED = {"propext", "Classical.choice", "Quot.sound"}

def _isolate():
    """Command prefix that denies network access to the build (override with REFOLD_ISOLATE)."""
    v = os.environ.get("REFOLD_ISOLATE")
    if v is not None:
        return v.split()
    if sys.platform == "darwin":
        return ["sandbox-exec", "-p", "(version 1)(allow default)(deny network*)"]
    return ["unshare", "-r", "-n"]


def _subjects(repo):
    """Subjects of a working copy: name -> (solution module, [challenge modules]).
    Read from refold-subjects.json in the working copy (or the file named by REFOLD_SUBJECTS)."""
    path = os.environ.get("REFOLD_SUBJECTS", os.path.join(repo, "refold-subjects.json"))
    return {k: (v["solution"], v["challenges"]) for k, v in json.load(open(path)).items()}

NONET = _isolate()
SUBJECTS = _subjects(REPO)
FROZEN = os.path.join(PROJ, "frozen.sha256")


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def frozen_files():
    out = []
    for d in ("ComparatorChallenges", "Gate"):
        for f in sorted(os.listdir(os.path.join(REPO, d))):
            out.append(os.path.join(d, f))
    return out


def run(cmd, log, timeout=3600):
    t0 = time.time()
    r0 = resource.getrusage(resource.RUSAGE_CHILDREN)
    p = subprocess.run(cmd, cwd=REPO, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
    r1 = resource.getrusage(resource.RUSAGE_CHILDREN)
    out = p.stdout.decode("utf-8", "replace")
    log.write("$ " + " ".join(cmd[len(NONET):] if cmd[:len(NONET)] == NONET else cmd) + "\n" + out + "\n")
    return p.returncode, out, time.time() - t0, (r1.ru_utime + r1.ru_stime) - (r0.ru_utime + r0.ru_stime), r1.ru_maxrss


def lean_names(names):
    return "[" + ", ".join("`" + n for n in names) + "]"


def main():
    subject, stage = sys.argv[1], sys.argv[2]
    solution, challenges = SUBJECTS[subject]
    os.makedirs(os.path.join(PROJ, "gate"), exist_ok=True)
    base = os.path.join(PROJ, "gate", subject + "-" + stage)
    log = open(base + ".log", "w")
    res = {"subject": subject, "stage": stage, "time": time.strftime("%Y-%m-%d %H:%M:%S")}

    # G1 frozen files
    cur = {f: sha(os.path.join(REPO, f)) for f in frozen_files()}
    if not os.path.exists(FROZEN):
        json.dump(cur, open(FROZEN, "w"), indent=1)
        log.write("recorded frozen hashes\n")
    want = json.load(open(FROZEN))
    res["G1"] = cur == want
    log.write("G1 frozen files: %s\n" % ("ok" if res["G1"] else "CHANGED: %s" % [f for f in cur if cur[f] != want.get(f)]))

    # G4 full build of the solution from scratch
    if "--keep-build" not in sys.argv:
        for sub in ("lib/lean", "ir"):
            d = os.path.join(REPO, ".lake", "build", sub)
            if os.path.isdir(d):
                for f in os.listdir(d):
                    if f.startswith(solution + "."):
                        os.remove(os.path.join(d, f))
    rc, out, wall, cpu, rss = run(NONET + ["lake", "build", solution, "ComparatorChallenges", "Gate"], log)
    m = re.search(r"Built " + re.escape(solution) + r" \((\d+(?:\.\d+)?)(ms|s)\)", out)
    res["build_seconds_module"] = (float(m.group(1)) / (1000 if m.group(2) == "ms" else 1)) if m else None
    res["build_wall_seconds"] = round(wall, 1)
    res["build_cpu_seconds"] = round(cpu, 1)
    res["build_peak_rss_mb"] = round(rss / 1e6, 0)
    res["warnings"] = len(re.findall(r"^warning: " + re.escape(solution), out, re.M))
    res["sorry_warnings"] = len(re.findall(r"^warning: " + re.escape(solution) + r"\.lean:\S* declaration uses `?sorry", out, re.M))
    res["G4"] = rc == 0 and res["sorry_warnings"] == 0
    ole = os.path.join(REPO, ".lake", "build", "lib", "lean", solution + ".olean")
    res["olean_bytes"] = os.path.getsize(ole) if os.path.exists(ole) else None

    # G2 / G3 statement fingerprint and axioms
    tmp = os.path.join(REPO, ".lake", "gate-tmp")
    os.makedirs(tmp, exist_ok=True)
    ok2, ok3, axioms = res["G4"], res["G4"], {}
    if res["G4"]:
        for ch in challenges:
            names = json.load(open(os.path.join(REPO, "ComparatorChallenges", ch + ".json")))["theorem_names"]
            a = os.path.join(tmp, "Challenge_" + ch + ".lean")
            b = os.path.join(tmp, "Solution_" + ch + ".lean")
            open(a, "w").write("import ComparatorChallenges.%s\nimport Gate.Tools\n#eval Gate.statementReport %s\n"
                               % (ch, lean_names(names)))
            open(b, "w").write("import %s\nimport Gate.Tools\n#eval Gate.statementReport %s\n#eval Gate.axiomReport %s\n"
                               % (solution, lean_names(names), lean_names(names)))
            rca, outa, *_ = run(NONET + ["lake", "env", "lean", a], log)
            rcb, outb, *_ = run(NONET + ["lake", "env", "lean", b], log)
            sa = [l for l in outa.splitlines() if l.startswith(("headline ", "const "))]
            sb = [l for l in outb.splitlines() if l.startswith(("headline ", "const "))]
            same = rca == 0 and rcb == 0 and sa == sb and len(sa) >= len(names)
            ok2 = ok2 and same
            log.write("G2 %s: %s (%d fingerprint lines)\n" % (ch, "ok" if same else "MISMATCH", len(sa)))
            for l in outb.splitlines():
                mm = re.match(r"axioms (\S+) \[(.*)\]", l)
                if mm:
                    ax = set(x.strip() for x in mm.group(2).split(",") if x.strip())
                    axioms[mm.group(1)] = sorted(ax)
                    ok3 = ok3 and ax <= ALLOWED
            ok3 = ok3 and all(n in axioms for n in names)
    res["G2"], res["G3"], res["axioms"] = ok2, ok3, axioms
    res["pass"] = all(res[g] for g in ("G1", "G2", "G3", "G4"))
    log.write(json.dumps(res, indent=1) + "\n")
    json.dump(res, open(base + ".json", "w"), indent=1)
    print("%s %s: %s  G1=%s G2=%s G3=%s G4=%s  build %.0fs (module %s s), cpu %.0fs, warnings %d" % (
        subject, stage, "PASS" if res["pass"] else "FAIL", res["G1"], res["G2"], res["G3"], res["G4"],
        wall, res["build_seconds_module"], cpu, res["warnings"]))
    sys.exit(0 if res["pass"] else 1)


if __name__ == "__main__":
    main()
