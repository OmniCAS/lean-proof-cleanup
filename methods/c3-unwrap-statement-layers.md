# C3 去掉陈述包装层（unwrap statement layers）

## 1. 一句话判断

包装层（给陈述起名字的 `Prop` 定义、只转述别处定理的别名与包装文件、层层传递的假设包）是模型生成的大型开发最显眼的冗余；人写研究仓库和维护者精心维护的库里都很少，后者把别名只当作带日期的过渡。薄包装和别名可以机械删（[A5](a5-module-regrouping.md)），内联命名陈述、拆假设包要理解后才能做。从单个定理（去掉没用的假设）到大仓库都适用，但只有在包装层成片出现时才值得专门做。

## 2. 做什么

- 把 `def X : Prop := ...` 这类命名陈述内联到用它的地方，删掉只为它存在的转换引理。
- 删别名定理和"换个名字再证一遍"的包装文件；公开接口上的别名先弃用、过期再删。
- 把一串假设包成的结构拆开，只传真正用到的字段；删掉从未用到的假设。
- 删掉从未被证明、也从未被使用的文献陈述。

## 3. 谁在用

- Lean 与 Mathlib：环境 linter `unusedArguments` 报告没用到的参数（`#lint` / `lake lint`） [T8]；Mathlib 的别名只作为带日期的弃用过渡，过期后由定时工作流删除 [P50]（见 [curated-library-mathlib](../cases/curated-library-mathlib.md)）。
- 其他系统：Isabelle 的 `find_unused_assms` 逐个去掉前提跑 Quickcheck，标出可能多余的假设 [T16]；Mizar 的 irrelevant utilities 找多余的前提与步骤 [P6] [P7]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#318]（David Loeffler：删 `GlobalTheory.Published` 里从未证明也未使用的文献陈述，如 `LocalLanglandsExists`；完整的局部 Langlands 陈述被约 6,000 个文件导入） [z643015203] [z642804360]，[#324] 删了 22,054 个薄包装模块；Michael Righi 的字段活性分析找出从未用到的结构字段（`alpoge` 线 RH#151，新 `main` [#5642]）；grh-lean 两个短版本里命名 `Prop` 定义几乎完全消失（§7）。

## 4. 证据等级

- **主流在用**：删未用假设与参数（linter、`find_unused_assms`）、别名的弃用流程；RH 社区删薄包装与未用文献陈述的 PR。
- **推测**：内联命名陈述。只在 RH 案例的短版本里看到包装层消失（§7 本仓库测），作者是否有意为之不知道；没有论文或工具专门做这一步。

## 5. 作用层级

单个定理（删没用的假设）到大仓库。删薄包装和别名不需要理解数学；拆假设包和内联命名陈述需要。

## 6. 正确性靠什么保证

- 最终陈述的定义文件不在可改范围内；其余包装层的改动由重编和 comparator 保证（[E2](e2-verification-gate.md)）。
- 删"未使用的文献陈述"之前要确认它确实不在闭包里（[A1](a1-reachability-pruning.md)、[E5](e5-dependency-analysis.md)）。
- 找多余假设的工具多是启发式（`find_unused_assms` 靠反例搜索），删后仍要重编确认 [T16]。
- （例：Lean RH 开发里陈述文件冻结，CI 拒绝任何改 challenge 文件的 PR [C3]。）

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个文件 × 模型生成的证明（3 千行） | 定义 42 → 3（只剩标题陈述用到的三个）：标号、嵌入、证书结构体等具名数据层在换成函数层面的归纳后全部消失；这发生在换论证的阶段，不是单独的去包装步骤。[small-ramsey](../experiments/small-ramsey/README.md) | 本仓库测 |
| 库 × Mathlib | 命名 `Prop` 定义每千行代码 0.8 个（[profiles](../cases/profiles.md) 的宽口径） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PrimeNumberTheoremAnd [D19]–[D21]） | 每千行 0.3–0.6 个 | 本仓库测 |
| 大仓库 × 模型生成（RH） | 每千行 6.0 个（宽口径）；按精确形式 `def X : Prop :=` 数：原始 65,318 个，可读版 274 个，紧凑版 4 个 | 本仓库测（[grh-compact-vs-original](../cases/rh/grh-compact-vs-original.md)） |
| 大仓库 × 模型生成（RH） | 原始版本文件名含 `Statement` 的文件：48,367 个（28%） | 本仓库测 |
| 大仓库 × 模型生成（RH） | #318：1,370 个声明 [z643015203]；#324：22,054 个薄包装模块 | 他人报告 |
| 大仓库 × 模型生成（RH） | 删掉从未用到的假设：原始版本最多省 0.1%（连同未用的 `let`/`have` 值 0.3%） [D8] | 他人报告 |
| 其他规模与来源（删包装层的效果） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。即使在这一格里，未用假设也只占 0.1%，大头在命名陈述与包装文件。

## 8. 代价与坑

- 命名陈述承担了"接口"作用，内联后调用点的类型会变长，需要同时做 [C2](c2-statement-generalization.md)。
- 不是所有命名 `Prop` 都是冗余：给重要猜想或常用性质起名是正常做法（Mathlib 每千行也有约 0.8 个），只删只为一处服务的。
- 文献陈述可能被文档或网站引用，删前先查保留清单。
- 删未用假设的收益通常很小（例：Lean RH 开发的原始版本里最多 0.1% [D8]）。

## 9. 什么时候用

机械部分（薄包装、别名、未用文献陈述）在 A 层里做；需要理解的部分与 [C1](c1-unroll-simplify-reroll.md)、[C2](c2-statement-generalization.md) 一起做。动手前先看命名 `Prop` 的密度和只转述别处定理的文件数（[profiles](../cases/profiles.md)）：接近人写仓库与 Mathlib 的水平，就不必专门做。

## 10. 未解决的问题

- 命名 `Prop` 中有多少可以机械内联而不需要理解？任何来源上都没人量过。
- Lean 能否有一个 `find_unused_assms` 式的工具：逐个去掉前提，重编或做反例搜索，列出多余假设？
- （RH 案例）原始版本的 65,318 个命名 `Prop` 里，有多少能机械内联？

[#318]: https://github.com/leanprover-community/riemann-hypothesis/pull/318
[#324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[C3]: ../REFERENCES.md
[D8]: ../REFERENCES.md
[D19]: ../REFERENCES.md
[D21]: ../REFERENCES.md
[P6]: ../REFERENCES.md
[P7]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[T16]: ../REFERENCES.md
[z642804360]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642804360
[z643015203]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643015203
