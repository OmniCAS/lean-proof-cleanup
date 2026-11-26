# Brief for the rewriting agent: small subject (multicolour triangle Ramsey)

> Verbatim prompt given to the rewriting agent, with local paths replaced by `<WORKING_COPY>` (the Lake project being rewritten), `<EXPERIMENT_DIR>` (where logs go) and `<TOOLS>` (this directory).

You are doing the part of a proof-compression experiment that needs an understanding of the mathematics. The mechanical parts are already done by scripts. Work only inside your working copy and write only the files named below.

## The subject

Working copy (a Lake project, Lean v4.33.1, Mathlib already built, no network):
`<WORKING_COPY>`

File to rewrite: `MulticolorTriangleRamsey.lean` (about 2,900 lines, model-generated, Apache-2.0). It proves a superexponential lower bound for multicolour triangle Ramsey numbers. Its four headline theorems and their statements are fixed by `ComparatorChallenges/I_MulticolorTriangleRamsey.lean`:
`erdos_183`, `erdos_problem_183_explicit`, `triangleRamseyNumber_log_sharp_coefficients`, `triangleRamseyNumber_log_isTheta` (namespace `ErdosProblems.MulticolourTriangleRamsey`), together with the three definitions those statements use (`TriangleFree`, `ForcesMonochromaticTriangle`, `triangleRamseyNumber`).

State of the file: single-use lemmas have already been inlined by a script as local `have name binders : statement := proof` blocks at the start of the proof of their only user (so some proofs are several hundred lines long and nested), and a blind search has already replaced the proof blocks that one plain automation call can close. What is left is what a script cannot do.

## The goal

Make the development as small as you can **without changing what is proved**: fewer theorems and lemmas, fewer definitions, fewer code lines. The count of statements matters more than line count. Everything except the four headline statements and the three definitions above is a means and may be reorganised, generalised, replaced or deleted.

## Hard rules

1. Do not edit anything in `ComparatorChallenges/` or `Gate/`, nor `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`. Do not touch `CompactnessAndDegeneracy.lean`.
2. The four headline theorems keep their names and exact statements; the three definitions keep their exact text.
3. No `sorry`, no new `axiom`, no `native_decide`, no `unsafe`, no `#eval`, no new macros or elaborators.
4. Do not weaken a statement to make its proof shorter and then use it elsewhere in a way that needs the stronger form; the build decides.
5. Avoid raising `maxHeartbeats`; if a declaration truly needs it, use `set_option maxHeartbeats N in` on that declaration only and note it in the log.
6. Build only with this command (it denies network access):
   `cd <WORKING_COPY> && sandbox-exec -p '(version 1)(allow default)(deny network*)' lake build MulticolorTriangleRamsey`
   A build takes 10 to 40 seconds. Build after every meaningful edit; never accumulate unverified edits.
7. Write nothing outside the working copy except the log file named below. Do not push, publish or fetch anything.

## The gate (acceptance test)

After each stage, run from `<EXPERIMENT_DIR>`:

`REFOLD_REPO=<WORKING_COPY> python3 -I <TOOLS>/gate.py ramsey agent-<stage>`

It must print `PASS` (frozen files unchanged, headline statements identical to the challenge module, only the three standard axioms, full offline build). Then record metrics:

`REFOLD_REPO=<WORKING_COPY> python3 -I <TOOLS>/metrics.py ramsey agent-<stage>`

and commit in the working copy: `git commit -am "<message>"` (with a placeholder identity) followed by `git tag agent-<stage>`.

## Stages, in this order, each ending with gate, metrics, commit and tag

**Stage A, `agent-simplify`: simplify inside the unrolled proofs, without creating new top-level lemmas.**
- Delete local `have`s that are not used, or whose only use can be discharged directly.
- A local lemma that is stated generally but used once: specialise it to that use (its hypotheses are then facts in context) and see whether it collapses to a line.
- Replace step-by-step derivations by the right library fact or by automation given the right facts (`grind [...]`, `simp [...]`, `omega`, `positivity`, `gcongr`, `bound`, `fun_prop`, `norm_num`, `linarith`, `nlinarith`, `aesop`).
- Merge sub-derivations that are repeated in several places.
- Remove wrapper layers: definitions used once, named propositions, lemmas that only restate another lemma, certificates that only bundle hypotheses.
- Look for detours: an intermediate result stronger or more general than its use needs, a case split that is not needed, a construction that Mathlib already provides.

**Stage B, `agent-refold`: fold back into lemmas only where it pays.**
- Extract a top-level lemma only if it is used at least twice, or if it is a self-contained mathematical fact about general objects (state it at its natural generality, with section variables, not about the project's own data bundles).
- Check whether Mathlib already has it (search the Mathlib source under `.lake/packages/mathlib/Mathlib`); if so use the library statement and delete ours.
- Replace a clumsy sub-argument by a better one if you see one, including a different construction, as long as the headline statements are proved.
- Reorder so that the file reads top-down: general facts, the construction, the counting, the asymptotics, the headline theorems.

**Stage C, `agent-shorten`: shorten what remains.**
- Tactic-level compression of each remaining proof; term-mode where it is shorter; shared `variable`s; `open` where it removes qualifications. Do not sacrifice a passing build for a line.

Stop a stage when further effort gives little; it is fine to revisit an earlier kind of change in a later stage, but say so in the log.

## The log (required, part of the experiment record)

Write `<EXPERIMENT_DIR>/agent-log.md`, updated as you go, in English:

- For each stage: start and end time (run `date`), number of builds, and the metrics line printed by `metrics.py`.
- A table of what you did by kind (for example: unused `have` deleted; specialised to the use site; replaced by a library lemma, naming it; replaced by automation; repeated derivation merged; wrapper removed; definition inlined; statement generalised; lemma extracted with its number of uses; argument replaced), with a count for each kind and two or three concrete before/after examples with line counts.
- What you tried that failed or that you abandoned, and why.
- Anything you judged not worth doing, and why.
- A short description of the mathematical structure of the proof as you understand it (one paragraph), so that a reader can follow the reorganisation.

## Final report

When done (or when you judge that further work is not worth it), reply with: the three stage tags and whether each gate passed; theorems, definitions and code lines before and after each stage; the main kinds of change that produced the reduction; what remains and why it resists. Do not claim anything the gate did not confirm.
