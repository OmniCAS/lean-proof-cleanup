# Brief: rewrite one block of a Lean development behind a fixed contract

Template. Fill the fields in braces from the block file written by `dominators.py --show NAME --block FILE`.
One run per block; at most two runs at a time, each in its own copy of the working tree.

---

You are running one experiment in a study of how far dedicated effort can compress a formal proof. The object is one block of a model-generated Lean 4 development. The block has a contract: one theorem whose statement is fixed. Everything inside the block may be proved in any way.

## The subject

Working copy (a Lake project, Mathlib already built, no network): `{working copy}`

Only your block may change.

## The block and its contract

Contract theorem: `{contract}` in `{file}` (lines {first}–{last}). Its statement, which must stay exactly as it is:

```lean
{statement}
```

The rest of the development uses the block only through this theorem (its users: {users}).

The block is the contract theorem together with every declaration that is needed only for it: {n} declarations ({t} theorems, {d} definitions and instances), {lines} lines. They are listed, with their line ranges, in `{block file}`.

What the block is about. {two or three sentences: what the contract says mathematically, how the present proof goes, what an earlier pass did and did not touch}

## What is fixed and what is free

Fixed:
- the name and statement of the contract theorem;
- every declaration outside the block, byte for byte (other blocks are being rewritten in other copies; the results will be merged, so a change outside your line ranges makes your result unusable);
- the definitions the contract statement mentions, directly or through other definitions (the gate checks them by fingerprint);
- the challenge files, the gate files, the lakefile, the manifest and the toolchain file.

Free: everything inside the block. You may delete any of its declarations, replace them, add new ones (inside the block's line ranges, for example just before the contract theorem), change or drop every intermediate statement and definition, use a completely different mathematical argument, and use anything in Mathlib. No intermediate statement has to survive.

## Goal

The shortest proof of the contract theorem that passes the gate; then tidy it. Count success in lines and in number of declarations of the block. A different, shorter mathematical argument is the main lever: before shortening anything locally, work out on paper what the block proves and ask whether there is a standard or simpler route to the same statement. The constants in the statement are fixed, so check that a candidate argument can reach them.

## Rules

1. No `sorry`, no new `axiom`, no `native_decide`, no `unsafe`, no `#eval`, no new macros or elaborators in the result.
2. Do not add or raise `maxHeartbeats` options (removing one is welcome).
3. Build only with network access denied: `{build command}`.
4. Fast iteration: develop the new proof in a scratch file that imports the built subject, works in a namespace of its own, and proves the contract statement under a new name using only Mathlib and declarations from outside the block; check it with `lake env lean`, which does not rebuild the subject. When the scratch proof is complete, transplant it in place of the old block, delete the scratch file, and run the full build and the gate.
5. Run at most one build at a time, and touch nothing outside your working copy and your log file.
6. Do not push, publish or fetch anything.

## The gate

`{block gate command}` must end with `BLOCK GATE PASS`: the ordinary gate of the subject (headline statements, axioms, full offline build), the contract fingerprint unchanged, and every change located inside the block's line ranges. It also prints the block's size before and after. After each improvement that passes, commit and tag it; tag the final state. A banked partial result is worth more than an unfinished ambitious one.

## Budget

About {hours} hours of wall time. Stop earlier if progress stalls: when two successive serious attempts at a shorter argument fail, or when what remains is a long computation with no visible shortcut. Do not spend the budget on line-by-line polishing before the mathematical question is settled.

## The log (required)

Write `{log file}`, updated as you go:
- start and end time, number of builds and scratch checks;
- a paragraph on what the block proves and how the current proof goes;
- every argument you considered as a replacement: what it is, whether it reaches the fixed statement with its constants, what happened when you tried it (lines before and after, or why it failed);
- what you replaced by what, with line counts;
- what you tried and gave up, and why;
- at the end, an explicit verdict for the part that remains: does it resist because the mathematics is long (say which shorter routes you looked for and why they do not work), or because the budget ran out (say what the promising next step is)?

## Final report

The tags and whether each gate passed; block lines, theorems and definitions before and after; wall time, number of builds; which arguments were replaced by what; what was tried and given up; and the verdict above. Do not claim anything the gate did not confirm.
