/-
Analysis helpers for the mechanical stage (our own code, not part of upstream).

* `Gate.dupReport`: groups of theorems of one module whose types are syntactically equal.
* `Gate.aliasReport`: theorems and definitions whose body is another project constant applied
  to its own bound variables in order (an alias or thin wrapper).
-/
import Gate.Tools

open Lean

namespace Gate

private def moduleConsts (modName : Name) : CoreM (Array ConstantInfo) := do
  let env ← getEnv
  let some midx := env.getModuleIdx? modName | throwError "module {modName} not imported"
  return env.header.moduleData[midx.toNat]!.constNames.filterMap env.find?

/-- Print groups of user-level theorems of `modName` with identical type. -/
def dupReport (modName : Name) : CoreM Unit := do
  let cs ← moduleConsts modName
  let mut groups : Std.HashMap UInt64 (Array ConstantInfo) := {}
  for ci in cs do
    if ci matches .thmInfo _ then
      if ci.name.isInternalDetail then continue
      if (← findDeclarationRanges? ci.name).isNone then continue
      groups := groups.insert ci.type.hash ((groups.getD ci.type.hash #[]).push ci)
  let mut n := 0
  for (_, g) in groups.toList do
    if g.size > 1 then
      let t := g[0]!.type
      let same := g.filter fun c => c.type == t && c.levelParams.length == g[0]!.levelParams.length
      if same.size > 1 then
        n := n + 1
        IO.println s!"dup {same.map (·.name) |>.toList}"
  IO.println s!"dup-groups {n}"

/-- Strip leading lambdas, returning the body and the number of binders. -/
private def stripLams : Expr → Nat → Expr × Nat
  | .lam _ _ b _, n => stripLams b (n + 1)
  | .mdata _ e, n => stripLams e n
  | e, n => (e, n)

/-- Print user-level theorems/definitions whose body is `c x₁ … xₖ` for a project constant `c`
and bound variables only. -/
def aliasReport (modName : Name) : CoreM Unit := do
  let env ← getEnv
  let cs ← moduleConsts modName
  let mut n := 0
  for ci in cs do
    let some v := (match ci with
      | .thmInfo t => some t.value
      | .defnInfo d => some d.value
      | _ => none) | continue
    if ci.name.isInternalDetail then continue
    if (← findDeclarationRanges? ci.name).isNone then continue
    let (b, _) := stripLams v 0
    let f := b.getAppFn
    let args := b.getAppArgs
    if let .const c _ := f then
      if isProjectConst env c && c != ci.name && args.all (fun a => a.isBVar) then
        n := n + 1
        IO.println s!"alias {ci.name} := {c} ({args.size} args)"
  IO.println s!"aliases {n}"

end Gate
