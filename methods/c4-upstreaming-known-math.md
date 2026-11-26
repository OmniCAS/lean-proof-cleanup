# C4 把已知数学移到通用库（upstreaming known mathematics）

## 1. 一句话判断

对单个项目不减少"要检查的东西"，只是把它搬到通用库里；但它是唯一能让清理成果惠及其他项目的路线，也让项目本身只剩新的数学。它只在仓库规模上有意义。来源决定能搬多少、要先做多少：人写研究仓库和模型生成的大型开发都带着大量通用库缺少的背景，模型生成的部分还要先通用化、达到库的标准；维护者精心维护的库是接收方，审阅节奏以周、月计。

## 2. 做什么

- 把项目里证明的标准结果（背景理论、教科书定理）整理成通用陈述，提交到 Mathlib 或专门的通用库，再让项目依赖它们。
- 先在路线图里列出项目需要而库里缺少的内容，按依赖顺序推进。
- 动手前先查库里是否已有、只是没被接上（相似检索、对每条自有引理试 `exact?`，见 [B1](b1-library-replacement.md)）。

## 3. 谁在用

- Mathlib 的维护流程：审阅、linter、弃用别名、技术债跟踪 [P49] [P50]（见 [curated-library-mathlib](../cases/curated-library-mathlib.md)）；MathlibLemma 挖出 1,506 条已验证的常识引理，其中少量合入 Mathlib [P36]。
- 其他系统：Metamath 的 set.mm 采纳了 GPT-f 找到的 23 个更短证明，是模型产出被主库接受的最早案例 [P5]。
- 找"库里已有"的工具：跨库概念对齐 [P31]、相似声明检索 [P34]。
- Tau Ceti：把已知数学重新形式化成通用库的项目，按路线图推进（[TauCetiProject/TauCetiRoadmap](https://github.com/TauCetiProject/TauCetiRoadmap)，[TauCetiProject/TauCeti](https://github.com/TauCetiProject/TauCeti)）。
- 大仓库示例（Lean RH 开发，模型生成）：Tau Ceti 针对该开发所需而 Mathlib 没有的内容新开了 41 个路线图 [z642819551]；社区新 `main` 的计划之一是把已知数学移到 Tau Ceti（见 [rh-community-cleanup](../cases/rh/rh-community-cleanup.md)）；立场上，David Loeffler 主张把标准材料移到 Tau Ceti、这里只留新的数学，Joseph Myers 认为只在本仓库内去冗余只惠及本项目 [z642818201]；grh-lean 的 `Lib/`（紧凑版 573 个文件：Weil 表示、Shimura 簇、adele、上同调、类域论等）是天然的候选 [D16]。

## 4. 证据等级

- **主流在用**：Mathlib 的接收流程 [P49] [P50]；模型产出被主库接受有先例 [P5] [P36]。
- **有论文或工具**：找已有内容的对齐与检索 [P31] [P34]。
- **主流在用（进行中）**：RH 案例里的 Tau Ceti 路线图；实际迁移量尚无数字。

## 5. 作用层级

小仓库到大仓库，以及它们与通用库之间。需要理解数学，也需要符合目标库的标准。

## 6. 正确性靠什么保证

- 通用库自己的审阅与 CI；项目这边只要最终陈述不变、闸门通过（[E2](e2-verification-gate.md)）。
- 陈述用到的定义若来自通用库，要确认库版本变动不改定义（例：Lean RH 开发里，[grh-compact-reliability](../cases/rh/grh-compact-reliability.md) §1 比较了两个 Mathlib 版本之间定义 ζ 与 L 函数的文件）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | MathlibLemma：1,506 条已验证的常识引理，少量合入 [P36] | 他人报告 |
| 库 × Metamath set.mm | GPT-f 的 23 个更短证明被采纳 [P5] | 他人报告 |
| 大仓库 × 模型生成（RH） | Tau Ceti：41 个新路线图 [z642819551] | 他人报告 |
| 大仓库 × 模型生成（RH） | 项目本身的缩小：取决于迁出多少，目前没有数字 | — |
| 库 × Tau Ceti | 构建规模约 3.5 万个模块，模型预测约 57 核·时 | 他人报告（[OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build)） |
| 其他规模与来源（人写研究仓库迁出的量） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 慢：通用库的审阅标准高，节奏以周、月计。
- 项目要跟着库的版本走，迁移期间两边都在变。
- 移出的部分仍要被检查，"项目变小"不等于"要信任的东西变少"。
- 模型生成的背景材料通常要先通用化（[C2](c2-statement-generalization.md)）、改名、补文档才可能被接受；直接搬是搬不进去的。

## 9. 什么时候用

在 [C2](c2-statement-generalization.md) 之后（先写成通用陈述）；与 [D2](d2-blueprint-first-reformalization.md) 配合（蓝图决定哪些是背景）。人写研究仓库可以边做边上游；模型生成的大型开发宜在重写之后，因为原始生成的代码达不到库的标准。

## 10. 未解决的问题

- 一个项目的背景里，有多少已经在 Mathlib 里、只是没被接上？对齐与检索工具 [P31] [P34] 能否自动给出这个比例？
- 模型生成的背景材料要改到什么程度才能被通用库接受？除了 [P5] [P36] 的少量先例，没有系统的数字。
- （RH 案例）RH 所需的背景里，有多少已经在 Mathlib 或 Tau Ceti 里、只是没被接上？

[D16]: ../REFERENCES.md
[P5]: ../REFERENCES.md
[P31]: ../REFERENCES.md
[P34]: ../REFERENCES.md
[P36]: ../REFERENCES.md
[P49]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[z642818201]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642818201
[z642819551]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642819551
