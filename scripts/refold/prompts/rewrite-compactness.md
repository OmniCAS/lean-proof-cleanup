# Brief for the rewriting agent: second subject (compactness and degeneracy counterexamples)

> Verbatim prompt given to the rewriting agent, with local paths replaced by `<WORKING_COPY>` (the Lake project being rewritten), `<EXPERIMENT_DIR>` (where logs go) and `<TOOLS>` (this directory).

You are doing the part of a proof-compression experiment that needs an understanding of the mathematics. The mechanical parts are already done by scripts. Work only inside your working copy and write only the files named below.

## The subject

Working copy (a Lake project, Lean v4.33.1, Mathlib already built, no network):
`<WORKING_COPY>`

File to rewrite: `CompactnessAndDegeneracy.lean` (about 18,000 lines, model-generated, Apache-2.0). It proves counterexamples to two conjectures in extremal graph theory. Its five headline theorems and their statements are fixed by two challenge files:
- `ComparatorChallenges/J_CompactnessConjecture.lean`: `CompactnessConjecture.not_erdos_180`, `CompactnessConjecture.quantitativeCompactnessCounterexample`, `CompactnessConjecture.compactnessCounterexample_bigO`;
- `ComparatorChallenges/J_TwoDegenerateGraphs.lean`: `TwoDegenerateGraphs.twoDegenerateExtremalCounterexample`, `TwoDegenerateGraphs.not_erdos_146`;
together with every definition those two challenge files contain (`FiniteGraph`, `FamilyFree`, `familyExtremal`, `IsCyclicFamily`, `IsCompactFamily`, `CompactnessConjectureStatement`, `extremalScale`, `UniformMemberLower`, `neighborsWithin`, `IsDegenerate`, `IsTwoDegenerate`, `DegeneracyConjectureStatement`). Read the two challenge files first: they are the specification.

The file has two developments, in two namespaces: `CompactnessConjecture` (the first half) and `TwoDegenerateGraphs` (the second half, which uses some declarations of the first).

State of the file: single-use lemmas have already been inlined by a script as local `have name binders : statement := proof` blocks at the start of the proof of their only user, sometimes wrapped as `(open … in have … )`. So some declarations are thousands of lines long and deeply nested, three of them carry `set_option maxHeartbeats N in`, and a full build takes about two and a half minutes. What is left is what a script cannot do.

A previous run of this same task on a 3,000-line file from the same repository ended at one fifth of the lines. Almost all of that came from replacing sub-arguments by better ones (a standard construction or a Mathlib notion instead of a home-made hierarchy of definitions and certificates), not from local shortening. Expect the same here: look first for whole sub-developments that can be replaced.

## The goal

Make the development as small as you can **without changing what is proved**: fewer theorems and lemmas, fewer definitions, fewer code lines. The count of statements matters more than line count. Everything except the five headline statements and the definitions of the challenge files is a means and may be reorganised, generalised, replaced or deleted.

## Hard rules

1. Do not edit anything in `ComparatorChallenges/` or `Gate/`, nor `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`. Do not touch `MulticolorTriangleRamsey.lean`.
2. The five headline theorems keep their names and exact statements; the definitions that occur in the two challenge files keep their exact text.
3. No `sorry`, no new `axiom`, no `native_decide`, no `unsafe`, no `#eval`, no new macros or elaborators.
4. Do not weaken a statement to make its proof shorter and then use it elsewhere in a way that needs the stronger form; the build decides.
5. Avoid raising `maxHeartbeats`; if a declaration truly needs it, use `set_option maxHeartbeats N in` on that declaration only and note it in the log.
6. Build only with this command (it denies network access):
   `cd <WORKING_COPY> && sandbox-exec -p '(version 1)(allow default)(deny network*)' lake build CompactnessAndDegeneracy`
   A full build takes two to three minutes at the start and gets faster as the file shrinks. To iterate quickly on a replacement for one sub-development, you may develop it in a scratch file `Scratch.lean` in the working copy (importing only Mathlib, or the subject file) and check it with `sandbox-exec -p '(version 1)(allow default)(deny network*)' lake env lean Scratch.lean`; the scratch file is not part of the result and must be deleted before each gate. Never accumulate unverified edits in the subject file.
7. Write nothing outside the working copy except the log file named below. Do not push, publish or fetch anything.

## The gate (acceptance test)

After each stage, run from `<EXPERIMENT_DIR>`:

`REFOLD_REPO=<WORKING_COPY> python3 -I <TOOLS>/gate.py compactness agent-<stage>`

It must print `PASS` (frozen files unchanged, headline statements identical to the challenge module, only the three standard axioms, full offline build). Then record metrics:

`REFOLD_REPO=<WORKING_COPY> python3 -I <TOOLS>/metrics.py compactness agent-<stage>`

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

Because this file is large, bank progress: inside Stage B, each time one sub-development has been replaced and the gate passes, commit and tag it `agent-refold-1`, `agent-refold-2`, … with a metrics line, then go on; tag the end of the stage `agent-refold`. Work on the sub-developments in decreasing order of size. If you run out of time or the remaining parts resist, stop cleanly at a gated commit and say in the log and in the report which sub-developments were rewritten, which were left as they are, and why.

## The log (required, part of the experiment record)

Write `<EXPERIMENT_DIR>/agent-log.md`, updated as you go, in English:

- For each stage: start and end time (run `date`), number of builds, and the metrics line printed by `metrics.py`.
- A table of what you did by kind (for example: unused `have` deleted; specialised to the use site; replaced by a library lemma, naming it; replaced by automation; repeated derivation merged; wrapper removed; definition inlined; statement generalised; lemma extracted with its number of uses; argument replaced), with a count for each kind and two or three concrete before/after examples with line counts.
- What you tried that failed or that you abandoned, and why.
- Anything you judged not worth doing, and why.
- A short description of the mathematical structure of the proof as you understand it (one paragraph), so that a reader can follow the reorganisation.

## Final report

When done (or when you judge that further work is not worth it), reply with: the stage tags (including the intermediate `agent-refold-N`) and whether each gate passed; theorems, definitions and code lines before and after each stage; the main kinds of change that produced the reduction; what remains and why it resists. Do not claim anything the gate did not confirm.
