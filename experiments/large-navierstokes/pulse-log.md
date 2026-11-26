# Slice "pulse" log

- Start: Thu Nov 26 10:31:40 CST 2026
- Counters (running): see end of file for final numbers.

## What the block proves and how (as found)

The contract says: for fixed P, m, K there is lam₀ > 0 such that for every tail datum with
lam < lam₀, h ≤ lam/100000 and the canonical wait, every reset witness, every |eta| ≤ 1 and every
pulse time y, the four `PulseConeAt` inequalities hold for the corrected amplitude:
Qs > 0, shearB·directionRatio ≤ 0.74, 2·b·v + b²/A + (A−2)v² ≤ 1.68, radialA > 2.

The existing proof: on the pulse radialA = 2 + 2lam exactly; shearB = −R + O(lam) where
R = amp·mainPulse(lam·y) ≥ 0; directionRatio = Ns/(E·Qs) is expanded as
(angular equilibrium · mainDirection + O(lam²) lag error − (1/2−h)·eta·∂_eta(lag) + pressure/energy
history error)/Qs, with Qs within O(lam^28) of the equilibrium (shaped-wait estimate + ODE barrier)
and Qs ≥ lam/4 + eta²/5; mainDirection is then compared with the ideal 2R − C·Z (C ≤ 2.001,
Z ≤ 6/5). All errors are bounded by a constant times coneRate(lam) = lam + √lam(1+log(1/lam)),
which → 0, and a numerical lemma turns |b+R|, |v−(2R−CZ)| ≤ eps into the two margins
(max of −2R²+2.41R is 0.726 < 0.74, of −3.5R²+4.82R is 1.66 < 1.68).

Constraints discovered: several block declarations are used by out-of-block code that must keep
compiling, so their statements are fixed too: `pulse_history_bounds` and `historyConstant`
(PulseEnergyHistory, used by `corrected_pulse_history_bounds`), `linearLag_abs_le` and
`angularLag_hold_error` (ShapedWaitBounds, used by `canonical_hold_estimates`), `shapeRate`
(OutgoingHistories), `coneErrorBudget` (used by the private `cone_budget_eps_le_one`).
Private helper lemmas (`quotient_remainder_bound`, `normalized_axial_bound`, `raw_error_le_rate`,
`direction_identity_algebra`, `cone_budget_eps_le_one`) and `coneRate*` lie outside the block ranges
and can be used for free.

## Is a cruder argument possible? (mathematical question)

The margins are tight: the first margin needs C·Z ≤ 2.43 with Z up to 6/5, so C must be ≤ 2.02
while its true value is 2 + o(1); the direction ratio must be known to o(1) uniformly in eta,
including eta ~ √lam where Qs ~ lam. This forces: the lag expansion to second order (error o(lam)),
the fine parameter-derivative bound (|∂_eta lag| ≤ 3·mainBound·|amp'| + O(lam²), with
|amp'| = O(lam log 1/lam), divided by Qs ≥ |eta|·√lam/4), the O(lam^28) equilibrium error of Qs,
and the exact coefficient C. Crude bounds are possible only where errors are super-exponentially
or polynomially tiny (energy/pressure histories multiplied by E = O(lam^30)), and the block already
uses crude bounds there. So no shorter mathematical route was found; savings are from removing
unused statements, merging, and tighter proofs.

## Changes (with line counts)

1. PulseLag: `fullError_bounds_of_amplitude_bounds` proved only the value bound actually used
   (the parameter-derivative half and `affineError`, `pulseError`, `fullError_eq` deleted);
   direct proof from `affineLag_error` + `initial_memory_bound`. Gate stage1 PASS, 2035 → 1923.
   Tag block-pulse-1.
2. PulseEnergyHistory: `pulse_history_bounds` (fixed statement) reproved: 320 → 192 lines
   (one forcing bound, linear `linarith` certificates in place of long chains, single integration
   helper specialised to the fixed constants).
3. PulseCone: cone-margin lemma reproved by explicit product certificates (90 → 35 lines);
   `actual_Qs_pulse_error` reproved with the two ODE barriers inline (93 → 65);
   `corrected_pulse_cone`, `correctedPulseBudget`, `amplitudeDerivativeConstant_pos` folded into
   the contract.
   Gate stage2 PASS, 2035 → 1697. Tag block-pulse-2.
4. PulseCone (after tag 2): `axialHistoryError_bound` lifted out of `directionRatio_error_bound`
   and reproved with explicit linear certificates (145 → ~100); `actual_component_errors`
   assembly shortened; `pulseRatio_abs_le` reused instead of a duplicate proof.
   (Lesson: the margin lemma as a local `have` inside the large `actual_pulse_cone` timed out;
   as a top-level theorem it is instant.)
5. ShapedWaitBounds: `angularLag_hold_error` (fixed statement) reproved with one source bound and
   product certificates, 107 → 65 lines.
6. PulseLag: `affineLag_error` reproved with the two integrations by parts inline (117 → ~85),
   tested in scratch.
   (Also `normalizedLag_parameter_fine_bound` lifted to a top-level theorem, 48 → 37.)
   Gate stage3 PASS, 2035 → 1542. Tag block-pulse-3.
7. Final round: contract threshold chosen with one `Filter.Eventually` conjunction and
   `mem_nhdsGT_iff_exists_Ioo_subset` instead of the nested `min` bookkeeping and the local
   `exists_pulseBudget_threshold`; `linearLag_abs_le` (fixed statement) reproved with the two
   barriers directly (23 → 14); shear bound in `shearB_main_error` by four product certificates.
   (A string-index slip in my edit script duplicated half of PulseCone.lean once; caught by the
   build and repaired from the duplicated copy before any gate.)
   Gate final PASS, 2035 → 1512. Tag block-pulse-final.

## Tags and gates

| tag | gate | block lines |
|---|---|---|
| block-pulse-1 | stage1 PASS | 1923 |
| block-pulse-2 | stage2 PASS | 1697 |
| block-pulse-3 | stage3 PASS | 1542 |
| block-pulse-final | final PASS | 1512 |

Declarations: 98 (58 theorems, 40 definitions) → 95 (58 theorems, 37 definitions).
Removed: `affineError`, `pulseError`, `fullError_eq`, `corrected_pulse_cone`, `correctedPulseBudget`,
`amplitudeDerivativeConstant_pos`. Added as top-level theorems (formerly local `have`s or new):
`perturbed_cone_margins`, `axialHistoryError_bound`, `normalizedLag_parameter_fine_bound`.

## Tried and given up / not pursued

- A cruder cone argument (dropping the ideal direction 2R − C·Z or the exact coefficient C):
  impossible, the margins need C·Z ≤ 2.42 with Z = 6/5 attainable, i.e. C ≤ 2.016 against a true
  value 2 + o(1).
- First-order lag expansion only: its remainder is O(lam), which after division by Qs ~ lam is O(1);
  the second-order expansion is needed.
- Replacing the fine bound on ∂_eta(lag) by the crude O(1) bound: the term (1/2−h)·eta·∂_eta(lag)/Qs
  is then O(1/√lam) near eta ~ √lam; the fine bound (O(|amp'|) + O(lam²)) is needed.
- One master constant for all named constants (≈ 115 lines of defs and `_pos` lemmas): would save
  perhaps 50–60 lines but requires re-proving every bound against products of a single constant;
  not attempted for lack of budget relative to the gain.
- Statements of `pulse_history_bounds`, `historyConstant`, `angularLag_hold_error`,
  `linearLag_abs_le`, `shapeRate`, `coneErrorBudget` could not be weakened (out-of-block users).

## Verdict

What remains resists mainly because the mathematics is long, not because the budget ran out.
The contract's existential threshold does not buy crude estimates where it matters: the two cone
margins are within ~2% of the ideal values, so the direction ratio must be computed to o(1)
uniformly in eta, which forces the second-order lag expansion, the fine parameter-derivative bound,
the O(lam^28) equilibrium error of Qs (shaped wait + two-sided ODE barrier), the exact coefficient C
and the ideal-direction comparison. Where errors are tiny (energy and pressure histories times
E = O(lam^30)) the proof was already crude. Further shortening is local only: a single master
constant (≈ 50 lines) and tighter versions of `main_profile_bounds`, `mainDirection_ideal_error`,
`scaledPulse_correction_bounds`, `derivativeCoefficient_le` (≈ 10–15 lines each). Six block
declarations carry statements fixed by code outside the block, which also caps the reduction.

- End: Thu Nov 26 12:09 CST 2026 (about 1 h 40 min of wall time).
- Builds: 9 (2 failed and fixed: a local-`have` timeout, an edit-script slip). Scratch checks: 24.
  Gates: 4, all PASS.
