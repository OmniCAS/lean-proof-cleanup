# A1 可达性裁剪（reachability pruning）

## 1. 一句话判断

最便宜、最安全、最先做的一步，收益几乎全由来源决定：维护者精心维护的库里"没被引用"的定理是 API，不是死代码，裁剪无从谈起；人写的研究仓库里只有零散残留；模型生成的大型开发里死代码可能成片出现。上限就是死代码本身的比例，但去重、换库引理、重组依赖每做一轮都会制造新的不可达部分，所以它也是把这些重构的收益兑现成删除的那一步。

## 2. 做什么

- 从保留根出发沿依赖求闭包，删掉闭包之外的东西。保留根：最终定理（comparator 配置里的 `theorem_names` 与 `definition_names`）、对外 API、文档或论文引用的声明。
- 两张图分两步：先在 import 图上删整个不可达模块（便宜），再在内核证明项的常量依赖图上删未用声明。
- 删完重编；编译失败的声明（实例、simp/ext 引理、notation、macro、`deriving` 生成物这类不出现在证明项里却是编译所需的）放回保留清单。
- 每轮去重（[A2](a2-statement-dedup.md)）、换库引理（[B1](b1-library-replacement.md)）之后重算闭包。
- 在库里，根是全部公开声明：要去掉的声明先留带日期的 deprecation 别名，过期再删，而不是按闭包直接删。

## 3. 谁在用

- Lean 与 Mathlib：只有单文件的 Batteries `#show_unused` [T8]，没有仓库级的未用声明工具；Mathlib 删改公开声明时留带 `since` 的 deprecation 别名，过期（约 6 个月）的由 CI 定时清理 [P50]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 研究：Mathlib 网络结构的分析发现 44.8% 的定理不被任何声明引用，它们是库的叶子（API），不是死代码 [P38]；LeanLean 的仓库级基准里，智能体的收益大头来自"让原本用到的声明变得不再需要" [P30]，裁剪是兑现这部分收益的最后一步。
- 其他系统：Isabelle 的 `unused_thms` 列出给定理论范围内没被用到的定理 [T16]；Coq 与 Mizar 有依赖抽取 [P37]；Mizar 的 MML 由核心团队定期修订、去冗余 [P48]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#45]（先收窄顶层导入，再删不可达子树）、[#66]（升 4.36 时删不可达文件）、[#55]（按内核依赖删声明，后来大部分被 #66/#134 覆盖）；James Shore 的依赖闭包数据集 [D8] 和机械裁剪的 S1 阶段 [D9]；新 `main`（可读版）上 Anton Mellit 数出约 2.3 万个声明里有 1,151 个未用 [z643723346]，剪枝 PR 如 [#5652]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Isabelle、Mizar 的整库命令与定期修订，Mathlib 的 deprecation 流程。
- 有论文或工具：依赖抽取 [P37]、Mathlib 网络结构 [P38]、LeanLean [P30]（在审，只读摘要）；Lean 的仓库级闭包只有 RH 案例里的自建脚本和公开数据集 [D8]。
- 作者自述：RH 案例里删后的构建与核验结果。

## 5. 作用层级

单个文件到大仓库；单个定理内部的未用 `have` 归 [A3](a3-linter-driven-cleanup.md)。小仓库每批全量重编就能确认；大仓库上，确认"证明项之外的编译依赖"的那次重编最贵。不需要理解数学。

## 6. 正确性靠什么保证

- 删除不可能让陈述变化，只可能让编译失败，所以"重编通过 + 陈述文件未改"就够了；发布前再跑一次 comparator（[E2](e2-verification-gate.md)）。
- 闭包必须来自内核证明项或 `.olean`，不能靠文本匹配（例：Lean RH 开发里 issue #3 的文本估计先说可删 45%，构建失败后改成约 9% [C2]）。
- 保留根写成清单、进版本控制；否则文档、网站引用的声明会被当成死代码删掉。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | 44.8% 的定理不被任何声明引用，但它们是 API，不是可删的死代码 [P38] | 他人报告 |
| 仓库 × LeanLean 的 64 个真实仓库 | 最强模型平均压缩分 48.3%，大头来自让声明变得不再需要；单独的裁剪没有拆开报告 [P30] | 他人报告 |
| 仓库 × 人写研究仓库 | 没有公开数字（闭包要从构建产物算，[profiles](../cases/profiles.md) 里没有） | — |
| 大仓库 × 模型生成（RH） | 原始版本 1,061,400 个项目声明中 804,912 个被用到（75.8%）；被用声明内部 10,737,728 行，占 61.8% [D8] | 他人报告 |
| 大仓库 × 模型生成（RH） | Shore S1：文件 164,463 → 150,632，行 16,588,671 → 14,473,033，声明 1,024,669 → 858,404 [D9] | 他人报告（作者自述，含 nanoda 与 con-leche 比对） |
| 大仓库 × 模型生成（RH） | #55：作者称构建时间 −18%、CPU −19%、峰值内存 −41% [#55] | 他人报告 |
| 大仓库 × 模型生成（RH） | #45 删 11,163 个文件、832,333 行；#66 删 15,068 个文件 | 他人报告 |
| 大仓库 × 模型生成（RH） | `alpoge` 线上还剩约 1.5 万个未用声明 [z643026403] | 他人报告（估计） |
| 大仓库 × 模型生成（RH 重写后的可读版） | 约 2.3 万个声明中 1,151 个未用（约 5%） [z643723346] | 他人报告 |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 可达不等于必需：通过结构字段引用的代码会被保留，要另做字段活性分析（[E5](e5-dependency-analysis.md)）。
- 证明项里看不到的编译依赖（实例、simp、ext、notation、`deriving`）只能靠重编确认，仓库越大这一步越贵。
- 在库里"不被引用"是常态：按闭包删会删掉下游要用的 API。
- 删除带来大量 import 改动，和并行的其他清理冲突最多（例：Lean RH 开发里 #55 的大部分被之后的 #66/#134 覆盖）。

## 9. 什么时候用

- 第一步，紧跟在冻结裁判（[E2](e2-verification-gate.md)）之后；之后接 [A2](a2-statement-dedup.md)、[B1](b1-library-replacement.md)，每轮结束再回到 A1。
- 导入收窄（[A4](a4-import-narrowing.md)）放在它后面：先删内容，导入才会真正多余。
- 按来源：模型生成的大型开发最先做、反复做；人写研究仓库在每次发布前跑一次即可；维护的库不按闭包裁剪，走 deprecation。

## 10. 未解决的问题

- Lean 没有仓库级的未用声明工具；需要一个能区分"证明项依赖"和"编译依赖"的实现。
- 人写研究仓库里死代码的典型比例是多少？没有公开数字，要在 [profiles](../cases/profiles.md) 里那几个仓库上从构建产物补测。
- LeanLean 的收益里，多少是重组之后的纯裁剪？摘要没有拆开。
- （RH 案例）当前 `alpoge` 线与新 `main` 的完整闭包（声明、文件、行）没人量过。

[#45]: https://github.com/leanprover-community/riemann-hypothesis/pull/45
[#55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[#66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[#5652]: https://github.com/leanprover-community/riemann-hypothesis/pull/5652
[C2]: ../REFERENCES.md
[D8]: ../REFERENCES.md
[D9]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P37]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[P48]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[T16]: ../REFERENCES.md
[z643026403]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643026403
[z643723346]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643723346
