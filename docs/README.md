# 文档

**Summary (English).** Index of the documents in this folder, with a suggested reading order. The documents cover Lean proof cleanup in general; cases indexed by scale and provenance, including the Lean RH development, are in `../cases/`. Each document links its sources directly; [`../REFERENCES.md`](../REFERENCES.md) lists them with numbers, venue, year and how closely we read them. The documents are in Chinese.

| 文档 | 内容 |
|---|---|
| [layered-plan.md](layered-plan.md) | 分层方案：单个定理、单个文件、小仓库、大仓库各自的目标、手段、语义不变的验证（G0–G6 闸门）、自动化程度，以及对中小型研究仓库的判断 |
| [ideas-and-engineering.md](ideas-and-engineering.md) | 14 条优化思路的排序（来源、粒度、收益、正确性保证），以及仓库级的工程流水线：依赖图、去重、import、批处理、增量与分布式构建、守卫、合并顺序、度量 |
| [survey.md](survey.md) | LeanPolish 与同期工作；Lean / Mathlib v4.35 自带的清理与核验工具 |
| [literature.md](literature.md) | 跨系统文献（Lean、Coq/Rocq、Isabelle、HOL、Mizar、Metamath、证明论），按方法与粒度分组 |
| [open-problems.md](open-problems.md) | 待解决问题与建议答案 |

案例不在这个目录：按规模 × 来源索引的案例在 [`../cases/`](../cases/README.md)，其中 [`../cases/rh/`](../cases/rh/README.md) 是大仓库 × 模型生成的大型开发（Lean RH 开发），[`../cases/profiles.md`](../cases/profiles.md) 是七棵公开 Lean 树的结构指标对照。

**阅读顺序。** 想看有哪些路线：[`../methods/README.md`](../methods/README.md)。想直接动手：layered-plan → ideas-and-engineering。想看不同规模与来源的实例：[`../cases/README.md`](../cases/README.md)。想查某个工具或论文：survey、literature。

**写法约定。** 数字都注明出处；"本仓库测"指 [`../scripts/`](../scripts/) 里的脚本算出、[`../data/`](../data/) 里有结果的；"据报告"指论文、PR 或 Zulip 上的说法，没有独立复核；"估计"是我们的推算。对 Lean RH 开发，只说它陈述了 RH 与 Dirichlet GRH、第三方报告机器核验通过、数学尚无人审阅。
