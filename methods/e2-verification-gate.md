# E2 验证闸门（verification gate）

## 1. 一句话判断

所有路线共用的一道门：陈述不变、公理不增、内核接受，与改写者是 linter、符号 pass、模型还是人无关。规模决定它能多常跑：单个定理到小仓库每批都能跑完整闸门；大仓库上一次完整检查的时间与内存都很可观，只能在发布点跑，逐步清理的中间状态往往没人核验，而小到能整体重建的版本反而能当天核验完。来源决定要防什么：模型生成的证明要防陈述被改、新增 `sorry` 与公理、可信定义被一起改掉；精心维护的库靠审阅与 CI 拦住这些。

## 2. 做什么

| 层次 | 内容 |
|---|---|
| 冻结裁判 | Challenge 文件、comparator 配置、导出目标不许任何改动碰；清理前导出一次 Challenge，之后对着冻结导出判（`lake comparator --challenge-from-export`） |
| 陈述与公理 | comparator：Solution 里每个目标定理的陈述与 Challenge 相同、公理不超出允许集；`#print axioms`；源码不新增 `sorry`、`admit`、`axiom`、`native_decide` |
| 内核 | Lean 默认内核与 paranoid 内核；外部内核 nanoda、lean4lean、con-leche、con-ron；`leanchecker` 逐模块重放 |
| 可复现 | 两台机器分别构建并导出，比对导出哈希 |
| 构建完整性 | `LEAN_ABORT_ON_PANIC=1`；共享缓存的来源与哈希 |
| 频率 | 每个改动：编译与禁用 token 扫描；每批：comparator 对冻结导出；发布点：外部内核与可复现检查 |

## 3. 谁在用

- Lean 核心与 Lake：`lake comparator`、`lake check`、`leanchecker` [T1]，外部内核 [T10] [T12]；此前的独立 comparator 写明了陈述、公理、内核三项保证 [T11]。
- 论文与工具都靠"生成后检查"：LeanPolish 每处编辑后重新 elaborate 并过内核，基准语料再用独立进程从头编译，并审计陈述一致、无新增 `sorry`/`admit`/`axiom`/`native_decide`、只用三条标准公理 [P12] [D2]；ImProver、ProofOptimizer、Lean Refactor 都以编译把关 [P8] [P9] [P11]。
- 其他系统：Metamath 最小化时加 `/no_new_axioms_from`，禁止引入新公理 [T15]；本身带保证的方法很少：形式定义的 refactoring [P20]、沿类型等价的迁移 [P40]。
- 大仓库示例（Lean RH 开发，模型生成；该开发陈述了 RH 与 Dirichlet GRH，第三方报告机器核验通过，数学尚无人审阅）：MIT（Andrew Sutherland）对原始版本 [D17] 和两个短版本 [D18] 做了上表的全部检查；Jack McCarthy 在另一台机器上对原始版本跑了 comparator [z643222049]；社区仓库用 `challenge-files.yml` 冻结 challenge 文件 [C3]，`comparator.json` 列外部内核；缓存里的一个 `.olean` 在编译器 panic 的情况下产出却没被发现，之后要求构建时设置 `LEAN_ABORT_ON_PANIC=1` [z643107722]。

## 4. 证据等级

主流在用（Lean 自带的工具、各篇论文的编译把关、MIT 的公开记录）。

## 5. 作用层级

全部层级。单个定理上是重新 elaborate 加内核检查；仓库上是 comparator 对冻结导出，加外部内核。

## 6. 正确性靠什么保证

闸门本身就是保证；它的可信度来自"多个独立实现都接受"。共同前提是 Lean 的类型论与三条标准公理、以及导出工具。冻结的 Challenge 导出堵的是"可信定义与 Challenge 一起被改、comparator 照样通过"这个口子。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明（LeanPolish） | 逐处编译把关：接受 33,402 条编辑，同一位置失败的尝试 65,596 条；与 AXLE 对比实验的审计全部通过（陈述、禁用 token、公理） [P12] [D2] | 他人报告 |
| 大仓库 × 模型生成（RH 原始版本） | 构建、`#print axioms`、逐模块重放、跨机器导出比对、nanoda、con-leche/con-ron `--compare`、Lean 默认与 paranoid 内核、`lake comparator` 全流程都通过；paranoid 内核跑了 68 小时 53 分 [z643222049] | 他人报告 [D17] |
| 大仓库 × 模型生成（RH `alpoge` 线） | 只有 CI 构建与每批的机械检查；没有报告过端到端核验 | 他人报告（缺失） |
| 大仓库 × 模型生成（RH 可读版，即新 `main` 的起点） | 构建、axioms、803/803 重放、导出比对、全部外部内核、`lake comparator` 通过；单独跑 lean4lean 用 2 小时 35 分、峰值 332 GB 内存；`lake comparator --paranoid` 在较大的机器上给出 "Your solution is okay!"（4 小时 9 分 59 秒，其中 lean4lean 约 2 小时 40 分），在较小的机器上因内存不够被停止、没有结论（不是拒绝） | 他人报告（[D18]，02:50 UTC 版，全部检查结束） |
| 大仓库 × 模型生成（RH 紧凑版） | 上述全部通过，`lake comparator --paranoid` 在两台机器上通过 | 他人报告（同上） |
| 其他规模与来源（人写研究仓库、Mathlib 的端到端核验成本） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据；两个短版本是它的重写，规模已接近小仓库。

## 8. 代价与坑

- 规模决定能否核验：comparator 是单线程的 [z643463691]，大仓库上一次完整检查以天计（例：Lean RH 开发的原始版本，paranoid 内核约 69 小时）。
- 内存：外部内核在大导出上要几百 GB（例：Lean RH 开发的可读版上 lean4lean 需要 332 GB，作者自己的机器在 125 GB 处耗尽 [z643710501]）。
- "陈述文本相同"不等于"陈述用到的定义相同"：要用冻结的 Challenge 导出比对。
- 共享缓存加速了构建，也带来新的信任点：要么从源码重建，要么校验缓存的来源与哈希（[E4](e4-build-acceleration.md)）。

## 9. 什么时候用

任何路线之前冻结；每个改动跑编译与禁用 token 扫描，每批跑机械检查，小仓库每批再跑 comparator；每个发布点跑完整核验。

## 10. 未解决的问题

- comparator 能否只检查受改动影响的依赖锥体，让大仓库也能每批跑？
- 外部内核能否并行或分片，把大导出的内存需求降下来？
- （RH 案例）新 `main` 的后续提交（批次 m1–m4、升 4.37）还没有单独的端到端核验报告。

[C3]: ../REFERENCES.md
[D2]: ../REFERENCES.md
[D17]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P20]: ../REFERENCES.md
[P40]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T10]: ../REFERENCES.md
[T11]: ../REFERENCES.md
[T12]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[z643107722]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643107722
[z643222049]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/RH.3A.20conserving.20original.20proof/near/643222049
[z643463691]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643463691
[z643710501]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643710501
