# Tools for the staged compression experiments

**Summary (English).** Scripts and Lean files used by the experiments in [`../../experiments/`](../../experiments/README.md). The environment and workflow are described in [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md). Everything here is our own code (Apache-2.0); nothing is copied from the subjects.

| File | Stage | What it does |
|---|---|---|
| `gate.py`, `lean/GateTools.lean` | every stage | Gate for one subject: frozen statement files, statement fingerprint of the headline theorems against the challenge module, axioms, full offline build |
| `metrics.py` | every stage | Source metrics (same conventions as `../profile_lean_trees.py`) and declaration-graph metrics read from the built environment |
| `lean/GateAnalysis.lean` | 1 mechanical | Theorems with identical types; aliases |
| `lean/ProjectGraph.lean`, `graph_summary.py`, `server/project_graph.sh` | 1 mechanical | Declaration graph of a whole multi-file project and its reachability summary |
| `lean/ClosureFromOleans.lean` | 1 mechanical | Headline closure of a very large project read one module at a time from its `.olean` files (no environment, so no limit on the number of modules) |
| `prune_unreachable.py` | 1 mechanical | Delete declarations the headline theorems do not reach, with build feedback; keeps instances, attribute-tagged declarations and names still mentioned in source |
| `unroll.py` | 2 unroll | Inline single-use theorems into their only user as local `have` blocks, with build feedback |
| `unroll_project.py` | 2 unroll | The same for a multi-file project, module by module in parallel |
| `lean/Golf.lean`, `golf_blocks.py` | 3 simplify | Probe every proof block for a one-line automation replacement; apply and verify |
| `repair_modules.py` | 2 unroll | After a per-module unroll of a multi-file project: full build, restore from the previous tag every module that fails and every unrolled module it mentions, repeat until the build passes |
| `prompts/` | 3–5 | Briefs given to rewriting agents (`rewrite-block.md` is the template for one block behind a contract) |
| `dominators.py` | 3–5 | Sub-developments with a one-statement interface: dominator tree of the declaration graph; `--show NAME --block FILE` writes a block (contract theorem, the declarations needed only for it, their line ranges) |
| `block_gate.py` | 3–5 | Gate for rewriting one block behind its contract: the subject's gate, the contract theorem's statement fingerprint against the base, and locality of the change (every changed line inside the block), so that blocks rewritten separately can be merged |
| `candidate_graph.py`, `reference_counts.py` | choosing subjects | Import-graph closure and name-reference estimates from source, without building |
| `server/` | infra | Fetch and verify toolchains and sources, fetch Mathlib oleans, timed builds with memory sampling |

Configuration is by environment variables (`REFOLD_REPO`, `REFOLD_OUT`, `REFOLD_ISOLATE`, `REFOLD_SUBJECTS`); see the docstring of `gate.py`. A working copy needs `refold-subjects.json`, for example:

```json
{"ramsey": {"solution": "MulticolorTriangleRamsey", "challenges": ["I_MulticolorTriangleRamsey"]}}
```

and `lean/GateTools.lean` installed as `Gate/Tools.lean` (plus `lean/GateAnalysis.lean` as `Gate/Analysis.lean`) with a `Gate` library in its lakefile.
