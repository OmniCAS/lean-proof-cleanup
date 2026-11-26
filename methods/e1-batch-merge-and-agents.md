# E1 批量合并与智能体流水线（batch merge and agents）

## 1. 一句话判断

当贡献以每分钟一个 PR 的速度涌入时，瓶颈从写代码变成合并与构建；把能干净合并的 PR 串成一批、由智能体处理机械冲突、对整批跑一次构建，是社区维持速度的关键，但它只保证"构建通过"，不保证端到端核验。

## 2. 做什么

- 按 PR 编号把所有待合并、只改 `src/` 的 PR 用 `git merge-tree` 依次叠到主干上，保留能干净合并的。
- 冲突只做机械解决（一边删文件另一边改了它、两边删同样的行、相邻但不重叠的改动），每处解决都先编译改动模块及其直接导入者。
- 整批对着共享缓存完整构建，通过就合并；每个原 PR 保留自己的合并提交和作者信息。
- 规则写进仓库的 `AGENTS.md`，用标签（`deferred`、`awaiting-author`、`batch`、`building`）控制哪些进批。

## 3. 谁在用

- 社区 `alpoge` 线：批次 b1 到 b23（如 [#1198] 合 68 个 PR、[#2318] 合 139 个 PR，最后一批是 [#4761]）；维护者用带智能体的流程修冲突 [z643408471]。
- 新 `main`：批次 m1 到 m4（[#5631]、[#5636]、[#5645]、[#5657]）。
- 规则文件：[#312] 加入 `AGENTS.md`；文档类 PR 暂停 [z643424144]；贡献者被要求在 Zulip 上说明 AI 生成的内容。

## 4. 证据等级

主流在用。

## 5. 作用层级

大仓库的流程。不需要理解数学。

## 6. 正确性靠什么保证

每批的检查：import 可解析、没有被删模块仍被导入、导入图无环、不新增 `sorry`/`admit`/`axiom`、不改 Challenge、comparator 与 `Main.lean` 文件；CI 拒绝任何改 challenge 文件的 PR [C3]。这些是构建层面的保证；端到端核验见 [E2](e2-verification-gate.md)。

## 7. 效果

| 数字 | 标记 |
|---|---|
| `alpoge` 线从 `7cce738` 到第 23 批共 146 个主线提交；新 `main` 截至 `b7642ae` 13 个 | 本仓库测（`data/rh_mainline_merges.csv`） |
| 最快一批开出后 55 分钟合并 [z643352115] | 他人报告 |
| 过去 24 小时平均每分钟超过一个 PR；每批构建时间大致不变，而每批的提交数在增加 [z643489800] | 他人报告 |
| 批次 b6：68 个 PR，净 −377,039 行；b15：139 个 PR，净 −172,395 行 | 本仓库测 |

## 8. 代价与坑

- 人审成了瓶颈 [z642928351]；模型生成的文档与引用出过错，只能整类暂停。
- 批内一个坏 PR 会拖住整批，要能二分剔除。
- 增量构建对着共享缓存，缓存的完整性成了新的信任点（[E2](e2-verification-gate.md)）。

## 9. 什么时候用

PR 数量超过人审能力时；配合 A、B 层的脚本化变换（它们最适合成批）。

## 10. 未解决的问题

- 如何在批处理里加入"每批一次 comparator"而不让 CI 时间翻倍？

[#312]: https://github.com/leanprover-community/riemann-hypothesis/pull/312
[#1198]: https://github.com/leanprover-community/riemann-hypothesis/pull/1198
[#2318]: https://github.com/leanprover-community/riemann-hypothesis/pull/2318
[#4761]: https://github.com/leanprover-community/riemann-hypothesis/pull/4761
[#5631]: https://github.com/leanprover-community/riemann-hypothesis/pull/5631
[#5636]: https://github.com/leanprover-community/riemann-hypothesis/pull/5636
[#5645]: https://github.com/leanprover-community/riemann-hypothesis/pull/5645
[#5657]: https://github.com/leanprover-community/riemann-hypothesis/pull/5657
[C3]: ../REFERENCES.md
[z642928351]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642928351
[z643352115]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643352115
[z643408471]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643408471
[z643424144]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643424144
[z643489800]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643489800
