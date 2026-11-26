# C4 把已知数学移到通用库（upstreaming known mathematics）

## 1. 一句话判断

对单个项目不减少"要检查的东西"，只是把它搬到通用库里；但它是唯一能让清理成果惠及其他项目的路线，也让项目本身只剩新的数学。

## 2. 做什么

- 把项目里证明的标准结果（背景理论、教科书定理）整理成通用陈述，提交到 Mathlib 或专门的通用库，再让项目依赖它们。
- 先在路线图里列出项目需要而库里缺少的内容，按依赖顺序推进。

## 3. 谁在用

- Tau Ceti：针对 RH 开发所需而 Mathlib 没有的内容，新开了 41 个路线图 [z642819551]（[TauCetiProject/TauCetiRoadmap](https://github.com/TauCetiProject/TauCetiRoadmap)，[TauCetiProject/TauCeti](https://github.com/TauCetiProject/TauCeti)）。
- 社区新 `main` 的计划之一是把已知数学移到 Tau Ceti（见 [rh-community-cleanup](../docs/rh-community-cleanup.md)）。
- 立场：David Loeffler 主张把标准材料移到 Tau Ceti、这里只留新的数学；Joseph Myers 认为只在本仓库内去冗余只惠及本项目 [z642818201]。
- grh-lean 的 `Lib/`（紧凑版 573 个文件：Weil 表示、Shimura 簇、adele、上同调、类域论等）是天然的候选 [D16]。
- Mathlib 的维护流程 [P49] [P50]；MathlibLemma 有少量合入 Mathlib [P36]。

## 4. 证据等级

主流在用（Tau Ceti 进行中）；对 RH 项目的实际迁移量尚无数字。

## 5. 作用层级

大仓库与生态。需要理解数学，也需要符合目标库的标准。

## 6. 正确性靠什么保证

- 通用库自己的审阅与 CI；项目这边只要最终陈述不变、闸门通过。
- 陈述的定义若来自通用库，要确认库版本变动不改定义（[grh-compact-reliability](../docs/grh-compact-reliability.md) §1 的做法）。

## 7. 效果

| 数字 | 标记 |
|---|---|
| Tau Ceti：41 个新路线图 [z642819551] | 他人报告 |
| 项目本身的缩小：取决于迁出多少，目前没有数字 | — |
| Tau Ceti 的构建规模：约 3.5 万个模块，模型预测约 57 核·时 | 他人报告（[OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build)） |

## 8. 代价与坑

- 慢：通用库的审阅标准高，节奏以周、月计。
- 项目要跟着库的版本走，迁移期间两边都在变。
- 移出的部分仍要被检查，"项目变小"不等于"要信任的东西变少"。

## 9. 什么时候用

在 [C2](c2-statement-generalization.md) 之后（先写成通用陈述）；与 [D2](d2-blueprint-first-reformalization.md) 配合（蓝图决定哪些是背景）。

## 10. 未解决的问题

- RH 所需的背景里，有多少已经在 Mathlib 或 Tau Ceti 里、只是没被接上？

[D16]: ../REFERENCES.md
[P36]: ../REFERENCES.md
[P49]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[z642818201]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642818201
[z642819551]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642819551
