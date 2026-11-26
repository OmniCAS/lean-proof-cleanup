# A7 分阶段的机械流水线（staged mechanical pipeline）

## 1. 一句话判断

把可达性裁剪、linter 删除、去重、导入收窄串成可重放、每步有回执的流水线，是机械路线里最可信的做法；它不提高上限，但让每一步都能被第三方独立复核。规模越大、来源越难信任（模型生成的大型开发），回执越值钱；维护者精心维护的库把同一套东西做成定期跑的 CI，而不是一次性运动。

## 2. 做什么

- 固定基线提交和工具链；每个阶段只做一类变换（删未用声明、删 linter 标记的语法、去重、删多余 import）。
- 每个阶段是一个提交，附回执：变换脚本与参数、输入输出的树指纹、完整构建结果、独立内核结果、陈述比对结果。
- 任何人用同样的脚本从基线重放，指纹必须一致。
- 变换只删或改指向，不写任何证明；改写类工作另立流水线。
- 长期维护的仓库把各阶段做成定期任务，每次在当前主干上重跑。

## 3. 谁在用

- 定期整库流程：Mathlib 在 CI 里跑 linter 与 `lake shake`，TacticAnalysis 的昂贵检查定期运行，过期的 deprecation 定时清理 [T1] [T4] [P50]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）；Metamath 每一两年对整个 set.mm 跑一次 `minimize_with`，并用 `/no_new_axioms_from` 防止引入新公理 [T15]；Mizar 的 MML 由核心团队定期修订，有公开的修订记录 [P48] [T17]。
- 单个证明上的不动点迭代：LeanPolish 把删除与替换 pass 循环到不再变化 [P12]。
- 大仓库示例（Lean RH 开发，模型生成）：James Shore 的 `rh-proof-trimmed`，S1 删未用声明、S2 删 linter 标记的语法、S3 去重（只在 4.37 上）、S4 删多余 import；S1–S3 已并入社区线（[#55]、[#67]、[#243]、[#295]）[D9]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Metamath、Mizar、Mathlib 的定期整库流程。
- 有论文或工具：LeanPolish 的不动点迭代；RH 案例里带回执的分阶段裁剪（公开仓库与回执）。
- 作者自述：RH 案例里各阶段的结果，没有第三方复核报告。

## 5. 作用层级

小仓库到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 每个阶段：完整构建；独立内核接受导出；comparator 对照冻结的 Challenge 导出；逐条比较导出里的陈述与基线（例：Lean RH 开发里 Shore 每阶段用 Lean 4.33.1 完整构建，nanoda 接受导出，con-leche `--compare` 对照公开的 challenge [D9]）。
- 变换不写任何证明，只删或改指向，所以审阅只需看脚本，不需要看每一处 diff。
- 最小化不引入新公理，照搬 Metamath 的约束 [T15]。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | LeanPolish 的符号 pass 迭代到不动点，miniF2F 节省从 19.7% 升到 27.5% [P12] | 他人报告 |
| 其他规模与来源（Mathlib、Metamath、Mizar 的定期流程，人写研究仓库） | 没有公开的分阶段压缩数字 | — |
| 大仓库 × 模型生成（RH） | 基线（社区 `7da4577e`）：文件 164,463，行 16,588,671，声明 1,024,669 [D9] | 他人报告 |
| 大仓库 × 模型生成（RH） | S1：文件 150,632，行 14,473,033，声明 858,404 [D9] | 他人报告 |
| 大仓库 × 模型生成（RH） | S2：文件 150,632，行 14,453,805，声明 858,404 [D9] | 他人报告 |
| 大仓库 × 模型生成（RH） | S4（分支 `s4-on-s1`）：文件 150,632，行 14,252,250，声明 858,404 [D9] | 他人报告 |
| 大仓库 × 模型生成（RH） | 从基线算：行 −14.1%，声明 −16.2% | 估计（按上面几行） |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 每个阶段都要完整构建和导出，仓库越大越贵，大仓库上每次以小时计。
- 主线同时在变，阶段需要在新基线上重做（例：Lean RH 开发里 S2、S3 都移植过）。
- 上限受 [A1](a1-reachability-pruning.md)–[A4](a4-import-narrowing.md) 本身限制。
- 回执格式没有标准，第三方要复核只能读脚本和日志。

## 9. 什么时候用

- 大仓库清理的第一阶段，或任何需要向第三方证明"只做了机械变换"的场合。
- 长期维护的库和研究仓库：做成定期 CI 任务，跑在当前主干上。
- 之后的改写类路线（B、C、D）各自另立回执。

## 10. 未解决的问题

- 回执格式没有标准；可以考虑把树指纹与导出哈希写进 CI，由第三方机器复算。
- 定期跑的频率：Metamath 一两年一次，Mathlib 按 CI 节奏；快速变化的仓库多久跑一次合适？没有公开的经验。
- 机械阶段之间的顺序是否影响最终结果（例如先去重还是先删 linter 标记的语法）？没有系统比较。

[#55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[#67]: https://github.com/leanprover-community/riemann-hypothesis/pull/67
[#243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[D9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P48]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[T17]: ../REFERENCES.md
