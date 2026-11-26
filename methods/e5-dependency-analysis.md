# E5 依赖分析（dependency analysis）

## 1. 一句话判断

先量再删：依赖闭包给出机械路线的下限，支配树给出"哪一块是承重的"，字段活性补上可达性看不到的死代码；文本匹配会严重高估可删量，必须从内核证明项或 `.olean` 算。根怎么选取决于来源：以几个最终定理为目标的仓库（人写研究仓库、模型生成的开发）从这些定理出发，闭包之外都是候选；维护者精心维护的库的根是全部公开接口，不被引用的叶子是接口，不是死代码。单个文件有现成工具，仓库级的声明闭包在 Lean 上要自建。

## 2. 做什么

- 依赖闭包：从最终定理出发，沿内核证明项的常量引用求闭包，按声明、文件、行统计。
- 支配树：一个声明 D 属于 X，当且仅当从最终定理到 D 的每条依赖链都经过 X；用来找"删掉 X 就能删掉的整片"。
- 字段活性：结构的哪些字段从未被读取（可达性分析会因构造子引用而保留它们）。
- 导入图统计：模块数、边数、层数、最宽一层，用来判断并行度与重组方向。
- 编译依赖另算：实例、simp 集合、notation 不在证明项里，要靠删后重编确认。

## 3. 谁在用

- Lean 工具：Batteries 的 `#show_unused`、`#print dependents`（单文件） [T8]；`lake shake --explain` 列出每个导入贡献了哪些常量 [T1]；import-graph 的 `lake exe graph`、`unused_transitive_imports` [T9]。Lean 核心与 Mathlib 都没有仓库级的未用声明工具。
- 其他系统：Isabelle `unused_thms` 列出给定理论范围内没被用到的定理 [T16]；Coq/Mizar 的依赖抽取 [P37]；Mathlib 的网络结构分析（44.8% 的定理是叶子，即对外的接口，不等于死代码） [P38]。
- 基准：LeanLean 报告仓库级压缩的大头来自让原本用到的声明变得不再需要 [P30]，这正是闭包与支配树要找的东西。
- 大仓库示例（Lean RH 开发，模型生成）：James Shore 的 `rh-proof-dependencies`（CC0 数据集）从 Sutherland 的内核导出算出，三套独立构建得到同一闭包 [D8]；Bin 的 riemann-explorer 沿支配树切分 `riemannHypothesis` 的依赖图 [D12] [z643337613]；Michael Righi 的字段活性分析（`alpoge` 线与新 `main` 的 [#5642]） [z642699511]；Anton Mellit 在可读版上数未用声明 [z643723346]。

## 4. 证据等级

- **主流在用**：单文件与导入层面的工具 [T1] [T8] [T9]，其他系统的未用定理工具 [T16]。
- **有论文或工具**：依赖抽取 [P37]、库的网络结构 [P38]；Lean 上仓库级的声明闭包只有 RH 案例的公开数据集 [D8]，其他分析多为作者自报。

## 5. 作用层级

单个文件（现成工具）到大仓库（自建）。不需要理解数学，但解读支配树需要。

## 6. 正确性靠什么保证

分析本身不改代码；删除时的正确性见 [A1](a1-reachability-pruning.md)。数据集的可信度来自独立构建的一致性（例：Lean RH 开发的闭包数据集由三套独立构建复现 [D8]）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | 44.8% 的定理不被任何声明引用（叶子是接口，不是死代码） [P38] | 他人报告 |
| 大仓库 × 模型生成（RH） | 原始版本：1,484,729 个内核常量被五个定理用到，其中项目 1,270,184、Mathlib 204,488（Mathlib 的 35.9%） [D8] | 他人报告 |
| 大仓库 × 模型生成（RH） | 项目声明 804,912 / 1,061,400 被用；五个定理几乎共享一切，每一个单独就用了其中至少 804,889 个 [D8] | 他人报告 |
| 大仓库 × 模型生成（RH） | riemann-explorer：提交 `6c68212` 上 `riemannHypothesis` 的依赖图有 727,065 个声明（是否含 Mathlib 未说明） [z643337613] | 他人报告 |
| 大仓库 × 模型生成（RH） | 文本追踪的高估：issue #3 先估可删约 45%，构建失败后改为约 9% [C2] | 他人报告 |
| 大仓库 × 模型生成（RH） | 导入图：原始 175,187 个模块、753,261 条内部边、203 层、最宽一层 5,927；紧凑版 794、1,398、55、32 | 本仓库测 |
| 其他规模与来源（人写研究仓库的依赖闭包） | 没有公开数字（[profiles](../cases/profiles.md) 只有源码层面的指标） | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 导出很大，算闭包要大内存（例：Lean RH 开发的原始导出 61.6 GB）。
- 闭包只覆盖证明项里的依赖；编译依赖（实例、simp 集合、notation）要另外确认。
- 支配树的结果依赖根的选取；换根就要重算。
- 对库不能套用"闭包之外即死代码"：叶子是给下游的接口 [P38]。

## 9. 什么时候用

清理开始之前与每个大阶段之后；结果交给 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 和 [C1](c1-unroll-simplify-reroll.md)（找可以整体换掉的子论证）。对以最终定理为目标的仓库最有用；对库只用来找内部重复，不用来删叶子。

## 10. 未解决的问题

- Lean 是否该有仓库级的未用声明工具（像 Isabelle 的 `unused_thms`），并把编译依赖也算进去？
- 支配树能否自动提示"整体换掉一块"的候选（[D1](d1-argument-replacement.md)）？
- 人写研究仓库里闭包之外的声明占多少？没有公开测量。
- （RH 案例）`alpoge` 线当前版本与新 `main` 的闭包都没人公开量过。

[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[C2]: ../REFERENCES.md
[D8]: ../REFERENCES.md
[D12]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P37]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[T9]: ../REFERENCES.md
[T16]: ../REFERENCES.md
[z642699511]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699511
[z643337613]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Explorer.20for.20the.20formalization/near/643337613
[z643723346]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643723346
