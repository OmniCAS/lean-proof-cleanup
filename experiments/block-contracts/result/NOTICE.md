# Notice

`CompactnessAndDegeneracy.lean` in this directory is a derived work of the file of the same name in
[openai/ten-proofs](https://github.com/openai/ten-proofs) at commit
`94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`, which is licensed under the Apache License,
Version 2.0 (see `LICENSE` in this directory, copied unchanged from that repository).

Changes made. First, all the changes of the earlier experiment, listed in
`../../small-compactness/result/NOTICE.md` (the file published there is the starting point of
this one). Then, in the experiment described in `../README.md`, three blocks of the file were
rewritten, each behind one theorem whose name and statement were kept:

- behind `TwoDegenerateGraphs.pairCoordinateConditionalEntropy_empirical_bound`: the proof through
  independent weights, a transfer to sampling without replacement with error terms, and a smoothing
  kernel was replaced by a direct proof for the empirical weights (a weighted Gibbs inequality,
  tangent lines of the logarithm with a sum-of-squares identity, and a concavity proof of a
  Pinsker-type bound); 31 declarations became 2;
- behind `CompactnessConjecture.proposedFamilyFree_sixteenth_power_host_bound`: the supersaturation
  count through non-backtracking paths, heavy fibres and glued copies was replaced by a count with a
  vertex cover, one power-mean step and one injection, with the forbidden quotients built directly
  from configurations; 93 declarations became 32;
- behind `CompactnessConjecture.proposedFamily_uniformMemberLower`: the host graph, previously the
  incidence graph of the symplectic generalised quadrangle W(q) with points and lines as submodules,
  was replaced by the algebraic graph D(3,q) on triples of field elements, with the avoidance of the
  forbidden quotients proved by polynomial identities; 120 declarations became 36.

Nothing outside these three blocks was changed. The five headline theorems
(`CompactnessConjecture.not_erdos_180`,
`CompactnessConjecture.quantitativeCompactnessCounterexample`,
`CompactnessConjecture.compactnessCounterexample_bigO`,
`TwoDegenerateGraphs.twoDegenerateExtremalCounterexample`, `TwoDegenerateGraphs.not_erdos_146`)
keep their names and statements, and the definitions of the two upstream challenge files keep
their text. The file went from 16,717 lines with 214 theorems to 9,813 lines with 151 theorems
(upstream: 18,588 lines with 656 theorems).

The file was checked with Lean v4.33.1 and Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`
(the upstream repository pins Lean v4.32.0): it builds offline without errors, the headline
theorems and the three contract theorems depend only on `propext`, `Classical.choice` and
`Quot.sound`, the statements of the headline theorems, together with the definitions they mention,
are structurally identical to those of the upstream challenge files
`ComparatorChallenges/J_CompactnessConjecture.lean` and
`ComparatorChallenges/J_TwoDegenerateGraphs.lean`, and the statements of the three contract
theorems are structurally identical to those in the starting file. No independent kernel replay was
run, and the mathematics has not been reviewed by a person: the new arguments were written by a
language model and are accepted here only because Lean checks them.
