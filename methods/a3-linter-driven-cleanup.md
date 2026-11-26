# A3 linter 驱动的删除（linter-driven cleanup）

## 1. 一句话判断

零风险、可整库批量做的收尾工作，删的是语法垃圾而不是数学；行数收益有限，主要价值是让后续改写面对干净的代码。

## 2. 做什么

- 收集构建日志里 Lean 与 Mathlib linter 的警告：未用 simp 参数、不可达 tactic、不改变目标的 tactic、多余 `simpa`、未用变量、未用 `have`。
- 用脚本只删不改：Mathlib 的 `fix_unused.py`、`fix_unused_simp_args.py` [T6]，或自写的删除器。
- 迭代到没有新警告为止（删一处可能让另一处变成多余）。

## 3. 谁在用

- 社区 `alpoge` 线：[#67] → [#243]（James Shore，只删 linter 标为无用的语法）；新 `main` 上 Righi 的未用字段 PR [#5642]。
- 工具：Lean 核心与 Mathlib 的 linter [T2] [T3]、Batteries 的 `unusedHavesSuffices` [T8]、AXLE 的 `simplify_theorems` [P13]、ProofOptimizer 的符号阶段 [P9]、LeanPolish 的删除类编辑 [P12]。

## 4. 证据等级

主流在用；工具都是公开的。

## 5. 作用层级

定理到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 只改证明体，陈述不可能变化；重编该文件即可，批量时整库重编。
- linter 本身只是诊断，删掉之后能否编译由重编决定。

## 7. 效果

| 数字 | 标记 |
|---|---|
| #243：约 10.7 万~11.2 万行删除，"unused" 类警告 −94%；作者自报完整构建 + nanoda + con-leche [z642796623] [z643005632] | 他人报告 |
| #67：存储的 linter 警告约 35.7 万 → 约 26.5 万 | 他人报告 |
| LeanPolish 的 33,402 条已接受编辑中，删除占 51.6% [P12] | 他人报告 |
| linter 本身约占构建 CPU 的 0.4% [z643409003] | 他人报告 |

## 8. 代价与坑

- 收益集中在模型生成的代码里；人写代码几乎没有可删的。
- 删掉 `<;>` 之类的组合子后，有时会改变哪个 tactic 生效，必须重编。
- 大量小改动会制造合并冲突，适合单独成批（[E1](e1-batch-merge-and-agents.md)）。

## 9. 什么时候用

- 在 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 之后（先删整块，再删碎片），在 [B2](b2-tactic-golf-and-automation.md) 之前。
- 每一轮改写之后再跑一次。

## 10. 未解决的问题

- 删除类 pass 与替换类 pass 的最佳顺序：LeanPolish 与 AXLE 两种顺序叠加的结果接近（miniF2F 35.9% 对 34.0%） [D2]，大仓库上没有测过。

[#67]: https://github.com/leanprover-community/riemann-hypothesis/pull/67
[#243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[D2]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P13]: ../REFERENCES.md
[T2]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[T6]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[z642796623]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642796623
[z643005632]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643005632
[z643409003]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643409003
