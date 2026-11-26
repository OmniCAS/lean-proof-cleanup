# 清理与压缩的路线

**Summary (English).** Twenty-three routes for cleaning up and compressing Lean proofs, one file each, in five tiers: A mechanical and statement-preserving, B local rewriting one theorem at a time, C structural refactoring across theorems, D rewriting the mathematics, E process and guards shared by all. Routes are chosen along two axes: scale (single theorem, file, small repository, large repository) and provenance (curated library, human-written research repository, model-generated proofs, large model-generated development), because provenance decides how much redundancy there is and of which kind. This page gives the general judgments with their evidence, a diagnosis step (which indicators to compute before choosing), a table for choosing routes by scale and provenance, the route table, a matrix of practitioners against routes, and a recommended order. The Lean RH development appears as the example for the cell "large repository, model-generated". The text is in Chinese.

## 两条轴

- **规模**：单个定理 / 单个文件 / 小仓库（每批改动能全量重编）/ 大仓库。规模决定验证成本，也决定能否整体重写。
- **来源**：精心维护的库（Mathlib）/ 人写的研究仓库 / 模型生成的证明（竞赛题等）/ 模型生成的大型开发。来源决定冗余有多少、是哪一种，所以决定哪些路线有回报。

案例按这两条轴索引在 [`../cases/`](../cases/README.md)；七棵公开 Lean 树的结构指标在 [`../cases/profiles.md`](../cases/profiles.md)。

## 核心判断

1. **冗余在哪里由来源决定，压缩的单位也随之不同。** 模型生成的竞赛证明，冗余在证明内部：LeanPolish 的符号 pass 省约 20% 的 token，ProofOptimizer 报告 57%–87% [P12] [P9]。精心维护的库几乎没有可压的：同一管线在 Mathlib 上只省 0.53%，ImProver 2 的长度改进约 0.016 [P12] [P10]。大型生成开发的冗余在命题个数与组织：LeanLean 的 64 个仓库里收益主要来自重组依赖 [P30]；大仓库示例（RH）里定理与引理从 818,755 个降到 7,088 个，而每个定理的平均行数几乎不变（16.7 → 11.1）。
2. **机械、保持陈述的路线有上限，上限由死代码与重复的比例决定。** Metamath 与 Mizar 长期整库跑最小化与删冗余工具，收益是持续的小步 [T15] [P48]；人写研究仓库的结构指标显示几乎没有成片的包装层（[profiles](../cases/profiles.md)）。大仓库示例（RH）：24% 的声明未被用到，约 24.1 万个定理重复先前的陈述，48,367 个文件是陈述包装，合计估计约两到三倍；逐步清理五天做到正文行 −23%。
3. **结构性的缩小需要理解证明。** LeanLean 里只有最强的模型能从依赖重组里拿到大头 [P30]；Leanify 观察到压缩越往后、发现的可复用引理越多 [P29]；证明论里切规则引入与发明定义是同一方向的理论先例 [P17] [P16]。大仓库示例（RH）：两个数量级来自在同一证明骨架上的重写（展开再分块、通用化、换论证）。
4. **自动化让源码变短，但不一定更快，也不一定更小。** Lean Refactor 发现长度与编译时间只是弱相关 [P11]；ProofOptimizer 的缩短让约 2/3 的证明快了 10% 以上 [P9]，而大仓库示例（RH）里自动换成 `grind` 的建议 26 条有 22 条更慢，紧凑版源码是可读版的 1/4、导出却大 15%。写法可以直接从策略画像看出（[profiles](../cases/profiles.md)：`have` 每千行从 Mathlib 的 31.8 到 RH 原始的 168.0）。
5. **每条路线都用同一道闸门，成本随规模走。** 几乎所有方法都是"生成后检查"：重新编译、陈述与公理不变、内核接受（Metamath 的最小化还显式禁止引入新公理 [T15]）。小仓库每批都能全量重编；大仓库只能分级核验，能否缩到可以整体重建的规模，决定了核验能做到哪一步。大仓库示例（RH）：逐步清理线没有端到端核验报告，两个短版本发布当天就被多个独立内核检查完。
6. **先诊断，再选路线。** 下面"诊断"一节的指标能在不构建的情况下区分来源，并直接指向该用的路线。

## 诊断：动手前先算的指标

用 [`../scripts/profile_lean_trees.py`](../scripts/profile_lean_trees.py) 从源码算（不构建）；闭包类指标要构建后从内核项算（[E5](e5-dependency-analysis.md)）。参照值取自 [profiles](../cases/profiles.md)：Mathlib / 三个人写研究仓库 / 大型生成开发（RH 原始）。

| 指标 | 参照值 | 偏高时指向 |
|---|---|---|
| 未用声明比例（从最终定理出发的闭包之外） | 库不适用（叶子是 API [P38]）；RH 原始 24% | [A1](a1-reachability-pruning.md) |
| 与先前陈述相同的定理比例 | RH 原始约 30%（导出上统计）；其他没有公开数字 | [A2](a2-statement-dedup.md)、[B1](b1-library-replacement.md) |
| 只有一个声明的文件占比 | 3.7% / 7%–19% / 45% | [A5](a5-module-regrouping.md)、[C3](c3-unwrap-statement-layers.md) |
| 每个文件的声明数 | 30.0 / 14–39 / 6.1 | 偏低时同上 |
| 命名 `Prop` 定义（每千行代码） | 0.8 / 0.3–0.6 / 6.0 | [C3](c3-unwrap-statement-layers.md) |
| 导入行占全部行 | 1.0% / 0.5%–2.0% / 5.2% | [A4](a4-import-narrowing.md) |
| 注释行占全部行 | 15% / 6%–15% / 0% | 接近 0 是生成的痕迹；可读性要另做（[D3](d3-thin-then-thick.md)） |
| 每个定理的平均行数 | 7.5 / 15.6–17.5 / 16.7 | 高且写法逐步时 [B2](b2-tactic-golf-and-automation.md)、[B3](b3-llm-proof-rewriting.md) |
| 策略画像（`have`/`rw`/`exact` 对 `simp`/`grind`，每千行） | `have` 31.8 / 67–127 / 168.0 | 逐步推导多：B2；自动化多：先查编译时间（[A6](a6-option-and-performance-cleanup.md)） |
| 选项覆盖（heartbeats 等，每千行） | 8.3 / 3.0–5.9 / 5.0 | 不区分来源；指向构建与版本问题（A6、[E4](e4-build-acceleration.md)） |
| 重复的短名（占不同短名） | 13.3% / 1.7%–5.8% / 13.0% | 不区分来源（库按命名空间复用短名） |
| 构建时间分布与内存峰值 | 计时构建 | 热点：A6、E4 |

## 按规模与来源选路线

| 来源 \ 规模 | 单个定理 | 单个文件 | 小仓库 | 大仓库 |
|---|---|---|---|---|
| 精心维护的库 | A3、A6；B 层收益很小 | A3、A4、拆长文件 | — | E 层的持续流程：默认 linter、CI 里的 shake、弃用别名、技术债统计（[Mathlib 案例](../cases/curated-library-mathlib.md)） |
| 人写的研究仓库 | B1、B2（收益小到中） | A3、A4 | A1、A2、B1；把背景上游（C4） | 同小仓库，加 E1、E4 |
| 模型生成的证明 | A3、B2、B3（主要收益在这里） | A3 | A1、A2、B1；证明集合可做 C1 式压缩（Leanify） | — |
| 模型生成的大型开发 | B2（只对热点） | A5、C3 | — | A1 → A2 → B1 → 回到 A1 → A3–A6（可按 A7 分阶段）；到顶后 C1–C3、D1、D3 整体重写；E 层全套（[RH 案例](../cases/rh/README.md)） |

## 23 条路线

"观察到的效果"注明规模 × 来源；测＝本仓库测，报＝他人报告，称＝仅声称。"估计上限"是我们的推算。

| 路线 | 层 | 需要理解 | 证据等级 | 观察到的效果 | 估计上限 |
|---|---|---|---|---|---|
| [A1 可达性裁剪](a1-reachability-pruning.md) | A | 否 | 主流在用 | 大型生成开发（RH）：声明 −16.2%（报） | 等于未用声明比例 |
| [A2 同陈述去重](a2-statement-dedup.md) | A | 否 | 主流在用 | 大型生成开发（RH）：约 1.7 万处（报）；其他无公开数字 | 等于重复陈述比例 |
| [A3 linter 驱动的删除](a3-linter-driven-cleanup.md) | A | 否 | 主流在用 | 生成竞赛证明：删除占 LeanPolish 编辑的 51.6%（报）；Mathlib 默认开启 | 几个百分点 |
| [A4 导入收窄](a4-import-narrowing.md) | A | 否 | 主流在用 | Mathlib：CI 里持续跑；大型生成开发（RH）：编译 −22%（报） | 内容不变；构建可降很多 |
| [A5 模块重组](a5-module-regrouping.md) | A | 否 | 主流在用（大仓库） | 大型生成开发（RH）：文件 −58%（测）；其他无公开数字 | 内容不变 |
| [A6 选项与性能清理](a6-option-and-performance-cleanup.md) | A | 否 | 主流在用 | Mathlib：覆盖须写原因；自动替换常更慢（RH，报） | 只影响构建 |
| [A7 分阶段的机械流水线](a7-staged-mechanical-pipeline.md) | A | 否 | 有工具 | Metamath、Mizar 定期整库跑；RH：行 −14.1%（S4，报） | 同 A1–A4 合计 |
| [B1 换成库里的引理](b1-library-replacement.md) | B | 少量 | 主流在用 | 大型生成开发（RH）：约 6.6 万个定理已在 Mathlib/Core 中（报） | 取决于与库的重合 |
| [B2 tactic 精简与收尾自动化](b2-tactic-golf-and-automation.md) | B | 少量 | 有论文或工具 | 生成竞赛证明 −20%，Mathlib −0.5%（报） | 生成证明约 1.3 倍 |
| [B3 逐个定理的 LLM 改写](b3-llm-proof-rewriting.md) | B | 局部 | 有论文或工具 | 竞赛证明 57%–87%，研究仓库 >20%（报） | 研究仓库约 1.3 倍 |
| [B4 证明项层面的压缩](b4-term-level-compression.md) | B | 否 | 仅声称（部分有报告） | Leanify：证明项 −94%～−99%（报）；RH 导出 −20%（报） | 未知 |
| [C1 展开、化简、再分块](c1-unroll-simplify-reroll.md) | C | 是 | 作者自述 + 推测 | LeanLean：依赖重组是大头（报）；RH：命题 115 倍（测，与 C2、C3、D1 合计） | 与 D1 合计数十倍（大型生成开发） |
| [C2 陈述通用化](c2-statement-generalization.md) | C | 是 | 推测 | RH 短版本里普遍（测）；其他无公开数字 | 同上 |
| [C3 去掉陈述包装层](c3-unwrap-statement-layers.md) | C | 部分 | 主流在用 + 推测 | 命名 `Prop` 每千行：人写 0.3–0.6、RH 原始 6.0（测） | 包装层在生成开发里可占文件的三成 |
| [C4 把已知数学移到通用库](c4-upstreaming-known-math.md) | C | 是 | 主流在用 | Mathlib 的上游流程；Tau Ceti 路线图（报） | 移走而非减少 |
| [D1 换掉子论证](d1-argument-replacement.md) | D | 是（研究层面） | 作者自述 + 本仓库测 | RH：被砍理论的目录至少约 26 万行（测，下限）；其他无公开数字 | 视数学而定 |
| [D2 先写非形式化证明再重新形式化](d2-blueprint-first-reformalization.md) | D | 是 | 有先例 | 蓝图工作流在大型 Lean 项目里常用；RH 上只有计划 | — |
| [D3 先压到最短，再为阅读展开](d3-thin-then-thick.md) | D | 是 | 作者自述 + 本仓库测 | RH：可读版是原始的 1/36、紧凑版的 4 倍（测） | — |
| [E1 批量合并与智能体流水线](e1-batch-merge-and-agents.md) | E | 否 | 主流在用 | 大仓库：每分钟超过 1 个 PR（RH，报） | — |
| [E2 验证闸门](e2-verification-gate.md) | E | 否 | 主流在用 | 各规模都必需；RH 两个短版本当天完成多内核核验（报） | — |
| [E3 度量](e3-metrics.md) | E | 否 | 有工具 | 行数会被导入展开、长行、合并文件干扰（测） | — |
| [E4 构建加速](e4-build-acceleration.md) | E | 否 | 主流在用 | AFP 分布式构建 10–20 节点（报）；Mathlib module system | — |
| [E5 依赖分析](e5-dependency-analysis.md) | E | 否 | 有工具与公开数据 | Mathlib 44.8% 的定理是叶子（报）；RH 闭包 75.8%（报） | — |

## 谁用了哪些路线

●＝主要用到，○＝部分用到或在计划中，空白＝没有。前五栏是一般的实践与工作，后三栏是大仓库示例（RH）。

| 路线 | Mathlib 的维护实践 | 仓库级基准（LeanLean、Lean Refactor、Leanify） | 单定理缩短工具（LeanPolish、AXLE、TacticAnalysis） | 其他证明器（Isabelle、Coq、Mizar、Metamath） | Tau Ceti | RH 逐步清理线 | RH 机械裁剪（Shore） | RH 重写（grh-lean） |
|---|---|---|---|---|---|---|---|---|
| A1 可达性裁剪 |  | ○ |  | ●（`unused_thms`、依赖抽取） |  | ● | ● |  |
| A2 同陈述去重 |  | ○ |  | ○（概念对齐、克隆检测） |  | ● | ● |  |
| A3 linter 删除 | ● |  | ● | ●（Mizar 无关前提工具） |  | ● | ● |  |
| A4 导入收窄 | ● |  |  |  |  | ● | ● | ○ |
| A5 模块重组 | ○（拆长文件） |  |  |  |  | ● |  | ○ |
| A6 选项与性能 | ● |  | ○ |  |  | ● |  |  |
| A7 分阶段流水线 | ○ |  | ○（迭代到不动点） | ●（Metamath、Mizar 定期整库） |  |  | ● |  |
| B1 换库引理 | ○ | ● |  | ○（hammer） | ○ | ● |  | ● |
| B2 tactic 精简与自动化 | ○ | ● | ● | ●（Sledgehammer、TacticToe 最小化） |  | ○ |  | ● |
| B3 LLM 改写 |  | ● | ○ |  |  | ● |  | ○ |
| B4 证明项压缩 |  | ●（Leanify） |  | ○（证明论里的压缩） |  | ○ |  |  |
| C1 展开再分块 |  | ●（LeanLean 的依赖重组） |  | ○（切规则引入、引理挖掘） |  |  |  | ● |
| C2 陈述通用化 | ● | ○ |  | ○（层级重构） | ● |  |  | ● |
| C3 去掉包装层 | ○ | ○ |  | ○（`find_unused_assms`） |  | ● |  | ● |
| C4 移到通用库 | ● |  |  |  | ● | ○ |  | ○ |
| D1 换子论证 |  |  |  |  |  |  |  | ● |
| D2 蓝图优先 | ○ |  |  |  | ● |  |  |  |
| D3 先压后展 |  |  |  |  |  |  |  | ● |
| E1 批量合并 | ○（合并队列） |  |  |  |  | ● |  |  |
| E2 验证闸门 | ● | ● | ● | ● | ○ | ○ | ● | ● |
| E3 度量 | ○（技术债统计） | ● | ● |  |  | ● | ● |  |
| E4 构建加速 | ●（缓存、module system） |  |  | ●（AFP 分布式构建、iCoq/piCoq） |  | ● |  |  |
| E5 依赖分析 | ○（网络结构研究） |  |  | ● |  | ● | ● |  |

（grh-lean 一栏按成品推断：作者没有公开流程，C1、C2、D1 的作者说法见各自文件。）

## 推荐顺序

1. **诊断**：算上面的指标，记基线（E3）；冻结裁判（E2）；需要时量闭包（E5）。
2. **按来源决定重心**：精心维护的库以 E 层流程和 A3、A4、A6 为主；人写研究仓库以 A1、A2、B1 和上游（C4）为主；模型生成的证明以 A3、B2、B3 为主；模型生成的大型开发按下一步。
3. **A 层**：A1 → A2 → B1 → 回到 A1 → A3 → A4 → A5 → A6，每批单独验收；要向第三方证明"只做了机械变换"时按 A7 分阶段并附回执。
4. **B2，只收"更短且不更慢"的替换**；B3 只用于剩下的长而慢的证明。
5. **机械路线到顶之后决定是否重写**：C1 + C2 + C3 + D1 在独立分支上整体完成，按 D3 先压后展；已知数学按 C4、D2 交给通用库。
6. **每个发布点跑完整的 E2；E1、E4 贯穿大仓库的全程。**

## 与分层方案的对应

| [分层方案](../docs/layered-plan.md)的层级 | 主要路线 |
|---|---|
| 单个定理 | A3、A6、B1、B2、B3 |
| 单个文件 | A3、A4、C2、C3（单文件内） |
| 小仓库（每批能全量重编） | A1、A2、A7、B1，以及整体重写 C1–C3、D1、D3 |
| 大仓库 | A1、A2、A4、A5、A7、B4、C4、D2，加上 E1、E4、E5；E2 在所有层级都必需 |

各条路线的出处编号见 [`../REFERENCES.md`](../REFERENCES.md)。

[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P16]: ../REFERENCES.md
[P17]: ../REFERENCES.md
[P29]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[P48]: ../REFERENCES.md
[T15]: ../REFERENCES.md
