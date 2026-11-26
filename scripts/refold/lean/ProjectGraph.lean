/-
Declaration graph of a whole project, read from the built environment (our own tool).

`ProjectGraph.dump prefixes out` writes one JSON line per user-level declaration of every imported
module whose name starts with one of `prefixes`:
  {"i": index, "n": name, "k": kind, "m": module, "l0": first line, "l1": last line,
   "u": [indices of project declarations its type or body mentions], "t": [those in its type]}
Auxiliary constants (`_proof_1`, match helpers, equation lemmas, recursors, projections,
constructors) are attributed to the declaration they belong to. Import the modules to be covered
before calling it.
-/
import Lean

open Lean

namespace ProjectGraph

def kindOf (env : Environment) (n : Name) (ci : ConstantInfo) : String :=
  match ci with
  | .thmInfo _ => "theorem"
  | .defnInfo _ => if Meta.isInstanceCore env n then "instance" else "def"
  | .opaqueInfo _ => "opaque"
  | .axiomInfo _ => "axiom"
  | .inductInfo _ => if isStructure env n then "structure" else "inductive"
  | _ => "other"

def dump (prefixes : List Name) (out : System.FilePath) : CoreM Unit := do
  let env ← getEnv
  let mods := env.header.moduleNames
  let mut anchors : Array Name := #[]
  let mut anchorIdx : Std.HashMap Name Nat := {}
  let mut modOf : Array Nat := #[]
  let mut ranges : Array (Nat × Nat) := #[]
  let mut inProject : Std.HashSet Name := {}
  let mut projMods : Array Nat := #[]
  for h : mi in [0:mods.size] do
    if prefixes.any (fun p => p.isPrefixOf mods[mi]) then projMods := projMods.push mi
  -- pass 1: anchors
  for mi in projMods do
    for n in env.header.moduleData[mi]!.constNames do
      inProject := inProject.insert n
      let some ci := env.find? n | continue
      if ci matches .ctorInfo _ then continue
      if ci matches .recInfo _ then continue
      if (env.getProjectionFnInfo? n).isSome then continue
      if n.isInternalDetail then continue
      if isAuxRecursor env n || isNoConfusion env n then continue
      if let some r ← findDeclarationRanges? n then
        anchorIdx := anchorIdx.insert n anchors.size
        anchors := anchors.push n
        modOf := modOf.push mi
        ranges := ranges.push (r.range.pos.line, r.range.endPos.line)
  let anchorOf (n : Name) : Option Nat := Id.run do
    if let some i := anchorIdx[n]? then return some i
    let mut p := n
    while !p.isAnonymous do
      p := p.getPrefix
      if let some i := anchorIdx[p]? then return some i
    return none
  -- pass 2: edges
  let mut uses : Array (Std.HashSet Nat) := Array.replicate anchors.size {}
  let mut tuses : Array (Std.HashSet Nat) := Array.replicate anchors.size {}
  for mi in projMods do
    for n in env.header.moduleData[mi]!.constNames do
      let some ci := env.find? n | continue
      let some a := anchorOf n | continue
      let tdeps := ci.type.getUsedConstants
      let vdeps : Array Name := match ci with
        | .defnInfo d => d.value.getUsedConstants
        | .thmInfo t => t.value.getUsedConstants
        | .opaqueInfo o => o.value.getUsedConstants
        | _ => #[]
      let mut s := uses[a]!
      let mut ts := tuses[a]!
      for d in tdeps do
        if inProject.contains d then
          if let some b := anchorOf d then
            if b != a then
              s := s.insert b
              if anchors[a]! == n then ts := ts.insert b
      for d in vdeps do
        if inProject.contains d then
          if let some b := anchorOf d then
            if b != a then s := s.insert b
      uses := uses.set! a s
      tuses := tuses.set! a ts
  let h ← IO.FS.Handle.mk out .write
  for i in [0:anchors.size] do
    let n := anchors[i]!
    let some ci := env.find? n | continue
    let (l0, l1) := ranges[i]!
    let us := ",".intercalate (uses[i]!.toList.map toString)
    let ts := ",".intercalate (tuses[i]!.toList.map toString)
    h.putStrLn <| "{\"i\":" ++ toString i ++ ",\"n\":" ++ (Json.str (toString n)).compress ++ ",\"k\":\""
      ++ kindOf env n ci ++ "\",\"m\":" ++ (Json.str (toString mods[modOf[i]!]!)).compress ++ ",\"l0\":"
      ++ toString l0 ++ ",\"l1\":" ++ toString l1 ++ ",\"u\":[" ++ us ++ "],\"t\":[" ++ ts ++ "]}"
  h.flush
  IO.println s!"PROJECT_GRAPH modules={projMods.size} declarations={anchors.size}"

end ProjectGraph
