/-
Headline closure of a very large project, read from its .olean files one module at a time
(our own tool; run with `lean --run ClosureFromOleans.lean LIST ROOT [ROOT ...]`).

`lean/ProjectGraph.lean` imports every module into one environment. For a project of tens of
thousands of module-system modules that needs three memory maps per module and runs into the
kernel's limit on the number of maps. This tool never builds an environment: it reads the parts of
one module (`.olean`, `.olean.server`, `.olean.private`), records for every constant a hash of its
name, the hashes of the constants its type and body mention, its kind and the user-level
declaration it belongs to, frees the module, and goes on. At the end it prints, per top-level
library: user-level theorems and definitions, how many are reachable from the root declarations,
and how many reachable theorems have exactly one user.

LIST is a text file with one line per module: `LIBRARY PATH_WITHOUT_EXTENSION`.
"User-level" is decided from names (auxiliary suffixes, constructors, recursors), so structure
projections count as definitions; theorem counts are not affected.
-/
import Lean

open Lean

def auxLast (s : String) : Bool :=
  s.startsWith "_" || s.startsWith "match_" || s.startsWith "proof_" || s.startsWith "eq_" ||
  ["injEq", "inj", "sizeOf_spec", "congr_simp", "noConfusion", "noConfusionType", "casesOn", "recOn",
   "rec", "below", "brecOn", "binductionOn", "ibelow", "ctorIdx", "toCtorIdx", "ctorElim",
   "ctorElimType", "induct", "induct_unfolding", "fun_cases", "fun_cases_unfolding"].contains s

/-- Auxiliary constant? Private declarations (`_private.Module.0.name`) are judged by their
user-facing name, so a `private theorem` counts as a user-level theorem. -/
def isAuxName (n : Name) : Bool :=
  let u := (privateToUserName? n).getD n
  match u with
    | .str _ s => auxLast s || u.isInternalDetail
    | .num _ _ => true
    | .anonymous => true

structure Store where
  hashes : Array UInt64 := #[]
  anchor : Array UInt64 := #[]
  kind : Array UInt8 := #[]      -- 1 theorem, 2 definition, 3 inductive, 0 other
  user : Array Bool := #[]
  lib : Array Nat := #[]
  deps : Array (Array UInt64) := #[]

/-- Read one module and append its constants to `acc`. Returns the memory regions of the module,
to be freed by the caller only after this function has returned (no reference into them may be
alive at that point; `acc` holds hashes only). -/
unsafe def readModule (base : String) (lib : Nat) (acc : Store) :
    IO (Store × Array CompactedRegion) := do
  let mut files : Array System.FilePath := #[System.FilePath.mk (base ++ ".olean")]
  for ext in [".olean.server", ".olean.private"] do
    let f := System.FilePath.mk (base ++ ext)
    if ← f.pathExists then files := files.push f
  let parts ← readModuleDataParts files
  let mut tbl : Std.HashMap Name ConstantInfo := {}
  for (md, _) in parts do
    for ci in md.constants do
      tbl := tbl.insert ci.name ci
  let mut acc := acc
  for (n, ci) in tbl.toList do
    let aux := isAuxName n || (ci matches .ctorInfo _) || (ci matches .recInfo _)
    let mut a := n
    if aux then
      let mut p := n.getPrefix
      let mut found := false
      while !p.isAnonymous && !found do
        if tbl.contains p && !isAuxName p then
          a := p; found := true
        else p := p.getPrefix
    let k : UInt8 := match ci with
      | .thmInfo _ => 1 | .defnInfo _ => 2 | .opaqueInfo _ => 2 | .inductInfo _ => 3 | _ => 0
    let vdeps : Array Name := match ci with
      | .thmInfo t => t.value.getUsedConstants
      | .defnInfo d => d.value.getUsedConstants
      | .opaqueInfo o => o.value.getUsedConstants
      | _ => #[]
    let ds := (ci.type.getUsedConstants ++ vdeps).map (·.hash)
    acc := { acc with hashes := acc.hashes.push n.hash, anchor := acc.anchor.push a.hash,
                      kind := acc.kind.push k, user := acc.user.push (!aux), lib := acc.lib.push lib,
                      deps := acc.deps.push ds }
  return (acc, parts.map (·.2))

unsafe def processModule (base : String) (lib : Nat) (acc : Store) : IO Store := do
  let (acc, regions) ← readModule base lib acc
  for r in regions.reverse do r.free
  return acc

unsafe def main (args : List String) : IO Unit := do
  let listFile :: roots := args | throw <| IO.userError "usage: LIST ROOT..."
  let lines := (← IO.FS.lines listFile).filter (· ≠ "")
  let mut libs : Array String := #[]
  let mut acc : Store := {}
  let mut done := 0
  for l in lines do
    let [libName, base] := l.splitOn " " | continue
    let li ← match libs.idxOf? libName with
      | some i => pure i
      | none => do libs := libs.push libName; pure (libs.size - 1)
    acc ← processModule base li acc
    done := done + 1
    if done % 2000 == 0 then IO.eprintln s!"read {done}/{lines.size} modules, {acc.hashes.size} constants"
  let n := acc.hashes.size
  let mut idx : Std.HashMap UInt64 Nat := {}
  for i in [0:n] do idx := idx.insert acc.hashes[i]! i
  -- closure of the roots over raw constants
  let mut seen : Array Bool := Array.replicate n false
  let mut stack : Array Nat := #[]
  let mut rootsFound := 0
  for r in roots do
    if let some i := idx[r.toName.hash]? then
      stack := stack.push i; rootsFound := rootsFound + 1
  while !stack.isEmpty do
    let i := stack.back!
    stack := stack.pop
    if seen[i]! then continue
    seen := seen.set! i true
    for d in acc.deps[i]! do
      if let some j := idx[d]? then
        if !seen[j]! then stack := stack.push j
  -- users per user-level declaration: all, and counting only users inside the closure
  let mut first : Std.HashMap UInt64 UInt64 := {}
  let mut multi : Std.HashSet UInt64 := {}
  let mut firstR : Std.HashMap UInt64 UInt64 := {}
  let mut multiR : Std.HashSet UInt64 := {}
  for i in [0:n] do
    let a := acc.anchor[i]!
    for d in acc.deps[i]! do
      if let some j := idx[d]? then
        let b := acc.anchor[j]!
        if b != a then
          match first[b]? with
          | none => first := first.insert b a
          | some u => if u != a then multi := multi.insert b
          if seen[i]! then
            match firstR[b]? with
            | none => firstR := firstR.insert b a
            | some u => if u != a then multiR := multiR.insert b
  let mut out : Array String := #[]
  for li in [0:libs.size] do
    let mut thm := 0; let mut thmR := 0; let mut defs := 0; let mut defsR := 0
    let mut once := 0; let mut onceR := 0; let mut unused := 0; let mut consts := 0
    for i in [0:n] do
      if acc.lib[i]! != li then continue
      consts := consts + 1
      if !acc.user[i]! then continue
      let h := acc.hashes[i]!
      if acc.kind[i]! == 1 then
        thm := thm + 1
        if seen[i]! then thmR := thmR + 1
        if first.contains h && !multi.contains h then once := once + 1
        if !first.contains h then unused := unused + 1
        if seen[i]! && firstR.contains h && !multiR.contains h then onceR := onceR + 1
      else if acc.kind[i]! == 2 then
        defs := defs + 1
        if seen[i]! then defsR := defsR + 1
    out := out.push <| "{\"library\":\"" ++ libs[li]! ++ "\",\"constants\":" ++ toString consts
      ++ ",\"theorems\":" ++ toString thm ++ ",\"theorems_reachable\":" ++ toString thmR
      ++ ",\"theorems_used_by_nothing\":" ++ toString unused ++ ",\"theorems_used_once\":" ++ toString once
      ++ ",\"reachable_theorems_used_once_within_closure\":" ++ toString onceR
      ++ ",\"definitions_incl_projections\":" ++ toString defs ++ ",\"definitions_reachable\":" ++ toString defsR ++ "}"
  IO.println <| "{\"modules\":" ++ toString lines.size ++ ",\"roots_found\":" ++ toString rootsFound
    ++ ",\"constants\":" ++ toString n ++ ",\"libraries\":[" ++ ",".intercalate out.toList ++ "]}"
