# Block "entropy" rewrite log

Start: Thu Nov 26 09:27:57 CST 2026

## Counters
- End: Thu Nov 26 10:20 CST 2026 (wall time about 52 minutes)
- full builds: 7 in total (4 block-gate runs: base, stage1, stage2 failed, stage2 passed; 3 plain lake builds,
  one of them showing the stage2 failure)
- scratch checks (`lake env lean` on scratch files): about 30

## Base gate
`block_gate.py entropy base`: BLOCK GATE PASS. Block lines base 1446 (31 declarations: 14 theorems, 17 defs/instances). File build 121 s.

## What the block proves and how the current proof goes

The block bounds the conditional entropy of one child coordinate given the parent pair type:
H(Z|T) <= kappa + log2(3)*D + (h(v) - h(q))/2 + err(n), where the pair types T are 00, 11, mixed with
without-replacement weights W0, W1, W2 (from n parents with k ones, q = k/n), D the empirical average
disagreement, v the empirical child frequency, err(n) = (1+log2 3)/n + h(1/n)/2.

Current proof (1446 lines, 31 declarations): (1) an "independent" version for i.i.d. Bernoulli(q) pair weights:
Gibbs/log-sum inequality per pair type with amplitudes a = sqrt(1-v), b = sqrt v, then a potential bound
Phi(q,a,b) <= kappa*ln2 via tangent lines of log at fixed points sigma, rho (sqrt 2, sqrt 3 constants),
Cauchy-Schwarz, sqrt(1+x) <= 1+x/2, log(4/3) < 1/3 and a hand-made binary Pinsker inequality
(convexity of a gap function by second derivative); the boundary v in {0,1} is handled by smoothing the
kernel and a limit argument; (2) transfer from i.i.d. weights to without-replacement weights with error
terms: |E_emp f - E_ind f| <= 1/n for conditional entropy, disagreement and marginal, plus a modulus of
continuity |h(x)-h(y)| <= h(|x-y|) (subadditivity of h) and monotonicity of h on [0,1/2]; (3) the
translation from the combinatorial pair-type counts to the kernel.

## Arguments considered

1. **Direct proof with the empirical weights (no transfer step).** Observation: the without-replacement
   weights are W0 = (1-q)^2 - delta, W1 = q^2 - delta, W2 = 2q(1-q) + 2 delta with delta = q(1-q)/(n-1) >= 0,
   and in the potential the delta-term has coefficient 2 log((a+b)/sqrt3) - log(a+b/3) - log(a/3+b) <= 0
   (since (a+b)^2/3 <= (a+b/3)(a/3+b) for a^2+b^2=1). So the inequality holds for the empirical weights
   with NO error term; the contract follows since err(n) >= 0. This removes the whole step (2)
   (about 400 lines) and the marginal/entropy modulus machinery. Reaches the fixed statement: yes
   (it is stronger: error 0).
2. **Boundary v in {0,1} without smoothing.** A weighted Gibbs lemma w*(h(z) + (1-z)(log a + log c)
   + z(log b + log d)) <= w*log(ca+db) with the side conditions "a = 0 -> w(1-z) = 0", "b = 0 -> w z = 0",
   which hold automatically because sum W_t z_t = v. Lean's log 0 = 0 convention then makes
   (1-v) log a + v log b = -h(v)/2 hold for all v. Removes the smoothing kernel, the limit argument and
   continuity lemmas.
3. **Potential bound without square roots.** Gibbs constants c = d = 1 for the mixed type (the -log3/2
   is moved to the end), tangents in squared form log x <= (log s + x^2/s - 1)/2 at s = 8/9 and s = 2,
   so all constants are rational; the remaining inequality Q_W(a,b) <= 1 + (2q-1)^2/3 on a^2+b^2=1 is
   proved by an explicit SOS identity (homogenised, checked by `ring`, verified first with sympy):
   N((1+t/3)N - Q_W) = (4sN+3x)^2/48 + (e/16)(4q(1-q)N + 3e) + ((W2-2q(1-q))/8) e N.
   Replaces sigma/rho/coefficient definitions and the Cauchy-Schwarz/sqrt steps.
4. **Pinsker.** Searched Mathlib: no Pinsker, no KL lower bound for binEntropy. Shorter proof: the
   function h(x) + 2x^2 is concave on [0,1] (second derivative -1/x - 1/(1-x) + 4 <= 0 via
   `concaveOn_of_hasDerivWithinAt2_nonpos`), and the midpoint inequality between q and 1-q gives
   h(q) <= log 2 - (2q-1)^2/2 directly (no slope/derivative-at-1/2 argument). Weaker substitutes were
   checked and rejected: Bhattacharyya/Hellinger (KL >= (2q-1)^2/4) and Topsoe-type bounds are too weak;
   the argument needs KL(q||1/2) >= c(2q-1)^2 with c about 0.43, i.e. Pinsker strength.
5. Jensen on the whole potential with weights w^(3/4) (absorbing h(q)/2 as a quarter of the joint
   entropy): rejected, equality case does not match (numerically 1.244 > 1.2408 at q = 1/2).

## Stage 1 (arguments 1-4 together)
Scratch development in `Scratch.lean` (about 25 scratch checks). Replaced the whole block by
5 helper theorems placed in the old range [8333, 8406] (`binEntropy_le_pinsker`, `weighted_gibbs`,
`log_le_square_tangent`, `pairTypePotential_quadratic`, `pairTypeEntropy_bound`) and the new contract proof in
[10221, 11362]; all other block declarations deleted (the `set_option maxHeartbeats 400000 in` on line 10220 is
outside the block and stays in front of the contract). Diff: 224 insertions, 1446 deletions. Full build OK (121 s).
Gate `stage1`: BLOCK GATE PASS, block lines 1446 -> 224, contract unchanged, all changes inside the block.
Commit 9464231, tag `block-entropy-1`.

## Stage 2 (tidy)
- The four small lemmas (Pinsker, weighted Gibbs, squared tangent, SOS quadratic) became local `have`s of
  `pairTypeEntropy_bound` (with a docstring and comments); the SOS step and the final combination use
  `linarith only` with explicit product facts (nlinarith over the big context timed out); line wrapping.
- First stage2 gate FAILED: a rewrapped `(by simp only [...]; exact_mod_cast` term broke parsing (not
  scratch-checked); fixed, rebuilt, gate re-run.
- Gate `stage2`: BLOCK GATE PASS, block lines 1446 -> 223. Commit ad3ac99, tags `block-entropy-2` and
  `block-entropy-final`.
- Checked in a scratch file but not adopted: folding `pairTypeEntropy_bound` into the contract as one
  declaration also compiles (under the existing 400000-heartbeat option). Not adopted: it gives one
  240-line theorem, with the real-analysis inequality mixed into the combinatorial translation.

## What replaced what
| old | new |
|---|---|
| 31 declarations, 1446 lines (14 theorems, 17 defs/instances) | 2 theorems, 223 lines |
| independent-weights bound + transfer to empirical weights with 1/n errors, entropy modulus of continuity, monotonicity (about 450 lines) | direct proof with the empirical weights: the excess mixed weight delta only helps (SOS term `(W2-2q(1-q))/8 (a-b)^2`), error term not needed (err(n) >= 0 is used only at the end) |
| smoothing kernel + limit argument for v in {0,1} (about 110 lines) | weighted Gibbs lemma with side conditions that follow from sum W_t z_t = v |
| tangent constants sigma, rho, coefficient defs, Cauchy-Schwarz, sqrt bound (about 170 lines) | squared tangents at 8/9 and 2 plus a 3-term SOS identity checked by `ring` |
| Pinsker via convex gap function, derivative at 1/2, slope argument (about 115 lines with defs) | concavity of h(x)+2x^2 plus the midpoint inequality (about 20 lines) |
| BinaryPairKernel helper defs, without-replacement nonnegativity/error lemmas, empirical marginal defs | deleted; the contract uses `withoutReplacementBinaryPairMass_eq_pairTypeGroup` and `pairTypeGroup_probability_mul_childRatio` from outside the block directly |

## Tried and given up
- Jensen over the joint pair distribution with weights w^(3/4), absorbing h(q)/2: false at q = 1/2.
- Pinsker replacements of Hellinger/Bhattacharyya strength (KL >= t/4) and Topsoe-type bounds: too weak,
  since the route needs KL(q||1/2) >= about 0.43 (2q-1)^2.
- `nlinarith` for the SOS and final combination inside the large context: heartbeat timeouts. Replaced by
  `linarith only` with explicit products.

## Verdict
The remaining 223 lines are short because the mathematics turned out shorter, not because the budget ran out.
The old length came from a detour (independent weights, then transfer with error terms, then smoothing) and
from hand-built constants. What remains is long because the mathematics is long, and it has four pieces that
seem unavoidable: (1) Gibbs per pair type (any route needs it, since the statement is tight at q = 1/2,
a = b); (2) a quadratic bound on the log terms, which here is 3 tangents and an SOS; (3) a Pinsker-strength
bound on binary entropy, which is not in Mathlib and needs one calculus step (one second-derivative concavity
argument); (4) the combinatorial translation (pair-type counts, child-ones fiber sum, mass formulas), about
65 lines, which uses the outside lemmas as directly as possible. Shorter routes looked for and rejected:
Mathlib KL/Pinsker (absent), weaker entropy bounds (too weak, see above), Jensen with power weights (false),
and dropping the boundary case (needed, since log 0 = 0). The one possible further step is only cosmetic:
folding everything into one declaration (checked in a scratch file, not adopted).
