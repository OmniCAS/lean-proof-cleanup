# B3 逐个定理的 LLM 改写（per-theorem LLM rewriting）

## 1. 一句话判断

收益随来源急剧下降：模型生成的竞赛证明上缩短一半以上，人写研究仓库上约两成，维护者精心维护的库上几乎为零。它只改单个证明，碰不到命题个数和依赖结构；而从现有的一份实测看，模型生成的大型开发里单个证明并不比人写研究仓库更啰嗦，冗余主要在命题个数与组织，所以到了大仓库它不是主力。按每条定理美元量级的成本，只适合符号手段处理不了的热点。

## 2. 做什么

- 以单个定理为单位，让模型在陈述不变的前提下重写证明体，按长度、编译时间或可读性等指标选优；编译失败就带报错再试。
- 变体：冻结模型加检索策略库（Lean Refactor）、训练小模型（ProofOptimizer、ImProver 2）、以已验证编辑为监督（LeanPolish 的神经部分）、按片段抽辅助声明（Proof-Refactor）。
- 只交给它符号手段（[B1](b1-library-replacement.md)、[B2](b2-tactic-golf-and-automation.md)）之后仍然长而慢的证明；每条改写都要人看 diff。

## 3. 谁在用

- 论文与工具：ImProver [P8]、ProofOptimizer [P9]、ImProver 2 [P10]、Lean Refactor [P11]、LeanPolish [P12]、Proof-Refactor [P28]；Lean Refactor Arena 比赛 [D13] 与参赛报告 [P14]。
- 仓库规模的对照：LeanLean 让智能体在 12 小时内压缩真实仓库，收益大头来自依赖重组而不是证明写法 [P30]（见 [仓库级基准](../cases/repository-benchmarks.md)）。
- 其他系统：GPT-f 的 23 个更短的 Metamath 证明被 set.mm 采纳，是 LLM 缩短证明被主库接受的最早案例 [P5]；Isabelle 上的 Baldur 做整证明生成与带报错修复 [P43]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线上大量 PR 由智能体生成（分支名带 `codex/` 的如 [#438]），由维护者的智能体批处理合并（[E1](e1-batch-merge-and-agents.md)）；社区因模型写的文档与引用出错，暂停了文档类 PR [z643418033] [z643424144]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 有论文或工具：上面的论文与比赛（多数只读了摘要）。
- 主流在用：只在 RH 案例里，贡献分散在批次里，没有单独的效果统计。

## 5. 作用层级

单个定理。改写者需要读懂局部证明，不需要理解全局结构。

## 6. 正确性靠什么保证

- 编译 + 陈述不变 + 公理不增；对 LLM 产出，comparator 或 `lake check` 是唯一可靠的闸门（[E2](e2-verification-gate.md)）。
- 论文里的评测都是逐个证明独立编译，不涉及跨文件依赖；整库用时要按下游锥体重编。
- 模型写的注释、文档与引用不在闸门的检查范围内，要人审。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | ProofOptimizer：miniF2F −87%，PutnamBench −57%；约 2/3 的证明编译快至少 10% [P9] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | Lean Refactor：token 压缩 >70% [P11] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | LeanPolish 编辑对微调后，DeepSeek-Prover 单样本缩短 58% 的 miniF2F 证明（原 12%），省 8.6% token（原 3.4%）；对更长的 PutnamBench 证明不再有效 [P12] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | 比赛参赛报告：每题约 2.8 美元 [P14] | 他人报告 |
| 仓库 × 人写研究仓库（Lean Refactor 的研究仓库） | token >20%，编译时间最多 −60% [P11] | 他人报告 |
| 库 × Mathlib | ImProver 2：长度几乎不降（改进约 0.016） [P10] | 他人报告 |
| 仓库 × LeanLean 的 64 个真实仓库 | 最强模型平均压缩分 48.3%，小模型 <25%；大头来自依赖重组，只有最强模型在语法层面有明显收益 [P30] | 他人报告 |
| 库 × Mathlib | 每个定理平均 7.5 行（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 每个定理平均 15.6–17.5 行（[profiles](../cases/profiles.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | 原始版本每个定理平均 16.7 行，与人写研究仓库相近（[profiles](../cases/profiles.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | 没有单独的效果统计；按每条定理约 3 美元算，原始版本的 81.9 万个定理要两百多万美元 | 估计 |

单定理数字的背景见 [单定理 × 生成证明](../cases/theorem-scale-generated-proofs.md)。RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 成本：按每条定理约 3 美元算，几千条定理就是上万美元（估计）。
- 指标容易被刷：token 数可以靠长行、删注释、换成更重的自动化压下来（[E3](e3-metrics.md)）。
- 模型写的文档与引用会出错，闸门查不出来（例：Lean RH 开发的社区因此暂停了文档类 PR [z643418033] [z643424144]）。
- 单定理的大比例缩短不能外推到仓库：竞赛证明的冗余在证明内部，大型开发的冗余在结构里。

## 9. 什么时候用

- A 层与 [B1](b1-library-replacement.md)、[B2](b2-tactic-golf-and-automation.md) 之后，只对剩下的长而慢的证明。
- 需要减少命题个数时改用 C 层或仓库级智能体（LeanLean 那种依赖重组）。
- 按来源：模型生成的竞赛证明收益最大；人写研究仓库只做热点和可读性；维护的库基本不值得。

## 10. 未解决的问题

- 逐个定理改写的收益能否叠加成仓库级的缩小？现有评测都在单文件上。
- 人写研究仓库上的 >20% 是在哪些仓库、按什么口径算的？摘要没有说明。
- 训练出的小模型能否在不同来源之间迁移（竞赛题训练，用在研究仓库上）？没有公开数字。

[#438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[D13]: ../REFERENCES.md
[P5]: ../REFERENCES.md
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P14]: ../REFERENCES.md
[P28]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P43]: ../REFERENCES.md
[z643418033]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643418033
[z643424144]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643424144
