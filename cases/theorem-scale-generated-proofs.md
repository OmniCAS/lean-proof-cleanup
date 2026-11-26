# 案例：单个定理 × 模型生成的证明

**Summary (English).** Theorem-scale cleanup of model-generated proofs, mostly competition problems (miniF2F, PutnamBench, Lean Workbook proofs from Goedel-Prover). This is where the published proof-shortening work lives: symbolic passes save about a fifth of the tokens, trained or agentic rewriters report 50–87%, and the same tools save almost nothing on human-written Mathlib. Every result is per proof, compiled in isolation, with no cross-file effects. The text is in Chinese.

## 判断

模型生成的单个证明里有大量局部冗余：多余的 `have`、绕远的 `rw` 链、可以一步关闭的目标。删除类和替换类的符号 pass 就能拿走约两成，学习或智能体改写能拿走一半以上。这些数字只说明单个证明的写法有多啰嗦，不说明仓库能缩多少：命题个数和依赖结构不在这类方法的范围内。

## 证据（他人报告）

| 工作 | 语料 | 结果 |
|---|---|---|
| LeanPolish [P12] [D2] | Goedel-Prover 生成的 Lean Workbook 证明 | token −20.0% |
| 同上 | miniF2F 已验证证明 | −22.6%（迭代到不动点约 −27.5%）；与 AXLE 叠加 −35.9% |
| 同上 | PutnamBench | −13.5% |
| 同上 | 前沿证明器写的 Putnam 2025 长证明（AxiomProver） | 约 −1%～−2% |
| 同上（对照） | Mathlib 子集（人写） | −0.53% |
| ProofOptimizer [P9] | miniF2F、PutnamBench | −87%、−57%；约 2/3 的证明编译至少快 10% |
| Lean Refactor [P11] | 竞赛题 | token −70% 以上 |
| ImProver [P8] | 竞赛题与 Mathlib 子集 | 按自定义指标改写；Mathlib 上改进很小 |
| ImProver 2 [P10] | Mathlib | 长度改进约 0.016，依赖数与模块度有改进 |
| Lean Refactor Arena 参赛报告 [P14] | 比赛题 | 每题约 2.8 美元 |

## 这一格的特点

- **冗余在证明内部。** LeanPolish 接受的 33,402 条编辑里，删除占 51.6%、tactic 替换占 47.6%、跨 `have` 合并只占 0.8% [P12]。
- **越短的证明越难压。** 前沿证明器写的长证明和人写的 Mathlib 都几乎压不动，说明收益来自生成过程的啰嗦，而不是 Lean 本身。
- **验证简单。** 每个证明单独编译、陈述不动，闸门就是重新 elaborate 加内核检查；LeanPolish 另用新进程独立重编 [P12]。

## 适用的路线

[A3](../methods/a3-linter-driven-cleanup.md)、[B2](../methods/b2-tactic-golf-and-automation.md)、[B3](../methods/b3-llm-proof-rewriting.md)；单个证明的 [B1](../methods/b1-library-replacement.md)（换成库引理）。这一格不需要 C、D 层。

## 缺口

- 评测都在单文件里；把这些工具整库跑一遍、看能否叠加成仓库级缩小，没有公开结果。
- 指标多为 token 数，容易被长行、重度自动化刷高（见 [E3](../methods/e3-metrics.md)）；编译时间与可读性另需验收。

[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P14]: ../REFERENCES.md
[D2]: ../REFERENCES.md
