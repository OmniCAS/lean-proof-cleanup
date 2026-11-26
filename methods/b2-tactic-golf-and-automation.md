# B2 tactic 精简与收尾自动化（tactic golf and closing automation）

## 1. 一句话判断

在模型生成的证明上能省约两成 token，在人写代码上几乎为零；把一段推导换成一次 `grind`/`simp_all` 是短版本的标志写法，但自动替换常常更慢，必须计时。

## 2. 做什么

- 替换菜单：在关闭目标的叶子 tactic 处依次试 `rfl`、`ring`、`norm_num`、`omega`、`linarith`、`positivity`、`decide`、`simp?` 等，只收更短且通过的；迭代到不动点。
- 收尾自动化：把逐步的 `have`/`rw`/`exact` 换成"给出事实，交给 `grind [...]`、`simp_all [...]`、`aesop`、`bound`、`fun_prop`、`field`"。
- 搜索式 tactic 固化：`simp?`、`exact?`、`aesop?`、`try?` 的建议写回源码。

## 3. 谁在用

- LeanPolish（15 个候选的替换菜单 + 删未用 `have`，迭代到不动点） [P12] [D2]；AXLE 的 `simplify_theorems` [P13]；ProofOptimizer 的符号阶段 [P9]。
- Mathlib TacticAnalysis：`tryAtEachStep*`、`terminalToGrind`、`mergeWithGrind`、`rwMerge` [T4]；Skimmer 批量应用 Try-this [T7]。
- 社区 `alpoge` 线：逐个证明的 golf PR（如 [#90] −344 行，[#75] 25 → 11 行）。
- grh-lean 两个短版本整体采用这种写法（见下表）。

## 4. 证据等级

有论文或工具（LeanPolish、AXLE、TacticAnalysis）；在 RH 上是主流在用的小 PR。短版本的写法统计是本仓库测。

## 5. 作用层级

定理。不需要理解数学（替换菜单）；收尾自动化需要知道证明用到哪些事实。

## 6. 正确性靠什么保证

- 只改证明体；每处替换都重新 elaborate 并过内核（LeanPolish 另用新进程独立重编） [P12]。
- 不引入新公理：最小化时排除 `native_decide` 等。

## 7. 效果

| 数字 | 标记 |
|---|---|
| LeanPolish 节省 token：Mathlib 子集 0.53%，Goedel-Prover 证明 20.0%，miniF2F 22.6% [D2] | 他人报告 |
| LeanPolish 不动点与 AXLE 叠加：miniF2F 29.8% / 27.1% → 35.9%；PutnamBench 16.1% / 25.6% → 28.5% [D2] | 他人报告 |
| 每千行代码的 `grind`：原始 0.0，可读版 6.2，紧凑版 38.4；`have`：168.0、124.8、63.4；`rw`：133.7、52.7、16.1 | 本仓库测（`data/versions_summary.json`） |
| `alpoge` 线上 `terminalToGrind` 的 26 条建议中 22 条更慢 [z643461700] | 他人报告（转述） |

## 8. 代价与坑

- 更短常常更慢：重度自动化把搜索成本搬到编译时；紧凑版要全局放宽 heartbeats 才能编译。
- 依赖自动化的证明对库版本更敏感，simp 集合一变就可能失败。
- 可读性下降：社区以可读版而不是紧凑版为准。

## 9. 什么时候用

在 A 层之后、[B3](b3-llm-proof-rewriting.md) 之前；对热点证明先做。与 [A6](a6-option-and-performance-cleanup.md) 共用计时闸门。

## 10. 未解决的问题

- 删除类与替换类 pass 在大仓库上的叠加效果；目前只有竞赛题上的数字。
- "更短"与"更快"的权衡没有统一的验收规则。

[#75]: https://github.com/leanprover-community/riemann-hypothesis/pull/75
[#90]: https://github.com/leanprover-community/riemann-hypothesis/pull/90
[D2]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P13]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T7]: ../REFERENCES.md
[z643461700]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643461700
