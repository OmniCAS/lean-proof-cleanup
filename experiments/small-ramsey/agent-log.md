> Log written by the rewriting agent while it worked (stages 3b, 4 and 5 of this experiment), unedited except that local paths are replaced by placeholders. Its stage names: `agent-simplify` = 3b, `agent-refold` = 4, `agent-shorten` = 5. Times are local time of the laptop.

# Rewriting log: MulticolorTriangleRamsey (agent-ramsey)

Baseline (tag/commit `c2ed57c`, metrics stage `s3a-auto`): 43 theorems (4 headlines), 42 defs (3 fixed), 1 structure, 2815 code lines.

## Stage A (agent-simplify)

Start: 2026-11-26 04:33 CST (reading the file), editing from 04:38 CST. End: 04:51 CST. Builds: 5 (+1 gate build).

Metrics line: `ramsey agent-simplify lines=2732 code_lines=2639 gzip_bytes=21838 theorems_env=37 defs_env=42 declarations_env=80 unreachable=0 theorems_used_0=0 theorems_used_1=19 theorems_used_2plus=14 defs_used_1=13 theorem_lines_mean=58.8 theorem_lines_median=16 theorem_lines_max=950 gate_build_seconds_module=13.0 gate_olean_bytes=4264936`

Gate: PASS.

Stage A was kept deliberately small: after reading the whole file I decided that the construction (palette blocks, certificates, saturated matrices, palette packing, bracket/adjacency numerics) would be replaced by a different, shorter argument in Stage B (the brief allows "a different construction" there), so detailed local simplification of code that is about to be deleted would be wasted effort. Stage A therefore only touched the parts whose argument survives.

| Kind | Count | Example |
|---|---|---|
| Detour removed (headline derived from another headline / from the explicit bound instead of re-running the construction) | 3 | `divergentRamseyRoot` (36 lines, re-ran the bracket and the main bound) deleted: `erdos_183` is now `erdos_problem_183_explicit.2`, and the limit is proved in 12 lines from the explicit bound (k^(1/6) ≤ base eventually). `triangleRamseyNumber_log_isTheta` (118 lines, re-derived both bounds for ε = 1/6) now takes `triangleRamseyNumber_log_sharp_coefficients (1/6)` and is 9 lines. |
| Proof rewritten with library asymptotics/automation | 1 | `triangleRamseyNumber_log_sharp_coefficients`: 86 → 47 lines (norm unfolding by one `simp only`, `nlinarith`, `gcongr`). |
| Single-use theorem inlined as local `have` | 5 | `quantitativeLowerBound_explicit_all` (now the `L` block of `erdos_problem_183_explicit`), `allColourPaletteRamsey_exponential_bound_sharp`, `paletteColourCount_three`, `triangleRamseyNumber_succ_le`, `triangleRamseyNumber_factorial_upper`. |
| `grind [lemma]` → `grind` after the lemma became local | 1 | |

Result: 43 → 37 theorems, 2815 → 2639 code lines.


## Stage B (agent-refold)

Start: 04:52 CST. End: 05:14 CST. Builds: 24 (builds 6–29 of the session counter; +2 gate builds, one of them only to re-check after removing an unused simp argument).

Metrics line: `ramsey agent-refold lines=637 code_lines=616 gzip_bytes=9369 theorems_env=9 defs_env=3 declarations_env=12 unreachable=0 theorems_used_0=0 theorems_used_1=4 theorems_used_2plus=1 defs_used_1=0 theorem_lines_mean=67.7 theorem_lines_median=42 theorem_lines_max=180 gate_build_seconds_module=9.5 gate_olean_bytes=3874952`

Gate: PASS. Result: 37 → 9 theorems (4 headlines + 5), 42 → 3 defs (only the three fixed ones), 1 → 0 structures, 2639 → 616 code lines.

The new file was written next to the old one, lemma by lemma (each built on its own), then the explicit bound was switched over and all old declarations were deleted in one step.

| Kind | Count | Example / note |
|---|---|---|
| Argument replaced: palette packing (t-subsets, greedy maximal separated family, shells, transversal palettes, binomial monotonicity, 2 Stirling-type bounds) by a greedy Hamming code (Gilbert–Varshamov) over `Fin t → Fin q` | 1 | `exists_code`, 42 lines, replaces `paletteBall`, `paletteShell`, `paletteShellEmbedding`, `transversal*` (3 defs), `IsPaletteSeparated` and about 280 lines of local lemmas. The ball bound is `C(t,s)·q^s` (cover the ball by "agree with the centre off an s-set D"), which is also stronger than the old `s·C(t,s)·C(N,s)` and needs no monotonicity of binomials. |
| Argument replaced: saturated matrix + `forwardGuess`/`backwardGuess` + `IsCoordinateCovering` by one covering function `Φ : X → X → Fin s ⊕ Fin s` with exactly the two properties the construction uses | 1 | `exists_covering`, 89 lines (was `exists_coordinate_covering`, 296 lines, plus 11 defs `IsSaturated`, `RowCovers`, `badSaturationRows`, `missingSymbolRows`, `badSaturationMatrices`, `exceptionalColumns`, `exceptionalColumnIndex`, `backwardGuess`, `forwardGuess`, `saturatedMatrixWidth`, `saturatedMatrixRows`). Saturation is stated directly as "for every y at most m exceptional columns"; the forward guess is no longer needed because the index of the exceptional column itself is the returned coordinate. |
| Argument replaced: the recursive palette colouring (`TopEdgeLabeling` on `family × V`, relabel equivalences, `PaletteBlockCertificate` structure with 5 fields, `globalLabel`, colourability via `Colorable`) by a function-level invariant | 1 | `exists_stage`, 180 lines (was lines 28–140 and 306–1176 of the original, about 1000 lines, 23 defs and 17 theorems). Colourings are symmetric functions `V → V → Fin t × ℕ`; a colour is `(position, level)`, block `i` misses the colours `(c, w i c)`; the "j-colourable colour classes" are an explicit label function `l : colour → V → Fin H`. Relabelling is the arithmetic map `x ↦ if x < w c then x else x+1` (handled by `omega`) instead of `Fintype.equivFinOfCardEq`. |
| Argument replaced: upper bound `R(k) ≤ 4·k!` via `TopEdgeLabeling` pullbacks and colour deletion by a function-level pigeonhole induction giving `Forces (2·(k+1)^k) k` | 1 | `forces_pow`, 48 lines (was `forcesMonochromaticTriangle_zero/_succ`, `deleteUnusedColour`, `omittedColourEquiv`, `cliqueFree_pullback_embedding`, `labelGraph_pullback_embedding`, `triangleRamseyNumber_forces`, `_succ_le`, `_factorial_upper`: about 170 lines). Colours are naturals `< k`, deleting a colour is `if c < ω then c else c - 1`. |
| Argument replaced: parameter choice by bracketing `count(H) ≤ k < count(H+1)` (with `Nat.find`, monotonicity of `count`, the adjacent-ratio bound `a·count(H+1) ≤ (a+34)·count(H)`, the cube-root control, `paletteColourCount 3 = 342`) by an explicit choice `H = ⌊e^37·β⌋`, `a = k / (H·s)` | 1 | The bracket needed ~330 lines and 4 defs (`paletteLogWidth`, `paletteColourCount`, `PaletteGrowthBound`, `singletonZeroColouring`) and 9 theorems; the explicit choice needs about 60 lines inside the explicit bound, because when the base β exceeds 1 the stage parameter H ≥ e^36·β is astronomically large and every estimate has room to spare. |
| Statement generalised / bridge lemma | 1 | `lt_triangleRamseyNumber`: any symmetric triangle-free function colouring on a fintype `V` with colours `< k` gives `card V < R(k)`; used twice (small case with `Empty`, main case). It absorbs `triangleFree_lt_triangleRamseyNumber`, `triangleRamseyNumber_mono` and the `Colorable`/`pullback` transport. |
| Replaced by a library lemma | 4 | `Real.pow_div_factorial_le_exp` (gives `(n/e)^n ≤ n!` in 5 lines instead of `Stirling.le_factorial_stirling` + 15 lines), `hammingDist`/`hammingDist_comm`/`hammingDist_self` for the code distance, `Finset.exists_subsuperset_card_eq`, `Finset.card_biUnion_le_card_mul`. |
| Lemma extracted (kept top-level) | 5 | `exists_covering` (1 use, self-contained combinatorial fact), `exists_code` (1 use, Gilbert–Varshamov bound), `exists_stage` (1 use, see "abandoned" below), `forces_pow` (2 uses), `lt_triangleRamseyNumber` (1 theorem, 2 uses). |
| Reordered | 1 | defs; general facts (`exists_covering`, `exists_code`); Ramsey-number facts (`forces_pow`, `lt_triangleRamseyNumber`); construction (`exists_stage`); explicit bound; asymptotics. |
| Upper bound in `…_sharp_coefficients` adapted | 1 | now from `R(k) ≤ 2(k+1)^k ≤ 4^k k^k`, so the slack is `k·log 4 ≤ ε·k·log k`. |

Before/after examples:
- Covering: `exists_coordinate_covering` + its 11 defs, 296 + ~60 lines → `exists_covering`, 89 lines.
- Construction: 23 defs + 17 theorems + 1 structure, ~1000 lines → `exists_stage`, 180 lines.
- Parameter bracketing and transfer: `allColourPaletteRamsey_exponential_bound_sharp` (733 lines as a local block) + `paletteStage_cube_root_control_six_sharp` (100 lines) + small case (40) → the `L` block of `erdos_problem_183_explicit`, 166 lines.

Tried and abandoned:
- Inlining `exists_stage` into `erdos_problem_183_explicit` (it has one use): the combined declaration exceeds the default `maxHeartbeats 200000` (timeouts in unrelated `positivity`/`nlinarith` calls), so it stays a top-level theorem rather than raising `maxHeartbeats`.
- `nlinarith` for the final linear inequality in the log comparison timed out inside the big context (it multiplies all hypothesis pairs); replaced by an exact `linear_combination 2*h₁ + h₂ + 32*h₃ + 69*h₄`.
- `rw [Real.log_div]` on `log β` looked through the `set` definition of β; fixed with `clear_value`.

## Stage C (agent-shorten)

Start: 05:15 CST. End: 05:19 CST. Builds: 6 (builds 30–35 of the session counter; +1 gate build).

Metrics line: `ramsey agent-shorten lines=611 code_lines=589 gzip_bytes=9262 theorems_env=9 defs_env=3 declarations_env=12 unreachable=0 theorems_used_0=0 theorems_used_1=4 theorems_used_2plus=1 defs_used_1=0 theorem_lines_mean=64.7 theorem_lines_median=42 theorem_lines_max=176 gate_build_seconds_module=9.3 gate_olean_bytes=3862040`

Gate: PASS. Result: 616 → 589 code lines (theorem and def counts unchanged: 9 and 3).

| Kind | Count | Example |
|---|---|---|
| `open` removes qualifications | 3 namespaces | `Finset.`/`SimpleGraph.` were already opened by the original header but still written everywhere; `open Real` added. All prefixes dropped outside the four headline statements (whose text is left verbatim). Several wrapped lines became single lines. |
| Local abbreviations | 2 | `xv`, `yv` (the label vectors fed to Φ) in `exists_stage`: the two `cases e : Φ … <;> cases e : Φ …` headers went from 4 lines to 1 each. |
| Proof branches merged with `<;>` | 1 | the two properties of Φ in `exists_covering`: 14 → 5 lines. |
| `simp` closes a goal that was built by hand | 1 | end of `forces_pow`: 5 → 2 lines (`simp` with `labelGraph_adj` after rewriting the `ℕ` equalities to `Fin` equalities). |
| Shorter term proofs | 4 | `hr`, `hrinj` in `exists_stage`; `ha1`, `hka`, `hkb` in the explicit bound (`Nat.ceil_pos`, `mul_left_comm`, `linarith`). |

## Things tried and abandoned (all stages)

- (B) Inlining `exists_stage` into `erdos_problem_183_explicit` (single use): exceeds the default heartbeat budget of one declaration. Kept as a lemma instead of raising `maxHeartbeats`.
- (B) `nlinarith` inside the large context of the explicit bound timed out twice; replaced by an exact `linear_combination` and by explicit hint terms.
- (B) `rw [Real.log_div]` matched inside the body of a `set` variable; fixed with `clear_value`.
- (C) A one-line `nlinarith`/`lt_trichotomy` proof of the injectivity of the colour encoding `(c, y) ↦ c + t·y` was not attempted inside the big context for the same heartbeat reason; the `% t`, `/ t` proof (9 lines) stays.

## Judged not worth doing

- Extracting the "k^δ ≤ base eventually" step shared by the limit in `erdos_problem_183_explicit` and the lower half of `…_sharp_coefficients`: the only way to share it is an extra top-level theorem (the explicit bound cannot use the sharp-coefficient theorem without a cycle), which would trade ~12 lines for one more statement.
- Inlining `exists_covering` and `exists_code` into `exists_stage`: they are self-contained general facts (a covering function from a random-matrix count; the Gilbert–Varshamov bound), which the brief allows to keep as lemmas, and `exists_stage` is already the largest declaration.
- A shared `variable`/`include` block for `hH hm hs` (used by `exists_covering` and `exists_stage`): saves about one line net.
- Replacing the numeric part of `exists_covering` (`H²(H-1)^(m+1) < H^(m+1)` from `m ≥ 2H log H`, 20 lines) with `Real.one_sub_div_pow_le_exp_neg`: the rewriting into the `(1 - t/n)^n` shape costs as much as it saves.

## Mathematical structure of the final proof

Upper bound (`forces_pow`): by pigeonhole on the colours of the edges at one vertex, a k+1-colouring of more than (k+1)·n other vertices contains a fibre of n vertices joined to the root in one colour ω; either the fibre has an ω-edge (triangle) or it is k-coloured after deleting ω; induction gives `Forces (2(k+1)^k) k`, hence `R(k) ≤ 2(k+1)^k ≤ 4^k k^k`. Lower bound: a triangle-free colouring is built in H stages on the colour set (position c < t, level y < H), t = a·s. Stage j is a colouring of V_j with levels < j whose colour classes carry proper labellings with labels < j. To go to stage j+1, take a code W ⊆ [j+1]^t with pairwise Hamming distance ≥ s and |W| ≥ (j+1)^t / (C(t,s)(j+1)^s) (`exists_code`, greedy Gilbert–Varshamov). The new vertex set is W × V_j; inside block w the old colours are shifted so that the colours (c, w(c)) are missing; between blocks w < w′ one picks s positions where they differ and uses a covering function Φ (`exists_covering`, from a random-matrix counting argument with s = m(m+1)+1, m ≈ 2H log H) to choose one of the 2s colours (c_d, w′(c_d)) or (c_d, w(c_d)) from the label vectors of the two endpoints. A colour missing in a block gets the fresh label j; a monochromatic triangle is impossible inside a block (old colouring), with two vertices in one block (Φ forces equal labels on a properly labelled edge), or across three blocks (each cross edge changes "missing or not", odd cycle). After H stages |V| ≥ (H!)^{(a-1)s}/C(t,s)^H ≥ (H/e)^{H(a-1)s}/(e·a)^{sH}. Given k with base β = k^{1/3}/(6e^38 log k) > 1 one takes H = ⌊e^37 β⌋, s as above and a = ⌊k/(Hs)⌋ (so a ≥ log H and k < H(a+1)s); comparing logarithms gives β^k ≤ |V| < R(k) (`lt_triangleRamseyNumber`). For β ≤ 1 the bound is trivial. The limit R(k)^{1/k} → ∞ follows from β ≥ k^{1/6} eventually; the sharp coefficients compare k^{(1/3-ε)k} ≤ R(k) ≤ 4^k k^k; the Θ statement is the case ε = 1/6.

## Summary over the stages

| Tag | Gate | Theorems | Defs | Structures | Code lines |
|---|---|---|---|---|---|
| baseline (`s3a-auto`) | PASS | 43 | 42 | 1 | 2815 |
| `agent-simplify` | PASS | 37 | 42 | 1 | 2639 |
| `agent-refold` | PASS | 9 | 3 | 0 | 616 |
| `agent-shorten` | PASS | 9 | 3 | 0 | 589 |

No `maxHeartbeats` option was raised anywhere; no `sorry`, axiom, `native_decide`, `unsafe`, `#eval`, macro or elaborator was added.
