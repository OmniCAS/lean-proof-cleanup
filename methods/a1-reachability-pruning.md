# A1 可达性裁剪（reachability pruning）

## 1. 一句话判断

最便宜、最安全、最先做的一步，但上限是死代码本身的比例：在 Lean RH 原始版本上只有约四分之一的声明没被用到，单靠它缩不到两倍以内之外。

## 2. 做什么

- 以最终定理（comparator 的 `theorem_names`）和保留清单为根，沿依赖求闭包，删掉闭包之外的东西。
- 两张图分两步：先在 import 图上删整个不可达模块，再在内核证明项的常量依赖图上删未用声明。
- 删完重编；编译失败的声明（实例、simp 引理、notation 等不出现在证明项里却是编译所需的）放回保留清单。
- 每轮去重、换库之后重算闭包，因为它们会制造新的不可达部分。

## 3. 谁在用

- 社区 `alpoge` 线：[#45]（先收窄顶层导入，再删不可达子树）、[#66]（升 4.36 时删不可达文件）、[#55]（按内核依赖删声明，后来大部分被 #66/#134 覆盖）。
- James Shore 的依赖闭包数据集 [D8] 和机械裁剪的 S1 阶段 [D9]。
- 新 `main`（可读版）上重新开始：Anton Mellit 数出约 2.3 万个声明里有 1,151 个未用 [z643723346]，剪枝 PR 如 [#5652]。
- 其他系统：Isabelle `unused_thms`，Coq/Mizar 的依赖抽取 [P37]；Lean 只有单文件的 Batteries `#show_unused` [T8]。

## 4. 证据等级

主流在用。闭包数字有公开数据集；删后的构建与核验多为作者自报。

## 5. 作用层级

文件到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 删除不可能让陈述变化，只可能让编译失败，所以"重编通过 + 陈述文件未改"就够了；发布前再跑一次 comparator。
- 闭包必须来自内核证明项或 `.olean`，不能靠文本匹配：issue #3 的文本估计先说可删 45%，构建失败后改成约 9% [C2]。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 原始版本：1,061,400 个项目声明中 804,912 个被用到（75.8%）；被用声明内部 10,737,728 行，占 61.8% [D8] | 他人报告 |
| Shore S1：文件 164,463 → 150,632，行 16,588,671 → 14,473,033，声明 1,024,669 → 858,404 [D9] | 他人报告（作者自报，含 nanoda 与 con-leche 比对） |
| #55：作者称构建时间 −18%、CPU −19%、峰值内存 −41% [#55] | 他人报告 |
| #45 删 11,163 个文件、832,333 行；#66 删 15,068 个文件 | 他人报告 |
| `alpoge` 线上还剩约 1.5 万个未用声明 [z643026403] | 他人报告（估计） |
| 可读版：约 2.3 万个声明中 1,151 个未用（约 5%） [z643723346] | 他人报告 |

## 8. 代价与坑

- 可达不等于必需：通过构造子字段引用的代码会被保留，要另做字段活性分析（[E5](e5-dependency-analysis.md)）。
- 证明项里看不到的编译依赖（实例、simp、ext、notation、`deriving`）需要重编确认，大仓库上这一步最贵。
- 删除产生大量 import 改动，和并行的其他清理冲突最多。

## 9. 什么时候用

- 第一步，紧跟在冻结裁判（[E2](e2-verification-gate.md)）之后。
- 之后接 [A2](a2-statement-dedup.md)、[B1](b1-library-replacement.md)，每轮结束再回到 A1。
- 导入收窄（[A4](a4-import-narrowing.md)）放在它后面：先删内容，导入才会真正多余。

## 10. 未解决的问题

- 当前 `alpoge` 线与新 `main` 的完整闭包（声明、文件、行）没人量过。
- Lean 没有仓库级的未用声明工具；需要一个能区分"证明项依赖"和"编译依赖"的实现。

[#45]: https://github.com/leanprover-community/riemann-hypothesis/pull/45
[#55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[#66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[#5652]: https://github.com/leanprover-community/riemann-hypothesis/pull/5652
[C2]: ../REFERENCES.md
[D8]: ../REFERENCES.md
[D9]: ../REFERENCES.md
[P37]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[z643026403]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643026403
[z643723346]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643723346
