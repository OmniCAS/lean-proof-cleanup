# A2 同陈述去重（statement deduplication）

## 1. 一句话判断

机械路线里收益第二大的一步，而且能截断整片依赖锥；但只处理"陈述完全相同"的一类，近似重复要靠 [C2](c2-statement-generalization.md) 那种理解后的通用化。

## 2. 做什么

- 按规范化的类型（宇宙参数、绑定变量名统一）给定理分组，定义再加上值；每组只留一份，其余删掉或改成 `alias`，引用改指保留的那份。
- 代表的选择：Mathlib/Core 已有的优先，其次是 import 顺序里最早、被引用最多的那份。
- 去重后重算闭包（[A1](a1-reachability-pruning.md)）：被去掉的副本往往拖着自己的整条依赖链。

## 3. 谁在用

- 社区 `alpoge` 线：[#295]（James Shore，同陈述的定理、同类型同值的定义只留一份）、[#74]（同名重复）、#1595（重复定义，提议）[z643396699]。
- Tanner Clary 在 Sutherland 的导出上做可达性加 `Prop` 去重 [z642652193]。
- 文献：HOL 库之间的概念对齐 [P31]、Isabelle 的相似声明检索 [P34]、Rocq 的目标克隆检测 [P35]。

## 4. 证据等级

主流在用（#295 已合并）；规模估计来自导出上的统计。

## 5. 作用层级

文件到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 只合并内核判定类型相等的声明；#295 要求新旧两个工具链都判定相等才合并。
- 被删副本的引用全部改指保留版本，再重编；陈述文件不在可改范围内。
- 发布前用 comparator 对照冻结的 Challenge 导出。

## 7. 效果

| 数字 | 标记 |
|---|---|
| #295：约 1.65 万~1.7 万处删除；作者自报完整构建 + nanoda + con-leche 通过 [z642796623] [z643005632] | 他人报告 |
| 导出上约 24.1 万个定理与先前定理类型相同，其中约 6.6 万个已在 Mathlib/Core；可达性加去重后导出缩小约 20%，`con-ron --compare` 仍通过 [z642652193] | 他人报告 |
| 原始版本：与另一个被用定理陈述相同的定理最多再省 606,362 行（5.6%） [D8] | 他人报告 |
| 原始版本：同一个短名被定义多次的名字 98,631 个；紧凑版 225 个 | 本仓库测（`data/versions_summary.json`） |
| #92：用已有同类型定理替换一处证明，112 个模块随之不可达 [#92] | 他人报告 |

## 8. 代价与坑

- 只差绑定显式性的"重复"不能直接合并；加载顺序不同时会选出不同代表 [z642698586]。
- 保留的那份若只能经 private import 看到，替换会破坏可见性；#295 因此保留了 686 个完整副本。
- 引用改写会新增 import；要确认闭包没有因此变大。

## 9. 什么时候用

紧跟 [A1](a1-reachability-pruning.md)，之后接 [B1](b1-library-replacement.md)（对 Mathlib 去重），再回到 A1。

## 10. 未解决的问题

- 模定义展开或模假设顺序的"近似重复"有多少？没人量过。
- 6.6 万个 Mathlib 已有的定理，替换后能截断多少依赖锥？

[#74]: https://github.com/leanprover-community/riemann-hypothesis/pull/74
[#92]: https://github.com/leanprover-community/riemann-hypothesis/pull/92
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[D8]: ../REFERENCES.md
[P31]: ../REFERENCES.md
[P34]: ../REFERENCES.md
[P35]: ../REFERENCES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
[z642698586]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642698586
[z642796623]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642796623
[z643005632]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643005632
[z643396699]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643396699
