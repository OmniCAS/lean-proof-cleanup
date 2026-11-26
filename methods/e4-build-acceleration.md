# E4 构建加速（build acceleration）

## 1. 一句话判断

构建速度决定了清理能迭代多快、能不能做端到端核验；在原始规模上，缓存与分布式构建是一切的前提，而最有效的"加速"其实是把仓库缩小到能整体重建。

## 2. 做什么

- 共享缓存：编译产物按内容哈希存放，贡献者下载后 `lake build --no-build` 校验，不必重编。
- 分片与分布式构建：沿 import 图分片，按每模块实测耗时排程，产物放内容寻址存储。
- 降低导入成本（[A4](a4-import-narrowing.md)）与每文件开销（[A5](a5-module-regrouping.md)）；迁到 module system，让只改证明的改动不触发下游重编。
- 升级工具链（新版本的 Lean 本身更快）。

## 3. 谁在用

- 社区：共享缓存服务、分片构建与快速检查 [z642719038]；每批对着缓存增量构建。
- 分布式构建的调度与模拟：[OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build)（预测原始版本约 475 核·时、最长链约 0.93 小时，512 核约 69 分钟）。
- Isabelle：AFP 的分布式构建（10–20 节点，目标 45 分钟以内） [P55]；Coq：回归证明选择与并行 [P53] [P54]。

## 4. 证据等级

主流在用。

## 5. 作用层级

大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 缓存只能加速，不能代替检查：完整核验要从源码重建（MIT 的做法），或至少对缓存做来源与哈希校验。
- 构建要设 `LEAN_ABORT_ON_PANIC=1`，避免 panic 之后产出的 `.olean` 进入缓存（[E2](e2-verification-gate.md)）。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 原始版本：48 核、503 GB 机器上预计 7–10 小时（社区 `verification/NOTES.md`）；Jack McCarthy 的沙箱构建 8 小时 17 分 [z643222049] | 他人报告 |
| `alpoge` 线 #185 之后：约 103 CPU 小时（192 核），约一半花在加载导入 [z642808607]；24 线程整机约 6 小时 11 分 [z643193268]；核数每翻一倍约快 1.6 倍 [z643369073] | 他人报告 |
| 两个短版本：沙箱内全项目构建约 32–34 分钟（9,852 / 9,843 个任务） [D18] | 他人报告 |
| 原始导入图 175,187 个模块、203 层、5,927 个起点；短版本 794–803 个模块、54–55 层，接近一条链 | 本仓库测 |

## 8. 代价与坑

- 短版本窄而深（55 层），并行度低，分布式构建帮不上多少；大仓库宽而浅，才值得分布式。
- 共享缓存是新的信任点：社区有人问过缓存能否被投毒 [z643465849]。
- 大文件（合并之后）让单个任务变重，关键路径变长。

## 9. 什么时候用

大仓库清理一开始就要有缓存与分片构建；仓库缩小到能整体重建之后，优先做完整核验而不是继续优化构建。

## 10. 未解决的问题

- 新 `main` 升到 v4.37.0-rc1 后的构建时间与内存，尚无公开测量。

[D18]: ../REFERENCES.md
[P53]: ../REFERENCES.md
[P54]: ../REFERENCES.md
[P55]: ../REFERENCES.md
[z642719038]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642719038
[z642808607]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642808607
[z643193268]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643193268
[z643222049]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/RH.3A.20conserving.20original.20proof/near/643222049
[z643369073]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643369073
[z643465849]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643465849
