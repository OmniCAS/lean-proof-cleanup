# 清理与压缩的路线

**Summary (English).** Twenty-three routes for cleaning up and compressing Lean proofs, one file each, grouped in five tiers: A mechanical and statement-preserving, B local rewriting one theorem at a time, C structural refactoring across theorems, D rewriting the mathematics, E process and guards shared by all. Each file gives our judgment first, then the operation, who uses it, the evidence grade, the level it acts on, what keeps it correct, measured or reported effects, costs, when to use it and open problems. The routes are drawn from the community cleanup of the Lean RH development, the two-edition rewrite `lsernau/grh-lean`, and published tools and papers. The text is in Chinese.

## 核心判断

1. **压缩的单位是命题个数，不是证明长度。** 定理 + 引理：原始 818,755 个，可读版 18,227 个，紧凑版 7,088 个；每个定理的平均行数是 16.7、21.0、11.1。两个数量级的差别几乎全部来自"要证的东西少了"。（本仓库测，`data/versions_summary.json`）
2. **机械路线（A 层）合计的上限约为两到三倍。** 原始版本里 24% 的声明没被用到，约 24.1 万个定理与先前的陈述重复，48,367 个文件是陈述包装，12.8% 的行是导入与脚手架。社区 `alpoge` 线五天里把正文行减了 23%（14,621,937 → 11,217,763）。（本仓库测与他人报告）
3. **两个数量级来自 C 层与 D 层：在同一个证明骨架上重写。** 官方口径是"基于同一个证明"，很多步骤用了别的论证；作者对方法只给了三句话：展开再卷回去；一部分是新论证；先压到最短，再为清晰重写。
4. **写法跟着路线走。** 原始版本是 `have`/`rw`/`exact` 逐步推导，短版本把事实交给 `simp`/`grind`：每千行代码的 `grind` 从 0.0 到 6.2（可读版）、38.4（紧凑版），`have` 从 168.0 降到 124.8、63.4。
5. **源码短不等于证明小。** 导出：原始 61.6 GB，可读版 4.49 GB，紧凑版 5.17 GB；按内核要检查的量，短版本小 12–14 倍，不是 36–150 倍。
6. **先压后展回不到原来的样子。** 可读版仍只有原始的约 1/36，与紧凑版共享 75% 的名字，与原始版本共享的不到 8%。
7. **每条路线都需要同一道闸门（E 层）。** 逐步清理的 `alpoge` 线没有人报告过端到端核验；两个短版本发布当天就被多个独立内核检查完，因为它们小到可以重建。

## 23 条路线

"需要理解"指是否需要理解证明的数学。"观察到的效果"标出处类型：测＝本仓库测，报＝他人报告，称＝仅声称。"估计上限"是我们的推算。

| 路线 | 层 | 作用层级 | 需要理解 | 证据等级 | 观察到的效果 | 估计上限 |
|---|---|---|---|---|---|---|
| [A1 可达性裁剪](a1-reachability-pruning.md) | A | 文件–大仓库 | 否 | 主流在用 | 声明 −16.2%（S1，报）；原始 24% 未用（报） | 约 1.3 倍 |
| [A2 同陈述去重](a2-statement-dedup.md) | A | 文件–大仓库 | 否 | 主流在用 | #295 约 1.7 万处（报）；导出 −20%（含 A1，报） | 约 1.3 倍 |
| [A3 linter 驱动的删除](a3-linter-driven-cleanup.md) | A | 定理–大仓库 | 否 | 主流在用 | #243 约 11 万行（报） | 几个百分点 |
| [A4 导入收窄](a4-import-narrowing.md) | A | 文件–大仓库 | 否 | 主流在用 | 编译 −22%（#134，报） | 内容不变；构建约 −50% |
| [A5 模块重组](a5-module-regrouping.md) | A | 大仓库 | 否 | 主流在用 | 文件 −58%（#324，测） | 内容不变 |
| [A6 选项与性能清理](a6-option-and-performance-cleanup.md) | A | 定理–大仓库 | 否 | 主流在用 | 自动换 `grind` 22/26 更慢（报） | 只影响构建 |
| [A7 分阶段的机械流水线](a7-staged-mechanical-pipeline.md) | A | 小仓库–大仓库 | 否 | 有工具 | 行 −14.1%、声明 −16.2%（S4，报） | 同 A1–A4 合计 |
| [B1 换成库里的引理](b1-library-replacement.md) | B | 定理–大仓库 | 少量 | 主流在用 | #221 净 −22 万行（测） | 约 6.6 万个定理可换（报） |
| [B2 tactic 精简与收尾自动化](b2-tactic-golf-and-automation.md) | B | 定理 | 少量 | 有论文或工具 | 生成代码约 −20% token，Mathlib −0.5%（报） | 生成代码约 1.3 倍 |
| [B3 逐个定理的 LLM 改写](b3-llm-proof-rewriting.md) | B | 定理 | 局部 | 有论文或工具 | 研究仓库 >20%（报） | 约 1.3 倍 |
| [B4 证明项层面的压缩](b4-term-level-compression.md) | B | 大仓库 | 否 | 仅声称（部分有报告） | 导出 −20%（报）；52.9 万行（称） | 未知 |
| [C1 展开、化简、再分块](c1-unroll-simplify-reroll.md) | C | 小仓库–大仓库 | 是 | 作者自述 + 推测 | 与 C2、C3、D1 合计：命题 115 倍（测） | 与 D1 合计数十倍 |
| [C2 陈述通用化](c2-statement-generalization.md) | C | 文件–大仓库 | 是 | 推测（短版本里普遍，测） | 重复短名 98,631 → 225（测） | 同上 |
| [C3 去掉陈述包装层](c3-unwrap-statement-layers.md) | C | 文件–大仓库 | 部分 | 主流在用 + 推测 | 命名 `Prop` 65,318 → 4（测）；#318 1,370 个（报） | 包装文件占原始文件数的 28% |
| [C4 把已知数学移到通用库](c4-upstreaming-known-math.md) | C | 大仓库与生态 | 是 | 主流在用（进行中） | 41 个 Tau Ceti 路线图（报） | 移走而非减少 |
| [D1 换掉子论证](d1-argument-replacement.md) | D | 大仓库 | 是（研究层面） | 作者自述 + 本仓库测 | 被砍理论的目录至少约 26 万行（测，下限） | 与 C 层合计数十倍 |
| [D2 先写非形式化证明再重新形式化](d2-blueprint-first-reformalization.md) | D | 大仓库与生态 | 是 | 有先例；RH 上只有计划 | — | 有人猜测 −98% 以上（报） |
| [D3 先压到最短，再为阅读展开](d3-thin-then-thick.md) | D | 小仓库–大仓库 | 是 | 作者自述 + 本仓库测 | 可读版为原始的 1/36，紧凑版的 4 倍（测） | — |
| [E1 批量合并与智能体流水线](e1-batch-merge-and-agents.md) | E | 大仓库流程 | 否 | 主流在用 | 每分钟超过 1 个 PR（报） | — |
| [E2 验证闸门](e2-verification-gate.md) | E | 全部 | 否 | 主流在用 | 两个短版本发布当天完成多内核核验（报） | — |
| [E3 度量](e3-metrics.md) | E | 全部 | 否 | 有工具 | #185 一次净增约 560 万行 import（测） | — |
| [E4 构建加速](e4-build-acceleration.md) | E | 大仓库 | 否 | 主流在用 | 约 103 CPU 小时（报） | — |
| [E5 依赖分析](e5-dependency-analysis.md) | E | 大仓库 | 否 | 有工具与公开数据 | 闭包 75.8%（报） | — |

## 项目 × 路线

●＝主要用到，○＝部分用到或在计划中，空白＝没有。

| 路线 | 社区 `alpoge` 线 | Shore 的机械裁剪 | grh-lean（两版） | 社区新 `main` | Tau Ceti | LeanPolish / AXLE / TacticAnalysis | LLM 改写论文 |
|---|---|---|---|---|---|---|---|
| A1 可达性裁剪 | ● | ● |  | ● |  |  |  |
| A2 同陈述去重 | ● | ● |  |  |  |  |  |
| A3 linter 删除 | ● | ● |  | ○ |  | ● | ○ |
| A4 导入收窄 | ● | ● | ○ | ○ |  |  |  |
| A5 模块重组 | ● |  | ○ |  |  |  |  |
| A6 选项与性能 | ● |  |  | ● |  | ○ |  |
| A7 分阶段流水线 |  | ● |  |  |  | ○ |  |
| B1 换库引理 | ● |  | ● |  | ○ |  |  |
| B2 tactic 精简与自动化 | ○ |  | ● |  |  | ● | ○ |
| B3 LLM 改写 | ● |  | ○ |  |  | ○ | ● |
| B4 证明项压缩 | ○ |  |  |  |  |  |  |
| C1 展开再分块 |  |  | ● |  |  |  |  |
| C2 陈述通用化 |  |  | ● |  | ● |  |  |
| C3 去掉包装层 | ● |  | ● | ○ |  |  |  |
| C4 移到通用库 | ○ |  | ○ | ○ | ● |  |  |
| D1 换子论证 |  |  | ● |  |  |  |  |
| D2 蓝图优先 |  |  |  |  | ● |  |  |
| D3 先压后展 |  |  | ● |  |  |  |  |
| E1 批量合并 | ● |  |  | ● |  |  |  |
| E2 验证闸门 | ○ | ● | ● | ○ | ○ | ● | ● |
| E3 度量 | ● | ● |  |  |  | ● | ● |
| E4 构建加速 | ● |  |  | ● |  |  |  |
| E5 依赖分析 | ● | ● |  | ○ |  |  |  |

（grh-lean 一栏按成品推断：作者没有公开流程，C1、C2、D1 的作者说法见各自文件。）

## 推荐顺序

1. **E2 冻结裁判，E3 记基线，E5 量闭包。**
2. **A 层，按 A1 → A2 → B1 → 回到 A1 → A3 → A4 → A5 → A6 的顺序**，每批单独验收；需要向第三方证明"只做了机械变换"时，按 A7 分阶段并附回执。
3. **B2，只收"更短且不更慢"的替换**；B3 只用于剩下的长而慢的证明。
4. **机械路线到顶（约两到三倍）之后，决定是否重写。** 重写走 C1 + C2 + C3 + D1，在独立分支上整体完成，用 D3 的方式先压后展；已知数学按 C4、D2 交给通用库。
5. **每个发布点跑完整的 E2；E1、E4 贯穿全程。**

## 与分层方案的对应

| [分层方案](../docs/layered-plan.md)的层级 | 主要路线 |
|---|---|
| 单个定理 | A3、A6、B1、B2、B3 |
| 单个文件 | A3、A4、C2、C3（单文件内） |
| 小仓库（每批能全量重编） | A1、A2、A7、B1，以及整体重写 C1–C3、D1、D3 |
| 大仓库 | A1、A2、A4、A5、A7、B4、C4、D2，加上 E1、E4、E5；E2 在所有层级都必需 |

各条路线的出处编号见 [`../REFERENCES.md`](../REFERENCES.md)。
