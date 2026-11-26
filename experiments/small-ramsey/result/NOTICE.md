# Notice

`MulticolorTriangleRamsey.lean` in this directory is a derived work of the file of the same name in
[openai/ten-proofs](https://github.com/openai/ten-proofs) at commit
`94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`, which is licensed under the Apache License,
Version 2.0 (see `LICENSE` in this directory, copied unchanged from that repository).

Changes made: the proofs were rewritten in the experiment described in `../README.md`. The four
headline theorems (`erdos_183`, `erdos_problem_183_explicit`,
`triangleRamseyNumber_log_sharp_coefficients`, `triangleRamseyNumber_log_isTheta`) keep their
names and statements, and the three definitions used by those statements (`TriangleFree`,
`ForcesMonochromaticTriangle`, `triangleRamseyNumber`) keep their text. All other declarations of
the original file were removed or replaced: the file went from 3,053 lines with 96 theorems and
42 definitions to 610 lines with 9 theorems and 3 definitions.

The file was checked with Lean v4.33.1 and Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`
(the upstream repository pins Lean v4.32.0): it builds offline without errors, the headline
theorems depend only on `propext`, `Classical.choice` and `Quot.sound`, and their statements,
together with the definitions they mention, are structurally identical to those of the upstream
challenge file `ComparatorChallenges/I_MulticolorTriangleRamsey.lean`. No independent kernel
replay was run, and the mathematics has not been reviewed by a person.
