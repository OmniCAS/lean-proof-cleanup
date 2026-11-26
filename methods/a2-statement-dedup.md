# A2 同陈述去重（statement deduplication）

## 1. 一句话判断

只合并内核判定类型完全相同的声明，机械、安全，还能顺带截断被删副本的整片依赖锥；收益由来源决定：维护者精心维护的库靠评审挡住重复，几乎没有完全相同的副本；人写研究仓库里的重复主要是"通用库早有"，归 [B1](b1-library-replacement.md)；模型生成的大型开发会在不同分支里各自重新证明同一个命题，副本可能成批出现（目前只有一个这样的实测）。近似重复要靠 [C2](c2-statement-generalization.md) 那种理解后的通用化。

## 2. 做什么

- 按规范化的类型（宇宙参数、绑定变量名统一）给定理分组，定义再加上值；每组只留一份，其余删掉或改成 `alias`，引用改指保留的那份。
- 代表的选择：通用库（Mathlib/Core）已有的优先，其次是 import 顺序里最早、被引用最多的那份。
- 去重后重算闭包（[A1](a1-reachability-pruning.md)）：被去掉的副本往往拖着自己的整条依赖链。
- 近似重复（只差绑定显式性、差一个可推出的假设）不自动合并，列清单交给人或 [C2](c2-statement-generalization.md)。
- 不按名字找重复：同一个短名在不同命名空间里本来就可以指不同的东西。

## 3. 谁在用

- Lean 与 Mathlib：没有现成的整库去重工具，要自写按类型建索引的脚本（[survey](../docs/survey.md) §3.6）；Mathlib 合并或改名时留带 `since` 的 deprecation 别名 [P50]。
- 其他系统与论文：HOL 系库之间的概念对齐 [P31]、MMT 的理论态射搜索 [P32]、Coq/ACL2 的证明模式聚类 [P33]、Isabelle 的相似声明检索 [P34]、Rocq 的目标克隆检测 [P35]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#295]（James Shore，同陈述的定理、同类型同值的定义只留一份）、[#74]（同名重复）、#1595（重复定义，提议）[z643396699]；Tanner Clary 在 MIT 导出上做可达性加 `Prop` 去重 [z642652193]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 有论文或工具：跨系统的相似检索、克隆检测与概念对齐（多数只读了摘要）。
- 主流在用：只在 RH 案例里（#295 已合并）。
- 作者自述：RH 案例里的规模估计（导出上的统计）与构建、核验结果。

## 5. 作用层级

单个文件到大仓库。小仓库可以整库一次分组、一次重编；大仓库要按类型哈希分组后分批改引用。不需要理解数学。

## 6. 正确性靠什么保证

- 只合并内核判定类型相等的声明（例：Lean RH 开发里 #295 要求新旧两个工具链都判定相等才合并）。
- 被删副本的引用全部改指保留版本，再重编；陈述文件不在可改范围内。
- 发布前用 comparator 对照冻结的 Challenge 导出（[E2](e2-verification-gate.md)）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | 重复短名占不同短名 13.3%，与 RH 原始版本（13.0%）几乎相同：库按命名空间复用短名，这个指标不代表重复（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 重复短名 1.7%–5.8%；完全相同陈述的比例没有测（[profiles](../cases/profiles.md)） | 本仓库测 |
| 其他规模与来源 | 完全相同陈述的比例没有公开数字 | — |
| 大仓库 × 模型生成（RH） | #295：约 1.65 万~1.7 万处删除；作者自述完整构建 + nanoda + con-leche 通过 [z642796623] [z643005632] | 他人报告 |
| 大仓库 × 模型生成（RH） | 导出上约 24.1 万个定理与先前定理类型相同，其中约 6.6 万个已在 Mathlib/Core；可达性加去重后导出缩小约 20%，`con-ron --compare` 仍通过 [z642652193] | 他人报告 |
| 大仓库 × 模型生成（RH） | 原始版本：与另一个被用定理陈述相同的定理最多再省 606,362 行（5.6%） [D8] | 他人报告 |
| 大仓库 × 模型生成（RH） | #92：用已有同类型定理替换一处证明，112 个模块随之不可达 [#92] | 他人报告 |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 只差绑定显式性的"重复"不能直接合并；加载顺序不同时会选出不同代表（例：Lean RH 开发里的讨论 [z642698586]）。
- 保留的那份若只能经 private import 看到，替换会破坏可见性（例：Lean RH 开发里 #295 因此保留了 686 个完整副本）。
- 引用改写会新增 import；要确认闭包没有因此变大。
- 在维护的库里，同型的两个名字可能是有意的别名或 deprecation 过渡期，不能当重复删。

## 9. 什么时候用

- 紧跟 [A1](a1-reachability-pruning.md)，之后接 [B1](b1-library-replacement.md)（对通用库去重），再回到 A1。
- 按来源：模型生成的大型开发先做仓库内去重；人写研究仓库直接做 B1；维护的库不需要单独做。

## 10. 未解决的问题

- 模定义展开或模假设顺序的"近似重复"有多少？没人量过；跨系统的相似检索、克隆检测 [P34] [P35] 能否移植到 Lean？
- 不同来源的仓库里，完全相同陈述的比例各是多少？需要按类型哈希实测，短名统计代替不了。
- （RH 案例）约 6.6 万个已在 Mathlib/Core 中的定理，替换后能截断多少依赖锥？

[#74]: https://github.com/leanprover-community/riemann-hypothesis/pull/74
[#92]: https://github.com/leanprover-community/riemann-hypothesis/pull/92
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[D8]: ../REFERENCES.md
[P31]: ../REFERENCES.md
[P32]: ../REFERENCES.md
[P33]: ../REFERENCES.md
[P34]: ../REFERENCES.md
[P35]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
[z642698586]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642698586
[z642796623]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642796623
[z643005632]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643005632
[z643396699]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643396699
