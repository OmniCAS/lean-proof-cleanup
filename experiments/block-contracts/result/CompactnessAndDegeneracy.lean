import Mathlib

namespace CompactnessConjecture

noncomputable section Foundations

open Filter Finset SimpleGraph
open scoped Topology

structure FiniteGraph where
  order : ℕ
  graph : SimpleGraph (Fin order)

def FamilyFree (family : Finset FiniteGraph) {n : ℕ}
    (host : SimpleGraph (Fin n)) : Prop :=
  ∀ forbidden ∈ family, forbidden.graph.Free host

noncomputable def familyExtremal (family : Finset FiniteGraph)
    (n : ℕ) : ℕ := by
  classical
  exact (Finset.univ.filter (FamilyFree family)).sup
    (fun host : SimpleGraph (Fin n) => host.edgeFinset.card)

def IsCyclicFamily (family : Finset FiniteGraph) : Prop :=
  ∀ forbidden ∈ family, ¬ forbidden.graph.IsAcyclic

def IsCompactFamily (family : Finset FiniteGraph) : Prop :=
  ∃ forbidden ∈ family, ∃ C : ℝ, 0 < C ∧
    ∀ᶠ n : ℕ in atTop,
      (SimpleGraph.extremalNumber n forbidden.graph : ℝ) ≤
        C * (familyExtremal family n : ℝ)

def CompactnessConjectureStatement : Prop :=
  ∀ family : Finset FiniteGraph,
    family.Nonempty → IsCyclicFamily family → IsCompactFamily family

end Foundations

noncomputable section DensityReduction

open Finset SimpleGraph
open scoped Classical

lemma edgeFinset_card_eq_natCard {V : Type*} (G : SimpleGraph V)
    [Fintype G.edgeSet] :
    G.edgeFinset.card = Nat.card G.edgeSet := by
  simpa only [Nat.card_eq_fintype_card] using
    (SimpleGraph.edgeFinset_card (G := G))

lemma degree_eq_natCard_neighborSet {V : Type*}
    (G : SimpleGraph V) (v : V) [Fintype (G.neighborSet v)] :
    G.degree v = Nat.card (G.neighborSet v) := by
  simpa only [Nat.card_eq_fintype_card] using
    (SimpleGraph.card_neighborSet_eq_degree G v).symm

end DensityReduction

noncomputable section Patterns

open SimpleGraph

abbrev SubdivisionVertex (k : ℕ) :=
  (Fin 3 ⊕ Fin k) ⊕ (Fin 3 × Fin k)

def subdivisionRelation (k : ℕ) :
    SubdivisionVertex k → SubdivisionVertex k → Prop
  | .inl (.inl base), .inr (otherBase, _) => base = otherBase
  | .inl (.inr center), .inr (_, otherCenter) => center = otherCenter
  | _, _ => False

def SubdivisionGraph (k : ℕ) : SimpleGraph (SubdivisionVertex k) :=
  SimpleGraph.fromRel (subdivisionRelation k)

def subdivisionColor (k : ℕ) : SubdivisionVertex k → Bool
  | .inl _ => false
  | .inr _ => true

abbrev thetaGraph : SimpleGraph (SubdivisionVertex 2) :=
  SubdivisionGraph 2

abbrev gammaGraph : SimpleGraph (SubdivisionVertex 3) :=
  SubdivisionGraph 3

end Patterns

noncomputable section Quotients

open Finset SimpleGraph

abbrev JVertex :=
  (Fin 4 ⊕ (Fin 2 × Fin 2)) ⊕
    ((Fin 2 × (Fin 3 × Fin 2)) ⊕ Unit)

def jBase (copy : Fin 2) (base : Fin 3) : Fin 4 :=
  if base = 0 then
    if copy = 0 then 0 else 1
  else if base = 1 then 2 else 3

def jTemplateRelation : JVertex → JVertex → Prop
  | .inl (.inl base), .inr (.inl (copy, (i, _))) =>
      base = jBase copy i
  | .inl (.inr (copy, center)), .inr (.inl (copy', (_, center'))) =>
      copy = copy' ∧ center = center'
  | .inl (.inl base), .inr (.inr _) =>
      base = 0 ∨ base = 1
  | _, _ => False

def jTemplate : SimpleGraph JVertex :=
  SimpleGraph.fromRel jTemplateRelation

def jColor : JVertex → Bool
  | .inl _ => false
  | .inr _ => true

def InJCopy (copy : Fin 2) : JVertex → Prop
  | .inl (.inl base) => ∃ i : Fin 3, base = jBase copy i
  | .inl (.inr (copy', _)) => copy = copy'
  | .inr (.inl (copy', _)) => copy = copy'
  | .inr (.inr _) => False

abbrev KVertex := Fin 2 × SubdivisionVertex 3

def kSpecifiedCenter : SubdivisionVertex 3 :=
  .inl (.inr 0)

def kTemplateRelation (u v : KVertex) : Prop :=
  (u.1 = v.1 ∧ subdivisionRelation 3 u.2 v.2) ∨
    (u.1 = 0 ∧ v.1 = 1 ∧
      u.2 = kSpecifiedCenter ∧ v.2 = kSpecifiedCenter)

def kTemplate : SimpleGraph KVertex :=
  SimpleGraph.fromRel kTemplateRelation

def kColor (v : KVertex) : Bool :=
  if v.1 = 0 then subdivisionColor 3 v.2
  else !(subdivisionColor 3 v.2)

def ColorRespecting {α : Type*}
    (color : α → Bool) (f : α → α) : Prop :=
  ∀ u v, f u = f v → color u = color v

def JAdmissible (f : JVertex → JVertex) : Prop :=
  ColorRespecting jColor f ∧
    Function.Injective
      (fun base : Fin 4 => f (.inl (.inl base))) ∧
    ∀ copy : Fin 2, Set.InjOn f {v | InJCopy copy v}

def KAdmissible (f : KVertex → KVertex) : Prop :=
  ColorRespecting kColor f ∧
    ∀ copy : Fin 2,
      Set.InjOn f {v : KVertex | v.1 = copy}

def quotientRelation {α : Type*}
    (graph : SimpleGraph α) (f : α → α)
    (u v : Set.range f) : Prop :=
  ∃ x y : α, f x = (u : α) ∧ f y = (v : α) ∧ graph.Adj x y

def quotientGraph {α : Type*}
    (graph : SimpleGraph α) (f : α → α) :
    SimpleGraph (Set.range f) :=
  SimpleGraph.fromRel (quotientRelation graph f)

noncomputable def encodeFiniteGraph {α : Type*} [Fintype α]
    (graph : SimpleGraph α) : FiniteGraph :=
  ⟨Fintype.card α,
    graph.map (Fintype.equivFin α).toEmbedding⟩

noncomputable def jQuotients : Finset FiniteGraph :=
  (Set.finite_range
    (fun f : {f : JVertex → JVertex // JAdmissible f} =>
      encodeFiniteGraph
        (quotientGraph jTemplate (f : JVertex → JVertex)))).toFinset

noncomputable def kQuotients : Finset FiniteGraph :=
  (Set.finite_range
    (fun f : {f : KVertex → KVertex // KAdmissible f} =>
      encodeFiniteGraph
        (quotientGraph kTemplate (f : KVertex → KVertex)))).toFinset

def finiteCycle (n : ℕ) : FiniteGraph :=
  ⟨n, SimpleGraph.cycleGraph n⟩

noncomputable def proposedFamily : Finset FiniteGraph := by
  classical
  exact {finiteCycle 4, finiteCycle 6} ∪ jQuotients ∪ kQuotients

theorem proposedFamily_mem_iff {graph : FiniteGraph} :
    graph ∈ proposedFamily ↔
      (((graph = finiteCycle 4 ∨ graph = finiteCycle 6) ∨
        (∃ f : JVertex → JVertex, JAdmissible f ∧
          encodeFiniteGraph (quotientGraph jTemplate f) = graph)) ∨
        (∃ f : KVertex → KVertex, KAdmissible f ∧
          encodeFiniteGraph (quotientGraph kTemplate f) = graph)) := by
  have jQuotients_mem_iff {graph : FiniteGraph} :
      graph ∈ jQuotients ↔
        ∃ f : JVertex → JVertex, JAdmissible f ∧
          encodeFiniteGraph (quotientGraph jTemplate f) = graph := by
    rw [jQuotients, Set.Finite.mem_toFinset]
    constructor
    · rintro ⟨⟨f, hf⟩, heq⟩
      exact ⟨f, hf, heq⟩
    · rintro ⟨f, hf, heq⟩
      exact ⟨⟨f, hf⟩, heq⟩
  have kQuotients_mem_iff {graph : FiniteGraph} :
      graph ∈ kQuotients ↔
        ∃ f : KVertex → KVertex, KAdmissible f ∧
          encodeFiniteGraph (quotientGraph kTemplate f) = graph := by
    rw [kQuotients, Set.Finite.mem_toFinset]
    constructor
    · rintro ⟨⟨f, hf⟩, heq⟩
      exact ⟨f, hf, heq⟩
    · rintro ⟨f, hf, heq⟩
      exact ⟨⟨f, hf⟩, heq⟩
  classical
  simp only [proposedFamily, Finset.mem_union, Finset.mem_insert,
    Finset.mem_singleton, jQuotients_mem_iff, kQuotients_mem_iff]

theorem proposedFamily_induction {P : FiniteGraph → Prop}
    (hfour : P (finiteCycle 4)) (hsix : P (finiteCycle 6))
    (hj : ∀ f : JVertex → JVertex, JAdmissible f →
      P (encodeFiniteGraph (quotientGraph jTemplate f)))
    (hk : ∀ f : KVertex → KVertex, KAdmissible f →
      P (encodeFiniteGraph (quotientGraph kTemplate f))) :
    ∀ graph ∈ proposedFamily, P graph := by
  intro graph hgraph
  rcases proposedFamily_mem_iff.mp hgraph with
    ((rfl | rfl) | ⟨f, hf, rfl⟩) | ⟨f, hf, rfl⟩
  · exact hfour
  · exact hsix
  · exact hj f hf
  · exact hk f hf

theorem proposedFamily_nonempty : proposedFamily.Nonempty :=
  ⟨_, proposedFamily_mem_iff.mpr (.inl (.inl (.inl rfl)))⟩


lemma jQuotient_mem_proposedFamily
    {f : JVertex → JVertex} (hf : JAdmissible f) :
    encodeFiniteGraph (quotientGraph jTemplate f) ∈ proposedFamily :=
  proposedFamily_mem_iff.mpr (.inl (.inr ⟨f, hf, rfl⟩))

lemma kQuotient_mem_proposedFamily
    {f : KVertex → KVertex} (hf : KAdmissible f) :
    encodeFiniteGraph (quotientGraph kTemplate f) ∈ proposedFamily :=
  proposedFamily_mem_iff.mpr (.inr ⟨f, hf, rfl⟩)

end Quotients

noncomputable section Geometry

open SimpleGraph

section SymplecticGeometry

variable (K : Type*) [Field K]


end SymplecticGeometry

section NumericalParameters


end NumericalParameters

end Geometry

noncomputable section Cyclicity

open Finset SimpleGraph

def thetaCycleVertex : Fin 8 → SubdivisionVertex 2 :=
  ![.inl (.inl 0),
    .inr (0, 0),
    .inl (.inr 0),
    .inr (1, 0),
    .inl (.inl 1),
    .inr (1, 1),
    .inl (.inr 1),
    .inr (0, 1)]

def thetaCycleCopy :
    SimpleGraph.Copy (SimpleGraph.cycleGraph 8) thetaGraph := by
  refine ⟨⟨thetaCycleVertex, ?_⟩, ?_⟩
  · intro u v hadj
    fin_cases u <;> fin_cases v <;>
      simp_all [thetaCycleVertex, SubdivisionGraph,
        subdivisionRelation, SimpleGraph.cycleGraph]
    all_goals
      exact (of_decide_eq_false rfl) hadj
  · decide

def jThetaVertex (copy : Fin 2) : SubdivisionVertex 2 → JVertex
  | .inl (.inl base) => .inl (.inl (jBase copy base))
  | .inl (.inr center) => .inl (.inr (copy, center))
  | .inr (base, center) => .inr (.inl (copy, (base, center)))

def jThetaCopy (copy : Fin 2) :
    SimpleGraph.Copy thetaGraph jTemplate := by
  refine ⟨⟨jThetaVertex copy, ?_⟩, ?_⟩
  · intro u v hadj
    rcases (SimpleGraph.fromRel_adj
      (subdivisionRelation 2) u v).mp hadj with
      ⟨hne, hforward | hbackward⟩
    · apply (SimpleGraph.fromRel_adj
        jTemplateRelation (jThetaVertex copy u)
        (jThetaVertex copy v)).mpr
      constructor
      · intro heq
        have hinj : Function.Injective (jThetaVertex copy) := by fin_cases copy <;> decide
        exact hne (hinj heq)
      · left
        rcases u with (u | u) | u <;>
          rcases v with (v | v) | v <;>
          simp_all [subdivisionRelation, jTemplateRelation, jThetaVertex]
    · apply (SimpleGraph.fromRel_adj
        jTemplateRelation (jThetaVertex copy u)
        (jThetaVertex copy v)).mpr
      constructor
      · intro heq
        have hinj : Function.Injective (jThetaVertex copy) := by fin_cases copy <;> decide
        exact hne (hinj heq)
      · right
        rcases u with (u | u) | u <;>
          rcases v with (v | v) | v <;>
          simp_all [subdivisionRelation, jTemplateRelation, jThetaVertex]
  · fin_cases copy <;> decide

lemma jThetaVertex_mem (copy : Fin 2)
    (v : SubdivisionVertex 2) :
    InJCopy copy (jThetaVertex copy v) := by
  rcases v with (base | center) | pair
  · exact ⟨base, rfl⟩
  · simp [InJCopy, jThetaVertex]
  · simp [InJCopy, jThetaVertex]

def gammaCycleVertex : Fin 8 → SubdivisionVertex 3 :=
  ![.inl (.inl 0),
    .inr (0, 0),
    .inl (.inr 0),
    .inr (1, 0),
    .inl (.inl 1),
    .inr (1, 1),
    .inl (.inr 1),
    .inr (0, 1)]

def gammaCycleCopy :
    SimpleGraph.Copy (SimpleGraph.cycleGraph 8) gammaGraph := by
  refine ⟨⟨gammaCycleVertex, ?_⟩, ?_⟩
  · intro u v hadj
    fin_cases u <;> fin_cases v <;>
      simp_all [gammaCycleVertex, SubdivisionGraph,
        subdivisionRelation, SimpleGraph.cycleGraph]
    all_goals
      exact (of_decide_eq_false rfl) hadj
  · decide

def kGammaVertex (copy : Fin 2)
    (v : SubdivisionVertex 3) : KVertex := (copy, v)

def kGammaCopy (copy : Fin 2) :
    SimpleGraph.Copy gammaGraph kTemplate := by
  refine ⟨⟨kGammaVertex copy, ?_⟩, ?_⟩
  · intro u v hadj
    rcases (SimpleGraph.fromRel_adj
      (subdivisionRelation 3) u v).mp hadj with
      ⟨hne, hforward | hbackward⟩
    · apply (SimpleGraph.fromRel_adj
        kTemplateRelation (kGammaVertex copy u)
        (kGammaVertex copy v)).mpr
      constructor
      · intro heq
        exact hne (congrArg Prod.snd heq)
      · left
        exact Or.inl ⟨rfl, hforward⟩
    · apply (SimpleGraph.fromRel_adj
        kTemplateRelation (kGammaVertex copy u)
        (kGammaVertex copy v)).mpr
      constructor
      · intro heq
        exact hne (congrArg Prod.snd heq)
      · right
        exact Or.inl ⟨rfl, hbackward⟩
  · intro u v h
    exact congrArg Prod.snd h

def copyToQuotient {α β : Type*}
    (source : SimpleGraph β) (target : SimpleGraph α)
    (f : α → α) (copy : SimpleGraph.Copy source target)
    (hinj : Function.Injective (fun v : β => f (copy v))) :
    SimpleGraph.Copy source (quotientGraph target f) := by
  refine ⟨⟨fun v => ⟨f (copy v), ⟨copy v, rfl⟩⟩, ?_⟩, ?_⟩
  · intro u v hadj
    apply (SimpleGraph.fromRel_adj
      (quotientRelation target f) _ _).mpr
    constructor
    · intro heq
      exact hadj.ne (hinj (congrArg Subtype.val heq))
    · left
      exact ⟨copy u, copy v, rfl, rfl, copy.toHom.map_rel hadj⟩
  · intro u v heq
    exact hinj (congrArg Subtype.val heq)

theorem proposedFamily_isCyclic : IsCyclicFamily proposedFamily :=
  have not_acyclic_of_eight_cycle_copy
      {α : Type _} {graph : SimpleGraph α}
      (copy : SimpleGraph.Copy (SimpleGraph.cycleGraph 8) graph) :
      ¬ graph.IsAcyclic := by
    intro hacyclic
    have hcycle : (SimpleGraph.cycleGraph 8).IsAcyclic :=
      hacyclic.comap copy.toHom copy.injective
    exact hcycle (SimpleGraph.cycleGraph.cycle 5)
      (SimpleGraph.cycleGraph.isCycle_cycle)
  have encodeFiniteGraph_not_acyclic
      {α : Type _} [Fintype α]
      (graph : SimpleGraph α) (h : ¬ graph.IsAcyclic) :
      ¬ (encodeFiniteGraph graph).graph.IsAcyclic := by
    intro hencoded
    apply h
    exact (SimpleGraph.Iso.map (Fintype.equivFin α) graph).isAcyclic_iff.mpr
      hencoded
  have jQuotient_not_acyclic
      {f : JVertex → JVertex} (hf : JAdmissible f) :
      ¬ (encodeFiniteGraph (quotientGraph jTemplate f)).graph.IsAcyclic := by
    have jTheta_quotient_injective
        {f : JVertex → JVertex} (hf : JAdmissible f)
        (copy : Fin 2) :
        Function.Injective (fun v : SubdivisionVertex 2 =>
          f (jThetaVertex copy v)) := by
      intro u v heq
      have htemplate : jThetaVertex copy u = jThetaVertex copy v :=
        hf.2.2 copy (jThetaVertex_mem copy u)
          (jThetaVertex_mem copy v) heq
      exact (jThetaCopy copy).injective htemplate
    apply encodeFiniteGraph_not_acyclic
    apply not_acyclic_of_eight_cycle_copy
    exact (copyToQuotient thetaGraph jTemplate f (jThetaCopy 0)
      (jTheta_quotient_injective hf 0)).comp thetaCycleCopy
  have kQuotient_not_acyclic
      {f : KVertex → KVertex} (hf : KAdmissible f) :
      ¬ (encodeFiniteGraph (quotientGraph kTemplate f)).graph.IsAcyclic := by
    have kGamma_quotient_injective
        {f : KVertex → KVertex} (hf : KAdmissible f)
        (copy : Fin 2) :
        Function.Injective (fun v : SubdivisionVertex 3 =>
          f (kGammaVertex copy v)) := by
      intro u v heq
      have htemplate : kGammaVertex copy u = kGammaVertex copy v :=
        hf.2 copy (show (kGammaVertex copy u).1 = copy from rfl)
          (show (kGammaVertex copy v).1 = copy from rfl) heq
      exact (kGammaCopy copy).injective htemplate
    apply encodeFiniteGraph_not_acyclic
    apply not_acyclic_of_eight_cycle_copy
    exact (copyToQuotient gammaGraph kTemplate f (kGammaCopy 0)
      (kGamma_quotient_injective hf 0)).comp gammaCycleCopy
  have four_cycle_not_acyclic : ¬ (finiteCycle 4).graph.IsAcyclic := by
    intro h
    exact h (SimpleGraph.cycleGraph.cycle 1)
      SimpleGraph.cycleGraph.isCycle_cycle
  have six_cycle_not_acyclic : ¬ (finiteCycle 6).graph.IsAcyclic := by
    intro h
    exact h (SimpleGraph.cycleGraph.cycle 3)
      SimpleGraph.cycleGraph.isCycle_cycle
  proposedFamily_induction (P := fun graph => ¬ graph.graph.IsAcyclic)
    four_cycle_not_acyclic six_cycle_not_acyclic
    (fun _ hf => jQuotient_not_acyclic hf)
    (fun _ hf => kQuotient_not_acyclic hf)

end Cyclicity

noncomputable section CharacteristicAvoidance

open SimpleGraph

section PointClass

variable (K : Type*) [Field K]


def colorRespectingQuotientProjectionHom
    {V : Type*} (graph : SimpleGraph V) (color : V → Bool)
    (hproper : ∀ ⦃u v : V⦄, graph.Adj u v → color u ≠ color v)
    (f : V → V) (hf : ColorRespecting color f) :
    graph →g quotientGraph graph f := by
  refine ⟨fun v => ⟨f v, v, rfl⟩, ?_⟩
  intro u v hadj
  apply (SimpleGraph.fromRel_adj
    (quotientRelation graph f)
    (⟨f u, u, rfl⟩ : Set.range f)
    (⟨f v, v, rfl⟩ : Set.range f)).mpr
  constructor
  · intro heq
    exact hproper hadj
      (hf u v (congrArg Subtype.val heq))
  · left
    exact ⟨u, v, rfl, rfl, hadj⟩

lemma jTemplate_adj_color_ne {u v : JVertex} (h : jTemplate.Adj u v) : jColor u ≠ jColor v := by
  rcases u with (u | u) | (u | u) <;>
    rcases v with (v | v) | (v | v) <;>
    simp_all [jTemplate, SimpleGraph.fromRel_adj,
      jTemplateRelation, jColor]

lemma kTemplate_adj_color_ne {u v : KVertex} (h : kTemplate.Adj u v) : kColor u ≠ kColor v := by
  rcases u with ⟨u, (u | u) | u⟩ <;>
    rcases v with ⟨v, (v | v) | v⟩ <;>
    fin_cases u <;> fin_cases v <;>
    simp_all [kTemplate, SimpleGraph.fromRel_adj,
      kTemplateRelation, kColor, subdivisionColor,
      subdivisionRelation, kSpecifiedCenter]
  all_goals aesop


end PointClass

end CharacteristicAvoidance

noncomputable section SubdivisionLineExtraction

open SimpleGraph

variable (K : Type*) [Field K]


end SubdivisionLineExtraction

noncomputable section Padding

open SimpleGraph

lemma free_map_of_no_isolated
    {U V W : Type*}
    (forbidden : SimpleGraph U)
    (hneighbors : ∀ u : U, ∃ v : U, forbidden.Adj u v)
    {host : SimpleGraph V}
    (embedding : V ↪ W)
    (hfree : forbidden.Free host) :
    forbidden.Free (host.map embedding) := by
  classical
  rintro ⟨copy⟩
  have hpreimage (u : U) : ∃ v : V, embedding v = copy u := by
    obtain ⟨w, huw⟩ := hneighbors u
    have hadj := copy.toHom.map_rel huw
    change (host.map embedding).Adj (copy u) (copy w) at hadj
    obtain ⟨v, _, _, hv, _⟩ :=
      (SimpleGraph.map_adj embedding host _ _).mp hadj
    exact ⟨v, hv⟩
  let lift : U → V := fun u => Classical.choose (hpreimage u)
  have hlift (u : U) : embedding (lift u) = copy u :=
    Classical.choose_spec (hpreimage u)
  apply hfree
  refine ⟨⟨⟨lift, ?_⟩, ?_⟩⟩
  · intro u v huv
    have hadj := copy.toHom.map_rel huv
    change (host.map embedding).Adj (copy u) (copy v) at hadj
    rw [← hlift u, ← hlift v] at hadj
    exact SimpleGraph.map_adj_apply.mp hadj
  · intro u v huv
    change lift u = lift v at huv
    apply copy.injective
    change copy u = copy v
    rw [← hlift u, ← hlift v]
    exact congrArg embedding huv

lemma extremalNumber_monotone_of_no_isolated
    {U : Type*} (forbidden : SimpleGraph U)
    (hneighbors : ∀ u : U, ∃ v : U, forbidden.Adj u v)
    {m n : ℕ} (hmn : m ≤ n) :
    SimpleGraph.extremalNumber m forbidden ≤
      SimpleGraph.extremalNumber n forbidden := by
  classical
  have hbound :
      SimpleGraph.extremalNumber (Fintype.card (Fin m)) forbidden ≤
        SimpleGraph.extremalNumber n forbidden := by
    apply (SimpleGraph.extremalNumber_le_iff
      (V := Fin m) forbidden
      (SimpleGraph.extremalNumber n forbidden)).mpr
    intro host _ hfree
    let embedding : Fin m ↪ Fin n := Fin.castLEEmb hmn
    have hpadded : forbidden.Free (host.map embedding) :=
      free_map_of_no_isolated forbidden hneighbors embedding hfree
    calc
      host.edgeFinset.card =
          (host.map embedding).edgeFinset.card := by
        simpa only [SimpleGraph.edgeFinset_card,
          ← Nat.card_eq_fintype_card] using
          (SimpleGraph.card_edgeFinset_map embedding host).symm
      _ ≤ SimpleGraph.extremalNumber n forbidden := by
        simpa using SimpleGraph.card_edgeFinset_le_extremalNumber hpadded
  simpa using hbound


end Padding

noncomputable section LocalGeometry

open SimpleGraph

lemma cycle_of {V : Type*} {G : SimpleGraph V} {k : ℕ} (f : Fin (k + 2) → V)
    (hf : Function.Injective f) (hadj : ∀ i, G.Adj (f i) (f (i + 1)))
    (hfree : (cycleGraph (k + 2)).Free G) : False :=
  hfree ⟨⟨⟨f, fun {i j} h => by
    rcases cycleGraph_adj.1 h with h | h
    · rw [sub_eq_iff_eq_add.1 h, add_comm]; exact (hadj j).symm
    · rw [sub_eq_iff_eq_add.1 h, add_comm]; exact hadj i⟩, hf⟩⟩

theorem common_neighbor_unique_of_four_cycle_free
    {V : Type*} {G : SimpleGraph V}
    (hfree : (SimpleGraph.cycleGraph 4).Free G)
    {u v x y : V} (huv : u ≠ v)
    (hux : G.Adj u x) (hvx : G.Adj v x)
    (huy : G.Adj u y) (hvy : G.Adj v y) : x = y := by
  by_contra hxy
  refine cycle_of ![u, x, v, y] ?_ ?_ hfree
  · intro i j h
    fin_cases i <;> fin_cases j <;> simp_all [hux.ne, hux.ne.symm, hvx.ne, hvx.ne.symm,
      huy.ne, huy.ne.symm, hvy.ne, hvy.ne.symm, Ne.symm huv, Ne.symm hxy]
  · intro i; fin_cases i
    exacts [hux, hvx.symm, hvy, huy.symm]

def CommonNeighborRelated {V : Type*} (G : SimpleGraph V)
    (u v : V) : Prop :=
  u ≠ v ∧ ∃ w : V, G.Adj u w ∧ G.Adj v w

lemma commonNeighborRelated_symm
    {V : Type*} {G : SimpleGraph V} {u v : V}
    (h : CommonNeighborRelated G u v) :
    CommonNeighborRelated G v u := by
  obtain ⟨hne, w, huw, hvw⟩ := h
  exact ⟨hne.symm, w, hvw, huw⟩

lemma bipartite_coloring_eq_of_common_neighbor
    {V : Type*} {G : SimpleGraph V}
    (color : G.Coloring (Fin 2)) {u v w : V}
    (huw : G.Adj u w) (hvw : G.Adj v w) :
    color u = color v := by
  have hu := color.valid huw
  have hv := color.valid hvw
  apply Fin.ext
  omega

theorem common_neighbors_triangle_eq_of_cycle_free
    {V : Type*} {G : SimpleGraph V}
    (hbip : G.IsBipartite)
    (hfour : (SimpleGraph.cycleGraph 4).Free G)
    (hsix : (SimpleGraph.cycleGraph 6).Free G)
    {u v w a b c : V}
    (huv : u ≠ v) (hvw : v ≠ w) (huw : u ≠ w)
    (hua : G.Adj u a) (hva : G.Adj v a)
    (hvb : G.Adj v b) (hwb : G.Adj w b)
    (hwc : G.Adj w c) (huc : G.Adj u c) :
    a = b ∧ b = c := by
  have h4 := @common_neighbor_unique_of_four_cycle_free _ _ hfour
  by_cases hab : a = b
  · exact ⟨hab, hab ▸ h4 huw hua (hab ▸ hwb) huc hwc⟩
  by_cases hbc : b = c
  · exact (hab ((h4 huv hua hva huc (hbc ▸ hvb)).trans hbc.symm)).elim
  by_cases hac : a = c
  · exact (hab (h4 hvw hva (hac ▸ hwc) hvb hwb)).elim
  obtain ⟨col⟩ := hbip
  have e1 := bipartite_coloring_eq_of_common_neighbor col hua hva
  have e2 := bipartite_coloring_eq_of_common_neighbor col hvb hwb
  have hub : u ≠ b := fun h => col.valid hvb (h ▸ e1.symm)
  have hvc : v ≠ c := fun h => col.valid huc (h ▸ e1)
  have hwa : w ≠ a := fun h => col.valid hva (h ▸ e2)
  refine (cycle_of ![u, a, v, b, w, c] ?_ ?_ hsix).elim
  · intro i j h
    fin_cases i <;> fin_cases j <;> simp_all [hua.ne, hua.ne.symm, hva.ne, hva.ne.symm,
      hvb.ne, hvb.ne.symm, hwb.ne, hwb.ne.symm, hwc.ne, hwc.ne.symm, huc.ne, huc.ne.symm,
      Ne.symm huv, Ne.symm hvw, Ne.symm huw, Ne.symm hab, Ne.symm hbc, Ne.symm hac,
      Ne.symm hub, Ne.symm hvc, Ne.symm hwa]
  · intro i; fin_cases i
    exacts [hua, hva.symm, hvb, hwb.symm, hwc, huc.symm]

theorem common_second_neighbors_pairwise_unrelated
    {V : Type*} {G : SimpleGraph V}
    (hbip : G.IsBipartite)
    (hfour : (SimpleGraph.cycleGraph 4).Free G)
    (hsix : (SimpleGraph.cycleGraph 6).Free G)
    {u v x y : V} (huv : u ≠ v)
    (hunrelated : ¬ CommonNeighborRelated G u v)
    (hxu : CommonNeighborRelated G x u)
    (hxv : CommonNeighborRelated G x v)
    (hyu : CommonNeighborRelated G y u)
    (hyv : CommonNeighborRelated G y v) :
    ¬ CommonNeighborRelated G x y := by
  rintro ⟨hxy, b, hxb, hyb⟩
  obtain ⟨hxu_ne, a, hxa, hua⟩ := hxu
  obtain ⟨hxv_ne, d, hxd, hvd⟩ := hxv
  obtain ⟨hyu_ne, c, hyc, huc⟩ := hyu
  obtain ⟨hyv_ne, e, hye, hve⟩ := hyv
  have habc : a = c ∧ c = b :=
    common_neighbors_triangle_eq_of_cycle_free hbip hfour hsix
      hxu_ne (Ne.symm hyu_ne) hxy
      hxa hua huc hyc hyb hxb
  have hdeb : d = e ∧ e = b :=
    common_neighbors_triangle_eq_of_cycle_free hbip hfour hsix
      hxv_ne (Ne.symm hyv_ne) hxy
      hxd hvd hve hye hyb hxb
  apply hunrelated
  refine ⟨huv, b, ?_, ?_⟩
  · rwa [habc.1.trans habc.2] at hua
  · rwa [hdeb.1.trans hdeb.2] at hvd

section FourPathCounting

variable {V : Type*} [Fintype V] [DecidableEq V]


end FourPathCounting

end LocalGeometry

noncomputable section BreadthFirstCounting

open SimpleGraph

section BreadthFirstPaths

variable {V : Type*} [Fintype V] [DecidableEq V]


end BreadthFirstPaths

end BreadthFirstCounting

noncomputable section SubdivisionCounting

open SimpleGraph

section SubdivisionCopies

variable {V : Type*} {G : SimpleGraph V} {k : ℕ}

def subdivisionVertexImage
    (base : Fin 3 → V) (center : Fin k → V)
    (pair : Fin 3 → Fin k → V) : SubdivisionVertex k → V
  | .inl (.inl i) => base i
  | .inl (.inr j) => center j
  | .inr (i, j) => pair i j

lemma subdivisionVertexImage_injective
    (hbip : G.IsBipartite)
    (base : Fin 3 → V) (center : Fin k → V)
    (pair : Fin 3 → Fin k → V)
    (hbase : Function.Injective base)
    (hcenter : Function.Injective center)
    (hbase_center : ∀ i j, base i ≠ center j)
    (hbase_unrelated : ∀ ⦃i j : Fin 3⦄, i ≠ j →
      ¬ CommonNeighborRelated G (base i) (base j))
    (hcenter_unrelated : ∀ ⦃i j : Fin k⦄, i ≠ j →
      ¬ CommonNeighborRelated G (center i) (center j))
    (hpair_base : ∀ i j, G.Adj (base i) (pair i j))
    (hpair_center : ∀ i j, G.Adj (center j) (pair i j)) :
    Function.Injective (subdivisionVertexImage base center pair) := by
  obtain ⟨col⟩ := hbip
  have e i j : col (base i) = col (center j) :=
    bipartite_coloring_eq_of_common_neighbor col (hpair_base i j) (hpair_center i j)
  have hb i j i' : pair i j ≠ base i' := fun h =>
    col.valid (hpair_base i j) (by rw [h, e i j, e i' j])
  have hc i j j' : pair i j ≠ center j' := fun h =>
    col.valid (hpair_base i j) (by rw [h, e i j'])
  have hp {i j i' j'} (h : pair i j = pair i' j') : i = i' ∧ j = j' := by
    by_contra hne
    rcases not_and_or.1 hne with hi | hj
    · exact hbase_unrelated hi ⟨hbase.ne hi, _, hpair_base i j, h ▸ hpair_base i' j'⟩
    · obtain rfl : i = i' := by
        by_contra hi
        exact hbase_unrelated hi ⟨hbase.ne hi, _, hpair_base i j, h ▸ hpair_base i' j'⟩
      exact hcenter_unrelated hj ⟨hcenter.ne hj, _, hpair_center i j, h ▸ hpair_center i j'⟩
  rintro ((i | j) | ⟨i, j⟩) ((i' | j') | ⟨i', j'⟩) h <;>
    simp only [subdivisionVertexImage] at h
  · rw [hbase h]
  · exact absurd h (hbase_center _ _)
  · exact absurd h.symm (hb _ _ _)
  · exact absurd h.symm (hbase_center _ _)
  · rw [hcenter h]
  · exact absurd h.symm (hc _ _ _)
  · exact absurd h (hb _ _ _)
  · exact absurd h (hc _ _ _)
  · obtain ⟨rfl, rfl⟩ := hp h; rfl


end SubdivisionCopies

end SubdivisionCounting

noncomputable section QuotientWitnesses

open SimpleGraph


end QuotientWitnesses

section CommutativeRing

variable {K : Type*} [CommRing K]

def symmetricQuadratic (a b c x y : K) : K :=
  a * x ^ 2 + (2 : K) * b * x * y + c * y ^ 2


end CommutativeRing

section CharacteristicTwo

variable {K : Type*} [Field K] [CharP K 2]

end CharacteristicTwo

section Field

variable {K : Type*} [Field K]


end Field

noncomputable section Separation

open Filter Finset SimpleGraph
open scoped Topology

def extremalScale (n : ℕ) : ℝ :=
  (n : ℝ) ^ ((4 : ℝ) / 3)

def UniformMemberLower (family : Finset FiniteGraph) (c : ℝ) : Prop :=
  ∀ forbidden ∈ family,
    ∀ᶠ n : ℕ in atTop,
      c * extremalScale n ≤
        (SimpleGraph.extremalNumber n forbidden.graph : ℝ)

noncomputable def manuscriptLowerConstant : ℝ :=
  (2 : ℝ) ^ (-((4 : ℝ) / 3)) *
    (27 : ℝ) ^ (-((4 : ℝ) / 3))

theorem manuscriptLowerConstant_pos : 0 < manuscriptLowerConstant := by
  unfold manuscriptLowerConstant
  positivity

end Separation

noncomputable section Supersaturation

open Finset SimpleGraph

section FiniteHeavyFibers


end FiniteHeavyFibers

section ActualFourPathFibers

variable {V : Type*} [Fintype V] [DecidableEq V]

omit [Fintype V] [DecidableEq V] in
lemma img_rel {G : SimpleGraph V} {k : ℕ} {b : Fin 3 → V} {c : Fin k → V} {m : Fin 3 → Fin k → V}
    (hbm : ∀ i j, G.Adj (b i) (m i j)) (hcm : ∀ i j, G.Adj (c j) (m i j))
    {s s' : SubdivisionVertex k} (h : subdivisionRelation k s s') :
    G.Adj (subdivisionVertexImage b c m s) (subdivisionVertexImage b c m s') := by
  rcases s with (i | j) | ⟨i, j⟩ <;> rcases s' with (i' | j') | ⟨i', j'⟩ <;>
    simp only [subdivisionRelation] at h <;> subst h
  exacts [hbm _ _, hcm _ _]

end ActualFourPathFibers

section ActualThetaExtensions

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualThetaExtensions

section ActualCommonCenterTriples

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualCommonCenterTriples

section CubicBinomialSupersaturation

end CubicBinomialSupersaturation

section ActualTripleSupersaturation

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualTripleSupersaturation

section OrderedThetaTripleCounting


end OrderedThetaTripleCounting

section ActualGammaAndKForcing

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualGammaAndKForcing

section ActualBadVertexEdgeCounting

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualBadVertexEdgeCounting

end Supersaturation

noncomputable section BadVertexCounting

open Finset SimpleGraph


section ActualIndependentTriples

variable {V : Type*} [Fintype V] [DecidableEq V]


end ActualIndependentTriples

end BadVertexCounting

noncomputable section TripleMassIncidence

open Finset SimpleGraph

section TripleIncidence

variable {V : Type*} [Fintype V] [DecidableEq V]

section UpperCount

open scoped Classical

variable {V : Type*} {G : SimpleGraph V}

lemma two_step [Fintype V] (hfour : (cycleGraph 4).Free G) {d : ℕ} (hd : ∀ v, d ≤ G.degree v)
    (x : V) (s t : Finset V) (hs : ∀ b ∈ s, G.Adj x b)
    (ht : ∀ b ∈ s, ∀ y, G.Adj b y → y ≠ x → y ∈ t) :
    #s * (d - 1) ≤ #t := by
  calc #s * (d - 1) ≤ ∑ b ∈ s, #((G.neighborFinset b).erase x) := by
        have := card_nsmul_le_sum s (fun b => #((G.neighborFinset b).erase x)) (d - 1)
          fun b hb => by
            rw [card_erase_of_mem (by simpa using (hs b hb).symm), card_neighborFinset_eq_degree]
            have := hd b; omega
        simpa using this
    _ = #(s.sigma fun b => (G.neighborFinset b).erase x) := (card_sigma ..).symm
    _ ≤ #t := card_le_card_of_injOn (fun p => p.2)
        (by rintro ⟨b, y⟩ hp
            simp only [coe_sigma, Set.mem_sigma_iff, mem_coe, mem_erase, mem_neighborFinset] at hp
            exact ht _ hp.1 _ hp.2.2 hp.2.1)
        (by
          rintro ⟨b, y⟩ hp ⟨b', y'⟩ hq (h : y = y')
          simp only [coe_sigma, Set.mem_sigma_iff, mem_coe, mem_erase, mem_neighborFinset] at hp hq
          subst h
          obtain rfl := common_neighbor_unique_of_four_cycle_free hfour hp.2.1.symm
            (hs _ hp.1) hp.2.2.symm (hs _ hq.1) hq.2.2.symm
          rfl)

/-- second neighbourhood -/
lemma card_far [Fintype V] (hbip : G.IsBipartite) (hfour : (cycleGraph 4).Free G)
    (hsix : (cycleGraph 6).Free G) {d : ℕ} (hd : ∀ v, d ≤ G.degree v) {u x : V}
    (hx : CommonNeighborRelated G u x) :
    (d - 1) * (d - 1) ≤
      #{v | (v ≠ u ∧ ¬ CommonNeighborRelated G u v) ∧ CommonNeighborRelated G v x} := by
  obtain ⟨hux, a, hua, hxa⟩ := hx
  have := two_step hfour hd x ((G.neighborFinset x).erase a)
    {v | (v ≠ u ∧ ¬ CommonNeighborRelated G u v) ∧ CommonNeighborRelated G v x}
    (by simp) fun b hb y hy hyx => by
      simp only [mem_erase, mem_neighborFinset] at hb
      simp only [mem_filter, mem_univ, true_and]
      refine ⟨⟨?_, ?_⟩, hyx, b, hy.symm, hb.2⟩
      · rintro rfl
        exact hb.1 (common_neighbor_unique_of_four_cycle_free hfour hux hua hxa hy.symm hb.2).symm
      · rintro ⟨huy, c, huc, hyc⟩
        exact hb.1 (common_neighbors_triangle_eq_of_cycle_free hbip hfour hsix hux hyx.symm huy
          hua hxa hb.2 hy.symm hyc huc).1.symm
  rw [card_erase_of_mem (by simpa using hxa), card_neighborFinset_eq_degree] at this
  exact le_trans (Nat.mul_le_mul_right _ (by have := hd x; omega)) this

/-- number of (v, x) with v far from u and x a common second neighbour -/
lemma card_paths [Fintype V] (hbip : G.IsBipartite) (hfour : (cycleGraph 4).Free G)
    (hsix : (cycleGraph 6).Free G) {d : ℕ} (hd : ∀ v, d ≤ G.degree v) (u : V) :
    G.degree u * (d - 1) ^ 3 ≤ ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
      #{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} := by
  have h := sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow
    (s := ({v | v ≠ u ∧ ¬ CommonNeighborRelated G u v} : Finset V)) (t := univ)
    (r := fun v x => CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x)
  simp only [bipartiteAbove, bipartiteBelow, filter_filter] at h
  rw [h]
  calc G.degree u * (d - 1) ^ 3 ≤ #{x | CommonNeighborRelated G u x} * ((d - 1) * (d - 1)) := by
        calc _ = G.degree u * (d - 1) * ((d - 1) * (d - 1)) := by ring
          _ ≤ _ := Nat.mul_le_mul_right _ (by
            rw [← card_neighborFinset_eq_degree]
            exact two_step hfour hd u _ _ (by simp) fun b hb y hy hyu => by
              simp only [mem_filter, mem_univ, true_and]
              exact ⟨hyu.symm, b, by simpa using hb, hy.symm⟩)
    _ ≤ ∑ x ∈ {x | CommonNeighborRelated G u x},
          #{v | (v ≠ u ∧ ¬ CommonNeighborRelated G u v) ∧ CommonNeighborRelated G v x} := by
        have := card_nsmul_le_sum {x | CommonNeighborRelated G u x} (fun x =>
          #{v | (v ≠ u ∧ ¬ CommonNeighborRelated G u v) ∧ CommonNeighborRelated G v x})
          ((d - 1) * (d - 1)) fun x hx => card_far hbip hfour hsix hd (by simpa using hx)
        simpa [mul_comm] using this
    _ ≤ _ := by
        rw [sum_filter]
        refine sum_le_sum fun x _ => ?_
        split_ifs with hx
        · exact card_le_card fun v => by simp [hx]
        · exact Nat.zero_le _

lemma img_color (col : G.Coloring (Fin 2)) {k : ℕ} {b : Fin 3 → V} {c : Fin k → V}
    {m : Fin 3 → Fin k → V}
    (hbm : ∀ i j, G.Adj (b i) (m i j)) (hcm : ∀ i j, G.Adj (c j) (m i j)) (j0 : Fin k)
    (s : SubdivisionVertex k) :
    col (subdivisionVertexImage b c m s) = col (c j0) ↔ subdivisionColor k s = false := by
  have e i j : col (b i) = col (c j) :=
    bipartite_coloring_eq_of_common_neighbor col (hbm i j) (hcm i j)
  rcases s with (i | j) | ⟨i, j⟩
  · simpa [subdivisionVertexImage, subdivisionColor] using e i j0
  · simp [subdivisionVertexImage, subdivisionColor, ← e 0 j, e 0 j0]
  · simp only [subdivisionVertexImage, subdivisionColor, Bool.true_eq_false, iff_false]
    exact fun h => col.valid (hcm i j) ((e i j).symm.trans ((e i j0).trans h.symm))

lemma exists_conf (hbip : G.IsBipartite) (hfour : (cycleGraph 4).Free G)
    (hsix : (cycleGraph 6).Free G) {k : ℕ} (b : Fin 3 → V) (c : Fin k → V)
    (hb : Function.Injective b) (hc : Function.Injective c)
    (hbu : ∀ ⦃i j⦄, i ≠ j → ¬ CommonNeighborRelated G (b i) (b j))
    (hr : ∀ i j, CommonNeighborRelated G (b i) (c j)) :
    ∃ m : Fin 3 → Fin k → V, Function.Injective (subdivisionVertexImage b c m) ∧
      (∀ i j, G.Adj (b i) (m i j)) ∧ ∀ i j, G.Adj (c j) (m i j) := by
  choose m hm using fun i j => (hr i j).2
  refine ⟨m, subdivisionVertexImage_injective hbip b c m hb hc (fun i j => (hr i j).1) hbu
    (fun i j _ => common_second_neighbors_pairwise_unrelated hbip hfour hsix
      (hb.ne (by decide : (0 : Fin 3) ≠ 1)) (hbu (by decide))
      (commonNeighborRelated_symm (hr 0 i)) (commonNeighborRelated_symm (hr 1 i))
      (commonNeighborRelated_symm (hr 0 j)) (commonNeighborRelated_symm (hr 1 j)))
    (fun i j => (hm i j).1) (fun i j => (hm i j).2), fun i j => (hm i j).1,
    fun i j => (hm i j).2⟩

lemma free_of_hom {α : Type*} [Fintype α] [Nonempty α] (T : SimpleGraph α) (g : α → V)
    (hg : ∀ x y, T.Adj x y → G.Adj (g x) (g y))
    {inst : Fintype (Set.range (Function.invFun g ∘ g))}
    (h : (@encodeFiniteGraph _ inst (quotientGraph T (Function.invFun g ∘ g))).graph.Free G) :
    False := by
  have spec a : g (Function.invFun g (g a)) = g a := Function.invFun_eq ⟨a, rfl⟩
  refine h ⟨Copy.comp ⟨⟨fun u => g u.1, ?_⟩, ?_⟩
    (Iso.map (Fintype.equivFin _) (quotientGraph T (Function.invFun g ∘ g))).symm.toCopy⟩
  · rintro ⟨_, a, rfl⟩ ⟨_, b, rfl⟩ hab
    obtain ⟨-, ⟨x, y, hx, hy, hxy⟩ | ⟨x, y, hx, hy, hxy⟩⟩ := (fromRel_adj _ _ _).1 hab
    · have hx' := congrArg g hx; have hy' := congrArg g hy
      simp only [Function.comp, spec] at hx' hy' ⊢
      rw [← hx', ← hy']; exact hg _ _ hxy
    · have hx' := congrArg g hx; have hy' := congrArg g hy
      simp only [Function.comp, spec] at hx' hy' ⊢
      rw [← hx', ← hy']; exact (hg _ _ hxy).symm
  · rintro ⟨_, a, rfl⟩ ⟨_, b, rfl⟩ hab
    change g (Function.invFun g (g a)) = g (Function.invFun g (g b)) at hab
    rw [spec, spec] at hab
    simp [hab]

lemma nf_eq {α : Type*} [Nonempty α] (g : α → V) {x y : α} :
    (Function.invFun g ∘ g) x = (Function.invFun g ∘ g) y ↔ g x = g y :=
  by
  constructor
  · intro h
    simpa [Function.invFun_eq ⟨x, rfl⟩, Function.invFun_eq ⟨y, rfl⟩] using congrArg g h
  · intro h; simp [h]

/-- K: two gamma configurations with adjacent marked centres are forbidden. -/
lemma k_free (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (col : G.Coloring (Fin 2))
    (b c : Fin 2 → Fin 3 → V) (m : Fin 2 → Fin 3 → Fin 3 → V)
    (hinj : ∀ t, Function.Injective (subdivisionVertexImage (b t) (c t) (m t)))
    (hbm : ∀ t i j, G.Adj (b t i) (m t i j)) (hcm : ∀ t i j, G.Adj (c t j) (m t i j))
    (hadj : G.Adj (c 0 0) (c 1 0)) : False := by
  let g : KVertex → V := fun v => subdivisionVertexImage (b v.1) (c v.1) (m v.1) v.2
  have hcol (v : KVertex) : col (g v) = col (c 0 0) ↔ kColor v = false := by
    obtain ⟨t, s⟩ := v
    have h := img_color col (hbm t) (hcm t) 0 s
    rcases (by decide : ∀ t : Fin 2, t = 0 ∨ t = 1) t with rfl | rfl
    · simpa [kColor, g] using h
    · have key : ∀ a b c : Fin 2, b ≠ c → (a = b ↔ ¬ a = c) := by decide
      have hk : kColor (1, s) = !subdivisionColor 3 s := by simp [kColor]
      rw [hk, key _ _ _ (col.valid hadj)]
      simp only [g] at h ⊢
      rw [h]; simp
  refine free_of_hom kTemplate g ?_ (hfree _ (kQuotient_mem_proposedFamily ⟨?_, ?_⟩))
  · intro x y hxy
    obtain ⟨-, h | h⟩ := (fromRel_adj _ _ _).1 hxy
    · rcases h with ⟨h1, h2⟩ | ⟨h1, h2, h3, h4⟩
      · simp only [g, h1] at h2 ⊢; exact img_rel (hbm _) (hcm _) h2
      · simp [g, h1, h2, h3, h4, kSpecifiedCenter, subdivisionVertexImage, hadj]
    · rcases h with ⟨h1, h2⟩ | ⟨h1, h2, h3, h4⟩
      · simp only [g, h1] at h2 ⊢; exact (img_rel (hbm _) (hcm _) h2).symm
      · simp [g, h1, h2, h3, h4, kSpecifiedCenter, subdivisionVertexImage, hadj.symm]
  · intro x y h
    have h1 := hcol x; have h2 := hcol y
    rw [(nf_eq g).1 h] at h1
    cases hx : kColor x <;> cases hy : kColor y <;> simp_all
  · rintro t ⟨t1, s⟩ h1 ⟨t2, s'⟩ h2 h
    obtain rfl : t1 = t := h1
    obtain rfl : t2 = t1 := h2
    have h' : g (t2, s) = g (t2, s') := (nf_eq g).1 h
    rw [show s = s' from hinj t2 h']

def jMap (B : Fin 2 → Fin 3 → V) (c : Fin 2 → Fin 2 → V)
    (m : Fin 2 → Fin 3 → Fin 2 → V) (jn : V) : JVertex → V
  | .inl (.inl i) => ![B 0 0, B 1 0, B 0 1, B 0 2] i
  | .inl (.inr (t, j)) => c t j
  | .inr (.inl (t, (i, j))) => m t i j
  | .inr (.inr _) => jn

def jEmb (t : Fin 2) : SubdivisionVertex 2 → JVertex
  | .inl (.inl i) => .inl (.inl (jBase t i))
  | .inl (.inr j) => .inl (.inr (t, j))
  | .inr (i, j) => .inr (.inl (t, (i, j)))

/-- J: two theta configurations sharing two bases whose third bases have a common
neighbour are forbidden. -/
lemma j_free (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (col : G.Coloring (Fin 2))
    (B : Fin 2 → Fin 3 → V) (c : Fin 2 → Fin 2 → V)
    (m : Fin 2 → Fin 3 → Fin 2 → V) (jn : V)
    (hB1 : B 1 1 = B 0 1) (hB2 : B 1 2 = B 0 2) (hne : B 0 0 ≠ B 1 0)
    (hinj : ∀ t, Function.Injective (subdivisionVertexImage (B t) (c t) (m t)))
    (hbm : ∀ t i j, G.Adj (B t i) (m t i j)) (hcm : ∀ t i j, G.Adj (c t j) (m t i j))
    (hj0 : G.Adj (B 0 0) jn) (hj1 : G.Adj (B 1 0) jn) : False := by
  let g := jMap B c m jn
  have hbase t i : ![B 0 0, B 1 0, B 0 1, B 0 2] (jBase t i) = B t i := by
    fin_cases t <;> fin_cases i <;> simp [jBase, hB1, hB2]
  have hemb t s : g (jEmb t s) = subdivisionVertexImage (B t) (c t) (m t) s := by
    rcases s with (i | j) | ⟨i, j⟩ <;> simp [g, jMap, jEmb, subdivisionVertexImage, hbase]
  have hct t : col (c t 0) = col (B 0 1) := by
    have h := (img_color col (hbm t) (hcm t) 0 (.inl (.inl 1))).2 rfl
    simp only [subdivisionVertexImage] at h
    rcases (by decide : ∀ t : Fin 2, t = 0 ∨ t = 1) t with rfl | rfl
    · exact h.symm
    · rw [← h, hB1]
  have hcol (v : JVertex) : col (g v) = col (B 0 1) ↔ jColor v = false := by
    have hjn : col jn ≠ col (B 0 1) := fun h => col.valid hj0 (by
      rw [h, ← hct 0]
      exact (img_color col (hbm 0) (hcm 0) 0 (.inl (.inl 0))).2 rfl)
    have hE t s : col (g (jEmb t s)) = col (B 0 1) ↔ jColor (jEmb t s) = false := by
      rw [hemb, ← hct t, img_color col (hbm t) (hcm t) 0 s]
      rcases s with (i | j) | ⟨i, j⟩ <;> rfl
    rcases v with ((i | ⟨t, j⟩) | (⟨t, i, j⟩ | ⟨⟩))
    · fin_cases i
      exacts [hE 0 (.inl (.inl 0)), hE 1 (.inl (.inl 0)), hE 0 (.inl (.inl 1)),
        hE 0 (.inl (.inl 2))]
    · exact hE t (.inl (.inr j))
    · exact hE t (.inr (i, j))
    · simpa [g, jMap, jColor] using hjn
  refine free_of_hom jTemplate g ?_ (hfree _ (jQuotient_mem_proposedFamily ⟨?_, ?_, ?_⟩))
  · have key : ∀ u v, jTemplateRelation u v → G.Adj (g u) (g v) := by
      rintro ((i | ⟨t, j⟩) | (⟨t, i, j⟩ | ⟨⟩)) ((i' | ⟨t', j'⟩) | (⟨t', i', j'⟩ | ⟨⟩)) h <;>
        simp only [jTemplateRelation] at h
      · subst h; simpa [g, jMap, hbase] using hbm t' i' j'
      · rcases h with rfl | rfl
        · simpa [g, jMap] using hj0
        · simpa [g, jMap] using hj1
      · obtain ⟨rfl, rfl⟩ := h; exact hcm t i' j
    intro u v huv
    obtain ⟨-, h | h⟩ := (fromRel_adj _ _ _).1 huv
    exacts [key _ _ h, (key _ _ h).symm]
  · intro x y h
    have h1 := hcol x; have h2 := hcol y
    rw [(nf_eq g).1 h] at h1
    cases hx : jColor x <;> cases hy : jColor y <;> simp_all
  · intro i i' h
    have h' := (nf_eq g).1 h
    have e0 := (hinj 0).ne (a₁ := .inl (.inl 0)) (a₂ := .inl (.inl 1)) (by simp)
    have e1 := (hinj 0).ne (a₁ := .inl (.inl 0)) (a₂ := .inl (.inl 2)) (by simp)
    have e2 := (hinj 0).ne (a₁ := .inl (.inl 1)) (a₂ := .inl (.inl 2)) (by simp)
    have e3 := (hinj 1).ne (a₁ := .inl (.inl 0)) (a₂ := .inl (.inl 1)) (by simp)
    have e4 := (hinj 1).ne (a₁ := .inl (.inl 0)) (a₂ := .inl (.inl 2)) (by simp)
    simp only [subdivisionVertexImage, hB1, hB2] at e0 e1 e2 e3 e4
    fin_cases i <;> fin_cases i' <;> simp [g, jMap] at h' ⊢ <;>
      first | exact absurd h' (by assumption) | exact absurd h'.symm (by assumption)
  · intro t
    have hcopy : ∀ v, InJCopy t v → ∃ s, jEmb t s = v := by
      rintro ((i | ⟨t', j⟩) | (⟨t', i, j⟩ | ⟨⟩)) h
      · obtain ⟨i', rfl⟩ := h; exact ⟨.inl (.inl i'), rfl⟩
      · obtain rfl : t = t' := h; exact ⟨.inl (.inr j), rfl⟩
      · obtain rfl : t = t' := h; exact ⟨.inr (i, j), rfl⟩
      · exact h.elim
    rintro u hu v hv h
    obtain ⟨s, rfl⟩ := hcopy u hu
    obtain ⟨s', rfl⟩ := hcopy v hv
    have h' := (nf_eq g).1 h
    rw [hemb, hemb] at h'
    rw [hinj t h']

/-- `u` is the marked centre of a subdivided `K_{3,3}` in girth-eight position. -/
def Good (G : SimpleGraph V) (u : V) : Prop :=
  ∃ b c : Fin 3 → V, Function.Injective b ∧
    (∀ ⦃i j⦄, i ≠ j → ¬ CommonNeighborRelated G (b i) (b j)) ∧
    Function.Injective c ∧ c 0 = u ∧ ∀ i j, CommonNeighborRelated G (b i) (c j)

lemma good_adj (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (hbip : G.IsBipartite)
    {u u' : V} (hu : Good G u) (hu' : Good G u') : ¬ G.Adj u u' := by
  have hfour := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inl rfl))))
  have hsix := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inr rfl))))
  obtain ⟨b, c, hb, hbu, hc, rfl, hr⟩ := hu
  obtain ⟨b', c', hb', hbu', hc', rfl, hr'⟩ := hu'
  obtain ⟨m, hm, hbm, hcm⟩ := exists_conf hbip hfour hsix b c hb hc hbu hr
  obtain ⟨m', hm', hbm', hcm'⟩ := exists_conf hbip hfour hsix b' c' hb' hc' hbu' hr'
  obtain ⟨col⟩ := hbip
  exact k_free hfree col ![b, b'] ![c, c'] ![m, m'] (Fin.forall_fin_two.2 ⟨hm, hm'⟩)
    (Fin.forall_fin_two.2 ⟨hbm, hbm'⟩) (Fin.forall_fin_two.2 ⟨hcm, hcm'⟩)

lemma theta_unique (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (hbip : G.IsBipartite)
    {x x' : Fin 3 → V} {c c' : Fin 2 → V}
    (hx : Function.Injective x) (hxu : ∀ ⦃i j⦄, i ≠ j → ¬ CommonNeighborRelated G (x i) (x j))
    (hx' : Function.Injective x') (hxu' : ∀ ⦃i j⦄, i ≠ j → ¬ CommonNeighborRelated G (x' i) (x' j))
    (hc : Function.Injective c) (hc' : Function.Injective c')
    (hr : ∀ i j, CommonNeighborRelated G (x i) (c j))
    (hr' : ∀ i j, CommonNeighborRelated G (x' i) (c' j))
    (h1 : x' 1 = x 1) (h2 : x' 2 = x 2) {w : V} (hw : G.Adj (x 0) w)
    (hw' : G.Adj (x' 0) w) : x 0 = x' 0 := by
  have hfour := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inl rfl))))
  have hsix := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inr rfl))))
  by_contra hne
  obtain ⟨m, hm, hbm, hcm⟩ := exists_conf hbip hfour hsix x c hx hc hxu hr
  obtain ⟨m', hm', hbm', hcm'⟩ := exists_conf hbip hfour hsix x' c' hx' hc' hxu' hr'
  obtain ⟨col⟩ := hbip
  exact j_free hfree col ![x, x'] ![c, c'] ![m, m'] w h1 h2 hne
    (Fin.forall_fin_two.2 ⟨hm, hm'⟩) (Fin.forall_fin_two.2 ⟨hbm, hbm'⟩)
    (Fin.forall_fin_two.2 ⟨hcm, hcm'⟩) hw hw'

lemma triple_count [Fintype V] (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (hbip : G.IsBipartite) {d : ℕ}
    (hd : ∀ v, d ≤ G.degree v) :
    d * ∑ u ∈ {u | ¬ Good G u}, ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
      #{x : Fin 3 → V | Function.Injective x ∧
        ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)} ≤ 2 * Fintype.card V ^ 3 := by
  have hfour := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inl rfl))))
  have hsix := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inr rfl))))
  have indep {u v : V} {x : Fin 3 → V} (hvu : v ≠ u)
      (huv : ¬ CommonNeighborRelated G u v)
      (hx : ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)) :
      ∀ ⦃i j⦄, i ≠ j → ¬ CommonNeighborRelated G (x i) (x j) := fun i j _ =>
    common_second_neighbors_pairwise_unrelated hbip hfour hsix hvu.symm huv
      (commonNeighborRelated_symm (hx i).1) (commonNeighborRelated_symm (hx i).2)
      (commonNeighborRelated_symm (hx j).1) (commonNeighborRelated_symm (hx j).2)
  have cen {u v : V} {x : Fin 3 → V}
      (hx : ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)) :
      ∀ i j, CommonNeighborRelated G (x i) (![u, v] j) := fun i j => by
    fin_cases j
    exacts [commonNeighborRelated_symm (hx i).1, commonNeighborRelated_symm (hx i).2]
  have inj2 {u v : V} (h : v ≠ u) : Function.Injective ![u, v] := by
    intro i j hij; fin_cases i <;> fin_cases j <;> simp_all [eq_comm]
  calc d * ∑ u ∈ {u | ¬ Good G u}, ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
      #{x : Fin 3 → V | Function.Injective x ∧
        ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)}
      ≤ #(({u | ¬ Good G u} : Finset V).sigma fun u =>
          ({v | v ≠ u ∧ ¬ CommonNeighborRelated G u v} : Finset V).sigma fun v =>
          ({x : Fin 3 → V | Function.Injective x ∧
            ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)} :
              Finset (Fin 3 → V)).sigma fun x => G.neighborFinset (x 0)) := by
        simp only [card_sigma, mul_sum]
        gcongr with u _ v _
        have := card_nsmul_le_sum ({x : Fin 3 → V | Function.Injective x ∧
            ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)})
          (fun x => #(G.neighborFinset (x 0))) d (fun x _ => by simpa using hd (x 0))
        simpa [mul_comm] using this
    _ ≤ #(univ : Finset (V × V × V × Bool)) := by
        refine card_le_card_of_injOn
          (fun p => (p.2.2.1 1, p.2.2.1 2, p.2.2.2,
            decide (Fintype.equivFin V p.1 < Fintype.equivFin V p.2.1))) (by simp) ?_
        rintro ⟨u, v, x, w⟩ hp ⟨u', v', x', w'⟩ hq heq
        simp only [coe_sigma, Set.mem_sigma_iff, mem_coe, mem_filter, mem_univ, true_and,
          mem_neighborFinset] at hp hq
        simp only [Prod.mk.injEq, decide_eq_decide] at heq
        obtain ⟨h1, h2, rfl, hlt⟩ := heq
        have hx0 : x 0 = x' 0 := theta_unique hfree hbip hp.2.2.1.1
          (indep hp.2.1.1 hp.2.1.2 hp.2.2.1.2) hq.2.2.1.1 (indep hq.2.1.1 hq.2.1.2 hq.2.2.1.2)
          (inj2 hp.2.1.1) (inj2 hq.2.1.1) (cen hp.2.2.1.2) (cen hq.2.2.1.2) h1.symm h2.symm
          hp.2.2.2 hq.2.2.2
        obtain rfl : x = x' := funext fun i => by fin_cases i; exacts [hx0, h1, h2]
        have three (t : V) (ht : ∀ i, CommonNeighborRelated G t (x i)) : t = u ∨ t = v := by
          by_contra hne
          push Not at hne
          refine hp.1 ⟨x, ![u, v, t], hp.2.2.1.1, indep hp.2.1.1 hp.2.1.2 hp.2.2.1.2, ?_, rfl,
            fun i j => ?_⟩
          · intro i j hij
            have := hp.2.1.1
            fin_cases i <;> fin_cases j <;> simp_all [eq_comm]
          · fin_cases j
            exacts [commonNeighborRelated_symm (hp.2.2.1.2 i).1,
              commonNeighborRelated_symm (hp.2.2.1.2 i).2, commonNeighborRelated_symm (ht i)]
        have hvu := hp.2.1.1
        have hvu' := hq.2.1.1
        rcases three u' (fun i => (hq.2.2.1.2 i).1) with rfl | rfl <;>
          rcases three v' (fun i => (hq.2.2.1.2 i).2) with rfl | rfl
        · exact absurd rfl hvu'
        · rfl
        · exact ((lt_or_gt_of_ne ((Fintype.equivFin V).injective.ne hvu)).elim (fun h => lt_asymm h (hlt.2 h))
            (fun h => lt_asymm h (hlt.1 h))).elim
        · exact absurd rfl hvu'
    _ = 2 * Fintype.card V ^ 3 := by simp [card_univ]; ring

lemma triple_lower [Fintype V] (s : Finset V) :
    (#s - 2) ^ 3 ≤ #{x : Fin 3 → V | Function.Injective x ∧ ∀ i, x i ∈ s} := by
  calc (#s - 2) ^ 3 ≤ (#s).descFactorial 3 := by
        simpa using Nat.pow_sub_le_descFactorial (#s) 3
    _ = #(univ : Finset (Fin 3 ↪ s)) := by
        rw [card_univ, Fintype.card_embedding_eq]; simp
    _ ≤ _ := card_le_card_of_injOn (fun e i => (e i).1)
        (fun e _ => by
          simp only [coe_filter, mem_univ, true_and, Set.mem_ofPred]
          exact ⟨Subtype.val_injective.comp e.injective, fun i => (e i).2⟩)
        (fun e _ e' _ h => Function.Embedding.ext fun i => Subtype.ext (congrFun h i))

lemma per_vertex [Fintype V] (hbip : G.IsBipartite) (hfour : (cycleGraph 4).Free G)
    (hsix : (cycleGraph 6).Free G) {d : ℕ} (hd : ∀ v, d ≤ G.degree v) (u : V) :
    (G.degree u * (d - 1) ^ 3 - 2 * Fintype.card V) ^ 3 ≤
      Fintype.card V ^ 2 * ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
        #{x : Fin 3 → V | Function.Injective x ∧
          ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)} := by
  have hpaths := card_paths hbip hfour hsix hd u
  set F : Finset V := {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v}
  have hF : #F ≤ Fintype.card V := by simpa using card_le_univ F
  have hsum : ∑ v ∈ F, #{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} ≤
      ∑ v ∈ F, (#{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} - 2) + 2 * Fintype.card V := by
    calc _ ≤ ∑ v ∈ F, ((#{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} - 2) + 2) :=
          sum_le_sum fun v _ => by omega
      _ ≤ _ := by rw [sum_add_distrib, sum_const, smul_eq_mul]; nlinarith
  calc (G.degree u * (d - 1) ^ 3 - 2 * Fintype.card V) ^ 3
      ≤ (∑ v ∈ F, (#{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} - 2)) ^ 3 :=
        Nat.pow_le_pow_left (tsub_le_iff_right.2 (hpaths.trans hsum)) 3
    _ ≤ #F ^ 2 * ∑ v ∈ F, (#{x | CommonNeighborRelated G u x ∧ CommonNeighborRelated G v x} - 2) ^ 3 :=
        pow_sum_le_card_mul_sum_pow (fun _ _ => Nat.zero_le _) 2
    _ ≤ _ := Nat.mul_le_mul (Nat.pow_le_pow_left hF 2) (sum_le_sum fun v _ =>
        (triple_lower _).trans (card_le_card fun x hx => by simpa using hx))

lemma cover [Fintype V] (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (hbip : G.IsBipartite) {d : ℕ}
    (hd : ∀ v, d ≤ G.degree v) : Fintype.card V * d ≤ 2 * ∑ u ∈ {u | ¬ Good G u}, G.degree u := by
  have h2 := sum_card_bipartiteAbove_eq_sum_card_bipartiteBelow (s := univ)
    (t := ({w | ¬ Good G w} : Finset V)) (r := G.Adj)
  simp only [bipartiteAbove, bipartiteBelow] at h2
  have h3 : ∀ w, #{u | G.Adj u w} = G.degree w := fun w => by
    rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter]
    simp [adj_comm]
  calc Fintype.card V * d ≤ ∑ u, G.degree u := by simpa using card_nsmul_le_sum univ _ d fun u _ => hd u
    _ ≤ ∑ u, ((if ¬ Good G u then G.degree u else 0) +
          #(({w | ¬ Good G w} : Finset V).filter (G.Adj u))) := by
        refine sum_le_sum fun u _ => ?_
        split_ifs with hu
        · rw [← card_neighborFinset_eq_degree, neighborFinset_eq_filter, zero_add]
          refine card_le_card fun w hw => ?_
          simp only [mem_filter, mem_univ, true_and] at hw ⊢
          exact ⟨fun hw' => good_adj hfree hbip hu hw' hw, hw⟩
        · omega
    _ = 2 * ∑ u ∈ {u | ¬ Good G u}, G.degree u := by
        rw [sum_add_distrib, h2, ← sum_filter]
        simp only [h3]; ring

theorem core [Fintype V] (hfree : ∀ F ∈ proposedFamily, F.graph.Free G) (hbip : G.IsBipartite) (hn : 0 < Fintype.card V)
    {d : ℕ} (hd : ∀ v, d ≤ G.degree v) : d ^ 16 ≤ 2 ^ 20 * Fintype.card V ^ 5 := by
  have hfour := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inl rfl))))
  have hsix := hfree _ (proposedFamily_mem_iff.mpr (.inl (.inl (.inr rfl))))
  have htc := triple_count hfree hbip hd
  have hcov := cover hfree hbip hd
  have hpv := per_vertex hbip hfour hsix hd
  generalize Fintype.card V = n at *
  have hn5 := Nat.one_le_pow 5 n hn
  by_cases hd1 : d ≤ 1
  · calc d ^ 16 ≤ 1 ^ 16 := Nat.pow_le_pow_left hd1 16
      _ ≤ 2 ^ 20 * n ^ 5 := by nlinarith
  have hdd : d ≤ 2 * (d - 1) := by omega
  have hd3 : d ^ 3 ≤ 2 ^ 3 * (d - 1) ^ 3 := by
    rw [← mul_pow]; exact Nat.pow_le_pow_left hdd 3
  by_cases hlow : d * (d - 1) ^ 3 < 4 * n
  · have h4 : d ^ 4 ≤ 32 * n := by
      calc d ^ 4 = d * d ^ 3 := by ring
        _ ≤ d * (2 ^ 3 * (d - 1) ^ 3) := Nat.mul_le_mul_left d hd3
        _ ≤ 32 * n := by nlinarith
    calc d ^ 16 = (d ^ 4) ^ 4 := by ring
      _ ≤ (32 * n) ^ 4 := Nat.pow_le_pow_left h4 4
      _ = 2 ^ 20 * n ^ 4 := by ring
      _ ≤ 2 ^ 20 * n ^ 5 := Nat.mul_le_mul_left _ (Nat.pow_le_pow_right hn (by norm_num))
  push Not at hlow
  have hu : ∀ u ∈ ({u | ¬ Good G u} : Finset V), G.degree u * (d ^ 2 * (d - 1) ^ 9) ≤
      8 * (n ^ 2 * ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
        #{x : Fin 3 → V | Function.Injective x ∧
          ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)}) := by
    intro u _
    have h := hpv u
    have hP : 4 * n ≤ G.degree u * (d - 1) ^ 3 :=
      hlow.trans (Nat.mul_le_mul_right _ (hd u))
    have h2 : G.degree u * (d - 1) ^ 3 ≤ 2 * (G.degree u * (d - 1) ^ 3 - 2 * n) := by omega
    calc G.degree u * (d ^ 2 * (d - 1) ^ 9) ≤ (G.degree u * (d - 1) ^ 3) ^ 3 := by
          have := Nat.pow_le_pow_left (hd u) 2
          calc _ ≤ G.degree u * (G.degree u ^ 2 * (d - 1) ^ 9) :=
                Nat.mul_le_mul_left _ (Nat.mul_le_mul_right _ this)
            _ = _ := by ring
      _ ≤ (2 * (G.degree u * (d - 1) ^ 3 - 2 * n)) ^ 3 := Nat.pow_le_pow_left h2 3
      _ = 8 * (G.degree u * (d - 1) ^ 3 - 2 * n) ^ 3 := by ring
      _ ≤ _ := Nat.mul_le_mul_left 8 h
  have hsum := sum_le_sum hu
  rw [← sum_mul, ← mul_sum, ← mul_sum] at hsum
  have key : n * (d ^ 4 * (d - 1) ^ 9) ≤ n * (32 * n ^ 4) := by
    calc n * (d ^ 4 * (d - 1) ^ 9) = (n * d) * d * (d ^ 2 * (d - 1) ^ 9) := by ring
      _ ≤ (2 * ∑ u ∈ {u | ¬ Good G u}, G.degree u) * d * (d ^ 2 * (d - 1) ^ 9) := by gcongr
      _ = 2 * d * ((∑ u ∈ {u | ¬ Good G u}, G.degree u) * (d ^ 2 * (d - 1) ^ 9)) := by ring
      _ ≤ 2 * d * (8 * (n ^ 2 * ∑ u ∈ {u | ¬ Good G u},
            ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
              #{x : Fin 3 → V | Function.Injective x ∧
                ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)})) := by
          gcongr
      _ = 16 * n ^ 2 * (d * ∑ u ∈ {u | ¬ Good G u},
            ∑ v ∈ {v | v ≠ u ∧ ¬ CommonNeighborRelated G u v},
              #{x : Fin 3 → V | Function.Injective x ∧
                ∀ i, CommonNeighborRelated G u (x i) ∧ CommonNeighborRelated G v (x i)}) := by ring
      _ ≤ 16 * n ^ 2 * (2 * n ^ 3) := Nat.mul_le_mul_left _ htc
      _ = n * (32 * n ^ 4) := by ring
  have h13 : d ^ 13 ≤ 2 ^ 14 * n ^ 4 := by
    have := Nat.le_of_mul_le_mul_left key hn
    have h9 : d ^ 9 ≤ 2 ^ 9 * (d - 1) ^ 9 := by
      rw [← mul_pow]; exact Nat.pow_le_pow_left hdd 9
    calc d ^ 13 = d ^ 4 * d ^ 9 := by ring
      _ ≤ d ^ 4 * (2 ^ 9 * (d - 1) ^ 9) := Nat.mul_le_mul_left _ h9
      _ ≤ 2 ^ 14 * n ^ 4 := by nlinarith
  have : (d ^ 16) ^ 13 ≤ (2 ^ 18 * n ^ 5) ^ 13 := by
    calc (d ^ 16) ^ 13 = (d ^ 13) ^ 16 := by ring
      _ ≤ (2 ^ 14 * n ^ 4) ^ 16 := Nat.pow_le_pow_left h13 16
      _ = 2 ^ 224 * n ^ 64 := by ring
      _ ≤ 2 ^ 234 * n ^ 65 := Nat.mul_le_mul (Nat.pow_le_pow_right (by norm_num) (by norm_num))
          (Nat.pow_le_pow_right hn (by norm_num))
      _ = (2 ^ 18 * n ^ 5) ^ 13 := by ring
  calc d ^ 16 ≤ 2 ^ 18 * n ^ 5 := (Nat.pow_le_pow_iff_left (by norm_num)).1 this
    _ ≤ 2 ^ 20 * n ^ 5 := Nat.mul_le_mul_right _ (by norm_num)

end UpperCount

end TripleIncidence

end TripleMassIncidence

noncomputable section QuantitativeBadVertexBound

open Finset SimpleGraph

end QuantitativeBadVertexBound

noncomputable section LineCoordinates

variable (K : Type*) [Field K]


section CharacteristicTwo

variable [CharP K 2] [Finite K]

end CharacteristicTwo

end LineCoordinates

noncomputable section ArbitraryLineNormalization

open SimpleGraph

variable (K : Type*) [Field K]


end ArbitraryLineNormalization

noncomputable section JQuotientAvoidanceReduction

open SimpleGraph

end JQuotientAvoidanceReduction

noncomputable section JTemplateLineAvoidanceReduction

open SimpleGraph

variable (K : Type*) [Field K]


end JTemplateLineAvoidanceReduction

noncomputable section CharacteristicTwoLineAvoidance

open SimpleGraph

variable (K : Type*) [Field K] [CharP K 2] [Finite K]

end CharacteristicTwoLineAvoidance

noncomputable section UpperBoundReduction

open Filter Finset SimpleGraph
open scoped Classical Topology

end UpperBoundReduction

noncomputable section AsymptoticExtraction

open Filter Finset SimpleGraph
open scoped Classical Topology

noncomputable def compactnessDegreePowerConstant : ℝ :=
  (48 : ℝ) ^ (4 : ℕ) + 1769472 + 1

noncomputable def compactnessHostPowerConstant : ℝ :=
  (2 : ℝ) ^ (16 : ℕ) * compactnessDegreePowerConstant

set_option maxHeartbeats 800000 in
theorem proposedFamilyFree_sixteenth_power_host_bound
    (n : ℕ) (host : SimpleGraph (Fin n))
    (hfree : FamilyFree proposedFamily host) :
    (host.edgeFinset.card : ℝ) ^ 16 ≤
      compactnessHostPowerConstant * (n : ℝ) ^ 21 := by
  classical
  have exists_bipartite_min_degree_supported_subgraph
      {V : Type _} [Fintype V] [DecidableEq V]
      (G : SimpleGraph V) [DecidableRel G.Adj]
      (hpositive : 0 < G.edgeFinset.card) :
      ∃ H : SimpleGraph V,
        H.IsBipartite ∧ H ≤ G ∧ 0 < Nat.card H.edgeSet ∧
        ∀ v : V, v ∈ H.support →
          G.edgeFinset.card ≤ 2 * Fintype.card V * H.degree v := by
    have exists_bipartite_half_edges
        {V : Type _} [Fintype V] [DecidableEq V]
        (G : SimpleGraph V) [DecidableRel G.Adj] :
        ∃ B : SimpleGraph V,
          B.IsBipartite ∧ B ≤ G ∧
          G.edgeFinset.card ≤ 2 * B.edgeFinset.card := by
      let cut : (V → Bool) → SimpleGraph V := fun c => G ⊓ (⊤ : SimpleGraph Bool).comap c
      have hcard : ∀ c, #(cut c).edgeFinset = #(G.edgeFinset.filter fun x => x ∈ (cut c).edgeSet) := by
        intro c
        congr 1
        ext x
        simp only [mem_edgeFinset, mem_filter]
        exact ⟨fun h => ⟨edgeSet_mono inf_le_left h, h⟩, fun h => h.2⟩
      have hpair : ∀ x ∈ G.edgeFinset,
          #(univ : Finset (V → Bool)) = 2 * #(univ.filter fun c : V → Bool => x ∈ (cut c).edgeSet) := by
        intro x hx
        induction x using Sym2.ind with
        | h u v =>
          have huv : G.Adj u v := by simpa using hx
          have hcross : ∀ c : V → Bool, s(u, v) ∈ (cut c).edgeSet ↔ c u ≠ c v := by
            intro c; simp [cut, huv]
          simp_rw [hcross]
          let φ : (V → Bool) → (V → Bool) := fun c => Function.update c u (!c u)
          have hv : ∀ c, φ c v = c v := fun c => Function.update_of_ne huv.ne.symm _ _
          have hφ : ∀ c, φ (φ c) = c := by intro c; ext w; by_cases hw : w = u <;> simp [φ, hw]
          have hswap : #(univ.filter fun c : V → Bool => c u ≠ c v) =
              #(univ.filter fun c : V → Bool => ¬ c u ≠ c v) := by
            apply Finset.card_bij' (fun c _ => φ c) (fun c _ => φ c) <;> simp [hφ, hv, φ]
            intro a h; revert h; cases a u <;> cases a v <;> simp
          rw [← Finset.card_filter_add_card_filter_not (s := univ) (fun c : V → Bool => c u ≠ c v), hswap]
          ring
      have hsum : ∑ _c : V → Bool, #G.edgeFinset ≤ ∑ c : V → Bool, 2 * #(cut c).edgeFinset := by
        simp_rw [hcard, card_filter, ← Finset.mul_sum]
        rw [Finset.sum_comm, Finset.mul_sum, sum_const, smul_eq_mul, mul_comm, ← smul_eq_mul,
          ← Finset.sum_const]
        refine le_of_eq (Finset.sum_congr rfl fun x hx => ?_)
        rw [hpair x hx, card_filter]
      obtain ⟨c, -, hc⟩ := Finset.exists_le_of_sum_le univ_nonempty hsum
      exact ⟨cut c, by simpa using (Coloring.mk (G := cut c) c fun h => h.2).colorable,
        inf_le_left, by convert hc using 3 <;> first | rfl | (congr 1; exact Subsingleton.elim _ _)⟩
    obtain ⟨cut, hcut, hcutG, hhalf⟩ := exists_bipartite_half_edges G
    simp only [edgeFinset_card_eq_natCard, degree_eq_natCard_neighborSet] at *
    have prune : ∀ (k : ℕ) (H : SimpleGraph V), Nat.card H.edgeSet ≤ k →
        Nat.card G.edgeSet * Nat.card H.support ≤ 2 * Fintype.card V * Nat.card H.edgeSet →
        0 < Nat.card H.edgeSet → ∃ K ≤ H, 0 < Nat.card K.edgeSet ∧
          ∀ v ∈ K.support, Nat.card G.edgeSet ≤ 2 * Fintype.card V * Nat.card (K.neighborSet v) := by
      intro k
      induction k with
      | zero => intro H hk _ hpos; omega
      | succ k ih =>
        intro H hk hinv hpos
        by_cases hall : ∀ v ∈ H.support,
            Nat.card G.edgeSet ≤ 2 * Fintype.card V * Nat.card (H.neighborSet v)
        · exact ⟨H, le_rfl, hpos, hall⟩
        push Not at hall
        obtain ⟨v, hv, hlow⟩ := hall
        have hdrop := card_support_deleteIncidenceSet H hv
        have hdel := card_edgeFinset_deleteIncidenceSet H v
        have hdeg := degree_le_card_edgeFinset H v
        have hdpos := (H.degree_pos_iff_mem_support v).2 hv
        simp only [edgeFinset_card_eq_natCard, degree_eq_natCard_neighborSet,
          ← Nat.card_eq_fintype_card] at hdrop hdel hdeg hdpos
        have hs : 0 < Nat.card H.support := Nat.card_pos_iff.2 ⟨⟨⟨v, hv⟩⟩, inferInstance⟩
        have key : Nat.card G.edgeSet * Nat.card (H.deleteIncidenceSet v).support <
            2 * Fintype.card V * Nat.card (H.deleteIncidenceSet v).edgeSet := by
          nlinarith [Nat.mul_le_mul_left (Nat.card G.edgeSet) hdrop,
            Nat.sub_add_cancel hdeg, Nat.sub_add_cancel hs]
        obtain ⟨K, hK, hKpos, hKdeg⟩ := ih (H.deleteIncidenceSet v) (by omega) key.le
          (Nat.pos_of_ne_zero fun h => by rw [h, mul_zero] at key; omega)
        exact ⟨K, hK.trans (deleteIncidenceSet_le H v), hKpos, hKdeg⟩
    have hsupp : Nat.card cut.support ≤ Fintype.card V := by
      simpa using Finite.card_subtype_le (fun x => x ∈ cut.support)
    obtain ⟨K, hK, hKpos, hKdeg⟩ := prune _ cut le_rfl
      (by nlinarith [Nat.mul_le_mul_left (Nat.card G.edgeSet) hsupp]) (by omega)
    exact ⟨K, hcut.mono_left hK, hK.trans hcutG, hKpos, hKdeg⟩
  by_cases hzero : host.edgeFinset.card = 0
  · simp only [hzero, Nat.cast_zero, zero_pow (by norm_num : 16 ≠ 0)]
    unfold compactnessHostPowerConstant compactnessDegreePowerConstant
    positivity
  obtain ⟨H, hHbip, hHG, hHpos, hmin⟩ :=
    exists_bipartite_min_degree_supported_subgraph host (Nat.pos_of_ne_zero hzero)
  have : Nonempty H.support := by
    obtain ⟨⟨e, he⟩⟩ := Finite.card_pos_iff.mp hHpos
    induction e using Sym2.inductionOn with
    | hf u v => exact ⟨⟨u, (H.mem_edgeSet.1 he).mem_support_left⟩⟩
  have hd := core (G := H.induce H.support)
    (fun F hF h => hfree F hF ((h.trans ⟨(Embedding.induce H.support).toCopy⟩).mono_right hHG))
    (Colorable.of_hom (Embedding.induce H.support).toHom hHbip) Fintype.card_pos
    (minDegree_le_degree _)
  obtain ⟨v, hv⟩ := (H.induce H.support).exists_minimal_degree_vertex
  have hminimum : host.edgeFinset.card ≤ 2 * n * (H.induce H.support).minDegree := by
    have := hmin v v.2
    rw [hv, degree_induce_support]
    simpa using this
  have hNn : Fintype.card H.support ≤ n := by simpa using Fintype.card_subtype_le (· ∈ H.support)
  have hnat : host.edgeFinset.card ^ 16 ≤ 2 ^ 36 * n ^ 21 :=
    calc host.edgeFinset.card ^ 16 ≤ (2 * n * (H.induce H.support).minDegree) ^ 16 :=
          Nat.pow_le_pow_left hminimum 16
      _ = 2 ^ 16 * n ^ 16 * (H.induce H.support).minDegree ^ 16 := by ring
      _ ≤ 2 ^ 16 * n ^ 16 * (2 ^ 20 * n ^ 5) :=
          Nat.mul_le_mul_left _ (hd.trans (Nat.mul_le_mul_left _ (Nat.pow_le_pow_left hNn 5)))
      _ = 2 ^ 36 * n ^ 21 := by ring
  calc (host.edgeFinset.card : ℝ) ^ 16 ≤ 2 ^ 36 * (n : ℝ) ^ 21 := by exact_mod_cast hnat
    _ ≤ compactnessHostPowerConstant * (n : ℝ) ^ 21 := by
      unfold compactnessHostPowerConstant compactnessDegreePowerConstant
      gcongr; norm_num

end AsymptoticExtraction

noncomputable section CycleBounds

open Filter Finset SimpleGraph
open scoped Topology


end CycleBounds

noncomputable section Counterexample

open SimpleGraph

open Filter

/-! The lower bound uses the Wenger graph `D(3, q)` (`2q³` vertices, `q⁴` edges, girth eight):
`q = 2^j` avoids every `J`-quotient and `q = 3^j` every `K`-quotient.  All geometric facts are
polynomial identities in the coordinates of points `(x, y, z)` and lines `(a, b, c)`. -/

abbrev V3 (K : Type*) := K × K × K

/-- Wenger incidence: point `p = (x, y, z)` lies on line `l = (a, b, c)`. -/
def wengerInc {K : Type*} [Field K] (p l : V3 K) : Prop :=
  l.2.1 = p.1 * l.1 - p.2.1 ∧ l.2.2 = p.1 * l.2.1 - p.2.2

theorem wengerInc_triangle {K : Type*} [Field K] {p₁ p₂ p₃ l₁ l₂ l₃ : V3 K}
    (h11 : wengerInc p₁ l₁) (h21 : wengerInc p₂ l₁) (h22 : wengerInc p₂ l₂)
    (h32 : wengerInc p₃ l₂) (h33 : wengerInc p₃ l₃) (h13 : wengerInc p₁ l₃) :
    p₁ = p₂ ∨ p₂ = p₃ ∨ p₃ = p₁ ∨ l₁ = l₂ := by
  obtain ⟨x1, y1, z1⟩ := p₁
  obtain ⟨x2, y2, z2⟩ := p₂
  obtain ⟨x3, y3, z3⟩ := p₃
  obtain ⟨a1, b1, c1⟩ := l₁
  obtain ⟨a2, b2, c2⟩ := l₂
  obtain ⟨a3, b3, c3⟩ := l₃
  simp only [wengerInc] at *
  have key : (x1 - x2) * (x2 - x3) * (a2 - a1) = 0 := by grind
  simp only [Prod.mk.injEq]
  rcases mul_eq_zero.mp key with h | h
  · rcases mul_eq_zero.mp h with h | h
    · left; refine ⟨?_, ?_, ?_⟩ <;> grind
    · right; left; refine ⟨?_, ?_, ?_⟩ <;> grind
  · right; right; right; refine ⟨?_, ?_, ?_⟩ <;> grind

theorem wengerInc_unique {K : Type*} [Field K] {p p' l l' : V3 K}
    (h1 : wengerInc p l) (h2 : wengerInc p l') (h3 : wengerInc p' l) (h4 : wengerInc p' l') :
    p = p' ∨ l = l' := by
  obtain ⟨x1, y1, z1⟩ := p
  obtain ⟨x2, y2, z2⟩ := p'
  obtain ⟨a1, b1, c1⟩ := l
  obtain ⟨a2, b2, c2⟩ := l'
  simp only [wengerInc, Prod.mk.injEq] at *
  have key : (x1 - x2) * (a1 - a2) = 0 := by grind
  rcases mul_eq_zero.mp key with h | h
  · left; refine ⟨?_, ?_, ?_⟩ <;> grind
  · right; refine ⟨?_, ?_, ?_⟩ <;> grind

/-- The quadratic form of the difference of two lines; it vanishes when they meet. -/
def wQ {K : Type*} [Field K] (u v : V3 K) : K :=
  (u.2.1 - v.2.1) ^ 2 - (u.1 - v.1) * (u.2.2 - v.2.2)

/-- The form that vanishes when two points are collinear. -/
def wR {K : Type*} [Field K] (p q : V3 K) : K :=
  p.2.2 - q.2.2 - p.2.1 * q.1 + p.1 * q.2.1

/-- Polar identities: `B, B'` are lines meeting the line `C` at `s, s'`. -/
theorem wengerInc_polar {K : Type*} [Field K] {B B' C s s' : V3 K}
    (h1 : wengerInc s B) (h2 : wengerInc s C) (h3 : wengerInc s' B') (h4 : wengerInc s' C) :
    (C.1 - B.1) * ((B'.1 - B.1) * s.1 ^ 2 - 2 * (B'.2.1 - B.2.1) * s.1 + (B'.2.2 - B.2.2)) =
        -wQ B' B ∧ wQ B' B = (C.1 - B.1) * (C.1 - B'.1) * (s.1 - s'.1) ^ 2 := by
  obtain ⟨x1, y1, z1⟩ := s
  obtain ⟨x2, y2, z2⟩ := s'
  obtain ⟨a1, b1, c1⟩ := B
  obtain ⟨a2, b2, c2⟩ := B'
  obtain ⟨a3, b3, c3⟩ := C
  simp only [wengerInc, wQ] at *
  constructor <;> grind

/-- Two distinct lines through a point differ in their first coordinate. -/
theorem wengerInc_line_fst_ne {K : Type*} [Field K] {p l l' : V3 K}
    (h1 : wengerInc p l) (h2 : wengerInc p l') (h : l ≠ l') : l.1 - l'.1 ≠ 0 := by
  obtain ⟨x1, y1, z1⟩ := p
  obtain ⟨a1, b1, c1⟩ := l
  obtain ⟨a2, b2, c2⟩ := l'
  simp only [wengerInc, Prod.mk.injEq, ne_eq] at *
  intro h0
  exact h ⟨by grind, by grind, by grind⟩

/-- Two distinct points on a line differ in their first coordinate. -/
theorem wengerInc_point_fst_ne {K : Type*} [Field K] {p p' l : V3 K}
    (h1 : wengerInc p l) (h2 : wengerInc p' l) (h : p ≠ p') : p.1 - p'.1 ≠ 0 := by
  obtain ⟨x1, y1, z1⟩ := p
  obtain ⟨x2, y2, z2⟩ := p'
  obtain ⟨a1, b1, c1⟩ := l
  simp only [wengerInc, Prod.mk.injEq, ne_eq] at *
  intro h0
  exact h ⟨by grind, by grind, by grind⟩

theorem odd_quadratic_pencil_eq {K : Type*} [Field K] (htwo : (2 : K) ≠ 0)
    {α₁ β₁ γ₁ α₂ β₂ γ₂ : K} (x σ : Fin 3 → K)
    (hx : ∀ j j', j ≠ j' → x j - x j' ≠ 0) (hσ : ∀ j, σ j ≠ 0)
    (hq₁ : β₁ ^ 2 - α₁ * γ₁ ≠ 0) (hq₂ : β₂ ^ 2 - α₂ * γ₂ ≠ 0)
    (h₁ : ∀ j, σ j * (α₁ * x j ^ 2 - 2 * β₁ * x j + γ₁) = -(β₁ ^ 2 - α₁ * γ₁))
    (h₂ : ∀ j, σ j * (α₂ * x j ^ 2 - 2 * β₂ * x j + γ₂) = -(β₂ ^ 2 - α₂ * γ₂)) :
    α₁ = α₂ ∧ β₁ = β₂ ∧ γ₁ = γ₂ := by
  set q₁ := β₁ ^ 2 - α₁ * γ₁
  set q₂ := β₂ ^ 2 - α₂ * γ₂
  have e (j) : (q₂ * α₁ - q₁ * α₂) * x j ^ 2 - 2 * (q₂ * β₁ - q₁ * β₂) * x j +
      (q₂ * γ₁ - q₁ * γ₂) = 0 :=
    mul_left_cancel₀ (hσ j) (by linear_combination q₂ * h₁ j - q₁ * h₂ j)
  have r₁ : (q₂ * α₁ - q₁ * α₂) * (x 0 + x 1) - 2 * (q₂ * β₁ - q₁ * β₂) = 0 :=
    mul_left_cancel₀ (hx 0 1 (by decide)) (by linear_combination e 0 - e 1)
  have r₂ : (q₂ * α₁ - q₁ * α₂) * (x 0 + x 2) - 2 * (q₂ * β₁ - q₁ * β₂) = 0 :=
    mul_left_cancel₀ (hx 0 2 (by decide)) (by linear_combination e 0 - e 2)
  have nα : q₂ * α₁ - q₁ * α₂ = 0 :=
    mul_left_cancel₀ (hx 1 2 (by decide)) (by linear_combination r₁ - r₂)
  have nβ : q₂ * β₁ - q₁ * β₂ = 0 :=
    mul_left_cancel₀ htwo (by linear_combination (x 0 + x 1) * nα - r₁)
  have nγ : q₂ * γ₁ - q₁ * γ₂ = 0 := by linear_combination e 0 - x 0 ^ 2 * nα + 2 * x 0 * nβ
  have hq : q₁ = q₂ := by
    have : q₁ * q₂ * (q₂ - q₁) = 0 := by
      linear_combination (q₂ * β₁ + q₁ * β₂) * nβ - q₂ * γ₁ * nα - q₁ * α₂ * nγ
    rcases mul_eq_zero.mp this with h | h
    · exact absurd h (mul_ne_zero hq₁ hq₂)
    · exact (sub_eq_zero.mp h).symm
  rw [hq] at nα nβ nγ
  exact ⟨by simpa [sub_eq_zero, mul_right_inj' hq₂] using nα,
    by simpa [sub_eq_zero, mul_right_inj' hq₂] using nβ,
    by simpa [sub_eq_zero, mul_right_inj' hq₂] using nγ⟩

theorem wengerInc_no_line_gamma {K : Type*} [Field K] (htwo : (2 : K) ≠ 0)
    (B C : Fin 3 → V3 K) (s : Fin 3 → Fin 3 → V3 K)
    (hB : ∀ i j, wengerInc (s i j) (B i)) (hC : ∀ i j, wengerInc (s i j) (C j))
    (hs : ∀ i k i' k', (i, k) ≠ (i', k') → s i k ≠ s i' k')
    (hBC : ∀ i j, C j ≠ B i) (hB12 : B 1 ≠ B 2) : False := by
  have hσ (i j) := wengerInc_line_fst_ne (hC i j) (hB i j) (hBC i j)
  have hP (i j) := wengerInc_polar (hB 0 j) (hC 0 j) (hB i j) (hC i j)
  have hq (i) (hi : i ≠ 0) := (hP i 0).2 ▸ mul_ne_zero (mul_ne_zero (hσ 0 0) (hσ i 0))
    (pow_ne_zero 2 (wengerInc_point_fst_ne (hC 0 0) (hC i 0) (hs _ _ _ _ (by simp [Ne.symm hi]))))
  obtain ⟨h1, h2, h3⟩ := odd_quadratic_pencil_eq htwo (fun j => (s 0 j).1)
    (fun j => (C j).1 - (B 0).1)
    (fun j j' h => wengerInc_point_fst_ne (hB 0 j) (hB 0 j') (hs _ _ _ _ (by simp [h]))) (hσ 0)
    (hq 1 (by decide)) (hq 2 (by decide)) (fun j => (hP 1 j).1) (fun j => (hP 2 j).1)
  exact hB12 (Prod.ext (by linear_combination h1) (Prod.ext (by linear_combination h2)
    (by linear_combination h3)))

/-- Line side of one theta copy in characteristic two. -/
theorem wengerInc_char_two_theta {K : Type*} [Field K] (h2 : (2 : K) = 0)
    (b : Fin 3 → V3 K) (C : Fin 2 → V3 K) (s : Fin 3 → Fin 2 → V3 K)
    (hb : ∀ i k, wengerInc (s i k) (b i)) (hc : ∀ i k, wengerInc (s i k) (C k))
    (hs : ∀ i k i' k', (i, k) ≠ (i', k') → s i k ≠ s i' k') (hCb : ∀ i k, C k ≠ b i) :
    wQ (b 2) (b 1) ≠ 0 ∧
    wQ (b 2) (b 1) * ((b 0).1 - (b 1).1) = wQ (b 0) (b 1) * ((b 2).1 - (b 1).1) ∧
    wQ (b 2) (b 1) * ((b 0).2.2 - (b 1).2.2) = wQ (b 0) (b 1) * ((b 2).2.2 - (b 1).2.2) := by
  have hσ (i k) := wengerInc_line_fst_ne (hc i k) (hb i k) (hCb i k)
  have hP (i k) := wengerInc_polar (hb 1 k) (hc 1 k) (hb i k) (hc i k)
  refine ⟨(hP 2 0).2 ▸ mul_ne_zero (mul_ne_zero (hσ 1 0) (hσ 2 0))
    (pow_ne_zero 2 (wengerInc_point_fst_ne (hc 1 0) (hc 2 0) (hs _ _ _ _ (by simp)))), ?_⟩
  set q₀ := wQ (b 0) (b 1)
  set q₂ := wQ (b 2) (b 1)
  have e (k) : (q₂ * ((b 0).1 - (b 1).1) - q₀ * ((b 2).1 - (b 1).1)) * (s 1 k).1 ^ 2 +
      (q₂ * ((b 0).2.2 - (b 1).2.2) - q₀ * ((b 2).2.2 - (b 1).2.2)) = 0 :=
    mul_left_cancel₀ (hσ 1 k) (by
      linear_combination q₂ * (hP 0 k).1 - q₀ * (hP 2 k).1 +
        ((C k).1 - (b 1).1) * (s 1 k).1 *
          (q₂ * ((b 0).2.1 - (b 1).2.1) - q₀ * ((b 2).2.1 - (b 1).2.1)) * h2)
  have hx := wengerInc_point_fst_ne (hb 1 0) (hb 1 1) (hs _ _ _ _ (by simp))
  have nα : q₂ * ((b 0).1 - (b 1).1) - q₀ * ((b 2).1 - (b 1).1) = 0 :=
    (mul_eq_zero.mp (by linear_combination e 0 - e 1 -
      (q₂ * ((b 0).1 - (b 1).1) - q₀ * ((b 2).1 - (b 1).1)) *
        ((s 1 0).1 * (s 1 1).1 - (s 1 1).1 ^ 2) * h2 :
      _ * ((s 1 0).1 - (s 1 1).1) ^ 2 = 0)).resolve_right (pow_ne_zero 2 hx)
  exact ⟨by linear_combination nα, by linear_combination e 0 - (s 1 0).1 ^ 2 * nα⟩

theorem wengerInc_char_two_no_line_j {K : Type*} [Field K] (h2 : (2 : K) = 0)
    (b b' : Fin 3 → V3 K)
    (C C' : Fin 2 → V3 K) (s s' : Fin 3 → Fin 2 → V3 K) (u : V3 K)
    (hb : ∀ i k, wengerInc (s i k) (b i)) (hc : ∀ i k, wengerInc (s i k) (C k))
    (hs : ∀ i k i' k', (i, k) ≠ (i', k') → s i k ≠ s i' k') (hCb : ∀ i k, C k ≠ b i)
    (hb' : ∀ i k, wengerInc (s' i k) (b' i)) (hc' : ∀ i k, wengerInc (s' i k) (C' k))
    (hs' : ∀ i k i' k', (i, k) ≠ (i', k') → s' i k ≠ s' i' k') (hCb' : ∀ i k, C' k ≠ b' i)
    (e1 : b' 1 = b 1) (e2 : b' 2 = b 2)
    (hu0 : wengerInc u (b 0)) (hu1 : wengerInc u (b' 0)) (h01 : b 0 ≠ b' 0) : False := by
  obtain ⟨hqz, hα0, hγ0⟩ := wengerInc_char_two_theta h2 _ C s hb hc hs hCb
  obtain ⟨-, hα1, hγ1⟩ := wengerInc_char_two_theta h2 _ C' s' hb' hc' hs' hCb'
  rw [e1, e2] at hα1 hγ1
  have hu := (wengerInc_polar hu1 hu0 hu0 hu0).2
  simp only [sub_self, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow,
    mul_zero] at hu
  simp only [wQ] at hqz hα0 hγ0 hα1 hγ1 hu
  set q₀ := ((b 0).2.1 - (b 1).2.1) ^ 2 - ((b 0).1 - (b 1).1) * ((b 0).2.2 - (b 1).2.2)
  set q₁ := ((b' 0).2.1 - (b 1).2.1) ^ 2 - ((b' 0).1 - (b 1).1) * ((b' 0).2.2 - (b 1).2.2)
  set q := ((b 2).2.1 - (b 1).2.1) ^ 2 - ((b 2).1 - (b 1).1) * ((b 2).2.2 - (b 1).2.2)
  have key : q ^ 2 * (q₀ - q₁) = 0 := by
    linear_combination q ^ 2 * hu
      + (q ^ 2 * (((b 0).2.1 - (b 1).2.1) * ((b' 0).2.1 - (b 1).2.1) - q₁)
        - q₀ * q₁ * ((b 2).1 - (b 1).1) * ((b 2).2.2 - (b 1).2.2)) * h2
      - q * ((b' 0).2.2 - (b 1).2.2) * hα0 - q₀ * ((b 2).1 - (b 1).1) * hγ1
      - q * ((b 0).2.2 - (b 1).2.2) * hα1 - q₁ * ((b 2).1 - (b 1).1) * hγ0
  have hq : q₀ = q₁ := sub_eq_zero.mp ((mul_eq_zero.mp key).resolve_left (pow_ne_zero 2 hqz))
  have : (b 0).1 - (b' 0).1 = 0 :=
    mul_left_cancel₀ hqz (by linear_combination hα0 - hα1 + ((b 2).1 - (b 1).1) * hq)
  exact wengerInc_line_fst_ne hu0 hu1 h01 this

/-- Points `p, q` on lines `L, L'` through a common point `c`. -/
theorem wengerInc_collinear {K : Type*} [Field K] {p q c L L' : V3 K}
    (h1 : wengerInc p L) (h2 : wengerInc c L) (h3 : wengerInc q L') (h4 : wengerInc c L') :
    wR p q = (L'.1 - L.1) * (c.1 - p.1) * (c.1 - q.1) := by
  obtain ⟨x1, y1, z1⟩ := p
  obtain ⟨x2, y2, z2⟩ := q
  obtain ⟨x3, y3, z3⟩ := c
  obtain ⟨a1, b1, c1⟩ := L
  obtain ⟨a2, b2, c2⟩ := L'
  simp only [wengerInc, wR] at *
  grind

theorem plane_pair_parallel {K : Type*} [Field K] {ex ey ez dx dy dz x₀ y₀ x₁ y₁ X Y : K}
    (he₀ : ez + y₀ * ex - x₀ * ey = 0) (he₁ : ez + y₁ * ex - x₁ * ey = 0)
    (hd₀ : dz + y₀ * dx - x₀ * dy = 0) (hd₁ : dz + y₁ * dx - x₁ * dy = 0)
    (hm : x₀ ≠ x₁ ∨ y₀ ≠ y₁) :
    (dz - dy * X + dx * Y) * ex = (ez - ey * X + ex * Y) * dx ∧
    (dz - dy * X + dx * Y) * ey = (ez - ey * X + ex * Y) * dy ∧
    (dz - dy * X + dx * Y) * ez = (ez - ey * X + ex * Y) * dz := by
  have h1 : ex * dy - ey * dx = 0 := by
    rcases hm with hm | hm
    · exact (mul_eq_zero.mp (by linear_combination dx * he₁ - dx * he₀ - ex * hd₁ + ex * hd₀ :
        (x₁ - x₀) * _ = 0)).resolve_left (sub_ne_zero.mpr (Ne.symm hm))
    · exact (mul_eq_zero.mp (by linear_combination dy * he₁ - dy * he₀ - ey * hd₁ + ey * hd₀ :
        (y₁ - y₀) * _ = 0)).resolve_left (sub_ne_zero.mpr (Ne.symm hm))
  refine ⟨by grind, by grind, by grind⟩

/-- Point side of one theta copy. -/
theorem wengerInc_point_theta {K : Type*} [Field K]
    (b : Fin 3 → V3 K) (C : Fin 2 → V3 K) (s : Fin 3 → Fin 2 → V3 K)
    (hb : ∀ i k, wengerInc (b i) (s i k)) (hc : ∀ i k, wengerInc (C k) (s i k))
    (hs : ∀ i k i' k', (i, k) ≠ (i', k') → s i k ≠ s i' k') (hCb : ∀ i k, C k ≠ b i)
    (hC : C 0 ≠ C 1) :
    wR (b 2) (b 1) ≠ 0 ∧
    wR (b 2) (b 1) * ((b 0).1 - (b 1).1) = wR (b 0) (b 1) * ((b 2).1 - (b 1).1) ∧
    wR (b 2) (b 1) * ((b 0).2.1 - (b 1).2.1) = wR (b 0) (b 1) * ((b 2).2.1 - (b 1).2.1) ∧
    wR (b 2) (b 1) * ((b 0).2.2 - (b 1).2.2) = wR (b 0) (b 1) * ((b 2).2.2 - (b 1).2.2) := by
  have hR (i k) := wengerInc_collinear (hb i k) (hc i k) (hc i k) (hc i k)
  simp only [sub_self, mul_zero, wR] at hR
  refine ⟨by
    rw [wengerInc_collinear (hb 2 0) (hc 2 0) (hb 1 0) (hc 1 0)]
    exact mul_ne_zero (mul_ne_zero
      (wengerInc_line_fst_ne (hc 1 0) (hc 2 0) (hs _ _ _ _ (by simp)))
      (wengerInc_point_fst_ne (hc 2 0) (hb 2 0) (hCb 2 0)))
      (wengerInc_point_fst_ne (hc 1 0) (hb 1 0) (hCb 1 0)), ?_⟩
  have hm : (C 0).1 ≠ (C 1).1 ∨ (C 0).2.1 ≠ (C 1).2.1 := by
    by_contra! h
    exact hC (Prod.ext h.1 (Prod.ext h.2 (by linear_combination -(hR 1 0) + hR 1 1 -
      (b 1).2.1 * h.1 + (b 1).1 * h.2)))
  obtain ⟨h1, h2, h3⟩ := plane_pair_parallel (X := (b 1).1) (Y := (b 1).2.1)
    (ex := (b 0).1 - (b 1).1) (ey := (b 0).2.1 - (b 1).2.1) (ez := (b 0).2.2 - (b 1).2.2)
    (dx := (b 2).1 - (b 1).1) (dy := (b 2).2.1 - (b 1).2.1) (dz := (b 2).2.2 - (b 1).2.2)
    (x₀ := (C 0).1) (y₀ := (C 0).2.1) (x₁ := (C 1).1) (y₁ := (C 1).2.1)
    (by linear_combination hR 0 0 - hR 1 0) (by linear_combination hR 0 1 - hR 1 1)
    (by linear_combination hR 2 0 - hR 1 0) (by linear_combination hR 2 1 - hR 1 1) hm
  simp only [wR]
  exact ⟨by linear_combination h1, by linear_combination h2, by linear_combination h3⟩

theorem wengerInc_no_point_j {K : Type*} [Field K] (b b' : Fin 3 → V3 K)
    (C C' : Fin 2 → V3 K) (s s' : Fin 3 → Fin 2 → V3 K) (u : V3 K)
    (hb : ∀ i k, wengerInc (b i) (s i k)) (hc : ∀ i k, wengerInc (C k) (s i k))
    (hs : ∀ i k i' k', (i, k) ≠ (i', k') → s i k ≠ s i' k')
    (hCb : ∀ i k, C k ≠ b i) (hC : C 0 ≠ C 1)
    (hb' : ∀ i k, wengerInc (b' i) (s' i k)) (hc' : ∀ i k, wengerInc (C' k) (s' i k))
    (hs' : ∀ i k i' k', (i, k) ≠ (i', k') → s' i k ≠ s' i' k')
    (hCb' : ∀ i k, C' k ≠ b' i) (hC' : C' 0 ≠ C' 1) (e1 : b' 1 = b 1) (e2 : b' 2 = b 2)
    (hu0 : wengerInc (b 0) u) (hu1 : wengerInc (b' 0) u) (h01 : b 0 ≠ b' 0) : False := by
  obtain ⟨hd, h0x, h0y, h0z⟩ := wengerInc_point_theta _ C s hb hc hs hCb hC
  obtain ⟨-, h1x, h1y, h1z⟩ := wengerInc_point_theta _ C' s' hb' hc' hs' hCb' hC'
  rw [e1, e2] at h1x h1y h1z
  have hR := wengerInc_collinear hu0 hu1 hu1 hu1
  simp only [sub_self, zero_mul, wR] at hR hd h0x h0y h0z h1x h1y h1z
  set l := (b 2).2.2 - (b 1).2.2 - (b 2).2.1 * (b 1).1 + (b 2).1 * (b 1).2.1
  set l₀ := (b 0).2.2 - (b 1).2.2 - (b 0).2.1 * (b 1).1 + (b 0).1 * (b 1).2.1
  set l₁ := (b' 0).2.2 - (b 1).2.2 - (b' 0).2.1 * (b 1).1 + (b' 0).1 * (b 1).2.1
  have key : l ^ 2 * (l₀ - l₁) = 0 := by
    linear_combination l ^ 2 * hR - l * ((b' 0).2.1 - (b 1).2.1) * h0x
      - l₀ * ((b 2).1 - (b 1).1) * h1y + l * ((b' 0).1 - (b 1).1) * h0y
      + l₀ * ((b 2).2.1 - (b 1).2.1) * h1x
  have hl : l₀ = l₁ := sub_eq_zero.mp ((mul_eq_zero.mp key).resolve_left (pow_ne_zero 2 hd))
  exact h01 (Prod.ext
    (mul_left_cancel₀ hd (by linear_combination h0x - h1x + ((b 2).1 - (b 1).1) * hl))
    (Prod.ext (mul_left_cancel₀ hd (by linear_combination h0y - h1y + ((b 2).2.1 - (b 1).2.1) * hl))
      (mul_left_cancel₀ hd (by linear_combination h0z - h1z + ((b 2).2.2 - (b 1).2.2) * hl))))

/-- The Wenger graph `D(3, K)`: points and lines are triples, joined by `wengerInc`. -/
def wenger (K : Type*) [Field K] : SimpleGraph (V3 K ⊕ V3 K) where
  Adj
    | .inl p, .inr l => wengerInc p l
    | .inr l, .inl p => wengerInc p l
    | _, _ => False
  symm := ⟨by rintro (_ | _) (_ | _) h <;> exact h⟩
  loopless := ⟨by rintro (_ | _) h <;> exact h⟩

theorem wenger_adj_inr {K : Type*} [Field K] {u : V3 K ⊕ V3 K} {l : V3 K}
    (h : (wenger K).Adj u (.inr l)) : ∃ p, u = .inl p ∧ wengerInc p l := by
  rcases u with p | l'
  · exact ⟨p, rfl, h⟩
  · exact h.elim

theorem wenger_adj_inl {K : Type*} [Field K] {u : V3 K ⊕ V3 K} {p : V3 K}
    (h : (wenger K).Adj u (.inl p)) : ∃ l, u = .inr l ∧ wengerInc p l := by
  rcases u with p' | l
  · exact h.elim
  · exact ⟨l, rfl, h⟩

theorem wenger_cycle_four_free (K : Type*) [Field K] : (cycleGraph 4).Free (wenger K) := by
  rintro ⟨g⟩
  have a01 := g.toHom.map_rel (show (cycleGraph 4).Adj 0 1 by decide)
  have a12 := g.toHom.map_rel (show (cycleGraph 4).Adj 1 2 by decide)
  have a23 := g.toHom.map_rel (show (cycleGraph 4).Adj 2 3 by decide)
  have a30 := g.toHom.map_rel (show (cycleGraph 4).Adj 3 0 by decide)
  have n02 : g 0 ≠ g 2 := g.injective.ne (by decide)
  have n13 : g 1 ≠ g 3 := g.injective.ne (by decide)
  simp only [Copy.coe_toHom] at a01 a12 a23 a30
  rcases g 0 with _ | _ <;> rcases g 1 with _ | _ <;> rcases g 2 with _ | _ <;>
    rcases g 3 with _ | _ <;> simp [wenger] at * <;> grind [wengerInc_unique]

theorem wenger_no_hexagon {K : Type*} [Field K] {a b c d e f : V3 K ⊕ V3 K} {p : V3 K}
    (hab : (wenger K).Adj a b) (hbc : (wenger K).Adj b c) (hcd : (wenger K).Adj c d)
    (hde : (wenger K).Adj d e) (hef : (wenger K).Adj e f) (hfa : (wenger K).Adj f a)
    (hac : a ≠ c) (hce : c ≠ e) (hea : e ≠ a) (hbd : b ≠ d) (ha : a = .inl p) : False := by
  subst ha
  obtain ⟨l₁, rfl, h₁⟩ := wenger_adj_inl hab.symm
  obtain ⟨p₂, rfl, h₂⟩ := wenger_adj_inr hbc.symm
  obtain ⟨l₂, rfl, h₃⟩ := wenger_adj_inl hcd.symm
  obtain ⟨p₃, rfl, h₄⟩ := wenger_adj_inr hde.symm
  obtain ⟨l₃, rfl, h₅⟩ := wenger_adj_inl hef.symm
  rcases wengerInc_triangle h₁ h₂ h₃ h₄ h₅ hfa with h | h | h | h <;> simp_all

theorem wenger_cycle_six_free (K : Type*) [Field K] : (cycleGraph 6).Free (wenger K) := by
  rintro ⟨g⟩
  have a (i j : Fin 6) (h : (cycleGraph 6).Adj i j := by decide) := g.toHom.map_rel h
  have n (i j : Fin 6) (h : i ≠ j := by decide) : g i ≠ g j := g.injective.ne h
  simp only [Copy.coe_toHom] at a
  rcases h : g 0 with p | l
  · exact wenger_no_hexagon (a 0 1) (a 1 2) (a 2 3) (a 3 4) (a 4 5) (a 5 0)
      (n 0 2) (n 2 4) (n 4 0) (n 1 3) h
  · obtain ⟨p, hp, -⟩ := wenger_adj_inr (h ▸ a 0 1).symm
    exact wenger_no_hexagon (a 1 2) (a 2 3) (a 3 4) (a 4 5) (a 5 0) (a 0 1)
      (n 1 3) (n 3 5) (n 5 1) (n 2 4) hp

/-- A copy of a subdivided `K_{3,k}` whose subdivision vertex `(i₀, c₀)` is a point:
all branch vertices are lines and all subdivision vertices are points. -/
theorem wenger_subdivision_lines {K : Type*} [Field K] {k : ℕ}
    (g : (SubdivisionGraph k).Copy (wenger K))
    (i₀ : Fin 3) (c₀ : Fin k) {p : V3 K} (hp : g (.inr (i₀, c₀)) = .inl p) :
    ∃ (B : Fin 3 → V3 K) (C : Fin k → V3 K) (s : Fin 3 → Fin k → V3 K),
      (∀ i, g (.inl (.inl i)) = .inr (B i)) ∧ (∀ c, g (.inl (.inr c)) = .inr (C c)) ∧
      (∀ i c, wengerInc (s i c) (B i)) ∧ (∀ i c, wengerInc (s i c) (C c)) ∧
      (∀ i c i' c', (i, c) ≠ (i', c') → s i c ≠ s i' c') ∧ (∀ i c, C c ≠ B i) ∧
      Function.Injective B ∧ Function.Injective C := by
  have hb (i c) : (wenger K).Adj (g (.inl (.inl i))) (g (.inr (i, c))) :=
    g.toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation])
  have hc (i c) : (wenger K).Adj (g (.inl (.inr c))) (g (.inr (i, c))) :=
    g.toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation])
  obtain ⟨B₀, hB₀, -⟩ := wenger_adj_inl (hp ▸ hb i₀ c₀)
  have hC (c) : ∃ l, g (.inl (.inr c)) = .inr l := by
    obtain ⟨q, hq, -⟩ := wenger_adj_inr (hB₀ ▸ (hb i₀ c).symm)
    exact (wenger_adj_inl (hq ▸ hc i₀ c)).imp fun _ h => h.1
  choose C hC using hC
  have hB (i) : ∃ l, g (.inl (.inl i)) = .inr l := by
    obtain ⟨q, hq, -⟩ := wenger_adj_inr (hC c₀ ▸ (hc i c₀).symm)
    exact (wenger_adj_inl (hq ▸ hb i c₀)).imp fun _ h => h.1
  choose B hB using hB
  have hs (i c) : ∃ q, g (.inr (i, c)) = .inl q :=
    (wenger_adj_inr (hB i ▸ (hb i c).symm)).imp fun _ h => h.1
  choose s hs using hs
  have inj {u v} (hu : g u = g v) : u = v := g.injective hu
  refine ⟨B, C, s, hB, hC, fun i c => ?_, fun i c => ?_, fun i c i' c' h e => ?_,
    fun i c e => ?_, fun i i' e => ?_, fun c c' e => ?_⟩
  · have h := hb i c; rw [hB i, hs i c] at h; exact h
  · have h := hc i c; rw [hC c, hs i c] at h; exact h
  · exact h (Sum.inr.inj (inj ((hs i c).trans (e ▸ (hs i' c').symm))))
  · exact Sum.inr_ne_inl (Sum.inl.inj (inj ((hC c).trans (e ▸ (hB i).symm))))
  · exact Sum.inl.inj (Sum.inl.inj (inj ((hB i).trans (e ▸ (hB i').symm))))
  · exact Sum.inr.inj (Sum.inl.inj (inj ((hC c).trans (e ▸ (hC c').symm))))

/-- The same with the roles of points and lines exchanged. -/
theorem wenger_subdivision_points {K : Type*} [Field K] {k : ℕ}
    (g : (SubdivisionGraph k).Copy (wenger K))
    (i₀ : Fin 3) (c₀ : Fin k) {l : V3 K} (hl : g (.inr (i₀, c₀)) = .inr l) :
    ∃ (B : Fin 3 → V3 K) (C : Fin k → V3 K) (s : Fin 3 → Fin k → V3 K),
      (∀ i, g (.inl (.inl i)) = .inl (B i)) ∧ (∀ c, g (.inl (.inr c)) = .inl (C c)) ∧
      (∀ i c, wengerInc (B i) (s i c)) ∧ (∀ i c, wengerInc (C c) (s i c)) ∧
      (∀ i c i' c', (i, c) ≠ (i', c') → s i c ≠ s i' c') ∧ (∀ i c, C c ≠ B i) ∧
      Function.Injective B ∧ Function.Injective C := by
  have hb (i c) : (wenger K).Adj (g (.inl (.inl i))) (g (.inr (i, c))) :=
    g.toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation])
  have hc (i c) : (wenger K).Adj (g (.inl (.inr c))) (g (.inr (i, c))) :=
    g.toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation])
  obtain ⟨B₀, hB₀, -⟩ := wenger_adj_inr (hl ▸ hb i₀ c₀)
  have hC (c) : ∃ q, g (.inl (.inr c)) = .inl q := by
    obtain ⟨m, hm, -⟩ := wenger_adj_inl (hB₀ ▸ (hb i₀ c).symm)
    exact (wenger_adj_inr (hm ▸ hc i₀ c)).imp fun _ h => h.1
  choose C hC using hC
  have hB (i) : ∃ q, g (.inl (.inl i)) = .inl q := by
    obtain ⟨m, hm, -⟩ := wenger_adj_inl (hC c₀ ▸ (hc i c₀).symm)
    exact (wenger_adj_inr (hm ▸ hb i c₀)).imp fun _ h => h.1
  choose B hB using hB
  have hs (i c) : ∃ m, g (.inr (i, c)) = .inr m :=
    (wenger_adj_inl (hB i ▸ (hb i c).symm)).imp fun _ h => h.1
  choose s hs using hs
  have inj {u v} (hu : g u = g v) : u = v := g.injective hu
  refine ⟨B, C, s, hB, hC, fun i c => ?_, fun i c => ?_, fun i c i' c' h e => ?_,
    fun i c e => ?_, fun i i' e => ?_, fun c c' e => ?_⟩
  · have h := hb i c; rw [hB i, hs i c] at h; exact h
  · have h := hc i c; rw [hC c, hs i c] at h; exact h
  · exact h (Sum.inr.inj (inj ((hs i c).trans (e ▸ (hs i' c').symm))))
  · exact Sum.inr_ne_inl (Sum.inl.inj (inj ((hC c).trans (e ▸ (hB i).symm))))
  · exact Sum.inl.inj (Sum.inl.inj (inj ((hB i).trans (e ▸ (hB i').symm))))
  · exact Sum.inr.inj (Sum.inl.inj (inj ((hC c).trans (e ▸ (hC c').symm))))

theorem wenger_no_kTemplate {K : Type*} [Field K] (htwo : (2 : K) ≠ 0)
    (hom : kTemplate →g wenger K)
    (hcopies : ∀ i : Fin 2, Set.InjOn hom {v : KVertex | v.1 = i}) : False := by
  have hjoin := hom.map_rel (show kTemplate.Adj (0, kSpecifiedCenter) (1, kSpecifiedCenter) by
    simp [kTemplate, kTemplateRelation, kSpecifiedCenter])
  obtain ⟨i, L, hL⟩ : ∃ i L, hom (i, kSpecifiedCenter) = .inr L := by
    rcases h : hom (0, kSpecifiedCenter) with p | L
    · obtain ⟨L, hL, -⟩ := wenger_adj_inl (h ▸ hjoin).symm
      exact ⟨1, L, hL⟩
    · exact ⟨0, L, h⟩
  let g : gammaGraph.Copy (wenger K) := ⟨hom.comp (kGammaCopy i).toHom, fun u v h =>
    (kGammaCopy i).injective (hcopies i rfl rfl h)⟩
  obtain ⟨p, hp, -⟩ := wenger_adj_inr (show (wenger K).Adj (g (.inr (0, 0))) (.inr L) by
    rw [← hL]; exact g.toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation,
      kSpecifiedCenter]))
  obtain ⟨B, C, s, -, -, hB, hC, hs, hCB, hBi, -⟩ := wenger_subdivision_lines g 0 0 hp
  exact wengerInc_no_line_gamma htwo B C s hB hC hs hCB (hBi.ne (by decide))

theorem wenger_no_jTemplate {K : Type*} [Field K] (h2 : (2 : K) = 0)
    (hom : jTemplate →g wenger K)
    (hbase : Function.Injective fun i : Fin 4 => hom (.inl (.inl i)))
    (hcopies : ∀ c : Fin 2, Set.InjOn hom {v | InJCopy c v}) : False := by
  let g (c : Fin 2) : thetaGraph.Copy (wenger K) := ⟨hom.comp (jThetaCopy c).toHom, fun u v h =>
    (jThetaCopy c).injective (hcopies c (jThetaVertex_mem c u) (jThetaVertex_mem c v) h)⟩
  have hu (i : Fin 4) (hi : i = 0 ∨ i = 1 := by decide) :
      (wenger K).Adj (hom (.inr (.inr ()))) (hom (.inl (.inl i))) :=
    hom.map_rel (by simpa [jTemplate, jTemplateRelation] using hi)
  have e00 : g 0 (.inl (.inl 0)) = hom (.inl (.inl 0)) := rfl
  have e10 : g 1 (.inl (.inl 0)) = hom (.inl (.inl 1)) := rfl
  have e1 (c) : g c (.inl (.inl 1)) = hom (.inl (.inl 2)) := by fin_cases c <;> rfl
  have e2 (c) : g c (.inl (.inl 2)) = hom (.inl (.inl 3)) := by fin_cases c <;> rfl
  have a (c) : (wenger K).Adj (hom (.inl (.inl 2))) (g c (.inr (1, 0))) :=
    e1 c ▸ (g c).toHom.map_rel (by simp [SubdivisionGraph, subdivisionRelation])
  have h01 : hom (.inl (.inl 0)) ≠ hom (.inl (.inl 1)) := hbase.ne (by decide)
  rcases h : hom (.inl (.inl 2)) with P | L
  · obtain ⟨m₀, hm₀, -⟩ := wenger_adj_inl (h ▸ a 0).symm
    obtain ⟨m₁, hm₁, -⟩ := wenger_adj_inl (h ▸ a 1).symm
    obtain ⟨B, C, s, hB, -, hb, hc, hs, hCb, -, hC⟩ :=
      wenger_subdivision_points (g 0) 1 0 hm₀
    obtain ⟨B', C', s', hB', -, hb', hc', hs', hCb', -, hC'⟩ :=
      wenger_subdivision_points (g 1) 1 0 hm₁
    have hu0 := hu 0
    have hu1 := hu 1
    rw [← e00, hB] at h01 hu0
    rw [← e10, hB'] at h01 hu1
    obtain ⟨m, hm, hu0⟩ := wenger_adj_inl hu0
    rw [hm] at hu1
    exact wengerInc_no_point_j B B' C C' s s' m hb hc hs hCb (hC.ne (by decide)) hb' hc' hs' hCb'
      (hC'.ne (by decide))
      (Sum.inl.inj ((hB' 1).symm.trans ((e1 1).trans ((e1 0).symm.trans (hB 1)))))
      (Sum.inl.inj ((hB' 2).symm.trans ((e2 1).trans ((e2 0).symm.trans (hB 2))))) hu0 hu1
      (fun e => h01 (by rw [e]))
  · obtain ⟨m₀, hm₀, -⟩ := wenger_adj_inr (h ▸ a 0).symm
    obtain ⟨m₁, hm₁, -⟩ := wenger_adj_inr (h ▸ a 1).symm
    obtain ⟨B, C, s, hB, -, hb, hc, hs, hCb, -, -⟩ := wenger_subdivision_lines (g 0) 1 0 hm₀
    obtain ⟨B', C', s', hB', -, hb', hc', hs', hCb', -, -⟩ :=
      wenger_subdivision_lines (g 1) 1 0 hm₁
    have hu0 := hu 0
    have hu1 := hu 1
    rw [← e00, hB] at h01 hu0
    rw [← e10, hB'] at h01 hu1
    obtain ⟨m, hm, hu0⟩ := wenger_adj_inr hu0
    rw [hm] at hu1
    exact wengerInc_char_two_no_line_j h2 B B' C C' s s' m hb hc hs hCb hb' hc' hs' hCb'
      (Sum.inr.inj ((hB' 1).symm.trans ((e1 1).trans ((e1 0).symm.trans (hB 1)))))
      (Sum.inr.inj ((hB' 2).symm.trans ((e2 1).trans ((e2 0).symm.trans (hB 2))))) hu0 hu1
      (fun e => h01 (by rw [e]))

theorem wenger_extremal_lower (K : Type*) [Field K] [Finite K] {U : Type*} (F : SimpleGraph U)
    (hiso : ∀ u, ∃ v, F.Adj u v) (hfree : F.Free (wenger K)) {n : ℕ}
    (hn : 2 * Nat.card K ^ 3 ≤ n) : Nat.card K ^ 4 ≤ extremalNumber n F := by
  classical
  have := Fintype.ofFinite K
  rw [Nat.card_eq_fintype_card] at *
  let e : K × K × K × K → (wenger K).edgeSet := fun ⟨x, y, z, a⟩ =>
    ⟨s(.inl (x, y, z), .inr (a, x * a - y, x * (x * a - y) - z)), by simp [wenger, wengerInc]⟩
  have he : Function.Injective e := by
    rintro ⟨x, y, z, a⟩ ⟨x', y', z', a'⟩ h
    simp only [e] at h
    grind
  calc Fintype.card K ^ 4 ≤ (wenger K).edgeFinset.card := by
        simpa [edgeFinset_card, pow_succ, mul_assoc] using Fintype.card_le_of_injective e he
    _ ≤ extremalNumber (Fintype.card (V3 K ⊕ V3 K)) F := card_edgeFinset_le_extremalNumber hfree
    _ ≤ extremalNumber n F := extremalNumber_monotone_of_no_isolated F hiso
        (by simpa [two_mul, pow_succ, mul_assoc] using hn)

theorem manuscriptLowerConstant_mul_le {q n : ℕ} (h : n ≤ 54 * q ^ 3) :
    manuscriptLowerConstant * extremalScale n ≤ (q : ℝ) ^ 4 := by
  have h' : (n : ℝ) ≤ 54 * (q : ℝ) ^ 3 := by exact_mod_cast h
  unfold manuscriptLowerConstant extremalScale
  calc _ ≤ (2 : ℝ) ^ (-((4 : ℝ) / 3)) * 27 ^ (-((4 : ℝ) / 3)) *
        (54 * (q : ℝ) ^ 3) ^ ((4 : ℝ) / 3) := by gcongr
    _ = (q : ℝ) ^ 4 := by
      rw [Real.mul_rpow (by norm_num) (by positivity), show (54 : ℝ) = 2 * 27 by norm_num,
        Real.mul_rpow (by norm_num) (by norm_num), ← Real.rpow_natCast (q : ℝ) 3,
        ← Real.rpow_mul (by positivity), Real.rpow_neg (by norm_num), Real.rpow_neg (by norm_num)]
      have h2 : (0 : ℝ) < 2 ^ ((4 : ℝ) / 3) := by positivity
      have h27 : (0 : ℝ) < 27 ^ ((4 : ℝ) / 3) := by positivity
      field_simp
      norm_num

theorem eventually_lower_of_wenger_free {F : FiniteGraph} (hiso : ∀ u, ∃ v, F.graph.Adj u v)
    (t : ℕ) [Fact t.Prime] (ht : 2 ≤ t) (ht3 : t ≤ 3)
    (hfree : ∀ j, 0 < j → F.graph.Free (wenger (GaloisField t j))) :
    ∀ᶠ n in atTop, manuscriptLowerConstant * extremalScale n ≤ extremalNumber n F.graph := by
  filter_upwards [eventually_ge_atTop (2 * t ^ 3)] with n hn
  have ht1 : 1 < t ^ 3 := Nat.one_lt_pow (by norm_num) (by omega)
  have hj : 0 < Nat.log (t ^ 3) (n / 2) := Nat.log_pos ht1 (by omega)
  have h1 := Nat.pow_log_le_self (t ^ 3) (show n / 2 ≠ 0 by omega)
  have h2 := Nat.lt_pow_succ_log_self ht1 (n / 2)
  set j := Nat.log (t ^ 3) (n / 2)
  have hq : (t ^ j) ^ 3 = (t ^ 3) ^ j := by ring
  have h27 : t ^ 3 * (t ^ 3) ^ j ≤ 27 * (t ^ 3) ^ j :=
    Nat.mul_le_mul_right _ (by interval_cases t <;> norm_num)
  have hedge := wenger_extremal_lower (GaloisField t j) F.graph hiso (hfree j hj) (n := n)
    (by rw [GaloisField.card t j hj.ne', hq]; omega)
  rw [GaloisField.card t j hj.ne'] at hedge
  have h2' : n / 2 < t ^ 3 * (t ^ 3) ^ j := by rw [← pow_succ']; exact h2
  calc _ ≤ ((t ^ j : ℕ) : ℝ) ^ 4 := manuscriptLowerConstant_mul_le (by rw [hq]; omega)
    _ ≤ _ := by exact_mod_cast hedge

theorem encodeFiniteGraph_no_isolated {α : Type*} [Fintype α] {G : SimpleGraph α}
    (hG : ∀ u, ∃ v, G.Adj u v) : ∀ u, ∃ v, (encodeFiniteGraph G).graph.Adj u v := by
  intro u
  obtain ⟨v, hv⟩ := hG ((Fintype.equivFin α).symm u)
  refine ⟨Fintype.equivFin α v, ?_⟩
  change (G.map (Fintype.equivFin α).toEmbedding).Adj u _
  rw [← (Fintype.equivFin α).apply_symm_apply u]
  exact map_adj_apply.mpr hv

theorem encodeFiniteGraph_free {α : Type*} [Fintype α] {G : SimpleGraph α} {W : Type*}
    {H : SimpleGraph W} (h : G.Free H) : (encodeFiniteGraph G).graph.Free H :=
  (free_congr_left (Iso.map (Fintype.equivFin α) G)).mp h

theorem quotientGraph_no_isolated {V : Type*} {T : SimpleGraph V} {color : V → Bool}
    (hcol : ∀ ⦃u v⦄, T.Adj u v → color u ≠ color v) (hT : ∀ u, ∃ v, T.Adj u v)
    {f : V → V} (hf : ColorRespecting color f) : ∀ u, ∃ v, (quotientGraph T f).Adj u v := by
  rintro ⟨_, u, rfl⟩
  obtain ⟨v, huv⟩ := hT u
  exact ⟨_, (colorRespectingQuotientProjectionHom T color hcol f hf).map_rel huv⟩

theorem jTemplate_no_isolated : ∀ u, ∃ v, jTemplate.Adj u v := by
  rintro ((base | ⟨copy, center⟩) | (⟨copy, ⟨base, center⟩⟩ | ⟨⟩))
  · fin_cases base
    · exact ⟨.inr (.inr ()), by simp [jTemplate, jTemplateRelation]⟩
    · exact ⟨.inr (.inr ()), by simp [jTemplate, jTemplateRelation]⟩
    · exact ⟨.inr (.inl (0, (1, 0))), by simp [jTemplate, jTemplateRelation, jBase]⟩
    · exact ⟨.inr (.inl (0, (2, 0))), by simp [jTemplate, jTemplateRelation, jBase]⟩
  · exact ⟨.inr (.inl (copy, (0, center))), by simp [jTemplate, jTemplateRelation]⟩
  · exact ⟨.inl (.inl (jBase copy base)), by simp [jTemplate, jTemplateRelation]⟩
  · exact ⟨.inl (.inl 0), by simp [jTemplate, jTemplateRelation]⟩

theorem kTemplate_no_isolated : ∀ u, ∃ v, kTemplate.Adj u v := by
  rintro ⟨copy, (base | center) | ⟨base, center⟩⟩
  · exact ⟨(copy, .inr (base, 0)), by simp [kTemplate, kTemplateRelation, subdivisionRelation]⟩
  · exact ⟨(copy, .inr (0, center)), by simp [kTemplate, kTemplateRelation, subdivisionRelation]⟩
  · exact ⟨(copy, .inl (.inl base)), by simp [kTemplate, kTemplateRelation, subdivisionRelation]⟩

theorem proposedFamily_uniformMemberLower :
    UniformMemberLower proposedFamily manuscriptLowerConstant := by
  intro F hF
  rcases proposedFamily_mem_iff.mp hF with ((rfl | rfl) | ⟨f, hf, rfl⟩) | ⟨f, hf, rfl⟩
  · exact eventually_lower_of_wenger_free
      (show ∀ u : Fin 4, ∃ v, (cycleGraph 4).Adj u v by decide) 2 le_rfl (by norm_num)
      fun _ _ => wenger_cycle_four_free _
  · exact eventually_lower_of_wenger_free
      (show ∀ u : Fin 6, ∃ v, (cycleGraph 6).Adj u v by decide) 2 le_rfl (by norm_num)
      fun _ _ => wenger_cycle_six_free _
  · refine eventually_lower_of_wenger_free (encodeFiniteGraph_no_isolated
      (quotientGraph_no_isolated (fun _ _ h => jTemplate_adj_color_ne h)
        jTemplate_no_isolated hf.1))
      2 le_rfl (by norm_num) fun j _ => ?_
    refine encodeFiniteGraph_free ?_
    rintro ⟨copy⟩
    let hom := copy.toHom.comp (colorRespectingQuotientProjectionHom jTemplate jColor
      (fun _ _ h => jTemplate_adj_color_ne h) f hf.1)
    have hq (u v) (h : hom u = hom v) : f u = f v := congrArg Subtype.val (copy.injective h)
    exact wenger_no_jTemplate (by simpa using CharP.cast_eq_zero (GaloisField 2 j) 2) hom
      (fun a b h => hf.2.1 (hq _ _ h)) (fun c u hu v hv h => hf.2.2 c hu hv (hq u v h))
  · refine eventually_lower_of_wenger_free (encodeFiniteGraph_no_isolated
      (quotientGraph_no_isolated (fun _ _ h => kTemplate_adj_color_ne h)
        kTemplate_no_isolated hf.1))
      3 (by norm_num) le_rfl fun j _ => ?_
    refine encodeFiniteGraph_free ?_
    rintro ⟨copy⟩
    let hom := copy.toHom.comp (colorRespectingQuotientProjectionHom kTemplate kColor
      (fun _ _ h => kTemplate_adj_color_ne h) f hf.1)
    have hq (u v) (h : hom u = hom v) : f u = f v := congrArg Subtype.val (copy.injective h)
    have htwo := (CharP.cast_eq_zero_iff (GaloisField 3 j) 3 2).not.mpr (by norm_num)
    exact wenger_no_kTemplate (by exact_mod_cast htwo) hom
      fun i u hu v hv h => hf.2 i hu hv (hq u v h)

end Counterexample

noncomputable section Connectedness

open Finset SimpleGraph

theorem proposedFamily_member_connected
    {forbidden : FiniteGraph}
    (hforbidden : forbidden ∈ proposedFamily) :
    forbidden.graph.Connected :=
  have quotientGraph_connected_of_colorRespecting
      {V : Type _} (graph : SimpleGraph V) (color : V → Bool)
      (hproper : ∀ ⦃u v : V⦄, graph.Adj u v → color u ≠ color v)
      (f : V → V) (hf : ColorRespecting color f)
      (hconnected : graph.Connected) :
      (quotientGraph graph f).Connected := by
    refine SimpleGraph.Connected.map
      (colorRespectingQuotientProjectionHom graph color hproper f hf)
      ?_ hconnected
    rintro ⟨_, ⟨v, rfl⟩⟩
    exact ⟨v, rfl⟩
  have encodeFiniteGraph_connected
      {V : Type _} [Fintype V] (graph : SimpleGraph V)
      (hconnected : graph.Connected) :
      (encodeFiniteGraph graph).graph.Connected := by
    change (graph.map (Fintype.equivFin V).toEmbedding).Connected
    exact (SimpleGraph.Iso.connected_iff
      (SimpleGraph.Iso.map (Fintype.equivFin V) graph)).mp hconnected
  have encodedJQuotient_connected {f : JVertex → JVertex}
      (hf : JAdmissible f) :
      (encodeFiniteGraph (quotientGraph jTemplate f)).graph.Connected :=
    have jTemplate_connected : jTemplate.Connected := by
      apply (SimpleGraph.connected_iff_exists_forall_reachable jTemplate).2
      let root : JVertex := .inl (.inl (2 : Fin 4))
      refine ⟨root, ?_⟩
      have hbasePair (copy : Fin 2) (base : Fin 3) (center : Fin 2) :
          jTemplate.Adj
            (.inl (.inl (jBase copy base)))
            (.inr (.inl (copy, (base, center)))) := by
        simp [jTemplate, SimpleGraph.fromRel_adj, jTemplateRelation]
      have hcenterPair (copy : Fin 2) (base : Fin 3) (center : Fin 2) :
          jTemplate.Adj
            (.inl (.inr (copy, center)))
            (.inr (.inl (copy, (base, center)))) := by
        simp [jTemplate, SimpleGraph.fromRel_adj, jTemplateRelation]
      have hrootCenter (copy : Fin 2) (center : Fin 2) :
          jTemplate.Reachable root (.inl (.inr (copy, center))) := by
        have hfirst : jTemplate.Adj root (.inr (.inl (copy, ((1 : Fin 3), center)))) := by
          simpa [root, jBase] using hbasePair copy 1 center
        exact hfirst.reachable.trans
          (hcenterPair copy 1 center).symm.reachable
      have hrootPair (copy : Fin 2) (base : Fin 3) (center : Fin 2) :
          jTemplate.Reachable root
            (.inr (.inl (copy, (base, center)))) :=
        (hrootCenter copy center).trans (hcenterPair copy base center).reachable
      have hrootBase (copy : Fin 2) (base : Fin 3) :
          jTemplate.Reachable root (.inl (.inl (jBase copy base))) :=
        (hrootPair copy base 0).trans (hbasePair copy base 0).symm.reachable
      intro vertex
      rcases vertex with (base | ⟨copy, center⟩) |
          (⟨copy, ⟨base, center⟩⟩ | lastVertex)
      · fin_cases base
        · simpa [jBase] using hrootBase 0 0
        · simpa [jBase] using hrootBase 1 0
        · simpa [jBase] using hrootBase 0 1
        · simpa [jBase] using hrootBase 0 2
      · exact hrootCenter copy center
      · exact hrootPair copy base center
      · cases lastVertex
        have hjoin : jTemplate.Adj (.inl (.inl (0 : Fin 4))) (.inr (.inr ())) := by
          simp [jTemplate, SimpleGraph.fromRel_adj, jTemplateRelation]
        have hzero : jTemplate.Reachable root (.inl (.inl (0 : Fin 4))) := by
          simpa [jBase] using hrootBase 0 0
        exact hzero.trans hjoin.reachable
    encodeFiniteGraph_connected _
      (quotientGraph_connected_of_colorRespecting jTemplate jColor
        (fun _ _ h => jTemplate_adj_color_ne h) f hf.1 jTemplate_connected)
  have encodedKQuotient_connected {f : KVertex → KVertex}
      (hf : KAdmissible f) :
      (encodeFiniteGraph (quotientGraph kTemplate f)).graph.Connected :=
    have kTemplate_connected : kTemplate.Connected := by
      apply (SimpleGraph.connected_iff_exists_forall_reachable kTemplate).2
      let root : KVertex := ((0 : Fin 2), kSpecifiedCenter)
      refine ⟨root, ?_⟩
      have hbasePair (copy : Fin 2) (base : Fin 3) (center : Fin 3) :
          kTemplate.Adj
            (copy, .inl (.inl base))
            (copy, .inr (base, center)) := by
        simp [kTemplate, SimpleGraph.fromRel_adj, kTemplateRelation,
          subdivisionRelation]
      have hcenterPair (copy : Fin 2) (base : Fin 3) (center : Fin 3) :
          kTemplate.Adj
            (copy, .inl (.inr center))
            (copy, .inr (base, center)) := by
        simp [kTemplate, SimpleGraph.fromRel_adj, kTemplateRelation,
          subdivisionRelation]
      have hbridge : kTemplate.Adj root ((1 : Fin 2), kSpecifiedCenter) := by
        simp [root, kTemplate, SimpleGraph.fromRel_adj, kTemplateRelation,
          kSpecifiedCenter, subdivisionRelation]
      have hhub (copy : Fin 2) : kTemplate.Reachable root (copy, kSpecifiedCenter) := by
        fin_cases copy
        · exact SimpleGraph.Reachable.refl root
        · exact hbridge.reachable
      have hrootBase (copy : Fin 2) (base : Fin 3) :
          kTemplate.Reachable root (copy, .inl (.inl base)) := by
        have hfirst : kTemplate.Reachable root (copy, .inr (base, (0 : Fin 3))) := by
          exact (hhub copy).trans
            (by
              simpa [kSpecifiedCenter] using
                (hcenterPair copy base 0).reachable)
        exact hfirst.trans (hbasePair copy base 0).symm.reachable
      have hrootPair (copy : Fin 2) (base : Fin 3) (center : Fin 3) :
          kTemplate.Reachable root (copy, .inr (base, center)) :=
        (hrootBase copy base).trans (hbasePair copy base center).reachable
      have hrootCenter (copy : Fin 2) (center : Fin 3) :
          kTemplate.Reachable root (copy, .inl (.inr center)) :=
        (hrootPair copy 0 center).trans
          (hcenterPair copy 0 center).symm.reachable
      intro vertex
      rcases vertex with ⟨copy, (base | center) | ⟨base, center⟩⟩
      · exact hrootBase copy base
      · exact hrootCenter copy center
      · exact hrootPair copy base center
    encodeFiniteGraph_connected _
      (quotientGraph_connected_of_colorRespecting kTemplate kColor
        (fun _ _ h => kTemplate_adj_color_ne h) f hf.1 kTemplate_connected)
  have finiteCycle_connected {n : ℕ} (hn : 0 < n) : (finiteCycle n).graph.Connected := by
    change (SimpleGraph.cycleGraph n).Connected
    let : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
    exact ⟨SimpleGraph.cycleGraph_preconnected⟩
  proposedFamily_induction (P := fun graph => graph.graph.Connected)
    (finiteCycle_connected (by norm_num : 0 < (4 : ℕ)))
    (finiteCycle_connected (by norm_num : 0 < (6 : ℕ)))
    (fun _ hf => encodedJQuotient_connected hf)
    (fun _ hf => encodedKQuotient_connected hf)
    forbidden hforbidden

end Connectedness

noncomputable section Bipartiteness

open Finset SimpleGraph

theorem proposedFamily_member_isBipartite
    {forbidden : FiniteGraph}
    (hforbidden : forbidden ∈ proposedFamily) :
    forbidden.graph.IsBipartite :=
  have colorRespectingQuotient_isBipartite
      {V : Type _} (graph : SimpleGraph V) (color : V → Bool)
      (hproper : ∀ ⦃u v : V⦄, graph.Adj u v → color u ≠ color v)
      (f : V → V) (hf : ColorRespecting color f) :
      (quotientGraph graph f).IsBipartite := by
    classical
    let representative : Set.range f → V :=
      fun vertex => Classical.choose vertex.property
    have hrepresentative (vertex : Set.range f) : f (representative vertex) = (vertex : V) :=
      Classical.choose_spec vertex.property
    let quotientColor : Set.range f → Bool :=
      fun vertex => color (representative vertex)
    have hdirected {u v : Set.range f}
        (h : quotientRelation graph f u v) :
        quotientColor u ≠ quotientColor v := by
      rcases h with ⟨x, y, hx, hy, hxy⟩
      change color (representative u) ≠ color (representative v)
      intro heq
      apply hproper hxy
      calc
        color x = color (representative u) :=
          (hf (representative u) x
            ((hrepresentative u).trans hx.symm)).symm
        _ = color (representative v) := heq
        _ = color y :=
          hf (representative v) y
            ((hrepresentative v).trans hy.symm)
    have hcoloring : (quotientGraph graph f).Coloring Bool :=
      SimpleGraph.Coloring.mk quotientColor (by
        intro u v hadj
        change (SimpleGraph.fromRel (quotientRelation graph f)).Adj u v at hadj
        rcases
            (SimpleGraph.fromRel_adj (quotientRelation graph f) u v).mp hadj with
          ⟨_, hforward | hbackward⟩
        · exact hdirected hforward
        · exact Ne.symm (hdirected hbackward))
    simpa using hcoloring.colorable
  have encodeFiniteGraph_isBipartite
      {V : Type _} [Fintype V] (graph : SimpleGraph V)
      (hbipartite : graph.IsBipartite) :
      (encodeFiniteGraph graph).graph.IsBipartite := by
    classical
    exact SimpleGraph.Colorable.map
      (Fintype.equivFin V).toEmbedding hbipartite
  have encodedJQuotient_isBipartite
      {f : JVertex → JVertex} (hf : JAdmissible f) :
      (encodeFiniteGraph (quotientGraph jTemplate f)).graph.IsBipartite :=
    encodeFiniteGraph_isBipartite _
      (colorRespectingQuotient_isBipartite jTemplate jColor
        (fun _ _ h => jTemplate_adj_color_ne h) f hf.1)
  have encodedKQuotient_isBipartite
      {f : KVertex → KVertex} (hf : KAdmissible f) :
      (encodeFiniteGraph (quotientGraph kTemplate f)).graph.IsBipartite :=
    encodeFiniteGraph_isBipartite _
      (colorRespectingQuotient_isBipartite kTemplate kColor
        (fun _ _ h => kTemplate_adj_color_ne h) f hf.1)
  proposedFamily_induction (P := fun graph => graph.graph.IsBipartite)
    (SimpleGraph.cycleGraph.bicoloring_of_even 4 (by decide)).colorable
    (SimpleGraph.cycleGraph.bicoloring_of_even 6 (by decide)).colorable
    (fun _ hf => encodedJQuotient_isBipartite hf)
    (fun _ hf => encodedKQuotient_isBipartite hf)
    forbidden hforbidden

end Bipartiteness

noncomputable section FamilyExtremal

open Finset SimpleGraph

theorem proposedFamily_familyExtremal_sixteenth_power_le (n : ℕ) :
    (familyExtremal proposedFamily n : ℝ) ^ 16 ≤
      compactnessHostPowerConstant * (n : ℝ) ^ 21 := by
  have finiteNatSup_sixteenth_power_le
      {α : Type _} (s : Finset α) (weight : α → ℕ) (bound : ℝ)
      (hbound : 0 ≤ bound)
      (hweight : ∀ a ∈ s, (weight a : ℝ) ^ 16 ≤ bound) :
      ((s.sup weight : ℕ) : ℝ) ^ 16 ≤ bound := by
    classical
    rcases s.eq_empty_or_nonempty with hs | hs
    · subst s
      simpa using hbound
    · obtain ⟨a, ha, hmax⟩ := Finset.exists_mem_eq_sup s hs weight
      simpa [hmax] using hweight a ha
  classical
  have hbound : 0 ≤ compactnessHostPowerConstant * (n : ℝ) ^ 21 := by
    unfold compactnessHostPowerConstant compactnessDegreePowerConstant
    positivity
  unfold familyExtremal
  apply finiteNatSup_sixteenth_power_le
    (Finset.univ.filter (FamilyFree proposedFamily))
    (fun host : SimpleGraph (Fin n) => host.edgeFinset.card)
    (compactnessHostPowerConstant * (n : ℝ) ^ 21) hbound
  intro host hhost
  exact proposedFamilyFree_sixteenth_power_host_bound n host
    (Finset.mem_filter.mp hhost).2

end FamilyExtremal

noncomputable section MainTheorem

open Filter Finset SimpleGraph
open scoped Classical

theorem proposedFamily_not_compact : ¬ IsCompactFamily proposedFamily := by
  rintro ⟨F, hF, C, hC, hev⟩
  have hc := manuscriptLowerConstant_pos
  have hK : 0 < compactnessHostPowerConstant := by
    unfold compactnessHostPowerConstant compactnessDegreePowerConstant
    positivity
  have hgrow : Tendsto (fun n : ℕ => (n : ℝ) ^ ((1 : ℝ) / 3)) atTop atTop :=
    (tendsto_rpow_atTop (by norm_num)).comp tendsto_natCast_atTop_atTop
  obtain ⟨n, hn1, hn2, hn3, hn4⟩ := (hev.and ((proposedFamily_uniformMemberLower F hF).and
    ((hgrow.eventually_gt_atTop
      (C ^ 16 * compactnessHostPowerConstant / manuscriptLowerConstant ^ 16)).and
      (eventually_gt_atTop 0)))).exists
  have hn : (0 : ℝ) < n := by exact_mod_cast hn4
  have hs : extremalScale n ^ 16 = (n : ℝ) ^ 21 * (n : ℝ) ^ ((1 : ℝ) / 3) := by
    rw [extremalScale, ← Real.rpow_natCast, ← Real.rpow_mul hn.le, ← Real.rpow_natCast,
      ← Real.rpow_add hn]
    norm_num
  have h3 := pow_le_pow_left₀ (by unfold extremalScale; positivity) (hn2.trans hn1) 16
  rw [mul_pow, hs, mul_pow] at h3
  have h4 := h3.trans (mul_le_mul_of_nonneg_left
    (proposedFamily_familyExtremal_sixteenth_power_le n) (by positivity))
  rw [div_lt_iff₀ (by positivity)] at hn3
  nlinarith [pow_pos hn 21, pow_pos hc 16]

theorem not_erdos_180 : ¬ CompactnessConjectureStatement := fun h =>
  proposedFamily_not_compact (h _ proposedFamily_nonempty proposedFamily_isCyclic)


theorem quantitativeCompactnessCounterexample :
    ∃ (family : Finset FiniteGraph) (c C : ℝ),
      family.Nonempty ∧
      (∀ forbidden ∈ family,
        forbidden.graph.Connected ∧ forbidden.graph.IsBipartite ∧
          ¬ forbidden.graph.IsAcyclic) ∧
      0 < c ∧
      0 < C ∧
      UniformMemberLower family c ∧
      (∀ (n : ℕ) (host : SimpleGraph (Fin n)),
        FamilyFree family host →
          (host.edgeFinset.card : ℝ) ^ 16 ≤ C * (n : ℝ) ^ 21) ∧
      (∀ n : ℕ,
        (familyExtremal family n : ℝ) ^ 16 ≤ C * (n : ℝ) ^ 21) ∧
      (0 : ℝ) < 1 / 48 ∧
      (21 : ℝ) / 16 = (4 : ℝ) / 3 - 1 / 48 ∧
      ¬ IsCompactFamily family ∧
      ¬ CompactnessConjectureStatement :=
  ⟨proposedFamily, manuscriptLowerConstant, compactnessHostPowerConstant,
    proposedFamily_nonempty,
    fun _ hF => ⟨proposedFamily_member_connected hF,
      proposedFamily_member_isBipartite hF, proposedFamily_isCyclic _ hF⟩,
    manuscriptLowerConstant_pos,
    by unfold compactnessHostPowerConstant compactnessDegreePowerConstant; positivity,
    proposedFamily_uniformMemberLower, proposedFamilyFree_sixteenth_power_host_bound,
    proposedFamily_familyExtremal_sixteenth_power_le, by norm_num, by norm_num,
    proposedFamily_not_compact, not_erdos_180⟩


theorem compactnessCounterexample_bigO :
    ∃ (family : Finset FiniteGraph) (c : ℝ),
      family.Nonempty ∧
      (∀ forbidden ∈ family,
        forbidden.graph.Connected ∧ forbidden.graph.IsBipartite ∧
          ¬ forbidden.graph.IsAcyclic) ∧
      0 < c ∧
      UniformMemberLower family c ∧
      Asymptotics.IsBigO Filter.atTop
        (fun n : ℕ => (familyExtremal family n : ℝ))
        (fun n : ℕ =>
          (n : ℝ) ^ ((4 : ℝ) / 3 - (1 : ℝ) / 48)) ∧
      ¬ IsCompactFamily family ∧
      ¬ CompactnessConjectureStatement := by
  have proposedFamily_familyExtremal_isBigO :
      Asymptotics.IsBigO Filter.atTop
        (fun n : ℕ => (familyExtremal proposedFamily n : ℝ))
        (fun n : ℕ => (n : ℝ) ^ ((21 : ℝ) / 16)) := by
    let C : ℝ := max compactnessHostPowerConstant 1
    have hCone : 1 ≤ C := le_max_right _ _
    have hCnonneg : 0 ≤ C := zero_le_one.trans hCone
    have hconstant : compactnessHostPowerConstant ≤ C ^ (16 : ℕ) :=
      (le_max_left _ _).trans (le_self_pow₀ hCone (by norm_num))
    apply Asymptotics.isBigO_iff.mpr
    refine ⟨C, Filter.Eventually.of_forall fun n => ?_⟩
    have hnnonneg : (0 : ℝ) ≤ (n : ℝ) := Nat.cast_nonneg _
    have hscale : ((n : ℝ) ^ ((21 : ℝ) / 16)) ^ (16 : ℕ) = (n : ℝ) ^ (21 : ℕ) := by
      rw [← Real.rpow_mul_natCast hnnonneg ((21 : ℝ) / 16) 16]
      norm_num
    have hpower :
        (familyExtremal proposedFamily n : ℝ) ^ (16 : ℕ) ≤
          (C * (n : ℝ) ^ ((21 : ℝ) / 16)) ^ (16 : ℕ) := by
      calc
        (familyExtremal proposedFamily n : ℝ) ^ (16 : ℕ) ≤
            compactnessHostPowerConstant * (n : ℝ) ^ (21 : ℕ) :=
          proposedFamily_familyExtremal_sixteenth_power_le n
        _ ≤ C ^ (16 : ℕ) * (n : ℝ) ^ (21 : ℕ) :=
          mul_le_mul_of_nonneg_right hconstant (by positivity)
        _ = (C * (n : ℝ) ^ ((21 : ℝ) / 16)) ^ (16 : ℕ) := by rw [mul_pow, hscale]
    have hbound := le_of_pow_le_pow_left₀
      (by norm_num : (16 : ℕ) ≠ 0)
      (mul_nonneg hCnonneg (Real.rpow_nonneg hnnonneg _)) hpower
    have hextremal_nonneg : (0 : ℝ) ≤ (familyExtremal proposedFamily n : ℝ) :=
      Nat.cast_nonneg _
    simpa only [Real.norm_eq_abs, abs_of_nonneg hextremal_nonneg,
      abs_of_nonneg (Real.rpow_nonneg hnnonneg _)] using hbound
  refine ⟨proposedFamily, manuscriptLowerConstant,
    proposedFamily_nonempty, ?_, manuscriptLowerConstant_pos,
    proposedFamily_uniformMemberLower, ?_, proposedFamily_not_compact,
    not_erdos_180⟩
  · intro forbidden hforbidden
    exact ⟨proposedFamily_member_connected hforbidden,
      proposedFamily_member_isBipartite hforbidden,
      proposedFamily_isCyclic forbidden hforbidden⟩
  · convert proposedFamily_familyExtremal_isBigO using 1
    norm_num

end MainTheorem

end CompactnessConjecture

namespace TwoDegenerateGraphs

open Filter Finset SimpleGraph
open scoped Topology

section BinaryEntropy

noncomputable def logTwo (x : ℝ) : ℝ := Real.log x / Real.log 2

noncomputable def binaryEntropy (x : ℝ) : ℝ :=
  Real.binEntropy x / Real.log 2

noncomputable def tau : ℝ := (Real.sqrt 3 - 1) / 2

noncomputable def kappa : ℝ := 3 / 2 - (3 / 4) * logTwo 3

noncomputable def certifiedWindowWidth : ℝ :=
  logTwo ((97 + 56 * Real.sqrt 3) / 192) / 4

theorem twelve_sevenths_lt_sqrt_three : (12 : ℝ) / 7 < Real.sqrt 3 := by
  have hsqrt_nonneg : 0 ≤ Real.sqrt (3 : ℝ) := Real.sqrt_nonneg 3
  have hsqrt_sq : (Real.sqrt (3 : ℝ)) ^ 2 = 3 := Real.sq_sqrt (by positivity)
  nlinarith

theorem log_two_pos : 0 < Real.log (2 : ℝ) :=
  Real.log_pos (by norm_num)

theorem binaryEntropy_nonneg {x : ℝ} (hzero : 0 ≤ x) (hone : x ≤ 1) : 0 ≤ binaryEntropy x := by
  exact div_nonneg (Real.binEntropy_nonneg hzero hone) log_two_pos.le

theorem binaryEntropy_le_one (x : ℝ) : binaryEntropy x ≤ 1 := by
  unfold binaryEntropy
  apply (div_le_iff₀ log_two_pos).2
  simpa using (Real.binEntropy_le_log_two (p := x))

@[simp] theorem binaryEntropy_zero : binaryEntropy 0 = 0 := by simp [binaryEntropy]


@[fun_prop] theorem binaryEntropy_continuous : Continuous binaryEntropy := by
  exact Real.binEntropy_continuous.div_const _

/-- The pair-type entropy inequality, for pair-type weights `W0, W1, W2` (types `00`, `11`, mixed)
whose one-parent marginal is `q` and whose mixed weight is at least the independent one `2q(1-q)`
(true for sampling without replacement), and child probabilities `z0, z1, z2`.  Proof: a weighted
Gibbs inequality per type with amplitudes `√(1-v)`, `√v` (`v` the child marginal), tangent lines of
`log` in squared form at `8/9` and `2`, an explicit sum-of-squares certificate, and binary Pinsker. -/
theorem pairTypeEntropy_bound {q W0 W1 W2 z0 z1 z2 : ℝ}
    (h0 : 0 ≤ W0) (h1 : 0 ≤ W1) (h2 : 0 ≤ W2)
    (hsum : W0 + W1 + W2 = 1) (hq : W1 + W2 / 2 = q) (hW2 : 2 * q * (1 - q) ≤ W2)
    (hz0 : 0 ≤ z0 ∧ z0 ≤ 1) (hz1 : 0 ≤ z1 ∧ z1 ≤ 1) (hz2 : 0 ≤ z2 ∧ z2 ≤ 1) :
    W0 * binaryEntropy z0 + W1 * binaryEntropy z1 + W2 * binaryEntropy z2 ≤
      kappa + logTwo 3 * (W0 * z0 + W1 * (1 - z1) + W2 / 2) +
        (binaryEntropy (W0 * z0 + W1 * z1 + W2 * z2) - binaryEntropy q) / 2 := by
  -- binary Pinsker: `x ↦ h(x) + 2x²` is concave, compare `q` and `1 - q` with `1/2`
  have pinsker {q : ℝ} (h0 : 0 ≤ q) (h1 : q ≤ 1) :
      Real.binEntropy q ≤ Real.log 2 - (2 * q - 1) ^ 2 / 2 := by
    have hc : ConcaveOn ℝ (Set.Icc 0 1) (fun x => Real.binEntropy x + 2 * x ^ 2) := by
      refine concaveOn_of_hasDerivWithinAt2_nonpos (convex_Icc 0 1)
        (f' := fun x => Real.log (1 - x) - Real.log x + 4 * x)
        (f'' := fun x => -(1 - x)⁻¹ - x⁻¹ + 4) (by fun_prop) ?_ ?_ ?_ <;>
        intro x hx <;> rw [interior_Icc] at hx <;> obtain ⟨hx0, hx1⟩ := hx
      · exact (((Real.hasDerivAt_binEntropy hx0.ne' hx1.ne).add
          ((hasDerivAt_pow 2 x).const_mul 2)).congr_deriv (by simp; ring)).hasDerivWithinAt
      · exact (((((hasDerivAt_id x).const_sub 1).log (by simp; linarith)).sub
          (Real.hasDerivAt_log hx0.ne')).add ((hasDerivAt_id x).const_mul 4)).congr_deriv
          (by simp; ring) |>.hasDerivWithinAt
      · have := sub_pos.2 hx1
        field_simp
        nlinarith [sq_nonneg (2 * x - 1)]
    have := hc.2 ⟨h0, h1⟩ ⟨sub_nonneg.2 h1, by linarith⟩ (by norm_num : (0 : ℝ) ≤ 1 / 2)
      (by norm_num : (0 : ℝ) ≤ 1 / 2) (by norm_num)
    simp only [smul_eq_mul, Real.binEntropy_one_sub] at this
    rw [show 1 / 2 * q + 1 / 2 * (1 - q) = (2 : ℝ)⁻¹ by ring, Real.binEntropy_two_inv] at this
    nlinarith
  -- weighted Gibbs inequality `h(z) + (1-z) log(ca) + z log(db) ≤ log(ca + db)`, also at `a b = 0`
  have gibbs {w z a b c d : ℝ} (hw : 0 ≤ w) (hz0 : 0 ≤ z) (hz1 : z ≤ 1)
      (ha : 0 ≤ a) (hb : 0 ≤ b) (hc : 0 < c) (hd : 0 < d) (hS : 0 < c * a + d * b)
      (hA : a = 0 → w * (1 - z) = 0) (hB : b = 0 → w * z = 0) :
      w * (Real.binEntropy z + (1 - z) * (Real.log a + Real.log c) +
        z * (Real.log b + Real.log d)) ≤ w * Real.log (c * a + d * b) := by
    rcases hw.eq_or_lt with rfl | hw
    · simp
    refine mul_le_mul_of_nonneg_left ?_ hw.le
    have piece : ∀ y e k : ℝ, 0 ≤ y → 0 ≤ e → 0 < k → (e = 0 → w * y = 0) →
        y * (Real.log e + Real.log k) - y * Real.log y - y * Real.log (c * a + d * b) ≤
          k * e / (c * a + d * b) - y := by
      intro y e k hy he hk hye
      rcases hy.eq_or_lt with rfl | hy
      · simp; positivity
      have he : 0 < e := he.lt_of_ne fun h => (mul_pos hw hy).ne' (hye h.symm)
      have := Real.log_le_sub_one_of_pos (show 0 < k * e / (y * (c * a + d * b)) by positivity)
      rw [Real.log_div (by positivity) (by positivity), Real.log_mul hk.ne' he.ne',
        Real.log_mul hy.ne' hS.ne'] at this
      have h2 : y * (k * e / (y * (c * a + d * b))) = k * e / (c * a + d * b) := by
        field_simp
      nlinarith [mul_le_mul_of_nonneg_left this hy.le]
    have h1 := piece z b d hz0 hb hd hB
    have h2 := piece (1 - z) a c (by linarith) ha hc hA
    have : Real.binEntropy z = -(z * Real.log z) - (1 - z) * Real.log (1 - z) := by
      simp [Real.binEntropy, Real.log_inv]; ring
    have : c * a / (c * a + d * b) + d * b / (c * a + d * b) = 1 := by
      rw [← add_div]; exact div_self hS.ne'
    linarith
  have tangent {x s : ℝ} (hx : 0 < x) (hs : 0 < s) :
      Real.log x ≤ (Real.log s + x ^ 2 / s - 1) / 2 := by
    have := Real.log_le_sub_one_of_pos (show 0 < x ^ 2 / s by positivity)
    rw [Real.log_div (by positivity) hs.ne', Real.log_pow] at this
    push_cast at this
    linarith
  obtain ⟨v, hv⟩ : ∃ v, v = W0 * z0 + W1 * z1 + W2 * z2 := ⟨_, rfl⟩
  rw [← hv]
  have hp0 := mul_nonneg h0 hz0.1
  have hp1 := mul_nonneg h1 hz1.1
  have hp2 := mul_nonneg h2 hz2.1
  have hr0 := mul_nonneg h0 (sub_nonneg.2 hz0.2)
  have hr1 := mul_nonneg h1 (sub_nonneg.2 hz1.2)
  have hr2 := mul_nonneg h2 (sub_nonneg.2 hz2.2)
  have hv0 : 0 ≤ v := by linarith
  have hv1 : v ≤ 1 := by linarith
  set a := Real.sqrt (1 - v)
  set b := Real.sqrt v
  have ha2 : a ^ 2 = 1 - v := Real.sq_sqrt (by linarith)
  have hb2 : b ^ 2 = v := Real.sq_sqrt hv0
  have ha : 0 ≤ a := Real.sqrt_nonneg _
  have hb : 0 ≤ b := Real.sqrt_nonneg _
  have hab : a ^ 2 + b ^ 2 = 1 := by linarith
  have hA : a = 0 → W0 * (1 - z0) = 0 ∧ W1 * (1 - z1) = 0 ∧ W2 * (1 - z2) = 0 := by
    intro h; rw [h] at ha2
    refine ⟨?_, ?_, ?_⟩ <;> linarith
  have hB : b = 0 → W0 * z0 = 0 ∧ W1 * z1 = 0 ∧ W2 * z2 = 0 := by
    intro h; rw [h] at hb2
    refine ⟨?_, ?_, ?_⟩ <;> linarith
  have hS : ∀ c d : ℝ, 0 < c → 0 < d → 0 < c * a + d * b := fun c d hc hd => by
    rcases ha.eq_or_lt with h | h
    · rw [← h] at hab ⊢
      have : 0 < b := by nlinarith
      positivity
    · positivity
  have third : (0 : ℝ) < 1 / 3 := by norm_num
  have g0 := gibbs h0 hz0.1 hz0.2 ha hb one_pos third
    (hS _ _ one_pos third) (fun h => (hA h).1) (fun h => (hB h).1)
  have g1 := gibbs h1 hz1.1 hz1.2 ha hb third one_pos
    (hS _ _ third one_pos) (fun h => (hA h).2.1) (fun h => (hB h).2.1)
  have g2 := gibbs h2 hz2.1 hz2.2 ha hb one_pos one_pos
    (hS _ _ one_pos one_pos) (fun h => (hA h).2.2) (fun h => (hB h).2.2)
  have t0 := mul_le_mul_of_nonneg_left
    (tangent (hS _ _ one_pos third) (by norm_num : (0 : ℝ) < 8 / 9)) h0
  have t1 := mul_le_mul_of_nonneg_left
    (tangent (hS _ _ third one_pos) (by norm_num : (0 : ℝ) < 8 / 9)) h1
  have t2 := mul_le_mul_of_nonneg_left (tangent (hS _ _ one_pos one_pos) two_pos) h2
  have hla : Real.log a = Real.log (1 - v) / 2 := Real.log_sqrt (by linarith)
  have hlb : Real.log b = Real.log v / 2 := Real.log_sqrt hv0
  have hhv : Real.binEntropy v = -(v * Real.log v) - (1 - v) * Real.log (1 - v) := by
    simp [Real.binEntropy, Real.log_inv]; ring
  have hl89 : Real.log (8 / 9) = 3 * Real.log 2 - 2 * Real.log 3 := by
    rw [Real.log_div (by norm_num) (by norm_num),
      show (8 : ℝ) = 2 ^ 3 by norm_num, show (9 : ℝ) = 3 ^ 2 by norm_num,
      Real.log_pow, Real.log_pow]; push_cast; ring
  have hl43 : Real.log (4 / 3) = 2 * Real.log 2 - Real.log 3 := by
    rw [Real.log_div (by norm_num) (by norm_num), show (4 : ℝ) = 2 ^ 2 by norm_num,
      Real.log_pow]; push_cast; ring
  have hl43le := Real.log_le_sub_one_of_pos (show (0 : ℝ) < 4 / 3 by norm_num)
  have hl43pos := Real.log_nonneg (show (1 : ℝ) ≤ 4 / 3 by norm_num)
  rw [hl43] at hl43pos hl43le
  have hP := pinsker (show 0 ≤ q by linarith) (show q ≤ 1 by linarith)
  have hW0 : W0 = 1 - q - W2 / 2 := by linarith
  have hW1 : W1 = q - W2 / 2 := by linarith
  subst hW0 hW1
  -- the quadratic form left by the tangent lines, bounded by an explicit sum of squares
  have hquad : 9 / 8 * ((1 - q - W2 / 2) * (1 * a + 1 / 3 * b) ^ 2 +
        (q - W2 / 2) * (1 / 3 * a + 1 * b) ^ 2) + W2 * (1 * a + 1 * b) ^ 2 / 2 ≤
      1 + (2 * q - 1) ^ 2 / 3 := by
    have hsos : (1 + (2 * q - 1) ^ 2 / 3) * (a ^ 2 + b ^ 2) * (a ^ 2 + b ^ 2) -
        (a ^ 2 + b ^ 2) * (9 / 8 * ((1 - q - W2 / 2) * (1 * a + 1 / 3 * b) ^ 2 +
          (q - W2 / 2) * (1 / 3 * a + 1 * b) ^ 2) + W2 * (1 * a + 1 * b) ^ 2 / 2) =
        (4 * (2 * q - 1) * (a ^ 2 + b ^ 2) + 3 * (a ^ 2 - b ^ 2)) ^ 2 / 48 +
          (a - b) ^ 2 / 16 * (4 * (q * (1 - q)) * (a ^ 2 + b ^ 2) + 3 * (a - b) ^ 2) +
          (W2 - 2 * q * (1 - q)) / 8 * (a - b) ^ 2 * (a ^ 2 + b ^ 2) := by ring
    rw [hab] at hsos
    have hq01 := mul_nonneg (show 0 ≤ q by linarith) (show 0 ≤ 1 - q by linarith)
    linarith only [hsos, sq_nonneg (4 * (2 * q - 1) * 1 + 3 * (a ^ 2 - b ^ 2)),
      mul_nonneg (sq_nonneg (a - b)) (sub_nonneg.2 hW2),
      mul_nonneg (sq_nonneg (a - b)) (add_nonneg (mul_nonneg (mul_nonneg zero_le_four hq01)
        zero_le_one) (mul_nonneg zero_le_three (sq_nonneg (a - b))))]
  have hnat : (1 - q - W2 / 2) * Real.binEntropy z0 + (q - W2 / 2) * Real.binEntropy z1 +
      W2 * Real.binEntropy z2 ≤
      3 / 2 * Real.log 2 - 3 / 4 * Real.log 3 +
        Real.log 3 * ((1 - q - W2 / 2) * z0 + (q - W2 / 2) * (1 - z1) + W2 / 2) +
        (Real.binEntropy v - Real.binEntropy q) / 2 := by
    simp only [hla, hlb, Real.log_one, add_zero, one_div, Real.log_inv] at g0 g1 g2
    rw [hl89] at t0 t1
    linarith only [g0, g1, g2, t0, t1, t2, hhv, hP, hquad, congrArg (· * Real.log v) hv,
      congrArg (fun x => (1 - x) * Real.log (1 - v)) hv,
      mul_nonneg (sub_nonneg.2 hW2) hl43pos,
      mul_nonneg (sq_nonneg (2 * q - 1)) (show 0 ≤ 1 / 3 - (2 * Real.log 2 - Real.log 3) by
        linarith)]
  have hL2 := Real.log_pos (show (1 : ℝ) < 2 by norm_num)
  refine (mul_le_mul_iff_of_pos_right hL2).1 (le_of_eq_of_le ?_ (hnat.trans_eq ?_))
  · simp only [binaryEntropy]; field_simp
  · simp only [binaryEntropy, kappa, logTwo]; field_simp

structure BinaryPairKernel where
  parentProbability : ℝ
  parentProbability_nonneg : 0 ≤ parentProbability
  parentProbability_le_one : parentProbability ≤ 1
  childProbability : Bool → Bool → ℝ
  childProbability_nonneg : ∀ left right, 0 ≤ childProbability left right
  childProbability_le_one : ∀ left right, childProbability left right ≤ 1

namespace BinaryPairKernel


def bitDisagreementProbability (parent : Bool) (childProbability : ℝ) : ℝ :=
  if parent then 1 - childProbability else childProbability


end BinaryPairKernel

def empiricalBinaryOutcomeCount
    (parentCount oneCount : ℕ) (outcome : Bool) : ℝ :=
  if outcome then (oneCount : ℝ)
  else (parentCount : ℝ) - (oneCount : ℝ)

noncomputable def withoutReplacementBinaryPairMass
    (parentCount oneCount : ℕ) (left right : Bool) : ℝ :=
  empiricalBinaryOutcomeCount parentCount oneCount left *
      (empiricalBinaryOutcomeCount parentCount oneCount right -
        if left = right then 1 else 0) /
    ((parentCount : ℝ) * ((parentCount : ℝ) - 1))


noncomputable def withoutReplacementBinaryPairExpectation
    (parentCount oneCount : ℕ) (f : Bool → Bool → ℝ) : ℝ :=
  ∑ left : Bool, ∑ right : Bool,
    withoutReplacementBinaryPairMass parentCount oneCount left right *
      f left right


noncomputable def empiricalAverageDisagreement
    (parentCount oneCount : ℕ) (kernel : BinaryPairKernel) : ℝ :=
  withoutReplacementBinaryPairExpectation parentCount oneCount
    (fun left right =>
      (BinaryPairKernel.bitDisagreementProbability left
          (kernel.childProbability left right) +
        BinaryPairKernel.bitDisagreementProbability right
          (kernel.childProbability left right)) / 2)

noncomputable def binomialProbabilityMass
    (trialCount successCount : ℕ) (probability : ℝ) : ℝ :=
  (trialCount.choose successCount : ℝ) *
    probability ^ successCount *
    (1 - probability) ^ (trialCount - successCount)

theorem certifiedWindowWidth_pos : 0 < certifiedWindowWidth := by
  have certificate_ratio_one_lt : (1 : ℝ) < (97 + 56 * Real.sqrt 3) / 192 := by
    have h := twelve_sevenths_lt_sqrt_three
    nlinarith
  unfold certifiedWindowWidth logTwo
  exact div_pos
    (div_pos (Real.log_pos certificate_ratio_one_lt)
      log_two_pos)
    (by norm_num)

theorem tau_pos : 0 < tau := by
  unfold tau
  nlinarith [twelve_sevenths_lt_sqrt_three]

theorem tau_lt_one_half : tau < (1 : ℝ) / 2 := by
  have hsqrt_nonneg : 0 ≤ Real.sqrt (3 : ℝ) := Real.sqrt_nonneg 3
  have hsqrt_sq : (Real.sqrt (3 : ℝ)) ^ 2 = 3 := Real.sq_sqrt (by positivity)
  unfold tau
  nlinarith

noncomputable def entropyLowerEndpoint : ℝ := kappa + tau * logTwo 3

noncomputable def entropyUpperEndpoint : ℝ := 2 * binaryEntropy tau - 1

noncomputable def midpointBeta : ℝ :=
  (entropyLowerEndpoint + entropyUpperEndpoint) / 2

theorem entropyWindow_eq_certifiedWindowWidth :
    entropyUpperEndpoint - entropyLowerEndpoint = certifiedWindowWidth := by
  have sqrt_three_pos : 0 < Real.sqrt (3 : ℝ) := by positivity
  have tau_complement : 1 - tau = Real.sqrt 3 * tau := by
    have hsqrt_sq : (Real.sqrt (3 : ℝ)) ^ 2 = 3 := Real.sq_sqrt (by positivity)
    unfold tau
    nlinarith
  have entropy_tau_identity :
      2 * binaryEntropy tau - tau * logTwo 3 =
        2 * logTwo (1 + 1 / Real.sqrt 3) := by
    have tau_reciprocal_identity : 1 + 1 / Real.sqrt 3 = (1 - tau)⁻¹ := by
      have hsqrt_sq : (Real.sqrt (3 : ℝ)) ^ 2 = 3 := Real.sq_sqrt (by positivity)
      rw [tau_complement]
      field_simp [sqrt_three_pos.ne', tau_pos.ne']
      unfold tau
      nlinarith
    have log_three_eq_twice_log_sqrt_three : Real.log (3 : ℝ) = 2 * Real.log (Real.sqrt 3) := by
      have hsqrt_sq : (Real.sqrt (3 : ℝ)) ^ 2 = 3 := Real.sq_sqrt (by positivity)
      calc
        Real.log (3 : ℝ) = Real.log ((Real.sqrt 3) ^ 2) := by rw [hsqrt_sq]
        _ = 2 * Real.log (Real.sqrt 3) := by
          rw [Real.log_pow]
          ring
    have hlog_complement : Real.log (1 - tau) = Real.log (Real.sqrt 3) + Real.log tau := by
      rw [tau_complement, Real.log_mul sqrt_three_pos.ne' tau_pos.ne']
    unfold binaryEntropy logTwo Real.binEntropy
    rw [Real.log_inv, Real.log_inv, tau_reciprocal_identity, Real.log_inv,
      hlog_complement, log_three_eq_twice_log_sqrt_three]
    ring
  have log_certificate_ratio_identity :
      Real.log ((97 + 56 * Real.sqrt 3) / 192) =
        8 * Real.log (1 + 1 / Real.sqrt 3) +
          3 * Real.log 3 - 10 * Real.log 2 := by
    have certificate_ratio_identity :
        (1 + 1 / Real.sqrt 3) ^ (8 : ℕ) * 27 / 1024 =
          (97 + 56 * Real.sqrt 3) / 192 := by grind
    have hu : 0 < (1 : ℝ) + 1 / Real.sqrt 3 := by positivity
    have hlog27 : Real.log (27 : ℝ) = 3 * Real.log 3 := by
      calc
        Real.log (27 : ℝ) = Real.log ((3 : ℝ) ^ (3 : ℕ)) := by norm_num
        _ = 3 * Real.log 3 := by rw [Real.log_pow]; norm_num
    have hlog1024 : Real.log (1024 : ℝ) = 10 * Real.log 2 := by
      calc
        Real.log (1024 : ℝ) = Real.log ((2 : ℝ) ^ (10 : ℕ)) := by norm_num
        _ = 10 * Real.log 2 := by rw [Real.log_pow]; norm_num
    rw [← certificate_ratio_identity,
      Real.log_div (by positivity) (by norm_num),
      Real.log_mul (by positivity) (by norm_num),
      Real.log_pow, hlog27, hlog1024]
    ring
  have hentropy := entropy_tau_identity
  have hlog := log_certificate_ratio_identity
  unfold logTwo at hentropy
  have hlog_argument : (Real.sqrt 3 + 1) / Real.sqrt 3 = 1 + 1 / Real.sqrt 3 := by
    field_simp [sqrt_three_pos.ne']
  unfold entropyUpperEndpoint entropyLowerEndpoint kappa
    certifiedWindowWidth logTwo
  field_simp [log_two_pos.ne'] at hentropy ⊢
  rw [hlog_argument] at hentropy
  ring_nf at hentropy hlog ⊢
  linarith

theorem entropyWindow_pos : entropyLowerEndpoint < entropyUpperEndpoint := by
  have h := certifiedWindowWidth_pos
  rw [← entropyWindow_eq_certifiedWindowWidth] at h
  linarith

theorem midpointBeta_lt_upper_unconditional : midpointBeta < entropyUpperEndpoint :=
  have midpointBeta_lt_upper
      (hwindow : entropyLowerEndpoint < entropyUpperEndpoint) :
      midpointBeta < entropyUpperEndpoint := by
    unfold midpointBeta
    linarith
  midpointBeta_lt_upper entropyWindow_pos

theorem logTwo_three_pos : 0 < logTwo 3 := by
  unfold logTwo
  exact div_pos (Real.log_pos (by norm_num)) log_two_pos

theorem entropyLowerEndpoint_pos : 0 < entropyLowerEndpoint := by
  have kappa_pos : 0 < kappa := by
    have logTwo_three_lt_two : logTwo 3 < 2 := by
      have hlog : Real.log (3 : ℝ) < Real.log 4 :=
        Real.log_lt_log (by norm_num) (by norm_num)
      have hlog_four : Real.log (4 : ℝ) = 2 * Real.log 2 := by
        calc
          Real.log (4 : ℝ) = Real.log ((2 : ℝ) ^ (2 : ℕ)) := by norm_num
          _ = 2 * Real.log 2 := by rw [Real.log_pow]; norm_num
      unfold logTwo
      apply (div_lt_iff₀ log_two_pos).mpr
      nlinarith [hlog]
    unfold kappa
    nlinarith [logTwo_three_lt_two]
  unfold entropyLowerEndpoint
  positivity [kappa_pos, tau_pos, logTwo_three_pos]

theorem entropyUpperEndpoint_lt_one : entropyUpperEndpoint < 1 := by
  have binaryEntropy_tau_lt_one : binaryEntropy tau < 1 := by
    have htau_ne : tau ≠ (2 : ℝ)⁻¹ := by
      intro heq
      have hlt := tau_lt_one_half
      rw [heq] at hlt
      norm_num at hlt
    unfold binaryEntropy
    apply (div_lt_iff₀ log_two_pos).mpr
    simpa using (Real.binEntropy_lt_log_two.mpr htau_ne)
  unfold entropyUpperEndpoint
  nlinarith [binaryEntropy_tau_lt_one]

theorem midpointBeta_pos : 0 < midpointBeta :=
  have midpointBeta_gt_lower_unconditional : entropyLowerEndpoint < midpointBeta :=
    have midpointBeta_gt_lower
        (hwindow : entropyLowerEndpoint < entropyUpperEndpoint) :
        entropyLowerEndpoint < midpointBeta := by
      unfold midpointBeta
      linarith
    midpointBeta_gt_lower entropyWindow_pos
  entropyLowerEndpoint_pos.trans midpointBeta_gt_lower_unconditional

theorem midpointBeta_lt_one : midpointBeta < 1 :=
  midpointBeta_lt_upper_unconditional.trans entropyUpperEndpoint_lt_one

noncomputable def entropySlack : ℝ := certifiedWindowWidth / 8

noncomputable def exponentGain : ℝ :=
  certifiedWindowWidth / (8 * (1 - midpointBeta))

theorem exponentGain_pos : 0 < exponentGain := by
  unfold exponentGain
  exact div_pos certifiedWindowWidth_pos
    (mul_pos (by norm_num) (sub_pos.mpr midpointBeta_lt_one))

noncomputable def empiricalEntropyError (layerSize : ℕ) : ℝ :=
  (1 + logTwo 3) / (layerSize : ℝ) +
    binaryEntropy (1 / (layerSize : ℝ)) / 2

theorem exists_entropy_exclusion_base :
    ∃ L₀ : ℕ, 4 ≤ L₀ ∧
      ∀ L : ℕ, L₀ ≤ L →
        empiricalEntropyError L < entropySlack ∧
        (L : ℝ) +
            3 * logTwo ((L.choose 2 + 1 : ℕ) : ℝ) -
              entropySlack * (L.choose 2 : ℝ) < -1 := by
  have entropySlack_pos : 0 < entropySlack := by
    unfold entropySlack
    exact div_pos certifiedWindowWidth_pos (by norm_num)
  have logTwo_pairLayer_card_add_one_le (L : ℕ) (hL : 2 ≤ L) :
      logTwo ((L.choose 2 + 1 : ℕ) : ℝ) ≤
        2 * (L : ℝ) / Real.log 2 := by
    let x : ℝ := ((L.choose 2 + 1 : ℕ) : ℝ)
    have hxpos : 0 < x := by grind
    have hLreal : (2 : ℝ) ≤ L := by exact_mod_cast hL
    have hchoose : (L.choose 2 : ℝ) = (L : ℝ) * ((L : ℝ) - 1) / 2 := Nat.cast_choose_two ℝ L
    have hxle : x ≤ (L : ℝ) ^ 2 := by grind
    have hsqrt : Real.sqrt x ≤ (L : ℝ) := by
      have hsq := Real.sq_sqrt hxpos.le
      have hsqrt_nonneg := Real.sqrt_nonneg x
      nlinarith
    have hlog : Real.log x ≤ 2 * Real.sqrt x := by
      have hbound := Real.log_le_rpow_div hxpos.le
        (show (0 : ℝ) < 1 / 2 by norm_num)
      rw [← Real.sqrt_eq_rpow] at hbound
      norm_num at hbound
      linarith
    change Real.log x / Real.log 2 ≤ 2 * (L : ℝ) / Real.log 2
    apply (div_le_div_iff_of_pos_right log_two_pos).mpr
    linarith
  have exists_empiricalEntropyError_base :
      ∃ L₀ : ℕ, 4 ≤ L₀ ∧
        ∀ L : ℕ, L₀ ≤ L → empiricalEntropyError L < entropySlack := by
    have empiricalEntropyError_tendsto_zero :
        Filter.Tendsto empiricalEntropyError Filter.atTop (nhds 0) := by
      have hinv : Filter.Tendsto (fun L : ℕ => 1 / (L : ℝ)) Filter.atTop (nhds 0) :=
        tendsto_one_div_atTop_nhds_zero_nat
      have hfirst :
          Filter.Tendsto
            (fun L : ℕ => (1 + logTwo 3) / (L : ℝ))
            Filter.atTop (nhds 0) := by
        have hconst :
            Filter.Tendsto (fun _ : ℕ => 1 + logTwo 3)
              Filter.atTop (nhds (1 + logTwo 3)) :=
          tendsto_const_nhds
        simpa [div_eq_mul_inv] using hconst.mul hinv
      have hentropy :
          Filter.Tendsto
            (fun L : ℕ => binaryEntropy (1 / (L : ℝ)))
            Filter.atTop (nhds 0) := by
        have hcontinuous := binaryEntropy_continuous.continuousAt.tendsto.comp hinv
        rw [binaryEntropy_zero] at hcontinuous
        refine hcontinuous.congr' ?_
        filter_upwards [] with L
        rfl
      change Filter.Tendsto
        (fun L : ℕ => (1 + logTwo 3) / (L : ℝ) +
          binaryEntropy (1 / (L : ℝ)) / 2)
        Filter.atTop (nhds 0)
      simpa using hfirst.add (hentropy.div_const 2)
    have heventually : ∀ᶠ L : ℕ in Filter.atTop, empiricalEntropyError L < entropySlack :=
      (tendsto_order.1 empiricalEntropyError_tendsto_zero).2
        entropySlack entropySlack_pos
    obtain ⟨L₀, hL₀⟩ := (Filter.eventually_atTop.1 heventually)
    refine ⟨max 4 L₀, le_max_left _ _, ?_⟩
    intro L hL
    exact hL₀ L ((le_max_right 4 L₀).trans hL)
  obtain ⟨Lerror, _, herror⟩ := exists_empiricalEntropyError_base
  let C : ℝ := 1 + 6 / Real.log 2
  obtain ⟨N, hN⟩ :=
    exists_nat_gt (4 * (C + entropySlack + 1) / entropySlack)
  refine ⟨max 4 (max Lerror N), le_max_left _ _, ?_⟩
  intro L hL
  have hrest : max Lerror N ≤ L :=
    (le_max_right 4 (max Lerror N)).trans hL
  have herrorL : Lerror ≤ L := (le_max_left Lerror N).trans hrest
  have hNL : N ≤ L := (le_max_right Lerror N).trans hrest
  refine ⟨herror L herrorL, ?_⟩
  have hLfour : 4 ≤ L :=
    (le_max_left 4 (max Lerror N)).trans hL
  have hLreal : (4 : ℝ) ≤ L := by exact_mod_cast hLfour
  have hLpos : 0 < (L : ℝ) := by linarith
  have hNreal : (N : ℝ) ≤ L := by exact_mod_cast hNL
  have hthreshold : 4 * (C + entropySlack + 1) / entropySlack < (L : ℝ) :=
    hN.trans_le hNreal
  have hbig : 4 * (C + entropySlack + 1) < entropySlack * (L : ℝ) := by
    have h := (div_lt_iff₀ entropySlack_pos).mp hthreshold
    nlinarith
  have hscaled := mul_lt_mul_of_pos_right hbig hLpos
  have hlog := logTwo_pairLayer_card_add_one_le L (by omega)
  have hlinear :
      (L : ℝ) + 3 * logTwo ((L.choose 2 + 1 : ℕ) : ℝ) ≤
        C * (L : ℝ) := by grind
  have hchoose : (L.choose 2 : ℝ) = (L : ℝ) * ((L : ℝ) - 1) / 2 :=
    Nat.cast_choose_two ℝ L
  rw [hchoose]
  nlinarith [mul_pos entropySlack_pos hLpos]

theorem exists_entropy_exclusion_depth :
    ∃ depth : ℕ, 0 < depth ∧
      1 < (depth : ℝ) * (certifiedWindowWidth / 2) := by
  obtain ⟨depth, hdepth⟩ :=
    exists_nat_gt ((2 : ℝ) / certifiedWindowWidth)
  have hwidth := certifiedWindowWidth_pos
  have hdepth_real : 0 < (depth : ℝ) :=
    (div_pos (by norm_num) hwidth).trans hdepth
  have hdepth_nat : 0 < depth := by exact_mod_cast hdepth_real
  refine ⟨depth, hdepth_nat, ?_⟩
  have hproduct := (div_lt_iff₀ hwidth).mp hdepth
  nlinarith

end BinaryEntropy

section ForbiddenGraph

noncomputable def neighborsWithin {V : Type*} (G : SimpleGraph V)
    (s : Finset V) (v : V) : Finset V := by
  classical
  exact s.filter (G.Adj v)

def IsDegenerate {V : Type*} (r : ℕ) (G : SimpleGraph V) : Prop :=
  ∀ s : Finset V, s.Nonempty →
    ∃ v ∈ s, (neighborsWithin G s v).card ≤ r

abbrev IsTwoDegenerate {V : Type*} (G : SimpleGraph V) : Prop :=
  IsDegenerate 2 G

def DegeneracyConjectureStatement : Prop :=
  ∀ (r q : ℕ) (H : SimpleGraph (Fin q)),
    0 < r → H.IsBipartite → IsDegenerate r H →
      Asymptotics.IsBigO Filter.atTop
        (fun n : ℕ => (SimpleGraph.extremalNumber n H : ℝ))
        (fun n : ℕ => (n : ℝ) ^ (((2 : ℕ) : ℝ) - 1 / (r : ℝ)))

structure ParentSystem (V : Type*) where
  level : V → ℕ
  parents : V → Finset V
  parent_level : ∀ ⦃v u : V⦄, u ∈ parents v → level u + 1 = level v
  parent_card : ∀ v : V, (parents v).card ≤ 2

namespace ParentSystem

def graph {V : Type*} (P : ParentSystem V) : SimpleGraph V :=
  SimpleGraph.fromRel (fun v u => u ∈ P.parents v)

theorem graph_adj_iff {V : Type*} (P : ParentSystem V) (v u : V) :
    (P.graph).Adj v u ↔
      v ≠ u ∧ (u ∈ P.parents v ∨ v ∈ P.parents u) := by
  rfl

theorem graph_isBipartite {V : Type*} (P : ParentSystem V) : P.graph.IsBipartite := by
  refine ⟨SimpleGraph.Coloring.mk
    (fun v => (⟨P.level v % 2, by omega⟩ : Fin 2)) ?_⟩
  intro v u hadj
  apply Fin.ne_of_val_ne
  change P.level v % 2 ≠ P.level u % 2
  rcases (P.graph_adj_iff v u).mp hadj with ⟨_, huv | huv⟩
  · have hlevel := P.parent_level huv
    omega
  · have hlevel := P.parent_level huv
    omega

theorem graph_isTwoDegenerate {V : Type*} (P : ParentSystem V) : IsTwoDegenerate P.graph := by
  classical
  intro s hs
  obtain ⟨v, hv, hmax⟩ := Finset.exists_max_image s P.level hs
  refine ⟨v, hv, ?_⟩
  have hsubset : neighborsWithin P.graph s v ⊆ P.parents v := by
    intro u hu
    have hus : u ∈ s ∧ P.graph.Adj v u := by simpa [neighborsWithin] using hu
    rcases (P.graph_adj_iff v u).mp hus.2 with ⟨_, hparent | hchild⟩
    · exact hparent
    · have hlevel := P.parent_level hchild
      have hle := hmax u hus.1
      omega
  exact (Finset.card_le_card hsubset).trans (P.parent_card v)

end ParentSystem

def PairLayer (baseSize : ℕ) : ℕ → Type
  | 0 => Fin baseSize
  | i + 1 => {parents : Finset (PairLayer baseSize i) // parents.card = 2}

noncomputable instance pairLayerFintype (baseSize i : ℕ) :
    Fintype (PairLayer baseSize i) := by
  classical
  induction i with
  | zero =>
      change Fintype (Fin baseSize)
      infer_instance
  | succ i ih =>
      letI := ih
      change Fintype
        {parents : Finset (PairLayer baseSize i) // parents.card = 2}
      infer_instance

theorem pairLayer_card_zero (baseSize : ℕ) : Fintype.card (PairLayer baseSize 0) = baseSize := by
  change Fintype.card (Fin baseSize) = baseSize
  simp

theorem pairLayer_card_succ (baseSize i : ℕ) :
    Fintype.card (PairLayer baseSize (i + 1)) =
      (Fintype.card (PairLayer baseSize i)).choose 2 := by
  classical
  let layerPairs : Finset (Finset (PairLayer baseSize i)) :=
    (Finset.univ : Finset (PairLayer baseSize i)).powersetCard 2
  let equivalence : PairLayer baseSize (i + 1) ≃ layerPairs :=
    { toFun := fun p =>
        ⟨p.val, by
          apply Finset.mem_powersetCard.mpr
          exact ⟨Finset.subset_univ _, p.property⟩⟩
      invFun := fun p => ⟨p.val, (Finset.mem_powersetCard.mp p.property).2⟩
      left_inv := by intro p; rfl
      right_inv := by intro p; rfl }
  calc
    Fintype.card (PairLayer baseSize (i + 1)) = Fintype.card layerPairs :=
      Fintype.card_congr equivalence
    _ = layerPairs.card := Fintype.card_coe layerPairs
    _ = (Fintype.card (PairLayer baseSize i)).choose 2 := by simp [layerPairs]

theorem pairLayer_card_ge_base
    (baseSize i : ℕ) (hbase : 4 ≤ baseSize) :
    baseSize ≤ Fintype.card (PairLayer baseSize i) := by
  have le_choose_two_of_four {size : ℕ} (hsize : 4 ≤ size) : size ≤ size.choose 2 := by
    have hreal : (4 : ℝ) ≤ (size : ℝ) := by exact_mod_cast hsize
    have hchoose : (size.choose 2 : ℝ) = (size : ℝ) * ((size : ℝ) - 1) / 2 :=
      Nat.cast_choose_two ℝ size
    have hbound : (size : ℝ) ≤ (size.choose 2 : ℝ) := by nlinarith
    exact_mod_cast hbound
  induction i with
  | zero =>
      rw [pairLayer_card_zero]
  | succ i ih =>
      rw [pairLayer_card_succ]
      exact ih.trans
        (le_choose_two_of_four (hbase.trans ih))

noncomputable def pairLayerFinEquiv (baseSize layer : ℕ) :
    PairLayer baseSize layer ≃
      Fin (Fintype.card (PairLayer baseSize layer)) :=
  Fintype.equivFin (PairLayer baseSize layer)

noncomputable def pairLayerPairEquiv (baseSize layer : ℕ) :
    PairLayer (Fintype.card (PairLayer baseSize layer)) 1 ≃
      PairLayer baseSize (layer + 1) := by
  classical
  change
    {parents : Finset
      (Fin (Fintype.card (PairLayer baseSize layer))) //
        parents.card = 2} ≃
      {parents : Finset (PairLayer baseSize layer) //
        parents.card = 2}
  exact
    (pairLayerFinEquiv baseSize layer).symm.finsetCongr.subtypeEquiv
      (fun parents => by
        simp [Equiv.finsetCongr_apply])

abbrev PairVertex (baseSize depth : ℕ) :=
  Σ i : Fin (depth + 1), PairLayer baseSize i.val

def pairLayerEmbedding (baseSize depth i : ℕ) (hi : i < depth + 1) :
    PairLayer baseSize i ↪ PairVertex baseSize depth where
  toFun v := ⟨⟨i, hi⟩, v⟩
  inj' := by
    intro v w heq
    cases heq
    rfl

noncomputable def pairParents (baseSize depth : ℕ) :
    PairVertex baseSize depth → Finset (PairVertex baseSize depth)
  | ⟨⟨0, _⟩, _⟩ => ∅
  | ⟨⟨i + 1, hi⟩, v⟩ =>
      v.val.map (pairLayerEmbedding baseSize depth i (by omega))

noncomputable def pairParentSystem (baseSize depth : ℕ) :
    ParentSystem (PairVertex baseSize depth) where
  level v := v.1.val
  parents := pairParents baseSize depth
  parent_level := by
    classical
    rintro ⟨⟨i, hi⟩, v⟩ ⟨⟨j, hj⟩, u⟩ hparent
    cases i with
    | zero =>
        simp [pairParents] at hparent
    | succ i =>
        change {parents : Finset (PairLayer baseSize i) // parents.card = 2} at v
        simp only [pairParents, Finset.mem_map] at hparent
        obtain ⟨w, _, hw⟩ := hparent
        have hlevels := congrArg
          (fun z : PairVertex baseSize depth => z.1.val) hw
        change i = j at hlevels
        change j + 1 = i + 1
        omega
  parent_card := by
    classical
    rintro ⟨⟨i, hi⟩, v⟩
    cases i with
    | zero =>
        simp [pairParents]
    | succ i =>
        change {parents : Finset (PairLayer baseSize i) // parents.card = 2} at v
        simp [pairParents, v.property]

theorem pairGraph_parent_child_adj
    (baseSize depth layer : ℕ)
    (hlayer : layer + 1 < depth + 1)
    (child : PairLayer baseSize (layer + 1))
    (parent : PairLayer baseSize layer)
    (hparent : parent ∈ child.val) :
    (pairParentSystem baseSize depth).graph.Adj
      (pairLayerEmbedding baseSize depth (layer + 1) hlayer child)
      (pairLayerEmbedding baseSize depth layer (by omega) parent) := by
  apply (ParentSystem.graph_adj_iff _ _ _).mpr
  constructor
  · intro hequal
    have hlevels := congrArg
      (fun vertex : PairVertex baseSize depth => vertex.1.val)
      hequal
    change layer + 1 = layer at hlevels
    omega
  · left
    change
      pairLayerEmbedding baseSize depth layer (by omega) parent ∈
        pairParents baseSize depth
          (pairLayerEmbedding baseSize depth (layer + 1)
            hlayer child)
    change
      pairLayerEmbedding baseSize depth layer (by omega) parent ∈
        child.val.map
          (pairLayerEmbedding baseSize depth layer (by omega))
    exact Finset.mem_map.mpr ⟨parent, hparent, rfl⟩

def pairBaseVertex (baseSize depth : ℕ) (a : Fin baseSize) :
    PairVertex baseSize depth :=
  pairLayerEmbedding baseSize depth 0 (by omega) a

noncomputable def pairGraphOverFin (baseSize depth : ℕ) :
    SimpleGraph (Fin (Fintype.card (PairVertex baseSize depth))) :=
  (pairParentSystem baseSize depth).graph.overFin rfl

noncomputable def pairGraphOverFinIso (baseSize depth : ℕ) :
    (pairParentSystem baseSize depth).graph ≃g
      pairGraphOverFin baseSize depth :=
  (pairParentSystem baseSize depth).graph.overFinIso rfl

theorem pairGraphOverFin_connected (baseSize depth : ℕ)
    (hbase : 0 < baseSize) (hdepth : 0 < depth) :
    (pairGraphOverFin baseSize depth).Connected :=
  have pairGraph_connected (baseSize depth : ℕ)
      (hbase : 0 < baseSize) (hdepth : 0 < depth) :
      (pairParentSystem baseSize depth).graph.Connected := by
    have pairLayer_reaches_base (baseSize depth : ℕ) :
        ∀ (i : ℕ) (hi : i < depth + 1) (v : PairLayer baseSize i),
          ∃ a : Fin baseSize,
            (pairParentSystem baseSize depth).graph.Reachable
              (pairLayerEmbedding baseSize depth i hi v)
              (pairBaseVertex baseSize depth a) := by
      intro i
      induction i with
      | zero =>
          intro hi v
          exact ⟨v, SimpleGraph.Reachable.rfl⟩
      | succ i ih =>
          intro hi v
          change {parents : Finset (PairLayer baseSize i) // parents.card = 2} at v
          have hnonempty : v.val.Nonempty := by
            apply Finset.card_pos.mp
            omega
          obtain ⟨parent, hparent⟩ := hnonempty
          let lower := pairLayerEmbedding baseSize depth i (by omega) parent
          let upper := pairLayerEmbedding baseSize depth (i + 1) hi v
          have hedge : (pairParentSystem baseSize depth).graph.Adj upper lower := by
            apply (ParentSystem.graph_adj_iff _ upper lower).mpr
            constructor
            · intro heq
              have hlevels := congrArg
                (fun x : PairVertex baseSize depth => x.1.val) heq
              change i + 1 = i at hlevels
              omega
            · left
              change lower ∈ pairParents baseSize depth upper
              change lower ∈
                v.val.map (pairLayerEmbedding baseSize depth i (by omega))
              exact Finset.mem_map.mpr ⟨parent, hparent, rfl⟩
          obtain ⟨a, ha⟩ := ih (by omega) parent
          refine ⟨a, hedge.reachable.trans ?_⟩
          exact ha
    have pairBaseVertices_reachable (baseSize depth : ℕ)
        (hdepth : 0 < depth) (a b : Fin baseSize) :
        (pairParentSystem baseSize depth).graph.Reachable
          (pairBaseVertex baseSize depth a)
          (pairBaseVertex baseSize depth b) := by
      classical
      let pairDecidableEq : DecidableEq (PairLayer baseSize 0) := Classical.decEq _
      by_cases hab : a = b
      · subst b
        exact SimpleGraph.Reachable.rfl
      · let pair : PairLayer baseSize 1 :=
          ⟨{a, b}, Finset.card_pair hab⟩
        let bridge := pairLayerEmbedding baseSize depth 1 (by omega) pair
        have hadj (x : Fin baseSize) (hx : x = a ∨ x = b) :
            (pairParentSystem baseSize depth).graph.Adj
              bridge (pairBaseVertex baseSize depth x) := by
          apply (ParentSystem.graph_adj_iff _ bridge _).mpr
          constructor
          · intro heq
            have hlevels := congrArg
              (fun z : PairVertex baseSize depth => z.1.val) heq
            change 1 = 0 at hlevels
            omega
          · left
            change pairBaseVertex baseSize depth x ∈
              pairParents baseSize depth bridge
            have hxmem : x ∈ ({a, b} : Finset (PairLayer baseSize 0)) := by
              rcases hx with hxa | hxb
              · rw [hxa]
                exact @Finset.mem_insert_self (PairLayer baseSize 0)
                  pairDecidableEq a ({b} : Finset (PairLayer baseSize 0))
              · rw [hxb]
                exact @Finset.mem_insert_of_mem (PairLayer baseSize 0)
                  pairDecidableEq ({b} : Finset (PairLayer baseSize 0)) b a
                  (Finset.mem_singleton_self b)
            change
              pairLayerEmbedding baseSize depth 0 (by omega) x ∈
                ({a, b} : Finset (PairLayer baseSize 0)).map
                  (pairLayerEmbedding baseSize depth 0 (by omega))
            exact Finset.mem_map.mpr ⟨x, hxmem, rfl⟩
        exact (hadj a (Or.inl rfl)).symm.reachable.trans
          (hadj b (Or.inr rfl)).reachable
    let root : Fin baseSize := ⟨0, hbase⟩
    apply (SimpleGraph.connected_iff_exists_forall_reachable _).mpr
    refine ⟨pairBaseVertex baseSize depth root, ?_⟩
    rintro ⟨⟨i, hi⟩, v⟩
    obtain ⟨a, ha⟩ := pairLayer_reaches_base baseSize depth i hi v
    exact (pairBaseVertices_reachable baseSize depth hdepth root a).trans ha.symm
  (pairGraphOverFinIso baseSize depth).connected_iff.mp
    (pairGraph_connected baseSize depth hbase hdepth)

end ForbiddenGraph

section HammingProfiles

abbrev HammingWord (dimension : ℕ) := Fin dimension → Bool

noncomputable def booleanWordOnes {ι : Type*} [Fintype ι]
    (word : ι → Bool) : Finset ι := by
  classical
  exact Finset.univ.filter (fun index => word index = true)

theorem booleanWordOnes_card_equiv
    {ι κ : Type*} [Fintype ι] [Fintype κ]
    (equivalence : ι ≃ κ)
    (word : κ → Bool) :
    (booleanWordOnes (fun index : ι => word (equivalence index))).card =
      (booleanWordOnes word).card := by
  classical
  apply Finset.card_bij
    (fun index _ => equivalence index)
  · intro index hindex
    have hone := (Finset.mem_filter.mp hindex).2
    unfold booleanWordOnes
    exact Finset.mem_filter.mpr
      ⟨Finset.mem_univ _, hone⟩
  · intro first _ second _ hequal
    exact equivalence.injective hequal
  · intro index hindex
    refine ⟨equivalence.symm index, ?_, equivalence.apply_symm_apply index⟩
    unfold booleanWordOnes
    apply Finset.mem_filter.mpr
    refine ⟨Finset.mem_univ _, ?_⟩
    have hone := (Finset.mem_filter.mp hindex).2
    simpa using hone

noncomputable def booleanWordsOfWeight (ι : Type*) [Fintype ι]
    (weight : ℕ) : Finset (ι → Bool) := by
  classical
  exact Finset.univ.filter
    (fun word => (booleanWordOnes word).card = weight)

noncomputable def booleanWordsOfWeightEquiv
    (ι : Type*) [Fintype ι] (weight : ℕ) :
    ↥(booleanWordsOfWeight ι weight) ≃
      ↥((Finset.univ : Finset ι).powersetCard weight) := by
  classical
  refine
    { toFun := fun word => ⟨booleanWordOnes word.val, ?_⟩
      invFun := fun support =>
        ⟨fun index => decide (index ∈ support.val), ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · apply Finset.mem_powersetCard.mpr
    refine ⟨Finset.subset_univ _, ?_⟩
    have hword :
        word.val ∈
          (Finset.univ.filter
            (fun candidate : ι → Bool =>
              (booleanWordOnes candidate).card = weight)) := by
      simpa only [booleanWordsOfWeight] using word.property
    exact (Finset.mem_filter.mp hword).2
  · have hsupport :=
      (Finset.mem_powersetCard.mp support.property).2
    have hones : booleanWordOnes (fun index : ι => decide (index ∈ support.val)) = support.val := by
      ext index
      simp [booleanWordOnes]
    simp only [booleanWordsOfWeight, Finset.mem_filter,
      Finset.mem_univ, true_and]
    rw [hones]
    exact hsupport
  · intro word
    apply Subtype.ext
    funext index
    cases hbit : word.val index <;>
      simp [booleanWordOnes, hbit]
  · intro support
    apply Subtype.ext
    ext index
    simp [booleanWordOnes]

abbrev ClassificationFiber
    {ι γ : Type*} (classify : ι → γ) (group : γ) :=
  {index : ι // classify index = group}

noncomputable def classificationGroup
    {ι γ : Type*} [Fintype ι] [DecidableEq γ]
    (classify : ι → γ) (group : γ) : Finset ι :=
  Finset.univ.filter (fun index => classify index = group)

noncomputable def classifiedWordOnes
    {ι γ : Type*} [Fintype ι] [DecidableEq γ]
    (classify : ι → γ) (group : γ) (word : ι → Bool) : Finset ι :=
  (classificationGroup classify group).filter
    (fun index => word index = true)

noncomputable def classifiedWordSupportEquiv
    {ι γ : Type*} [Fintype ι] [DecidableEq γ]
    (classify : ι → γ) (group : γ) (word : ι → Bool) :
    ↥(booleanWordOnes
        (fun index : ClassificationFiber classify group => word index.val)) ≃
      ↥(classifiedWordOnes classify group word) := by
  classical
  refine
    { toFun := fun index => ⟨index.val.val, ?_⟩
      invFun := fun index => ⟨⟨index.val, ?_⟩, ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have hbit : word index.val.val = true := by
      have hmembership :
          index.val ∈
            (Finset.univ.filter
              (fun candidate : ClassificationFiber classify group =>
                word candidate.val = true)) := by
        simpa only [booleanWordOnes] using index.property
      exact (Finset.mem_filter.mp hmembership).2
    simp [classifiedWordOnes, classificationGroup,
      index.val.property, hbit]
  · have hmembership :
        index.val ∈
          (classificationGroup classify group).filter
            (fun candidate => word candidate = true) := by
      simpa only [classifiedWordOnes] using index.property
    have hgroup := (Finset.mem_filter.mp hmembership).1
    exact (Finset.mem_filter.mp hgroup).2
  · have hmembership :
        index.val ∈
          (classificationGroup classify group).filter
            (fun candidate => word candidate = true) := by
      simpa only [classifiedWordOnes] using index.property
    have hbit := (Finset.mem_filter.mp hmembership).2
    simp [booleanWordOnes, hbit]
  · intro index
    apply Subtype.ext
    apply Subtype.ext
    rfl
  · intro index
    apply Subtype.ext
    rfl

theorem classifiedWordOnes_card
    {ι γ : Type*} [Fintype ι] [DecidableEq γ]
    (classify : ι → γ) (group : γ) (word : ι → Bool) :
    (classifiedWordOnes classify group word).card =
      (booleanWordOnes
        (fun index : ClassificationFiber classify group => word index.val)).card := by
  calc
    (classifiedWordOnes classify group word).card =
        Fintype.card ↥(classifiedWordOnes classify group word) :=
      (Fintype.card_coe _).symm
    _ = Fintype.card
        ↥(booleanWordOnes
          (fun index : ClassificationFiber classify group => word index.val)) :=
      Fintype.card_congr
        (classifiedWordSupportEquiv classify group word).symm
    _ = (booleanWordOnes
          (fun index : ClassificationFiber classify group => word index.val)).card :=
      Fintype.card_coe _

noncomputable def classifiedBooleanWords
    {ι γ : Type*} [Fintype ι] [Fintype γ] [DecidableEq γ]
    (classify : ι → γ) (counts : γ → ℕ) : Finset (ι → Bool) := by
  classical
  exact Finset.univ.filter
    (fun word => ∀ group,
      (classifiedWordOnes classify group word).card = counts group)

noncomputable def classifiedBooleanWordsEquiv
    {ι γ : Type*} [Fintype ι] [Fintype γ] [DecidableEq γ]
    (classify : ι → γ) (counts : γ → ℕ) :
    ↥(classifiedBooleanWords classify counts) ≃
      (∀ group : γ,
        ↥(booleanWordsOfWeight
          (ClassificationFiber classify group) (counts group))) := by
  classical
  refine
    { toFun := fun word group =>
        ⟨fun index => word.val index.val, ?_⟩
      invFun := fun pieces =>
        ⟨fun index => (pieces (classify index)).val ⟨index, rfl⟩, ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have hmembership :
        word.val ∈
          (Finset.univ.filter
            (fun candidate : ι → Bool =>
              ∀ group,
                (classifiedWordOnes classify group candidate).card =
                  counts group)) := by
      simpa only [classifiedBooleanWords] using word.property
    have hprofile := (Finset.mem_filter.mp hmembership).2 group
    simp only [booleanWordsOfWeight, Finset.mem_filter,
      Finset.mem_univ, true_and]
    exact (classifiedWordOnes_card classify group word.val).symm.trans
      hprofile
  · simp only [classifiedBooleanWords, Finset.mem_filter,
      Finset.mem_univ, true_and]
    intro group
    rw [classifiedWordOnes_card]
    have hrestriction :
        (fun index : ClassificationFiber classify group =>
          (pieces (classify index.val)).val
            ⟨index.val, rfl⟩) =
          (pieces group).val := by
      funext index
      rcases index with ⟨index, hindex⟩
      cases hindex
      rfl
    rw [hrestriction]
    have hmembership := (pieces group).property
    unfold booleanWordsOfWeight at hmembership
    exact (Finset.mem_filter.mp hmembership).2
  · intro word
    apply Subtype.ext
    funext index
    rfl
  · intro pieces
    funext group
    apply Subtype.ext
    funext index
    rcases index with ⟨index, hindex⟩
    cases hindex
    rfl

abbrev PairBitType := Fin 3

abbrev PairTypeCountProfile (parentCount dimension : ℕ) :=
  PairBitType → Fin dimension → Fin (parentCount.choose 2 + 1)

noncomputable def pairCoordinateBitType
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (pair : PairLayer parentCount 1) : PairBitType := by
  classical
  exact
    if ∀ parent ∈ pair.val, parents parent coordinate = false then 0
    else if ∀ parent ∈ pair.val, parents parent coordinate = true then 1
    else 2

noncomputable def pairTypeGroup
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (bitType : PairBitType) : Finset (PairLayer parentCount 1) := by
  classical
  exact Finset.univ.filter
    (fun pair => pairCoordinateBitType parents coordinate pair = bitType)

noncomputable def pairCoordinateClassification
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension) :
    PairLayer parentCount 1 × Fin dimension → PairBitType × Fin dimension :=
  fun index =>
    (pairCoordinateBitType parents index.2 index.1, index.2)

noncomputable def pairCoordinateClassificationFiberEquiv
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (bitType : PairBitType) (coordinate : Fin dimension) :
    ClassificationFiber
        (pairCoordinateClassification parents) (bitType, coordinate) ≃
      ↥(pairTypeGroup parents coordinate bitType) := by
  classical
  refine
    { toFun := fun index => ⟨index.val.1, ?_⟩
      invFun := fun pair => ⟨(pair.val, coordinate), ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have htype := congrArg Prod.fst index.property
    have hcoordinate : index.val.2 = coordinate := by
      simpa [pairCoordinateClassification] using
        congrArg Prod.snd index.property
    simp only [pairTypeGroup, Finset.mem_filter,
      Finset.mem_univ, true_and]
    simpa [pairCoordinateClassification, hcoordinate] using htype
  · have hmembership :
        pair.val ∈
          (Finset.univ.filter
            (fun candidate : PairLayer parentCount 1 =>
              pairCoordinateBitType parents coordinate candidate = bitType)) := by
      simpa only [pairTypeGroup] using pair.property
    have htype := (Finset.mem_filter.mp hmembership).2
    change
      (pairCoordinateBitType parents coordinate pair.val, coordinate) =
        (bitType, coordinate)
    exact Prod.ext htype rfl
  · intro index
    apply Subtype.ext
    apply Prod.ext
    · rfl
    · have hcoordinate := congrArg Prod.snd index.property
      simpa [pairCoordinateClassification] using hcoordinate.symm
  · intro pair
    apply Subtype.ext
    rfl

theorem pairTypeGroup_card_le
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (bitType : PairBitType) :
    (pairTypeGroup parents coordinate bitType).card ≤
      parentCount.choose 2 := by
  classical
  calc
    (pairTypeGroup parents coordinate bitType).card ≤
      (Finset.univ : Finset (PairLayer parentCount 1)).card := by
        unfold pairTypeGroup
        exact Finset.card_filter_le _ _
    _ = parentCount.choose 2 := by
      rw [Finset.card_univ, pairLayer_card_succ parentCount 0,
        pairLayer_card_zero]

noncomputable def pairTypeGroupChildOnes
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (bitType : PairBitType) : Finset (PairLayer parentCount 1) := by
  classical
  exact (pairTypeGroup parents coordinate bitType).filter
    (fun pair => children pair coordinate = true)

theorem pairTypeGroupChildOnes_card_le
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (bitType : PairBitType) :
    (pairTypeGroupChildOnes parents children coordinate bitType).card ≤
      (pairTypeGroup parents coordinate bitType).card := by
  classical
  unfold pairTypeGroupChildOnes
  exact Finset.card_filter_le _ _

def flattenPairChildArray
    {parentCount dimension : ℕ}
    (children : PairLayer parentCount 1 → HammingWord dimension) :
    PairLayer parentCount 1 × Fin dimension → Bool :=
  fun index => children index.1 index.2

theorem pairChildClassificationOnes_card
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (bitType : PairBitType) (coordinate : Fin dimension) :
    (classifiedWordOnes
      (pairCoordinateClassification parents) (bitType, coordinate)
      (flattenPairChildArray children)).card =
        (pairTypeGroupChildOnes parents children coordinate bitType).card := by
  classical
  apply Finset.card_bij (fun index _ => index.1)
  · intro index hindex
    have hclassified :
        index ∈
          (classificationGroup (pairCoordinateClassification parents)
            (bitType, coordinate)).filter
              (fun candidate =>
                flattenPairChildArray children candidate = true) := by
      simpa only [classifiedWordOnes] using hindex
    have hparts := Finset.mem_filter.mp hclassified
    have hgroup := (Finset.mem_filter.mp hparts.1).2
    have htype := congrArg Prod.fst hgroup
    have hcoordinate := congrArg Prod.snd hgroup
    have hcoord : index.2 = coordinate := by simpa [pairCoordinateClassification] using hcoordinate
    simp only [pairTypeGroupChildOnes, Finset.mem_filter]
    constructor
    · simp only [pairTypeGroup, Finset.mem_filter,
        Finset.mem_univ, true_and]
      simpa [pairCoordinateClassification, hcoord] using htype
    · simpa [flattenPairChildArray, hcoord] using hparts.2
  · intro first hfirst second hsecond hequal
    apply Prod.ext
    · exact hequal
    · have hfirst_group :=
        (Finset.mem_filter.mp hfirst).1
      have hsecond_group :=
        (Finset.mem_filter.mp hsecond).1
      have hfirst_class :=
        (Finset.mem_filter.mp hfirst_group).2
      have hsecond_class :=
        (Finset.mem_filter.mp hsecond_group).2
      have hfirst_coordinate := congrArg Prod.snd hfirst_class
      have hsecond_coordinate := congrArg Prod.snd hsecond_class
      simpa [pairCoordinateClassification] using
        hfirst_coordinate.trans hsecond_coordinate.symm
  · intro pair hpair
    refine ⟨(pair, coordinate), ?_, rfl⟩
    have hpair_parts := Finset.mem_filter.mp hpair
    have hpair_type := (Finset.mem_filter.mp hpair_parts.1).2
    change
      (pair, coordinate) ∈
        (classificationGroup (pairCoordinateClassification parents)
          (bitType, coordinate)).filter
            (fun index => flattenPairChildArray children index = true)
    apply Finset.mem_filter.mpr
    constructor
    · unfold classificationGroup
      apply Finset.mem_filter.mpr
      refine ⟨Finset.mem_univ _, ?_⟩
      exact Prod.ext hpair_type rfl
    · exact hpair_parts.2

noncomputable def pairChildCountProfile
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension) :
    PairTypeCountProfile parentCount dimension := by
  intro bitType coordinate
  refine ⟨(pairTypeGroupChildOnes parents children coordinate bitType).card, ?_⟩
  have hones := pairTypeGroupChildOnes_card_le
    parents children coordinate bitType
  have hgroup := pairTypeGroup_card_le parents coordinate bitType
  omega

noncomputable def pairChildArraysOfProfile
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (profile : PairTypeCountProfile parentCount dimension) :
    Finset (PairLayer parentCount 1 → HammingWord dimension) := by
  classical
  exact Finset.univ.filter
    (fun children => pairChildCountProfile parents children = profile)

noncomputable def pairChildArraysOfProfileEquiv
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (profile : PairTypeCountProfile parentCount dimension) :
    ↥(pairChildArraysOfProfile parents profile) ≃
      ↥(classifiedBooleanWords
        (pairCoordinateClassification parents)
        (fun index : PairBitType × Fin dimension =>
          (profile index.1 index.2).val)) := by
  classical
  refine
    { toFun := fun children =>
        ⟨flattenPairChildArray children.val, ?_⟩
      invFun := fun word =>
        ⟨fun pair coordinate => word.val (pair, coordinate), ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have hmembership := children.property
    unfold pairChildArraysOfProfile at hmembership
    have hprofile := (Finset.mem_filter.mp hmembership).2
    simp only [classifiedBooleanWords, Finset.mem_filter,
      Finset.mem_univ, true_and]
    rintro ⟨bitType, coordinate⟩
    rw [pairChildClassificationOnes_card]
    have hcount := congrArg
      (fun candidate : PairTypeCountProfile parentCount dimension =>
        (candidate bitType coordinate).val) hprofile
    simpa [pairChildCountProfile] using hcount
  · simp only [pairChildArraysOfProfile, Finset.mem_filter,
      Finset.mem_univ, true_and]
    funext bitType
    funext coordinate
    apply Fin.ext
    change
      (pairTypeGroupChildOnes parents
        (fun pair coordinate => word.val (pair, coordinate))
        coordinate bitType).card = (profile bitType coordinate).val
    have hmembership := word.property
    unfold classifiedBooleanWords at hmembership
    have hprofile :=
      (Finset.mem_filter.mp hmembership).2 (bitType, coordinate)
    rw [← pairChildClassificationOnes_card]
    have hflatten :
        flattenPairChildArray
          (fun pair coordinate => word.val (pair, coordinate)) =
            word.val := by
      funext index
      rcases index with ⟨pair, coordinate⟩
      rfl
    rw [hflatten]
    exact hprofile
  · intro children
    apply Subtype.ext
    funext pair
    funext coordinate
    rfl
  · intro word
    apply Subtype.ext
    funext index
    rcases index with ⟨pair, coordinate⟩
    rfl

noncomputable def pairCoordinateConditionalEntropy
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension) : ℝ :=
  ∑ bitType : PairBitType,
    ((pairTypeGroup parents coordinate bitType).card : ℝ) /
        (parentCount.choose 2 : ℝ) *
      binaryEntropy
        (((pairTypeGroupChildOnes parents children coordinate bitType).card : ℝ) /
          ((pairTypeGroup parents coordinate bitType).card : ℝ))

noncomputable def pairChildArrayEntropy
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension) : ℝ :=
  (∑ coordinate : Fin dimension,
    pairCoordinateConditionalEntropy parents children coordinate) /
      (dimension : ℝ)

noncomputable def pairParentCoordinateOneCount
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension) : ℕ :=
  (booleanWordOnes (fun parent => parents parent coordinate)).card

theorem pairParentCoordinateOneCount_le
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension) :
    pairParentCoordinateOneCount parents coordinate ≤ parentCount := by
  classical
  unfold pairParentCoordinateOneCount booleanWordOnes
  calc
    (Finset.univ.filter
      (fun parent : Fin parentCount =>
        parents parent coordinate = true)).card ≤
        (Finset.univ : Finset (Fin parentCount)).card :=
      Finset.card_filter_le _ _
    _ = parentCount := by simp

noncomputable def pairParentCoordinateSupport
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (outcome : Bool) : Finset (Fin parentCount) := by
  classical
  exact Finset.univ.filter
    (fun parent => parents parent coordinate = outcome)

theorem pairParentCoordinateSupport_true_card
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension) :
    (pairParentCoordinateSupport parents coordinate true).card =
      pairParentCoordinateOneCount parents coordinate := by
  rfl

theorem pairCoordinateBitType_homogeneous_iff
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (pair : PairLayer parentCount 1)
    (outcome : Bool) :
    pairCoordinateBitType parents coordinate pair =
        (if outcome then (1 : PairBitType) else 0) ↔
      ∀ parent ∈ pair.val, parents parent coordinate = outcome := by
  classical
  obtain ⟨a, b, hab, hp⟩ := Finset.card_eq_two.mp pair.property
  cases outcome <;> cases ha : parents a coordinate <;>
    cases hb : parents b coordinate <;>
    simp_all [pairCoordinateBitType]

noncomputable def pairTypeGroupHomogeneousEquiv
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (outcome : Bool) :
    ↥(pairTypeGroup parents coordinate
      (if outcome then (1 : PairBitType) else 0)) ≃
      ↥((pairParentCoordinateSupport parents coordinate outcome).powersetCard 2) := by
  classical
  refine
    { toFun := fun pair => ⟨pair.val.val, ?_⟩
      invFun := fun support =>
        ⟨⟨support.val, ?_⟩, ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have hmembership := pair.property
    unfold pairTypeGroup at hmembership
    have htype := (Finset.mem_filter.mp hmembership).2
    have hhomogeneous :=
      (pairCoordinateBitType_homogeneous_iff
        parents coordinate pair.val outcome).mp htype
    apply Finset.mem_powersetCard.mpr
    refine ⟨?_, pair.val.property⟩
    intro parent hparent
    unfold pairParentCoordinateSupport
    exact Finset.mem_filter.mpr
      ⟨Finset.mem_univ _, hhomogeneous parent hparent⟩
  · exact (Finset.mem_powersetCard.mp support.property).2
  · unfold pairTypeGroup
    apply Finset.mem_filter.mpr
    refine ⟨Finset.mem_univ _, ?_⟩
    apply (pairCoordinateBitType_homogeneous_iff
      parents coordinate
      ⟨support.val, (Finset.mem_powersetCard.mp support.property).2⟩
      outcome).mpr
    intro parent hparent
    have hsubset :=
      (Finset.mem_powersetCard.mp support.property).1
    have hsupport := hsubset hparent
    unfold pairParentCoordinateSupport at hsupport
    exact (Finset.mem_filter.mp hsupport).2
  · intro pair
    apply Subtype.ext
    apply Subtype.ext
    rfl
  · intro support
    apply Subtype.ext
    rfl

theorem pairTypeGroup_homogeneous_card
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (outcome : Bool) :
    (pairTypeGroup parents coordinate
      (if outcome then (1 : PairBitType) else 0)).card =
      (pairParentCoordinateSupport parents coordinate outcome).card.choose 2 := by
  calc
    (pairTypeGroup parents coordinate
      (if outcome then (1 : PairBitType) else 0)).card =
      Fintype.card
        ↥(pairTypeGroup parents coordinate
          (if outcome then (1 : PairBitType) else 0)) :=
      (Fintype.card_coe _).symm
    _ = Fintype.card
      ↥((pairParentCoordinateSupport parents coordinate outcome).powersetCard 2) :=
      Fintype.card_congr
        (pairTypeGroupHomogeneousEquiv parents coordinate outcome)
    _ = ((pairParentCoordinateSupport parents coordinate outcome).powersetCard 2).card :=
      Fintype.card_coe _
    _ = (pairParentCoordinateSupport parents coordinate outcome).card.choose 2 :=
      Finset.card_powersetCard _ _

def pairBitTypeOfOutcomes (left right : Bool) : PairBitType :=
  if left = false ∧ right = false then 0
  else if left = true ∧ right = true then 1
  else 2

noncomputable def pairCoordinateKernel
    {parentCount dimension : ℕ}
    (hparents : 0 < parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension) : BinaryPairKernel where
  parentProbability :=
    (pairParentCoordinateOneCount parents coordinate : ℝ) /
      (parentCount : ℝ)
  parentProbability_nonneg := by positivity
  parentProbability_le_one := by
    have hpositive : 0 < (parentCount : ℝ) := by exact_mod_cast hparents
    apply (div_le_one hpositive).mpr
    exact_mod_cast pairParentCoordinateOneCount_le parents coordinate
  childProbability left right :=
    ((pairTypeGroupChildOnes parents children coordinate
      (pairBitTypeOfOutcomes left right)).card : ℝ) /
        ((pairTypeGroup parents coordinate
          (pairBitTypeOfOutcomes left right)).card : ℝ)
  childProbability_nonneg := by
    intro left right
    positivity
  childProbability_le_one := by
    intro left right
    let bitType := pairBitTypeOfOutcomes left right
    have hle := pairTypeGroupChildOnes_card_le
      parents children coordinate bitType
    by_cases hzero : (pairTypeGroup parents coordinate bitType).card = 0
    · simp [bitType, hzero]
    · have hpositive :
          0 < ((pairTypeGroup parents coordinate bitType).card : ℝ) := by
        exact_mod_cast Nat.pos_of_ne_zero hzero
      apply (div_le_one hpositive).mpr
      exact_mod_cast hle

theorem pairCoordinateKernel_childProbability
    {parentCount dimension : ℕ}
    (hparents : 0 < parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (left right : Bool) :
    (pairCoordinateKernel hparents parents children coordinate).childProbability
        left right =
      ((pairTypeGroupChildOnes parents children coordinate
        (pairBitTypeOfOutcomes left right)).card : ℝ) /
          ((pairTypeGroup parents coordinate
            (pairBitTypeOfOutcomes left right)).card : ℝ) := by
  rfl

noncomputable def pairChildCoordinateOneCount
    {parentCount dimension : ℕ}
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension) : ℕ :=
  (booleanWordOnes (fun pair => children pair coordinate)).card

theorem pairTypeGroup_probability_mul_childRatio
    {parentCount dimension : ℕ}
    (hparents : 2 ≤ parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (bitType : PairBitType) :
    ((pairTypeGroup parents coordinate bitType).card : ℝ) /
        (parentCount.choose 2 : ℝ) *
      (((pairTypeGroupChildOnes parents children
          coordinate bitType).card : ℝ) /
        ((pairTypeGroup parents coordinate bitType).card : ℝ)) =
      ((pairTypeGroupChildOnes parents children
        coordinate bitType).card : ℝ) /
          (parentCount.choose 2 : ℝ) := by
  have hpair : 0 < (parentCount.choose 2 : ℝ) := by exact_mod_cast Nat.choose_pos hparents
  by_cases hgroup : (pairTypeGroup parents coordinate bitType).card = 0
  · have hchild :
        (pairTypeGroupChildOnes parents children
          coordinate bitType).card = 0 := by
      have hle := pairTypeGroupChildOnes_card_le
        parents children coordinate bitType
      omega
    simp [hgroup, hchild]
  · have hgroup_real :
        ((pairTypeGroup parents coordinate bitType).card : ℝ) ≠ 0 := by
      exact_mod_cast hgroup
    field_simp [hpair.ne', hgroup_real]

theorem withoutReplacementBinaryPairMass_eq_pairTypeGroup
    {parentCount dimension : ℕ}
    (hparents : 2 ≤ parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (coordinate : Fin dimension)
    (left right : Bool) :
    withoutReplacementBinaryPairMass parentCount
        (pairParentCoordinateOneCount parents coordinate) left right =
      ((pairTypeGroup parents coordinate
        (pairBitTypeOfOutcomes left right)).card : ℝ) /
        (parentCount.choose 2 : ℝ) *
          (if left = right then (1 : ℝ) else 1 / 2) := by
  have pairTypeGroup_false_card
      {parentCount dimension : ℕ}
      (parents : Fin parentCount → HammingWord dimension)
      (coordinate : Fin dimension) :
      (pairTypeGroup parents coordinate 0).card =
        (parentCount - pairParentCoordinateOneCount parents coordinate).choose 2 := by
    have pairParentCoordinateSupport_false_card
        {parentCount dimension : ℕ}
        (parents : Fin parentCount → HammingWord dimension)
        (coordinate : Fin dimension) :
        (pairParentCoordinateSupport parents coordinate false).card =
          parentCount - pairParentCoordinateOneCount parents coordinate := by
      have pairParentCoordinateSupport_card_add
          {parentCount dimension : ℕ}
          (parents : Fin parentCount → HammingWord dimension)
          (coordinate : Fin dimension) :
          (pairParentCoordinateSupport parents coordinate false).card +
            (pairParentCoordinateSupport parents coordinate true).card =
              parentCount := by
        classical
        have hpartition :=
          Finset.card_filter_add_card_filter_not
            (s := (Finset.univ : Finset (Fin parentCount)))
            (fun parent => parents parent coordinate = false)
        simpa [pairParentCoordinateSupport, Bool.not_eq_false] using hpartition
      have hpartition := pairParentCoordinateSupport_card_add parents coordinate
      rw [pairParentCoordinateSupport_true_card] at hpartition
      omega
    simpa [pairParentCoordinateSupport_false_card] using
      pairTypeGroup_homogeneous_card parents coordinate false
  have pairTypeGroup_true_card
      {parentCount dimension : ℕ}
      (parents : Fin parentCount → HammingWord dimension)
      (coordinate : Fin dimension) :
      (pairTypeGroup parents coordinate 1).card =
        (pairParentCoordinateOneCount parents coordinate).choose 2 := by
    simpa [pairParentCoordinateSupport_true_card] using
      pairTypeGroup_homogeneous_card parents coordinate true
  have pairTypeGroup_mixed_card
      {parentCount dimension : ℕ}
      (parents : Fin parentCount → HammingWord dimension)
      (coordinate : Fin dimension) :
      (pairTypeGroup parents coordinate 2).card =
        (parentCount - pairParentCoordinateOneCount parents coordinate) *
          pairParentCoordinateOneCount parents coordinate := by
    have sum_pairTypeGroup_card
        {parentCount dimension : ℕ}
        (parents : Fin parentCount → HammingWord dimension)
        (coordinate : Fin dimension) :
        (∑ bitType : PairBitType,
          (pairTypeGroup parents coordinate bitType).card) =
          parentCount.choose 2 := by
      classical
      have hmaps :
          (((Finset.univ : Finset (PairLayer parentCount 1)) :
            Set (PairLayer parentCount 1))).MapsTo
              (pairCoordinateBitType parents coordinate)
              (Finset.univ : Finset PairBitType) := by simp_all
      have hpartition := Finset.card_eq_sum_card_fiberwise hmaps
      have hpairs :
          (Finset.univ : Finset (PairLayer parentCount 1)).card =
            parentCount.choose 2 := by
        rw [Finset.card_univ, pairLayer_card_succ parentCount 0,
          pairLayer_card_zero]
      calc
        (∑ bitType : PairBitType,
            (pairTypeGroup parents coordinate bitType).card) =
          (Finset.univ : Finset (PairLayer parentCount 1)).card := by
            simpa [pairTypeGroup] using hpartition.symm
        _ = parentCount.choose 2 := hpairs
    have hones := pairParentCoordinateOneCount_le parents coordinate
    have htotal :
        (pairTypeGroup parents coordinate 0).card +
          (pairTypeGroup parents coordinate 1).card +
            (pairTypeGroup parents coordinate 2).card =
              parentCount.choose 2 := by
      simpa [Fin.sum_univ_succ, add_assoc] using
        sum_pairTypeGroup_card parents coordinate
    rw [pairTypeGroup_false_card,
      pairTypeGroup_true_card] at htotal
    have htotal_real :
        (((parentCount -
            pairParentCoordinateOneCount parents coordinate).choose 2 : ℕ) : ℝ) +
          (((pairParentCoordinateOneCount parents coordinate).choose 2 : ℕ) : ℝ) +
          ((pairTypeGroup parents coordinate 2).card : ℝ) =
            (parentCount.choose 2 : ℝ) := by
      exact_mod_cast htotal
    rw [Nat.cast_choose_two, Nat.cast_choose_two,
      Nat.cast_choose_two, Nat.cast_sub hones] at htotal_real
    have hresult :
        ((pairTypeGroup parents coordinate 2).card : ℝ) =
          (((parentCount -
            pairParentCoordinateOneCount parents coordinate) *
              pairParentCoordinateOneCount parents coordinate : ℕ) : ℝ) := by
      rw [Nat.cast_mul, Nat.cast_sub hones]
      nlinarith
    exact_mod_cast hresult
  have hones := pairParentCoordinateOneCount_le parents coordinate
  have hparent : 0 < (parentCount : ℝ) := by
    exact_mod_cast lt_of_lt_of_le (by norm_num : 0 < 2) hparents
  have hparent_minus : 0 < (parentCount : ℝ) - 1 := by
    have htwo : (2 : ℝ) ≤ (parentCount : ℝ) := by exact_mod_cast hparents
    linarith
  cases left <;> cases right <;>
    simp [withoutReplacementBinaryPairMass,
      empiricalBinaryOutcomeCount,
      pairBitTypeOfOutcomes,
      pairTypeGroup_false_card,
      pairTypeGroup_true_card,
      pairTypeGroup_mixed_card,
      Nat.cast_choose_two,
      Nat.cast_sub hones] <;>
    field_simp [hparent.ne', hparent_minus.ne']


noncomputable def pairCoordinatePairMismatchCount
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (pair : PairLayer parentCount 1) : ℕ := by
  classical
  exact (pair.val.filter
    (fun parent =>
      parents parent coordinate ≠ children pair coordinate)).card

theorem pairCoordinatePairMismatchCount_homogeneous
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension)
    (pair : PairLayer parentCount 1)
    (outcome : Bool)
    (hgroup :
      pairCoordinateBitType parents coordinate pair =
        (if outcome then (1 : PairBitType) else 0)) :
    pairCoordinatePairMismatchCount parents children coordinate pair =
      if children pair coordinate = outcome then 0 else 2 := by
  classical
  have hhomogeneous :=
    (pairCoordinateBitType_homogeneous_iff
      parents coordinate pair outcome).mp hgroup
  by_cases hchild : children pair coordinate = outcome
  · have hempty :
        pair.val.filter
          (fun parent =>
            parents parent coordinate ≠ children pair coordinate) = ∅ := by
      apply Finset.filter_eq_empty_iff.mpr
      intro parent hmember hdisagree
      exact hdisagree
        ((hhomogeneous parent hmember).trans hchild.symm)
    unfold pairCoordinatePairMismatchCount
    rw [hempty]
    simp [hchild]
  · have hfull :
        pair.val.filter
          (fun parent =>
            parents parent coordinate ≠ children pair coordinate) =
          pair.val := by
      ext parent
      constructor
      · intro hmember
        exact (Finset.mem_filter.mp hmember).1
      · intro hmember
        apply Finset.mem_filter.mpr
        refine ⟨hmember, ?_⟩
        intro hequal
        apply hchild
        exact hequal.symm.trans
          (hhomogeneous parent hmember)
    unfold pairCoordinatePairMismatchCount
    rw [hfull, if_neg hchild]
    exact pair.property

set_option maxHeartbeats 400000 in
theorem pairCoordinateConditionalEntropy_empirical_bound
    {parentCount dimension : ℕ}
    (hparents : 4 ≤ parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension)
    (coordinate : Fin dimension) :
    pairCoordinateConditionalEntropy parents children coordinate ≤
      kappa +
        logTwo 3 *
          empiricalAverageDisagreement parentCount
            (pairParentCoordinateOneCount parents coordinate)
            (pairCoordinateKernel (by omega)
              parents children coordinate) +
        (binaryEntropy
            ((pairChildCoordinateOneCount children coordinate : ℝ) /
              (parentCount.choose 2 : ℝ)) -
          binaryEntropy
            ((pairParentCoordinateOneCount parents coordinate : ℝ) /
              (parentCount : ℝ))) / 2 +
        empiricalEntropyError parentCount := by
  have h2 : 2 ≤ parentCount := by omega
  have hm := withoutReplacementBinaryPairMass_eq_pairTypeGroup h2 parents coordinate
  have m00 := hm false false
  have m11 := hm true true
  have m01 := hm false true
  simp [withoutReplacementBinaryPairMass, empiricalBinaryOutcomeCount,
    pairBitTypeOfOutcomes] at m00 m11 m01
  have hC : (0 : ℝ) < parentCount.choose 2 := by exact_mod_cast Nat.choose_pos h2
  have hn : (2 : ℝ) ≤ parentCount := by exact_mod_cast h2
  have hk : (pairParentCoordinateOneCount parents coordinate : ℝ) ≤ parentCount := by
    exact_mod_cast pairParentCoordinateOneCount_le parents coordinate
  have hcs : (pairChildCoordinateOneCount children coordinate : ℝ) =
      ∑ t, ((pairTypeGroupChildOnes parents children coordinate t).card : ℝ) := by
    rw [pairChildCoordinateOneCount, Finset.card_eq_sum_card_fiberwise
      (f := pairCoordinateBitType parents coordinate) (t := Finset.univ)
      (fun _ _ => Finset.mem_univ _)]
    push_cast
    refine Finset.sum_congr rfl fun t _ => ?_
    congr 2
    ext
    simp [booleanWordOnes, pairTypeGroupChildOnes, pairTypeGroup, and_comm]
  have hp (t : PairBitType) := pairTypeGroup_probability_mul_childRatio h2 parents children
    coordinate t
  set n : ℝ := ((parentCount : ℕ) : ℝ)
  set k : ℝ := (pairParentCoordinateOneCount parents coordinate : ℝ)
  set C : ℝ := (parentCount.choose 2 : ℝ)
  set g : PairBitType → ℝ := fun t => ((pairTypeGroup parents coordinate t).card : ℝ)
  set c : PairBitType → ℝ := fun t =>
    ((pairTypeGroupChildOnes parents children coordinate t).card : ℝ)
  have hz (t : PairBitType) : 0 ≤ c t / g t ∧ c t / g t ≤ 1 :=
    ⟨by positivity, div_le_one_of_le₀ (by
      simp only [c, g]
      exact_mod_cast pairTypeGroupChildOnes_card_le parents children coordinate t)
      (by positivity)⟩
  have e2 : g 2 / C = 2 * ((n - k) * k / (n * (n - 1))) := by rw [m01]; ring
  have hn0 : n ≠ 0 := by positivity
  have hn1 : n - 1 ≠ 0 := by linarith
  have hW (t : PairBitType) : 0 ≤ g t / C := div_nonneg (Nat.cast_nonneg _) hC.le
  have hcore := pairTypeEntropy_bound (q := k / n) (hW 0) (hW 1) (hW 2)
    (by rw [← m00, ← m11, e2]; field_simp; ring) (by rw [← m11, e2]; field_simp; ring)
    (by
      rw [e2, show 2 * (k / n) * (1 - k / n) = 2 * ((n - k) * k / (n * n)) by field_simp]
      gcongr 2 * ?_
      exact div_le_div_of_nonneg_left (mul_nonneg (by linarith) (by positivity))
        (by nlinarith) (by nlinarith))
    (hz 0) (hz 1) (hz 2)
  have eD : empiricalAverageDisagreement parentCount
      (pairParentCoordinateOneCount parents coordinate)
      (pairCoordinateKernel (by omega) parents children coordinate) =
      g 0 / C * (c 0 / g 0) + g 1 / C * (1 - c 1 / g 1) + g 2 / C / 2 := by
    simp only [empiricalAverageDisagreement, withoutReplacementBinaryPairExpectation, hm,
      Fintype.sum_bool, pairCoordinateKernel_childProbability, pairBitTypeOfOutcomes,
      BinaryPairKernel.bitDisagreementProbability]
    simp
    ring
  have hv : (pairChildCoordinateOneCount children coordinate : ℝ) / C =
      g 0 / C * (c 0 / g 0) + g 1 / C * (c 1 / g 1) + g 2 / C * (c 2 / g 2) := by
    rw [hp, hp, hp, hcs, Fin.sum_univ_three]; ring
  have herr : 0 ≤ empiricalEntropyError parentCount := by
    unfold empiricalEntropyError
    have := binaryEntropy_nonneg (x := 1 / n) (by positivity)
      (by rw [div_le_one (by positivity)]; linarith)
    have := logTwo_three_pos
    positivity
  rw [eD, hv]
  simp only [pairCoordinateConditionalEntropy, Fin.sum_univ_three]
  linarith

noncomputable def pairParentArrayEntropyPotential
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension) : ℝ :=
  (∑ coordinate : Fin dimension,
    binaryEntropy
      ((pairParentCoordinateOneCount parents coordinate : ℝ) /
        (parentCount : ℝ))) /
      (dimension : ℝ)

noncomputable def pairChildArrayEntropyPotential
    {parentCount dimension : ℕ}
    (children : PairLayer parentCount 1 → HammingWord dimension) : ℝ :=
  (∑ coordinate : Fin dimension,
    binaryEntropy
      ((pairChildCoordinateOneCount children coordinate : ℝ) /
        (parentCount.choose 2 : ℝ))) /
      (dimension : ℝ)

noncomputable def pairChildArrayAverageDisagreement
    {parentCount dimension : ℕ}
    (hparents : 4 ≤ parentCount)
    (parents : Fin parentCount → HammingWord dimension)
    (children : PairLayer parentCount 1 → HammingWord dimension) : ℝ :=
  (∑ coordinate : Fin dimension,
    empiricalAverageDisagreement parentCount
      (pairParentCoordinateOneCount parents coordinate)
      (pairCoordinateKernel (by omega) parents children coordinate)) /
    (dimension : ℝ)

noncomputable def badPairChildArrays
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (threshold : ℝ) :
    Finset (PairLayer parentCount 1 → HammingWord dimension) := by
  classical
  exact Finset.univ.filter
    (fun children => pairChildArrayEntropy parents children ≤ threshold)

end HammingProfiles

section SamplingAndHammingBalls

noncomputable def hammingRetentionProbability (dimension : ℕ) : ℝ :=
  Real.exp (-(midpointBeta * (dimension : ℝ) * Real.log 2))

theorem hammingRetentionProbability_pos (dimension : ℕ) :
    0 < hammingRetentionProbability dimension := by
  unfold hammingRetentionProbability
  exact Real.exp_pos _

theorem hammingRetentionProbability_le_one (dimension : ℕ) :
    hammingRetentionProbability dimension ≤ 1 := by
  unfold hammingRetentionProbability
  apply Real.exp_le_one_iff.mpr
  have hproduct : 0 ≤ midpointBeta * (dimension : ℝ) * Real.log 2 :=
    mul_nonneg
      (mul_nonneg midpointBeta_pos.le (Nat.cast_nonneg dimension))
      log_two_pos.le
  linarith

theorem hammingRetentionProbability_mul_wordCount_eq_exp
    (dimension : ℕ) :
    hammingRetentionProbability dimension *
        ((2 ^ dimension : ℕ) : ℝ) =
      Real.exp
        ((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) := by
  have hwords : ((2 ^ dimension : ℕ) : ℝ) = Real.exp ((dimension : ℝ) * Real.log 2) := by
    rw [Real.exp_nat_mul, Real.exp_log (by norm_num)]
    norm_cast
  unfold hammingRetentionProbability
  rw [hwords, ← Real.exp_add]
  congr 1
  ring

theorem hammingRetentionProbability_mul_wordCount_tendsto_atTop :
    Tendsto
      (fun dimension : ℕ =>
        hammingRetentionProbability dimension *
          ((2 ^ dimension : ℕ) : ℝ))
      atTop atTop := by
  have hrate : 0 < (1 - midpointBeta) * Real.log 2 :=
    mul_pos (sub_pos.mpr midpointBeta_lt_one) log_two_pos
  have hlinear :
      Tendsto
        (fun dimension : ℕ =>
          ((1 - midpointBeta) * Real.log 2) * (dimension : ℝ))
        atTop atTop :=
    tendsto_natCast_atTop_atTop.const_mul_atTop hrate
  have hexponential := Real.tendsto_exp_atTop.comp hlinear
  apply hexponential.congr'
  filter_upwards [] with dimension
  simp only [Function.comp_apply]
  rw [hammingRetentionProbability_mul_wordCount_eq_exp]
  congr 1
  ring

theorem exp_mul_div_nat_succ_tendsto_atTop
    (rate : ℝ) (hrate : 0 < rate) :
    Tendsto
      (fun dimension : ℕ =>
        Real.exp (rate * (dimension : ℝ)) /
          ((dimension + 1 : ℕ) : ℝ))
      atTop atTop := by
  have hquotient :
      Tendsto
        (fun dimension : ℕ =>
          Real.exp (rate * (dimension : ℝ)) / (dimension : ℝ))
        atTop atTop := by
    have htendsto :=
      (tendsto_exp_mul_div_rpow_atTop 1 rate hrate).comp
        tendsto_natCast_atTop_atTop
    refine htendsto.congr' ?_
    filter_upwards [] with dimension
    simp [Function.comp_apply]
  have hhalf :
      Tendsto
        (fun dimension : ℕ =>
          (1 / 2 : ℝ) *
            (Real.exp (rate * (dimension : ℝ)) / (dimension : ℝ)))
        atTop atTop :=
    hquotient.const_mul_atTop (by norm_num)
  apply tendsto_atTop_mono' atTop _ hhalf
  filter_upwards [Filter.eventually_ge_atTop 1] with dimension hdimension
  have hpositive : 0 < (dimension : ℝ) := by exact_mod_cast (show 0 < dimension by omega)
  have hdimension_real : (1 : ℝ) ≤ (dimension : ℝ) := by exact_mod_cast hdimension
  calc
    (1 / 2 : ℝ) *
        (Real.exp (rate * (dimension : ℝ)) / (dimension : ℝ)) =
      Real.exp (rate * (dimension : ℝ)) /
        (2 * (dimension : ℝ)) := by
        ring
    _ ≤ Real.exp (rate * (dimension : ℝ)) /
        ((dimension + 1 : ℕ) : ℝ) := by
      gcongr
      push_cast
      nlinarith

noncomputable def hammingRetentionParameter (dimension : ℕ) : unitInterval :=
  ⟨hammingRetentionProbability dimension,
    hammingRetentionProbability_pos dimension |>.le,
    hammingRetentionProbability_le_one dimension⟩

noncomputable def hammingRetentionMeasure (dimension : ℕ) :
    MeasureTheory.Measure (Set (Bool × HammingWord dimension)) :=
  ProbabilityTheory.setBernoulli Set.univ
    (hammingRetentionParameter dimension)

theorem hammingRetentionMeasure_isProbability (dimension : ℕ) :
    MeasureTheory.IsProbabilityMeasure
      (hammingRetentionMeasure dimension) := by
  unfold hammingRetentionMeasure
  infer_instance

theorem hammingRetentionMeasure_integrable
    (dimension : ℕ)
    (observable : Set (Bool × HammingWord dimension) → ℝ) :
    MeasureTheory.Integrable observable
      (hammingRetentionMeasure dimension) := by
  let : MeasureTheory.IsProbabilityMeasure
      (hammingRetentionMeasure dimension) :=
    hammingRetentionMeasure_isProbability dimension
  exact MeasureTheory.Integrable.of_finite

theorem hammingRetentionMeasure_memLp_two
    (dimension : ℕ)
    (observable : Set (Bool × HammingWord dimension) → ℝ) :
    MeasureTheory.MemLp observable 2
      (hammingRetentionMeasure dimension) := by
  apply (MeasureTheory.memLp_two_iff_integrable_sq
    (hammingRetentionMeasure_integrable dimension observable).aestronglyMeasurable).mpr
  exact hammingRetentionMeasure_integrable dimension
    (fun retained => observable retained ^ 2)

theorem hammingRetentionMeasure_integral_eq_sum
    (dimension : ℕ)
    (observable : Set (Bool × HammingWord dimension) → ℝ) :
    (∫ retained,
      observable retained ∂hammingRetentionMeasure dimension) =
      ∑ retained : Set (Bool × HammingWord dimension),
        (hammingRetentionMeasure dimension).real {retained} *
          observable retained := by
  classical
  simpa [smul_eq_mul] using
    (MeasureTheory.integral_fintype
      (hammingRetentionMeasure_integrable dimension observable))

open Classical in
theorem hammingRetentionMeasure_real_event_eq_sum
    (dimension : ℕ)
    (event : Set (Set (Bool × HammingWord dimension))) :
    (hammingRetentionMeasure dimension).real event =
      ∑ retained : Set (Bool × HammingWord dimension),
        if retained ∈ event then
          (hammingRetentionMeasure dimension).real {retained}
        else 0 := by
  classical
  let : MeasureTheory.IsProbabilityMeasure
      (hammingRetentionMeasure dimension) :=
    hammingRetentionMeasure_isProbability dimension
  let support : Finset (Set (Bool × HammingWord dimension)) :=
    Finset.univ.filter (fun retained => retained ∈ event)
  have hsupport :
      (support : Set (Set (Bool × HammingWord dimension))) = event := by grind
  calc
    (hammingRetentionMeasure dimension).real event =
        (hammingRetentionMeasure dimension).real support := by
      rw [hsupport]
    _ = ∑ retained ∈ support,
        (hammingRetentionMeasure dimension).real {retained} := by
      exact (MeasureTheory.sum_measureReal_singleton support).symm
    _ = ∑ retained : Set (Bool × HammingWord dimension),
        if retained ∈ event then
          (hammingRetentionMeasure dimension).real {retained}
        else 0 := by
      rw [← Finset.sum_filter]

theorem hammingRetentionMeasure_real_deviation_le
    (dimension : ℕ)
    (observable : Set (Bool × HammingWord dimension) → ℝ)
    (threshold : ℝ) (hthreshold : 0 < threshold) :
    (hammingRetentionMeasure dimension).real
      {retained : Set (Bool × HammingWord dimension) |
        threshold ≤
          |observable retained -
            (∫ candidate,
              observable candidate ∂hammingRetentionMeasure dimension)|} ≤
      ProbabilityTheory.variance observable
          (hammingRetentionMeasure dimension) /
        threshold ^ 2 := by
  let : MeasureTheory.IsProbabilityMeasure
      (hammingRetentionMeasure dimension) :=
    hammingRetentionMeasure_isProbability dimension
  have hchebyshev :=
    ProbabilityTheory.meas_ge_le_variance_div_sq
      (hammingRetentionMeasure_memLp_two dimension observable)
      hthreshold
  have hreal := ENNReal.toReal_mono ENNReal.ofReal_ne_top hchebyshev
  have hnonnegative :
      0 ≤ ProbabilityTheory.variance observable
          (hammingRetentionMeasure dimension) /
        threshold ^ 2 := by
    exact div_nonneg
      (ProbabilityTheory.variance_nonneg observable
        (hammingRetentionMeasure dimension))
      (sq_nonneg threshold)
  simpa [MeasureTheory.Measure.real, ENNReal.toReal_ofReal hnonnegative]
    using hreal

theorem hammingRetentionMeasure_real_contains_finset
    (dimension : ℕ)
    (required : Finset (Bool × HammingWord dimension)) :
    (hammingRetentionMeasure dimension).real
      {retained : Set (Bool × HammingWord dimension) |
        ∀ vertex ∈ required, vertex ∈ retained} =
      hammingRetentionProbability dimension ^ required.card := by
  classical
  have hpreimage :
      (fun membership : (Bool × HammingWord dimension) → Prop =>
        {vertex | membership vertex}) ⁻¹'
          {retained : Set (Bool × HammingWord dimension) |
            ∀ vertex ∈ required, vertex ∈ retained} =
        Set.pi (required : Set (Bool × HammingWord dimension))
          (fun _ => ({True} : Set Prop)) := by grind
  have hmeasure :
      hammingRetentionMeasure dimension
          {retained : Set (Bool × HammingWord dimension) |
            ∀ vertex ∈ required, vertex ∈ retained} =
        (↑(unitInterval.toNNReal
          (hammingRetentionParameter dimension)) : ENNReal) ^
            required.card := by
    unfold hammingRetentionMeasure
    rw [ProbabilityTheory.setBernoulli_apply']
    rw [hpreimage]
    rw [MeasureTheory.Measure.infinitePi_pi]
    · simp
    · intro vertex _
      measurability
  change
    ENNReal.toReal
        (hammingRetentionMeasure dimension
          {retained : Set (Bool × HammingWord dimension) |
            ∀ vertex ∈ required, vertex ∈ retained}) = _
  rw [hmeasure, ENNReal.toReal_pow]
  simp [hammingRetentionParameter]

noncomputable def hammingExpectedRetainedVertexCount
    (dimension : ℕ) : ℝ :=
  ∑ vertex : Bool × HammingWord dimension,
    (hammingRetentionMeasure dimension).real
      {retained : Set (Bool × HammingWord dimension) |
        vertex ∈ retained}

theorem hammingExpectedRetainedVertexCount_eq
    (dimension : ℕ) :
    hammingExpectedRetainedVertexCount dimension =
      2 * hammingRetentionProbability dimension *
        ((2 ^ dimension : ℕ) : ℝ) := by
  have hammingRetentionMeasure_real_contains_vertex
      (dimension : ℕ)
      (vertex : Bool × HammingWord dimension) :
      (hammingRetentionMeasure dimension).real
        {retained : Set (Bool × HammingWord dimension) |
          vertex ∈ retained} =
        hammingRetentionProbability dimension := by
    classical
    simpa using
      hammingRetentionMeasure_real_contains_finset dimension {vertex}
  unfold hammingExpectedRetainedVertexCount
  simp_rw [hammingRetentionMeasure_real_contains_vertex]
  rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
  simp [HammingWord]
  ring

noncomputable def hammingRetainedVertexCount
    (dimension : ℕ)
    (retained : Set (Bool × HammingWord dimension)) : ℝ := by
  classical
  exact ∑ vertex : Bool × HammingWord dimension,
    if vertex ∈ retained then 1 else 0

theorem hammingRetainedVertexCount_integral_eq
    (dimension : ℕ) :
    (∫ retained,
      hammingRetainedVertexCount dimension retained
        ∂hammingRetentionMeasure dimension) =
      hammingExpectedRetainedVertexCount dimension := by
  (open Classical in
    have hammingRetentionMeasure_integral_event_indicator
        (dimension : ℕ)
        (event : Set (Set (Bool × HammingWord dimension))) :
        (∫ retained,
          (if retained ∈ event then (1 : ℝ) else 0)
            ∂hammingRetentionMeasure dimension) =
          (hammingRetentionMeasure dimension).real event := by
      rw [hammingRetentionMeasure_integral_eq_sum,
        hammingRetentionMeasure_real_event_eq_sum]
      apply Finset.sum_congr rfl
      intro retained _
      split_ifs <;> simp)
  classical
  unfold hammingRetainedVertexCount hammingExpectedRetainedVertexCount
  rw [MeasureTheory.integral_finsetSum Finset.univ
    (fun vertex _ => hammingRetentionMeasure_integrable dimension
      (fun retained : Set (Bool × HammingWord dimension) =>
        if vertex ∈ retained then (1 : ℝ) else 0))]
  apply Finset.sum_congr rfl
  intro vertex _
  exact hammingRetentionMeasure_integral_event_indicator dimension
    {retained : Set (Bool × HammingWord dimension) | vertex ∈ retained}

noncomputable def pairChildVertexFinset
    {parentCount dimension : ℕ}
    (side : Bool)
    (children : PairLayer parentCount 1 → HammingWord dimension) :
    Finset (Bool × HammingWord dimension) := by
  classical
  exact (Finset.univ : Finset (PairLayer parentCount 1)).image
    (fun pair => (side, children pair))

def pairChildRetentionEvent
    {parentCount dimension : ℕ}
    (side : Bool)
    (children : PairLayer parentCount 1 → HammingWord dimension) :
    Set (Set (Bool × HammingWord dimension)) :=
  {retained | ∀ pair, (side, children pair) ∈ retained}

noncomputable def badPairChildRetentionEvent
    {parentCount dimension : ℕ}
    (parents : Fin parentCount → HammingWord dimension)
    (side : Bool)
    (threshold : ℝ) : Set (Set (Bool × HammingWord dimension)) := by
  classical
  exact
    ⋃ children ∈
        (badPairChildArrays parents threshold).filter Function.Injective,
      pairChildRetentionEvent side children

noncomputable def badPairLayerRetentionEvent
    (parentCount dimension : ℕ)
    (side : Bool)
    (threshold : ℝ) : Set (Set (Bool × HammingWord dimension)) :=
  ⋃ parents : Fin parentCount → HammingWord dimension,
    badPairChildRetentionEvent parents side threshold

noncomputable def badPairLayersRetentionEvent
    {depth : ℕ}
    (layerSizes : Fin depth → ℕ)
    (dimension : ℕ) : Set (Set (Bool × HammingWord dimension)) :=
  ⋃ side : Bool, ⋃ layer : Fin depth,
    badPairLayerRetentionEvent (layerSizes layer) dimension side
      (midpointBeta - entropySlack)

noncomputable def hammingDifferenceSet {dimension : ℕ}
    (u v : HammingWord dimension) : Finset (Fin dimension) := by
  classical
  exact Finset.univ.filter (fun coordinate => u coordinate ≠ v coordinate)

noncomputable def hammingFlip {dimension : ℕ}
    (u : HammingWord dimension) (coordinates : Finset (Fin dimension)) :
    HammingWord dimension := by
  classical
  exact fun coordinate =>
    if coordinate ∈ coordinates then !(u coordinate) else u coordinate

theorem hammingDifferenceSet_flip {dimension : ℕ}
    (u : HammingWord dimension) (coordinates : Finset (Fin dimension)) :
    hammingDifferenceSet u (hammingFlip u coordinates) = coordinates := by
  classical
  ext coordinate
  by_cases hcoordinate : coordinate ∈ coordinates
  · simp [hammingDifferenceSet, hammingFlip, hcoordinate]
  · simp [hammingDifferenceSet, hammingFlip, hcoordinate]

theorem hammingFlip_differenceSet {dimension : ℕ}
    (u v : HammingWord dimension) :
    hammingFlip u (hammingDifferenceSet u v) = v := by
  classical
  funext coordinate
  cases hu : u coordinate <;> cases hv : v coordinate <;>
    simp [hammingFlip, hammingDifferenceSet, hu, hv]

noncomputable def hammingBall (dimension radius : ℕ)
    (u : HammingWord dimension) : Finset (HammingWord dimension) := by
  classical
  exact Finset.univ.filter (fun v => hammingDist u v ≤ radius)

noncomputable def boundedDifferenceSets (dimension radius : ℕ) :
    Finset (Finset (Fin dimension)) := by
  classical
  exact ((Finset.univ : Finset (Fin dimension)).powerset).filter
    (fun coordinates => coordinates.card ≤ radius)

noncomputable def hammingBallEquiv (dimension radius : ℕ)
    (u : HammingWord dimension) :
    ↥(hammingBall dimension radius u) ≃
      ↥(boundedDifferenceSets dimension radius) := by
  classical
  refine
    { toFun := fun v => ⟨hammingDifferenceSet u v.val, ?_⟩
      invFun := fun coordinates =>
        ⟨hammingFlip u coordinates.val, ?_⟩
      left_inv := ?_
      right_inv := ?_ }
  · have hball : hammingDist u v.val ≤ radius := by
      have hmembership : v.val ∈
          (Finset.univ.filter
            (fun w : HammingWord dimension => hammingDist u w ≤ radius)) := by
        simpa only [hammingBall] using v.property
      exact (Finset.mem_filter.mp hmembership).2
    simp only [boundedDifferenceSets, Finset.mem_filter,
      Finset.mem_powerset]
    refine ⟨Finset.subset_univ _, ?_⟩
    simpa [hammingDist, hammingDifferenceSet] using hball
  · have hcoordinates : coordinates.val.card ≤ radius := by
      have hmembership : coordinates.val ∈
          (((Finset.univ : Finset (Fin dimension)).powerset).filter
            (fun S => S.card ≤ radius)) := by
        simpa only [boundedDifferenceSets] using coordinates.property
      exact (Finset.mem_filter.mp hmembership).2
    simp only [hammingBall, Finset.mem_filter, Finset.mem_univ, true_and]
    change (hammingDifferenceSet u
      (hammingFlip u coordinates.val)).card ≤ radius
    simpa [hammingDifferenceSet_flip] using hcoordinates
  · intro v
    apply Subtype.ext
    exact hammingFlip_differenceSet u v.val
  · intro coordinates
    apply Subtype.ext
    exact hammingDifferenceSet_flip u coordinates.val

theorem hammingBall_card (dimension radius : ℕ)
    (u : HammingWord dimension) :
    (hammingBall dimension radius u).card =
      ∑ d ∈ Finset.range (radius + 1), dimension.choose d := by
  have boundedDifferenceSets_card (dimension radius : ℕ) :
      (boundedDifferenceSets dimension radius).card =
        ∑ d ∈ Finset.range (radius + 1), dimension.choose d := by
    classical
    have hmaps :
        ((boundedDifferenceSets dimension radius :
          Finset (Finset (Fin dimension))) : Set (Finset (Fin dimension))).MapsTo
          Finset.card (Finset.range (radius + 1)) := by
      intro S hS
      have hmembership : S ∈
          (((Finset.univ : Finset (Fin dimension)).powerset).filter
            (fun coordinates => coordinates.card ≤ radius)) := by
        exact Finset.mem_coe.mp hS
      have hcard := (Finset.mem_filter.mp hmembership).2
      exact Finset.mem_range.mpr (by omega)
    calc
      (boundedDifferenceSets dimension radius).card =
          ∑ d ∈ Finset.range (radius + 1),
            ((boundedDifferenceSets dimension radius).filter
              (fun coordinates => coordinates.card = d)).card :=
        Finset.card_eq_sum_card_fiberwise hmaps
      _ = ∑ d ∈ Finset.range (radius + 1), dimension.choose d := by
        apply Finset.sum_congr rfl
        intro d hd
        have hdle : d ≤ radius := by grind
        have hfiber :
            (boundedDifferenceSets dimension radius).filter
              (fun coordinates => coordinates.card = d) =
            (Finset.univ : Finset (Fin dimension)).powersetCard d := by
          ext coordinates
          simp only [boundedDifferenceSets, Finset.mem_filter,
            Finset.mem_powerset, Finset.mem_powersetCard]
          constructor
          · rintro ⟨⟨hsubset, _⟩, hcard⟩
            exact ⟨hsubset, hcard⟩
          · rintro ⟨hsubset, hcard⟩
            exact ⟨⟨hsubset, by omega⟩, hcard⟩
        rw [hfiber, Finset.card_powersetCard]
        simp
  calc
    (hammingBall dimension radius u).card =
        Fintype.card ↥(hammingBall dimension radius u) :=
      (Fintype.card_coe _).symm
    _ = Fintype.card ↥(boundedDifferenceSets dimension radius) :=
      Fintype.card_congr (hammingBallEquiv dimension radius u)
    _ = (boundedDifferenceSets dimension radius).card :=
      Fintype.card_coe _
    _ = ∑ d ∈ Finset.range (radius + 1), dimension.choose d :=
      boundedDifferenceSets_card dimension radius

end SamplingAndHammingBalls

attribute [local instance] Classical.propDecidable

section HammingHostAndExclusion

def hammingHost (dimension radius : ℕ) :
    SimpleGraph (Bool × HammingWord dimension) :=
  SimpleGraph.fromRel
    (fun x y => x.1 ≠ y.1 ∧ hammingDist x.2 y.2 ≤ radius)

theorem hammingHost_adj_iff (dimension radius : ℕ)
    (x y : Bool × HammingWord dimension) :
    (hammingHost dimension radius).Adj x y ↔
      x.1 ≠ y.1 ∧ hammingDist x.2 y.2 ≤ radius := by
  rw [hammingHost, SimpleGraph.fromRel_adj]
  constructor
  · rintro ⟨_, hforward | hbackward⟩
    · exact hforward
    · exact ⟨Ne.symm hbackward.1, by
        simpa [hammingDist_comm] using hbackward.2⟩
  · intro hxy
    refine ⟨?_, Or.inl hxy⟩
    intro heq
    exact hxy.1 (congrArg Prod.fst heq)

theorem hammingWordNeighbor_sum_const
    (dimension radius : ℕ) (left : HammingWord dimension)
    (weight : ℝ) :
    (∑ right : HammingWord dimension,
      if hammingDist left right ≤ radius then weight else 0) =
      ((∑ distance ∈ Finset.range (radius + 1),
        dimension.choose distance : ℕ) : ℝ) * weight := by
  classical
  calc
    (∑ right : HammingWord dimension,
      if hammingDist left right ≤ radius then weight else 0) =
        ∑ _right ∈ hammingBall dimension radius left, weight := by
          rw [← Finset.sum_filter]
          rfl
    _ = ((hammingBall dimension radius left).card : ℝ) * weight := by simp [nsmul_eq_mul]
    _ = ((∑ distance ∈ Finset.range (radius + 1),
        dimension.choose distance : ℕ) : ℝ) * weight := by
      rw [hammingBall_card]

theorem hammingWordEdge_sum_const
    (dimension radius : ℕ) (weight : ℝ) :
    (∑ left : HammingWord dimension,
      ∑ right : HammingWord dimension,
        if hammingDist left right ≤ radius then weight else 0) =
      ((2 ^ dimension : ℕ) : ℝ) *
        ((∑ distance ∈ Finset.range (radius + 1),
          dimension.choose distance : ℕ) : ℝ) * weight := by
  classical
  simp_rw [hammingWordNeighbor_sum_const]
  rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul]
  simp [HammingWord]
  ring

theorem hammingWordEdgePairSharedLeft_sum_const
    (dimension radius : ℕ) (weight : ℝ) :
    (∑ firstLeft : HammingWord dimension,
      ∑ firstRight : HammingWord dimension,
        ∑ secondLeft : HammingWord dimension,
          ∑ secondRight : HammingWord dimension,
            if hammingDist firstLeft firstRight ≤ radius ∧
                hammingDist secondLeft secondRight ≤ radius then
              if firstLeft = secondLeft then weight else 0
            else 0) =
      ((2 ^ dimension : ℕ) : ℝ) *
        ((∑ distance ∈ Finset.range (radius + 1),
          dimension.choose distance : ℕ) : ℝ) ^ 2 * weight := by
  classical
  have hshared (firstLeft : HammingWord dimension) :
      (∑ secondLeft : HammingWord dimension,
        ∑ secondRight : HammingWord dimension,
          if hammingDist secondLeft secondRight ≤ radius then
            if firstLeft = secondLeft then weight else 0
          else 0) =
        ((∑ distance ∈ Finset.range (radius + 1),
          dimension.choose distance : ℕ) : ℝ) * weight := by
    calc
      (∑ secondLeft : HammingWord dimension,
        ∑ secondRight : HammingWord dimension,
          if hammingDist secondLeft secondRight ≤ radius then
            if firstLeft = secondLeft then weight else 0
          else 0) =
        ∑ secondLeft : HammingWord dimension,
          if firstLeft = secondLeft then
            ∑ secondRight : HammingWord dimension,
              if hammingDist secondLeft secondRight ≤ radius then
                weight else 0
          else 0 := by
            apply Finset.sum_congr rfl
            intro secondLeft _
            by_cases hleft : firstLeft = secondLeft
            · subst secondLeft
              simp
            · simp [hleft]
      _ = ((∑ distance ∈ Finset.range (radius + 1),
            dimension.choose distance : ℕ) : ℝ) * weight := by
        simp [hammingWordNeighbor_sum_const]
  have hinner (firstLeft firstRight : HammingWord dimension) :
      (∑ secondLeft : HammingWord dimension,
        ∑ secondRight : HammingWord dimension,
          if hammingDist firstLeft firstRight ≤ radius ∧
              hammingDist secondLeft secondRight ≤ radius then
            if firstLeft = secondLeft then weight else 0
          else 0) =
        if hammingDist firstLeft firstRight ≤ radius then
          ((∑ distance ∈ Finset.range (radius + 1),
            dimension.choose distance : ℕ) : ℝ) * weight
        else 0 := by
    by_cases hedge : hammingDist firstLeft firstRight ≤ radius
    · simp only [hedge, true_and, if_true]
      exact hshared firstLeft
    · simp [hedge]
  simp_rw [hinner]
  rw [hammingWordEdge_sum_const]
  ring

noncomputable def hammingExpectedRetainedEdgeCount
    (dimension radius : ℕ) : ℝ :=
  ∑ left : HammingWord dimension,
    ∑ right : HammingWord dimension,
      if hammingDist left right ≤ radius then
        (hammingRetentionMeasure dimension).real
          {retained : Set (Bool × HammingWord dimension) |
            (false, left) ∈ retained ∧ (true, right) ∈ retained}
      else 0

theorem hammingExpectedRetainedEdgeCount_eq
    (dimension radius : ℕ) :
    hammingExpectedRetainedEdgeCount dimension radius =
      hammingRetentionProbability dimension ^ 2 *
        ((2 ^ dimension : ℕ) : ℝ) *
        ((∑ distance ∈ Finset.range (radius + 1),
          dimension.choose distance : ℕ) : ℝ) := by
  have hammingRetentionMeasure_real_contains_pair
      (dimension : ℕ)
      (first second : Bool × HammingWord dimension)
      (hdistinct : first ≠ second) :
      (hammingRetentionMeasure dimension).real
        {retained : Set (Bool × HammingWord dimension) |
          first ∈ retained ∧ second ∈ retained} =
        hammingRetentionProbability dimension ^ 2 := by
    classical
    simpa [hdistinct] using
      hammingRetentionMeasure_real_contains_finset dimension {first, second}
  classical
  have hpair (left right : HammingWord dimension) :
      (hammingRetentionMeasure dimension).real
          {retained : Set (Bool × HammingWord dimension) |
            (false, left) ∈ retained ∧ (true, right) ∈ retained} =
        hammingRetentionProbability dimension ^ 2 :=
    hammingRetentionMeasure_real_contains_pair
      dimension (false, left) (true, right) (by simp)
  unfold hammingExpectedRetainedEdgeCount
  simp_rw [hpair]
  simpa [mul_assoc, mul_comm, mul_left_comm] using
    hammingWordEdge_sum_const dimension radius
      (hammingRetentionProbability dimension ^ 2)

noncomputable def hammingExpectedRetainedEdgeSquare
    (dimension radius : ℕ) : ℝ :=
  ∑ firstLeft : HammingWord dimension,
    ∑ firstRight : HammingWord dimension,
      ∑ secondLeft : HammingWord dimension,
        ∑ secondRight : HammingWord dimension,
          if hammingDist firstLeft firstRight ≤ radius ∧
              hammingDist secondLeft secondRight ≤ radius then
            (hammingRetentionMeasure dimension).real
              {retained : Set (Bool × HammingWord dimension) |
                (false, firstLeft) ∈ retained ∧
                (true, firstRight) ∈ retained ∧
                (false, secondLeft) ∈ retained ∧
                (true, secondRight) ∈ retained}
          else 0

noncomputable def retainedHammingWordEdges
    (dimension radius : ℕ)
    (retained : Set (Bool × HammingWord dimension)) :
    Finset (HammingWord dimension × HammingWord dimension) := by
  classical
  exact Finset.univ.filter (fun edge =>
    hammingDist edge.1 edge.2 ≤ radius ∧
      (false, edge.1) ∈ retained ∧ (true, edge.2) ∈ retained)

noncomputable def hammingRetainedEdgeCount
    (dimension radius : ℕ)
    (retained : Set (Bool × HammingWord dimension)) : ℝ := by
  classical
  exact
    ∑ left : HammingWord dimension,
      ∑ right : HammingWord dimension,
        if hammingDist left right ≤ radius ∧
            (false, left) ∈ retained ∧ (true, right) ∈ retained
        then 1 else 0

theorem hammingRetainedEdgeCount_integral_eq
    (dimension radius : ℕ) :
    (∫ retained,
      hammingRetainedEdgeCount dimension radius retained
        ∂hammingRetentionMeasure dimension) =
      hammingExpectedRetainedEdgeCount dimension radius := by
  classical
  unfold hammingRetainedEdgeCount hammingExpectedRetainedEdgeCount
  rw [MeasureTheory.integral_finsetSum Finset.univ
    (fun left _ => hammingRetentionMeasure_integrable dimension
      (fun retained : Set (Bool × HammingWord dimension) =>
        ∑ right : HammingWord dimension,
          if hammingDist left right ≤ radius ∧
              (false, left) ∈ retained ∧ (true, right) ∈ retained
          then (1 : ℝ) else 0))]
  apply Finset.sum_congr rfl
  intro left _
  rw [MeasureTheory.integral_finsetSum Finset.univ
    (fun right _ => hammingRetentionMeasure_integrable dimension
      (fun retained : Set (Bool × HammingWord dimension) =>
        if hammingDist left right ≤ radius ∧
            (false, left) ∈ retained ∧ (true, right) ∈ retained
        then (1 : ℝ) else 0))]
  apply Finset.sum_congr rfl
  intro right _
  by_cases hedge : hammingDist left right ≤ radius
  · simp only [hedge, true_and, if_true]
    rw [hammingRetentionMeasure_integral_eq_sum,
      hammingRetentionMeasure_real_event_eq_sum]
    apply Finset.sum_congr rfl
    intro retained _
    by_cases hretained :
        (false, left) ∈ retained ∧ (true, right) ∈ retained <;>
      simp [hretained]
  · simp [hedge]

def retainedHammingHost (dimension radius : ℕ)
    (retained : Set (Bool × HammingWord dimension)) : SimpleGraph retained :=
  (hammingHost dimension radius).induce retained

theorem pairGraphCopy_child_layer_side_eq
    {baseSize depth dimension radius : ℕ}
    (retained : Set (Bool × HammingWord dimension))
    (copy : SimpleGraph.Copy
      (pairParentSystem baseSize depth).graph
      (retainedHammingHost dimension radius retained))
    (layer : ℕ)
    (hlayer : layer + 1 < depth + 1)
    (first second : PairLayer baseSize (layer + 1)) :
    (copy
      (pairLayerEmbedding baseSize depth (layer + 1)
        hlayer first)).val.1 =
    (copy
      (pairLayerEmbedding baseSize depth (layer + 1)
        hlayer second)).val.1 := by
  have pairGraphCopy_layer_side_eq
      {baseSize depth dimension radius : ℕ}
      (retained : Set (Bool × HammingWord dimension))
      (copy : SimpleGraph.Copy
        (pairParentSystem baseSize depth).graph
        (retainedHammingHost dimension radius retained))
      (layer : ℕ)
      (hlayer : layer + 1 < depth + 1)
      (first second : PairLayer baseSize layer) :
      (copy
        (pairLayerEmbedding baseSize depth layer (by omega) first)).val.1 =
      (copy
        (pairLayerEmbedding baseSize depth layer (by omega) second)).val.1 := by
    classical
    by_cases hequal : first = second
    · subst second
      rfl
    · let bridge : PairLayer baseSize (layer + 1) :=
        ⟨{first, second}, Finset.card_pair hequal⟩
      have hfirst_source :
          (pairParentSystem baseSize depth).graph.Adj
            (pairLayerEmbedding baseSize depth (layer + 1) hlayer bridge)
            (pairLayerEmbedding baseSize depth layer (by omega) first) :=
        pairGraph_parent_child_adj baseSize depth layer hlayer bridge first
          (by simp [bridge])
      have hsecond_source :
          (pairParentSystem baseSize depth).graph.Adj
            (pairLayerEmbedding baseSize depth (layer + 1) hlayer bridge)
            (pairLayerEmbedding baseSize depth layer (by omega) second) :=
        pairGraph_parent_child_adj baseSize depth layer hlayer bridge second
          (by simp [bridge])
      have hfirst_edge := copy.toHom.map_rel hfirst_source
      have hsecond_edge := copy.toHom.map_rel hsecond_source
      change
        (hammingHost dimension radius).Adj
          (copy
            (pairLayerEmbedding baseSize depth (layer + 1)
              hlayer bridge)).val
          (copy
            (pairLayerEmbedding baseSize depth layer
              (by omega) first)).val at hfirst_edge
      change
        (hammingHost dimension radius).Adj
          (copy
            (pairLayerEmbedding baseSize depth (layer + 1)
              hlayer bridge)).val
          (copy
            (pairLayerEmbedding baseSize depth layer
              (by omega) second)).val at hsecond_edge
      have hfirst_side :=
        (hammingHost_adj_iff dimension radius _ _).mp hfirst_edge
      have hsecond_side :=
        (hammingHost_adj_iff dimension radius _ _).mp hsecond_edge
      cases hbridge :
        (copy
          (pairLayerEmbedding baseSize depth (layer + 1)
            hlayer bridge)).val.1 <;>
        cases hfirst :
          (copy
            (pairLayerEmbedding baseSize depth layer
              (by omega) first)).val.1 <;>
        cases hsecond :
          (copy
            (pairLayerEmbedding baseSize depth layer
              (by omega) second)).val.1 <;>
        simp_all
  classical
  have hfirst_nonempty : first.val.Nonempty := by
    apply Finset.card_pos.mp
    rw [first.property]
    norm_num
  have hsecond_nonempty : second.val.Nonempty := by
    apply Finset.card_pos.mp
    rw [second.property]
    norm_num
  obtain ⟨firstParent, hfirstParent⟩ := hfirst_nonempty
  obtain ⟨secondParent, hsecondParent⟩ := hsecond_nonempty
  have hparent_side := pairGraphCopy_layer_side_eq
    retained copy layer hlayer firstParent secondParent
  have hfirst_edge := copy.toHom.map_rel
    (pairGraph_parent_child_adj
      baseSize depth layer hlayer first firstParent hfirstParent)
  have hsecond_edge := copy.toHom.map_rel
    (pairGraph_parent_child_adj
      baseSize depth layer hlayer second secondParent hsecondParent)
  change
    (hammingHost dimension radius).Adj
      (copy
        (pairLayerEmbedding baseSize depth (layer + 1)
          hlayer first)).val
      (copy
        (pairLayerEmbedding baseSize depth layer
          (by omega) firstParent)).val at hfirst_edge
  change
    (hammingHost dimension radius).Adj
      (copy
        (pairLayerEmbedding baseSize depth (layer + 1)
          hlayer second)).val
      (copy
        (pairLayerEmbedding baseSize depth layer
          (by omega) secondParent)).val at hsecond_edge
  have hfirst_side :=
    (hammingHost_adj_iff dimension radius _ _).mp hfirst_edge
  have hsecond_side :=
    (hammingHost_adj_iff dimension radius _ _).mp hsecond_edge
  cases hfirst :
    (copy
      (pairLayerEmbedding baseSize depth (layer + 1)
        hlayer first)).val.1 <;>
    cases hsecond :
      (copy
        (pairLayerEmbedding baseSize depth (layer + 1)
          hlayer second)).val.1 <;>
    cases hfirstParent_side :
      (copy
        (pairLayerEmbedding baseSize depth layer
          (by omega) firstParent)).val.1 <;>
    cases hsecondParent_side :
      (copy
        (pairLayerEmbedding baseSize depth layer
          (by omega) secondParent)).val.1 <;>
    simp_all

noncomputable def pairGraphCopyParentWords
    {baseSize depth dimension radius : ℕ}
    (retained : Set (Bool × HammingWord dimension))
    (copy : SimpleGraph.Copy
      (pairParentSystem baseSize depth).graph
      (retainedHammingHost dimension radius retained))
    (layer : Fin depth) :
    Fin (Fintype.card (PairLayer baseSize layer.val)) →
      HammingWord dimension :=
  fun parent =>
    (copy
      (pairLayerEmbedding baseSize depth layer.val (by omega)
        ((pairLayerFinEquiv baseSize layer.val).symm parent))).val.2

noncomputable def pairGraphCopyChildWords
    {baseSize depth dimension radius : ℕ}
    (retained : Set (Bool × HammingWord dimension))
    (copy : SimpleGraph.Copy
      (pairParentSystem baseSize depth).graph
      (retainedHammingHost dimension radius retained))
    (layer : Fin depth) :
    PairLayer (Fintype.card (PairLayer baseSize layer.val)) 1 →
      HammingWord dimension :=
  fun pair =>
    (copy
      (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
        ((pairLayerPairEquiv baseSize layer.val) pair))).val.2

noncomputable def pairGraphCopyChildSide
    {baseSize depth dimension radius : ℕ}
    (retained : Set (Bool × HammingWord dimension))
    (copy : SimpleGraph.Copy
      (pairParentSystem baseSize depth).graph
      (retainedHammingHost dimension radius retained))
    (layer : Fin depth)
    (reference :
      PairLayer (Fintype.card (PairLayer baseSize layer.val)) 1) : Bool :=
  (copy
    (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
      ((pairLayerPairEquiv baseSize layer.val) reference))).val.1

noncomputable def pairGraphCopyLayerPotential
    {baseSize depth dimension radius : ℕ}
    (retained : Set (Bool × HammingWord dimension))
    (copy : SimpleGraph.Copy
      (pairParentSystem baseSize depth).graph
      (retainedHammingHost dimension radius retained))
    (layer : Fin (depth + 1)) : ℝ :=
  (∑ coordinate : Fin dimension,
    binaryEntropy
      (((booleanWordOnes
        (fun vertex : PairLayer baseSize layer.val =>
          (copy
            (pairLayerEmbedding baseSize depth layer.val layer.isLt
              vertex)).val.2 coordinate)).card : ℝ) /
        (Fintype.card (PairLayer baseSize layer.val) : ℝ))) /
    (dimension : ℝ)

end HammingHostAndExclusion

section MainTheorem

noncomputable def manuscriptHammingRadius (dimension : ℕ) : ℕ :=
  ⌊tau * (dimension : ℝ)⌋₊

theorem manuscriptHammingRadius_le (dimension : ℕ) :
    (manuscriptHammingRadius dimension : ℝ) ≤
      tau * (dimension : ℝ) := by
  unfold manuscriptHammingRadius
  exact Nat.floor_le
    (mul_nonneg tau_pos.le (Nat.cast_nonneg dimension))

noncomputable def sampledHammingEdgeEntropyRate : ℝ :=
  (1 - 2 * midpointBeta) * Real.log 2 + Real.binEntropy tau

theorem eventually_manuscriptExpectedRetainedEdge_entropy_lower
    (loss : ℝ) (hloss : 0 < loss) :
    ∀ᶠ dimension : ℕ in atTop,
      Real.exp
          ((dimension : ℝ) *
            (sampledHammingEdgeEntropyRate - loss)) /
          ((dimension + 1 : ℕ) : ℝ) ≤
        hammingExpectedRetainedEdgeCount dimension
          (manuscriptHammingRadius dimension) := by
  have binomialProbabilityMass_nonneg
      (trialCount successCount : ℕ) (probability : ℝ)
      (hprobability_zero : 0 ≤ probability)
      (hprobability_one : probability ≤ 1) :
      0 ≤ binomialProbabilityMass trialCount successCount probability := by
    unfold binomialProbabilityMass
    have hcomplement : 0 ≤ 1 - probability := by linarith
    positivity
  have binomialProbabilityMass_succ_mul
      (trialCount successCount : ℕ) (probability : ℝ)
      (hcount : successCount < trialCount) :
      binomialProbabilityMass trialCount (successCount + 1) probability *
          ((successCount + 1 : ℕ) : ℝ) * (1 - probability) =
        binomialProbabilityMass trialCount successCount probability *
          ((trialCount - successCount : ℕ) : ℝ) * probability := by
    have hc :
        ((trialCount.choose (successCount + 1) : ℕ) : ℝ) *
            ((successCount + 1 : ℕ) : ℝ) =
          ((trialCount.choose successCount : ℕ) : ℝ) *
            ((trialCount - successCount : ℕ) : ℝ) := by
      exact_mod_cast Nat.choose_succ_right_eq trialCount successCount
    have hs : trialCount - successCount =
        (trialCount - (successCount + 1)) + 1 := by omega
    unfold binomialProbabilityMass
    rw [hs] at hc ⊢
    simp only [pow_succ]
    linear_combination
      (probability ^ successCount *
        (1 - probability) ^ (trialCount - (successCount + 1)) *
        probability * (1 - probability)) * hc
  have hammingRetentionProbability_sq_mul_wordCount_eq_exp
      (dimension : ℕ) :
      hammingRetentionProbability dimension ^ 2 *
          ((2 ^ dimension : ℕ) : ℝ) =
        Real.exp
          ((1 - 2 * midpointBeta) * (dimension : ℝ) * Real.log 2) := by
    have hwords : ((2 ^ dimension : ℕ) : ℝ) = Real.exp ((dimension : ℝ) * Real.log 2) := by
      rw [Real.exp_nat_mul, Real.exp_log (by norm_num)]
      norm_cast
    unfold hammingRetentionProbability
    rw [hwords, ← Real.exp_nat_mul, ← Real.exp_add]
    congr 1
    push_cast
    ring
  have manuscriptHammingBall_card_entropy_lower
      (dimension : ℕ) (word : HammingWord dimension) :
      Real.exp
          ((dimension : ℝ) *
            Real.binEntropy
              ((manuscriptHammingRadius dimension : ℝ) /
                (dimension : ℝ))) /
          ((dimension + 1 : ℕ) : ℝ) ≤
        ((hammingBall dimension
          (manuscriptHammingRadius dimension) word).card : ℝ) := by
    have exp_binary_entropy_div_le_choose
        (trialCount successCount : ℕ)
        (hcount : successCount ≤ trialCount) :
        Real.exp
            ((trialCount : ℝ) *
              Real.binEntropy
                ((successCount : ℝ) / (trialCount : ℝ))) /
            ((trialCount + 1 : ℕ) : ℝ) ≤
          (trialCount.choose successCount : ℝ) := by
      have binomialProbabilityMass_mode_ge_inverse
          (trialCount mode : ℕ) (hmode : mode ≤ trialCount) :
          1 / ((trialCount + 1 : ℕ) : ℝ) ≤
            binomialProbabilityMass trialCount mode
              ((mode : ℝ) / (trialCount : ℝ)) := by
        have binomialProbabilityMass_le_mode
            (trialCount mode successCount : ℕ)
            (hmode : mode ≤ trialCount)
            (hsuccess : successCount ≤ trialCount) :
            binomialProbabilityMass trialCount successCount
                ((mode : ℝ) / (trialCount : ℝ)) ≤
              binomialProbabilityMass trialCount mode
                ((mode : ℝ) / (trialCount : ℝ)) := by
          have binomialProbabilityMass_le_succ_of_lt_mode
              (trialCount mode successCount : ℕ)
              (hmode : mode < trialCount)
              (hcount : successCount < mode) :
              binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) ≤
                binomialProbabilityMass trialCount (successCount + 1)
                  ((mode : ℝ) / (trialCount : ℝ)) := by
            have binomialModeRatio_le_of_lt
                (trialCount mode successCount : ℕ)
                (hmode : mode ≤ trialCount)
                (hcount : successCount < mode) :
                ((successCount + 1 : ℕ) : ℝ) *
                    (1 - (mode : ℝ) / (trialCount : ℝ)) ≤
                  ((trialCount - successCount : ℕ) : ℝ) *
                    ((mode : ℝ) / (trialCount : ℝ)) := by
              have htrials : 0 < trialCount := by omega
              have htrials_real : 0 < (trialCount : ℝ) := by exact_mod_cast htrials
              have hcomplement :
                  1 - (mode : ℝ) / (trialCount : ℝ) =
                    ((trialCount - mode : ℕ) : ℝ) / (trialCount : ℝ) := by
                rw [Nat.cast_sub hmode]
                field_simp
              rw [hcomplement, ← mul_div_assoc, ← mul_div_assoc,
                div_le_div_iff_of_pos_right htrials_real,
                Nat.cast_sub hmode,
                Nat.cast_sub (show successCount ≤ trialCount by omega),
                Nat.cast_add, Nat.cast_one]
              have hgap : 0 ≤ (mode : ℝ) - (successCount : ℝ) - 1 := by
                have hcast : (successCount : ℝ) + 1 ≤ (mode : ℝ) := by
                  exact_mod_cast (show successCount + 1 ≤ mode by omega)
                linarith
              have hproduct := mul_nonneg (Nat.cast_nonneg trialCount) hgap
              have hmode_nonneg : 0 ≤ (mode : ℝ) := Nat.cast_nonneg mode
              nlinarith
            have htrials : 0 < trialCount := by omega
            have htrials_real : 0 < (trialCount : ℝ) := by exact_mod_cast htrials
            have hprobability_zero :
                0 ≤ (mode : ℝ) / (trialCount : ℝ) := by positivity
            have hprobability_one : (mode : ℝ) / (trialCount : ℝ) < 1 := by
              apply (div_lt_one htrials_real).mpr
              exact_mod_cast hmode
            have hscale :
                0 < ((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ)) := by
              positivity
            have hmass := binomialProbabilityMass_nonneg
              trialCount successCount ((mode : ℝ) / (trialCount : ℝ))
              hprobability_zero hprobability_one.le
            have hratio := binomialModeRatio_le_of_lt
              trialCount mode successCount hmode.le hcount
            have hidentity := binomialProbabilityMass_succ_mul
              trialCount successCount ((mode : ℝ) / (trialCount : ℝ))
              (show successCount < trialCount by omega)
            apply le_of_mul_le_mul_right (a :=
              ((successCount + 1 : ℕ) : ℝ) *
                (1 - (mode : ℝ) / (trialCount : ℝ)))
              (a0 := hscale)
            calc
              binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ))) ≤
                binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((trialCount - successCount : ℕ) : ℝ) *
                  ((mode : ℝ) / (trialCount : ℝ))) :=
                  mul_le_mul_of_nonneg_left hratio hmass
              _ = binomialProbabilityMass trialCount (successCount + 1)
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ))) := by nlinarith [hidentity]
          have binomialProbabilityMass_succ_le_of_ge_mode
              (trialCount mode successCount : ℕ)
              (hmode : mode < trialCount)
              (hcount : mode ≤ successCount)
              (hsuccess : successCount < trialCount) :
              binomialProbabilityMass trialCount (successCount + 1)
                  ((mode : ℝ) / (trialCount : ℝ)) ≤
                binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) := by
            have binomialModeRatio_le_of_ge
                (trialCount mode successCount : ℕ)
                (htrials : 0 < trialCount)
                (hmode : mode ≤ trialCount)
                (hcount : mode ≤ successCount)
                (hsuccess : successCount < trialCount) :
                ((trialCount - successCount : ℕ) : ℝ) *
                    ((mode : ℝ) / (trialCount : ℝ)) ≤
                  ((successCount + 1 : ℕ) : ℝ) *
                    (1 - (mode : ℝ) / (trialCount : ℝ)) := by
              have htrials_real : 0 < (trialCount : ℝ) := by exact_mod_cast htrials
              have hcomplement :
                  1 - (mode : ℝ) / (trialCount : ℝ) =
                    ((trialCount - mode : ℕ) : ℝ) / (trialCount : ℝ) := by
                rw [Nat.cast_sub hmode]
                field_simp
              rw [hcomplement, ← mul_div_assoc, ← mul_div_assoc,
                div_le_div_iff_of_pos_right htrials_real,
                Nat.cast_sub (Nat.le_of_lt hsuccess),
                Nat.cast_sub hmode,
                Nat.cast_add, Nat.cast_one]
              have hgap :
                  0 ≤ (successCount : ℝ) - (mode : ℝ) := by simp_all
              have hproduct := mul_nonneg (Nat.cast_nonneg trialCount) hgap
              have hmode_le : (mode : ℝ) ≤ (trialCount : ℝ) := by exact_mod_cast hmode
              nlinarith
            have htrials : 0 < trialCount := by omega
            have htrials_real : 0 < (trialCount : ℝ) := by exact_mod_cast htrials
            have hprobability_zero :
                0 ≤ (mode : ℝ) / (trialCount : ℝ) := by positivity
            have hprobability_one : (mode : ℝ) / (trialCount : ℝ) < 1 := by
              apply (div_lt_one htrials_real).mpr
              exact_mod_cast hmode
            have hscale :
                0 < ((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ)) := by
              positivity
            have hmass := binomialProbabilityMass_nonneg
              trialCount successCount ((mode : ℝ) / (trialCount : ℝ))
              hprobability_zero hprobability_one.le
            have hratio := binomialModeRatio_le_of_ge
              trialCount mode successCount htrials hmode.le hcount hsuccess
            have hidentity := binomialProbabilityMass_succ_mul
              trialCount successCount ((mode : ℝ) / (trialCount : ℝ)) hsuccess
            apply le_of_mul_le_mul_right (a :=
              ((successCount + 1 : ℕ) : ℝ) *
                (1 - (mode : ℝ) / (trialCount : ℝ)))
              (a0 := hscale)
            calc
              binomialProbabilityMass trialCount (successCount + 1)
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ))) =
                binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((trialCount - successCount : ℕ) : ℝ) *
                  ((mode : ℝ) / (trialCount : ℝ))) := by nlinarith [hidentity]
              _ ≤ binomialProbabilityMass trialCount successCount
                  ((mode : ℝ) / (trialCount : ℝ)) *
                (((successCount + 1 : ℕ) : ℝ) *
                  (1 - (mode : ℝ) / (trialCount : ℝ))) :=
                    mul_le_mul_of_nonneg_left hratio hmass
          by_cases htrials : trialCount = 0
          · subst trialCount
            have hmode_zero : mode = 0 := by omega
            have hsuccess_zero : successCount = 0 := by omega
            subst mode
            subst successCount
            exact le_rfl
          by_cases hmode_zero : mode = 0
          · subst mode
            by_cases hsuccess_zero : successCount = 0
            · subst successCount
              exact le_rfl
            · simp [binomialProbabilityMass, hsuccess_zero]
          by_cases hmode_full : mode = trialCount
          · subst mode
            have htrials_real : (trialCount : ℝ) ≠ 0 := by exact_mod_cast htrials
            rw [div_self htrials_real]
            by_cases hsuccess_full : successCount = trialCount
            · subst successCount
              exact le_rfl
            · have hpositive : 0 < trialCount - successCount := by omega
              simp [binomialProbabilityMass, hpositive.ne']
          have hmode_lt : mode < trialCount := by omega
          let probability : ℝ := (mode : ℝ) / (trialCount : ℝ)
          have hstep_up (index : ℕ) (hindex : index < mode) :
              binomialProbabilityMass trialCount index probability ≤
                binomialProbabilityMass trialCount (index + 1) probability := by grind
          have hstep_down (index : ℕ)
              (hindex_mode : mode ≤ index)
              (hindex_trials : index < trialCount) :
              binomialProbabilityMass trialCount (index + 1) probability ≤
                binomialProbabilityMass trialCount index probability := by grind
          by_cases hbelow : successCount ≤ mode
          · have hwalk (index : ℕ) (hindex : successCount ≤ index) :
                index ≤ mode →
                  binomialProbabilityMass trialCount successCount probability ≤
                    binomialProbabilityMass trialCount index probability := by
              induction index, hindex using Nat.le_induction with
              | base =>
                intro _
                exact le_rfl
              | succ index hindex hinduction =>
                intro hupper
                exact (hinduction (by omega)).trans
                  (hstep_up index (by omega))
            exact hwalk mode hbelow (le_refl mode)
          · have habove : mode ≤ successCount := by omega
            have hwalk (index : ℕ) (hindex : mode ≤ index) :
                index ≤ trialCount →
                  binomialProbabilityMass trialCount index probability ≤
                    binomialProbabilityMass trialCount mode probability := by
              induction index, hindex using Nat.le_induction with
              | base =>
                intro _
                exact le_rfl
              | succ index hindex hinduction =>
                intro hupper
                exact (hstep_down index hindex (by omega)).trans
                  (hinduction (by omega))
            exact hwalk successCount habove hsuccess
        have binomialProbabilityMass_sum_eq_one
            (trialCount : ℕ) (probability : ℝ) :
            (∑ successCount ∈ Finset.range (trialCount + 1),
              binomialProbabilityMass trialCount successCount probability) = 1 := by
          unfold binomialProbabilityMass
          calc
            (∑ successCount ∈ Finset.range (trialCount + 1),
              (trialCount.choose successCount : ℝ) *
                probability ^ successCount *
                (1 - probability) ^ (trialCount - successCount)) =
              ∑ successCount ∈ Finset.range (trialCount + 1),
                probability ^ successCount *
                  (1 - probability) ^ (trialCount - successCount) *
                  (trialCount.choose successCount : ℝ) := by
                    apply Finset.sum_congr rfl
                    intro successCount _
                    ring
            _ = (probability + (1 - probability)) ^ trialCount :=
              (add_pow probability (1 - probability) trialCount).symm
            _ = 1 := by
              rw [show probability + (1 - probability) = 1 by ring]
              simp
        have hdenominator : 0 < ((trialCount + 1 : ℕ) : ℝ) := by positivity
        apply (div_le_iff₀ hdenominator).mpr
        calc
          (1 : ℝ) =
            ∑ successCount ∈ Finset.range (trialCount + 1),
              binomialProbabilityMass trialCount successCount
                ((mode : ℝ) / (trialCount : ℝ)) :=
            (binomialProbabilityMass_sum_eq_one
              trialCount ((mode : ℝ) / (trialCount : ℝ))).symm
          _ ≤ ∑ _successCount ∈ Finset.range (trialCount + 1),
              binomialProbabilityMass trialCount mode
                ((mode : ℝ) / (trialCount : ℝ)) := by
            apply Finset.sum_le_sum
            intro successCount hsuccess
            apply binomialProbabilityMass_le_mode
              trialCount mode successCount hmode
            have hbound := Finset.mem_range.mp hsuccess
            omega
          _ = binomialProbabilityMass trialCount mode
                ((mode : ℝ) / (trialCount : ℝ)) *
              ((trialCount + 1 : ℕ) : ℝ) := by
            simp [nsmul_eq_mul]
            ring
      have binomialProbabilityMass_mode_mul_exp_entropy
          (trialCount mode : ℕ) (hmode : mode ≤ trialCount) :
          binomialProbabilityMass trialCount mode
              ((mode : ℝ) / (trialCount : ℝ)) *
            Real.exp
              ((trialCount : ℝ) *
                Real.binEntropy ((mode : ℝ) / (trialCount : ℝ))) =
            (trialCount.choose mode : ℝ) := by
        by_cases hzero : mode = 0
        · subst mode
          simp [binomialProbabilityMass]
        by_cases hfull : mode = trialCount
        · subst mode
          have htrials : (trialCount : ℝ) ≠ 0 := by exact_mod_cast hzero
          simp [binomialProbabilityMass, htrials]
        have hmode_pos : 0 < mode := Nat.pos_of_ne_zero hzero
        have hmode_lt : mode < trialCount :=
          lt_of_le_of_ne hmode hfull
        have htrials : 0 < trialCount := by omega
        have htrials_real : 0 < (trialCount : ℝ) := by exact_mod_cast htrials
        let probability : ℝ := (mode : ℝ) / (trialCount : ℝ)
        have hprobability : 0 < probability := by positivity
        have hprobability_one : probability < 1 := by
          dsimp [probability]
          apply (div_lt_one htrials_real).mpr
          exact_mod_cast hmode_lt
        have hcomplement : 0 < 1 - probability := by linarith
        have hproduct : 0 < probability ^ mode * (1 - probability) ^ (trialCount - mode) := by
          positivity
        have hentropy :
            (trialCount : ℝ) * Real.binEntropy probability =
              -(mode : ℝ) * Real.log probability -
                ((trialCount - mode : ℕ) : ℝ) *
                  Real.log (1 - probability) := by
          unfold Real.binEntropy
          rw [Real.log_inv, Real.log_inv, Nat.cast_sub hmode]
          dsimp [probability]
          field_simp [htrials_real.ne']
          ring
        have hlog :
            Real.log
              (probability ^ mode *
                (1 - probability) ^ (trialCount - mode)) +
              (trialCount : ℝ) * Real.binEntropy probability = 0 := by
          rw [Real.log_mul
            (pow_pos hprobability mode).ne'
            (pow_pos hcomplement (trialCount - mode)).ne',
            Real.log_pow, Real.log_pow, hentropy]
          ring
        change
          binomialProbabilityMass trialCount mode probability *
            Real.exp ((trialCount : ℝ) * Real.binEntropy probability) =
            (trialCount.choose mode : ℝ)
        calc
          binomialProbabilityMass trialCount mode probability *
              Real.exp ((trialCount : ℝ) * Real.binEntropy probability) =
            (trialCount.choose mode : ℝ) *
              (probability ^ mode *
                (1 - probability) ^ (trialCount - mode) *
                Real.exp ((trialCount : ℝ) * Real.binEntropy probability)) := by
              unfold binomialProbabilityMass
              ring
          _ = (trialCount.choose mode : ℝ) *
              Real.exp
                (Real.log
                    (probability ^ mode *
                      (1 - probability) ^ (trialCount - mode)) +
                  (trialCount : ℝ) * Real.binEntropy probability) := by
                rw [Real.exp_add, Real.exp_log hproduct]
          _ = (trialCount.choose mode : ℝ) := by
            rw [hlog]
            simp
      have hmode := binomialProbabilityMass_mode_ge_inverse
        trialCount successCount hcount
      have hexponential :
          0 ≤ Real.exp
            ((trialCount : ℝ) *
              Real.binEntropy
                ((successCount : ℝ) / (trialCount : ℝ))) :=
        (Real.exp_pos _).le
      calc
        Real.exp
            ((trialCount : ℝ) *
              Real.binEntropy
                ((successCount : ℝ) / (trialCount : ℝ))) /
            ((trialCount + 1 : ℕ) : ℝ) =
          (1 / ((trialCount + 1 : ℕ) : ℝ)) *
            Real.exp
              ((trialCount : ℝ) *
                Real.binEntropy
                  ((successCount : ℝ) / (trialCount : ℝ))) := by
            ring
        _ ≤ binomialProbabilityMass trialCount successCount
              ((successCount : ℝ) / (trialCount : ℝ)) *
            Real.exp
              ((trialCount : ℝ) *
                Real.binEntropy
                  ((successCount : ℝ) / (trialCount : ℝ))) :=
          mul_le_mul_of_nonneg_right hmode hexponential
        _ = (trialCount.choose successCount : ℝ) :=
          binomialProbabilityMass_mode_mul_exp_entropy
            trialCount successCount hcount
    have hammingBall_card_ge_boundary_binomial
        (dimension radius : ℕ)
        (word : HammingWord dimension) :
        dimension.choose radius ≤ (hammingBall dimension radius word).card := by
      rw [hammingBall_card]
      apply Finset.single_le_sum
        (s := Finset.range (radius + 1))
        (f := fun distance => dimension.choose distance)
      · intro distance _
        exact Nat.zero_le _
      · simp
    have manuscriptHammingRadius_le_dimension (dimension : ℕ) :
        manuscriptHammingRadius dimension ≤ dimension := by
      have hradius := manuscriptHammingRadius_le dimension
      have hdimension : 0 ≤ (dimension : ℝ) := Nat.cast_nonneg dimension
      have htau := tau_lt_one_half
      have hreal : (manuscriptHammingRadius dimension : ℝ) ≤ (dimension : ℝ) := by nlinarith
      exact_mod_cast hreal
    calc
      Real.exp
          ((dimension : ℝ) *
            Real.binEntropy
              ((manuscriptHammingRadius dimension : ℝ) /
                (dimension : ℝ))) /
          ((dimension + 1 : ℕ) : ℝ) ≤
        (dimension.choose (manuscriptHammingRadius dimension) : ℝ) :=
          exp_binary_entropy_div_le_choose dimension
            (manuscriptHammingRadius dimension)
            (manuscriptHammingRadius_le_dimension dimension)
      _ ≤ ((hammingBall dimension
          (manuscriptHammingRadius dimension) word).card : ℝ) := by
        exact_mod_cast hammingBall_card_ge_boundary_binomial
          dimension (manuscriptHammingRadius dimension) word
  have eventually_manuscriptHammingRadius_binEntropy_ge
      (loss : ℝ) (hloss : 0 < loss) :
      ∀ᶠ dimension : ℕ in atTop,
        Real.binEntropy tau - loss ≤
          Real.binEntropy
            ((manuscriptHammingRadius dimension : ℝ) /
              (dimension : ℝ)) := by
    have manuscriptHammingRadius_binEntropy_tendsto :
        Tendsto
          (fun dimension : ℕ =>
            Real.binEntropy
              ((manuscriptHammingRadius dimension : ℝ) / (dimension : ℝ)))
          atTop (𝓝 (Real.binEntropy tau)) := by
      have manuscriptHammingRadius_ratio_tendsto :
          Tendsto
            (fun dimension : ℕ =>
              (manuscriptHammingRadius dimension : ℝ) / (dimension : ℝ))
            atTop (𝓝 tau) := by
        unfold manuscriptHammingRadius
        exact
          (tendsto_nat_floor_mul_div_atTop (R := ℝ) tau_pos.le).comp
            tendsto_natCast_atTop_atTop
      exact Real.binEntropy_continuous.continuousAt.tendsto.comp
        manuscriptHammingRadius_ratio_tendsto
    have hneighborhood : Set.Ioi (Real.binEntropy tau - loss) ∈ 𝓝 (Real.binEntropy tau) :=
      Ioi_mem_nhds (by linarith)
    filter_upwards
      [manuscriptHammingRadius_binEntropy_tendsto hneighborhood]
      with dimension hdimension
    exact (show Real.binEntropy tau - loss <
      Real.binEntropy
        ((manuscriptHammingRadius dimension : ℝ) /
          (dimension : ℝ)) from hdimension).le
  filter_upwards
    [eventually_manuscriptHammingRadius_binEntropy_ge loss hloss]
    with dimension hentropy
  have hdegree :
      Real.exp
          ((dimension : ℝ) *
            Real.binEntropy
              ((manuscriptHammingRadius dimension : ℝ) /
                (dimension : ℝ))) /
          ((dimension + 1 : ℕ) : ℝ) ≤
        ((∑ distance ∈
          Finset.range (manuscriptHammingRadius dimension + 1),
          dimension.choose distance : ℕ) : ℝ) := by
    have hball := manuscriptHammingBall_card_entropy_lower dimension
      (fun _ : Fin dimension => false)
    rw [hammingBall_card] at hball
    exact hball
  calc
    Real.exp
        ((dimension : ℝ) *
          (sampledHammingEdgeEntropyRate - loss)) /
        ((dimension + 1 : ℕ) : ℝ) =
      (hammingRetentionProbability dimension ^ 2 *
        ((2 ^ dimension : ℕ) : ℝ)) *
        (Real.exp
          ((dimension : ℝ) * (Real.binEntropy tau - loss)) /
          ((dimension + 1 : ℕ) : ℝ)) := by
        rw [hammingRetentionProbability_sq_mul_wordCount_eq_exp,
          ← mul_div_assoc, ← Real.exp_add]
        congr 1
        unfold sampledHammingEdgeEntropyRate
        ring_nf
    _ ≤ (hammingRetentionProbability dimension ^ 2 *
        ((2 ^ dimension : ℕ) : ℝ)) *
        (Real.exp
          ((dimension : ℝ) *
            Real.binEntropy
              ((manuscriptHammingRadius dimension : ℝ) /
                (dimension : ℝ))) /
          ((dimension + 1 : ℕ) : ℝ)) := by
        gcongr
    _ ≤ (hammingRetentionProbability dimension ^ 2 *
        ((2 ^ dimension : ℕ) : ℝ)) *
        ((∑ distance ∈
          Finset.range (manuscriptHammingRadius dimension + 1),
          dimension.choose distance : ℕ) : ℝ) := by
        gcongr
    _ = hammingExpectedRetainedEdgeCount dimension
        (manuscriptHammingRadius dimension) := by
      rw [hammingExpectedRetainedEdgeCount_eq]

noncomputable def manuscriptSamplingFailureBound
    (depth dimension : ℕ) : ℝ :=
  (((2 * depth : ℕ) : ℝ)) *
      Real.exp (-(dimension : ℝ) * Real.log 2) +
    2 / 3 +
    (4 / hammingExpectedRetainedEdgeCount dimension
        (manuscriptHammingRadius dimension) +
      8 / (hammingRetentionProbability dimension *
        ((2 ^ dimension : ℕ) : ℝ)))

noncomputable def manuscriptSamplingFailureEvent
    {depth : ℕ}
    (layerSizes : Fin depth → ℕ)
    (dimension : ℕ) : Set (Set (Bool × HammingWord dimension)) :=
  (badPairLayersRetentionEvent layerSizes dimension ∪
    {retained : Set (Bool × HammingWord dimension) |
      3 * hammingRetentionProbability dimension *
          ((2 ^ dimension : ℕ) : ℝ) ≤
        hammingRetainedVertexCount dimension retained}) ∪
    {retained : Set (Bool × HammingWord dimension) |
      hammingRetainedEdgeCount dimension
          (manuscriptHammingRadius dimension) retained <
        hammingExpectedRetainedEdgeCount dimension
          (manuscriptHammingRadius dimension) / 2}

theorem pairGraphOverFin_forall_exists_adj
    (baseSize depth : ℕ)
    (hbase : 4 ≤ baseSize)
    (hdepth : 0 < depth) :
    ∀ vertex : Fin (Fintype.card (PairVertex baseSize depth)),
      ∃ neighbor,
        (pairGraphOverFin baseSize depth).Adj vertex neighbor := by
  have baseSize_le_pairVertex_card
      (baseSize depth : ℕ) :
      baseSize ≤ Fintype.card (PairVertex baseSize depth) := by
    calc
      baseSize = Fintype.card (PairLayer baseSize 0) :=
        (pairLayer_card_zero baseSize).symm
      _ ≤ Fintype.card (PairVertex baseSize depth) :=
        Fintype.card_le_of_embedding
          (pairLayerEmbedding baseSize depth 0 (by omega))
  have hcard : 2 ≤ Fintype.card (PairVertex baseSize depth) := by
    have hcard_base := baseSize_le_pairVertex_card baseSize depth
    omega
  let : Nontrivial (Fin (Fintype.card (PairVertex baseSize depth))) :=
    Fin.nontrivial_iff_two_le.mpr hcard
  intro vertex
  exact
    (pairGraphOverFin_connected baseSize depth (by omega) hdepth).preconnected
      |>.exists_adj_of_nontrivial vertex

noncomputable def manuscriptVertexCount (dimension : ℕ) : ℕ :=
  ⌈3 * hammingRetentionProbability dimension *
    ((2 ^ dimension : ℕ) : ℝ)⌉₊

noncomputable def manuscriptExtremalPower : ℝ :=
  (3 : ℝ) / 2 + exponentGain

theorem manuscriptExtremalPower_pos : 0 < manuscriptExtremalPower := by
  unfold manuscriptExtremalPower
  linarith [exponentGain_pos]

noncomputable def manuscriptEntropyGap : ℝ :=
  certifiedWindowWidth * Real.log 2 / 16

theorem manuscriptEntropyGap_pos : 0 < manuscriptEntropyGap := by
  unfold manuscriptEntropyGap
  positivity [certifiedWindowWidth_pos, log_two_pos]

open Classical in
set_option maxHeartbeats 3200000 in
theorem twoDegenerateExtremalCounterexample :
    ∃ (q : ℕ) (H : SimpleGraph (Fin q)),
      H.Connected ∧
      H.IsBipartite ∧
      IsTwoDegenerate H ∧
      (∀ coloring : H.Coloring (Fin 2), ∀ side : Fin 2,
        2 < (Finset.univ.filter
          (fun vertex : Fin q => coloring vertex = side)).sup
          (fun vertex => H.degree vertex)) ∧
      ∃ c ε : ℝ, 0 < c ∧ 0 < ε ∧
        ∀ᶠ n : ℕ in atTop,
          c * (n : ℝ) ^ ((3 : ℝ) / 2 + ε) ≤
            (SimpleGraph.extremalNumber n H : ℝ) := by
  have pairGraphOverFin_isBipartite (baseSize depth : ℕ) :
      (pairGraphOverFin baseSize depth).IsBipartite :=
    have isBipartite_of_iso {V W : Type _}
        {G : SimpleGraph V} {H : SimpleGraph W}
        (e : G ≃g H) (hG : G.IsBipartite) : H.IsBipartite := by
      obtain ⟨coloring⟩ := hG
      exact ⟨coloring.comp e.symm.toHom⟩
    have pairGraph_isBipartite (baseSize depth : ℕ) :
        (pairParentSystem baseSize depth).graph.IsBipartite :=
      ParentSystem.graph_isBipartite (pairParentSystem baseSize depth)
    isBipartite_of_iso (pairGraphOverFinIso baseSize depth)
      (pairGraph_isBipartite baseSize depth)
  have pairGraphOverFin_isTwoDegenerate (baseSize depth : ℕ) :
      IsTwoDegenerate (pairGraphOverFin baseSize depth) :=
    have isTwoDegenerate_of_iso {V W : Type _}
        {G : SimpleGraph V} {H : SimpleGraph W}
        (e : G ≃g H) (hG : IsTwoDegenerate G) :
        IsTwoDegenerate H := by
      classical
      intro s hs
      let t : Finset V := s.map e.symm.toEquiv.toEmbedding
      have ht : t.Nonempty := by
        obtain ⟨w, hw⟩ := hs
        refine ⟨e.symm w, ?_⟩
        exact Finset.mem_map.mpr ⟨w, hw, rfl⟩
      obtain ⟨v, hv, hcard⟩ := hG t ht
      refine ⟨e v, ?_, ?_⟩
      · change v ∈ s.map e.symm.toEquiv.toEmbedding at hv
        obtain ⟨w, hw, heq⟩ := Finset.mem_map.mp hv
        have hwv : w = e v := by
          apply e.symm.toEquiv.injective
          simpa using heq
        simpa [← hwv] using hw
      · have hneighbors :
            neighborsWithin H s (e v) =
              (neighborsWithin G t v).map e.toEquiv.toEmbedding := by
          ext w
          simp only [neighborsWithin, Finset.mem_filter, Finset.mem_map_equiv]
          have hmembership : e.symm w ∈ t ↔ w ∈ s := by
            change e.symm w ∈ s.map e.symm.toEquiv.toEmbedding ↔ w ∈ s
            constructor
            · intro hmember
              obtain ⟨u, hu, heq⟩ := Finset.mem_map.mp hmember
              have huw : u = w := e.symm.toEquiv.injective heq
              simpa [huw] using hu
            · intro hmember
              exact Finset.mem_map.mpr ⟨w, hmember, rfl⟩
          have hadjacency : G.Adj v (e.symm w) ↔ H.Adj (e v) w := by
            simpa using (e.map_rel_iff (a := v) (b := e.symm w)).symm
          exact (and_congr hmembership hadjacency).symm
        rw [hneighbors, Finset.card_map]
        exact hcard
    have pairGraph_isTwoDegenerate (baseSize depth : ℕ) :
        IsTwoDegenerate (pairParentSystem baseSize depth).graph :=
      ParentSystem.graph_isTwoDegenerate (pairParentSystem baseSize depth)
    isTwoDegenerate_of_iso (pairGraphOverFinIso baseSize depth)
      (pairGraph_isTwoDegenerate baseSize depth)
  (open Classical in
    have pairGraphOverFin_bipartition_maximum_degree_gt_two
        (baseSize depth : ℕ) (hbase : 4 ≤ baseSize) (hdepth : 2 ≤ depth) :
        ∀ coloring : (pairGraphOverFin baseSize depth).Coloring (Fin 2),
          ∀ side : Fin 2,
            2 < (Finset.univ.filter
              (fun vertex : Fin (Fintype.card (PairVertex baseSize depth)) =>
                coloring vertex = side)).sup
              (fun vertex => (pairGraphOverFin baseSize depth).degree vertex) := by
      (open Classical in
        have pairGraphOverFin_exists_adj_degree_gt_two
            (baseSize depth : ℕ) (hbase : 4 ≤ baseSize) (hdepth : 2 ≤ depth) :
            ∃ u v : Fin (Fintype.card (PairVertex baseSize depth)),
              (pairGraphOverFin baseSize depth).Adj u v ∧
              2 < (pairGraphOverFin baseSize depth).degree u ∧
              2 < (pairGraphOverFin baseSize depth).degree v := by
          (open Classical in
            have pairGraph_exists_adj_degree_gt_two
                (baseSize depth : ℕ) (hbase : 4 ≤ baseSize) (hdepth : 2 ≤ depth) :
                ∃ u v : PairVertex baseSize depth,
                  (pairParentSystem baseSize depth).graph.Adj u v ∧
                  2 < (pairParentSystem baseSize depth).graph.degree u ∧
                  2 < (pairParentSystem baseSize depth).graph.degree v := by
              (open Classical in
                have degree_gt_two_of_three_neighbors
                    {V : Type _} [Fintype V] (G : SimpleGraph V)
                    (v x y z : V)
                    (hx : G.Adj v x) (hy : G.Adj v y) (hz : G.Adj v z)
                    (hxy : x ≠ y) (hxz : x ≠ z) (hyz : y ≠ z) :
                    2 < G.degree v := by
                  classical
                  change 2 < (G.neighborFinset v).card
                  apply Finset.two_lt_card_iff.mpr
                  exact ⟨x, y, z,
                    (G.mem_neighborFinset v x).mpr hx,
                    (G.mem_neighborFinset v y).mpr hy,
                    (G.mem_neighborFinset v z).mpr hz,
                    hxy, hxz, hyz⟩)
              classical
              let a : PairLayer baseSize 0 := ⟨0, by omega⟩
              let b : PairLayer baseSize 0 := ⟨1, by omega⟩
              let c : PairLayer baseSize 0 := ⟨2, by omega⟩
              let d : PairLayer baseSize 0 := ⟨3, by omega⟩
              let pairDecidableEq : DecidableEq (PairLayer baseSize 0) := Classical.decEq _
              have hab : a ≠ b := by grind
              have hac : a ≠ c := by grind
              have had : a ≠ d := by grind
              have hbc : b ≠ c := by grind
              have hbd : b ≠ d := by grind
              have hcd : c ≠ d := by grind
              let ab : PairLayer baseSize 1 :=
                ⟨{a, b}, Finset.card_pair hab⟩
              let ac : PairLayer baseSize 1 :=
                ⟨{a, c}, Finset.card_pair hac⟩
              let ad : PairLayer baseSize 1 :=
                ⟨{a, d}, Finset.card_pair had⟩
              have habac : ab ≠ ac := by
                intro heq
                have hmem : b ∈ ab.val := by
                  change b ∈ ({a, b} : Finset (PairLayer baseSize 0))
                  exact Finset.mem_insert_of_mem (Finset.mem_singleton_self b)
                rw [heq] at hmem
                change b ∈ ({a, c} : Finset (PairLayer baseSize 0)) at hmem
                rcases Finset.mem_insert.mp hmem with hba | hbc'
                · exact hab hba.symm
                · exact hbc (Finset.mem_singleton.mp hbc')
              have habad : ab ≠ ad := by
                intro heq
                have hmem : b ∈ ab.val := by
                  change b ∈ ({a, b} : Finset (PairLayer baseSize 0))
                  exact Finset.mem_insert_of_mem (Finset.mem_singleton_self b)
                rw [heq] at hmem
                change b ∈ ({a, d} : Finset (PairLayer baseSize 0)) at hmem
                rcases Finset.mem_insert.mp hmem with hba | hbd'
                · exact hab hba.symm
                · exact hbd (Finset.mem_singleton.mp hbd')
              have hacad : ac ≠ ad := by
                intro heq
                have hmem : c ∈ ac.val := by
                  change c ∈ ({a, c} : Finset (PairLayer baseSize 0))
                  exact Finset.mem_insert_of_mem (Finset.mem_singleton_self c)
                rw [heq] at hmem
                change c ∈ ({a, d} : Finset (PairLayer baseSize 0)) at hmem
                rcases Finset.mem_insert.mp hmem with hca | hcd'
                · exact hac hca.symm
                · exact hcd (Finset.mem_singleton.mp hcd')
              let abc : PairLayer baseSize 2 :=
                ⟨{ab, ac}, Finset.card_pair habac⟩
              let va : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 0 (by omega) a
              let vb : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 0 (by omega) b
              let vab : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 1 (by omega) ab
              let vac : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 1 (by omega) ac
              let vad : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 1 (by omega) ad
              let vabc : PairVertex baseSize depth :=
                pairLayerEmbedding baseSize depth 2 (by omega) abc
              let G : SimpleGraph (PairVertex baseSize depth) :=
                (pairParentSystem baseSize depth).graph
              have ha_mem_ab : a ∈ ab.val := by
                change a ∈ ({a, b} : Finset (PairLayer baseSize 0))
                exact Finset.mem_insert_self a {b}
              have hb_mem_ab : b ∈ ab.val := by
                change b ∈ ({a, b} : Finset (PairLayer baseSize 0))
                exact Finset.mem_insert_of_mem (Finset.mem_singleton_self b)
              have ha_mem_ac : a ∈ ac.val := by
                change a ∈ ({a, c} : Finset (PairLayer baseSize 0))
                exact Finset.mem_insert_self a {c}
              have ha_mem_ad : a ∈ ad.val := by
                change a ∈ ({a, d} : Finset (PairLayer baseSize 0))
                exact Finset.mem_insert_self a {d}
              have hab_a : G.Adj vab va := by
                simpa only [G, vab, va] using
                  pairGraph_parent_child_adj baseSize depth 0
                    (by omega) ab a ha_mem_ab
              have hab_b : G.Adj vab vb := by
                simpa only [G, vab, vb] using
                  pairGraph_parent_child_adj baseSize depth 0
                    (by omega) ab b hb_mem_ab
              have hac_a : G.Adj vac va := by
                simpa only [G, vac, va] using
                  pairGraph_parent_child_adj baseSize depth 0
                    (by omega) ac a ha_mem_ac
              have had_a : G.Adj vad va := by
                simpa only [G, vad, va] using
                  pairGraph_parent_child_adj baseSize depth 0
                    (by omega) ad a ha_mem_ad
              have habc_ab : G.Adj vabc vab := by
                simpa only [G, vabc, vab] using
                  pairGraph_parent_child_adj baseSize depth 1
                    (by omega) abc ab (by
                      change ab ∈ ({ab, ac} : Finset (PairLayer baseSize 1))
                      exact Finset.mem_insert_self ab {ac})
              have hab_vac : vab ≠ vac := by grind
              have hab_vad : vab ≠ vad := by grind
              have hac_vad : vac ≠ vad := by grind
              have ha_b : va ≠ vb := by grind
              have ha_abc : va ≠ vabc := by
                intro heq
                have hlevel := congrArg
                  (fun vertex : PairVertex baseSize depth => vertex.1.val) heq
                change 0 = 2 at hlevel
                omega
              have hb_abc : vb ≠ vabc := by
                intro heq
                have hlevel := congrArg
                  (fun vertex : PairVertex baseSize depth => vertex.1.val) heq
                change 0 = 2 at hlevel
                omega
              have ha_degree : 2 < G.degree va :=
                degree_gt_two_of_three_neighbors G va vab vac vad
                  hab_a.symm hac_a.symm had_a.symm
                  hab_vac hab_vad hac_vad
              have hab_degree : 2 < G.degree vab :=
                degree_gt_two_of_three_neighbors G vab va vb vabc
                  hab_a hab_b habc_ab.symm ha_b ha_abc hb_abc
              exact ⟨va, vab, hab_a.symm, ha_degree, hab_degree⟩)
          classical
          obtain ⟨u, v, hadj, hu, hv⟩ :=
            pairGraph_exists_adj_degree_gt_two baseSize depth hbase hdepth
          let e := pairGraphOverFinIso baseSize depth
          refine ⟨e u, e v, (e.map_rel_iff).mpr hadj, ?_, ?_⟩
          · simpa only [e.degree_eq] using hu
          · simpa only [e.degree_eq] using hv)
      (open Classical in
        have bipartition_maximum_degree_gt_two_of_adj
            {V : Type _} [Fintype V]
            (G : SimpleGraph V) {u v : V}
            (hadj : G.Adj u v)
            (hu : 2 < G.degree u) (hv : 2 < G.degree v) :
            ∀ coloring : G.Coloring (Fin 2), ∀ side : Fin 2,
              2 < (Finset.univ.filter
                (fun vertex : V => coloring vertex = side)).sup
                (fun vertex => G.degree vertex) := by
          classical
          intro coloring side
          have hwitness : ∃ vertex : V, coloring vertex = side ∧ 2 < G.degree vertex := by
            by_cases hcolor : coloring u = side
            · exact ⟨u, hcolor, hu⟩
            · refine ⟨v, ?_, hv⟩
              have hproper : coloring u ≠ coloring v := coloring.valid hadj
              apply Fin.ext
              have hu_lt := (coloring u).isLt
              have hv_lt := (coloring v).isLt
              have hside_lt := side.isLt
              omega
          obtain ⟨vertex, hcolor, hdegree⟩ := hwitness
          have hmember :
              vertex ∈ Finset.univ.filter
                (fun candidate : V => coloring candidate = side) :=
            Finset.mem_filter.mpr ⟨Finset.mem_univ vertex, hcolor⟩
          exact lt_of_lt_of_le hdegree
            (Finset.le_sup (f := fun candidate => G.degree candidate) hmember))
      classical
      obtain ⟨u, v, hadj, hu, hv⟩ :=
        pairGraphOverFin_exists_adj_degree_gt_two baseSize depth hbase hdepth
      exact bipartition_maximum_degree_gt_two_of_adj
        (pairGraphOverFin baseSize depth) hadj hu hv)
  have eventually_manuscriptVertexCount_power_le_extremalNumber :
      ∃ baseSize depth : ℕ,
        4 ≤ baseSize ∧
        0 < depth ∧
        1 < (depth : ℝ) * (certifiedWindowWidth / 2) ∧
        ∀ᶠ dimension : ℕ in Filter.atTop,
          (manuscriptVertexCount dimension : ℝ) ^
              manuscriptExtremalPower ≤
            (SimpleGraph.extremalNumber
              (manuscriptVertexCount dimension)
              (pairGraphOverFin baseSize depth) : ℝ) := by
    (open Classical in
      have eventually_expectedRetainedEdge_le_extremalNumber :
          ∃ baseSize depth : ℕ,
            4 ≤ baseSize ∧
            0 < depth ∧
            1 < (depth : ℝ) * (certifiedWindowWidth / 2) ∧
            ∀ᶠ dimension : ℕ in Filter.atTop,
              hammingExpectedRetainedEdgeCount dimension
                  (manuscriptHammingRadius dimension) / 2 ≤
                (SimpleGraph.extremalNumber
                  (manuscriptVertexCount dimension)
                  (pairGraphOverFin baseSize depth) : ℝ) := by
        (open Classical in
          have hammingRetainedEdgeCount_eq_edgeFinset_card
              (dimension radius : ℕ)
              (retained : Set (Bool × HammingWord dimension)) :
              hammingRetainedEdgeCount dimension radius retained =
                ((retainedHammingHost dimension radius retained).edgeFinset.card : ℝ) := by
            have hammingRetainedEdgeCount_eq_wordEdges_card
                (dimension radius : ℕ)
                (retained : Set (Bool × HammingWord dimension)) :
                hammingRetainedEdgeCount dimension radius retained =
                  ((retainedHammingWordEdges dimension radius retained).card : ℝ) := by
              classical
              unfold hammingRetainedEdgeCount
              calc
                (∑ left : HammingWord dimension,
                  ∑ right : HammingWord dimension,
                    if hammingDist left right ≤ radius ∧
                        (false, left) ∈ retained ∧ (true, right) ∈ retained
                    then (1 : ℝ) else 0) =
                  ∑ edge : HammingWord dimension × HammingWord dimension,
                    if hammingDist edge.1 edge.2 ≤ radius ∧
                        (false, edge.1) ∈ retained ∧ (true, edge.2) ∈ retained
                    then (1 : ℝ) else 0 := by rw [Fintype.sum_prod_type]
                _ = ∑ _edge ∈ retainedHammingWordEdges dimension radius retained,
                      (1 : ℝ) := by
                  unfold retainedHammingWordEdges
                  rw [← Finset.sum_filter]
                _ = ((retainedHammingWordEdges dimension radius retained).card : ℝ) := by simp
            (open Classical in
              have retainedHammingHost_edgeFinset_card
                  (dimension radius : ℕ)
                  (retained : Set (Bool × HammingWord dimension)) :
                  (retainedHammingHost dimension radius retained).edgeFinset.card =
                    (retainedHammingWordEdges dimension radius retained).card := by
                classical
                let toEdge :
                    ∀ edge ∈ retainedHammingWordEdges dimension radius retained,
                      Sym2 retained := fun edge hedge =>
                  s(⟨(false, edge.1), by
                      exact (Finset.mem_filter.mp hedge).2.2.1⟩,
                    ⟨(true, edge.2), by
                      exact (Finset.mem_filter.mp hedge).2.2.2⟩)
                have hcard :
                    (retainedHammingWordEdges dimension radius retained).card =
                      (retainedHammingHost dimension radius retained).edgeFinset.card := by
                  apply Finset.card_bij toEdge
                  · intro edge hedge
                    have hdata := (Finset.mem_filter.mp hedge).2
                    change
                      s(⟨(false, edge.1), hdata.2.1⟩,
                        ⟨(true, edge.2), hdata.2.2⟩) ∈
                        (retainedHammingHost dimension radius retained).edgeFinset
                    rw [SimpleGraph.mem_edgeFinset, SimpleGraph.mem_edgeSet]
                    change (hammingHost dimension radius).Adj
                      (false, edge.1) (true, edge.2)
                    apply (hammingHost_adj_iff dimension radius _ _).mpr
                    exact ⟨by simp, hdata.1⟩
                  · intro first hfirst second hsecond hequal
                    dsimp [toEdge] at hequal
                    rcases (Sym2.eq_iff.mp hequal) with
                      ⟨hleft, hright⟩ | ⟨hswap, _⟩
                    · apply Prod.ext
                      · exact congrArg (fun vertex : retained => vertex.val.2) hleft
                      · exact congrArg (fun vertex : retained => vertex.val.2) hright
                    · have hside :=
                        congrArg (fun vertex : retained => vertex.val.1) hswap
                      simp at hside
                  · intro edge hedge
                    induction edge using Sym2.inductionOn with
                    | hf first second =>
                      have hadj :
                          (retainedHammingHost dimension radius retained).Adj
                            first second := by
                        exact (SimpleGraph.mem_edgeSet
                          (retainedHammingHost dimension radius retained)).mp
                            ((SimpleGraph.mem_edgeFinset).mp hedge)
                      have hhost :
                          (hammingHost dimension radius).Adj
                            first.val second.val := hadj
                      rcases first with ⟨⟨firstSide, firstWord⟩, hfirst⟩
                      rcases second with ⟨⟨secondSide, secondWord⟩, hsecond⟩
                      have hdata :=
                        (hammingHost_adj_iff dimension radius
                          (firstSide, firstWord) (secondSide, secondWord)).mp hhost
                      cases firstSide <;> cases secondSide
                      · simp at hdata
                      · refine ⟨(firstWord, secondWord), ?_, ?_⟩
                        · unfold retainedHammingWordEdges
                          simp [hdata.2, hfirst, hsecond]
                        · simp [toEdge]
                      · have hreverse : hammingDist secondWord firstWord ≤ radius := by
                          simpa [hammingDist_comm] using hdata.2
                        refine ⟨(secondWord, firstWord), ?_, ?_⟩
                        · unfold retainedHammingWordEdges
                          simp [hreverse, hfirst, hsecond]
                        · dsimp [toEdge]
                          exact Sym2.eq_swap
                      · simp at hdata
                exact hcard.symm)
            rw [hammingRetainedEdgeCount_eq_wordEdges_card,
              retainedHammingHost_edgeFinset_card])
        have eventually_exists_pairGraph_free_dense_retainedHost :
            ∃ baseSize depth : ℕ,
              4 ≤ baseSize ∧
              0 < depth ∧
              1 < (depth : ℝ) * (certifiedWindowWidth / 2) ∧
              ∀ᶠ dimension : ℕ in Filter.atTop,
                ∃ retained : Set (Bool × HammingWord dimension),
                  (pairGraphOverFin baseSize depth).Free
                      (retainedHammingHost dimension
                        (manuscriptHammingRadius dimension) retained) ∧
                  hammingRetainedVertexCount dimension retained <
                    3 * hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ) ∧
                  hammingExpectedRetainedEdgeCount dimension
                      (manuscriptHammingRadius dimension) / 2 ≤
                    hammingRetainedEdgeCount dimension
                      (manuscriptHammingRadius dimension) retained := by
          have exists_hammingRetention_outside_event
              (dimension : ℕ)
              (event : Set (Set (Bool × HammingWord dimension)))
              (hsmall : (hammingRetentionMeasure dimension).real event < 1) :
              ∃ retained : Set (Bool × HammingWord dimension), retained ∉ event := by
            let : MeasureTheory.IsProbabilityMeasure
                (hammingRetentionMeasure dimension) :=
              hammingRetentionMeasure_isProbability dimension
            by_contra hnone
            push Not at hnone
            have hevent : event = Set.univ := Set.eq_univ_of_forall hnone
            rw [hevent] at hsmall
            simp at hsmall
          have exists_actualPairLayer_exclusion_parameters :
              ∃ baseSize depth : ℕ,
                4 ≤ baseSize ∧
                0 < depth ∧
                1 < (depth : ℝ) * (certifiedWindowWidth / 2) ∧
                ∀ layer : Fin depth,
                  let layerSize :=
                    Fintype.card (PairLayer baseSize layer.val)
                  4 ≤ layerSize ∧
                  empiricalEntropyError layerSize < entropySlack ∧
                  (layerSize : ℝ) +
                    3 * logTwo ((layerSize.choose 2 + 1 : ℕ) : ℝ) -
                      entropySlack * (layerSize.choose 2 : ℝ) < -1 := by
            obtain ⟨baseSize, hbase, hbase_conditions⟩ :=
              exists_entropy_exclusion_base
            obtain ⟨depth, hdepth, hdepth_window⟩ :=
              exists_entropy_exclusion_depth
            refine ⟨baseSize, depth, hbase, hdepth, hdepth_window, ?_⟩
            intro layer
            dsimp
            have hsize : baseSize ≤ Fintype.card (PairLayer baseSize layer.val) :=
              pairLayer_card_ge_base baseSize layer.val hbase
            obtain ⟨herror, hfirst_moment⟩ :=
              hbase_conditions
                (Fintype.card (PairLayer baseSize layer.val)) hsize
            exact ⟨hbase.trans hsize, herror, hfirst_moment⟩
          have manuscriptSamplingFailureBound_tendsto_zero
              (depth : ℕ) :
              Tendsto
                (manuscriptSamplingFailureBound depth)
                atTop (𝓝 (2 / 3)) := by
            have hammingRetentionProbability_mul_wordCount_inv_tendsto_zero :
                Tendsto
                  (fun dimension : ℕ =>
                    1 / (hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ)))
                  atTop (𝓝 0) := by
              have htendsto := tendsto_inv_atTop_zero.comp
                hammingRetentionProbability_mul_wordCount_tendsto_atTop
              refine htendsto.congr' ?_
              filter_upwards [] with dimension
              simp only [Function.comp_apply, one_div]
            have pairLayerExclusionProbability_tendsto_zero (depth : ℕ) :
                Filter.Tendsto
                  (fun dimension : ℕ =>
                    (((2 * depth : ℕ) : ℝ)) *
                      Real.exp (-(dimension : ℝ) * Real.log 2))
                  Filter.atTop (nhds 0) := by
              have exp_neg_dimension_log_two (dimension : ℕ) :
                  Real.exp (-(dimension : ℝ) * Real.log 2) =
                    ((1 / 2 : ℝ) ^ dimension) := by
                calc
                  Real.exp (-(dimension : ℝ) * Real.log 2) =
                      Real.exp (-((dimension : ℝ) * Real.log 2)) := by
                        congr 1
                        ring
                  _ = (Real.exp ((dimension : ℝ) * Real.log 2))⁻¹ :=
                    Real.exp_neg _
                  _ = ((2 : ℝ) ^ dimension)⁻¹ := by
                    rw [Real.exp_nat_mul, Real.exp_log (by norm_num)]
                  _ = ((1 / 2 : ℝ) ^ dimension) := by
                    rw [← inv_pow]
                    norm_num
              have hgeometric :
                  Filter.Tendsto
                    (fun dimension : ℕ => (1 / 2 : ℝ) ^ dimension)
                    Filter.atTop (nhds 0) :=
                tendsto_pow_atTop_nhds_zero_of_lt_one (by norm_num) (by norm_num)
              simp_rw [exp_neg_dimension_log_two]
              simpa only [mul_zero] using
                hgeometric.const_mul (((2 * depth : ℕ) : ℝ))
            have manuscriptExpectedRetainedEdgeCount_inv_tendsto_zero :
                Tendsto
                  (fun dimension : ℕ =>
                    1 / hammingExpectedRetainedEdgeCount dimension
                      (manuscriptHammingRadius dimension))
                  atTop (𝓝 0) := by
              have manuscriptExpectedRetainedEdgeCount_tendsto_atTop :
                  Tendsto
                    (fun dimension : ℕ =>
                      hammingExpectedRetainedEdgeCount dimension
                        (manuscriptHammingRadius dimension))
                    atTop atTop := by
                have sampledHammingEdgeEntropyRate_pos : 0 < sampledHammingEdgeEntropyRate := by
                  have hwindow := midpointBeta_lt_upper_unconditional
                  unfold entropyUpperEndpoint at hwindow
                  have hbeta := midpointBeta_lt_one
                  have hbits : 0 < 1 - 2 * midpointBeta + binaryEntropy tau := by nlinarith
                  have hentropy : Real.binEntropy tau = binaryEntropy tau * Real.log 2 := by
                    unfold binaryEntropy
                    field_simp [log_two_pos.ne']
                  unfold sampledHammingEdgeEntropyRate
                  rw [hentropy]
                  nlinarith [mul_pos hbits log_two_pos]
                have hrate := sampledHammingEdgeEntropyRate_pos
                have hloss : 0 < sampledHammingEdgeEntropyRate / 2 := by positivity
                have hlower := eventually_manuscriptExpectedRetainedEdge_entropy_lower
                  (sampledHammingEdgeEntropyRate / 2) hloss
                have hgrowth := exp_mul_div_nat_succ_tendsto_atTop
                  (sampledHammingEdgeEntropyRate / 2) hloss
                have hhalf :
                    sampledHammingEdgeEntropyRate -
                        sampledHammingEdgeEntropyRate / 2 =
                      sampledHammingEdgeEntropyRate / 2 := by
                  ring
                apply tendsto_atTop_mono' atTop _ hgrowth
                filter_upwards [hlower] with dimension hdimension
                simpa only [hhalf, mul_comm] using hdimension
              have htendsto := tendsto_inv_atTop_zero.comp
                manuscriptExpectedRetainedEdgeCount_tendsto_atTop
              refine htendsto.congr' ?_
              filter_upwards [] with dimension
              simp only [Function.comp_apply, one_div]
            have hexclusion := pairLayerExclusionProbability_tendsto_zero depth
            have hvertices : Tendsto (fun _ : ℕ => (2 / 3 : ℝ)) atTop (𝓝 (2 / 3)) :=
              tendsto_const_nhds
            have hedges :=
              manuscriptExpectedRetainedEdgeCount_inv_tendsto_zero.const_mul 4
            have hwords :=
              hammingRetentionProbability_mul_wordCount_inv_tendsto_zero.const_mul 8
            have htotal := (hexclusion.add hvertices).add (hedges.add hwords)
            have htotal_zero :
                Tendsto
                  (fun dimension : ℕ =>
                    (((2 * depth : ℕ) : ℝ)) *
                        Real.exp (-(dimension : ℝ) * Real.log 2) +
                      2 / 3 +
                      (4 * (1 / hammingExpectedRetainedEdgeCount dimension
                          (manuscriptHammingRadius dimension)) +
                        8 * (1 / (hammingRetentionProbability dimension *
                          ((2 ^ dimension : ℕ) : ℝ)))))
                  atTop (𝓝 (2 / 3)) := by
              simpa only [mul_zero, add_zero, zero_add] using htotal
            apply htotal_zero.congr'
            filter_upwards [] with dimension
            unfold manuscriptSamplingFailureBound
            push_cast
            simp only [div_eq_mul_inv]
            ring
          have manuscriptSamplingFailureEvent_real_le
              {depth dimension : ℕ}
              (layerSizes : Fin depth → ℕ)
              (hdimension : 0 < dimension)
              (hparents : ∀ layer, 4 ≤ layerSizes layer)
              (hbase : ∀ layer,
                (layerSizes layer : ℝ) +
                  3 * logTwo
                    (((layerSizes layer).choose 2 + 1 : ℕ) : ℝ) -
                    entropySlack * ((layerSizes layer).choose 2 : ℝ) < -1) :
              (hammingRetentionMeasure dimension).real
                (manuscriptSamplingFailureEvent layerSizes dimension) ≤
                  manuscriptSamplingFailureBound depth dimension := by
            have hammingRetainedVertexCount_upper_tail_probability_le
                (dimension : ℕ) :
                (hammingRetentionMeasure dimension).real
                  {retained : Set (Bool × HammingWord dimension) |
                    3 * hammingRetentionProbability dimension *
                        ((2 ^ dimension : ℕ) : ℝ) ≤
                      hammingRetainedVertexCount dimension retained} ≤
                  2 / 3 := by
              let : MeasureTheory.IsProbabilityMeasure (hammingRetentionMeasure dimension) :=
                hammingRetentionMeasure_isProbability dimension
              have hp := hammingRetentionProbability_pos dimension
              have hmarkov := MeasureTheory.mul_meas_ge_le_integral_of_nonneg
                (Filter.Eventually.of_forall fun retained => by
                  unfold hammingRetainedVertexCount
                  exact Finset.sum_nonneg fun _ _ => by split_ifs <;> norm_num)
                (hammingRetentionMeasure_integrable dimension (hammingRetainedVertexCount dimension))
                (3 * hammingRetentionProbability dimension * ((2 ^ dimension : ℕ) : ℝ))
              rw [hammingRetainedVertexCount_integral_eq, hammingExpectedRetainedVertexCount_eq] at hmarkov
              rw [le_div_iff₀ (by norm_num : (0:ℝ) < 3)]
              nlinarith [show (0:ℝ) < hammingRetentionProbability dimension * ((2 ^ dimension : ℕ) : ℝ) by positivity]
            have badPairLayersRetentionEvent_real_le
                {depth dimension : ℕ}
                (layerSizes : Fin depth → ℕ)
                (hdimension : 0 < dimension)
                (hparents : ∀ layer, 4 ≤ layerSizes layer)
                (hbase : ∀ layer,
                  (layerSizes layer : ℝ) +
                    3 * logTwo
                      (((layerSizes layer).choose 2 + 1 : ℕ) : ℝ) -
                      entropySlack * ((layerSizes layer).choose 2 : ℝ) < -1) :
                (hammingRetentionMeasure dimension).real
                    (badPairLayersRetentionEvent layerSizes dimension) ≤
                  (((2 * depth : ℕ) : ℝ)) *
                    Real.exp (-(dimension : ℝ) * Real.log 2) := by
              have badPairLayerRetentionEvent_real_lt_exp_neg
                  {parentCount dimension : ℕ}
                  (hparents : 4 ≤ parentCount)
                  (hdimension : 0 < dimension)
                  (hbase :
                    (parentCount : ℝ) +
                      3 * logTwo ((parentCount.choose 2 + 1 : ℕ) : ℝ) -
                        entropySlack * (parentCount.choose 2 : ℝ) < -1)
                  (side : Bool) :
                  (hammingRetentionMeasure dimension).real
                    (badPairLayerRetentionEvent parentCount dimension side
                      (midpointBeta - entropySlack)) <
                    Real.exp (-(dimension : ℝ) * Real.log 2) := by
                have badPairLayerRetentionEvent_real_le
                    {parentCount dimension : ℕ}
                    (hparents : 2 ≤ parentCount)
                    (hdimension : 0 < dimension)
                    (side : Bool)
                    (threshold : ℝ) :
                    (hammingRetentionMeasure dimension).real
                        (badPairLayerRetentionEvent parentCount dimension side threshold) ≤
                      (((2 ^ (dimension * parentCount) : ℕ) : ℝ) *
                        (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                        Real.exp
                          ((parentCount.choose 2 : ℝ) * Real.log 2 *
                            (dimension : ℝ) * threshold)) *
                          hammingRetentionProbability dimension ^
                            (parentCount.choose 2) := by
                  have badPairChildRetentionEvent_real_le
                      {parentCount dimension : ℕ}
                      (hparents : 2 ≤ parentCount)
                      (hdimension : 0 < dimension)
                      (parents : Fin parentCount → HammingWord dimension)
                      (side : Bool)
                      (threshold : ℝ) :
                      (hammingRetentionMeasure dimension).real
                          (badPairChildRetentionEvent parents side threshold) ≤
                        ((((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                          Real.exp
                            ((parentCount.choose 2 : ℝ) * Real.log 2 *
                              (dimension : ℝ) * threshold)) *
                            hammingRetentionProbability dimension ^
                              (parentCount.choose 2) := by
                    have badPairChildArrays_card_le
                        {parentCount dimension : ℕ}
                        (hparents : 2 ≤ parentCount)
                        (hdimension : 0 < dimension)
                        (parents : Fin parentCount → HammingWord dimension)
                        (threshold : ℝ) :
                        ((badPairChildArrays parents threshold).card : ℝ) ≤
                          (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                            Real.exp
                              ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                (dimension : ℝ) * threshold) := by
                      have pairTypeCountProfile_card (parentCount dimension : ℕ) :
                          Fintype.card (PairTypeCountProfile parentCount dimension) =
                            (parentCount.choose 2 + 1) ^ (3 * dimension) := by
                        simp [PairTypeCountProfile, pow_mul, Nat.mul_comm]
                      have pairChildArraysOfRealizedProfile_card_le
                          {parentCount dimension : ℕ} (hparents : 2 ≤ parentCount)
                          (parents : Fin parentCount → HammingWord dimension)
                          (children : PairLayer parentCount 1 → HammingWord dimension) :
                          ((pairChildArraysOfProfile parents
                              (pairChildCountProfile parents children)).card : ℝ) ≤
                            Real.exp
                              ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                (∑ coordinate : Fin dimension,
                                  pairCoordinateConditionalEntropy parents children coordinate)) := by
                        have pairChildArraysOfProfile_card
                            {parentCount dimension : ℕ}
                            (parents : Fin parentCount → HammingWord dimension)
                            (profile : PairTypeCountProfile parentCount dimension) :
                            (pairChildArraysOfProfile parents profile).card =
                              ∏ index : PairBitType × Fin dimension,
                                ((pairTypeGroup parents index.2 index.1).card).choose
                                  (profile index.1 index.2).val := by
                          have classifiedBooleanWords_card
                              {ι γ : Type _} [Fintype ι] [Fintype γ] [DecidableEq γ]
                              (classify : ι → γ) (counts : γ → ℕ) :
                              (classifiedBooleanWords classify counts).card =
                                ∏ group : γ,
                                  (Fintype.card (ClassificationFiber classify group)).choose
                                    (counts group) := by
                            have booleanWordsOfWeight_card
                                (ι : Type _) [Fintype ι] (weight : ℕ) :
                                (booleanWordsOfWeight ι weight).card =
                                  (Fintype.card ι).choose weight := by
                              calc
                                (booleanWordsOfWeight ι weight).card =
                                    Fintype.card ↥(booleanWordsOfWeight ι weight) :=
                                  (Fintype.card_coe _).symm
                                _ = Fintype.card
                                    ↥((Finset.univ : Finset ι).powersetCard weight) :=
                                  Fintype.card_congr (booleanWordsOfWeightEquiv ι weight)
                                _ = ((Finset.univ : Finset ι).powersetCard weight).card :=
                                  Fintype.card_coe _
                                _ = (Fintype.card ι).choose weight := by simp
                            calc
                              (classifiedBooleanWords classify counts).card =
                                  Fintype.card ↥(classifiedBooleanWords classify counts) :=
                                (Fintype.card_coe _).symm
                              _ = Fintype.card
                                  (∀ group : γ,
                                    ↥(booleanWordsOfWeight
                                      (ClassificationFiber classify group) (counts group))) :=
                                Fintype.card_congr (classifiedBooleanWordsEquiv classify counts)
                              _ = ∏ group : γ,
                                    Fintype.card
                                      ↥(booleanWordsOfWeight
                                        (ClassificationFiber classify group) (counts group)) := by
                                rw [Fintype.card_pi]
                              _ = ∏ group : γ,
                                    (Fintype.card (ClassificationFiber classify group)).choose
                                      (counts group) := by
                                apply Finset.prod_congr rfl
                                intro group _
                                rw [Fintype.card_coe,
                                  booleanWordsOfWeight_card]
                          have pairCoordinateClassificationFiber_card
                              {parentCount dimension : ℕ}
                              (parents : Fin parentCount → HammingWord dimension)
                              (bitType : PairBitType) (coordinate : Fin dimension) :
                              Fintype.card
                                (ClassificationFiber
                                  (pairCoordinateClassification parents) (bitType, coordinate)) =
                                (pairTypeGroup parents coordinate bitType).card := by
                            calc
                              Fintype.card
                                  (ClassificationFiber
                                    (pairCoordinateClassification parents) (bitType, coordinate)) =
                                  Fintype.card ↥(pairTypeGroup parents coordinate bitType) :=
                                Fintype.card_congr
                                  (pairCoordinateClassificationFiberEquiv parents bitType coordinate)
                              _ = (pairTypeGroup parents coordinate bitType).card :=
                                Fintype.card_coe _
                          calc
                            (pairChildArraysOfProfile parents profile).card =
                              Fintype.card ↥(pairChildArraysOfProfile parents profile) :=
                                (Fintype.card_coe _).symm
                            _ = Fintype.card
                              ↥(classifiedBooleanWords
                                (pairCoordinateClassification parents)
                                (fun index : PairBitType × Fin dimension =>
                                  (profile index.1 index.2).val)) :=
                                Fintype.card_congr
                                  (pairChildArraysOfProfileEquiv parents profile)
                            _ = (classifiedBooleanWords
                                (pairCoordinateClassification parents)
                                (fun index : PairBitType × Fin dimension =>
                                  (profile index.1 index.2).val)).card :=
                                Fintype.card_coe _
                            _ = ∏ index : PairBitType × Fin dimension,
                                (Fintype.card
                                  (ClassificationFiber
                                    (pairCoordinateClassification parents) index)).choose
                                  (profile index.1 index.2).val :=
                                classifiedBooleanWords_card
                                  (pairCoordinateClassification parents)
                                  (fun index : PairBitType × Fin dimension =>
                                    (profile index.1 index.2).val)
                            _ = ∏ index : PairBitType × Fin dimension,
                                ((pairTypeGroup parents index.2 index.1).card).choose
                                  (profile index.1 index.2).val := by
                              apply Finset.prod_congr rfl
                              rintro ⟨bitType, coordinate⟩ _
                              rw [pairCoordinateClassificationFiber_card]
                        have pairChildGroup_choose_product_entropy_bound
                            {parentCount dimension : ℕ} (hparents : 2 ≤ parentCount)
                            (parents : Fin parentCount → HammingWord dimension)
                            (children : PairLayer parentCount 1 → HammingWord dimension) :
                            (∏ index : PairBitType × Fin dimension,
                              ((pairTypeGroup parents index.2 index.1).card).choose
                                ((pairTypeGroupChildOnes parents children index.2 index.1).card) : ℝ) ≤
                              Real.exp
                                ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                  (∑ coordinate : Fin dimension,
                                    pairCoordinateConditionalEntropy parents children coordinate)) := by
                          have choose_product_le_exp_binary_entropy
                              {ι : Type _} [Fintype ι]
                              (population success : ι → ℕ)
                              (hcount : ∀ index, success index ≤ population index) :
                              (∏ index : ι,
                                (population index).choose (success index) : ℝ) ≤
                                Real.exp
                                  (∑ index : ι,
                                    (population index : ℝ) *
                                      Real.binEntropy
                                        ((success index : ℝ) / (population index : ℝ))) := by
                            have choose_le_exp_binary_entropy
                                (trialCount successCount : ℕ)
                                (hcount : successCount ≤ trialCount) :
                                (trialCount.choose successCount : ℝ) ≤
                                  Real.exp
                                    ((trialCount : ℝ) *
                                      Real.binEntropy ((successCount : ℝ) / (trialCount : ℝ))) := by
                              have log_choose_le_binary_entropy
                                  (trialCount successCount : ℕ)
                                  (hcount : successCount ≤ trialCount) :
                                  Real.log (trialCount.choose successCount : ℝ) ≤
                                    (trialCount : ℝ) *
                                      Real.binEntropy ((successCount : ℝ) / (trialCount : ℝ)) := by
                                have binomial_probability_term_le_one
                                    (trialCount successCount : ℕ) (probability : ℝ)
                                    (hcount : successCount ≤ trialCount)
                                    (hprobability_zero : 0 ≤ probability)
                                    (hprobability_one : probability ≤ 1) :
                                    (trialCount.choose successCount : ℝ) *
                                        probability ^ successCount *
                                        (1 - probability) ^ (trialCount - successCount) ≤ 1 := by
                                  have hcomplement : 0 ≤ 1 - probability :=
                                    sub_nonneg.mpr hprobability_one
                                  have hsum :
                                      (∑ count ∈ Finset.range (trialCount + 1),
                                        probability ^ count *
                                          (1 - probability) ^ (trialCount - count) *
                                          (trialCount.choose count : ℝ)) = 1 := by
                                    calc
                                      (∑ count ∈ Finset.range (trialCount + 1),
                                          probability ^ count *
                                            (1 - probability) ^ (trialCount - count) *
                                            (trialCount.choose count : ℝ)) =
                                          (probability + (1 - probability)) ^ trialCount :=
                                        (add_pow probability (1 - probability) trialCount).symm
                                      _ = 1 := by
                                        rw [show probability + (1 - probability) = 1 by ring]
                                        simp
                                  have hterm := Finset.single_le_sum
                                    (s := Finset.range (trialCount + 1))
                                    (f := fun count : ℕ =>
                                      probability ^ count *
                                        (1 - probability) ^ (trialCount - count) *
                                        (trialCount.choose count : ℝ))
                                    (fun count _ => by positivity)
                                    (show successCount ∈ Finset.range (trialCount + 1) by
                                      simp; omega)
                                  rw [hsum] at hterm
                                  nlinarith
                                by_cases hzero : successCount = 0
                                · subst successCount
                                  simp
                                by_cases hfull : successCount = trialCount
                                · subst successCount
                                  by_cases htrials : trialCount = 0
                                  · simp [htrials]
                                  · have htrials_real : (trialCount : ℝ) ≠ 0 := by
                                      exact_mod_cast htrials
                                    simp [htrials_real]
                                have hsuccess : 0 < successCount := Nat.pos_of_ne_zero hzero
                                have hstrict : successCount < trialCount :=
                                  lt_of_le_of_ne hcount hfull
                                have htrials : 0 < trialCount :=
                                  lt_of_lt_of_le hsuccess hcount
                                let probability : ℝ :=
                                  (successCount : ℝ) / (trialCount : ℝ)
                                have hprobability_pos : 0 < probability := by positivity
                                have hprobability_lt_one : probability < 1 := by
                                  dsimp [probability]
                                  apply (div_lt_one (by exact_mod_cast htrials)).mpr
                                  exact_mod_cast hstrict
                                have hcomplement : 0 < 1 - probability :=
                                  sub_pos.mpr hprobability_lt_one
                                have hchoose : 0 < (trialCount.choose successCount : ℝ) := by
                                  exact_mod_cast Nat.choose_pos hcount
                                have hmass := binomial_probability_term_le_one
                                  trialCount successCount probability hcount
                                  hprobability_pos.le hprobability_lt_one.le
                                have hproduct :
                                    0 < (trialCount.choose successCount : ℝ) *
                                      probability ^ successCount *
                                      (1 - probability) ^ (trialCount - successCount) := by
                                  positivity
                                have hlogmass := Real.log_le_log hproduct hmass
                                simp only [Real.log_one] at hlogmass
                                rw [Real.log_mul
                                    (mul_pos hchoose (pow_pos hprobability_pos _)).ne'
                                    (pow_pos hcomplement _).ne',
                                  Real.log_mul hchoose.ne' (pow_pos hprobability_pos _).ne',
                                  Real.log_pow, Real.log_pow] at hlogmass
                                have htrials_real : (trialCount : ℝ) ≠ 0 := by
                                  exact_mod_cast htrials.ne'
                                have hentropy :
                                    (trialCount : ℝ) * Real.binEntropy probability =
                                      -(successCount : ℝ) * Real.log probability -
                                        ((trialCount - successCount : ℕ) : ℝ) *
                                          Real.log (1 - probability) := by
                                  unfold Real.binEntropy
                                  rw [Real.log_inv, Real.log_inv, Nat.cast_sub hcount]
                                  dsimp [probability]
                                  field_simp [htrials_real]
                                  ring
                                change Real.log (trialCount.choose successCount : ℝ) ≤
                                  (trialCount : ℝ) * Real.binEntropy probability
                                rw [hentropy]
                                linarith
                              have hchoose : 0 < (trialCount.choose successCount : ℝ) := by
                                exact_mod_cast Nat.choose_pos hcount
                              exact (Real.log_le_iff_le_exp hchoose).mp
                                (log_choose_le_binary_entropy trialCount successCount hcount)
                            calc
                              (∏ index : ι,
                                  (population index).choose (success index) : ℝ) ≤
                                ∏ index : ι,
                                  Real.exp
                                    ((population index : ℝ) *
                                      Real.binEntropy
                                        ((success index : ℝ) / (population index : ℝ))) := by
                                  apply Finset.prod_le_prod
                                  · intro index _
                                    positivity
                                  · intro index _
                                    exact choose_le_exp_binary_entropy
                                      (population index) (success index) (hcount index)
                              _ = Real.exp
                                  (∑ index : ι,
                                    (population index : ℝ) *
                                      Real.binEntropy
                                        ((success index : ℝ) / (population index : ℝ))) := by
                                rw [Real.exp_sum]
                          have pairCoordinateConditionalEntropy_log_mass
                              {parentCount dimension : ℕ} (hparents : 2 ≤ parentCount)
                              (parents : Fin parentCount → HammingWord dimension)
                              (children : PairLayer parentCount 1 → HammingWord dimension)
                              (coordinate : Fin dimension) :
                              (∑ bitType : PairBitType,
                                ((pairTypeGroup parents coordinate bitType).card : ℝ) *
                                  Real.binEntropy
                                    (((pairTypeGroupChildOnes parents children
                                        coordinate bitType).card : ℝ) /
                                      ((pairTypeGroup parents coordinate bitType).card : ℝ))) =
                                (parentCount.choose 2 : ℝ) * Real.log 2 *
                                  pairCoordinateConditionalEntropy parents children coordinate := by
                            have pairCoordinateConditionalEntropy_mass
                                {parentCount dimension : ℕ} (hparents : 2 ≤ parentCount)
                                (parents : Fin parentCount → HammingWord dimension)
                                (children : PairLayer parentCount 1 → HammingWord dimension)
                                (coordinate : Fin dimension) :
                                (parentCount.choose 2 : ℝ) *
                                    pairCoordinateConditionalEntropy parents children coordinate =
                                  ∑ bitType : PairBitType,
                                    ((pairTypeGroup parents coordinate bitType).card : ℝ) *
                                      binaryEntropy
                                        (((pairTypeGroupChildOnes parents children
                                            coordinate bitType).card : ℝ) /
                                          ((pairTypeGroup parents coordinate bitType).card : ℝ)) := by
                              have hpair : 0 < (parentCount.choose 2 : ℝ) := by
                                exact_mod_cast Nat.choose_pos hparents
                              unfold pairCoordinateConditionalEntropy
                              rw [Finset.mul_sum]
                              apply Finset.sum_congr rfl
                              intro bitType _
                              field_simp [hpair.ne']
                            calc
                              (∑ bitType : PairBitType,
                                  ((pairTypeGroup parents coordinate bitType).card : ℝ) *
                                    Real.binEntropy
                                      (((pairTypeGroupChildOnes parents children
                                          coordinate bitType).card : ℝ) /
                                        ((pairTypeGroup parents coordinate bitType).card : ℝ))) =
                                (∑ bitType : PairBitType,
                                  ((pairTypeGroup parents coordinate bitType).card : ℝ) *
                                    binaryEntropy
                                      (((pairTypeGroupChildOnes parents children
                                          coordinate bitType).card : ℝ) /
                                        ((pairTypeGroup parents coordinate bitType).card : ℝ))) *
                                  Real.log 2 := by
                                    rw [Finset.sum_mul]
                                    apply Finset.sum_congr rfl
                                    intro bitType _
                                    unfold binaryEntropy
                                    field_simp [log_two_pos.ne']
                              _ = (parentCount.choose 2 : ℝ) * Real.log 2 *
                                  pairCoordinateConditionalEntropy parents children coordinate := by
                                rw [← pairCoordinateConditionalEntropy_mass
                                  hparents parents children coordinate]
                                ring
                          have hproduct := choose_product_le_exp_binary_entropy
                            (ι := PairBitType × Fin dimension)
                            (fun index => (pairTypeGroup parents index.2 index.1).card)
                            (fun index =>
                              (pairTypeGroupChildOnes parents children index.2 index.1).card)
                            (fun index => pairTypeGroupChildOnes_card_le
                              parents children index.2 index.1)
                          have hsum :
                              (∑ index : PairBitType × Fin dimension,
                                ((pairTypeGroup parents index.2 index.1).card : ℝ) *
                                  Real.binEntropy
                                    (((pairTypeGroupChildOnes parents children
                                        index.2 index.1).card : ℝ) /
                                      ((pairTypeGroup parents index.2 index.1).card : ℝ))) =
                                (parentCount.choose 2 : ℝ) * Real.log 2 *
                                  (∑ coordinate : Fin dimension,
                                    pairCoordinateConditionalEntropy parents children coordinate) := by
                            rw [Fintype.sum_prod_type, Finset.sum_comm]
                            simp_rw [pairCoordinateConditionalEntropy_log_mass
                              hparents parents children]
                            rw [Finset.mul_sum]
                          rw [hsum] at hproduct
                          exact hproduct
                        have hcard :
                            ((pairChildArraysOfProfile parents
                              (pairChildCountProfile parents children)).card : ℝ) =
                              ∏ index : PairBitType × Fin dimension,
                                (((pairTypeGroup parents index.2 index.1).card).choose
                                  ((pairTypeGroupChildOnes parents children
                                    index.2 index.1).card) : ℝ) := by
                          exact_mod_cast
                            pairChildArraysOfProfile_card parents
                              (pairChildCountProfile parents children)
                        rw [hcard]
                        exact pairChildGroup_choose_product_entropy_bound
                          hparents parents children
                      classical
                      let bound : ℝ :=
                        Real.exp
                          ((parentCount.choose 2 : ℝ) * Real.log 2 *
                            (dimension : ℝ) * threshold)
                      have hbound_nonneg : 0 ≤ bound := by positivity
                      have hmaps :
                          ((badPairChildArrays parents threshold :
                            Finset (PairLayer parentCount 1 → HammingWord dimension)) :
                            Set (PairLayer parentCount 1 → HammingWord dimension)).MapsTo
                            (pairChildCountProfile parents)
                            (Finset.univ : Finset (PairTypeCountProfile parentCount dimension)) := by simp [*]
                      have hpartition := Finset.card_eq_sum_card_fiberwise hmaps
                      have hfiber (profile : PairTypeCountProfile parentCount dimension) :
                          (((badPairChildArrays parents threshold).filter
                            (fun children => pairChildCountProfile parents children = profile)).card : ℝ) ≤
                            bound := by
                        by_cases hnonempty :
                            ((badPairChildArrays parents threshold).filter
                              (fun children =>
                                pairChildCountProfile parents children = profile)).Nonempty
                        · obtain ⟨children, hchildren⟩ := hnonempty
                          have hparts := Finset.mem_filter.mp hchildren
                          have hprofile : pairChildCountProfile parents children = profile :=
                            hparts.2
                          have hbad : pairChildArrayEntropy parents children ≤ threshold := by
                            have hmembership :
                                children ∈
                                  (Finset.univ.filter
                                    (fun candidate : PairLayer parentCount 1 →
                                        HammingWord dimension =>
                                      pairChildArrayEntropy parents candidate ≤ threshold)) := by
                              simpa only [badPairChildArrays] using hparts.1
                            exact (Finset.mem_filter.mp hmembership).2
                          have hsubset :
                              (badPairChildArrays parents threshold).filter
                                  (fun candidate =>
                                    pairChildCountProfile parents candidate = profile) ⊆
                                pairChildArraysOfProfile parents profile := by
                            intro candidate hcandidate
                            have hcandidate_profile := (Finset.mem_filter.mp hcandidate).2
                            unfold pairChildArraysOfProfile
                            exact Finset.mem_filter.mpr
                              ⟨Finset.mem_univ _, hcandidate_profile⟩
                          have hcard :
                              (((badPairChildArrays parents threshold).filter
                                (fun candidate =>
                                  pairChildCountProfile parents candidate = profile)).card : ℝ) ≤
                                ((pairChildArraysOfProfile parents profile).card : ℝ) := by
                            exact_mod_cast Finset.card_le_card hsubset
                          have hrealized :
                              ((pairChildArraysOfProfile parents profile).card : ℝ) ≤
                                Real.exp
                                  ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                    (∑ coordinate : Fin dimension,
                                      pairCoordinateConditionalEntropy
                                        parents children coordinate)) := by grind
                          have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                          have hsum :
                              (∑ coordinate : Fin dimension,
                                pairCoordinateConditionalEntropy parents children coordinate) ≤
                                  (dimension : ℝ) * threshold := by
                            unfold pairChildArrayEntropy at hbad
                            have hcleared := (div_le_iff₀ hdimension_real).mp hbad
                            nlinarith
                          have hcoefficient : 0 ≤ (parentCount.choose 2 : ℝ) * Real.log 2 :=
                            mul_nonneg (Nat.cast_nonneg _) log_two_pos.le
                          have hexponential :
                              Real.exp
                                  ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                    (∑ coordinate : Fin dimension,
                                      pairCoordinateConditionalEntropy
                                        parents children coordinate)) ≤ bound := by
                            dsimp [bound]
                            apply Real.exp_le_exp.mpr
                            nlinarith [mul_le_mul_of_nonneg_left hsum hcoefficient]
                          exact hcard.trans (hrealized.trans hexponential)
                        · have hempty :
                              (badPairChildArrays parents threshold).filter
                                (fun children =>
                                  pairChildCountProfile parents children = profile) = ∅ :=
                              Finset.not_nonempty_iff_eq_empty.mp hnonempty
                          simpa [hempty] using hbound_nonneg
                      calc
                        ((badPairChildArrays parents threshold).card : ℝ) =
                            ∑ profile : PairTypeCountProfile parentCount dimension,
                              (((badPairChildArrays parents threshold).filter
                                (fun children =>
                                  pairChildCountProfile parents children = profile)).card : ℝ) := by
                          exact_mod_cast hpartition
                        _ ≤ ∑ _profile : PairTypeCountProfile parentCount dimension, bound := by
                          exact Finset.sum_le_sum (fun profile _ => hfiber profile)
                        _ = (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                              Real.exp
                                ((parentCount.choose 2 : ℝ) * Real.log 2 *
                                  (dimension : ℝ) * threshold) := by
                          rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul,
                            pairTypeCountProfile_card]
                    have hammingRetentionMeasure_real_pairChildren
                        {parentCount dimension : ℕ}
                        (side : Bool)
                        (children : PairLayer parentCount 1 → HammingWord dimension)
                        (hinjective : Function.Injective children) :
                        (hammingRetentionMeasure dimension).real
                            (pairChildRetentionEvent side children) =
                          hammingRetentionProbability dimension ^ (parentCount.choose 2) := by
                      have pairChildVertexFinset_card
                          {parentCount dimension : ℕ}
                          (side : Bool)
                          (children : PairLayer parentCount 1 → HammingWord dimension)
                          (hinjective : Function.Injective children) :
                          (pairChildVertexFinset side children).card = parentCount.choose 2 := by
                        classical
                        unfold pairChildVertexFinset
                        rw [Finset.card_image_of_injective]
                        · rw [Finset.card_univ, pairLayer_card_succ parentCount 0,
                            pairLayer_card_zero]
                        · intro first second hequal
                          exact hinjective (congrArg Prod.snd hequal)
                      classical
                      have hevent :
                          pairChildRetentionEvent side children =
                            {retained : Set (Bool × HammingWord dimension) |
                              ∀ vertex ∈ pairChildVertexFinset side children,
                                vertex ∈ retained} := by
                        ext retained
                        simp [pairChildRetentionEvent, pairChildVertexFinset]
                      rw [hevent, hammingRetentionMeasure_real_contains_finset,
                        pairChildVertexFinset_card side children hinjective]
                    classical
                    let distinctBad :
                        Finset (PairLayer parentCount 1 → HammingWord dimension) :=
                      (badPairChildArrays parents threshold).filter Function.Injective
                    have hprobability_nonneg :
                        0 ≤ hammingRetentionProbability dimension ^
                          (parentCount.choose 2) :=
                      pow_nonneg (hammingRetentionProbability_pos dimension).le _
                    have hcard :
                        (distinctBad.card : ℝ) ≤
                          ((badPairChildArrays parents threshold).card : ℝ) := by
                      dsimp [distinctBad]
                      exact_mod_cast
                        Finset.card_filter_le
                          (badPairChildArrays parents threshold) Function.Injective
                    calc
                      (hammingRetentionMeasure dimension).real
                          (badPairChildRetentionEvent parents side threshold) =
                        (hammingRetentionMeasure dimension).real
                          (⋃ children ∈ distinctBad,
                            pairChildRetentionEvent side children) := by
                          rfl
                      _ ≤ ∑ children ∈ distinctBad,
                            (hammingRetentionMeasure dimension).real
                              (pairChildRetentionEvent side children) :=
                          MeasureTheory.measureReal_biUnion_finset_le
                            distinctBad (pairChildRetentionEvent side)
                      _ = ∑ _children ∈ distinctBad,
                            hammingRetentionProbability dimension ^
                              (parentCount.choose 2) := by
                          apply Finset.sum_congr rfl
                          intro children hchildren
                          have hinjective : Function.Injective children := by grind
                          exact hammingRetentionMeasure_real_pairChildren
                            side children hinjective
                      _ = (distinctBad.card : ℝ) *
                            hammingRetentionProbability dimension ^
                              (parentCount.choose 2) := by
                          simp [nsmul_eq_mul]
                      _ ≤ ((badPairChildArrays parents threshold).card : ℝ) *
                            hammingRetentionProbability dimension ^
                              (parentCount.choose 2) :=
                          mul_le_mul_of_nonneg_right hcard hprobability_nonneg
                      _ ≤
                        ((((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                          Real.exp
                            ((parentCount.choose 2 : ℝ) * Real.log 2 *
                              (dimension : ℝ) * threshold)) *
                            hammingRetentionProbability dimension ^
                              (parentCount.choose 2) :=
                          mul_le_mul_of_nonneg_right
                            (badPairChildArrays_card_le hparents hdimension parents threshold)
                            hprobability_nonneg
                  have hammingParentTuple_card (parentCount dimension : ℕ) :
                      Fintype.card (Fin parentCount → HammingWord dimension) =
                        2 ^ (dimension * parentCount) := by
                    simp [HammingWord, ← pow_mul]
                  classical
                  let bound : ℝ :=
                    ((((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                      Real.exp
                        ((parentCount.choose 2 : ℝ) * Real.log 2 *
                          (dimension : ℝ) * threshold)) *
                        hammingRetentionProbability dimension ^
                          (parentCount.choose 2)
                  calc
                    (hammingRetentionMeasure dimension).real
                        (badPairLayerRetentionEvent parentCount dimension side threshold) =
                      (hammingRetentionMeasure dimension).real
                        (⋃ parents : Fin parentCount → HammingWord dimension,
                          badPairChildRetentionEvent parents side threshold) := by
                        rfl
                    _ ≤ ∑ parents : Fin parentCount → HammingWord dimension,
                          (hammingRetentionMeasure dimension).real
                            (badPairChildRetentionEvent parents side threshold) :=
                        MeasureTheory.measureReal_iUnion_fintype_le
                          (fun parents => badPairChildRetentionEvent parents side threshold)
                    _ ≤ ∑ _parents : Fin parentCount → HammingWord dimension, bound := by
                      apply Finset.sum_le_sum
                      intro parents _
                      exact badPairChildRetentionEvent_real_le
                        hparents hdimension parents side threshold
                    _ =
                      (((2 ^ (dimension * parentCount) : ℕ) : ℝ) *
                        (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                        Real.exp
                          ((parentCount.choose 2 : ℝ) * Real.log 2 *
                            (dimension : ℝ) * threshold)) *
                          hammingRetentionProbability dimension ^
                            (parentCount.choose 2) := by
                      rw [Finset.sum_const, Finset.card_univ, nsmul_eq_mul,
                        hammingParentTuple_card]
                      dsimp [bound]
                      ring
                have badPairLayerRetentionBound_eq_exp
                    (parentCount dimension : ℕ) :
                    ((((2 ^ (dimension * parentCount) : ℕ) : ℝ) *
                      (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                      Real.exp
                        ((parentCount.choose 2 : ℝ) * Real.log 2 *
                          (dimension : ℝ) * (midpointBeta - entropySlack))) *
                        hammingRetentionProbability dimension ^
                          (parentCount.choose 2)) =
                      Real.exp
                        ((dimension : ℝ) * Real.log 2 *
                          ((parentCount : ℝ) +
                            3 * logTwo ((parentCount.choose 2 + 1 : ℕ) : ℝ) -
                              entropySlack * (parentCount.choose 2 : ℝ))) := by
                  have hparent :
                      (((2 ^ (dimension * parentCount) : ℕ) : ℝ)) =
                        Real.exp
                          (((dimension * parentCount : ℕ) : ℝ) * Real.log 2) := by
                    calc
                      (((2 ^ (dimension * parentCount) : ℕ) : ℝ)) =
                          (2 : ℝ) ^ (dimension * parentCount) := by norm_cast
                      _ = Real.exp
                          (((dimension * parentCount : ℕ) : ℝ) * Real.log 2) := by
                            rw [Real.exp_nat_mul, Real.exp_log (by norm_num)]
                  have hprofile :
                      (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) =
                        Real.exp
                          (((3 * dimension : ℕ) : ℝ) *
                            Real.log ((parentCount.choose 2 + 1 : ℕ) : ℝ)) := by
                    calc
                      (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) =
                          (((parentCount.choose 2 + 1 : ℕ) : ℝ)) ^
                            (3 * dimension) := by norm_cast
                      _ = Real.exp
                          (((3 * dimension : ℕ) : ℝ) *
                            Real.log ((parentCount.choose 2 + 1 : ℕ) : ℝ)) := by
                              rw [Real.exp_nat_mul, Real.exp_log (by positivity)]
                  have hretention :
                      hammingRetentionProbability dimension ^
                          (parentCount.choose 2) =
                        Real.exp
                          ((parentCount.choose 2 : ℝ) *
                            (-(midpointBeta * (dimension : ℝ) * Real.log 2))) := by
                    unfold hammingRetentionProbability
                    rw [Real.exp_nat_mul]
                  rw [hparent, hprofile, hretention,
                    ← Real.exp_add, ← Real.exp_add, ← Real.exp_add]
                  apply congrArg Real.exp
                  unfold logTwo
                  push_cast
                  field_simp [log_two_pos.ne']
                  ring
                have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                calc
                  (hammingRetentionMeasure dimension).real
                    (badPairLayerRetentionEvent parentCount dimension side
                      (midpointBeta - entropySlack)) ≤
                    ((((2 ^ (dimension * parentCount) : ℕ) : ℝ) *
                      (((parentCount.choose 2 + 1) ^ (3 * dimension) : ℕ) : ℝ) *
                      Real.exp
                        ((parentCount.choose 2 : ℝ) * Real.log 2 *
                          (dimension : ℝ) * (midpointBeta - entropySlack))) *
                        hammingRetentionProbability dimension ^
                          (parentCount.choose 2)) :=
                      badPairLayerRetentionEvent_real_le
                        (by omega) hdimension side (midpointBeta - entropySlack)
                  _ = Real.exp
                      ((dimension : ℝ) * Real.log 2 *
                        ((parentCount : ℝ) +
                          3 * logTwo ((parentCount.choose 2 + 1 : ℕ) : ℝ) -
                            entropySlack * (parentCount.choose 2 : ℝ))) :=
                      badPairLayerRetentionBound_eq_exp parentCount dimension
                  _ < Real.exp (-(dimension : ℝ) * Real.log 2) := by
                    apply Real.exp_lt_exp.mpr
                    have hscaled := mul_lt_mul_of_pos_left hbase
                      (mul_pos hdimension_real log_two_pos)
                    nlinarith
              classical
              let bound : ℝ := Real.exp (-(dimension : ℝ) * Real.log 2)
              calc
                (hammingRetentionMeasure dimension).real
                    (badPairLayersRetentionEvent layerSizes dimension) =
                  (hammingRetentionMeasure dimension).real
                    (⋃ side : Bool, ⋃ layer : Fin depth,
                      badPairLayerRetentionEvent (layerSizes layer) dimension side
                        (midpointBeta - entropySlack)) := by
                    rfl
                _ ≤ ∑ side : Bool,
                    (hammingRetentionMeasure dimension).real
                      (⋃ layer : Fin depth,
                        badPairLayerRetentionEvent (layerSizes layer) dimension side
                          (midpointBeta - entropySlack)) :=
                    MeasureTheory.measureReal_iUnion_fintype_le
                      (fun side =>
                        ⋃ layer : Fin depth,
                          badPairLayerRetentionEvent (layerSizes layer) dimension side
                            (midpointBeta - entropySlack))
                _ ≤ ∑ side : Bool, ∑ layer : Fin depth,
                      (hammingRetentionMeasure dimension).real
                        (badPairLayerRetentionEvent
                          (layerSizes layer) dimension side
                            (midpointBeta - entropySlack)) := by
                    apply Finset.sum_le_sum
                    intro side _
                    exact MeasureTheory.measureReal_iUnion_fintype_le
                      (fun layer =>
                        badPairLayerRetentionEvent
                          (layerSizes layer) dimension side
                            (midpointBeta - entropySlack))
                _ ≤ ∑ _side : Bool, ∑ _layer : Fin depth, bound := by
                    apply Finset.sum_le_sum
                    intro side _
                    apply Finset.sum_le_sum
                    intro layer _
                    exact (badPairLayerRetentionEvent_real_lt_exp_neg
                      (hparents layer) hdimension (hbase layer) side).le
                _ = (((2 * depth : ℕ) : ℝ)) *
                      Real.exp (-(dimension : ℝ) * Real.log 2) := by
                    simp [bound, nsmul_eq_mul]
                    ring
            have hammingRetainedEdgeCount_lower_tail_probability_le
                (dimension radius : ℕ) :
                (hammingRetentionMeasure dimension).real
                  {retained : Set (Bool × HammingWord dimension) |
                    hammingRetainedEdgeCount dimension radius retained <
                      hammingExpectedRetainedEdgeCount dimension radius / 2} ≤
                  4 / hammingExpectedRetainedEdgeCount dimension radius +
                    8 / (hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ)) := by
              have hammingExpectedRetainedEdgeCount_pos
                  (dimension radius : ℕ) :
                  0 < hammingExpectedRetainedEdgeCount dimension radius := by
                have hterm :
                    1 ≤ ∑ distance ∈ Finset.range (radius + 1),
                      dimension.choose distance := by
                  have hzero := Finset.single_le_sum
                    (s := Finset.range (radius + 1))
                    (f := fun distance : ℕ => dimension.choose distance)
                    (fun distance _ => Nat.zero_le _)
                    (show 0 ∈ Finset.range (radius + 1) by simp)
                  simpa using hzero
                have hdegree :
                    0 < ((∑ distance ∈ Finset.range (radius + 1),
                      dimension.choose distance : ℕ) : ℝ) := by positivity
                rw [hammingExpectedRetainedEdgeCount_eq]
                have hprobability := hammingRetentionProbability_pos dimension
                positivity
              have hammingRetainedEdgeCount_deviation_probability_le
                  (dimension radius : ℕ) (threshold : ℝ)
                  (hthreshold : 0 < threshold) :
                  (hammingRetentionMeasure dimension).real
                    {retained : Set (Bool × HammingWord dimension) |
                      threshold ≤
                        |hammingRetainedEdgeCount dimension radius retained -
                          hammingExpectedRetainedEdgeCount dimension radius|} ≤
                    (hammingExpectedRetainedEdgeCount dimension radius +
                      2 * hammingRetentionProbability dimension ^ 3 *
                        ((2 ^ dimension : ℕ) : ℝ) *
                        ((∑ distance ∈ Finset.range (radius + 1),
                          dimension.choose distance : ℕ) : ℝ) ^ 2) /
                      threshold ^ 2 := by
                have hammingRetainedEdgeCount_variance_le
                    (dimension radius : ℕ) :
                    ProbabilityTheory.variance
                        (hammingRetainedEdgeCount dimension radius)
                        (hammingRetentionMeasure dimension) ≤
                      hammingExpectedRetainedEdgeCount dimension radius +
                        2 * hammingRetentionProbability dimension ^ 3 *
                          ((2 ^ dimension : ℕ) : ℝ) *
                          ((∑ distance ∈ Finset.range (radius + 1),
                            dimension.choose distance : ℕ) : ℝ) ^ 2 := by
                  have hammingExpectedRetainedEdgeVariance_le
                      (dimension radius : ℕ) :
                      hammingExpectedRetainedEdgeSquare dimension radius -
                          hammingExpectedRetainedEdgeCount dimension radius ^ 2 ≤
                        hammingExpectedRetainedEdgeCount dimension radius +
                          2 * hammingRetentionProbability dimension ^ 3 *
                            ((2 ^ dimension : ℕ) : ℝ) *
                            ((∑ distance ∈ Finset.range (radius + 1),
                              dimension.choose distance : ℕ) : ℝ) ^ 2 := by
                    have hammingExpectedRetainedEdgeSquare_le
                        (dimension radius : ℕ) :
                        hammingExpectedRetainedEdgeSquare dimension radius ≤
                          hammingExpectedRetainedEdgeCount dimension radius ^ 2 +
                            hammingExpectedRetainedEdgeCount dimension radius +
                            2 * hammingRetentionProbability dimension ^ 3 *
                              ((2 ^ dimension : ℕ) : ℝ) *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) ^ 2 := by
                      have hammingWordEdgePair_sum_const
                          (dimension radius : ℕ) (weight : ℝ) :
                          (∑ firstLeft : HammingWord dimension,
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    weight
                                  else 0) =
                            ((2 ^ dimension : ℕ) : ℝ) ^ 2 *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) ^ 2 * weight := by
                        classical
                        have hinner (firstLeft firstRight : HammingWord dimension) :
                            (∑ secondLeft : HammingWord dimension,
                              ∑ secondRight : HammingWord dimension,
                                if hammingDist firstLeft firstRight ≤ radius ∧
                                    hammingDist secondLeft secondRight ≤ radius then
                                  weight
                                else 0) =
                              if hammingDist firstLeft firstRight ≤ radius then
                                ((2 ^ dimension : ℕ) : ℝ) *
                                  ((∑ distance ∈ Finset.range (radius + 1),
                                    dimension.choose distance : ℕ) : ℝ) * weight
                              else 0 := by
                          by_cases hedge : hammingDist firstLeft firstRight ≤ radius
                          · simp only [hedge, true_and, if_true]
                            exact hammingWordEdge_sum_const dimension radius weight
                          · simp [hedge]
                        simp_rw [hinner]
                        rw [hammingWordEdge_sum_const]
                        ring
                      have hammingWordEdgePairSharedRight_sum_const
                          (dimension radius : ℕ) (weight : ℝ) :
                          (∑ firstLeft : HammingWord dimension,
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    if firstRight = secondRight then weight else 0
                                  else 0) =
                            ((2 ^ dimension : ℕ) : ℝ) *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) ^ 2 * weight := by
                        classical
                        calc
                          (∑ firstLeft : HammingWord dimension,
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    if firstRight = secondRight then weight else 0
                                  else 0) =
                            (∑ firstRight : HammingWord dimension,
                              ∑ firstLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  ∑ secondLeft : HammingWord dimension,
                                    if hammingDist firstLeft firstRight ≤ radius ∧
                                        hammingDist secondLeft secondRight ≤ radius then
                                      if firstRight = secondRight then weight else 0
                                    else 0) := by
                              rw [Finset.sum_comm]
                              apply Finset.sum_congr rfl
                              intro firstRight _
                              apply Finset.sum_congr rfl
                              intro firstLeft _
                              rw [Finset.sum_comm]
                          _ = ((2 ^ dimension : ℕ) : ℝ) *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) ^ 2 * weight := by
                            simpa only [hammingDist_comm] using
                              hammingWordEdgePairSharedLeft_sum_const dimension radius weight
                      have hammingWordEdgePairIdentical_sum_const
                          (dimension radius : ℕ) (weight : ℝ) :
                          (∑ firstLeft : HammingWord dimension,
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    if firstLeft = secondLeft ∧ firstRight = secondRight then
                                      weight else 0
                                  else 0) =
                            ((2 ^ dimension : ℕ) : ℝ) *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) * weight := by
                        classical
                        calc
                          _ = ∑ firstLeft : HammingWord dimension,
                                ∑ firstRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius then weight else 0 := by
                            apply Finset.sum_congr rfl
                            intro firstLeft _
                            apply Finset.sum_congr rfl
                            intro firstRight _
                            by_cases hedge : hammingDist firstLeft firstRight ≤ radius
                            · simp only [hedge, true_and, if_true]
                              have hpoint (secondLeft secondRight : HammingWord dimension) :
                                  (if hammingDist secondLeft secondRight ≤ radius then
                                    if firstLeft = secondLeft ∧ firstRight = secondRight then
                                      weight else 0
                                  else 0) =
                                    if firstLeft = secondLeft then
                                      if firstRight = secondRight then weight else 0
                                    else 0 := by
                                split_ifs <;> simp_all
                              simp_rw [hpoint]
                              simp
                            · simp [hedge]
                          _ = _ := hammingWordEdge_sum_const dimension radius weight
                      have hammingExpectedRetainedEdgeSquare_le_endpoint_decomposition
                          (dimension radius : ℕ) :
                          hammingExpectedRetainedEdgeSquare dimension radius ≤
                            ∑ firstLeft : HammingWord dimension,
                              ∑ firstRight : HammingWord dimension,
                                ∑ secondLeft : HammingWord dimension,
                                  ∑ secondRight : HammingWord dimension,
                                    if hammingDist firstLeft firstRight ≤ radius ∧
                                        hammingDist secondLeft secondRight ≤ radius then
                                      hammingRetentionProbability dimension ^ 4 +
                                        (if firstLeft = secondLeft then
                                          hammingRetentionProbability dimension ^ 3 else 0) +
                                        (if firstRight = secondRight then
                                          hammingRetentionProbability dimension ^ 3 else 0) +
                                        (if firstLeft = secondLeft ∧
                                            firstRight = secondRight then
                                          hammingRetentionProbability dimension ^ 2 else 0)
                                    else 0 := by
                        have hammingRetentionMeasure_real_contains_edgePair_le
                            (dimension : ℕ)
                            (firstLeft firstRight secondLeft secondRight : HammingWord dimension) :
                            (hammingRetentionMeasure dimension).real
                              {retained : Set (Bool × HammingWord dimension) |
                                (false, firstLeft) ∈ retained ∧
                                (true, firstRight) ∈ retained ∧
                                (false, secondLeft) ∈ retained ∧
                                (true, secondRight) ∈ retained} ≤
                              hammingRetentionProbability dimension ^ 4 +
                                (if firstLeft = secondLeft then
                                  hammingRetentionProbability dimension ^ 3 else 0) +
                                (if firstRight = secondRight then
                                  hammingRetentionProbability dimension ^ 3 else 0) +
                                (if firstLeft = secondLeft ∧ firstRight = secondRight then
                                  hammingRetentionProbability dimension ^ 2 else 0) := by
                          have hammingRetentionMeasure_real_contains_edgePair
                              (dimension : ℕ)
                              (firstLeft firstRight secondLeft secondRight : HammingWord dimension) :
                              (hammingRetentionMeasure dimension).real
                                {retained : Set (Bool × HammingWord dimension) |
                                  (false, firstLeft) ∈ retained ∧
                                  (true, firstRight) ∈ retained ∧
                                  (false, secondLeft) ∈ retained ∧
                                  (true, secondRight) ∈ retained} =
                                hammingRetentionProbability dimension ^
                                  (2 +
                                    (if firstLeft = secondLeft then 0 else 1) +
                                    (if firstRight = secondRight then 0 else 1)) := by
                            classical
                            let required : Finset (Bool × HammingWord dimension) :=
                              {(false, firstLeft), (true, firstRight),
                                (false, secondLeft), (true, secondRight)}
                            have hevent :
                                {retained : Set (Bool × HammingWord dimension) |
                                  (false, firstLeft) ∈ retained ∧
                                  (true, firstRight) ∈ retained ∧
                                  (false, secondLeft) ∈ retained ∧
                                  (true, secondRight) ∈ retained} =
                                {retained : Set (Bool × HammingWord dimension) |
                                  ∀ vertex ∈ required, vertex ∈ retained} := by
                              ext retained
                              simp [required, and_left_comm]
                            rw [hevent, hammingRetentionMeasure_real_contains_finset]
                            by_cases hleft : firstLeft = secondLeft <;>
                              by_cases hright : firstRight = secondRight
                            · subst secondLeft
                              subst secondRight
                              simp [required]
                            · subst secondLeft
                              simp [required, hright]
                            · subst secondRight
                              simp [required, hleft]
                            · simp [required, hleft, hright]
                          rw [hammingRetentionMeasure_real_contains_edgePair]
                          have hnonnegative := (hammingRetentionProbability_pos dimension).le
                          by_cases hleft : firstLeft = secondLeft <;>
                            by_cases hright : firstRight = secondRight <;>
                            simp only [hleft, hright, ↓reduceIte, add_zero, Nat.reduceAdd,
                              and_self, and_false, and_true, le_add_iff_nonneg_left, ge_iff_le,
                              Std.le_refl] <;>
                            positivity
                        unfold hammingExpectedRetainedEdgeSquare
                        apply Finset.sum_le_sum
                        intro firstLeft _
                        apply Finset.sum_le_sum
                        intro firstRight _
                        apply Finset.sum_le_sum
                        intro secondLeft _
                        apply Finset.sum_le_sum
                        intro secondRight _
                        by_cases hedge :
                            hammingDist firstLeft firstRight ≤ radius ∧
                              hammingDist secondLeft secondRight ≤ radius
                        · simp only [hedge]
                          exact hammingRetentionMeasure_real_contains_edgePair_le
                            dimension firstLeft firstRight secondLeft secondRight
                        · simp [hedge]
                      classical
                      have hpoint
                          (firstLeft firstRight secondLeft secondRight : HammingWord dimension) :
                          (if hammingDist firstLeft firstRight ≤ radius ∧
                              hammingDist secondLeft secondRight ≤ radius then
                            hammingRetentionProbability dimension ^ 4 +
                              (if firstLeft = secondLeft then
                                hammingRetentionProbability dimension ^ 3 else 0) +
                              (if firstRight = secondRight then
                                hammingRetentionProbability dimension ^ 3 else 0) +
                              (if firstLeft = secondLeft ∧ firstRight = secondRight then
                                hammingRetentionProbability dimension ^ 2 else 0)
                          else 0) =
                            (if hammingDist firstLeft firstRight ≤ radius ∧
                                hammingDist secondLeft secondRight ≤ radius then
                              hammingRetentionProbability dimension ^ 4 else 0) +
                            (if hammingDist firstLeft firstRight ≤ radius ∧
                                hammingDist secondLeft secondRight ≤ radius then
                              if firstLeft = secondLeft then
                                hammingRetentionProbability dimension ^ 3 else 0
                            else 0) +
                            (if hammingDist firstLeft firstRight ≤ radius ∧
                                hammingDist secondLeft secondRight ≤ radius then
                              if firstRight = secondRight then
                                hammingRetentionProbability dimension ^ 3 else 0
                            else 0) +
                            (if hammingDist firstLeft firstRight ≤ radius ∧
                                hammingDist secondLeft secondRight ≤ radius then
                              if firstLeft = secondLeft ∧ firstRight = secondRight then
                                hammingRetentionProbability dimension ^ 2 else 0
                            else 0) := by
                        split <;> simp
                      calc
                        hammingExpectedRetainedEdgeSquare dimension radius ≤
                          ∑ firstLeft : HammingWord dimension,
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    hammingRetentionProbability dimension ^ 4 +
                                      (if firstLeft = secondLeft then
                                        hammingRetentionProbability dimension ^ 3 else 0) +
                                      (if firstRight = secondRight then
                                        hammingRetentionProbability dimension ^ 3 else 0) +
                                      (if firstLeft = secondLeft ∧ firstRight = secondRight then
                                        hammingRetentionProbability dimension ^ 2 else 0)
                                  else 0 :=
                            hammingExpectedRetainedEdgeSquare_le_endpoint_decomposition
                              dimension radius
                        _ = hammingExpectedRetainedEdgeCount dimension radius ^ 2 +
                            hammingExpectedRetainedEdgeCount dimension radius +
                            2 * hammingRetentionProbability dimension ^ 3 *
                              ((2 ^ dimension : ℕ) : ℝ) *
                              ((∑ distance ∈ Finset.range (radius + 1),
                                dimension.choose distance : ℕ) : ℝ) ^ 2 := by
                          simp_rw [hpoint, Finset.sum_add_distrib]
                          rw [hammingWordEdgePair_sum_const,
                            hammingWordEdgePairSharedLeft_sum_const,
                            hammingWordEdgePairSharedRight_sum_const,
                            hammingWordEdgePairIdentical_sum_const,
                            hammingExpectedRetainedEdgeCount_eq]
                          ring
                    have hsecond := hammingExpectedRetainedEdgeSquare_le dimension radius
                    linarith
                  have hammingRetainedEdgeCount_variance_eq
                      (dimension radius : ℕ) :
                      ProbabilityTheory.variance
                          (hammingRetainedEdgeCount dimension radius)
                          (hammingRetentionMeasure dimension) =
                        hammingExpectedRetainedEdgeSquare dimension radius -
                          hammingExpectedRetainedEdgeCount dimension radius ^ 2 := by
                    have hammingRetainedEdgeCount_sq_integral_eq
                        (dimension radius : ℕ) :
                        (∫ retained,
                          hammingRetainedEdgeCount dimension radius retained ^ 2
                            ∂hammingRetentionMeasure dimension) =
                          hammingExpectedRetainedEdgeSquare dimension radius := by
                      (open Classical in
                        have hammingRetainedEdgeCount_sq
                            (dimension radius : ℕ)
                            (retained : Set (Bool × HammingWord dimension)) :
                            hammingRetainedEdgeCount dimension radius retained ^ 2 =
                              ∑ firstLeft : HammingWord dimension,
                                ∑ firstRight : HammingWord dimension,
                                  ∑ secondLeft : HammingWord dimension,
                                    ∑ secondRight : HammingWord dimension,
                                      if hammingDist firstLeft firstRight ≤ radius ∧
                                          hammingDist secondLeft secondRight ≤ radius then
                                        if (false, firstLeft) ∈ retained ∧
                                            (true, firstRight) ∈ retained ∧
                                            (false, secondLeft) ∈ retained ∧
                                            (true, secondRight) ∈ retained
                                        then (1 : ℝ) else 0
                                      else 0 := by
                          classical
                          unfold hammingRetainedEdgeCount
                          rw [pow_two, Finset.sum_mul_sum]
                          simp_rw [Finset.sum_mul_sum]
                          apply Finset.sum_congr rfl
                          intro firstLeft _
                          rw [Finset.sum_comm]
                          apply Finset.sum_congr rfl
                          intro firstRight _
                          apply Finset.sum_congr rfl
                          intro secondLeft _
                          apply Finset.sum_congr rfl
                          intro secondRight _
                          by_cases hfirst_edge : hammingDist firstLeft firstRight ≤ radius <;>
                            by_cases hsecond_edge : hammingDist secondLeft secondRight ≤ radius <;>
                            by_cases hfirst_left : (false, firstLeft) ∈ retained <;>
                            by_cases hfirst_right : (true, firstRight) ∈ retained <;>
                            by_cases hsecond_left : (false, secondLeft) ∈ retained <;>
                            by_cases hsecond_right : (true, secondRight) ∈ retained <;>
                            simp [hfirst_edge, hsecond_edge, hfirst_left, hfirst_right,
                              hsecond_left, hsecond_right])
                      classical
                      simp_rw [hammingRetainedEdgeCount_sq]
                      rw [MeasureTheory.integral_finsetSum Finset.univ
                        (fun firstLeft _ => hammingRetentionMeasure_integrable dimension
                          (fun retained : Set (Bool × HammingWord dimension) =>
                            ∑ firstRight : HammingWord dimension,
                              ∑ secondLeft : HammingWord dimension,
                                ∑ secondRight : HammingWord dimension,
                                  if hammingDist firstLeft firstRight ≤ radius ∧
                                      hammingDist secondLeft secondRight ≤ radius then
                                    if (false, firstLeft) ∈ retained ∧
                                        (true, firstRight) ∈ retained ∧
                                        (false, secondLeft) ∈ retained ∧
                                        (true, secondRight) ∈ retained
                                    then (1 : ℝ) else 0
                                  else 0))]
                      unfold hammingExpectedRetainedEdgeSquare
                      apply Finset.sum_congr rfl
                      intro firstLeft _
                      rw [MeasureTheory.integral_finsetSum Finset.univ
                        (fun firstRight _ => hammingRetentionMeasure_integrable dimension
                          (fun retained : Set (Bool × HammingWord dimension) =>
                            ∑ secondLeft : HammingWord dimension,
                              ∑ secondRight : HammingWord dimension,
                                if hammingDist firstLeft firstRight ≤ radius ∧
                                    hammingDist secondLeft secondRight ≤ radius then
                                  if (false, firstLeft) ∈ retained ∧
                                      (true, firstRight) ∈ retained ∧
                                      (false, secondLeft) ∈ retained ∧
                                      (true, secondRight) ∈ retained
                                  then (1 : ℝ) else 0
                                else 0))]
                      apply Finset.sum_congr rfl
                      intro firstRight _
                      rw [MeasureTheory.integral_finsetSum Finset.univ
                        (fun secondLeft _ => hammingRetentionMeasure_integrable dimension
                          (fun retained : Set (Bool × HammingWord dimension) =>
                            ∑ secondRight : HammingWord dimension,
                              if hammingDist firstLeft firstRight ≤ radius ∧
                                  hammingDist secondLeft secondRight ≤ radius then
                                if (false, firstLeft) ∈ retained ∧
                                    (true, firstRight) ∈ retained ∧
                                    (false, secondLeft) ∈ retained ∧
                                    (true, secondRight) ∈ retained
                                then (1 : ℝ) else 0
                              else 0))]
                      apply Finset.sum_congr rfl
                      intro secondLeft _
                      rw [MeasureTheory.integral_finsetSum Finset.univ
                        (fun secondRight _ => hammingRetentionMeasure_integrable dimension
                          (fun retained : Set (Bool × HammingWord dimension) =>
                            if hammingDist firstLeft firstRight ≤ radius ∧
                                hammingDist secondLeft secondRight ≤ radius then
                              if (false, firstLeft) ∈ retained ∧
                                  (true, firstRight) ∈ retained ∧
                                  (false, secondLeft) ∈ retained ∧
                                  (true, secondRight) ∈ retained
                              then (1 : ℝ) else 0
                            else 0))]
                      apply Finset.sum_congr rfl
                      intro secondRight _
                      by_cases hedge :
                          hammingDist firstLeft firstRight ≤ radius ∧
                            hammingDist secondLeft secondRight ≤ radius
                      · simp only [hedge]
                        rw [hammingRetentionMeasure_integral_eq_sum,
                          hammingRetentionMeasure_real_event_eq_sum]
                        apply Finset.sum_congr rfl
                        intro retained _
                        by_cases hretained :
                            (false, firstLeft) ∈ retained ∧
                              (true, firstRight) ∈ retained ∧
                              (false, secondLeft) ∈ retained ∧
                              (true, secondRight) ∈ retained <;>
                          simp [hretained]
                      · simp [hedge]
                    let : MeasureTheory.IsProbabilityMeasure
                        (hammingRetentionMeasure dimension) :=
                      hammingRetentionMeasure_isProbability dimension
                    rw [ProbabilityTheory.variance_eq_sub
                      (hammingRetentionMeasure_memLp_two dimension
                        (hammingRetainedEdgeCount dimension radius))]
                    change
                      (∫ retained,
                        hammingRetainedEdgeCount dimension radius retained ^ 2
                          ∂hammingRetentionMeasure dimension) -
                        (∫ retained,
                          hammingRetainedEdgeCount dimension radius retained
                            ∂hammingRetentionMeasure dimension) ^ 2 =
                        hammingExpectedRetainedEdgeSquare dimension radius -
                          hammingExpectedRetainedEdgeCount dimension radius ^ 2
                    rw [hammingRetainedEdgeCount_sq_integral_eq,
                      hammingRetainedEdgeCount_integral_eq]
                  rw [hammingRetainedEdgeCount_variance_eq]
                  exact hammingExpectedRetainedEdgeVariance_le dimension radius
                have hchebyshev := hammingRetentionMeasure_real_deviation_le
                  dimension (hammingRetainedEdgeCount dimension radius)
                  threshold hthreshold
                rw [hammingRetainedEdgeCount_integral_eq] at hchebyshev
                calc
                  (hammingRetentionMeasure dimension).real
                    {retained : Set (Bool × HammingWord dimension) |
                      threshold ≤
                        |hammingRetainedEdgeCount dimension radius retained -
                          hammingExpectedRetainedEdgeCount dimension radius|} ≤
                    ProbabilityTheory.variance
                        (hammingRetainedEdgeCount dimension radius)
                        (hammingRetentionMeasure dimension) /
                      threshold ^ 2 := hchebyshev
                  _ ≤
                    (hammingExpectedRetainedEdgeCount dimension radius +
                      2 * hammingRetentionProbability dimension ^ 3 *
                        ((2 ^ dimension : ℕ) : ℝ) *
                        ((∑ distance ∈ Finset.range (radius + 1),
                          dimension.choose distance : ℕ) : ℝ) ^ 2) /
                      threshold ^ 2 := by
                    gcongr
                    exact hammingRetainedEdgeCount_variance_le dimension radius
              let : MeasureTheory.IsProbabilityMeasure
                  (hammingRetentionMeasure dimension) :=
                hammingRetentionMeasure_isProbability dimension
              have hmean := hammingExpectedRetainedEdgeCount_pos dimension radius
              have hthreshold : 0 < hammingExpectedRetainedEdgeCount dimension radius / 2 := by
                positivity
              have hchebyshev := hammingRetainedEdgeCount_deviation_probability_le
                dimension radius
                (hammingExpectedRetainedEdgeCount dimension radius / 2)
                hthreshold
              have hsubset :
                  {retained : Set (Bool × HammingWord dimension) |
                    hammingRetainedEdgeCount dimension radius retained <
                      hammingExpectedRetainedEdgeCount dimension radius / 2} ⊆
                  {retained : Set (Bool × HammingWord dimension) |
                    hammingExpectedRetainedEdgeCount dimension radius / 2 ≤
                      |hammingRetainedEdgeCount dimension radius retained -
                        hammingExpectedRetainedEdgeCount dimension radius|} := by
                intro retained hretained
                change
                  hammingExpectedRetainedEdgeCount dimension radius / 2 ≤
                    |hammingRetainedEdgeCount dimension radius retained -
                      hammingExpectedRetainedEdgeCount dimension radius|
                have habsolute := neg_le_abs
                  (hammingRetainedEdgeCount dimension radius retained -
                    hammingExpectedRetainedEdgeCount dimension radius)
                change
                  hammingRetainedEdgeCount dimension radius retained <
                    hammingExpectedRetainedEdgeCount dimension radius / 2 at hretained
                linarith
              have hdegree_positive :
                  0 < ((∑ distance ∈ Finset.range (radius + 1),
                    dimension.choose distance : ℕ) : ℝ) := by
                have hterm :
                    1 ≤ ∑ distance ∈ Finset.range (radius + 1),
                      dimension.choose distance := by
                  have hzero := Finset.single_le_sum
                    (s := Finset.range (radius + 1))
                    (f := fun distance : ℕ => dimension.choose distance)
                    (fun distance _ => Nat.zero_le _)
                    (show 0 ∈ Finset.range (radius + 1) by simp)
                  simpa using hzero
                exact_mod_cast (show 0 < ∑ distance ∈ Finset.range (radius + 1),
                  dimension.choose distance by omega)
              have hprobability := hammingRetentionProbability_pos dimension
              have hwords : 0 < ((2 ^ dimension : ℕ) : ℝ) := by positivity
              calc
                (hammingRetentionMeasure dimension).real
                  {retained : Set (Bool × HammingWord dimension) |
                    hammingRetainedEdgeCount dimension radius retained <
                      hammingExpectedRetainedEdgeCount dimension radius / 2} ≤
                  (hammingRetentionMeasure dimension).real
                  {retained : Set (Bool × HammingWord dimension) |
                    hammingExpectedRetainedEdgeCount dimension radius / 2 ≤
                      |hammingRetainedEdgeCount dimension radius retained -
                        hammingExpectedRetainedEdgeCount dimension radius|} :=
                    MeasureTheory.measureReal_mono hsubset
                _ ≤
                  (hammingExpectedRetainedEdgeCount dimension radius +
                    2 * hammingRetentionProbability dimension ^ 3 *
                      ((2 ^ dimension : ℕ) : ℝ) *
                      ((∑ distance ∈ Finset.range (radius + 1),
                        dimension.choose distance : ℕ) : ℝ) ^ 2) /
                    (hammingExpectedRetainedEdgeCount dimension radius / 2) ^ 2 :=
                  hchebyshev
                _ = 4 / hammingExpectedRetainedEdgeCount dimension radius +
                    8 / (hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ)) := by
                  rw [hammingExpectedRetainedEdgeCount_eq]
                  field_simp [hprobability.ne', hwords.ne', hdegree_positive.ne']
                  ring
            let vertexFailure : Set (Set (Bool × HammingWord dimension)) :=
              {retained : Set (Bool × HammingWord dimension) |
                3 * hammingRetentionProbability dimension *
                    ((2 ^ dimension : ℕ) : ℝ) ≤
                  hammingRetainedVertexCount dimension retained}
            let edgeFailure : Set (Set (Bool × HammingWord dimension)) :=
              {retained : Set (Bool × HammingWord dimension) |
                hammingRetainedEdgeCount dimension
                    (manuscriptHammingRadius dimension) retained <
                  hammingExpectedRetainedEdgeCount dimension
                    (manuscriptHammingRadius dimension) / 2}
            change
              (hammingRetentionMeasure dimension).real
                ((badPairLayersRetentionEvent layerSizes dimension ∪
                  vertexFailure) ∪ edgeFailure) ≤
                  manuscriptSamplingFailureBound depth dimension
            calc
              (hammingRetentionMeasure dimension).real
                ((badPairLayersRetentionEvent layerSizes dimension ∪
                  vertexFailure) ∪ edgeFailure) ≤
                ((hammingRetentionMeasure dimension).real
                  (badPairLayersRetentionEvent layerSizes dimension) +
                 (hammingRetentionMeasure dimension).real vertexFailure) +
                  (hammingRetentionMeasure dimension).real edgeFailure := by
                calc
                  (hammingRetentionMeasure dimension).real
                    ((badPairLayersRetentionEvent layerSizes dimension ∪
                      vertexFailure) ∪ edgeFailure) ≤
                    (hammingRetentionMeasure dimension).real
                      (badPairLayersRetentionEvent layerSizes dimension ∪
                        vertexFailure) +
                      (hammingRetentionMeasure dimension).real edgeFailure :=
                        MeasureTheory.measureReal_union_le _ _
                  _ ≤ ((hammingRetentionMeasure dimension).real
                        (badPairLayersRetentionEvent layerSizes dimension) +
                      (hammingRetentionMeasure dimension).real vertexFailure) +
                      (hammingRetentionMeasure dimension).real edgeFailure := by
                        gcongr
                        exact MeasureTheory.measureReal_union_le _ _
              _ ≤ ((((2 * depth : ℕ) : ℝ)) *
                    Real.exp (-(dimension : ℝ) * Real.log 2) +
                  2 / 3) +
                  (4 / hammingExpectedRetainedEdgeCount dimension
                      (manuscriptHammingRadius dimension) +
                    8 / (hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ))) := by
                gcongr
                · exact badPairLayersRetentionEvent_real_le
                    layerSizes hdimension hparents hbase
                · exact hammingRetainedVertexCount_upper_tail_probability_le dimension
                · exact hammingRetainedEdgeCount_lower_tail_probability_le
                    dimension (manuscriptHammingRadius dimension)
              _ = manuscriptSamplingFailureBound depth dimension := by rfl
          have pairGraphOverFin_free_of_manuscript_exclusion
              {baseSize depth dimension : ℕ}
              (hbase : 4 ≤ baseSize)
              (hdimension : 0 < dimension)
              (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2))
              (retained : Set (Bool × HammingWord dimension))
              (hexclusion :
                ∀ (side : Bool) (layer : Fin depth),
                  retained ∉
                    badPairLayerRetentionEvent
                      (Fintype.card (PairLayer baseSize layer.val))
                      dimension side (midpointBeta - entropySlack))
              (herror :
                ∀ layer : Fin depth,
                  empiricalEntropyError
                    (Fintype.card (PairLayer baseSize layer.val)) < entropySlack) :
              (pairGraphOverFin baseSize depth).Free
                (retainedHammingHost dimension
                  (manuscriptHammingRadius dimension) retained) := by
            have pairGraphOverFin_free_of_layer_exclusion
                {baseSize depth dimension radius : ℕ}
                (hbase : 4 ≤ baseSize)
                (hdimension : 0 < dimension)
                (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2))
                (hradius : (radius : ℝ) ≤ tau * (dimension : ℝ))
                (retained : Set (Bool × HammingWord dimension))
                (hexclusion :
                  ∀ (side : Bool) (layer : Fin depth),
                    retained ∉
                      badPairLayerRetentionEvent
                        (Fintype.card (PairLayer baseSize layer.val))
                        dimension side (midpointBeta - entropySlack))
                (herror :
                  ∀ layer : Fin depth,
                    empiricalEntropyError
                      (Fintype.card (PairLayer baseSize layer.val)) < entropySlack) :
                (pairGraphOverFin baseSize depth).Free
                  (retainedHammingHost dimension radius retained) := by
              have pairGraphCopy_averageDisagreement_le_tau
                  {baseSize depth dimension radius : ℕ}
                  (hbase : 4 ≤ baseSize)
                  (hdimension : 0 < dimension)
                  (hradius : (radius : ℝ) ≤ tau * (dimension : ℝ))
                  (retained : Set (Bool × HammingWord dimension))
                  (copy : SimpleGraph.Copy
                    (pairParentSystem baseSize depth).graph
                    (retainedHammingHost dimension radius retained))
                  (layer : Fin depth) :
                  pairChildArrayAverageDisagreement
                    (hbase.trans
                      (pairLayer_card_ge_base baseSize layer.val hbase))
                    (pairGraphCopyParentWords retained copy layer)
                    (pairGraphCopyChildWords retained copy layer) ≤ tau := by
                have pairGraphCopy_averageDisagreement_le_radius
                    {baseSize depth dimension radius : ℕ}
                    (hbase : 4 ≤ baseSize)
                    (hdimension : 0 < dimension)
                    (retained : Set (Bool × HammingWord dimension))
                    (copy : SimpleGraph.Copy
                      (pairParentSystem baseSize depth).graph
                      (retainedHammingHost dimension radius retained))
                    (layer : Fin depth) :
                    pairChildArrayAverageDisagreement
                      (hbase.trans
                        (pairLayer_card_ge_base baseSize layer.val hbase))
                      (pairGraphCopyParentWords retained copy layer)
                      (pairGraphCopyChildWords retained copy layer) ≤
                        (radius : ℝ) / (dimension : ℝ) := by
                  have pairChildArrayAverageDisagreement_le_radius
                      {parentCount dimension : ℕ}
                      (hparents : 4 ≤ parentCount)
                      (hdimension : 0 < dimension)
                      (parents : Fin parentCount → HammingWord dimension)
                      (children : PairLayer parentCount 1 → HammingWord dimension)
                      (radius : ℕ)
                      (hedges :
                        ∀ (pair : PairLayer parentCount 1)
                          (parent : PairLayer parentCount 0),
                          parent ∈ pair.val →
                            hammingDist (parents parent) (children pair) ≤ radius) :
                      pairChildArrayAverageDisagreement hparents parents children ≤
                        (radius : ℝ) / (dimension : ℝ) := by
                    have sum_pairCoordinatePairMismatchCount_eq_hammingDist
                        {parentCount dimension : ℕ}
                        (parents : Fin parentCount → HammingWord dimension)
                        (children : PairLayer parentCount 1 → HammingWord dimension) :
                        (∑ coordinate : Fin dimension,
                          ∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair) =
                          ∑ pair : PairLayer parentCount 1,
                            ∑ parent ∈ pair.val,
                              hammingDist (parents parent) (children pair) := by
                      classical
                      rw [Finset.sum_comm]
                      apply Finset.sum_congr rfl
                      intro pair _
                      have hcount (coordinate : Fin dimension) :
                          pairCoordinatePairMismatchCount parents children coordinate pair =
                            ∑ parent ∈ pair.val,
                              if parents parent coordinate ≠ children pair coordinate
                                then 1 else 0 := by
                        change
                          (pair.val.filter
                            (fun parent =>
                              parents parent coordinate ≠ children pair coordinate)).card = _
                        exact (Finset.sum_boole _ _).symm
                      simp_rw [hcount]
                      rw [Finset.sum_comm]
                      apply Finset.sum_congr rfl
                      intro parent _
                      change
                        (∑ coordinate : Fin dimension,
                          if parents parent coordinate ≠ children pair coordinate
                            then 1 else 0) =
                          ((Finset.univ : Finset (Fin dimension)).filter
                            (fun coordinate =>
                              parents parent coordinate ≠ children pair coordinate)).card
                      exact Finset.sum_boole _ _
                    have pairCoordinateKernel_empiricalAverageDisagreement_eq_mismatches
                        {parentCount dimension : ℕ}
                        (hparents : 2 ≤ parentCount)
                        (parents : Fin parentCount → HammingWord dimension)
                        (children : PairLayer parentCount 1 → HammingWord dimension)
                        (coordinate : Fin dimension) :
                        empiricalAverageDisagreement parentCount
                            (pairParentCoordinateOneCount parents coordinate)
                            (pairCoordinateKernel (by omega) parents children coordinate) =
                          ((∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair : ℕ) : ℝ) /
                            (2 * (parentCount.choose 2 : ℝ)) := by
                      have pairCoordinateKernel_empiricalAverageDisagreement
                          {parentCount dimension : ℕ}
                          (hparents : 2 ≤ parentCount)
                          (parents : Fin parentCount → HammingWord dimension)
                          (children : PairLayer parentCount 1 → HammingWord dimension)
                          (coordinate : Fin dimension) :
                          empiricalAverageDisagreement parentCount
                              (pairParentCoordinateOneCount parents coordinate)
                              (pairCoordinateKernel (by omega) parents children coordinate) =
                            (((pairTypeGroupChildOnes parents children coordinate 0).card : ℝ) +
                              ((pairTypeGroup parents coordinate 2).card : ℝ) / 2 +
                              (((pairTypeGroup parents coordinate 1).card : ℝ) -
                                ((pairTypeGroupChildOnes parents children coordinate 1).card : ℝ))) /
                              (parentCount.choose 2 : ℝ) := by
                        have pairTypeGroup_probability_mul_childComplement
                            {parentCount dimension : ℕ}
                            (hparents : 2 ≤ parentCount)
                            (parents : Fin parentCount → HammingWord dimension)
                            (children : PairLayer parentCount 1 → HammingWord dimension)
                            (coordinate : Fin dimension)
                            (bitType : PairBitType) :
                            ((pairTypeGroup parents coordinate bitType).card : ℝ) /
                                (parentCount.choose 2 : ℝ) *
                              (1 -
                                ((pairTypeGroupChildOnes parents children
                                    coordinate bitType).card : ℝ) /
                                  ((pairTypeGroup parents coordinate bitType).card : ℝ)) =
                              (((pairTypeGroup parents coordinate bitType).card : ℝ) -
                                ((pairTypeGroupChildOnes parents children
                                  coordinate bitType).card : ℝ)) /
                                  (parentCount.choose 2 : ℝ) := by
                          calc
                            ((pairTypeGroup parents coordinate bitType).card : ℝ) /
                                (parentCount.choose 2 : ℝ) *
                              (1 -
                                ((pairTypeGroupChildOnes parents children
                                    coordinate bitType).card : ℝ) /
                                  ((pairTypeGroup parents coordinate bitType).card : ℝ)) =
                              ((pairTypeGroup parents coordinate bitType).card : ℝ) /
                                  (parentCount.choose 2 : ℝ) -
                                (((pairTypeGroup parents coordinate bitType).card : ℝ) /
                                  (parentCount.choose 2 : ℝ) *
                                    (((pairTypeGroupChildOnes parents children
                                      coordinate bitType).card : ℝ) /
                                      ((pairTypeGroup parents coordinate bitType).card : ℝ))) := by
                                  ring
                            _ = ((pairTypeGroup parents coordinate bitType).card : ℝ) /
                                  (parentCount.choose 2 : ℝ) -
                                ((pairTypeGroupChildOnes parents children
                                  coordinate bitType).card : ℝ) /
                                  (parentCount.choose 2 : ℝ) := by
                                  rw [pairTypeGroup_probability_mul_childRatio
                                    hparents parents children coordinate bitType]
                            _ = (((pairTypeGroup parents coordinate bitType).card : ℝ) -
                                ((pairTypeGroupChildOnes parents children
                                  coordinate bitType).card : ℝ)) /
                                  (parentCount.choose 2 : ℝ) := by
                                  ring
                        have hzero := pairTypeGroup_probability_mul_childRatio
                          hparents parents children coordinate 0
                        have hone := pairTypeGroup_probability_mul_childComplement
                          hparents parents children coordinate 1
                        calc
                          empiricalAverageDisagreement parentCount
                              (pairParentCoordinateOneCount parents coordinate)
                              (pairCoordinateKernel (by omega) parents children coordinate) =
                            ((pairTypeGroup parents coordinate 0).card : ℝ) /
                                (parentCount.choose 2 : ℝ) *
                              (((pairTypeGroupChildOnes parents children
                                coordinate 0).card : ℝ) /
                                  ((pairTypeGroup parents coordinate 0).card : ℝ)) +
                            ((pairTypeGroup parents coordinate 2).card : ℝ) /
                                (parentCount.choose 2 : ℝ) * (1 / 2 : ℝ) +
                            ((pairTypeGroup parents coordinate 1).card : ℝ) /
                                (parentCount.choose 2 : ℝ) *
                              (1 -
                                ((pairTypeGroupChildOnes parents children
                                  coordinate 1).card : ℝ) /
                                    ((pairTypeGroup parents coordinate 1).card : ℝ)) := by
                            unfold empiricalAverageDisagreement
                              withoutReplacementBinaryPairExpectation
                            simp_rw [withoutReplacementBinaryPairMass_eq_pairTypeGroup
                              hparents parents coordinate]
                            simp [Fintype.univ_bool,
                              pairCoordinateKernel_childProbability,
                              pairBitTypeOfOutcomes,
                              BinaryPairKernel.bitDisagreementProbability]
                            ring
                          _ =
                            (((pairTypeGroupChildOnes parents children coordinate 0).card : ℝ) +
                              ((pairTypeGroup parents coordinate 2).card : ℝ) / 2 +
                              (((pairTypeGroup parents coordinate 1).card : ℝ) -
                                ((pairTypeGroupChildOnes parents children coordinate 1).card : ℝ))) /
                              (parentCount.choose 2 : ℝ) := by
                            rw [hzero, hone]
                            ring
                      have sum_pairCoordinatePairMismatchCount
                          {parentCount dimension : ℕ}
                          (parents : Fin parentCount → HammingWord dimension)
                          (children : PairLayer parentCount 1 → HammingWord dimension)
                          (coordinate : Fin dimension) :
                          (∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair) =
                            2 * (pairTypeGroupChildOnes parents children coordinate 0).card +
                            (pairTypeGroup parents coordinate 2).card +
                            2 *
                              ((pairTypeGroup parents coordinate 1).card -
                                (pairTypeGroupChildOnes parents children coordinate 1).card) := by
                        have pairCoordinatePairMismatchCount_sum_false
                            {parentCount dimension : ℕ}
                            (parents : Fin parentCount → HammingWord dimension)
                            (children : PairLayer parentCount 1 → HammingWord dimension)
                            (coordinate : Fin dimension) :
                            (∑ pair ∈ pairTypeGroup parents coordinate 0,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              2 * (pairTypeGroupChildOnes parents children coordinate 0).card := by
                          classical
                          calc
                            (∑ pair ∈ pairTypeGroup parents coordinate 0,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              ∑ pair ∈ pairTypeGroup parents coordinate 0,
                                if children pair coordinate = true then 2 else 0 := by
                                apply Finset.sum_congr rfl
                                intro pair hpair
                                have hmembership :
                                    pair ∈
                                      (Finset.univ.filter
                                        (fun candidate : PairLayer parentCount 1 =>
                                          pairCoordinateBitType parents coordinate candidate = 0)) := by
                                  simpa only [pairTypeGroup] using hpair
                                have hgroup := (Finset.mem_filter.mp hmembership).2
                                have hterm := pairCoordinatePairMismatchCount_homogeneous
                                  parents children coordinate pair false hgroup
                                cases hchild : children pair coordinate <;>
                                  simpa [hchild] using hterm
                            _ = 2 * (pairTypeGroupChildOnes parents children coordinate 0).card := by
                              rw [← Finset.sum_filter]
                              simp [pairTypeGroupChildOnes, Nat.mul_comm]
                        have pairCoordinatePairMismatchCount_sum_true
                            {parentCount dimension : ℕ}
                            (parents : Fin parentCount → HammingWord dimension)
                            (children : PairLayer parentCount 1 → HammingWord dimension)
                            (coordinate : Fin dimension) :
                            (∑ pair ∈ pairTypeGroup parents coordinate 1,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              2 *
                                ((pairTypeGroup parents coordinate 1).card -
                                  (pairTypeGroupChildOnes parents children coordinate 1).card) := by
                          classical
                          let zeroChildren : Finset (PairLayer parentCount 1) :=
                            (pairTypeGroup parents coordinate 1).filter
                              (fun pair => children pair coordinate = false)
                          have hpartition :
                              (pairTypeGroupChildOnes parents children coordinate 1).card +
                                zeroChildren.card =
                                  (pairTypeGroup parents coordinate 1).card := by
                            have hfilter := Finset.card_filter_add_card_filter_not
                              (s := pairTypeGroup parents coordinate 1)
                              (fun pair => children pair coordinate = true)
                            simpa [pairTypeGroupChildOnes, zeroChildren] using hfilter
                          have hzero_card :
                              zeroChildren.card =
                                (pairTypeGroup parents coordinate 1).card -
                                  (pairTypeGroupChildOnes parents children coordinate 1).card := by
                            omega
                          calc
                            (∑ pair ∈ pairTypeGroup parents coordinate 1,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              ∑ pair ∈ pairTypeGroup parents coordinate 1,
                                if children pair coordinate = false then 2 else 0 := by
                                apply Finset.sum_congr rfl
                                intro pair hpair
                                have hmembership :
                                    pair ∈
                                      (Finset.univ.filter
                                        (fun candidate : PairLayer parentCount 1 =>
                                          pairCoordinateBitType parents coordinate candidate = 1)) := by
                                  simpa only [pairTypeGroup] using hpair
                                have hgroup := (Finset.mem_filter.mp hmembership).2
                                have hterm := pairCoordinatePairMismatchCount_homogeneous
                                  parents children coordinate pair true hgroup
                                cases hchild : children pair coordinate <;>
                                  simpa [hchild] using hterm
                            _ = 2 * zeroChildren.card := by
                              rw [← Finset.sum_filter]
                              simp [zeroChildren, Nat.mul_comm]
                            _ = 2 *
                                ((pairTypeGroup parents coordinate 1).card -
                                  (pairTypeGroupChildOnes parents children coordinate 1).card) := by
                              rw [hzero_card]
                        have pairCoordinatePairMismatchCount_sum_mixed
                            {parentCount dimension : ℕ}
                            (parents : Fin parentCount → HammingWord dimension)
                            (children : PairLayer parentCount 1 → HammingWord dimension)
                            (coordinate : Fin dimension) :
                            (∑ pair ∈ pairTypeGroup parents coordinate 2,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              (pairTypeGroup parents coordinate 2).card := by
                          have pairCoordinatePairMismatchCount_mixed
                              {parentCount dimension : ℕ}
                              (parents : Fin parentCount → HammingWord dimension)
                              (children : PairLayer parentCount 1 → HammingWord dimension)
                              (coordinate : Fin dimension)
                              (pair : PairLayer parentCount 1)
                              (hgroup : pairCoordinateBitType parents coordinate pair = 2) :
                              pairCoordinatePairMismatchCount parents children coordinate pair = 1 := by
                            classical
                            have hnotfalse :
                                ¬ ∀ parent ∈ pair.val, parents parent coordinate = false := by
                              intro hfalse
                              have hzero :=
                                (pairCoordinateBitType_homogeneous_iff
                                  parents coordinate pair false).mpr hfalse
                              rw [hgroup] at hzero
                              simp at hzero
                            have hnottrue :
                                ¬ ∀ parent ∈ pair.val, parents parent coordinate = true := by
                              intro htrue
                              have hone :=
                                (pairCoordinateBitType_homogeneous_iff
                                  parents coordinate pair true).mpr htrue
                              rw [hgroup] at hone
                              simp at hone
                            have hexfalse :
                                ∃ parent ∈ pair.val, parents parent coordinate = false := by grind
                            have hextrue :
                                ∃ parent ∈ pair.val, parents parent coordinate = true := by grind
                            obtain ⟨falseParent, hfalseParent, hfalseBit⟩ := hexfalse
                            obtain ⟨trueParent, htrueParent, htrueBit⟩ := hextrue
                            let mismatches : Finset (PairLayer parentCount 0) :=
                              pair.val.filter
                                (fun parent =>
                                  parents parent coordinate ≠ children pair coordinate)
                            let agreements : Finset (PairLayer parentCount 0) :=
                              pair.val.filter
                                (fun parent =>
                                  ¬ parents parent coordinate ≠ children pair coordinate)
                            have hmismatch : mismatches.Nonempty := by
                              cases hchild : children pair coordinate
                              · refine ⟨trueParent, ?_⟩
                                simp [mismatches, htrueParent, htrueBit, hchild]
                              · refine ⟨falseParent, ?_⟩
                                simp [mismatches, hfalseParent, hfalseBit, hchild]
                            have hagreement : agreements.Nonempty := by
                              cases hchild : children pair coordinate
                              · refine ⟨falseParent, ?_⟩
                                simp [agreements, hfalseParent, hfalseBit, hchild]
                              · refine ⟨trueParent, ?_⟩
                                simp [agreements, htrueParent, htrueBit, hchild]
                            have hpartition : mismatches.card + agreements.card = 2 := by
                              have hfilter := Finset.card_filter_add_card_filter_not
                                (s := pair.val)
                                (fun parent =>
                                  parents parent coordinate ≠ children pair coordinate)
                              change mismatches.card + agreements.card = pair.val.card at hfilter
                              simpa [pair.property] using hfilter
                            have hmismatch_pos := Finset.card_pos.mpr hmismatch
                            have hagreement_pos := Finset.card_pos.mpr hagreement
                            change mismatches.card = 1
                            omega
                          classical
                          calc
                            (∑ pair ∈ pairTypeGroup parents coordinate 2,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              ∑ _pair ∈ pairTypeGroup parents coordinate 2, 1 := by
                                apply Finset.sum_congr rfl
                                intro pair hpair
                                have hmembership :
                                    pair ∈
                                      (Finset.univ.filter
                                        (fun candidate : PairLayer parentCount 1 =>
                                          pairCoordinateBitType parents coordinate candidate = 2)) := by
                                  simpa only [pairTypeGroup] using hpair
                                exact pairCoordinatePairMismatchCount_mixed
                                  parents children coordinate pair
                                    (Finset.mem_filter.mp hmembership).2
                            _ = (pairTypeGroup parents coordinate 2).card := by simp
                        classical
                        have hmaps :
                            (((Finset.univ : Finset (PairLayer parentCount 1)) :
                              Set (PairLayer parentCount 1))).MapsTo
                                (pairCoordinateBitType parents coordinate)
                                (Finset.univ : Finset PairBitType) := by simp [*]
                        have hfiber :=
                          (Finset.sum_fiberwise_of_maps_to hmaps
                            (fun pair =>
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair)).symm
                        have hpartition :
                            (∑ pair : PairLayer parentCount 1,
                              pairCoordinatePairMismatchCount
                                parents children coordinate pair) =
                              (∑ pair ∈ pairTypeGroup parents coordinate 0,
                                pairCoordinatePairMismatchCount
                                  parents children coordinate pair) +
                              (∑ pair ∈ pairTypeGroup parents coordinate 1,
                                pairCoordinatePairMismatchCount
                                  parents children coordinate pair) +
                              (∑ pair ∈ pairTypeGroup parents coordinate 2,
                                pairCoordinatePairMismatchCount
                                  parents children coordinate pair) := by
                          simpa [pairTypeGroup, Fin.sum_univ_succ, add_assoc] using hfiber
                        rw [pairCoordinatePairMismatchCount_sum_false,
                          pairCoordinatePairMismatchCount_sum_true,
                          pairCoordinatePairMismatchCount_sum_mixed] at hpartition
                        omega
                      have hpair : 0 < (parentCount.choose 2 : ℝ) := by
                        exact_mod_cast Nat.choose_pos hparents
                      have hone := pairTypeGroupChildOnes_card_le
                        parents children coordinate 1
                      rw [pairCoordinateKernel_empiricalAverageDisagreement
                        hparents parents children coordinate,
                        sum_pairCoordinatePairMismatchCount]
                      push_cast [hone]
                      field_simp [hpair.ne']
                    classical
                    have hpair : 0 < (parentCount.choose 2 : ℝ) := by
                      exact_mod_cast Nat.choose_pos (by omega : 2 ≤ parentCount)
                    have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                    have htotal :
                        (∑ coordinate : Fin dimension,
                          ∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair) ≤
                          2 * parentCount.choose 2 * radius := by
                      calc
                        (∑ coordinate : Fin dimension,
                          ∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair) =
                          ∑ pair : PairLayer parentCount 1,
                            ∑ parent ∈ pair.val,
                              hammingDist (parents parent) (children pair) :=
                          sum_pairCoordinatePairMismatchCount_eq_hammingDist
                            parents children
                        _ ≤ ∑ pair : PairLayer parentCount 1,
                            ∑ _parent ∈ pair.val, radius := by
                          apply Finset.sum_le_sum
                          intro pair _
                          apply Finset.sum_le_sum
                          intro parent hparent
                          exact hedges pair parent hparent
                        _ = ∑ _pair : PairLayer parentCount 1, 2 * radius := by
                          apply Finset.sum_congr rfl
                          intro pair _
                          simp [pair.property]
                        _ = 2 * parentCount.choose 2 * radius := by
                          simp [pairLayer_card_succ, pairLayer_card_zero,
                            Nat.mul_assoc, Nat.mul_comm]
                    have htotal_real :
                        (∑ coordinate : Fin dimension,
                          ((∑ pair : PairLayer parentCount 1,
                            pairCoordinatePairMismatchCount
                              parents children coordinate pair : ℕ) : ℝ)) ≤
                          2 * (parentCount.choose 2 : ℝ) * (radius : ℝ) := by
                      exact_mod_cast htotal
                    unfold pairChildArrayAverageDisagreement
                    simp_rw [pairCoordinateKernel_empiricalAverageDisagreement_eq_mismatches
                      (by omega : 2 ≤ parentCount) parents children]
                    rw [← Finset.sum_div]
                    apply (div_le_div_iff_of_pos_right hdimension_real).mpr
                    apply (div_le_iff₀ (mul_pos (by norm_num) hpair)).mpr
                    nlinarith
                  have pairGraphCopy_parent_child_hammingDist_le
                      {baseSize depth dimension radius : ℕ}
                      (retained : Set (Bool × HammingWord dimension))
                      (copy : SimpleGraph.Copy
                        (pairParentSystem baseSize depth).graph
                        (retainedHammingHost dimension radius retained))
                      (layer : Fin depth)
                      (pair :
                        PairLayer (Fintype.card (PairLayer baseSize layer.val)) 1)
                      (parent :
                        PairLayer (Fintype.card (PairLayer baseSize layer.val)) 0)
                      (hparent : parent ∈ pair.val) :
                      hammingDist
                        (pairGraphCopyParentWords retained copy layer parent)
                        (pairGraphCopyChildWords retained copy layer pair) ≤ radius := by
                    have hactualParent :
                        (pairLayerFinEquiv baseSize layer.val).symm parent ∈
                          ((pairLayerPairEquiv baseSize layer.val) pair).val := by
                      change
                        (pairLayerFinEquiv baseSize layer.val).symm parent ∈
                          pair.val.map
                            (pairLayerFinEquiv baseSize layer.val).symm.toEmbedding
                      exact Finset.mem_map.mpr ⟨parent, hparent, rfl⟩
                    have hsource := pairGraph_parent_child_adj
                      baseSize depth layer.val (by omega)
                        ((pairLayerPairEquiv baseSize layer.val) pair)
                        ((pairLayerFinEquiv baseSize layer.val).symm parent)
                        hactualParent
                    have hedge := copy.toHom.map_rel hsource
                    change
                      (hammingHost dimension radius).Adj
                        (copy
                          (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                            ((pairLayerPairEquiv baseSize layer.val) pair))).val
                        (copy
                          (pairLayerEmbedding baseSize depth layer.val (by omega)
                            ((pairLayerFinEquiv baseSize layer.val).symm parent))).val at hedge
                    have hdist :=
                      ((hammingHost_adj_iff dimension radius _ _).mp hedge).2
                    simpa [pairGraphCopyParentWords, pairGraphCopyChildWords,
                      hammingDist_comm] using hdist
                  apply pairChildArrayAverageDisagreement_le_radius
                    (hbase.trans
                      (pairLayer_card_ge_base baseSize layer.val hbase))
                    hdimension
                    (pairGraphCopyParentWords retained copy layer)
                    (pairGraphCopyChildWords retained copy layer)
                    radius
                  intro pair parent hparent
                  exact pairGraphCopy_parent_child_hammingDist_le
                    retained copy layer pair parent hparent
                have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                calc
                  pairChildArrayAverageDisagreement
                    (hbase.trans
                      (pairLayer_card_ge_base baseSize layer.val hbase))
                    (pairGraphCopyParentWords retained copy layer)
                    (pairGraphCopyChildWords retained copy layer) ≤
                      (radius : ℝ) / (dimension : ℝ) :=
                    pairGraphCopy_averageDisagreement_le_radius
                      hbase hdimension retained copy layer
                  _ ≤ tau :=
                    (div_le_iff₀ hdimension_real).mpr hradius
              have pairGraphOverFin_free_of_layer_exclusion_and_disagreement
                  {baseSize depth dimension radius : ℕ}
                  (hbase : 4 ≤ baseSize)
                  (hdimension : 0 < dimension)
                  (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2))
                  (retained : Set (Bool × HammingWord dimension))
                  (hexclusion :
                    ∀ (side : Bool) (layer : Fin depth),
                      retained ∉
                        badPairLayerRetentionEvent
                          (Fintype.card (PairLayer baseSize layer.val))
                          dimension side (midpointBeta - entropySlack))
                  (herror :
                    ∀ layer : Fin depth,
                      empiricalEntropyError
                        (Fintype.card (PairLayer baseSize layer.val)) < entropySlack)
                  (hdisagreement :
                    ∀ (copy : SimpleGraph.Copy
                        (pairParentSystem baseSize depth).graph
                        (retainedHammingHost dimension radius retained))
                      (layer : Fin depth),
                        pairChildArrayAverageDisagreement
                          (hbase.trans
                            (pairLayer_card_ge_base baseSize layer.val hbase))
                          (pairGraphCopyParentWords retained copy layer)
                          (pairGraphCopyChildWords retained copy layer) ≤ tau) :
                  (pairGraphOverFin baseSize depth).Free
                    (retainedHammingHost dimension radius retained) := by
                have pairGraph_free_of_layer_exclusion_and_disagreement
                    {baseSize depth dimension radius : ℕ}
                    (hbase : 4 ≤ baseSize)
                    (hdimension : 0 < dimension)
                    (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2))
                    (retained : Set (Bool × HammingWord dimension))
                    (hexclusion :
                      ∀ (side : Bool) (layer : Fin depth),
                        retained ∉
                          badPairLayerRetentionEvent
                            (Fintype.card (PairLayer baseSize layer.val))
                            dimension side (midpointBeta - entropySlack))
                    (herror :
                      ∀ layer : Fin depth,
                        empiricalEntropyError
                          (Fintype.card (PairLayer baseSize layer.val)) < entropySlack)
                    (hdisagreement :
                      ∀ (copy : SimpleGraph.Copy
                          (pairParentSystem baseSize depth).graph
                          (retainedHammingHost dimension radius retained))
                        (layer : Fin depth),
                          pairChildArrayAverageDisagreement
                            (hbase.trans
                              (pairLayer_card_ge_base baseSize layer.val hbase))
                            (pairGraphCopyParentWords retained copy layer)
                            (pairGraphCopyChildWords retained copy layer) ≤ tau) :
                    (pairParentSystem baseSize depth).graph.Free
                      (retainedHammingHost dimension radius retained) := by
                  have entropy_layer_exclusion
                      (depth : ℕ) (potential conditionalEntropy error : ℕ → ℝ)
                      (hrange : ∀ i ≤ depth, 0 ≤ potential i ∧ potential i ≤ 1)
                      (herror : ∀ i < depth, error i < entropySlack)
                      (hlower : ∀ i < depth,
                        midpointBeta - entropySlack < conditionalEntropy i)
                      (hupper : ∀ i < depth,
                        conditionalEntropy i ≤
                          entropyLowerEndpoint +
                            (potential (i + 1) - potential i) / 2 + error i)
                      (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2)) : False := by
                    have entropy_potential_increment
                        (potentialBefore potentialAfter conditionalEntropy error : ℝ)
                        (herror : error < entropySlack)
                        (hlower : midpointBeta - entropySlack < conditionalEntropy)
                        (hupper : conditionalEntropy ≤
                          entropyLowerEndpoint +
                            (potentialAfter - potentialBefore) / 2 + error) :
                        certifiedWindowWidth / 2 < potentialAfter - potentialBefore := by
                      have hwindow := entropyWindow_eq_certifiedWindowWidth
                      unfold midpointBeta entropySlack at hlower
                      unfold entropySlack at herror
                      linarith
                    have entropy_potential_layers_impossible
                        (depth : ℕ) (potential : ℕ → ℝ)
                        (hrange : ∀ i ≤ depth, 0 ≤ potential i ∧ potential i ≤ 1)
                        (hincrement : ∀ i < depth,
                          certifiedWindowWidth / 2 < potential (i + 1) - potential i)
                        (hdepth : 1 < (depth : ℝ) * (certifiedWindowWidth / 2)) : False := by
                      have htotal :
                          ∀ i ≤ depth,
                            (i : ℝ) * (certifiedWindowWidth / 2) ≤
                              potential i - potential 0 := by
                        intro i hi
                        induction i with
                        | zero => simp
                        | succ i ih =>
                            have hiprev : i ≤ depth := by omega
                            have histep : i < depth := by omega
                            have hprevious := ih hiprev
                            have hnext := (hincrement i histep).le
                            push_cast
                            linarith
                      have hstart := (hrange 0 (by omega)).1
                      have hfinish := (hrange depth le_rfl).2
                      have hsum := htotal depth le_rfl
                      linarith
                    apply entropy_potential_layers_impossible depth potential hrange
                      (hdepth := hdepth)
                    intro i hi
                    exact entropy_potential_increment (potential i) (potential (i + 1))
                      (conditionalEntropy i) (error i)
                      (herror i hi) (hlower i hi) (hupper i hi)
                  have pairLayerPair_nonempty
                      {parentCount : ℕ}
                      (hparents : 2 ≤ parentCount) :
                      Nonempty (PairLayer parentCount 1) := by
                    apply Fintype.card_pos_iff.mp
                    rw [pairLayer_card_succ parentCount 0,
                      pairLayer_card_zero]
                    exact Nat.choose_pos hparents
                  have pairGraphCopyLayerPotential_mem_Icc
                      {baseSize depth dimension radius : ℕ}
                      (hbase : 4 ≤ baseSize)
                      (hdimension : 0 < dimension)
                      (retained : Set (Bool × HammingWord dimension))
                      (copy : SimpleGraph.Copy
                        (pairParentSystem baseSize depth).graph
                        (retainedHammingHost dimension radius retained))
                      (layer : Fin (depth + 1)) :
                      0 ≤ pairGraphCopyLayerPotential retained copy layer ∧
                        pairGraphCopyLayerPotential retained copy layer ≤ 1 := by
                    classical
                    have hlayer : 0 < Fintype.card (PairLayer baseSize layer.val) := by
                      have hcard := pairLayer_card_ge_base
                        baseSize layer.val hbase
                      omega
                    have hlayer_real : 0 < (Fintype.card (PairLayer baseSize layer.val) : ℝ) := by
                      exact_mod_cast hlayer
                    have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                    have hterm (coordinate : Fin dimension) :
                        0 ≤
                          binaryEntropy
                            (((booleanWordOnes
                              (fun vertex : PairLayer baseSize layer.val =>
                                (copy
                                  (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                    vertex)).val.2 coordinate)).card : ℝ) /
                                (Fintype.card (PairLayer baseSize layer.val) : ℝ)) ∧
                        binaryEntropy
                            (((booleanWordOnes
                              (fun vertex : PairLayer baseSize layer.val =>
                                (copy
                                  (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                    vertex)).val.2 coordinate)).card : ℝ) /
                                (Fintype.card (PairLayer baseSize layer.val) : ℝ)) ≤ 1 := by
                      have hcount :
                          (booleanWordOnes
                            (fun vertex : PairLayer baseSize layer.val =>
                              (copy
                                (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                  vertex)).val.2 coordinate)).card ≤
                            Fintype.card (PairLayer baseSize layer.val) := by
                        unfold booleanWordOnes
                        simpa using
                          (Finset.card_filter_le
                            (Finset.univ : Finset (PairLayer baseSize layer.val))
                            (fun vertex =>
                              (copy
                                (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                  vertex)).val.2 coordinate = true))
                      have hzero :
                          0 ≤
                            ((booleanWordOnes
                              (fun vertex : PairLayer baseSize layer.val =>
                                (copy
                                  (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                    vertex)).val.2 coordinate)).card : ℝ) /
                              (Fintype.card (PairLayer baseSize layer.val) : ℝ) := by
                        positivity
                      have hone :
                          ((booleanWordOnes
                            (fun vertex : PairLayer baseSize layer.val =>
                              (copy
                                (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                  vertex)).val.2 coordinate)).card : ℝ) /
                              (Fintype.card (PairLayer baseSize layer.val) : ℝ) ≤ 1 := by
                        apply (div_le_one hlayer_real).mpr
                        exact_mod_cast hcount
                      exact ⟨binaryEntropy_nonneg hzero hone,
                        binaryEntropy_le_one _⟩
                    unfold pairGraphCopyLayerPotential
                    constructor
                    · apply div_nonneg
                      · exact Finset.sum_nonneg
                          (fun coordinate _ => (hterm coordinate).1)
                      · exact hdimension_real.le
                    · apply (div_le_one hdimension_real).mpr
                      calc
                        (∑ coordinate : Fin dimension,
                          binaryEntropy
                            (((booleanWordOnes
                              (fun vertex : PairLayer baseSize layer.val =>
                                (copy
                                  (pairLayerEmbedding baseSize depth layer.val layer.isLt
                                    vertex)).val.2 coordinate)).card : ℝ) /
                                (Fintype.card (PairLayer baseSize layer.val) : ℝ))) ≤
                          ∑ _coordinate : Fin dimension, (1 : ℝ) := by
                            exact Finset.sum_le_sum
                              (fun coordinate _ => (hterm coordinate).2)
                        _ = (dimension : ℝ) := by simp
                  have pairGraphCopy_layer_entropy_upper_of_disagreement
                      {baseSize depth dimension radius : ℕ}
                      (hbase : 4 ≤ baseSize)
                      (hdimension : 0 < dimension)
                      (retained : Set (Bool × HammingWord dimension))
                      (copy : SimpleGraph.Copy
                        (pairParentSystem baseSize depth).graph
                        (retainedHammingHost dimension radius retained))
                      (layer : Fin depth)
                      (hdisagreement :
                        pairChildArrayAverageDisagreement
                          (hbase.trans
                            (pairLayer_card_ge_base baseSize layer.val hbase))
                          (pairGraphCopyParentWords retained copy layer)
                          (pairGraphCopyChildWords retained copy layer) ≤ tau) :
                      pairChildArrayEntropy
                        (pairGraphCopyParentWords retained copy layer)
                        (pairGraphCopyChildWords retained copy layer) ≤
                          entropyLowerEndpoint +
                            (pairGraphCopyLayerPotential retained copy
                                ⟨layer.val + 1, by omega⟩ -
                              pairGraphCopyLayerPotential retained copy
                                ⟨layer.val, by omega⟩) / 2 +
                            empiricalEntropyError
                              (Fintype.card (PairLayer baseSize layer.val)) := by
                    have pairChildArrayEntropy_empirical_bound
                        {parentCount dimension : ℕ}
                        (hparents : 4 ≤ parentCount)
                        (hdimension : 0 < dimension)
                        (parents : Fin parentCount → HammingWord dimension)
                        (children : PairLayer parentCount 1 → HammingWord dimension) :
                        pairChildArrayEntropy parents children ≤
                          kappa +
                            logTwo 3 *
                              pairChildArrayAverageDisagreement hparents parents children +
                            (pairChildArrayEntropyPotential children -
                              pairParentArrayEntropyPotential parents) / 2 +
                            empiricalEntropyError parentCount := by
                      have hdimension_real : 0 < (dimension : ℝ) := by exact_mod_cast hdimension
                      have hsum :
                          (∑ coordinate : Fin dimension,
                            pairCoordinateConditionalEntropy parents children coordinate) ≤
                          ∑ coordinate : Fin dimension,
                            (kappa +
                              logTwo 3 *
                                empiricalAverageDisagreement parentCount
                                  (pairParentCoordinateOneCount parents coordinate)
                                  (pairCoordinateKernel (by omega)
                                    parents children coordinate) +
                              (binaryEntropy
                                  ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                    (parentCount.choose 2 : ℝ)) -
                                binaryEntropy
                                  ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                    (parentCount : ℝ))) / 2 +
                              empiricalEntropyError parentCount) := by
                        apply Finset.sum_le_sum
                        intro coordinate _
                        exact pairCoordinateConditionalEntropy_empirical_bound
                          hparents parents children coordinate
                      have hnormalized :=
                        (div_le_div_iff_of_pos_right hdimension_real).mpr hsum
                      change pairChildArrayEntropy parents children ≤ _ at hnormalized
                      let disagreementSum : ℝ :=
                        ∑ coordinate : Fin dimension,
                          empiricalAverageDisagreement parentCount
                            (pairParentCoordinateOneCount parents coordinate)
                            (pairCoordinateKernel (by omega)
                              parents children coordinate)
                      let childEntropySum : ℝ :=
                        ∑ coordinate : Fin dimension,
                          binaryEntropy
                            ((pairChildCoordinateOneCount children coordinate : ℝ) /
                              (parentCount.choose 2 : ℝ))
                      let parentEntropySum : ℝ :=
                        ∑ coordinate : Fin dimension,
                          binaryEntropy
                            ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                              (parentCount : ℝ))
                      have hentropy_sum :
                          (∑ coordinate : Fin dimension,
                            (binaryEntropy
                                ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                  (parentCount.choose 2 : ℝ)) -
                              binaryEntropy
                                ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                  (parentCount : ℝ))) / 2) =
                            (childEntropySum - parentEntropySum) / 2 := by
                        dsimp [childEntropySum, parentEntropySum]
                        rw [← Finset.sum_div, Finset.sum_sub_distrib]
                      have hsum_formula :
                          (∑ coordinate : Fin dimension,
                            (kappa +
                              logTwo 3 *
                                empiricalAverageDisagreement parentCount
                                  (pairParentCoordinateOneCount parents coordinate)
                                  (pairCoordinateKernel (by omega)
                                    parents children coordinate) +
                              (binaryEntropy
                                  ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                    (parentCount.choose 2 : ℝ)) -
                                binaryEntropy
                                  ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                    (parentCount : ℝ))) / 2 +
                              empiricalEntropyError parentCount)) =
                            (dimension : ℝ) * kappa +
                              logTwo 3 * disagreementSum +
                              (childEntropySum - parentEntropySum) / 2 +
                              (dimension : ℝ) * empiricalEntropyError parentCount := by
                        calc
                          (∑ coordinate : Fin dimension,
                            (kappa +
                              logTwo 3 *
                                empiricalAverageDisagreement parentCount
                                  (pairParentCoordinateOneCount parents coordinate)
                                  (pairCoordinateKernel (by omega)
                                    parents children coordinate) +
                              (binaryEntropy
                                  ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                    (parentCount.choose 2 : ℝ)) -
                                binaryEntropy
                                  ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                    (parentCount : ℝ))) / 2 +
                              empiricalEntropyError parentCount)) =
                            (∑ _coordinate : Fin dimension, kappa) +
                              (∑ coordinate : Fin dimension,
                                logTwo 3 *
                                  empiricalAverageDisagreement parentCount
                                    (pairParentCoordinateOneCount parents coordinate)
                                    (pairCoordinateKernel (by omega)
                                      parents children coordinate)) +
                              (∑ coordinate : Fin dimension,
                                (binaryEntropy
                                    ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                      (parentCount.choose 2 : ℝ)) -
                                  binaryEntropy
                                    ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                      (parentCount : ℝ))) / 2) +
                              (∑ _coordinate : Fin dimension,
                                empiricalEntropyError parentCount) := by
                                simp only [Finset.sum_add_distrib]
                          _ = (dimension : ℝ) * kappa +
                              logTwo 3 * disagreementSum +
                              (childEntropySum - parentEntropySum) / 2 +
                              (dimension : ℝ) * empiricalEntropyError parentCount := by
                            rw [hentropy_sum]
                            dsimp [disagreementSum]
                            rw [← Finset.mul_sum]
                            simp [nsmul_eq_mul]
                      calc
                        pairChildArrayEntropy parents children ≤
                          (∑ coordinate : Fin dimension,
                            (kappa +
                              logTwo 3 *
                                empiricalAverageDisagreement parentCount
                                  (pairParentCoordinateOneCount parents coordinate)
                                  (pairCoordinateKernel (by omega)
                                    parents children coordinate) +
                              (binaryEntropy
                                  ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                    (parentCount.choose 2 : ℝ)) -
                                binaryEntropy
                                  ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                    (parentCount : ℝ))) / 2 +
                              empiricalEntropyError parentCount)) /
                                (dimension : ℝ) := hnormalized
                        _ = kappa +
                            logTwo 3 *
                              pairChildArrayAverageDisagreement hparents parents children +
                            (pairChildArrayEntropyPotential children -
                              pairParentArrayEntropyPotential parents) / 2 +
                            empiricalEntropyError parentCount := by
                          change
                            (∑ coordinate : Fin dimension,
                              (kappa +
                                logTwo 3 *
                                  empiricalAverageDisagreement parentCount
                                    (pairParentCoordinateOneCount parents coordinate)
                                    (pairCoordinateKernel (by omega)
                                      parents children coordinate) +
                                (binaryEntropy
                                    ((pairChildCoordinateOneCount children coordinate : ℝ) /
                                      (parentCount.choose 2 : ℝ)) -
                                  binaryEntropy
                                    ((pairParentCoordinateOneCount parents coordinate : ℝ) /
                                      (parentCount : ℝ))) / 2 +
                                empiricalEntropyError parentCount)) /
                                  (dimension : ℝ) =
                              kappa +
                                logTwo 3 * (disagreementSum / (dimension : ℝ)) +
                                (childEntropySum / (dimension : ℝ) -
                                  parentEntropySum / (dimension : ℝ)) / 2 +
                                empiricalEntropyError parentCount
                          rw [hsum_formula]
                          field_simp [hdimension_real.ne']
                    have pairGraphCopy_parentPotential_eq
                        {baseSize depth dimension radius : ℕ}
                        (retained : Set (Bool × HammingWord dimension))
                        (copy : SimpleGraph.Copy
                          (pairParentSystem baseSize depth).graph
                          (retainedHammingHost dimension radius retained))
                        (layer : Fin depth) :
                        pairParentArrayEntropyPotential
                            (pairGraphCopyParentWords retained copy layer) =
                          pairGraphCopyLayerPotential retained copy
                            ⟨layer.val, by omega⟩ := by
                      unfold pairParentArrayEntropyPotential
                        pairGraphCopyLayerPotential
                      apply congrArg (fun numerator : ℝ => numerator / (dimension : ℝ))
                      apply Finset.sum_congr rfl
                      intro coordinate _
                      unfold pairParentCoordinateOneCount pairGraphCopyParentWords
                      rw [booleanWordOnes_card_equiv
                        (pairLayerFinEquiv baseSize layer.val).symm
                        (fun vertex : PairLayer baseSize layer.val =>
                          (copy
                            (pairLayerEmbedding baseSize depth layer.val (by omega)
                              vertex)).val.2 coordinate)]
                    have pairGraphCopy_childPotential_eq
                        {baseSize depth dimension radius : ℕ}
                        (retained : Set (Bool × HammingWord dimension))
                        (copy : SimpleGraph.Copy
                          (pairParentSystem baseSize depth).graph
                          (retainedHammingHost dimension radius retained))
                        (layer : Fin depth) :
                        pairChildArrayEntropyPotential
                            (pairGraphCopyChildWords retained copy layer) =
                          pairGraphCopyLayerPotential retained copy
                            ⟨layer.val + 1, by omega⟩ := by
                      unfold pairChildArrayEntropyPotential
                        pairGraphCopyLayerPotential
                      apply congrArg (fun numerator : ℝ => numerator / (dimension : ℝ))
                      apply Finset.sum_congr rfl
                      intro coordinate _
                      unfold pairChildCoordinateOneCount pairGraphCopyChildWords
                      rw [booleanWordOnes_card_equiv
                        (pairLayerPairEquiv baseSize layer.val)
                        (fun vertex : PairLayer baseSize (layer.val + 1) =>
                          (copy
                            (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                              vertex)).val.2 coordinate)]
                      rw [pairLayer_card_succ]
                    have hparents : 4 ≤ Fintype.card (PairLayer baseSize layer.val) :=
                      hbase.trans
                        (pairLayer_card_ge_base baseSize layer.val hbase)
                    have hbound := pairChildArrayEntropy_empirical_bound
                      hparents hdimension
                      (pairGraphCopyParentWords retained copy layer)
                      (pairGraphCopyChildWords retained copy layer)
                    rw [pairGraphCopy_childPotential_eq retained copy layer,
                      pairGraphCopy_parentPotential_eq retained copy layer] at hbound
                    have hscaled := mul_le_mul_of_nonneg_left
                      hdisagreement logTwo_three_pos.le
                    unfold entropyLowerEndpoint
                    nlinarith
                  have pairGraphCopy_entropy_lower_of_exclusion
                      {baseSize depth dimension radius : ℕ}
                      (retained : Set (Bool × HammingWord dimension))
                      (copy : SimpleGraph.Copy
                        (pairParentSystem baseSize depth).graph
                        (retainedHammingHost dimension radius retained))
                      (layer : Fin depth)
                      (reference :
                        PairLayer (Fintype.card (PairLayer baseSize layer.val)) 1)
                      (threshold : ℝ)
                      (hexclusion :
                        retained ∉
                          badPairLayerRetentionEvent
                            (Fintype.card (PairLayer baseSize layer.val)) dimension
                            (pairGraphCopyChildSide retained copy layer reference)
                            threshold) :
                      threshold <
                        pairChildArrayEntropy
                          (pairGraphCopyParentWords retained copy layer)
                          (pairGraphCopyChildWords retained copy layer) := by
                    have pairGraphCopyChildWords_injective
                        {baseSize depth dimension radius : ℕ}
                        (retained : Set (Bool × HammingWord dimension))
                        (copy : SimpleGraph.Copy
                          (pairParentSystem baseSize depth).graph
                          (retainedHammingHost dimension radius retained))
                        (layer : Fin depth) :
                        Function.Injective (pairGraphCopyChildWords retained copy layer) := by
                      intro first second hwords
                      have hside := pairGraphCopy_child_layer_side_eq
                        retained copy layer.val (by omega)
                        ((pairLayerPairEquiv baseSize layer.val) first)
                        ((pairLayerPairEquiv baseSize layer.val) second)
                      have hvertices :
                          (copy
                            (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                              ((pairLayerPairEquiv baseSize layer.val) first))).val =
                          (copy
                            (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                              ((pairLayerPairEquiv baseSize layer.val) second))).val := by
                        apply Prod.ext
                        · exact hside
                        · exact hwords
                      have himages :
                          copy
                            (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                              ((pairLayerPairEquiv baseSize layer.val) first)) =
                          copy
                            (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                              ((pairLayerPairEquiv baseSize layer.val) second)) :=
                        Subtype.ext hvertices
                      have hsources := copy.injective himages
                      have hpairs :=
                        (pairLayerEmbedding baseSize depth (layer.val + 1)
                          (by omega)).injective hsources
                      exact (pairLayerPairEquiv baseSize layer.val).injective hpairs
                    have pairGraphCopyChildWords_retained
                        {baseSize depth dimension radius : ℕ}
                        (retained : Set (Bool × HammingWord dimension))
                        (copy : SimpleGraph.Copy
                          (pairParentSystem baseSize depth).graph
                          (retainedHammingHost dimension radius retained))
                        (layer : Fin depth)
                        (reference :
                          PairLayer (Fintype.card (PairLayer baseSize layer.val)) 1) :
                        retained ∈
                          pairChildRetentionEvent
                            (pairGraphCopyChildSide retained copy layer reference)
                            (pairGraphCopyChildWords retained copy layer) := by
                      intro pair
                      have hside := pairGraphCopy_child_layer_side_eq
                        retained copy layer.val (by omega)
                        ((pairLayerPairEquiv baseSize layer.val) reference)
                        ((pairLayerPairEquiv baseSize layer.val) pair)
                      have hretained :=
                        (copy
                          (pairLayerEmbedding baseSize depth (layer.val + 1) (by omega)
                            ((pairLayerPairEquiv baseSize layer.val) pair))).property
                      change
                        (pairGraphCopyChildSide retained copy layer reference,
                          pairGraphCopyChildWords retained copy layer pair) ∈ retained
                      unfold pairGraphCopyChildSide pairGraphCopyChildWords
                      rw [hside]
                      exact hretained
                    classical
                    by_contra hnot
                    have hbad_entropy :
                        pairChildArrayEntropy
                          (pairGraphCopyParentWords retained copy layer)
                          (pairGraphCopyChildWords retained copy layer) ≤ threshold :=
                      le_of_not_gt hnot
                    have hbad_array :
                        pairGraphCopyChildWords retained copy layer ∈
                          badPairChildArrays
                            (pairGraphCopyParentWords retained copy layer) threshold := by
                      unfold badPairChildArrays
                      exact Finset.mem_filter.mpr
                        ⟨Finset.mem_univ _, hbad_entropy⟩
                    have hinjective :
                        pairGraphCopyChildWords retained copy layer ∈
                          (badPairChildArrays
                            (pairGraphCopyParentWords retained copy layer) threshold).filter
                              Function.Injective :=
                      Finset.mem_filter.mpr
                        ⟨hbad_array,
                          pairGraphCopyChildWords_injective retained copy layer⟩
                    apply hexclusion
                    change retained ∈
                      ⋃ parents :
                          Fin (Fintype.card (PairLayer baseSize layer.val)) →
                            HammingWord dimension,
                        badPairChildRetentionEvent parents
                          (pairGraphCopyChildSide retained copy layer reference) threshold
                    apply Set.mem_iUnion.mpr
                    refine ⟨pairGraphCopyParentWords retained copy layer, ?_⟩
                    change retained ∈
                      ⋃ children ∈
                          (badPairChildArrays
                            (pairGraphCopyParentWords retained copy layer) threshold).filter
                              Function.Injective,
                        pairChildRetentionEvent
                          (pairGraphCopyChildSide retained copy layer reference) children
                    exact Set.mem_iUnion.mpr
                      ⟨pairGraphCopyChildWords retained copy layer,
                        Set.mem_iUnion.mpr
                          ⟨hinjective,
                            pairGraphCopyChildWords_retained
                              retained copy layer reference⟩⟩
                  classical
                  intro hcontained
                  obtain ⟨copy⟩ := hcontained
                  let potential : ℕ → ℝ := fun layer =>
                    if hlevel : layer < depth + 1 then
                      pairGraphCopyLayerPotential retained copy ⟨layer, hlevel⟩
                    else 0
                  let conditionalEntropy : ℕ → ℝ := fun layer =>
                    if hlevel : layer < depth then
                      pairChildArrayEntropy
                        (pairGraphCopyParentWords retained copy ⟨layer, hlevel⟩)
                        (pairGraphCopyChildWords retained copy ⟨layer, hlevel⟩)
                    else 0
                  let error : ℕ → ℝ := fun layer =>
                    if hlevel : layer < depth then
                      empiricalEntropyError
                        (Fintype.card (PairLayer baseSize layer))
                    else 0
                  apply entropy_layer_exclusion depth
                    potential conditionalEntropy error
                  · intro layer hlayer
                    have hinrange : layer < depth + 1 := by omega
                    have hle : layer ≤ depth := by omega
                    simpa [potential, hinrange, hle] using
                      pairGraphCopyLayerPotential_mem_Icc
                        hbase hdimension retained copy ⟨layer, hinrange⟩
                  · intro layer hlayer
                    simpa [error, hlayer] using
                      herror ⟨layer, hlayer⟩
                  · intro layer hlayer
                    have hsize : 2 ≤ Fintype.card (PairLayer baseSize layer) := by
                      have hcard := pairLayer_card_ge_base
                        baseSize layer hbase
                      omega
                    let reference :
                        PairLayer (Fintype.card (PairLayer baseSize layer)) 1 :=
                      Classical.choice (pairLayerPair_nonempty hsize)
                    have hlower := pairGraphCopy_entropy_lower_of_exclusion
                      retained copy ⟨layer, hlayer⟩ reference
                        (midpointBeta - entropySlack)
                        (hexclusion
                          (pairGraphCopyChildSide
                            retained copy ⟨layer, hlayer⟩ reference)
                          ⟨layer, hlayer⟩)
                    simpa [conditionalEntropy, hlayer] using hlower
                  · intro layer hlayer
                    have hnext : layer + 1 < depth + 1 := by omega
                    have hcurrent : layer < depth + 1 := by omega
                    have hnext_le : layer + 1 ≤ depth := by omega
                    have hcurrent_le : layer ≤ depth := by omega
                    have hupper := pairGraphCopy_layer_entropy_upper_of_disagreement
                      hbase hdimension retained copy ⟨layer, hlayer⟩
                      (hdisagreement copy ⟨layer, hlayer⟩)
                    simpa [conditionalEntropy, potential, error,
                      hlayer, hnext, hcurrent, hnext_le, hcurrent_le] using hupper
                  · exact hdepth
                exact (SimpleGraph.free_congr_left
                  (pairGraphOverFinIso baseSize depth)).mp
                    (pairGraph_free_of_layer_exclusion_and_disagreement
                      hbase hdimension hdepth retained hexclusion herror hdisagreement)
              apply pairGraphOverFin_free_of_layer_exclusion_and_disagreement
                hbase hdimension hdepth retained hexclusion herror
              intro copy layer
              exact pairGraphCopy_averageDisagreement_le_tau
                hbase hdimension hradius retained copy layer
            exact pairGraphOverFin_free_of_layer_exclusion
              hbase hdimension hdepth
              (manuscriptHammingRadius_le dimension)
              retained hexclusion herror
          obtain ⟨baseSize, depth, hbase, hdepth, hdepth_window, hlayers⟩ :=
            exists_actualPairLayer_exclusion_parameters
          let layerSizes : Fin depth → ℕ := fun layer =>
            Fintype.card (PairLayer baseSize layer.val)
          have hparents : ∀ layer, 4 ≤ layerSizes layer :=
            fun layer => (hlayers layer).1
          have hfirst_moment :
              ∀ layer,
                (layerSizes layer : ℝ) +
                  3 * logTwo
                    (((layerSizes layer).choose 2 + 1 : ℕ) : ℝ) -
                    entropySlack * ((layerSizes layer).choose 2 : ℝ) < -1 :=
            fun layer => (hlayers layer).2.2
          have hsmall :
              ∀ᶠ dimension : ℕ in Filter.atTop,
                manuscriptSamplingFailureBound depth dimension < 1 :=
            (tendsto_order.1
              (manuscriptSamplingFailureBound_tendsto_zero depth)).2
                1 (by norm_num)
          refine ⟨baseSize, depth, hbase, hdepth, hdepth_window, ?_⟩
          filter_upwards [hsmall, Filter.eventually_gt_atTop 0] with dimension
            hbound hdimension
          obtain ⟨retained, houtside⟩ :=
            exists_hammingRetention_outside_event dimension
              (manuscriptSamplingFailureEvent layerSizes dimension)
              ((manuscriptSamplingFailureEvent_real_le layerSizes
                hdimension hparents hfirst_moment).trans_lt hbound)
          have hexclusion :
              ∀ (side : Bool) (layer : Fin depth),
                retained ∉
                  badPairLayerRetentionEvent
                    (layerSizes layer) dimension side
                      (midpointBeta - entropySlack) := by
            intro side layer hbad
            exact houtside (Or.inl (Or.inl (Set.mem_iUnion.mpr
              ⟨side, Set.mem_iUnion.mpr ⟨layer, hbad⟩⟩)))
          have hvertices :
              hammingRetainedVertexCount dimension retained <
                3 * hammingRetentionProbability dimension *
                  ((2 ^ dimension : ℕ) : ℝ) :=
            lt_of_not_ge fun hlarge => houtside (Or.inl (Or.inr hlarge))
          have hedges :
              hammingExpectedRetainedEdgeCount dimension
                  (manuscriptHammingRadius dimension) / 2 ≤
                hammingRetainedEdgeCount dimension
                  (manuscriptHammingRadius dimension) retained :=
            le_of_not_gt fun hlow => houtside (Or.inr hlow)
          exact ⟨retained,
            pairGraphOverFin_free_of_manuscript_exclusion
              hbase hdimension hdepth_window retained hexclusion
              (fun layer => (hlayers layer).2.1),
            hvertices, hedges⟩
        (open Classical in
          have retainedVertex_card_le_manuscriptVertexCount
              (dimension : ℕ)
              (retained : Set (Bool × HammingWord dimension))
              (hvertices :
                hammingRetainedVertexCount dimension retained <
                  3 * hammingRetentionProbability dimension *
                    ((2 ^ dimension : ℕ) : ℝ)) :
              Fintype.card retained ≤ manuscriptVertexCount dimension := by
            (open Classical in
              have hammingRetainedVertexCount_eq_card
                  (dimension : ℕ)
                  (retained : Set (Bool × HammingWord dimension)) :
                  hammingRetainedVertexCount dimension retained =
                    (Fintype.card retained : ℝ) := by
                classical
                simp [hammingRetainedVertexCount, Fintype.card_subtype])
            have hreal : (Fintype.card retained : ℝ) ≤ (manuscriptVertexCount dimension : ℝ) := by
              calc
                (Fintype.card retained : ℝ) =
                    hammingRetainedVertexCount dimension retained :=
                  (hammingRetainedVertexCount_eq_card dimension retained).symm
                _ ≤ 3 * hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ) := hvertices.le
                _ ≤ (⌈3 * hammingRetentionProbability dimension *
                      ((2 ^ dimension : ℕ) : ℝ)⌉₊ : ℝ) :=
                  Nat.le_ceil _
                _ = (manuscriptVertexCount dimension : ℝ) := rfl
            exact_mod_cast hreal)
        obtain ⟨baseSize, depth, hbase, hdepth,
          hdepth_window, hhosts⟩ :=
          eventually_exists_pairGraph_free_dense_retainedHost
        refine ⟨baseSize, depth, hbase, hdepth, hdepth_window, ?_⟩
        filter_upwards [hhosts] with dimension hhost
        obtain ⟨retained, hfree, hvertices, hedges⟩ := hhost
        have hcard :=
          retainedVertex_card_le_manuscriptVertexCount
            dimension retained hvertices
        have hembedding : Nonempty (retained ↪ Fin (manuscriptVertexCount dimension)) := by
          apply Function.Embedding.nonempty_of_card_le
          simpa using hcard
        obtain ⟨embedding⟩ := hembedding
        let paddedHost : SimpleGraph (Fin (manuscriptVertexCount dimension)) :=
          (retainedHammingHost dimension
            (manuscriptHammingRadius dimension) retained).map embedding
        have hpadded_free : (pairGraphOverFin baseSize depth).Free paddedHost := by
          exact CompactnessConjecture.free_map_of_no_isolated
            (pairGraphOverFin baseSize depth)
            (pairGraphOverFin_forall_exists_adj baseSize depth hbase hdepth)
            embedding hfree
        have hpadded_edges :
            paddedHost.edgeFinset.card ≤
              SimpleGraph.extremalNumber
                (manuscriptVertexCount dimension)
                (pairGraphOverFin baseSize depth) := by
          simpa using
            (SimpleGraph.card_edgeFinset_le_extremalNumber hpadded_free)
        calc
          hammingExpectedRetainedEdgeCount dimension
              (manuscriptHammingRadius dimension) / 2 ≤
            hammingRetainedEdgeCount dimension
              (manuscriptHammingRadius dimension) retained := hedges
          _ = ((retainedHammingHost dimension
              (manuscriptHammingRadius dimension) retained).edgeFinset.card : ℝ) :=
            hammingRetainedEdgeCount_eq_edgeFinset_card
              dimension (manuscriptHammingRadius dimension) retained
          _ = (paddedHost.edgeFinset.card : ℝ) := by
            congr 1
            exact (SimpleGraph.card_edgeFinset_map embedding
              (retainedHammingHost dimension
                (manuscriptHammingRadius dimension) retained)).symm
          _ ≤ (SimpleGraph.extremalNumber
              (manuscriptVertexCount dimension)
              (pairGraphOverFin baseSize depth) : ℝ) := by
            exact_mod_cast hpadded_edges)
    have eventually_manuscriptVertexCount_power_le_expectedRetainedEdge :
        ∀ᶠ dimension : ℕ in Filter.atTop,
          (manuscriptVertexCount dimension : ℝ) ^
              manuscriptExtremalPower ≤
            hammingExpectedRetainedEdgeCount dimension
              (manuscriptHammingRadius dimension) / 2 := by
      have sampledHammingEdgeEntropyRate_eq_manuscriptExtremalPower :
          sampledHammingEdgeEntropyRate =
            (1 - midpointBeta) * manuscriptExtremalPower * Real.log 2 +
              2 * manuscriptEntropyGap := by
        have hmidpoint : entropyUpperEndpoint - midpointBeta = certifiedWindowWidth / 2 := by
          have hwindow := entropyWindow_eq_certifiedWindowWidth
          unfold midpointBeta
          linarith
        have hupper : binaryEntropy tau = (entropyUpperEndpoint + 1) / 2 := by
          unfold entropyUpperEndpoint
          ring
        have hgain : (1 - midpointBeta) * exponentGain = certifiedWindowWidth / 8 := by
          have hnonzero : 1 - midpointBeta ≠ 0 :=
            (sub_pos.mpr midpointBeta_lt_one).ne'
          unfold exponentGain
          field_simp [hnonzero]
        have hbits :
            1 - 2 * midpointBeta + binaryEntropy tau =
              (1 - midpointBeta) *
                  ((3 : ℝ) / 2 + exponentGain) +
                certifiedWindowWidth / 8 := by
          nlinarith [hmidpoint, hupper, hgain]
        have hentropy : Real.binEntropy tau = binaryEntropy tau * Real.log 2 := by
          unfold binaryEntropy
          field_simp [log_two_pos.ne']
        calc
          sampledHammingEdgeEntropyRate =
              (1 - 2 * midpointBeta + binaryEntropy tau) *
                Real.log 2 := by
            unfold sampledHammingEdgeEntropyRate
            rw [hentropy]
            ring
          _ = ((1 - midpointBeta) *
                ((3 : ℝ) / 2 + exponentGain) +
                certifiedWindowWidth / 8) * Real.log 2 := by
            rw [hbits]
          _ = (1 - midpointBeta) *
                manuscriptExtremalPower * Real.log 2 +
              2 * manuscriptEntropyGap := by
            unfold manuscriptExtremalPower manuscriptEntropyGap
            ring
      have eventually_manuscriptVertexCount_le_four_wordMean :
          ∀ᶠ dimension : ℕ in Filter.atTop,
            (manuscriptVertexCount dimension : ℝ) ≤
              4 * (hammingRetentionProbability dimension *
                ((2 ^ dimension : ℕ) : ℝ)) := by
        have manuscriptVertexCount_le_four_wordMean
            (dimension : ℕ)
            (hmean :
              1 ≤ hammingRetentionProbability dimension *
                ((2 ^ dimension : ℕ) : ℝ)) :
            (manuscriptVertexCount dimension : ℝ) ≤
              4 * (hammingRetentionProbability dimension *
                ((2 ^ dimension : ℕ) : ℝ)) := by
          have hargument :
              0 ≤ 3 * hammingRetentionProbability dimension *
                ((2 ^ dimension : ℕ) : ℝ) := by
            positivity [hammingRetentionProbability_pos dimension]
          have hceiling :
              (manuscriptVertexCount dimension : ℝ) <
                3 * hammingRetentionProbability dimension *
                  ((2 ^ dimension : ℕ) : ℝ) + 1 := by
            unfold manuscriptVertexCount
            exact Nat.ceil_lt_add_one hargument
          nlinarith
        have hlarge := Filter.tendsto_atTop.1
          hammingRetentionProbability_mul_wordCount_tendsto_atTop (1 : ℝ)
        filter_upwards [hlarge] with dimension hdimension
        exact manuscriptVertexCount_le_four_wordMean dimension hdimension
      have eventually_manuscriptEntropyGap_dominates_power_constant :
          ∀ᶠ dimension : ℕ in Filter.atTop,
            2 * (4 : ℝ) ^ manuscriptExtremalPower ≤
              Real.exp (manuscriptEntropyGap * (dimension : ℝ)) /
                ((dimension + 1 : ℕ) : ℝ) := by
        exact Filter.tendsto_atTop.1
          (exp_mul_div_nat_succ_tendsto_atTop
            manuscriptEntropyGap manuscriptEntropyGap_pos)
          (2 * (4 : ℝ) ^ manuscriptExtremalPower)
      have hlower :=
        eventually_manuscriptExpectedRetainedEdge_entropy_lower
          manuscriptEntropyGap manuscriptEntropyGap_pos
      have hvertex :=
        eventually_manuscriptVertexCount_le_four_wordMean
      have hconstant :=
        eventually_manuscriptEntropyGap_dominates_power_constant
      filter_upwards [hlower, hvertex, hconstant] with dimension
        hedge_lower hvertex_bound hconstant_bound
      have hconstant_half :
          (4 : ℝ) ^ manuscriptExtremalPower ≤
            (Real.exp (manuscriptEntropyGap * (dimension : ℝ)) /
              ((dimension + 1 : ℕ) : ℝ)) / 2 := by
        linarith
      have hexponent :
          ((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                manuscriptExtremalPower +
              manuscriptEntropyGap * (dimension : ℝ) =
            (dimension : ℝ) *
              (sampledHammingEdgeEntropyRate - manuscriptEntropyGap) := by grind
      calc
        (manuscriptVertexCount dimension : ℝ) ^
            manuscriptExtremalPower ≤
          (4 * (hammingRetentionProbability dimension *
            ((2 ^ dimension : ℕ) : ℝ))) ^
              manuscriptExtremalPower := by
            apply Real.rpow_le_rpow
            · positivity
            · exact hvertex_bound
            · exact manuscriptExtremalPower_pos.le
        _ = (4 : ℝ) ^ manuscriptExtremalPower *
            Real.exp
              (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                manuscriptExtremalPower) := by
          rw [hammingRetentionProbability_mul_wordCount_eq_exp,
            Real.mul_rpow (by norm_num) (Real.exp_pos _).le,
            ← Real.exp_mul]
        _ ≤ Real.exp
              (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                manuscriptExtremalPower) *
            ((Real.exp (manuscriptEntropyGap * (dimension : ℝ)) /
              ((dimension + 1 : ℕ) : ℝ)) / 2) := by
          calc
            (4 : ℝ) ^ manuscriptExtremalPower *
                Real.exp
                  (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                    manuscriptExtremalPower) =
              Real.exp
                  (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                    manuscriptExtremalPower) *
                (4 : ℝ) ^ manuscriptExtremalPower := by ring
            _ ≤ Real.exp
                  (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                    manuscriptExtremalPower) *
                ((Real.exp (manuscriptEntropyGap * (dimension : ℝ)) /
                  ((dimension + 1 : ℕ) : ℝ)) / 2) :=
              mul_le_mul_of_nonneg_left hconstant_half
                (Real.exp_pos _).le
        _ = (Real.exp
              (((1 - midpointBeta) * (dimension : ℝ) * Real.log 2) *
                  manuscriptExtremalPower +
                manuscriptEntropyGap * (dimension : ℝ)) /
              ((dimension + 1 : ℕ) : ℝ)) / 2 := by
          rw [Real.exp_add]
          ring
        _ = (Real.exp
              ((dimension : ℝ) *
                (sampledHammingEdgeEntropyRate - manuscriptEntropyGap)) /
              ((dimension + 1 : ℕ) : ℝ)) / 2 := by
          rw [hexponent]
        _ ≤ hammingExpectedRetainedEdgeCount dimension
              (manuscriptHammingRadius dimension) / 2 := by
          gcongr
    obtain ⟨baseSize, depth, hbase, hdepth,
      hdepth_window, hextremal⟩ :=
      eventually_expectedRetainedEdge_le_extremalNumber
    refine ⟨baseSize, depth, hbase, hdepth, hdepth_window, ?_⟩
    filter_upwards
      [eventually_manuscriptVertexCount_power_le_expectedRetainedEdge,
        hextremal] with dimension hpower hbound
    exact hpower.trans hbound
  have manuscriptVertexCount_succ_le_two_mul
      (dimension : ℕ) :
      manuscriptVertexCount (dimension + 1) ≤
        2 * manuscriptVertexCount dimension := by
    have hfactor : Real.exp ((1 - midpointBeta) * Real.log 2) ≤ (2 : ℝ) := by
      calc
        Real.exp ((1 - midpointBeta) * Real.log 2) ≤
            Real.exp (Real.log 2) := by
          apply Real.exp_le_exp.mpr
          nlinarith [mul_pos midpointBeta_pos log_two_pos]
        _ = 2 := Real.exp_log (by norm_num)
    have hrecurrence :
        hammingRetentionProbability (dimension + 1) *
            ((2 ^ (dimension + 1) : ℕ) : ℝ) =
          Real.exp ((1 - midpointBeta) * Real.log 2) *
            (hammingRetentionProbability dimension *
              ((2 ^ dimension : ℕ) : ℝ)) := by
      rw [hammingRetentionProbability_mul_wordCount_eq_exp,
        hammingRetentionProbability_mul_wordCount_eq_exp,
        ← Real.exp_add]
      congr 1
      push_cast
      ring
    unfold manuscriptVertexCount
    apply Nat.ceil_le.mpr
    norm_num only [Nat.cast_mul, Nat.cast_ofNat]
    calc
      3 * hammingRetentionProbability (dimension + 1) *
          ((2 ^ (dimension + 1) : ℕ) : ℝ) =
        Real.exp ((1 - midpointBeta) * Real.log 2) *
          (3 * hammingRetentionProbability dimension *
            ((2 ^ dimension : ℕ) : ℝ)) := by
          rw [show
            3 * hammingRetentionProbability (dimension + 1) *
                ((2 ^ (dimension + 1) : ℕ) : ℝ) =
              3 * (hammingRetentionProbability (dimension + 1) *
                ((2 ^ (dimension + 1) : ℕ) : ℝ)) by ring,
            hrecurrence]
          ring
      _ ≤ 2 * (3 * hammingRetentionProbability dimension *
            ((2 ^ dimension : ℕ) : ℝ)) := by
          exact mul_le_mul_of_nonneg_right hfactor (by
            positivity [hammingRetentionProbability_pos dimension])
      _ ≤ 2 *
            (⌈3 * hammingRetentionProbability dimension *
              ((2 ^ dimension : ℕ) : ℝ)⌉₊ : ℝ) := by
          gcongr
          exact Nat.le_ceil _
  have exists_manuscriptVertexCount_bracket
      (minimum n : ℕ)
      (hminimum : manuscriptVertexCount minimum ≤ n) :
      ∃ dimension : ℕ,
        minimum ≤ dimension ∧
        manuscriptVertexCount dimension ≤ n ∧
        n < manuscriptVertexCount (dimension + 1) := by
    have manuscriptVertexCount_tendsto_atTop :
        Filter.Tendsto manuscriptVertexCount Filter.atTop Filter.atTop := by
      have hscaled :
          Filter.Tendsto
            (fun dimension : ℕ =>
              3 * (hammingRetentionProbability dimension *
                ((2 ^ dimension : ℕ) : ℝ)))
            Filter.atTop Filter.atTop :=
        hammingRetentionProbability_mul_wordCount_tendsto_atTop.const_mul_atTop
          (by norm_num)
      have hceiling := tendsto_nat_ceil_atTop.comp hscaled
      apply hceiling.congr'
      filter_upwards [] with dimension
      change
        ⌈3 * (hammingRetentionProbability dimension *
          ((2 ^ dimension : ℕ) : ℝ))⌉₊ =
          manuscriptVertexCount dimension
      unfold manuscriptVertexCount
      congr 1
      ring
    have hlarge : ∀ᶠ dimension : ℕ in Filter.atTop, n < manuscriptVertexCount dimension := by
      have hevent := Filter.tendsto_atTop.1
        manuscriptVertexCount_tendsto_atTop (n + 1)
      filter_upwards [hevent] with dimension hdimension
      omega
    obtain ⟨dimension, hdimension, hafter⟩ :=
      (hlarge.and (Filter.eventually_ge_atTop minimum)).exists
    have hexists : ∃ offset : ℕ, n < manuscriptVertexCount (minimum + offset) := by
      refine ⟨dimension - minimum, ?_⟩
      rw [Nat.add_sub_of_le hafter]
      exact hdimension
    let offset : ℕ := Nat.find hexists
    have hnext : n < manuscriptVertexCount (minimum + offset) :=
      Nat.find_spec hexists
    have hoffset : 0 < offset := by grind
    refine ⟨minimum + (offset - 1), by omega, ?_, ?_⟩
    · have hbefore :
          ¬ n < manuscriptVertexCount (minimum + (offset - 1)) := by
        exact Nat.find_min hexists (by omega)
      exact Nat.le_of_not_gt hbefore
    · rw [show minimum + (offset - 1) + 1 = minimum + offset by omega]
      exact hnext
  classical
  obtain ⟨baseSize, depth, hbase, hdepth,
    hdepth_window, hsubsequence⟩ :=
    eventually_manuscriptVertexCount_power_le_extremalNumber
  have hwidth : certifiedWindowWidth < 1 := by
    rw [← entropyWindow_eq_certifiedWindowWidth]
    linarith [entropyLowerEndpoint_pos, entropyUpperEndpoint_lt_one]
  have hproduct : 0 ≤ (depth : ℝ) * (1 - certifiedWindowWidth) :=
    mul_nonneg (Nat.cast_nonneg depth) (sub_nonneg.mpr hwidth.le)
  have hdepth_real : (2 : ℝ) < (depth : ℝ) := by nlinarith
  have hdepth_nat : 2 < depth := by exact_mod_cast hdepth_real
  have hdepth_two : 2 ≤ depth := by omega
  let forbidden :
      SimpleGraph (Fin (Fintype.card (PairVertex baseSize depth))) :=
    pairGraphOverFin baseSize depth
  have hnoisolated :
      ∀ vertex : Fin (Fintype.card (PairVertex baseSize depth)),
        ∃ neighbor, forbidden.Adj vertex neighbor := by
    exact pairGraphOverFin_forall_exists_adj
      baseSize depth hbase hdepth
  refine ⟨Fintype.card (PairVertex baseSize depth), forbidden,
    pairGraphOverFin_connected baseSize depth (by omega) hdepth,
    pairGraphOverFin_isBipartite baseSize depth,
    pairGraphOverFin_isTwoDegenerate baseSize depth,
    ?_,
    1 / (2 : ℝ) ^ manuscriptExtremalPower,
    exponentGain, ?_, exponentGain_pos, ?_⟩
  · simpa only [forbidden] using
      pairGraphOverFin_bipartition_maximum_degree_gt_two
        baseSize depth hbase hdepth_two
  · exact one_div_pos.mpr
      (Real.rpow_pos_of_pos (by norm_num) manuscriptExtremalPower)
  · obtain ⟨minimum, hminimum⟩ :=
      Filter.eventually_atTop.1 hsubsequence
    apply Filter.eventually_atTop.2
    refine ⟨manuscriptVertexCount minimum, ?_⟩
    intro n hn
    obtain ⟨dimension, hdimension, hbelow, habove⟩ :=
      exists_manuscriptVertexCount_bracket minimum n hn
    have hdouble :=
      manuscriptVertexCount_succ_le_two_mul dimension
    have hn_bound : n ≤ 2 * manuscriptVertexCount dimension := by omega
    have hn_real : (n : ℝ) ≤ 2 * (manuscriptVertexCount dimension : ℝ) := by exact_mod_cast hn_bound
    have hsubseq := hminimum dimension hdimension
    have hmonotone :
        SimpleGraph.extremalNumber
            (manuscriptVertexCount dimension) forbidden ≤
          SimpleGraph.extremalNumber n forbidden :=
      CompactnessConjecture.extremalNumber_monotone_of_no_isolated
        forbidden hnoisolated hbelow
    change
      (1 / (2 : ℝ) ^ manuscriptExtremalPower) *
          (n : ℝ) ^ manuscriptExtremalPower ≤
        (SimpleGraph.extremalNumber n forbidden : ℝ)
    calc
      (1 / (2 : ℝ) ^ manuscriptExtremalPower) *
          (n : ℝ) ^ manuscriptExtremalPower ≤
        (1 / (2 : ℝ) ^ manuscriptExtremalPower) *
          (2 * (manuscriptVertexCount dimension : ℝ)) ^
            manuscriptExtremalPower := by
          apply mul_le_mul_of_nonneg_left
          · exact Real.rpow_le_rpow
              (Nat.cast_nonneg n) hn_real
              manuscriptExtremalPower_pos.le
          · positivity
      _ = (manuscriptVertexCount dimension : ℝ) ^
            manuscriptExtremalPower := by
          rw [Real.mul_rpow (by norm_num)
            (Nat.cast_nonneg (manuscriptVertexCount dimension))]
          have htwo : (2 : ℝ) ^ manuscriptExtremalPower ≠ 0 :=
            (Real.rpow_pos_of_pos (by norm_num)
              manuscriptExtremalPower).ne'
          field_simp [htwo]
      _ ≤ (SimpleGraph.extremalNumber
            (manuscriptVertexCount dimension) forbidden : ℝ) :=
          hsubseq
      _ ≤ (SimpleGraph.extremalNumber n forbidden : ℝ) := by exact_mod_cast hmonotone

theorem not_erdos_146 : ¬ DegeneracyConjectureStatement := by
  (open CompactnessConjecture in
  open scoped Classical Topology in
    have eventually_constant_le_positive_nat_rpow
        (constant coefficient exponent : ℝ)
        (hcoefficient : 0 < coefficient)
        (hexponent : 0 < exponent) :
        ∀ᶠ n : ℕ in Filter.atTop,
          constant ≤ coefficient * (n : ℝ) ^ exponent := by
      have hpower : Filter.Tendsto (fun n : ℕ => (n : ℝ) ^ exponent) Filter.atTop Filter.atTop :=
        (tendsto_rpow_atTop hexponent).comp
          (tendsto_natCast_atTop_atTop (R := ℝ))
      filter_upwards [hpower.eventually
        (Filter.eventually_ge_atTop (constant / coefficient))]
        with n hn
      calc
        constant = coefficient * (constant / coefficient) := by field_simp
        _ ≤ coefficient * (n : ℝ) ^ exponent :=
          mul_le_mul_of_nonneg_left hn hcoefficient.le)
  intro hconjecture
  obtain ⟨q, H, _hconnected, hbipartite, hdegenerate, _hdegree,
    c, ε, hc, hε, hlower⟩ := twoDegenerateExtremalCounterexample
  have hbigO := hconjecture 2 q H (by norm_num)
    hbipartite hdegenerate
  obtain ⟨C, hupper⟩ := Asymptotics.isBigO_iff.mp hbigO
  have hupper' :
      ∀ᶠ n : ℕ in Filter.atTop,
        (SimpleGraph.extremalNumber n H : ℝ) ≤
          C * (n : ℝ) ^ ((3 : ℝ) / 2) := by
    filter_upwards [hupper] with n hn
    have hnnonneg : (0 : ℝ) ≤ (n : ℝ) := Nat.cast_nonneg _
    have hextremal_nonneg : (0 : ℝ) ≤ (SimpleGraph.extremalNumber n H : ℝ) :=
      Nat.cast_nonneg _
    have hnormalized :
        (SimpleGraph.extremalNumber n H : ℝ) ≤
          C * (n : ℝ) ^ ((2 : ℝ) - 1 / (2 : ℝ)) := by
      simpa only [Real.norm_eq_abs, abs_of_nonneg hextremal_nonneg,
        abs_of_nonneg (Real.rpow_nonneg hnnonneg _), Nat.cast_ofNat] using hn
    convert hnormalized using 1
    norm_num
  have hlarge :=
    eventually_constant_le_positive_nat_rpow
      (C + 1) c ε hc hε
  have himpossible : ∀ᶠ n : ℕ in Filter.atTop, False := by
    filter_upwards [hlower, hupper', hlarge,
      Filter.eventually_gt_atTop 0] with n hlow hupp hlarge_n hn
    have hnreal : (0 : ℝ) < (n : ℝ) := by exact_mod_cast hn
    have hscale : 0 < (n : ℝ) ^ ((3 : ℝ) / 2) :=
      Real.rpow_pos_of_pos hnreal _
    have hdecompose :
        c * (n : ℝ) ^ ((3 : ℝ) / 2 + ε) =
          (c * (n : ℝ) ^ ε) * (n : ℝ) ^ ((3 : ℝ) / 2) := by
      rw [Real.rpow_add hnreal]
      ring
    rw [hdecompose] at hlow
    have hscaled := mul_le_mul_of_nonneg_right hlarge_n hscale.le
    nlinarith
  exact himpossible.exists.elim (fun _ h => h)

end MainTheorem

end TwoDegenerateGraphs
