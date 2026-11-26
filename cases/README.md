# 案例

**Summary (English).** Cases of Lean proof cleanup indexed by scale (single theorem, file, small repository, large repository) and provenance (curated library, human-written research repository, model-generated proofs, large model-generated development). Each case is evidence for its own cell; the Lean RH development is the large-repository, model-generated case, not the general rule. The text is in Chinese.

## 规模 × 来源

| 规模 \ 来源 | 精心维护的库（Mathlib） | 人写的研究仓库 | 模型生成的证明 | 模型生成的大型开发 |
|---|---|---|---|---|
| 单个定理 | [Mathlib](curated-library-mathlib.md)：缩短工具几乎无收益（LeanPolish 0.53%） | 少量公开数字（Lean Refactor 的研究仓库） | [竞赛证明](theorem-scale-generated-proofs.md)：符号 pass 约 20%，学习改写 50%–87% | [RH](rh/README.md)：原始版本每个定理 16.7 行，与人写研究仓库相近 |
| 单个文件 | [Mathlib](curated-library-mathlib.md)：linter、`longFile`、拆文件 | — | — | [RH](rh/README.md)：45% 的文件只有一个声明 |
| 小仓库 | — | [仓库级基准](repository-benchmarks.md)：Lean Refactor >20%；LeanLean 64 个仓库平均 48%（来源混合） | [Leanify](repository-benchmarks.md)：证明集合按证明项压缩 94%–99% | [RH 的两个短版本](rh/grh-compact-vs-original.md)：重写后 7,088 / 18,227 个定理 |
| 大仓库 | [Mathlib](curated-library-mathlib.md)：持续维护的流程 | — | — | [RH](rh/README.md)：逐步清理 −23%，重写缩小两个数量级 |

空格表示没有找到公开证据。各格共同的结构指标见 [profiles](profiles.md)。

上表是别人的工作与公开数字。我们自己在别的公开仓库上做的分阶段实验（“模型生成的证明”一列的单文件对象，3 千到 3.4 万行；“模型生成的大型开发”一列的数十万行仓库）单独放在 [`../experiments/`](../experiments/README.md)，每格是我们自己量的。

## 文件

| 文件 | 格 |
|---|---|
| [profiles.md](profiles.md) | 七棵公开 Lean 树的结构指标并排对照（Mathlib、三个人写研究仓库、RH 原始与两个短版本） |
| [theorem-scale-generated-proofs.md](theorem-scale-generated-proofs.md) | 单个定理 × 模型生成的证明 |
| [curated-library-mathlib.md](curated-library-mathlib.md) | 各规模 × 精心维护的库 |
| [repository-benchmarks.md](repository-benchmarks.md) | 小仓库与中型仓库 × 仓库级基准 |
| [rh/](rh/README.md) | 大仓库 × 模型生成的大型开发（Lean RH 开发） |

## 关于 RH 的说法

这些 Lean 开发陈述了 Mathlib 的 `RiemannHypothesis` 与 Dirichlet L 函数的 GRH 形式，第三方报告机器核验通过，数学部分尚无人审阅。
