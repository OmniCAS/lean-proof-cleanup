# E4 构建加速（build acceleration）

## 1. 一句话判断

构建速度决定清理能迭代多快、能不能做端到端核验。在小仓库以下（每批改动都能全量重编）它不是问题；到大仓库，缓存、回归选择与分布式构建是一切的前提，而最有效的"加速"其实是把仓库缩小到能整体重建。来源主要通过结构起作用：文件碎、导入多的仓库每文件开销高，先做导入收窄与模块重组；维护者精心维护的库已迁到 module system，只改证明不触发下游重编。导入图的形状决定分布式能帮多少：宽而浅才值得，窄而深帮不上。

## 2. 做什么

- 共享缓存：编译产物按内容哈希存放，贡献者下载后用 `lake build --no-build` 校验，不必重编。
- 回归选择：只重编受改动影响的模块和下游锥体；迁到 module system，让只改证明的改动不触发下游重编。
- 分片与分布式构建：沿 import 图分片，按每模块实测耗时排程，产物放内容寻址存储。
- 降低导入成本（[A4](a4-import-narrowing.md)）与每文件开销（[A5](a5-module-regrouping.md)）。
- 升级工具链（新版本的 Lean 本身更快）；单独一条线、单独验收，不和清理混在一起。

## 3. 谁在用

- Lean 与 Mathlib：module system 在 v4.27 稳定，手册说明只改证明、注释这类不导出的内容时不触发文件外重编；Mathlib 的 8,624 个文件已全部迁入 [T10]；`lake shake` 在 CI 里收窄导入 [T1]（见 [curated-library-mathlib](../cases/curated-library-mathlib.md)）。
- 其他系统：Isabelle AFP 的分布式构建（10–20 节点，目标 45 分钟以内） [P55]；Coq 的回归证明选择与并行 iCoq/piCoq [P53] [P54]；seL4 的大规模证明管理经验 [P51]；证明系统的性能工程 [P56]。
- 改写工具顺带的加速：Lean Refactor 把编译时间当作目标之一 [P11]；ProofOptimizer 报告多数证明编译变快 [P9]。
- 大仓库示例（Lean RH 开发，模型生成）：社区的共享缓存服务、分片构建与快速检查 [z642719038]，每批对着缓存增量构建；分布式构建的调度与模拟 [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build)（预测原始版本约 475 核·时、最长链约 0.93 小时，512 核约 69 分钟）。

## 4. 证据等级

- **主流在用**：缓存、回归选择、分布式构建，各系统都有；Lean 的 module system。
- **有论文或工具**：Lean 上按实测耗时排程的分布式构建与模拟（上面的 RH 示例）。

## 5. 作用层级

大仓库；小仓库只需要 module system 与导入收窄。不需要理解数学。

## 6. 正确性靠什么保证

- 缓存只能加速，不能代替检查：完整核验要从源码重建，或至少对缓存做来源与哈希校验（例：Lean RH 开发里 MIT 的核验从源码重建）。
- 构建要设 `LEAN_ABORT_ON_PANIC=1`，避免 panic 之后产出的 `.olean` 进入缓存（[E2](e2-verification-gate.md)）。
- 回归选择要按构建产物里的真实依赖算受影响集合，不能按文件名猜。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 仓库 × Isabelle AFP | 10–20 节点的集群，目标是把构建压回 45 分钟以内 [P55] | 他人报告 |
| 单个定理 × 竞赛题与研究仓库（Lean Refactor） | 编译时间最多 −60% [P11] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明 | ProofOptimizer：约 2/3 的证明编译快 ≥10% [P9] | 他人报告 |
| 大仓库 × 模型生成（RH） | 原始版本：48 核、503 GB 机器上预计 7–10 小时（社区 `verification/NOTES.md`）；Jack McCarthy 的沙箱构建 8 小时 17 分 [z643222049] | 他人报告 |
| 大仓库 × 模型生成（RH） | `alpoge` 线 #185 之后：约 103 CPU 小时（192 核），约一半花在加载导入 [z642808607]；24 线程整机约 6 小时 11 分 [z643193268]；核数每翻一倍约快 1.6 倍 [z643369073] | 他人报告 |
| 大仓库 × 模型生成（RH） | 两个短版本：沙箱内全项目构建约 32–34 分钟（9,852 / 9,843 个任务） [D18] | 他人报告 |
| 大仓库 × 模型生成（RH） | 原始导入图 175,187 个模块、203 层、5,927 个起点；短版本 794–803 个模块、54–55 层，接近一条链 | 本仓库测 |
| 其他规模与来源（Mathlib、人写研究仓库清理前后的构建时间） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 窄而深的导入图并行度低，分布式构建帮不上多少；宽而浅才值得分布式（例：Lean RH 开发的短版本有 55 层，原始版本最宽一层有 5,927 个模块）。
- 共享缓存是新的信任点（例：Lean RH 开发的社区里有人问过缓存能否被投毒 [z643465849]）。
- 大文件（合并之后）让单个任务变重，关键路径变长。
- 不用 module system 时，任何证明改动都会让下游全部重编，回归选择省不了多少。

## 9. 什么时候用

大仓库清理一开始就要有缓存与分片构建；仓库缩小到能整体重建之后，优先做完整核验而不是继续优化构建。小仓库先迁到 module system、收窄导入即可。

## 10. 未解决的问题

- module system 在"只改证明"的清理批次上实际省下多少重编？没有公开测量。
- Lean 能否像 iCoq 那样做到证明级的回归选择，而不只是模块级？
- （RH 案例）新 `main` 升到 v4.37.0-rc1 后的构建时间与内存，尚无公开测量。

[D18]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P51]: ../REFERENCES.md
[P53]: ../REFERENCES.md
[P54]: ../REFERENCES.md
[P55]: ../REFERENCES.md
[P56]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T10]: ../REFERENCES.md
[z642719038]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642719038
[z642808607]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642808607
[z643193268]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643193268
[z643222049]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/RH.3A.20conserving.20original.20proof/near/643222049
[z643369073]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643369073
[z643465849]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643465849
