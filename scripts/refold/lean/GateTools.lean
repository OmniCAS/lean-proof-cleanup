/-
Gate tools for the unroll/refold experiment (our own code, not part of upstream).

* `Gate.statementReport`: for each headline theorem, a structural hash of its type and of every
  project-defined constant its statement mentions (recursively, through types and definition
  bodies). Run once in the frozen challenge module and once in the solution module; the two
  outputs must be identical.
* `Gate.axiomReport`: the axioms each headline theorem depends on.
* `Gate.depGraph`: the declaration dependency graph of one module, read from the environment
  (auxiliary constants are attributed to the user-level declaration they belong to).
-/
import Lean

open Lean

namespace Gate

/-- Roots of modules that are not part of the project under test. -/
def libRoots : List Name :=
  [`Init, `Std, `Lean, `Mathlib, `Batteries, `Aesop, `Qq, `ProofWidgets, `Plausible, `ImportGraph,
    `LeanSearchClient, `Cli, `Lake, `Gate]

def moduleOf? (env : Environment) (c : Name) : Option Name :=
  (env.getModuleIdxFor? c).map fun idx => env.header.moduleNames[idx.toNat]!

/-- Is `c` defined in the project under test (as opposed to Lean core, Mathlib, …)? -/
def isProjectConst (env : Environment) (c : Name) : Bool :=
  match moduleOf? env c with
  | none => true
  | some m => !(libRoots.contains m.getRoot)

/-- Kind tag, the constants a statement-level reading of `ci` depends on, and a hash of its body. -/
def statementView (ci : ConstantInfo) : String × Array Name × UInt64 :=
  match ci with
  | .defnInfo d => ("def", d.type.getUsedConstants ++ d.value.getUsedConstants, d.value.hash)
  | .thmInfo t => ("thm", t.type.getUsedConstants, 0)
  | .opaqueInfo o => ("opaque", o.type.getUsedConstants ++ o.value.getUsedConstants, o.value.hash)
  | .axiomInfo a => ("axiom", a.type.getUsedConstants, 0)
  | .quotInfo q => ("quot", q.type.getUsedConstants, 0)
  | .inductInfo i =>
      ("ind", i.type.getUsedConstants ++ i.ctors.toArray ++ i.all.toArray,
        hash (i.ctors.map toString, i.numParams, i.numIndices))
  | .ctorInfo k => ("ctor", k.type.getUsedConstants.push k.induct, hash (k.cidx, k.numFields))
  | .recInfo r => ("rec", r.type.getUsedConstants, 0)

/-- Print the statement fingerprint of the headline theorems. Identical output in the challenge
module and in the solution module means: same theorem types over the same definitions. -/
def statementReport (thms : List Name) : CoreM Unit := do
  let env ← getEnv
  let mut seen : NameSet := {}
  let mut todo : Array Name := #[]
  let mut lines : Array String := #[]
  for t in thms do
    let some ci := env.find? t | throwError "statementReport: missing {t}"
    unless ci matches .thmInfo _ do throwError "statementReport: {t} is not a theorem"
    lines := lines.push s!"headline {t} levels={ci.levelParams.length} type={ci.type.hash}"
    for c in ci.type.getUsedConstants do
      if isProjectConst env c && !seen.contains c then
        seen := seen.insert c
        todo := todo.push c
  let mut i := 0
  let mut body : Array String := #[]
  while h : i < todo.size do
    let c := todo[i]
    i := i + 1
    let some ci := env.find? c | throwError "statementReport: missing {c}"
    let (kind, deps, vh) := statementView ci
    body := body.push s!"{c} {kind} levels={ci.levelParams.length} type={ci.type.hash} body={vh}"
    for d in deps do
      if isProjectConst env d && !seen.contains d then
        seen := seen.insert d
        todo := todo.push d
  for l in lines do IO.println l
  for l in body.qsort (· < ·) do IO.println s!"const {l}"

/-- Print the axioms each headline theorem depends on, one line per theorem. -/
def axiomReport (thms : List Name) : CoreM Unit := do
  for t in thms do
    let ax ← collectAxioms t
    let ax := (ax.map toString).qsort (· < ·)
    IO.println s!"axioms {t} {ax.toList}"

private def jsonStr (s : String) : String := (Json.str s).compress

/-- Dump the declaration graph of module `modName` as JSON lines:
`{"name", "kind", "line0", "line1", "uses": [...], "typeUses": [...]}` for every user-level
declaration; `uses` lists the user-level declarations of the same module that its type or body
mentions (after attributing auxiliary constants to their parent). -/
def depGraph (modName : Name) : CoreM Unit := do
  let env ← getEnv
  let some midx := env.getModuleIdx? modName | throwError "depGraph: module {modName} not imported"
  let names := env.header.moduleData[midx.toNat]!.constNames
  let inModule : NameSet := names.foldl (fun s n => s.insert n) {}
  -- anchors: declarations with a source range that are not constructors, projections, recursors
  let mut anchors : NameSet := {}
  let mut ranges : NameMap (Nat × Nat) := {}
  for n in names do
    let some ci := env.find? n | continue
    if ci matches .ctorInfo _ then continue
    if ci matches .recInfo _ then continue
    if (env.getProjectionFnInfo? n).isSome then continue
    if n.isInternalDetail then continue
    if isAuxRecursor env n || isNoConfusion env n then continue
    if let some r ← findDeclarationRanges? n then
      anchors := anchors.insert n
      ranges := ranges.insert n (r.range.pos.line, r.range.endPos.line)
  let anchorOf (n : Name) : Name := Id.run do
    if anchors.contains n then return n
    let mut p := n
    while !p.isAnonymous do
      p := p.getPrefix
      if anchors.contains p then return p
    return n
  let mut uses : NameMap NameSet := {}
  let mut typeUses : NameMap NameSet := {}
  for n in names do
    let some ci := env.find? n | continue
    let a := anchorOf n
    let tdeps := ci.type.getUsedConstants
    let vdeps : Array Name := match ci with
      | .defnInfo d => d.value.getUsedConstants
      | .thmInfo t => t.value.getUsedConstants
      | .opaqueInfo o => o.value.getUsedConstants
      | _ => #[]
    let mut s := (uses.find? a).getD {}
    let mut ts := (typeUses.find? a).getD {}
    for d in tdeps do
      if inModule.contains d then
        let b := anchorOf d
        if b != a then
          s := s.insert b
          if n == a then ts := ts.insert b
    for d in vdeps do
      if inModule.contains d then
        let b := anchorOf d
        if b != a then s := s.insert b
    uses := uses.insert a s
    typeUses := typeUses.insert a ts
  for a in anchors.toList do
    let some ci := env.find? a | continue
    let kind :=
      match ci with
      | .thmInfo _ => "theorem"
      | .defnInfo _ => if Meta.isInstanceCore env a then "instance" else "def"
      | .opaqueInfo _ => "opaque"
      | .axiomInfo _ => "axiom"
      | .inductInfo _ => if isStructure env a then "structure" else "inductive"
      | _ => "other"
    let (l0, l1) := (ranges.find? a).getD (0, 0)
    let us := ((uses.find? a).getD {}).toList.map (jsonStr ∘ toString)
    let ts := ((typeUses.find? a).getD {}).toList.map (jsonStr ∘ toString)
    IO.println <| "{\"name\":" ++ jsonStr (toString a) ++ ",\"kind\":\"" ++ kind ++ "\",\"line0\":"
      ++ toString l0 ++ ",\"line1\":" ++ toString l1 ++ ",\"uses\":[" ++ ",".intercalate us
      ++ "],\"typeUses\":[" ++ ",".intercalate ts ++ "]}"

end Gate
