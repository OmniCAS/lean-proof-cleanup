# B2 tactic 精简与收尾自动化（tactic golf and closing automation）

## 1. 一句话判断

收益几乎完全由来源决定：模型生成的竞赛证明上符号 pass 能省约两成 token，维护者精心维护的库上不到 1%，前沿证明器写的长证明上只有一两个百分点。把一段逐步推导换成一次 `grind`/`simp_all` 是短证明的标志写法，但自动替换常常更慢、对库版本更敏感，必须计时。

## 2. 做什么

- 替换菜单：在关闭目标的叶子 tactic 处依次试 `rfl`、`ring`、`norm_num`、`omega`、`linarith`、`positivity`、`decide`、`simp?` 等，只收更短且通过的；迭代到不动点。
- 收尾自动化：把逐步的 `have`/`rw`/`exact` 换成"给出事实，交给 `grind [...]`、`simp_all [...]`、`aesop`、`bound`、`fun_prop`、`field`"。
- 搜索式 tactic 固化：`simp?`、`exact?`、`aesop?`、`try?` 的建议写回源码，仓库里不留搜索 tactic；需要复查的用 `says` 固定 [T5]。
- 先看写法画像（每千行的 `have`、`rw`、`grind`），判断有没有可换的（[profiles](../cases/profiles.md)）。

## 3. 谁在用

- Mathlib：TacticAnalysis 的 `tryAtEachStep*`、`terminalToGrind`、`mergeWithGrind`、`rwMerge`，若干 pass 默认开、昂贵的定期运行 [T4]；Skimmer 批量应用 Try-this [T7]；核心的 `try?` [T2]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 工具与论文：LeanPolish（15 个候选的替换菜单 + 删未用 `have`，迭代到不动点）[P12] [D2]；AXLE 的 `simplify_theorems` [P13]；ProofOptimizer 的符号阶段 [P9]；LeanHammer [P15]。
- 其他系统：TacticToe 找到证明后做长度与参数最小化 [P4]；Sledgehammer 的事实最小化与 Isar 压缩 [P3]；Metamath 提交前必须最小化 [T15]，GPT-f 的 23 个更短证明被 set.mm 采纳 [P5]；HOL Light 的 Tactician 做 tactic 步骤的打包与展开 [P21]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线上逐个证明的 golf PR（如 [#90] −344 行，[#75] 25 → 11 行）；grh-lean 的两个短版本整体采用收尾自动化的写法（见下表）。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md) 与 [短版本对比](../cases/rh/grh-compact-vs-original.md)。

## 4. 证据等级

- 有论文或工具：LeanPolish、AXLE、ProofOptimizer、TacticAnalysis。
- 主流在用：Metamath 的提交前最小化；RH 案例里的小 PR。

§7 里的写法画像是本仓库测的写法统计，不是效果证据。

## 5. 作用层级

单个定理。替换菜单不需要理解数学；收尾自动化需要知道证明用到哪些事实。

## 6. 正确性靠什么保证

- 只改证明体；每处替换都重新 elaborate 并过内核（LeanPolish 另用新进程独立重编）[P12]。
- 不引入新公理：最小化时排除 `native_decide` 等，与 Metamath 的 `/no_new_axioms_from` 同理 [T15]。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | LeanPolish 节省 token：Goedel-Prover 证明 20.0%，miniF2F 22.6%，PutnamBench 13.5% [D2] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | LeanPolish 不动点与 AXLE 叠加：miniF2F 29.8% / 27.1% → 35.9%；PutnamBench 16.1% / 25.6% → 28.5% [D2] | 他人报告 |
| 单个定理 × 模型生成的长证明（前沿证明器） | AxiomProver 证明 1.3%–1.8%，Aristotle 的 IMO 题 0.3%–0.5% [D2] | 他人报告 |
| 库 × Mathlib | LeanPolish 在 Mathlib 子集上节省 0.53% [D2] | 他人报告 |
| 库 × Mathlib | 写法画像：每个定理 7.5 行，每千行 `have` 31.8、`grind` 5.0（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 每个定理 15.6–17.5 行，每千行 `have` 67.5–127.2、`grind` 0.7–4.3（[profiles](../cases/profiles.md)）；缩短的效果没有公开数字 | 本仓库测 |
| 大仓库 × 模型生成（RH） | 每千行 `grind`：原始 0.0，重写后的可读版 6.2、紧凑版 38.4；`have`：168.0、124.8、63.4；`rw`：133.7、52.7、16.1（`data/tree_profiles.json`） | 本仓库测 |
| 大仓库 × 模型生成（RH） | `terminalToGrind` 在 `alpoge` 线上的 26 条建议中 22 条更慢 [z643461700] | 他人报告（转述） |

单定理数字的背景见 [单定理 × 生成证明](../cases/theorem-scale-generated-proofs.md)。RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 更短常常更慢：重度自动化把搜索成本搬到编译时（例：Lean RH 开发重写后的紧凑版要全局放宽 heartbeats 才能编译）。
- 依赖自动化的证明对库版本更敏感，simp 集合或 `@[grind]` 标注一变就可能失败。
- 可读性下降：社区可能宁要较长的版本（例：Lean RH 开发的社区以可读版而不是紧凑版为准）。
- 在人写代码和前沿证明器的长证明上，菜单几乎找不到可换的，成本却按目标数线性增长。

## 9. 什么时候用

- 在 A 层之后、[B3](b3-llm-proof-rewriting.md) 之前；热点证明先做；与 [A6](a6-option-and-performance-cleanup.md) 共用计时闸门。
- 按来源：模型生成的证明全量跑；人写代码只跑 TacticAnalysis 出报告，人挑着收；维护的库按 CI 节奏跑。

## 10. 未解决的问题

- 删除类与替换类 pass 在仓库规模上的叠加效果；目前只有竞赛题上的数字。
- "更短"与"更快"的权衡没有统一的验收规则。
- LeanPolish 固定在 Lean 4.21，移植到当前版本要多少工作（[survey](../docs/survey.md) §1）。

[#75]: https://github.com/leanprover-community/riemann-hypothesis/pull/75
[#90]: https://github.com/leanprover-community/riemann-hypothesis/pull/90
[D2]: ../REFERENCES.md
[P3]: ../REFERENCES.md
[P4]: ../REFERENCES.md
[P5]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P13]: ../REFERENCES.md
[P15]: ../REFERENCES.md
[P21]: ../REFERENCES.md
[T2]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[T7]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[z643461700]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643461700
