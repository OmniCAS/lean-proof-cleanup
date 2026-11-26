# A3 linter 驱动的删除（linter-driven cleanup）

## 1. 一句话判断

零风险、可整库批量做的收尾工作，删的是语法垃圾而不是数学。收益跟着来源走：维护者精心维护的库默认开着这些 linter，合入前就处理掉，几乎没有存量；模型生成的单个证明里，删除类编辑占已接受编辑的一半；模型生成的大型开发里能成批删，但相对总行数很小。主要价值是让后续改写面对干净的代码，并且做成 CI 之后新代码不再积累。

## 2. 做什么

- 收集构建日志里 Lean 与 Mathlib linter 的警告：未用 simp 参数、不改变目标的 tactic、多余 `simpa`、未用变量；不可达 tactic、多余 `<;>` 要另开 `linter.extra.*`；未用的 `have`/`suffices` 由环境 linter（`#lint` 或 `lake lint`）报告。
- 用脚本只删不改：Mathlib 的 `fix_unused.py`、`fix_unused_simp_args.py` [T6]，AXLE `simplify_theorems` 的删除部分 [P13]，或自写的删除器。
- 迭代到没有新警告为止（删一处可能让另一处变成多余）。
- 下游仓库先收割默认开着的警告，再在 lakefile 打开 Mathlib 的标准集合，最后把这些 linter 放进 CI。

## 3. 谁在用

- Lean 核心与 Mathlib：`unusedVariables`、`unusedSimpArgs`、`unnecessarySimpa`、`unusedTactic` 默认开 [T2] [T3]；环境 linter `unusedHavesSuffices` [T8]；修复脚本 [T6]；维护论文把 `#lint` 与整环境检查列为库维护的基本手段 [P49] [P50]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 工具与论文：AXLE 的 `simplify_theorems` [P13]、ProofOptimizer 的符号阶段 [P9]、LeanPolish 的删除类编辑 [P12]。
- 其他系统：Isabelle Sledgehammer 的事实集最小化 [P3]、TacticToe 的 tactic 参数最小化 [P4]、Metamath 的 `minimize_with`（每一两年对整个 set.mm 跑一次）[T15]、Mizar 找多余前提与步骤的 irrelevant utilities [P6]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#67] → [#243]（James Shore，只删 linter 标为无用的语法）；新 `main`（可读版）上 Righi 的未用字段 PR [#5642]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Mathlib 默认开启并在合入前处理；Metamath、Mizar 有同类的整库做法。
- 有论文或工具：AXLE、ProofOptimizer、LeanPolish 的删除阶段。
- 作者自述：RH 案例里大批删除之后的构建与核验结果。

## 5. 作用层级

单个定理到大仓库：诊断在定理内，修复可以整库并行。不需要理解数学。

## 6. 正确性靠什么保证

- 只改证明体，陈述不可能变化；重编该文件即可，批量时整库重编。
- linter 只是诊断，删掉之后能否编译由重编决定。
- 逐处编辑后过内核、语料再用独立进程重编，是 LeanPolish 的做法 [P12]；批量删除时同样以重编为准。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | LeanPolish 的 33,402 条已接受编辑中，删除占 51.6% [P12] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | AXLE `simplify_theorems`（主要是删死代码）：miniF2F 省 27.1%，PutnamBench 省 25.6% [D2] | 他人报告 |
| 库 × Mathlib | 没有公开的存量数字（这几类 linter 默认开着，合入前处理） | — |
| 仓库 × 人写研究仓库 | 没有公开数字 | — |
| 大仓库 × 模型生成（RH） | #243：约 10.7 万~11.2 万行删除，"unused" 类警告 −94%；作者自述完整构建 + nanoda + con-leche [z642796623] [z643005632] | 他人报告 |
| 大仓库 × 模型生成（RH） | #67：存储的 linter 警告约 35.7 万 → 约 26.5 万 | 他人报告 |
| 大仓库 × 模型生成（RH） | linter 本身约占构建 CPU 的 0.4% [z643409003] | 他人报告 |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。单定理数字的背景见 [单定理 × 生成证明](../cases/theorem-scale-generated-proofs.md)。

## 8. 代价与坑

- 收益集中在模型生成的代码里；人写代码、尤其默认开着 linter 的库，几乎没有可删的。
- 删掉 `<;>` 之类的组合子后，有时会改变哪个 tactic 生效，必须重编。
- 环境 linter 要在全量构建之后跑，仓库越大越贵。
- 大量小改动会制造合并冲突，适合单独成批（[E1](e1-batch-merge-and-agents.md)）。

## 9. 什么时候用

- 在 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 之后（先删整块，再删碎片），在 [B2](b2-tactic-golf-and-automation.md) 之前。
- 每一轮改写之后再跑一次。
- 任何来源的下游仓库：尽早把默认 linter 放进 CI，存量一次收割，之后不再积累。

## 10. 未解决的问题

- 删除类与替换类 pass 的最佳顺序：LeanPolish 与 AXLE 两种顺序叠加的结果接近（miniF2F 35.9% 对 34.0%） [D2]，仓库规模上没有测过。
- 默认关闭的 `linter.extra.*`（不可达 tactic、多余 `<;>`）在模型生成的代码上能多删多少？没有公开数字。

[#67]: https://github.com/leanprover-community/riemann-hypothesis/pull/67
[#243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[D2]: ../REFERENCES.md
[P3]: ../REFERENCES.md
[P4]: ../REFERENCES.md
[P6]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P13]: ../REFERENCES.md
[P49]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T2]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[T6]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[z642796623]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642796623
[z643005632]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643005632
[z643409003]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643409003
