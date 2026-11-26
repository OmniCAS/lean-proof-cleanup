# A6 选项与性能清理（options and performance）

## 1. 一句话判断

针对构建时间和对版本的稳健性，不针对长度，适用于任何来源。选项覆盖的多少并不区分来源（维护者精心维护的库里覆盖密度反而最高），区别在于每处有没有写明原因、有没有定期清点；模型生成的证明更常靠重度自动化和放宽的上限才能编译，对库版本更敏感。最大的风险是"自动换成更强的 tactic"往往更慢，所以每处改动都要计时。

## 2. 做什么

- 清点 `set_option maxHeartbeats`、`synthInstance.*`、`backward.*` 等覆盖：`#count_heartbeats in` 测实际用量，删掉或降到实测值附近 [T5]。
- 清掉兼容性选项与 `attribute [-instance]` 之类的权宜做法；慢证明拆成引理。
- 带计时闸门的 tactic 替换：只收"更短且不更慢"的（工具见 [B2](b2-tactic-golf-and-automation.md)）。
- 每次升工具链之后单独做一轮，和移植本身分开验收。

## 3. 谁在用

- Mathlib：`linter.style.maxHeartbeats` 要求每处覆盖写明原因 [T3]；`#count_heartbeats` 测量 [T5]；`grind_unused_lemmas.sh` 清理激活很多次却没用上的 `@[grind]` 引理 [T6]；TacticAnalysis 的 `terminalToGrind` 在变慢时警告 [T4]；技术债定期统计 [P50]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 论文：Lean Refactor 把编译时间和版本兼容列为与长度并列的目标 [P11]；ProofOptimizer 报告缩短后的编译时间 [P9]；Isabelle 跨版本失败的实证研究 [P47]；Coq 大型证明系统的性能工程 [P56]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#9]（366 处 heartbeat 覆盖）、[#71]（删 `backward.*` 选项）、Jonathan Roy 对约 8,400 处设置的清点 [z643467299]；社区仓库的 `AGENTS.md` 规定先试 `lia`/`grind` 再改写 `nlinarith`，避免 `attribute [-instance]` [#312]；新 `main` 升到 v4.37.0-rc1 [#5769]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Mathlib 的风格 linter、计数与清理脚本。
- 有论文或工具：以编译时间为目标的改写（Lean Refactor、ProofOptimizer）。
- 作者自述：RH 案例里的效果数字，零散，部分是转述。

## 5. 作用层级

单个定理到大仓库：清点是仓库级的，修改落在单个定理上。不需要理解数学（拆慢证明除外）。

## 6. 正确性靠什么保证

- 选项只影响搜索与 elaboration，不影响内核；能编译即可。
- 替换 tactic 时要重编并比较 heartbeats，变慢就拒。
- 全局放宽的上限（lakefile 里的 `maxHeartbeats`）要单独记录，否则逐处清点会漏掉（例：Lean RH 开发重写后的紧凑版全局设了 `maxHeartbeats 4000000`）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | ProofOptimizer：约 2/3 的证明缩短后编译快至少 10% [P9] | 他人报告 |
| 仓库 × 人写研究仓库（Lean Refactor 的研究仓库） | 编译时间最多 −60%；长度与编译时间只是弱相关 [P11] | 他人报告 |
| 库 × Mathlib | 选项覆盖每千行代码 8.3 处，是七棵树里最高的（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 选项覆盖每千行代码 3.0–5.9 处（[profiles](../cases/profiles.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | 选项覆盖每千行代码：原始 5.0，重写后的可读版 0.15、紧凑版 0.64（[profiles](../cases/profiles.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | `maxHeartbeats` 设置：原始 64,937 处，可读版 5 处，紧凑版 9 处（[grh-compact-reliability](../cases/rh/grh-compact-reliability.md) §5） | 本仓库测 |
| 大仓库 × 模型生成（RH） | 紧凑版全局设 `maxHeartbeats 4000000`，并有 30 处 `respectTransparency false` | 本仓库测 |
| 大仓库 × 模型生成（RH） | #66 在移植时反而加了约 2.45 万处 `synthInstance.maxHeartbeats` [#66] | 他人报告 |
| 大仓库 × 模型生成（RH） | `terminalToGrind` 在 `alpoge` 线上给出的 26 条建议中 22 条更慢，最多慢 170 倍 [z643461700] | 他人报告（转述） |

覆盖密度指向构建与版本问题，不指向冗余。RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 升工具链时常常要先加覆盖才能编译通过，清理与移植方向相反，要分开验收（例：Lean RH 开发里 #66 移植时加了约 2.45 万处覆盖）。
- 重度自动化的证明对库版本更敏感，常靠放宽上限才能编译（例：Lean RH 开发的紧凑版）。
- 计时有噪声，单次测量不能作为拒绝依据；用 `#count_heartbeats!` 多次取样 [T5]。
- heartbeats 可复现但不等于墙钟时间；闸门用 heartbeats，最终验收看冷构建时间（[E3](e3-metrics.md)）。

## 9. 什么时候用

- 删除与导入工作之后、改写之前；每次升工具链之后单独做一轮。
- 任何来源都先清点覆盖最高的地方：它们往往集中在少数文件里，是构建热点的首选候选。
- 下游仓库可直接照搬"每处覆盖写明原因"的规则，新覆盖从此可审。

## 10. 未解决的问题

- heartbeat 上限与实际编译时间的关系在大仓库上没有系统数据。
- "更短"与"更快"冲突时的验收规则没有统一做法（与 [B2](b2-tactic-golf-and-automation.md) 共有）。
- （RH 案例）约 8,400 处设置里有多少是真正需要的？清点还在进行。

[#9]: https://github.com/leanprover-community/riemann-hypothesis/pull/9
[#66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[#71]: https://github.com/leanprover-community/riemann-hypothesis/pull/71
[#312]: https://github.com/leanprover-community/riemann-hypothesis/pull/312
[#5769]: https://github.com/leanprover-community/riemann-hypothesis/pull/5769
[P9]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P47]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[P56]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[T6]: ../REFERENCES.md
[z643461700]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643461700
[z643467299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643467299
