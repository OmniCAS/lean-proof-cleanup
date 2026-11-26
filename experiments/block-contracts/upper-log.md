# Block "upper" rewrite log

- Start: Thu Nov 26 09:27:57 CST 2026
- End: Thu Nov 26 10:30:27 CST 2026 (about 1 h 03 min)
- Full builds: 7 (3 standalone `lake build`, 4 inside gate runs); scratch checks: about 22

## What the block proves and how the current proof goes

Contract: every `proposedFamily`-free graph on `n` vertices has `e^16 ≤ C n^21`
(`C = 2^16 (48^4 + 1769472 + 1)`). The current proof (a) passes to a bipartite
subgraph `B` on `N ≤ n` vertices with minimum degree `d ≥ e/(2n)` (max cut plus
pruning), (b) uses that `B` is C4- and C6-free and bipartite (girth ≥ 8), and
(c) shows `d^16 ≤ 1769472 N^5` by a supersaturation count: vertices that are
not the specified centre of a subdivided K_{3,3} ("gamma-bad") form a vertex
cover (K-quotients), so `#bad ≥ e (d-1)^2 / N` (3-path count, degree ≤ N/(d-1)^2);
for each bad vertex the 4-paths are grouped into fibres by endpoint; heavy
fibres (≥ p/(2N)) carry a cubic triple mass; each triple of common second
neighbours with two common centres is an ordered theta triple, and a bad vertex
can share such a triple with only one further centre; the number of ordered
theta triples is at most `N^3/d` because theta extensions of a fixed pair are
pairwise without common neighbour (J-quotients). The arithmetic then yields
`d^5 (d-1)^11 ≤ 864 N^5`.

## Arguments considered

1. *Is a weaker hypothesis enough?* C4,C6-freeness alone gives only `n^{4/3}`
   (generalized quadrangle), and `21/16 < 4/3`, so both the J- and the
   K-quotients are genuinely needed; no route avoiding the supersaturation
   count exists at this exponent. Rejected on paper.
2. *Same mathematics, re-organised count (adopted).* Keep the reduction to a
   bipartite min-degree subgraph (already short), keep the J/K forcing idea, but
   replace the whole counting layer:
   - Vertex cover: good vertices (marked centre of a girth-8 K'_{3,3}
     configuration) are independent by K-freeness, so
     `N d ≤ Σ_deg ≤ 2 Σ_{u bad} deg u` (no 3-path count, no `Δ (d-1)^2 ≤ N`).
   - For every vertex `u`: `Σ_{v far} c(u,v) ≥ deg(u) (d-1)^3` by two
     applications of one "two-step" lemma and double counting
     (`sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow`), where `c(u,v)` is
     the number of common second neighbours.
   - Heavy fibres replaced by power mean: Mathlib's
     `pow_sum_le_card_mul_sum_pow` (Jensen for cubes, in ℕ) and
     `Nat.pow_sub_le_descFactorial` + `Fintype.card_embedding_eq` give
     `(Σ_v (c-2))^3 ≤ N^2 Σ_v #(injective triples)`.
   - Upper bound: one injection
     `(u bad, v far, x injective triple, w ~ x0) ↦ (x1, x2, w, [u<v])`
     into `Fin N^3 × Bool`, injective by J-freeness (x0 is determined by
     x1,x2,w) and by badness of `u` (the centre pair is determined up to order).
     This merges theta-count, `|ext|·d ≤ N`, bad-triple ≤ 2·theta into one
     statement: `d Σ_{u bad} Σ_v T ≤ 2 N^3`.
   - Arithmetic: high case `d^4 (d-1)^9 ≤ 32 N^4`, i.e. `d^13 ≤ 2^14 N^4`,
     which implies `d^16 ≤ 2^18 N^5` (13th-power trick); low case
     `d^4 ≤ 32 N`. Overall `d^16 ≤ 2^20 N^5 ≤ compactnessDegreePowerConstant N^5`,
     so the fixed constants are reached with room to spare.
   - Copies: instead of building `Copy thetaGraph`/`Copy gammaGraph` and
     gluing copies, build the J/K homomorphisms directly from configurations
     (bases, centres, chosen midpoints); the quotient is handled by
     `Function.invFun g ∘ g` instead of a hand-made kernel normal form.

## What was replaced by what (with line counts, block lines from the gate)

- Stage 1 (`block-upper-1`, gate PASS, 2961 -> 912 lines). Deleted the whole
  four-path / three-path machinery (`NonbacktrackingNeighbor`, `...FourPath*`,
  `...ThreePath*`, witnesses and equivalences), the theta/gamma `Copy`
  constructions and gluing (`gluedJ*`, `gluedK*`, `thetaBaseExtensions`,
  `tripleCommonCenters`, `IndependentThetaTriple*`, `BadFourPathTriple*`,
  `commonSecondNeighborFinset`, heavy-fibre masses, `gammaBadVertices`,
  `kernelNormalForm*`, `kernelQuotientCopy`, `encodeFiniteGraphCopy`), and the
  1,500-line counting inside the contract. New: `two_step`, `card_second`,
  `card_far`, `card_paths` (path counts), `img_rel`, `img_color`,
  `exists_conf` (configurations), `free_of_hom`, `nf_eq` (quotient via
  `invFun g ∘ g`), `k_free`, `jMap`, `jEmb`, `j_free` (direct J/K homs),
  `Good`, `good_adj`, `theta_unique` (forcing), `triple_lower`, `per_vertex`,
  `cover`, `triple_count`, `core` (counting and arithmetic). Constant reached:
  `d^16 ≤ 2^20 N^5`, then `e^16 ≤ 2^36 n^21 ≤ C n^21`.
- Stage 2 (`block-upper-2`, gate PASS, 912 -> 789). `subdivisionVertexImage_injective`
  117 -> 40 lines (colour argument instead of three nested helper lemmas);
  new `cycle_of` (a cycle copy from an injective cyclic sequence) shortens
  `common_neighbor_unique_of_four_cycle_free` and
  `common_neighbors_triangle_eq_of_cycle_free` (75 -> 35 lines).
- Stage 3: the counting is generalised from `Fin n` to any finite type, so the
  min-degree subgraph is used directly as `H.induce H.support` (no transfer to
  `Fin N`, no `familyFree_of_embedded_subgraph`); the two lemmas
  `proposedFamilyFree_four_cycle/six_cycle` are inlined.
  (`block-upper-3`, gate PASS, 789 -> 717.)
- Stage 4 (`block-upper-4` = `block-upper-final`, gate PASS, 717 -> 706, 0 warnings):
  `card_second` inlined, `[Fintype V]` given per lemma instead of as a section
  variable (removes the unused-variable linter warnings).

Final block: 706 lines (base 2961), 32 declarations (base 93): 27 theorems
(base 42) and 5 definitions (base 51 definitions and instances).

## Tried and given up

- Replacing the max-cut + pruning reduction (about 95 lines, from an earlier run):
  Mathlib has no max-cut or min-degree-subgraph lemma; bipartiteness cannot be
  dropped (the J/K quotients are colour-respecting, and the bipartite double
  cover does not preserve them). Kept as is.
- Rewriting the `Nat.card` bridging lemmas `edgeFinset_card_eq_natCard` /
  `degree_eq_natCard_neighborSet` away with Mathlib simp lemmas: the reverse
  `Nat.card_eq_fintype_card` also rewrites `Fintype.card V` and breaks the
  pruning statement; not worth the risk for 11 lines.

## Verdict for what remains

The mathematics is settled and the remaining 706 lines are, in my judgement,
mostly the price of the fixed encodings rather than a long argument. On the
mathematical side: no shorter route at exponent 21/16 exists that I could find.
C4/C6-freeness alone allows n^{4/3}, so J and K are both needed. A cubic
supersaturation count over common second neighbours is the natural way to use
them, and it is now a single Jensen step plus a single injection. The
remaining argument is short on paper (about one page). What resists is
engineering forced by the statement: (i) the J/K templates are concrete sum
types, so the homomorphism, colour-respecting and per-copy injectivity facts
are case analyses (about 200 lines for `k_free`, `j_free`, `jMap`, `jEmb`,
configurations and the quotient-by-`invFun` lemma); (ii) the girth-8 facts
(two cycle lemmas, injectivity of subdivision images, about 110 lines); (iii)
the bipartite min-degree reduction (about 95 lines). So the remainder is not
long because the mathematics is long, and the budget did not run out either
(about 1 h of 3 h used). I stopped because further gains would be line-level
polishing of these case analyses, worth perhaps 50–100 lines at most. The most
promising next step would be a generic lemma for building
colour-respecting, copy-injective homomorphisms out of arbitrary sum-type
templates from per-component injective maps, shared by J and K. It would
probably save 60–80 lines.
