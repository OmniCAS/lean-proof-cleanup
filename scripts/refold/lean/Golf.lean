/-
`golf "ID" => tacs` (our own tool for the simplify stage, not part of any subject).

Runs a fixed menu of closing tactics on the main goal, each under a heartbeat cap. If one of them
closes the goal, it logs `GOLF ID <tactic>` and is used; otherwise the original tactic block
`tacs` runs unchanged. One build of an instrumented file therefore reports, for every proof
block, whether some one-line automation call can replace it; nested blocks inside `tacs` are only
tried when the outer attempt failed.

The menu also contains `simp_all [facts]` and `grind [facts]`, where `facts` are the theorem
names that occur in the original block: "give the facts, leave the steps to automation".
-/
import Mathlib

open Lean Elab Tactic Meta

namespace Golf

/-- Heartbeat budget of one attempt (in the units of `maxHeartbeats`). -/
register_option golf.heartbeats : Nat := { defValue := 20000, descr := "heartbeat cap per attempt" }
/-- Maximal number of facts handed to `simp_all`/`grind`. -/
register_option golf.maxFacts : Nat := { defValue := 12, descr := "max facts per attempt" }

/-- Global theorem names mentioned in a piece of syntax, in order of first occurrence. -/
partial def factsOf (stx : Syntax) : TermElabM (Array Name) := do
  let env ← getEnv
  let mut out : Array Name := #[]
  let mut todo : List Syntax := [stx]
  while true do
    match todo with
    | [] => break
    | s :: rest =>
      todo := rest
      match s with
      | .ident _ _ n _ =>
        let cs ← try resolveGlobalName n catch _ => pure []
        for (c, fields) in cs do
          if fields.isEmpty && !out.contains c then
            if let some (.thmInfo _) := env.find? c then out := out.push c
      | .node _ _ args => todo := args.toList ++ todo
      | _ => pure ()
  return out

/-- Run `tac` with a fresh heartbeat budget and without error recovery; keep its effect only if
no goal remains and the proof term of the goal is complete. Timeouts and recursion-depth errors
of an attempt are caught (they are runtime exceptions) and count as failure. -/
def closes (tac : Syntax) (budget : Nat) : TacticM Bool := do
  let s ← saveState
  let g ← getMainGoal
  tryCatchRuntimeEx
    (do
      let ok ← withOptions (fun o => maxHeartbeats.set o budget) <| withCurrHeartbeats do
        withoutRecover <| evalTactic tac
        if !(← getUnsolvedGoals).isEmpty then return false
        Term.synthesizeSyntheticMVarsNoPostponing
        let e ← instantiateMVars (.mvar g)
        return !e.hasExprMVar && !e.hasSorry
      unless ok do s.restore
      return ok)
    (fun _ => do
      s.restore
      return false)

syntax (name := golfTac) "golf " str " => " tacticSeq : tactic

@[tactic golfTac] def evalGolf : Tactic := fun stx => do
  let id := stx[1].isStrLit?.getD "?"
  let body := stx[3]
  let budget := golf.heartbeats.get (← getOptions)
  let maxFacts := golf.maxFacts.get (← getOptions)
  let facts := (← factsOf body).extract 0 maxFacts
  let fs : Array (TSyntax `term) := facts.map fun n => mkIdent n
  let mut menu : Array (String × Syntax) := #[]
  menu := menu.push ("rfl", ← `(tactic| rfl))
  menu := menu.push ("omega", ← `(tactic| omega))
  menu := menu.push ("simp", ← `(tactic| simp))
  menu := menu.push ("norm_num", ← `(tactic| norm_num))
  menu := menu.push ("positivity", ← `(tactic| positivity))
  menu := menu.push ("linarith", ← `(tactic| linarith))
  menu := menu.push ("simp_all", ← `(tactic| simp_all))
  menu := menu.push ("grind", ← `(tactic| grind))
  menu := menu.push ("aesop", ← `(tactic| aesop))
  menu := menu.push ("nlinarith", ← `(tactic| nlinarith))
  menu := menu.push ("tauto", ← `(tactic| tauto))
  if !fs.isEmpty then
    let names := ", ".intercalate (facts.toList.map toString)
    menu := menu.push (s!"simp [{names}]", ← `(tactic| simp [$[$fs:term],*]))
    menu := menu.push (s!"simp_all [{names}]", ← `(tactic| simp_all [$[$fs:term],*]))
    menu := menu.push (s!"grind [{names}]", ← `(tactic| grind [$[$fs:term],*]))
  for (name, tac) in menu do
    if ← closes tac budget then
      logInfo m!"GOLF {id} {name}"
      return
  evalTactic body

end Golf
