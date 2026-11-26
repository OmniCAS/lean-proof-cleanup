# B3 逐个定理的 LLM 改写（per-theorem LLM rewriting）

## 1. 一句话判断

论文里在竞赛题上缩短 50%–87%，在研究仓库上约 20%，在人写库上几乎为零；它改的是单个证明，碰不到命题个数这个真正的大头，按每条定理美元量级的成本只适合热点。

## 2. 做什么

- 以单个定理为单位，让模型在陈述不变的前提下重写证明体，按长度、编译时间或可读性等指标选优；编译失败就带报错再试。
- 变体：冻结模型加检索策略库（Lean Refactor）、训练小模型（ProofOptimizer、ImProver 2）、以已验证编辑为监督（LeanPolish 的神经部分）、按片段抽辅助声明（Proof-Refactor）。

## 3. 谁在用

- 论文与工具：ImProver [P8]、ProofOptimizer [P9]、ImProver 2 [P10]、Lean Refactor [P11]、LeanPolish [P12]、Proof-Refactor [P28]、Lean Refactor Arena 的参赛报告 [P14]。
- 社区 `alpoge` 线：大量 PR 由智能体生成（分支名带 `codex/` 的如 [#438]），由维护者的智能体批处理合并（[E1](e1-batch-merge-and-agents.md)）。

## 4. 证据等级

有论文或工具；在 RH 上是主流在用，但贡献分散在批次里，没有单独的效果统计。

## 5. 作用层级

定理。改写者需要读懂局部证明，不需要理解全局结构。

## 6. 正确性靠什么保证

- 编译 + 陈述不变 + 公理不增；对 LLM 产出，comparator 或 `lake check` 是唯一可靠的闸门。
- 论文里的评测都是逐个证明独立编译，不涉及跨文件依赖。

## 7. 效果

| 数字 | 标记 |
|---|---|
| ProofOptimizer：miniF2F −87%，PutnamBench −57%；约 2/3 的证明编译快至少 10% [P9] | 他人报告 |
| Lean Refactor：竞赛题 token >70%，研究仓库 >20%，编译时间最多 −60% [P11] | 他人报告 |
| ImProver 2：Mathlib 上长度几乎不降（改进 0.016） [P10] | 他人报告 |
| LeanPolish 编辑对微调后，DeepSeek-Prover 单样本缩短 58% 的 miniF2F 证明（原 12%），省 8.6% token（原 3.4%） [P12] | 他人报告 |
| 比赛参赛报告：每题约 2.8 美元 [P14] | 他人报告 |

## 8. 代价与坑

- 成本：按每条定理约 3 美元算，RH 原始版本的 81.9 万个定理要两百多万美元（估计）。
- 指标容易被刷：token 数可以靠长行、删注释、换成更重的自动化压下来（[E3](e3-metrics.md)）。
- 模型写的文档与引用会出错：社区因此暂停了文档类 PR [z643418033] [z643424144]。

## 9. 什么时候用

A 层与 [B1](b1-library-replacement.md)、[B2](b2-tactic-golf-and-automation.md) 之后，只对剩下的长而慢的证明；需要结构性缩小时改用 C 层。

## 10. 未解决的问题

- 逐个定理改写的收益能否叠加成仓库级的缩小？现有评测都在单文件上。

[#438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P14]: ../REFERENCES.md
[P28]: ../REFERENCES.md
[z643418033]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643418033
[z643424144]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643424144
