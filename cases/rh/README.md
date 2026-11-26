# 案例：大仓库 × 模型生成的大型开发（Lean RH 开发）

**Summary (English).** The large-repository, model-generated case: the November 2026 Lean development by Alpöge with Claude (175,187 files, 17.4M lines), the community's step-by-step cleanup (branch `alpoge`), and the two-edition rewrite `lsernau/grh-lean`. The developments state Mathlib's `RiemannHypothesis` and Dirichlet GRH forms and are reported machine-checked by third parties; the mathematics is unreviewed. Its numbers are evidence for this cell of the scale × provenance table only. The text is in Chinese.

这一格的特点：规模大到每批改动不能全量重编；生成过程留下大量机械冗余（未用声明、重复陈述、陈述包装文件、逐步推导的写法）；端到端核验本身就要以天计。

| 文档 | 内容 |
|---|---|
| [rh-community-cleanup.md](rh-community-cleanup.md) | 2026-11-25 的切换与各版本的验证（§0）；逐步清理线（`alpoge`）的历史：各项工作、数字、闭包下限、还能做什么 |
| [grh-compact-vs-original.md](grh-compact-vs-original.md) | 两个短版本与原始代码的对比：命题个数、策略用法、样例、缩小的来源、与原始版本的关系 |
| [grh-compact-reliability.md](grh-compact-reliability.md) | 紧凑版的陈述与信任面审查；MIT 的核验；本机断网构建与 `#print axioms` |

这一格里的结论（详见上面三份）：

1. 机械路线合计的上限约两到三倍：原始版本 24% 的声明未被用到，约 24.1 万个定理重复先前的陈述，48,367 个文件是陈述包装；逐步清理五天做到正文行 −23%。
2. 两个数量级来自在同一个证明骨架上的重写：定理与引理 818,755 → 18,227（可读版）/ 7,088（紧凑版）。
3. 规模决定能否核验：逐步清理线没有端到端核验报告；两个短版本发布当天就被多个独立内核检查完。

和其他格的对照见 [`../README.md`](../README.md) 与 [`../profiles.md`](../profiles.md)。
