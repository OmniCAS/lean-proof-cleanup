# Notice

`CompactnessAndDegeneracy.lean` in this directory is a derived work of the file of the same name in
[openai/ten-proofs](https://github.com/openai/ten-proofs) at commit
`94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`, which is licensed under the Apache License,
Version 2.0 (see `LICENSE` in this directory, copied unchanged from that repository).

Changes made, in the experiment described in `../README.md`: three alias declarations, three unused
instance arguments and 18 style lints were removed; 412 lemmas used at exactly one place were
moved by a script into the proof of their only user as local `have` blocks; 84 local proofs were
replaced by automation calls; one detour (a little-o certificate) and nine wrapper declarations
were removed; three sub-arguments were replaced by shorter ones (a Markov bound instead of a
second-moment computation, an induction on the number of edges instead of a maximised potential,
an averaging argument instead of a vertex-flip argument for the maximum cut); statement headers
were reflowed. The five headline theorems (`CompactnessConjecture.not_erdos_180`,
`CompactnessConjecture.quantitativeCompactnessCounterexample`,
`CompactnessConjecture.compactnessCounterexample_bigO`,
`TwoDegenerateGraphs.twoDegenerateExtremalCounterexample`, `TwoDegenerateGraphs.not_erdos_146`)
keep their names and statements, and the definitions of the two upstream challenge files keep
their text. The file went from 18,588 lines with 656 theorems to 16,717 lines with 214 theorems.

The file was checked with Lean v4.33.1 and Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`
(the upstream repository pins Lean v4.32.0): it builds offline without errors, the headline
theorems depend only on `propext`, `Classical.choice` and `Quot.sound`, and their statements,
together with the definitions they mention, are structurally identical to those of the upstream
challenge files `ComparatorChallenges/J_CompactnessConjecture.lean` and
`ComparatorChallenges/J_TwoDegenerateGraphs.lean`. No independent kernel replay was run, and the
mathematics has not been reviewed by a person.
