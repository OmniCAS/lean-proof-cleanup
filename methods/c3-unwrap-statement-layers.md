# C3 去掉陈述包装层（unwrap statement layers）

## 1. 一句话判断

原始版本最显眼的冗余：数万个"给陈述起名字"的 `Prop` 定义、只转述别处定理的包装文件、层层传递的假设包；它们一部分可以机械删（[A5](a5-module-regrouping.md)），其余要理解后才能拆。

## 2. 做什么

- 把 `def X : Prop := ...` 这类命名陈述内联到用它的地方，删掉只为它存在的 `X_of_...` 转换引理。
- 删别名定理和"换个名字再证一遍"的包装文件。
- 把一串假设包成的结构拆开，只传真正用到的字段；删掉从未用到的假设。
- 删掉从未被证明、也从未被使用的文献陈述。

## 3. 谁在用

- 社区 `alpoge` 线：[#318]（David Loeffler：删 `GlobalTheory.Published` 里从未证明也未使用的文献陈述，如 `LocalLanglandsExists`；完整的局部 Langlands 陈述被约 6,000 个文件导入） [z643015203] [z642804360]；[#324] 删了 22,054 个薄包装模块。
- Michael Righi 的字段活性分析（找出从未用到的结构字段）：`alpoge` 线 RH#151，新 `main` [#5642]。
- grh-lean 两个短版本：命名 `Prop` 定义几乎完全消失（见效果）。
- Isabelle 的 `find_unused_assms`（逐个去掉前提跑 Quickcheck） [T16]。

## 4. 证据等级

- 删薄包装与文献陈述：主流在用。
- 短版本里包装层消失：本仓库测；作者是否有意为之：推测。

## 5. 作用层级

文件到大仓库。删包装不需要理解数学；拆假设包和内联命名陈述需要。

## 6. 正确性靠什么保证

- 最终陈述的定义文件（`Statements.lean`）不在可改范围内；其余包装层的改动由重编和 comparator 保证。
- 删"未使用的文献陈述"之前要确认它确实不在闭包里（[A1](a1-reachability-pruning.md)）。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 命名的 `Prop` 定义：原始 65,318 个，可读版 274 个，紧凑版 4 个 | 本仓库测（[grh-compact-vs-original](../docs/grh-compact-vs-original.md)） |
| 原始版本文件名含 `Statement` 的文件：48,367 个（28%） | 本仓库测 |
| #318：1,370 个声明 [z643015203] | 他人报告 |
| 删掉从未用到的假设：原始版本最多省 0.1%（连同未用的 `let`/`have` 值 0.3%） [D8] | 他人报告 |

## 8. 代价与坑

- 命名陈述在原始版本里承担了"接口"作用，内联后调用点的类型会变长，需要同时做 [C2](c2-statement-generalization.md)。
- 文献陈述可能被文档或网站引用，删前先查保留清单。

## 9. 什么时候用

机械部分（薄包装、未用文献陈述）在 A 层里做；需要理解的部分与 [C1](c1-unroll-simplify-reroll.md)、[C2](c2-statement-generalization.md) 一起做。

## 10. 未解决的问题

- 65,318 个命名 `Prop` 中有多少可以机械内联而不需要理解？没人量过。

[#318]: https://github.com/leanprover-community/riemann-hypothesis/pull/318
[#324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[D8]: ../REFERENCES.md
[T16]: ../REFERENCES.md
[z642804360]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642804360
[z643015203]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643015203
