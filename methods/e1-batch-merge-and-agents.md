# E1 批量合并与智能体流水线（batch merge and agents）

## 1. 一句话判断

当改动涌入的速度超过人审和构建的速度，瓶颈就从写代码变成合并与构建：把能干净合并的改动串成一批、由智能体处理机械冲突、对整批跑一次构建，是维持速度的办法，但它只保证"构建通过"，不保证端到端核验。这只在大仓库上才需要，而且主要出现在模型或智能体成批产出改动时；小仓库每批都能全量重编加完整闸门，顺序合并就够。

## 2. 做什么

- 按顺序把待合并、只改证明源码的 PR 依次叠到主干上（如用 `git merge-tree`），保留能干净合并的。
- 冲突只做机械解决（一边删文件另一边改了它、两边删同样的行、相邻但不重叠的改动），每处解决都先编译改动模块及其直接导入者。
- 整批对着共享缓存完整构建，通过就合并；每个原 PR 保留自己的合并提交和作者信息；批内的坏 PR 用二分剔除。
- 脚本化的变换在新基线上重新生成，而不是 rebase 生成的提交。
- 规则写进仓库里给智能体读的说明文件，用标签控制哪些 PR 进批（延后、等作者、已进批、构建中）。

## 3. 谁在用

- 回归证明选择：Coq 的 iCoq 只重查受改动影响的证明，piCoq 再并行执行 [P53] [P54]；这是批量构建能便宜的前提。
- 定期整库跑的脚本化变换：Mathlib 的过期弃用由定时工作流清理、部分 TacticAnalysis pass 定期运行 [P50] [T4]（见 [curated-library-mathlib](../cases/curated-library-mathlib.md)）；Metamath 每一两年对整个 set.mm 跑一遍 `minimize_with` [T15]；Mizar 的 MML 由核心团队定期修订 [P48]。
- 编译把关的智能体流水线：Lean Refactor 的冻结智能体 [P11]、Lean Refactor Arena 的参赛报告（固定改写规则、可复现） [P14]、LeanLean 每个仓库 12 小时的智能体 [P30]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的批次 b1 到 b23（如 [#1198] 合 68 个 PR、[#2318] 合 139 个 PR，最后一批是 [#4761]），维护者用带智能体的流程修冲突 [z643408471]；新 `main` 的批次 m1 到 m4（[#5631]、[#5636]、[#5645]、[#5657]）；[#312] 加入 `AGENTS.md`，文档类 PR 暂停 [z643424144]，贡献者被要求在 Zulip 上说明 AI 生成的内容。

## 4. 证据等级

- **主流在用**：回归证明选择、定期整库跑的变换（各系统）；RH 社区的批量合并。
- **有论文或工具**：编译把关的智能体改写 [P11] [P14] [P30]。
- **作者自述**：用智能体解决合并冲突，只有 RH 社区维护者的说明 [z643408471]。

## 5. 作用层级

大仓库的流程。不需要理解数学。小仓库只用得上其中"脚本化变换在新基线上重新生成"一条。

## 6. 正确性靠什么保证

每批的检查：import 可解析、没有被删模块仍被导入、导入图无环、不新增 `sorry`/`admit`/`axiom`、不改冻结的裁判文件（Challenge、comparator 配置、最终定理所在文件）。这些是构建层面的保证；端到端核验见 [E2](e2-verification-gate.md)。（例：Lean RH 开发里 CI 拒绝任何改 challenge 文件的 PR [C3]。）

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 比赛题（Lean Refactor Arena） | 编译把关的智能体改写每题约 2.8 美元 [P14] | 他人报告 |
| 仓库 × LeanLean 的 64 个真实仓库 | 每个仓库 12 小时智能体；最佳模型平均压缩分 48.3% [P30] | 他人报告 |
| 大仓库 × 模型生成（RH） | `alpoge` 线从 `7cce738` 到第 23 批共 146 个主线提交；新 `main` 截至 `b7642ae` 13 个 | 本仓库测（`data/rh_mainline_merges.csv`） |
| 大仓库 × 模型生成（RH） | 最快一批开出后 55 分钟合并 [z643352115] | 他人报告 |
| 大仓库 × 模型生成（RH） | 过去 24 小时平均每分钟超过一个 PR；每批构建时间大致不变，而每批的提交数在增加 [z643489800] | 他人报告 |
| 大仓库 × 模型生成（RH） | 批次 b6：68 个 PR，净 −377,039 行；b15：139 个 PR，净 −172,395 行 | 本仓库测 |
| 其他规模与来源（批量合并本身） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 人审成了瓶颈；模型生成的文档与引用出错时只能整类暂停（例：Lean RH 开发里维护者指出人审是瓶颈 [z642928351]，文档类 PR 被整体暂停 [z643424144]）。
- 批内一个坏 PR 会拖住整批，要能二分剔除。
- 增量构建对着共享缓存，缓存的完整性成了新的信任点（[E2](e2-verification-gate.md)、[E4](e4-build-acceleration.md)）。
- 智能体改写按定理计费，整库跑之前要先估预算 [P14]。

## 9. 什么时候用

PR 数量超过人审能力、或智能体成批产出改动时；配合 A、B 层的脚本化变换（它们最适合成批）。小仓库不必：每批全量重编加完整闸门更简单。

## 10. 未解决的问题

- 如何在批处理里加入"每批一次 comparator"而不让 CI 时间翻倍？能否只对受影响的依赖锥体检查？
- 智能体解决的冲突怎么审：要不要为每处冲突解决单独出回执？
- 智能体批量产出的改动，人审抽样的比例该怎么定？

[#312]: https://github.com/leanprover-community/riemann-hypothesis/pull/312
[#1198]: https://github.com/leanprover-community/riemann-hypothesis/pull/1198
[#2318]: https://github.com/leanprover-community/riemann-hypothesis/pull/2318
[#4761]: https://github.com/leanprover-community/riemann-hypothesis/pull/4761
[#5631]: https://github.com/leanprover-community/riemann-hypothesis/pull/5631
[#5636]: https://github.com/leanprover-community/riemann-hypothesis/pull/5636
[#5645]: https://github.com/leanprover-community/riemann-hypothesis/pull/5645
[#5657]: https://github.com/leanprover-community/riemann-hypothesis/pull/5657
[C3]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P14]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P48]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[P53]: ../REFERENCES.md
[P54]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[z642928351]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642928351
[z643352115]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643352115
[z643408471]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643408471
[z643424144]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643424144
[z643489800]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643489800
