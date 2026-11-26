# Block "matching" rewrite log

- Start: Thu Nov 26 11:15:50 CST 2026
- Base block size: 1571 lines (51 declarations: 32 theorems, 19 defs/structures)

## What the block proves and how (base)

The contract `exists_ordered_matching_threshold` gives, for a fixed outgoing profile F, order N and
tolerance rho, a control tolerance eps, then per (j, prep) a scale threshold Λ0, per Λ a shape time
T and a normalisation threshold C0, such that every control c with shapeTime = T and SmallControl c N eps
satisfies MatchingBounds: separation < e^-8, normalised five-row debt jets < rho, and the shape slope
window [11/20, 13/20].

Base proof: (1) `FixedBounds` packs constants depending only on F, N (normaliser of the debt, jets of
4η, idealAmplitude, logShape). (2) eps = driftBudget/3. (3) Seed bounds from
`TransitionRamp.ordered_seed_bounds` (uniform-in-C jet bounds of the seed fields u ≤ B, f ≤ K/C and
of the endpoint log ≤ BJ, built from the natural-profile coefficient estimates and the ramp's
log-control), (4) `ShapeTransition.shapeField_jets_uniform` (jets of the shaped field, split at X = Xi:
before Xi the seed bound, after Xi the held power law re-expressed through `angular`/`amplitude`/`blend`),
(5) `resetDebtJetSize_bound` (15 explicit row/ideal/restore jet bounds, with exact polynomial
coefficients `prefixCoefficient`, `idealPrefixCoefficient`, `vanishingDebtBound`, `restorationBound`),
(6) `vanishingDebtBound_tendsto` and the budgets `prefixBudget`, `driftBudget`, `vanishingSum` to choose C0.

## Log

### Stage 1 (11:20-12:00) — tag block-matching-1, gate PASS, 1571 -> 1128 lines

Replacements (all reach the fixed statement; checked in a scratch file, then gated):
- `resetDebtJetSize_bound` (396 lines) + `prefixCoefficient`, `prefixJetSize`, `idealPrefixJetSize`,
  `idealPrefixCoefficient`, `restoreJetSize`, `resetDebtJetSize`, `vanishingDebtBound`, `restorationBound`,
  `vanishingDebtBound_tendsto` -> four lemmas `prefix_rows`, `ideal_rows`, `restore_rows`, `debt_jets`
  (~190 lines). Crude constants: everything in the vanishing part is bounded by one
  m = 2^n M^2 (L+1) times (r + r^(1/5) + 1/C^2); the drift part by 6·2^n·M0·δ with M0 only from F, N.
  The in-block parameter-integral lemma was replaced by the existing `integral_jet_bound_on`.
- `shapeField_jets_uniform` (172 lines, with the `angular`/`amplitude`/`blend` chain and the case split at
  X = Xi using the held power law) -> the shaped field is old·exp(s·(logShape − li)) with s ∈ [0,1]; one
  product bound with the seed bound K/C (valid for all X ≥ 0) and an exp-composition bound
  (`shape_factor_jets`, `exp_jets`, ~25 lines). The hold formula is no longer needed.
- `FixedBounds`/`fixedBounds_exists`/`fixedBounds`, `prefixBudget`, `vanishingSum`, `driftFactor`,
  `driftBudget` (+lemmas), `SeedJets`, `blend_contDiff`, `shapeJetConstant` -> inlined `obtain`s in the
  contract proof; C0 from one `Tendsto` of K0·Q·(r + r^(1/5) + 1/C^2).
- Note: Lean's per-declaration heartbeat limit forced splitting the debt bound into four lemmas.

### Stage 2 (12:00-12:20) — tag block-matching-2, gate PASS, 1128 -> 985 lines

The seed bounds (`TransitionRamp`, 534 block lines: `exists_normalized_natural_jets`, `normalizedInitial`,
`normalizedLog` and their five lemmas, `endpointLog_jets_of_control`, `axialVelocity_jets_of_control`,
`physicalF/U_postaxis_jet_bound`, `exists_naturalU_jets`, `naturalF_jet_bound`, `normalizedInitial_jets`,
`ordered_seed_bounds`) were replaced by one development in `MatchingDebtBounds` (~350 lines):
- natural f: product route f = C⁻¹·exp(Λ·phase)·φ(ΛX,·) (no logarithm, no lower bound on φ needed);
  `local_product` transfers the global product estimate to functions smooth only on the parameter
  interval via the existing `extendParameter` retraction.
- post-axis f: f(X) = f_nat(radius0)·exp(g), g = logAmplitude − initialLog; one lemma `log_gap` gives
  g ≤ 1, positive jets of g ≤ 1 for all clocks (hold after the angular ramp), and g ≥ −2 at the final clock;
  `axial_gap` the same for the axial field. No normalised-log definitions.
- endpoint log: log C + initialLog = Λ·phase + log φ(4,·) (log composition only at Y = 4).
- kept from the base: `phase_smooth`, `compact_scalar_jets`, `local_composition_jet_bound`,
  `physical_fields_natural` (needed, or needed by a kept `include d in`).

### Stage 3 (12:05-) — exists_duration via the existing `OutgoingTail.sigma_derivative_le`
- `exists_duration` (53 lines, re-proving that σ' is bounded) -> `slope_window` (14 lines) using the
  already-proved bound 0 ≤ σ' ≤ stepBound in `OutgoingTail`.
- fixed jet constants via the existing `compact_scalar_jets`; `jet_add` merged into the ContDiffAt version.
- Gate stage3: BLOCK GATE PASS, 985 -> 937 lines. Tagged block-matching-3. (The gate output also printed a
  server-side script warning at slice_server.sh line 81 and "build 6s (module None s)", since the
  preceding `build` had already compiled this state; G1–G4 were all True.)
- `commit block-matching-final` answered "nothing to commit, working tree clean": the final state is the
  block-matching-3 commit (fcac84c); whether the extra tag was attached could not be checked from here.

## Summary
- End: Thu Nov 26 12:16 CST 2026 (about 1 h wall time). Builds: 6 (1 failed). Scratch `lean` checks: ~14. Gates: 3, all PASS.
- Block: 1571 -> 937 lines; 51 declarations (32 theorems, 19 defs/structures) -> 29 theorems, 0 defs.

## Tried and given up / not pursued
- Avoiding the logarithm of the coefficient profile altogether: not possible, because the endpoint log
  (initialShape) enters the shape factor exp(s(logShape − li)) and the slope window. It is now needed
  only at Y = 4.
- Bounding rows and ideal rows jointly, or turning the ideal rows into integrals and reusing
  `integral_jet_bound_on`: fails because the ideal densities are not smooth at x = 0 (√(2x), x^(1/10),
  x^(-4/5)). The three weights are computed or bounded by hand (~30 lines).
- Compactness instead of the explicit seed estimates: does not apply, because the bounds must be uniform in C,
  the coefficient solution E, and all control choices (a non-compact family).

## Verdict
What remains resists mainly because the mathematics is long, not because the budget ran out. The block has
to bound the jets of 13 concrete parameter integrals (5 rows, 5 ideal rows, 3 restoration integrals),
with the 1/C factor tracked so that the prefix part vanishes and the drift constant kept independent of the
seeds. It also needs seed bounds uniform in C, E and the controls, in two regimes (natural profile with the
coefficient-ball estimate; ramp with the log-control and the hold), plus the log at Y = 4. Each of these is a
few short lemma applications now; I see no shorter route for any of them. Remaining slack is polish only
(perhaps 50–100 lines): a generic weighted-row lemma for the four prefix rows, folding the E0 monotonicity
into `shape_factor_jets`, and shortening the post-axis F step in `seed_bounds`.
