> Log written by the rewriting agent while it worked (stages 3, 4 and 5 of this experiment), unedited except that local paths are replaced by placeholders. Its stage names: `agent-simplify` = 3, `agent-refold` (with intermediate `agent-refold-1/2/3`) = 4, `agent-shorten` = 5. Times are local time of the laptop.

# Rewriting log: CompactnessAndDegeneracy (agent-compactness)

Baseline (commit `5a01b91`, tag `s2-unroll-compactness`, metrics stage `s2-unroll`): 242 theorems, 272 defs, 4 structures, 8 instances, 17245 code lines (18156 lines). Gate PASS (module build 140 s).

Session start: 2026-11-26 05:31 CST.

## Map of the file (before editing)

Section sizes (lines) of the original file:

| Part | Section | Lines |
|---|---|---|
| I | Foundations, DensityReduction, Patterns, Quotients (definitions of the family) | 300 |
| I | Geometry / SymplecticGeometry (W(q): points, lines, counts, incidence ≅ edges) | 613 |
| I | Cyclicity, CharacteristicAvoidance, SubdivisionLineExtraction | 560 |
| I | Padding (monotonicity of ex(n,·), bracketing q = t^j, lower bound from W(q)) | 365 |
| I | LocalGeometry, BreadthFirstCounting, SubdivisionCounting, QuotientWitnesses | 670 |
| I | Separation (little-o, certificate) | 93 |
| I | Supersaturation, BadVertexCounting, TripleMassIncidence | 780 |
| I | LineCoordinates, ArbitraryLineNormalization (coordinates on Sp(4,K) lines) | 1415 |
| I | AsymptoticExtraction: `proposedFamilyFree_sixteenth_power_host_bound` (2042) + little-o (89) | 2165 |
| I | CycleBounds + Counterexample: `uniformMemberLower_of_characteristic_avoidance` (284), `proposedFamily_uniformMemberLower` (1360) | 1665 |
| I | Connectedness, Bipartiteness, FamilyExtremal, MainTheorem | 380 |
| II | BinaryEntropy (numerical entropy window) | 790 |
| II | ForbiddenGraph (pair graph H, 2-degenerate, bipartite, connected) | 338 |
| II | HammingProfiles (`pairCoordinateConditionalEntropy_empirical_bound`, 1194) | 2171 |
| II | SamplingAndHammingBalls, HammingHostAndExclusion | 940 |
| II | MainTheorem: `eventually_manuscriptExpectedRetainedEdge_entropy_lower` (554), `twoDegenerateExtremalCounterexample` (4072) | 4757 |

## Stage A (agent-simplify)

Start 05:31 CST (mapping and reading), editing from 05:40. End 06:12 CST (gate passed, tag `agent-simplify`).
Builds: 4 full builds of the subject + 3 instrumented whole-file elaborations (see below) + 1 gate build.

Metrics line:
`compactness agent-simplify lines=17624 code_lines=16724 gzip_bytes=121897 theorems_env=236 defs_env=266 declarations_env=513 unreachable=0 theorems_used_0=0 theorems_used_1=116 theorems_used_2plus=115 defs_used_1=59 theorem_lines_mean=61.6 theorem_lines_median=12.5 theorem_lines_max=3991 gate_build_seconds_module=109.0 gate_olean_bytes=38239600`

Result: 242 → 236 theorems, 272 → 266 defs, 4 → 3 structures, 17245 → 16724 code lines. Gate PASS.

Method for the automation part. With 1018 tactic `have`/theorem bodies of two or more lines it is not possible to try automation by hand. I used an instrumented copy of the file (in `.agent/`, untracked, deleted from the working tree before each gate): every candidate body was wrapped as `first | (bounded N tac₁) | … | (original body)`, where `bounded` is a small elaborator defined only in the instrumented copy that runs a tactic with its own heartbeat budget and turns a timeout into an ordinary failure (`set_option maxHeartbeats N in tac` inside a tactic block does not bound the tactic: the limit is fixed per command, which I checked; and an unbounded `grind` hung for minutes in a definitional unfolding of `jTemplate`). The `unreachableTactic` linter then tells, for each candidate, which alternative closed the goal. One elaboration of the whole instrumented file (`lean -j 6`) takes 3–5 minutes. Accepted replacements were applied outermost-first and then checked by a normal build with the normal heartbeat limits.

| Kind | Count | Example / note |
|---|---|---|
| Local proof replaced by automation (round 1: `grind`, `simp_all`) | 53 (50 `grind`, 3 `simp_all`) | 188 body lines removed |
| Local proof replaced by automation (round 2: larger `grind` budget, `nlinarith`, `positivity`, `simp [*]`, `simp_all`) | 31 (10 `grind`, 9 `positivity`, 8 `nlinarith`, 2 `simp_all`, 2 `simp [*]`) | 94 body lines removed |
| Detour removed: little-o certificate | 1 | `FamilyLittleO` (def), `SeparationCertificate` (structure), `proposedFamily_not_compact_of_bounds` (45 lines), `not_compactnessConjecture_of_bounds`, `proposedFamily_familyLittleO` (89 lines), `extremalScale_nonneg` deleted; `proposedFamily_not_compact` is now proved directly from the 16th-power bound on `familyExtremal` and the uniform lower bound (22 lines): if ex(n,F) ≤ C·fam(n) eventually then c^16 n^21 n^{1/3} ≤ C^16 K n^21, impossible for large n. `not_erdos_180` is a one-line term. |
| Wrapper removed in a headline | 1 | `quantitativeCompactnessCounterexample`: the 40-line restated conjunction `checkedManuscriptCounterexample` + `obtain`/`refine` replaced by one anonymous-constructor term (17 lines incl. the statement). |
| Wrapper lemma/def inlined | 9 | `FamilyFree.member`, `four_cycle_mem_proposedFamily`, `six_cycle_mem_proposedFamily` (local), `jQuotientProjectionHom`, `kQuotientProjectionHom`, `symplecticLinesOnPointEquiv`, `symplecticPointsOnLineEquiv` (each a one-line composition used once), named proposition `GraphHasNoIsolated` (replaced by `∀ u, ∃ v, G.Adj u v`) |
| Repeated derivation merged | 2 | C4 and C6 lower bounds in `uniformMemberLower_of_characteristic_avoidance` re-derived "padding + rpow constant" by hand (two 12-line tails); they now call the same `member_eventual_lower_of_prime_power_avoidance` as the quotient members, with the freeness facts as plain local haves. |

Before/after examples:
- `proposedFamily_familyLittleO` (89 lines) + `proposedFamily_not_compact_of_bounds` (45) + `not_compactnessConjecture_of_bounds` (8) + certificate structure and def (10) → `proposedFamily_not_compact` (22 lines).
- `quantitativeCompactnessCounterexample`: 59 → 37 lines (the statement is 20 of them).
- `jTemplate_adj_color_ne`-style case bashes were *not* replaced: `grind` hangs on them without a budget, and with a budget it fails.

## Mathematical structure (as I understand it)

Part I (Erdős #180, compactness). The family is C4, C6 and all colour-respecting quotients of two bipartite templates J (two theta graphs glued) and K (two gamma = subdivided K_{3,3}-type graphs joined at a specified centre). Lower bound: the point–line incidence graph W(q) of the symplectic generalised quadrangle (points and totally isotropic lines of a symplectic form on K^4) has 2(q+1)(q²+1) vertices and (q+1)²(q²+1) edges, is C4- and C6-free (girth 8), avoids every J-quotient when char K = 2 and every K-quotient when char K is odd (this is the long coordinate computation `proposedFamily_uniformMemberLower`, about 1300 lines, with lines of Sp(4,K) normalised to graphs of symmetric matrices); bracketing n between quadrangle sizes for q = t^j and padding with isolated vertices gives ex(n,F) ≥ c·n^{4/3} with one c for all members. Upper bound: a family-free host is reduced to a bipartite subgraph of minimum degree d ≥ e/(2n) (max cut + pruning); girth ≥ 8 gives many non-backtracking paths, and supersaturation of theta/gamma configurations around "bad" vertices (counting ordered theta triples and gamma-good fibres) gives d^16 ≤ C·n^5, hence e^16 ≤ C'·n^21, i.e. ex(n, family) = O(n^{4/3-1/48}). Non-compactness is then the incompatibility of n^{4/3} with n^{21/16}.

Part II (Erdős #146). H is the layered "pair graph": layer 0 has b vertices, layer i+1 consists of the 2-subsets of layer i, each joined to its two members; it is connected, bipartite (level parity) and 2-degenerate (the top-level vertex in any set has ≤ 2 neighbours in it). The host is a random induced subgraph (each vertex kept with probability p = 2^{-(1-β)d}) of the bipartite Hamming graph on two copies of {0,1}^d with edges at distance ≤ r. Copies of H whose layers satisfy an entropy inequality (binary entropy window, Pinsker-type tangent bounds, sampling without replacement on each coordinate) are shown to be rare (first moment over Hamming balls), the retained edge count is concentrated (second moment, Chebyshev), the vertex count is not too large (now Markov), and the resulting n-vertex H-free graph has ≥ n^{3/2+ε} edges; bracketing n between consecutive dimensions gives the eventual bound.

## Stage B (agent-refold)

Start 06:13 CST. End 08:12 CST (tags `agent-refold-1`, `agent-refold-2`, `agent-refold-3`, `agent-refold`; all gates PASS).
Builds: 6 normal builds + about 25 builds run by `scripts/unroll.py` (three abandoned runs, see below) + 4 gate builds; 6 scratch checks.

Metrics lines:
- `agent-refold-1`: `lines=17372 code_lines=16473 gzip_bytes=120619 theorems_env=236 defs_env=265 declarations_env=512 … theorem_lines_max=3747 gate_build_seconds_module=106.0`
- `agent-refold-2`: `lines=17234 code_lines=16337 gzip_bytes=119810 theorems_env=236 defs_env=263 declarations_env=510 … gate_build_seconds_module=109.0`
- `agent-refold-3` = `agent-refold`: `compactness agent-refold lines=17098 code_lines=16225 gzip_bytes=119230 theorems_env=214 defs_env=261 declarations_env=485 unreachable=0 theorems_used_0=0 theorems_used_1=99 theorems_used_2plus=110 defs_used_1=59 theorem_lines_mean=65.7 theorem_lines_median=14.0 theorem_lines_max=3747 gate_build_seconds_module=102.0 gate_olean_bytes=37836480`

Result: 236 → 214 theorems, 266 → 261 defs, 16724 → 16225 code lines.

Sub-developments in decreasing order of size, and what happened to each:

| Sub-development | Size | Action |
|---|---|---|
| Part II main argument (`twoDegenerateExtremalCounterexample`, entropy exclusion, sampling) | ~4000 | partly: vertex upper tail replaced (refold-1); rest left |
| Part I upper bound `proposedFamilyFree_sixteenth_power_host_bound` | ~2000 | partly: reduction to a bipartite min-degree subgraph replaced (refold-2, refold-3); supersaturation counting left |
| Part I char-2 / odd avoidance (`proposedFamily_uniformMemberLower`, line coordinates) | ~2700 | left as is |
| Part II `pairCoordinateConditionalEntropy_empirical_bound` | ~1200 | left as is |
| W(q) counting, padding, bracketing | ~900 | left as is (Stage A merged the cycle cases) |

| Kind | Count | Example / note |
|---|---|---|
| Argument replaced: second-moment upper tail of the retained vertex count by Markov | 1 | `hammingRetainedVertexCount_upper_tail_probability_le` (249 lines incl. variance computation, pair probabilities, square integral) → 13 lines using `MeasureTheory.mul_meas_ge_le_integral_of_nonneg`. The failure bound now has a constant term 2/3 instead of `4/E[V]`, so `manuscriptSamplingFailureBound_tendsto_zero` now tends to 2/3 (still < 1, which is all that is used); def `hammingExpectedRetainedVertexSquare` deleted. |
| Argument replaced: min-degree pruning | 1 | `exists_maximum_sharp_pruning_subgraph` + `maximum_sharp_pruning_subgraph_degree` + `maximum_sharp_pruning_subgraph_edge_positive` (about 140 lines) and defs `sharpPruningPotential`, `sharpPruningScore` (a potential with a +1 tie-break) → one induction on the number of edges with invariant e·|supp H| ≤ 2|V|·e(H), deleting a low-degree vertex (`deleteIncidenceSet`), 30 lines. |
| Argument replaced: max cut | 1 | per-vertex flip argument for a maximum Boolean cut (126 lines, defs/lemmas `booleanCut`, `booleanCut_adj`, `booleanCutDecidableRel`, `flipBooleanColor`, `flipBooleanColor_self`) → averaging over all 2^|V| colourings (each edge is cut by exactly half of them, via the involution "flip u"), 33 lines. |
| Lemma used once inlined (after the changes above made it single-use; `scripts/unroll.py`, restricted) | 20 | e.g. `edgeFinset_card_eq_natCard`, `degree_eq_natCard_neighborSet`, `symplecticPointsOnLine_card`, `cycleGraph_no_isolated`, `quotientGraph_no_isolated` … |
| Replaced by a library lemma | 4 | `MeasureTheory.mul_meas_ge_le_integral_of_nonneg` (Markov), `SimpleGraph.card_support_deleteIncidenceSet`, `Finset.card_filter_add_card_filter_not`, `Finset.exists_le_of_sum_le` |

Before/after examples: vertex upper tail 249 → 13 lines; pruning ~140 + 2 defs → 30 lines; max cut 126 + 5 decls → 33 lines.

## Stage C (agent-shorten)

Start 08:13 CST. End 08:19 CST (tag `agent-shorten`, gate PASS). Builds: 2 + 1 gate build.

Metrics line: `compactness agent-shorten lines=16717 code_lines=15844 gzip_bytes=118905 theorems_env=214 defs_env=261 declarations_env=485 unreachable=0 theorems_used_0=0 theorems_used_1=99 theorems_used_2plus=110 defs_used_1=59 theorem_lines_mean=63.9 theorem_lines_median=14.0 theorem_lines_max=3691 gate_build_seconds_module=104.0 gate_olean_bytes=37836480`

Result: 16225 → 15844 code lines; theorem/def counts unchanged.

| Kind | Count | Note |
|---|---|---|
| Statement header reflowed onto one line (have/theorem/lemma headers up to `:=`, only when the result fits in 100 columns and contains no `fun`/`match`/comment) | 267 lines saved | purely formatting |
| One-line tactic body joined to its `:= by` line | 97 | formatting |
| `:= by exact t` → `:= t` | 17 | |

This stage is mostly layout; I did not do further tactic-level golfing of the remaining 15.8k lines.

## Tried and abandoned

- Unbounded `grind` in the automation sweep: hung for minutes in a definitional unfolding (`jTemplate_adj_color_ne`); `set_option maxHeartbeats N in tac` does not bound a tactic (checked: `norm_num` proving a 7-digit prime under `maxHeartbeats 1` inside a tactic block succeeds). Fixed by the `bounded` elaborator in the instrumented copy only.
- `aesop` in the sweep: on failure it reports a warning and leaves the goal, which breaks the `first | …` detection (101 spurious errors); dropped.
- `scripts/unroll.py` on all 80 newly single-use lemmas: inlining into `proposedFamily_uniformMemberLower` (20 lemmas) made it time out, and the script kept doubling that declaration's heartbeat limit (to 4·10^11) — killed and reverted, since rule 5 forbids raising limits. Second and third attempts (excluding that user, then also `twoDegenerateExtremalCounterexample`) timed out in the other three large declarations; the fourth run excluded all lemmas whose only user is one of the four large declarations and inlined 20 (3 reverted by the script), no heartbeat raises. About an hour of build time went into this.
- Edge-count lower tail (Chebyshev, ~490 lines): cannot be replaced by Markov (it is a lower tail), and an expectation argument combining vertices, edges and the bad event fails because the bad-event probability is not small compared with the maximum possible edge count. Left.

## Not done, and why

- The two coordinate-heavy avoidance proofs (char 2 against J-quotients, odd characteristic against K-quotients; ~2700 lines with `ArbitraryLineNormalization`) and the supersaturation counting (~1500 lines) are genuine, long arguments; I saw no standard construction or Mathlib notion that replaces them wholesale, and a re-derivation would take far longer than this session.
- The entropy part of Part II (`pairCoordinateConditionalEntropy_empirical_bound`, binary Pinsker-type bound — Mathlib has `Real.binEntropy` but no Pinsker inequality) was left.
- Inlining the 59 single-use defs: many are unfolded by name in proofs; each needs individual work for one statement each.
- Unifying the two "bracket n between consecutive sizes + monotonicity of ex" arguments (Part I quadrangle sizes, Part II Hamming dimensions): the shapes differ (for all n ≥ N₀ with an explicit constant vs eventually), so a common lemma would save little.

Helper scripts (instrumenter, applier) and outputs are in the untracked directory `agent-compactness/.agent/`.
