# block-lower run log

- Start: Thu Nov 26 10:21:15 CST 2026
- End: Thu Nov 26 11:14 CST 2026 (wall time about 53 minutes)
- Full builds: 3 (plus 3 gate runs: base, block-lower-1, block-lower-2); scratch checks: about 25

## What the block proves and how the current proof goes

Contract: `UniformMemberLower proposedFamily manuscriptLowerConstant`, i.e. for every member F of the
family (C4, C6, every admissible quotient of the J template, every admissible quotient of the K template)
ex(n, F) >= 54^(-4/3) n^(4/3) for large n (54^(-4/3) = 2^(-4/3) 27^(-4/3)).
Current proof: host graph = incidence graph of the symplectic generalised quadrangle W(q), points and
lines as submodules of K^4 (Projectivization counting, (q+1)(q^2+1) points/lines); C4/C6-freeness from
"two points on at most one line" and "no triangles"; J-quotients avoided for q = 2^j (line side by a
char-2 regularity argument, point side by symplectic orthogonality), K-quotients avoided for q = 3^j
(odd characteristic: three pairwise opposite lines have at most two common transversals, proved via
normalising two lines by a symplectic automorphism and coordinates of lines as symmetric 2x2 matrices);
then padding with isolated vertices and bracketing n between powers of t (t^3 <= 27).
3914 lines, 120 declarations (67 theorems, 53 defs/instances).

## Arguments considered

1. **Wenger graph D(3,q) instead of W(q)** (chosen). Points and lines are triples in K^3, point
   (x,y,z) on line (a,b,c) iff b = xa - y and c = xb - z. It is known to be the incidence graph of W(q) with the
   vertices at distance <= 3 from a flag deleted (not used in the proof: girth and avoidance are
   proved directly), and every statement becomes polynomial algebra in K. Constants:
   2q^3 vertices, q^4 edges, so V^4 = 16 E^3 exactly, the same 2^(-4/3) as the quadrangle; with
   q = t^j, t in {2,3}, bracketing n between 2 t^(3j) and 2 t^(3j+3) gives n <= 54 q^3, i.e. exactly
   the fixed constant 54^(-4/3). Reaches the statement. The key algebraic facts found on paper:
   - two lines through a common point differ by (a-a')(1,x,x^2): line side = differences on the cone
     b^2 = ac (the Q(4,q) side); polar identities sigma*P(v,x) = -Q(v), Q(v) = sigma*tau*(x-w)^2;
   - K (odd q, line side): Q(v')P(v,x_j) = Q(v)P(v',x_j) at three distinct x_j forces Q(v')v = Q(v)v',
     then Q(v) = Q(v') and v = v' (two bases coincide); no girth argument needed, only injectivity;
   - J line side (q even): the same polar identity with two centres and x -> x^2 injective gives
     B_i - B_2 proportional to B_3 - B_2 in coordinates 1,3; a common point of B_0, B_1 then forces
     q_0 = q_1 and B_0 = B_1;
   - J point side (any q): points collinear with c form the plane z_p - z_c = x_c y_p - y_c x_p; two
     centres cut out an affine line, so B_0, B_1 lie on the line B_2B_3, and the collinearity form
     restricted to that line is (lambda - mu) * R(B_3,B_2) with R(B_3,B_2) != 0.
   `grind` (ring solver) proves the incidence identities; the main steps are explicit
   `linear_combination`s.
   Result: tag block-lower-1, gate PASS, block 3914 -> 476 lines (gate count), 120 -> 34 declarations
   (31 theorems, 3 defs). Built at 11:00, ~40 minutes after start.

2. **Keep W(q), shorten only the coordinate avoidance proofs** (not pursued). The W(q) model needs
   points/lines as submodules, Projectivization counting, symplectic automorphisms to normalise two
   opposite lines and the symmetric-matrix chart of lines; even a perfect avoidance proof keeps the
   ~600 lines of setup. Option 1 removes all of it, so this was dropped on paper.
3. **Random/deletion constructions or C4-freeness alone** (rejected on paper). Every quotient is
   bipartite of girth >= 8 for the identity quotient, and the theta theta(4,4,4) inside J has
   ex = Theta(n^(5/4)) (Verstraete-Williford, as I recall; not checked here), so the host must contain thetas and have density
   n^(4/3); the deletion method gives at most n^(2-19/25). Some algebraic girth-8 graph is necessary.
4. **A side-swapping automorphism of D(3,q) in characteristic 2** to reduce the J point side to the
   J line side (would save about 125 lines). Rejected: to my recollection Wenger graphs W_n(q), n >= 2, are
   not vertex-transitive (Lazebnik-Viglione), so no such automorphism exists (not re-checked); the point side
   (symplectic plane argument) and the line side (cone argument) are genuinely different.
5. **One generic extraction lemma for both orientations of a subdivision copy** (would save ~25
   lines through a bipartite-graph abstraction and a Sum.swap isomorphism). Judged not worth the
   extra abstraction; the two 34-line lemmas stay.

## What was replaced by what

- Old block (3914 lines, 120 declarations): symplectic space, points/lines as submodules, counting
  via Projectivization, W(q) incidence graph, subdivision-copy plumbing, symplectic automorphisms,
  line normaliser, symmetric-matrix chart, characteristic-2 and odd-characteristic avoidance,
  padding/bracketing.
- New block (gate count 488 lines; 36 declarations = 31 theorems + 5 defs/abbrevs):
  coordinates and incidence `wengerInc` with the forms `wQ`, `wR` (about 20 lines); incidence
  identities proved by `grind` (triangle, uniqueness, polar, first-coordinate lemmas, collinearity:
  about 80 lines); K avoidance (pencil lemma + gamma: 45 lines); J line side (char 2: 55 lines);
  J point side (65 lines); the graph, C4/C6 freeness (55 lines); extraction of subdivision copies
  (70 lines); template avoidance from homomorphisms (65 lines); counting, constant, bracketing (55
  lines); no-isolated-vertex facts and the contract (65 lines).
- block-lower-1: first transplant, 476 lines. block-lower-2 = block-lower-final: descriptive names,
  `wQ`/`wR`, lines wrapped to 100 columns, docstrings: 488 lines.

## Tried and given up

- `grind` on a 64-way case split for the 6-cycle hit the heartbeat limit; replaced by a hexagon lemma
  that walks the cycle with `wenger_adj_inl/inr` (no new heartbeat options).
- `simpa` with `Sum.inr.injEq` on copy injectivity did not fire through the `SubdivisionVertex`
  abbreviation; explicit `Sum.inl.inj`/`Sum.inr.inj` used instead.
- Rewriting the encoded quotient with `free_congr_left` directly at the concrete type timed out in
  `whnf`; a generic lemma `encodeFiniteGraph_free` avoids it.

## Verdict

The judgment of the earlier run (that the ~2,700 lines of coordinate avoidance proofs were long
genuine arguments) does not hold: the detour was the model, not the mathematics. In the Wenger graph
D(3,q) all three avoidance arguments are a few explicit polynomial identities (each 25-65 lines,
including statements), and the whole block is 488 lines instead of 3914, with no change to the fixed
constant. What remains resists for structural reasons, not budget: the two avoidance sides for J are
different geometries (point side = symplectic regularity, line side = characteristic-2 quadric
regularity) and no duality of D(3,q) identifies them; K needs odd characteristic and J needs
characteristic 2, so two field families and the bracketing stay; the counting/padding/no-isolated
plumbing is dictated by the statement (`extremalNumber` is not monotone for graphs with isolated
vertices). Remaining savings visible are cosmetic (merging the two orientation-specific extraction
lemmas, ~25 lines; some shared bookkeeping in the J/K reductions), estimated at under 10%.
The budget was not the limit (about 53 of 180 minutes used).
