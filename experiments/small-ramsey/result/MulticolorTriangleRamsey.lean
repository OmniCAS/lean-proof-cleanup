import Mathlib

namespace ErdosProblems.MulticolourTriangleRamsey

open Filter Finset SimpleGraph
open scoped Topology
open Real

def TriangleFree {n k : ℕ}
    (C : SimpleGraph.TopEdgeLabeling (Fin n) (Fin k)) : Prop :=
  ∀ colour : Fin k, (C.labelGraph colour).CliqueFree 3

def ForcesMonochromaticTriangle (n k : ℕ) : Prop :=
  ∀ C : SimpleGraph.TopEdgeLabeling (Fin n) (Fin k), ¬ TriangleFree C

noncomputable def triangleRamseyNumber (k : ℕ) : ℕ :=
  sInf {n : ℕ | ForcesMonochromaticTriangle n k}

theorem exists_covering {H m s : ℕ} (hH : 2 ≤ H) (hm : 2 * (H : ℝ) * log H ≤ m)
    (hs : m * (m + 1) < s) :
    ∃ Φ : (Fin s → Fin H) → (Fin s → Fin H) → Fin s ⊕ Fin s,
      (∀ x x' y d, Φ x y = .inl d → Φ x' y = .inl d → x d = x' d) ∧
        (∀ x y y' d, Φ x y = .inr d → Φ x y' = .inr d → y d = y' d) := by
  classical
  have key : H ^ 2 * (H - 1) ^ (m + 1) < H ^ (m + 1) := by
    have h0 : (0 : ℝ) < H := by positivity
    have e1 : (H : ℝ) - 1 ≤ H * exp (-1 / H) := by
      have := add_one_le_exp (-1 / (H : ℝ))
      have : (H : ℝ) * (-1 / H + 1) = H - 1 := by field_simp; ring
      nlinarith
    have e2 : (H : ℝ) ^ 2 * exp (-1 / H) ^ (m + 1) < 1 := by
      have h3 : (↑(m + 1) : ℝ) * (-1 / H) = -((m + 1) / H) := by push_cast; ring
      have h4 : 2 * log H < (m + 1) / H := by rw [lt_div_iff₀ h0]; linarith
      rw [← exp_nat_mul, h3, ← exp_log (by positivity : (0 : ℝ) < H ^ 2),
        ← exp_add, exp_lt_one_iff, log_pow]
      push_cast; linarith
    have : ((H ^ 2 * (H - 1) ^ (m + 1) : ℕ) : ℝ) < ((H ^ (m + 1) : ℕ) : ℝ) := by
      push_cast [Nat.cast_sub (by omega : 1 ≤ H)]
      calc (H : ℝ) ^ 2 * (H - 1) ^ (m + 1) ≤ H ^ 2 * (H * exp (-1 / H)) ^ (m + 1) := by
            have : (2 : ℝ) ≤ H := by exact_mod_cast hH
            gcongr; linarith
        _ = H ^ (m + 1) * (H ^ 2 * exp (-1 / H) ^ (m + 1)) := by ring
        _ < H ^ (m + 1) * 1 := by gcongr
        _ = _ := mul_one _
    exact_mod_cast this
  obtain ⟨A, hA⟩ : ∃ A : Fin s → (Fin m → Fin H) → Fin H, ∀ y : Fin s → Fin H,
      (univ.filter fun z => ∀ r, A r z ≠ y r).card ≤ m := by
    by_contra hno
    push Not at hno
    set P := (H - 1) ^ (m + 1) * H ^ (H ^ m - (m + 1))
    have hsub : (univ : Finset (Fin s → (Fin m → Fin H) → Fin H)) ⊆
        (univ ×ˢ (univ.powersetCard (m + 1))).biUnion
          (fun p : (Fin s → Fin H) × Finset (Fin m → Fin H) => Fintype.piFinset fun r =>
            Fintype.piFinset fun z => if z ∈ p.2 then univ.erase (p.1 r) else univ) := by
      intro A _
      obtain ⟨y, hy⟩ := hno A
      obtain ⟨T, hT, hTc⟩ := exists_subset_card_eq (Nat.succ_le_of_lt hy)
      simp only [mem_biUnion, mem_product, mem_univ, true_and,
        mem_powersetCard, Fintype.mem_piFinset]
      refine ⟨(y, T), ⟨subset_univ _, hTc⟩, fun r z => ?_⟩
      split_ifs with hz
      · simpa using (mem_filter.1 (hT hz)).2 r
      · simp
    have hcard := (card_le_card hsub).trans (card_biUnion_le_card_mul _ _ (P ^ s) (by
      rintro ⟨y, T⟩ hT
      simp only [mem_product, mem_powersetCard] at hT
      rw [Fintype.card_piFinset]
      refine (prod_le_pow_card _ _ P fun r _ => le_of_eq ?_).trans (by simp)
      dsimp only
      rw [Fintype.card_piFinset, prod_congr rfl fun z _ => show #(if z ∈ T then univ.erase (y r) else
        univ) = if z ∈ T then H - 1 else H by split_ifs <;> simp]
      simp [P, prod_ite, filter_notMem_eq_sdiff, card_sdiff_of_subset, hT.2.2]))
    have hm1 : m < H ^ m := Nat.lt_pow_self (by omega)
    have hchoose : (H ^ m).choose (m + 1) ≤ H ^ s := (Nat.choose_le_pow _ _).trans
      (by rw [← pow_mul]; exact Nat.pow_le_pow_right (by omega) hs.le)
    have hP : H ^ 2 * P < H ^ (H ^ m) := by
      calc H ^ 2 * P = H ^ 2 * (H - 1) ^ (m + 1) * H ^ (H ^ m - (m + 1)) := by ring
        _ < H ^ (m + 1) * H ^ (H ^ m - (m + 1)) :=
          Nat.mul_lt_mul_of_pos_right key (by positivity)
        _ = _ := by rw [← pow_add]; congr 1; omega
    have hcard' : (H ^ (H ^ m)) ^ s ≤ H ^ s * (H ^ m).choose (m + 1) * P ^ s := by
      simpa using hcard
    have : H ^ s * (H ^ m).choose (m + 1) * P ^ s ≤ (H ^ 2 * P) ^ s := by
      calc _ ≤ H ^ s * H ^ s * P ^ s := by gcongr
        _ = _ := by ring
    exact absurd (hcard'.trans this) (not_le.2 (Nat.pow_lt_pow_left hP (by omega)))
  have hms : m ≤ s := by nlinarith
  refine ⟨fun x y => if h : ∃ r, A r (fun i => x (Fin.castLE hms i)) = y r then .inr h.choose
    else .inl (Fin.castLE hms (Fin.castLE (hA y)
      ((univ.filter fun z => ∀ r, A r z ≠ y r).equivFin
        ⟨_, mem_filter.2 ⟨mem_univ _, fun r hr => h ⟨r, hr⟩⟩⟩))), ?_⟩
  refine ⟨fun x x' y d h1 h2 => ?_, fun x y y' d h1 h2 => ?_⟩ <;> dsimp only at h1 h2 <;>
    split_ifs at h1 h2 with g1 g2 <;> simp only [Sum.inl.injEq, Sum.inr.injEq] at h1 h2 <;> subst h1
  · exact (congrFun (congrArg Subtype.val ((equivFin _).injective
      (Fin.castLE_injective _ (Fin.castLE_injective _ h2)))) _).symm
  · rw [← g1.choose_spec, ← h2, g2.choose_spec]

theorem exists_code (q t s : ℕ) (hs : 0 < s) (hst : s ≤ t) :
    ∃ (M : ℕ) (w : Fin M → Fin t → Fin q),
      (∀ i i', i ≠ i' → s ≤ hammingDist (w i) (w i')) ∧ q ^ t ≤ M * (t.choose s * q ^ s) := by
  classical
  let good : Finset (Fin t → Fin q) → Prop := fun C =>
    ∀ φ ∈ C, ∀ ψ ∈ C, φ ≠ ψ → s ≤ hammingDist φ ψ
  obtain ⟨C, hC, hmax⟩ := exists_max_image (univ.filter good) card
    ⟨∅, by simp [good]⟩
  rw [mem_filter] at hC
  refine ⟨C.card, fun i => (C.equivFin.symm i).1, fun i i' h => hC.2 _ (C.equivFin.symm i).2 _
    (C.equivFin.symm i').2 (fun e => h (C.equivFin.symm.injective (Subtype.ext e))), ?_⟩
  calc q ^ t = (univ : Finset (Fin t → Fin q)).card := by simp
    _ ≤ (C.biUnion fun ψ => (univ.powersetCard s).biUnion fun D =>
          Fintype.piFinset fun c => if c ∈ D then univ else {ψ c}).card := by
        refine card_le_card fun φ _ => ?_
        obtain ⟨ψ, hψ, h⟩ : ∃ ψ ∈ C, hammingDist φ ψ < s := by
          by_contra h
          push Not at h
          have hφ : φ ∉ C := fun hφ => by simpa using (h φ hφ).trans_lt' hs
          have := hmax (insert φ C) (mem_filter.2 ⟨mem_univ _, by
            intro α hα β hβ hne
            simp only [mem_insert] at hα hβ
            rcases hα with rfl | hα <;> rcases hβ with rfl | hβ
            · exact absurd rfl hne
            · exact h β hβ
            · simpa only [hammingDist_comm] using h α hα
            · exact hC.2 α hα β hβ hne⟩)
          rw [card_insert_of_notMem hφ] at this
          omega
        obtain ⟨D, hD1, -, hD2⟩ := exists_subsuperset_card_eq
          (subset_univ (univ.filter fun c => φ c ≠ ψ c)) h.le (by simpa using hst)
        simp only [mem_biUnion, mem_powersetCard, Fintype.mem_piFinset]
        refine ⟨ψ, hψ, D, ⟨subset_univ _, hD2⟩, fun c => ?_⟩
        split_ifs with hc
        · exact mem_univ _
        · exact mem_singleton.2 (by_contra fun hne =>
            hc (hD1 (mem_filter.2 ⟨mem_univ _, hne⟩)))
    _ ≤ _ := card_biUnion_le_card_mul _ _ _ fun ψ _ =>
        (card_biUnion_le_card_mul _ _ (q ^ s) fun D hD => by
          rw [Fintype.card_piFinset, prod_congr rfl fun c _ => show
            #(if c ∈ D then univ else {ψ c}) = if c ∈ D then q else 1 by split_ifs <;> simp]
          simp [(mem_powersetCard.1 hD).2]).trans (by simp)

theorem forces_pow (k : ℕ) : ForcesMonochromaticTriangle (2 * (k + 1) ^ k) k := by
  classical
  have key : ∀ k (V : Type) [Fintype V], 2 * (k + 1) ^ k ≤ Fintype.card V →
      ∀ c : V → V → ℕ, (∀ x y, x ≠ y → c x y < k) →
        ∃ x y z, x ≠ y ∧ x ≠ z ∧ y ≠ z ∧ c x y = c x z ∧ c y z = c x z := by
    intro k
    induction k with
    | zero =>
      intro V _ hV c hc
      obtain ⟨x, y, hxy⟩ := Fintype.exists_pair_of_one_lt_card (α := V) (by simp at hV; omega)
      exact absurd (hc x y hxy) (Nat.not_lt_zero _)
    | succ k ih =>
      intro V _ hV c hc
      obtain ⟨r⟩ : Nonempty V := Fintype.card_pos_iff.mp (lt_of_lt_of_le (by positivity) hV)
      have hlt := Nat.pow_lt_pow_left (show k + 1 < k + 1 + 1 by omega) (show k + 1 ≠ 0 by omega)
      obtain ⟨ω, hω, hS⟩ := exists_le_card_fiber_of_mul_le_card_of_maps_to
        (s := univ.erase r) (t := range (k + 1)) (f := c r) (n := 2 * (k + 1) ^ k)
        (fun v hv => mem_range.2 (hc r v (ne_of_mem_erase hv).symm)) ⟨0, by simp⟩
        (by rw [card_range, card_erase_of_mem (mem_univ r), card_univ]
            have : (k + 1) * (2 * (k + 1) ^ k) = 2 * (k + 1) ^ (k + 1) := by ring
            omega)
      set S := (univ.erase r).filter (fun v => c r v = ω)
      by_cases h : ∃ u ∈ S, ∃ v ∈ S, u ≠ v ∧ c u v = ω
      · obtain ⟨u, hu, v, hv, huv, h⟩ := h
        simp only [S, mem_filter, mem_erase] at hu hv
        exact ⟨r, u, v, Ne.symm hu.1.1, Ne.symm hv.1.1, huv, by rw [hu.2, hv.2], by rw [h, hv.2]⟩
      · push Not at h
        obtain ⟨⟨x, hx⟩, ⟨y, hy⟩, ⟨z, hz⟩, hxy, hxz, hyz, h1, h2⟩ := ih S (by simpa using hS)
          (fun u v => if c u v < ω then c u v else c u v - 1) (by
            rintro ⟨u, hu⟩ ⟨v, hv⟩ huv
            have := h u hu v hv (fun e => huv (Subtype.ext e))
            have := hc u v (fun e => huv (Subtype.ext e))
            have := mem_range.1 hω
            dsimp only; split_ifs <;> omega)
        have a := h x hx y hy (fun e => hxy (Subtype.ext e))
        have b := h x hx z hz (fun e => hxz (Subtype.ext e))
        have d := h y hy z hz (fun e => hyz (Subtype.ext e))
        refine ⟨x, y, z, fun e => hxy (Subtype.ext e), fun e => hxz (Subtype.ext e),
          fun e => hyz (Subtype.ext e), ?_, ?_⟩ <;> dsimp only at h1 h2 <;> split_ifs at h1 h2 <;> omega
  intro C hC
  obtain ⟨x, y, z, hxy, hxz, hyz, h1, h2⟩ := key k (Fin _) (by simp)
    (fun x y => if h : x = y then 0 else (C.get x y h : ℕ)) (fun x y h => by simp [h])
  simp only [hxy, hxz, hyz, dite_false, ← Fin.ext_iff] at h1 h2
  exact hC (C.get x y hxy) {x, y, z} (is3Clique_triple_iff.2 (by simp [hxy, hxz, hyz, h1, h2]))

theorem lt_triangleRamseyNumber {V : Type*} [Fintype V] {k : ℕ} (c : V → V → ℕ)
    (hk : ∀ x y, x ≠ y → c x y < k) (hs : ∀ x y, c x y = c y x)
    (ht : ∀ x y z, x ≠ y → x ≠ z → y ≠ z → c x y = c x z → c y z = c x z → False) :
    Fintype.card V < triangleRamseyNumber k := by
  by_contra h
  push Not at h
  have hR : ForcesMonochromaticTriangle (triangleRamseyNumber k) k :=
    Nat.sInf_mem (s := {n | ForcesMonochromaticTriangle n k}) ⟨_, forces_pow k⟩
  let e := (Fin.castLEEmb h).trans (Fintype.equivFin V).symm.toEmbedding
  refine hR
    (EdgeLabeling.mk (fun x y h => ⟨c (e x) (e y), hk _ _ (e.injective.ne h)⟩)
      (fun x y _ => Fin.ext (hs _ _))) (fun col T hT => ?_)
  obtain ⟨x, y, z, ⟨h1, e1⟩, ⟨h2, e2⟩, ⟨h3, e3⟩, -⟩ := by
    simpa only [TopEdgeLabeling.labelGraph_adj] using is3Clique_iff.1 hT
  exact ht (e x) (e y) (e z) (e.injective.ne h1) (e.injective.ne h2) (e.injective.ne h3)
    (congrArg Fin.val (e1.trans e2.symm)) (congrArg Fin.val (e3.trans e2.symm))

theorem exists_stage {H m s t : ℕ} (hH : 2 ≤ H) (hm : 2 * (H : ℝ) * log H ≤ m)
    (hs : m * (m + 1) < s) (hst : s ≤ t) (j : ℕ) (hj : j ≤ H) :
    ∃ (V : Type) (_ : Fintype V) (c : V → V → Fin t × ℕ) (l : Fin t × ℕ → V → Fin H),
      (∀ x y, x ≠ y → (c x y).2 < j) ∧ (∀ x y, c x y = c y x) ∧
      (∀ x y z, x ≠ y → x ≠ z → y ≠ z → c x y = c x z → c y z = c x z → False) ∧
      (∀ x y, x ≠ y → l (c x y) x ≠ l (c x y) y) ∧ (∀ col x, col.2 < j → (l col x : ℕ) < j) ∧
      j.factorial ^ t ≤ Fintype.card V * t.choose s ^ j * j.factorial ^ s := by
  classical
  obtain ⟨Φ, hΦ⟩ := exists_covering hH hm hs
  induction j with
  | zero =>
    exact ⟨Unit, inferInstance, fun _ _ => (⟨0, by omega⟩, 0), fun _ _ => ⟨0, by omega⟩,
      fun x y h => absurd (Subsingleton.elim x y) h, fun _ _ => rfl,
      fun x y _ h => absurd (Subsingleton.elim x y) h, fun x y h => absurd (Subsingleton.elim x y) h,
      fun _ _ h => absurd h (Nat.not_lt_zero _), by simp⟩
  | succ j ih =>
    obtain ⟨V, _, c, l, hB, hS, hT, hL, hLb, hN⟩ := ih (by omega)
    obtain ⟨M, w, hw, hM⟩ := exists_code (j + 1) t s (by omega) hst
    have hD : ∀ i i' : Fin M, ∃ D : Fin s ↪ Fin t, i ≠ i' → ∀ d, w i (D d) ≠ w i' (D d) := by
      intro i i'
      by_cases h : i = i'
      · exact ⟨Fin.castLEEmb hst, fun h' => absurd h h'⟩
      · exact ⟨(Fin.castLEEmb (hw i i' h)).trans (orderEmbOfFin _ rfl).toEmbedding,
          fun _ d => (mem_filter.1 (orderEmbOfFin_mem
            (univ.filter fun c => w i c ≠ w i' c) rfl _)).2⟩
    choose D hD using hD
    let r : Fin M → Fin t × ℕ → Fin t × ℕ := fun i x =>
      (x.1, if x.2 < w i x.1 then x.2 else x.2 + 1)
    let Λ : Fin M → Fin t × ℕ → V → Fin H := fun i x u =>
      if x.2 = w i x.1 then ⟨j, by omega⟩ else l (x.1, if x.2 < w i x.1 then x.2 else x.2 - 1) u
    let xv : Fin M → Fin M → V → Fin s → Fin H := fun i i' u d => Λ i (D i i' d, w i' (D i i' d)) u
    let yv : Fin M → Fin M → V → Fin s → Fin H := fun i i' v d => Λ i' (D i i' d, w i (D i i' d)) v
    let X : Fin M → V → Fin M → V → Fin t × ℕ := fun i u i' v =>
      Sum.elim (fun d => (D i i' d, (w i' (D i i' d) : ℕ))) (fun d => (D i i' d, (w i (D i i' d) : ℕ)))
        (Φ (xv i i' u) (yv i i' v))
    let c' : Fin M × V → Fin M × V → Fin t × ℕ := fun p q =>
      if p.1 = q.1 then r p.1 (c p.2 q.2)
      else if p.1 < q.1 then X p.1 p.2 q.1 q.2 else X q.1 q.2 p.1 p.2
    have hr : ∀ i x u, Λ i (r i x) u = l x u := by
      intro i x u
      simp only [Λ, r]
      rw [if_neg (by split_ifs <;> omega)]
      exact congrArg (l · u) (Prod.ext rfl (by dsimp only; split_ifs <;> omega))
    have hrinj : ∀ i x y, r i x = r i y → x = y := by
      intro i x y h
      obtain ⟨h1, h2⟩ := Prod.mk.inj h
      rw [h1] at h2
      exact Prod.ext h1 (by split_ifs at h2 <;> omega)
    have hrm : ∀ i x, ¬ (r i x).2 = w i (r i x).1 := by
      intro i x; simp only [r]; split_ifs <;> omega
    have hXm : ∀ i i' u v, i ≠ i' →
        ((X i u i' v).2 = w i (X i u i' v).1 ↔ ¬ (X i u i' v).2 = w i' (X i u i' v).1) := by
      intro i i' u v h
      simp only [X]
      cases Φ _ _ <;> simp [Fin.val_inj, hD i i' h, Ne.symm (hD i i' h _)]
    have hXb : ∀ i i' u v, (X i u i' v).2 < j + 1 := by
      intro i i' u v; simp only [X]; cases Φ _ _ <;> simp [Fin.is_le]
    have hX1 : ∀ i i' u u' v, i ≠ i' → X i u i' v = X i u' i' v →
        ¬ (X i u i' v).2 = w i (X i u i' v).1 → Λ i (X i u i' v) u = Λ i (X i u i' v) u' := by
      intro i i' u u' v hi h hx
      simp only [X] at h hx ⊢
      cases e1 : Φ (xv i i' u) (yv i i' v) <;> cases e2 : Φ (xv i i' u') (yv i i' v) <;>
        simp only [e1, e2, Sum.elim_inl, Sum.elim_inr, Prod.mk.injEq] at h hx ⊢
      · obtain rfl := (D i i').injective h.1
        exact hΦ.1 _ _ _ _ e1 e2
      · obtain rfl := (D i i').injective h.1
        exact absurd (Fin.val_inj.1 h.2) (Ne.symm (hD i i' hi _))
      all_goals exact (hx trivial).elim
    have hX2 : ∀ i i' u v v', i ≠ i' → X i u i' v = X i u i' v' →
        ¬ (X i u i' v).2 = w i' (X i u i' v).1 → Λ i' (X i u i' v) v = Λ i' (X i u i' v) v' := by
      intro i i' u v v' hi h hx
      simp only [X] at h hx ⊢
      cases e1 : Φ (xv i i' u) (yv i i' v) <;> cases e2 : Φ (xv i i' u) (yv i i' v') <;>
        simp only [e1, e2, Sum.elim_inl, Sum.elim_inr, Prod.mk.injEq] at h hx ⊢
      · exact (hx trivial).elim
      · exact (hx trivial).elim
      · obtain rfl := (D i i').injective h.1
        exact absurd (Fin.val_inj.1 h.2) (hD i i' hi _)
      · obtain rfl := (D i i').injective h.1
        exact hΦ.2 _ _ _ _ e1 e2
    have hc'eq : ∀ i u v, c' (i, u) (i, v) = r i (c u v) := by intro i u v; simp [c']
    have hc'm : ∀ p q : Fin M × V, p.1 ≠ q.1 →
        ((c' p q).2 = w p.1 (c' p q).1 ↔ ¬ (c' p q).2 = w q.1 (c' p q).1) := by
      rintro ⟨i, u⟩ ⟨i', v⟩ h
      simp only [c', if_neg h]
      split_ifs
      · exact hXm i i' u v h
      · rw [hXm i' i v u (Ne.symm h)]; tauto
    have hS' : ∀ p q, c' p q = c' q p := by
      rintro ⟨i, u⟩ ⟨i', v⟩
      by_cases h : i = i'
      · subst h; simp [c', hS u v]
      · rcases lt_or_gt_of_ne h with h' | h' <;> simp [c', h, Ne.symm h, h', not_lt_of_gt h']
    have hTB : ∀ i u u' q, u ≠ u' → i ≠ q.1 → c' (i, u) q = r i (c u u') →
        c' (i, u') q = r i (c u u') → False := by
      rintro i u u' ⟨i', v⟩ huu h h1 h2
      have hx := hrm i (c u u')
      apply hL u u' huu
      rw [← hr i (c u u') u, ← hr i (c u u') u']
      simp only [c', if_neg h] at h1 h2
      split_ifs at h1 h2
      · rw [← h1] at hx ⊢; exact hX1 i i' u u' v h (h1.trans h2.symm) hx
      · rw [← h1] at hx ⊢; exact hX2 i' i v u u' (Ne.symm h) (h1.trans h2.symm) hx
    have hT' : ∀ x y z, x ≠ y → x ≠ z → y ≠ z → c' x y = c' x z → c' y z = c' x z → False := by
      rintro ⟨i, u⟩ ⟨i', v⟩ ⟨i'', v''⟩ hxy hxz hyz h1 h2
      by_cases e1 : i = i' <;> by_cases e2 : i = i''
      · subst e1 e2
        rw [hc'eq, hc'eq] at h1 h2
        exact hT u v v'' (by simpa using hxy) (by simpa using hxz) (by simpa using hyz)
          (hrinj _ _ _ h1) (hrinj _ _ _ h2)
      · subst e1
        exact hTB _ _ _ _ (by simpa using hxy) e2 (h1.symm.trans (hc'eq _ _ _))
          (h2.trans (h1.symm.trans (hc'eq _ _ _)))
      · subst e2
        exact hTB _ _ _ _ (by simpa using hxz) e1 (h1.trans (hc'eq _ _ _))
          ((hS' _ _).trans (h2.trans (hc'eq _ _ _)))
      · by_cases e3 : i' = i''
        · subst e3
          exact hTB _ _ _ _ (by simpa using hyz) (Ne.symm e1)
            ((hS' _ _).trans (h1.trans (h2.symm.trans (hc'eq _ _ _))))
            ((hS' _ _).trans (h2.symm.trans (hc'eq _ _ _)))
        · have m1 := hc'm (i, u) (i', v) e1
          have m2 := hc'm (i, u) (i'', v'') e2
          have m3 := hc'm (i', v) (i'', v'') e3
          rw [h1] at m1
          rw [h2] at m3
          dsimp only at m1 m2 m3
          tauto
    have hB' : ∀ p q, p ≠ q → (c' p q).2 < j + 1 := by
      rintro ⟨i, u⟩ ⟨i', v⟩ h
      by_cases e : i = i'
      · subst e
        rw [hc'eq]
        have := hB u v (by simpa using h)
        simp only [r]; split_ifs <;> omega
      · simp only [c', if_neg e]; split_ifs <;> exact hXb _ _ _ _
    have hΛb : ∀ i (x : Fin t × ℕ) u, x.2 < j + 1 → ¬ x.2 = (w i x.1 : ℕ) → (Λ i x u : ℕ) < j := by
      intro i x u h1 h2
      simp only [Λ, if_neg h2]
      have := (w i x.1).isLt
      exact hLb _ _ (by dsimp only; split_ifs <;> omega)
    have hL' : ∀ p q, p ≠ q → Λ p.1 (c' p q) p.2 ≠ Λ q.1 (c' p q) q.2 := by
      rintro ⟨i, u⟩ ⟨i', v⟩ h
      by_cases e : i = i'
      · subst e; dsimp only; rw [hc'eq, hr, hr]; exact hL u v (by simpa using h)
      · have hm := hc'm (i, u) (i', v) e
        have hb := hB' _ _ h
        dsimp only at hm hb ⊢
        intro heq
        have hv := congrArg Fin.val heq
        by_cases hx : (c' (i, u) (i', v)).2 = w i (c' (i, u) (i', v)).1
        · have h2 := hΛb i' _ v hb (hm.1 hx)
          have : (Λ i (c' (i, u) (i', v)) u : ℕ) = j := by simp only [Λ, if_pos hx]
          omega
        · have hq : (c' (i, u) (i', v)).2 = w i' (c' (i, u) (i', v)).1 := by
            by_contra hq; exact hx (hm.2 hq)
          have h2 := hΛb i _ u hb hx
          have : (Λ i' (c' (i, u) (i', v)) v : ℕ) = j := by simp only [Λ, if_pos hq]
          omega
    have hLb' : ∀ (x : Fin t × ℕ) (p : Fin M × V), x.2 < j + 1 → (Λ p.1 x p.2 : ℕ) < j + 1 := by
      intro x p h
      by_cases hx : x.2 = (w p.1 x.1 : ℕ)
      · simp [Λ, hx]
      · have := hΛb _ _ p.2 h hx; omega
    refine ⟨Fin M × V, inferInstance, c', fun x p => Λ p.1 x p.2, hB', hS', hT', hL', hLb', ?_⟩
    rw [Fintype.card_prod, Fintype.card_fin, Nat.factorial_succ, mul_pow, mul_pow]
    calc (j + 1) ^ t * j.factorial ^ t ≤ (M * (t.choose s * (j + 1) ^ s)) *
          (Fintype.card V * t.choose s ^ j * j.factorial ^ s) := Nat.mul_le_mul hM hN
      _ = _ := by ring

theorem erdos_problem_183_explicit :
    (∀ k : ℕ, 2 ≤ k →
      (((1 : ℝ) / (6 * Real.exp 38)) *
        (k : ℝ) ^ ((1 : ℝ) / 3) / Real.log (k : ℝ)) ^ k ≤
          (triangleRamseyNumber k : ℝ)) ∧
      Filter.Tendsto
        (fun k : ℕ =>
          (triangleRamseyNumber k : ℝ) ^ ((1 : ℝ) / (k : ℝ)))
        atTop atTop := by
  have L : ∀ k : ℕ, 2 ≤ k →
      (((1 : ℝ) / (6 * exp 38)) *
        (k : ℝ) ^ ((1 : ℝ) / 3) / log (k : ℝ)) ^ k ≤
          (triangleRamseyNumber k : ℝ) := by
    intro k hk
    have hk0 : (0 : ℝ) < k := by positivity
    have hlk : (1 / 2 : ℝ) < log k := by
      have := log_le_log (by norm_num) (by exact_mod_cast hk : (2 : ℝ) ≤ k)
      linarith [log_two_gt_d9]
    set β := (1 : ℝ) / (6 * exp 38) * (k : ℝ) ^ ((1 : ℝ) / 3) / log k with hβ
    rcases le_or_gt β 1 with hβ1 | hβ1
    · have h0 := lt_triangleRamseyNumber (V := Empty) (k := k) (fun _ _ => 0) (fun x => x.elim)
        (fun _ _ => rfl) (fun x => x.elim)
      rw [Fintype.card_empty] at h0
      exact (pow_le_one₀ (by positivity) hβ1).trans (by exact_mod_cast h0)
    set H := ⌊exp 37 * β⌋₊
    have e1 : (2 : ℝ) ≤ exp 1 := by linarith [add_one_le_exp 1]
    have h37 : exp 37 = exp 36 * exp 1 := by rw [← exp_add]; norm_num
    have e36 : (37 : ℝ) ≤ exp 36 := by linarith [add_one_le_exp 36]
    have hH36 : exp 36 * β ≤ H := by
      have := Nat.lt_floor_add_one (exp 37 * β)
      nlinarith
    have hH2 : 2 ≤ H := by exact_mod_cast (show (2 : ℝ) ≤ H by nlinarith)
    have hH0 : (0 : ℝ) < H := by positivity
    have hroot : 6 * exp 1 * H * log k ≤ (k : ℝ) ^ ((1 : ℝ) / 3) := by
      calc _ ≤ 6 * exp 1 * (exp 37 * β) * log k := by
            gcongr; exact Nat.floor_le (by positivity)
        _ = _ := by
            rw [hβ, h37, show exp 38 = exp 36 * exp 1 * exp 1 by
              rw [← exp_add, ← exp_add]; norm_num]
            field_simp
    have hcube : (6 * exp 1 * H * log k) ^ 3 ≤ k := by
      calc _ ≤ ((k : ℝ) ^ ((1 : ℝ) / 3)) ^ 3 := pow_le_pow_left₀ (by positivity) hroot 3
        _ = k := by rw [← rpow_natCast, ← rpow_mul hk0.le]; norm_num
    have hHk : (H : ℝ) ≤ k := by
      have h6 : 1 ≤ 6 * exp 1 * log k := by nlinarith
      calc (H : ℝ) ≤ 6 * exp 1 * H * log k := by
            nlinarith [mul_le_mul_of_nonneg_left h6 hH0.le]
        _ ≤ (k : ℝ) ^ ((1 : ℝ) / 3) := hroot
        _ ≤ (k : ℝ) ^ (1 : ℝ) := rpow_le_rpow_of_exponent_le
            (by exact_mod_cast (by omega : 1 ≤ k)) (by norm_num)
        _ = k := rpow_one _
    have hlogH : 0 ≤ log H := log_nonneg (by exact_mod_cast (by omega : 1 ≤ H))
    have hLk : log H ≤ log k := log_le_log hH0 hHk
    set m := ⌈2 * (H : ℝ) * log H⌉₊
    set s := m * (m + 1) + 1
    have hHs : (H : ℝ) * s * (log H + 1) ≤ k := by
      have hm1 : (m : ℝ) + 1 ≤ 2 * H * (log k + 1) := by
        have := Nat.ceil_lt_add_one (show 0 ≤ 2 * (H : ℝ) * log H by positivity)
        nlinarith
      have hs' : (s : ℝ) ≤ (m + 1) ^ 2 := by simp only [s]; push_cast; nlinarith
      calc (H : ℝ) * s * (log H + 1)
          ≤ H * (2 * H * (log k + 1)) ^ 2 * (log k + 1) := by
            gcongr; exact hs'.trans (pow_le_pow_left₀ (by positivity) hm1 2)
        _ ≤ 108 * (H * log k) ^ 3 := by
            have : log k + 1 ≤ 3 * log k := by linarith
            calc _ = 4 * H ^ 3 * (log k + 1) ^ 3 := by ring
              _ ≤ 4 * H ^ 3 * (3 * log k) ^ 3 := by gcongr
              _ = _ := by ring
        _ ≤ (6 * exp 1) ^ 3 * (H * log k) ^ 3 := by
            gcongr; calc (108 : ℝ) ≤ 6 ^ 3 := by norm_num
              _ ≤ _ := by gcongr; linarith
        _ = _ := by ring
        _ ≤ k := hcube
    have hHs0 : 0 < H * s := by positivity
    set a := k / (H * s) with ha_def
    have hca : ⌈log H⌉₊ ≤ a := by
      refine (Nat.le_div_iff_mul_le hHs0).2 ?_
      have : (⌈log H⌉₊ : ℝ) ≤ log H + 1 := (Nat.ceil_lt_add_one hlogH).le
      exact_mod_cast (show ((⌈log H⌉₊ * (H * s) : ℕ) : ℝ) ≤ k by push_cast; nlinarith)
    have ha : log H ≤ a := (Nat.le_ceil _).trans (by exact_mod_cast hca)
    have ha1 : 1 ≤ a := (Nat.ceil_pos.2 (log_pos (by exact_mod_cast hH2))).trans_le hca
    obtain ⟨b, hb⟩ : ∃ b, a = b + 1 := ⟨a - 1, by omega⟩
    have hka : H * ((b + 1) * s) ≤ k := by rw [← hb, mul_left_comm]; exact Nat.div_mul_le_self k _
    have hkb : k < H * ((b + 2) * s) := by
      have := Nat.lt_div_mul_add (a := k) hHs0
      rw [← ha_def, hb] at this
      linarith
    obtain ⟨V, _, col, -, hB, hS, hT, -, -, hN⟩ := exists_stage hH2 (Nat.le_ceil _)
      (by omega : m * (m + 1) < s) (show s ≤ (b + 1) * s by nlinarith) H le_rfl
    have henc : ∀ p q : Fin ((b + 1) * s) × ℕ,
        p.1.val + (b + 1) * s * p.2 = q.1.val + (b + 1) * s * q.2 → p = q := by
      intro p q h
      have hp : 0 < (b + 1) * s := by positivity
      have h1 := congrArg (· % ((b + 1) * s)) h
      have h2 := congrArg (· / ((b + 1) * s)) h
      simp only [Nat.add_mul_mod_self_left, Nat.mod_eq_of_lt p.1.isLt, Nat.mod_eq_of_lt q.1.isLt,
        Nat.add_mul_div_left _ _ hp, Nat.div_eq_of_lt p.1.isLt, Nat.div_eq_of_lt q.1.isLt,
        zero_add] at h1 h2
      exact Prod.ext (Fin.ext h1) h2
    have hV := lt_triangleRamseyNumber (k := k) (fun x y => (col x y).1.val + (b + 1) * s * (col x y).2)
      (fun x y h => by
        have := (col x y).1.isLt
        have := hB x y h
        nlinarith [Nat.mul_le_mul_left ((b + 1) * s) (show (col x y).2 + 1 ≤ H by omega)])
      (fun x y => by rw [hS]) (fun x y z h1 h2 h3 e1 e2 => hT x y z h1 h2 h3 (henc _ _ e1) (henc _ _ e2))
    have hfact : ∀ n : ℕ, ((n : ℝ) / exp 1) ^ n ≤ n.factorial := by
      intro n
      have := pow_div_factorial_le_exp _ (Nat.cast_nonneg n) n
      rw [div_le_iff₀ (by positivity)] at this
      rw [div_pow, ← exp_nat_mul, mul_one, div_le_iff₀ (exp_pos _)]
      linarith
    have hchoose : ((((b + 1) * s).choose s : ℕ) : ℝ) ≤ (exp 1 * (b + 1)) ^ s := by
      have hs0 : (0 : ℝ) < s := by positivity
      calc _ ≤ (((b + 1) * s : ℕ) : ℝ) ^ s / s.factorial := Nat.choose_le_pow_div s _
        _ ≤ (((b + 1) * s : ℕ) : ℝ) ^ s / ((s : ℝ) / exp 1) ^ s :=
          div_le_div_of_nonneg_left (by positivity) (by positivity) (hfact s)
        _ = _ := by rw [← div_pow]; congr 1; push_cast; field_simp
    have hN' : ((H.factorial : ℕ) : ℝ) ^ (b * s) ≤
        Fintype.card V * ((((b + 1) * s).choose s : ℕ) : ℝ) ^ H := by
      have : H.factorial ^ (b * s) * H.factorial ^ s ≤
          Fintype.card V * ((b + 1) * s).choose s ^ H * H.factorial ^ s := by
        rw [← pow_add, show b * s + s = (b + 1) * s by ring]; exact hN
      exact_mod_cast Nat.le_of_mul_le_mul_right this (by positivity)
    have hC0 : (0 : ℝ) < ((((b + 1) * s).choose s : ℕ) : ℝ) ^ H := by
      have := Nat.choose_pos (show s ≤ (b + 1) * s by nlinarith); positivity
    have hlb : log β ≤ log H - 36 := by
      have := log_le_log (by positivity) hH36
      rw [log_mul (by positivity) (by positivity), log_exp] at this
      linarith
    have hlb0 : 0 < log β := log_pos hβ1
    have hb1 : log (b + 1) ≤ b := by
      linarith [log_le_sub_one_of_pos (show (0 : ℝ) < b + 1 by positivity)]
    have hab : log H ≤ b + 1 := by exact_mod_cast hb ▸ ha
    have hk' : (k : ℝ) ≤ H * ((b + 2) * s) := by exact_mod_cast hkb.le
    have hRHS : log (((H : ℝ) / exp 1) ^ (H * (b * s)) / (exp 1 * (b + 1)) ^ (s * H))
        = (H * (b * s) : ℕ) * (log H - 1) - (s * H : ℕ) * (1 + log (b + 1)) := by
      rw [log_div (by positivity) (by positivity), log_pow, log_pow,
        log_div (by positivity) (by positivity), log_exp,
        log_mul (by positivity) (by positivity), log_exp]
    clear_value β a s m H
    calc β ^ k ≤ ((H : ℝ) / exp 1) ^ (H * (b * s)) / (exp 1 * (b + 1)) ^ (s * H) := by
          rw [← log_le_log_iff (pow_pos (by linarith) k) (by positivity), log_pow, hRHS]
          push_cast
          have hHs' : (0 : ℝ) ≤ H * s := by positivity
          calc (k : ℝ) * log β ≤ H * ((b + 2) * s) * log β :=
                mul_le_mul_of_nonneg_right hk' hlb0.le
            _ ≤ H * ((b + 2) * s) * (log H - 36) :=
                mul_le_mul_of_nonneg_left hlb (by positivity)
            _ = (H * s) * (b + 2) * (log H - 36) := by ring
            _ ≤ (H * s) * b * (log H - 1) - (H * s) * (1 + log (b + 1)) := by
                linear_combination 2 * mul_le_mul_of_nonneg_left hab hHs' +
                  mul_le_mul_of_nonneg_left hb1 hHs' + 32 * mul_nonneg hHs' (Nat.cast_nonneg b) +
                  69 * hHs'
            _ = _ := by ring
      _ ≤ (H.factorial : ℝ) ^ (b * s) / ((((b + 1) * s).choose s : ℕ) : ℝ) ^ H := by
          refine div_le_div₀ (by positivity) ?_ hC0 ?_
          · rw [pow_mul]; exact pow_le_pow_left₀ (by positivity) (hfact H) _
          · rw [pow_mul]; exact pow_le_pow_left₀ (by positivity) hchoose _
      _ ≤ Fintype.card V := (div_le_iff₀ hC0).2 hN'
      _ ≤ _ := by exact_mod_cast hV.le
  refine ⟨L, tendsto_atTop_mono' _ ?_
    ((tendsto_rpow_atTop (by norm_num : (0 : ℝ) < 1 / 6)).comp tendsto_natCast_atTop_atTop)⟩
  filter_upwards [((isLittleO_log_rpow_atTop (by norm_num : (0 : ℝ) < 1 / 6)).comp_tendsto
    tendsto_natCast_atTop_atTop).bound (by positivity : (0 : ℝ) < 1 / (6 * exp 38)),
    eventually_ge_atTop 2] with k hk hk2
  have hk0 : (0 : ℝ) < k := by positivity
  have hlog : 0 < log k := log_pos (by exact_mod_cast (show 1 < k by omega))
  have hr := rpow_pos_of_pos hk0 (1 / 6)
  simp only [Function.comp_apply, norm_eq_abs, abs_of_pos hlog, abs_of_pos hr] at hk ⊢
  have h1 : (k : ℝ) ^ (1 / 6 : ℝ) ≤
      1 / (6 * exp 38) * (k : ℝ) ^ (1 / 3 : ℝ) / log k := by
    rw [le_div_iff₀ hlog, show (1 / 3 : ℝ) = 1 / 6 + 1 / 6 by norm_num, rpow_add hk0]
    nlinarith [mul_le_mul_of_nonneg_left hk hr.le]
  have h2 := (pow_le_pow_left₀ hr.le h1 k).trans (L k hk2)
  simpa only [one_div] using (le_rpow_inv_iff_of_pos hr.le (by positivity) hk0).mpr
    (by simpa [rpow_natCast] using h2)

theorem erdos_183 :
    Filter.Tendsto
      (fun k : ℕ =>
        (triangleRamseyNumber k : ℝ) ^ ((1 : ℝ) / (k : ℝ)))
      atTop atTop :=
  erdos_problem_183_explicit.2

theorem triangleRamseyNumber_log_sharp_coefficients :
    ∀ ε : ℝ, 0 < ε →
      ∀ᶠ k : ℕ in atTop,
        ((1 / 3 : ℝ) - ε) * (k : ℝ) * Real.log (k : ℝ) ≤
            Real.log (triangleRamseyNumber k : ℝ) ∧
          Real.log (triangleRamseyNumber k : ℝ) ≤
            (1 + ε) * (k : ℝ) * Real.log (k : ℝ) := by
  intro ε hε
  filter_upwards [((isLittleO_log_rpow_atTop hε).comp_tendsto tendsto_natCast_atTop_atTop).bound
      (by positivity : (0 : ℝ) < 1 / (6 * exp 38)),
    ((isLittleO_const_log_atTop (c := log 4)).comp_tendsto
      tendsto_natCast_atTop_atTop).bound hε,
    eventually_ge_atTop 2] with k hk hfour hk2
  have hk0 : (0 : ℝ) < k := by positivity
  have hlog : 0 < log k := log_pos (by exact_mod_cast (show 1 < k by omega))
  simp only [Function.comp_apply, norm_eq_abs, abs_of_pos hlog,
    abs_of_pos (rpow_pos_of_pos hk0 ε),
    abs_of_pos (log_pos (by norm_num : (1 : ℝ) < 4))] at hk hfour
  have hroot : 0 < (k : ℝ) ^ ((1 / 3 : ℝ) - ε) := rpow_pos_of_pos hk0 _
  have hlow : ((k : ℝ) ^ ((1 / 3 : ℝ) - ε)) ^ k ≤ (triangleRamseyNumber k : ℝ) := by
    refine (pow_le_pow_left₀ hroot.le ?_ k).trans (erdos_problem_183_explicit.1 k hk2)
    rw [le_div_iff₀ hlog]
    calc (k : ℝ) ^ ((1 / 3 : ℝ) - ε) * log k
        ≤ (k : ℝ) ^ ((1 / 3 : ℝ) - ε) * (1 / (6 * exp 38) * (k : ℝ) ^ ε) := by gcongr
      _ = 1 / (6 * exp 38) * (k : ℝ) ^ ((1 : ℝ) / 3) := by
        rw [mul_left_comm, ← rpow_add hk0, sub_add_cancel]
  have hupp : (triangleRamseyNumber k : ℝ) ≤ 4 ^ k * (k : ℝ) ^ k := by
    have h2 : 2 * (k + 1) ^ k ≤ 4 ^ k * k ^ k := by
      calc 2 * (k + 1) ^ k ≤ 2 * (2 * k) ^ k := by gcongr; omega
        _ = 2 ^ (k + 1) * k ^ k := by rw [mul_pow]; ring
        _ ≤ 2 ^ (2 * k) * k ^ k := by gcongr <;> omega
        _ = 4 ^ k * k ^ k := by rw [pow_mul]; norm_num
    exact_mod_cast (Nat.sInf_le (forces_pow k)).trans h2
  constructor
  · calc ((1 / 3 : ℝ) - ε) * k * log k = log (((k : ℝ) ^ ((1 / 3 : ℝ) - ε)) ^ k) := by
          rw [log_pow, log_rpow hk0]; ring
      _ ≤ _ := log_le_log (pow_pos hroot k) hlow
  · calc log (triangleRamseyNumber k : ℝ) ≤ log (4 ^ k * (k : ℝ) ^ k) :=
          log_le_log ((pow_pos hroot k).trans_le hlow) hupp
      _ = k * log 4 + k * log k := by
          rw [log_mul (by positivity) (by positivity), log_pow, log_pow]
      _ ≤ _ := by nlinarith [mul_le_mul_of_nonneg_left hfour hk0.le]

theorem triangleRamseyNumber_log_isTheta :
    (fun k : ℕ => Real.log (triangleRamseyNumber k : ℝ))
      =Θ[atTop] (fun k : ℕ => (k : ℝ) * Real.log (k : ℝ)) := by
  have h := triangleRamseyNumber_log_sharp_coefficients (1 / 6) (by norm_num)
  refine ⟨.of_bound 2 ?_, .of_bound 6 ?_⟩ <;>
  filter_upwards [h, eventually_ge_atTop 1] with k hk hk1 <;>
  have h0 : 0 ≤ (k : ℝ) * log k :=
    mul_nonneg (by positivity) (log_nonneg (by exact_mod_cast hk1)) <;>
  rw [norm_of_nonneg h0, norm_of_nonneg (by nlinarith)] <;> nlinarith

end ErdosProblems.MulticolourTriangleRamsey
