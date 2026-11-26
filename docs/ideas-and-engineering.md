# Lean 证明清理：优化思路与工程流水线

**Summary (English).** Fourteen concrete cleanup ideas for Lean repositories of any scale and provenance, ranked by gain, safety and cost (each with source, granularity, gain and what keeps it correct), and an engineering pipeline for running cleanup on a repository, especially a large one: dependency graph and reachability-based removal, deduplication against Mathlib and within the repository, import minimisation, batching, incremental and distributed builds, a guard on every change, CI and merge order, and what to measure. The text is in Chinese.

适用于任何规模与来源的 Lean 仓库；按规模（单个定理 / 文件 / 小仓库 / 大仓库）与来源（精心维护的库 / 人写研究仓库 / 模型生成的证明 / 模型生成的大型开发）选路线的表见 [`../methods/README.md`](../methods/README.md)。来源见 [literature.md](literature.md)（跨系统文献）、[survey.md](survey.md)（LeanPolish 与 Lean 工具）与 [`../cases/`](../cases/README.md)（按规模 × 来源索引的案例）。下文里带 PR 编号或 Zulip 链接的数字都来自大仓库示例（Lean RH 开发，模型生成），只说明那一格。分层的目标与判断见 [layered-plan.md](layered-plan.md)。

## 核心判断

1. **先冻结裁判，再动代码。** 每一步的正确性都靠"陈述不变、公理不增、内核接受"这一个判定；判定所依据的文件（Challenge、comparator 配置、导出目标）必须先冻结。Metamath 的最小化显式禁止引入新公理；大仓库示例（RH）用 CI 禁止任何 PR 改这些文件，这是放手自动化的前提。
2. **收益的大小与顺序取决于来源。** 对以几个最终定理为目标的仓库，大头是删不可达 → 去重 → 换 Mathlib → 再删不可达，都是机械的、可脚本化（大仓库示例 RH：删未用声明 −16.2%、去重约 1.7 万处）；对模型生成的竞赛证明，大头在证明内部的符号 pass（约 −20%）；对精心维护的库，几乎只剩流程与构建上的收益（LeanPolish 在 Mathlib 上 0.53%）。
3. **每类变换单独成批，按依赖锥切片，批内全自动、批间串行合并。** 验证的单位是"被改模块加上它的下游锥体"；只改证明体时，module system 能把下游重编截掉。
4. **度量要选不会被 import 展开、长行或合并文件干扰的指标。** 反映内容多少的是正文行、命题个数和依赖闭包大小，反映成本的是冷构建 CPU 小时和峰值内存（大仓库示例 RH：`import Mathlib` 展开一次多出约 560 万行，合并模块让文件数降了一半多而内容几乎不变）。动手前先算结构指标，判断来源（[`../cases/profiles.md`](../cases/profiles.md)）。

## 一、优化思路（按"收益 × 安全 ÷ 成本"排序）

| # | 思路 | 来源 | 粒度 | 收益 | 正确性靠什么 |
|---|---|---|---|---|---|
| 1 | **冻结裁判**：清理前导出一次 Challenge，之后用 `lake comparator --challenge-from-export` 判；CI 禁止改 Challenge 与 comparator 文件；最小化时禁止引入新公理 | RH `challenge-files.yml`；Lake v4.35；Metamath `minimize_with /no_new_axioms_from` | 仓库 | 无直接收益，是其余各项的前提 | 本身就是闸门 |
| 2 | **按依赖闭包删死代码**：先在 import 图上删不可达模块，再在内核证明项图上删未用声明 | RH #45、#66、#55 与 Shore S1；Isabelle `unused_thms`；Alama 等 CICM 2012 | 仓库 | RH：S1 声明 −16.2%、行 −12.8%；#55 作者报构建 −18%、峰值内存 −41% | 重编（elaboration 用到的实例、simp 引理、notation 不在证明项里）+ comparator |
| 3 | **完全相同的声明只留一份**：同陈述的定理、同类型同值的定义，其余删掉或改成 `alias`，引用改指保留的那份 | RH #295、#92；Clary 的导出实验；HOL 库概念对齐 | 仓库 | RH #295 约 1.7 万处；#92 一次替换让 112 个模块变得不可达 | 内核判定类型相等（RH 要求新旧两个工具链都相等）、重编、comparator；之后重跑 #2 |
| 4 | **换成 Mathlib 引理**：自有引理与 Mathlib 同型时改用 Mathlib 的名字；在已导入的文件里优先做 | RH #295、#389、#221；Clary：约 6.6 万个定理已在 Mathlib/Core | 文件到仓库 | 声明、行；还能截断依赖锥 | 类型相等或隐藏自身后 `exact?` 一步关闭；重编；检查没有因此新增导入 |
| 5 | **删掉没被证明也没被使用的陈述与字段**：文献陈述、从未实例化的结构、死字段、从未用到的假设 | RH #318、Righi 的字段活性；Isabelle `find_unused_assms` | 仓库 | RH #318：1,370 个声明，且拖着约 6,000 个文件的导入 | 闭包确认未被用到；最终陈述不变；comparator |
| 6 | **linter 驱动的删除**：未用 simp 参数、不可达 tactic、无效 tactic、未用 `have`、未用变量；用脚本批量修 | Lean/Mathlib linter、`fix_unused*.py`；RH #67/#243；AXLE；ProofOptimizer 的符号阶段 | 定理 | RH #243 约 11 万行删除、相关警告 −94%；LeanPolish 的删除类编辑占 51.6% | 只改证明体；重编该文件 |
| 7 | **import 精简**：`lake shake --fix`、`#min_imports`；module system 下收窄 `public import` | Lake；RH #9、#4（agitate）、Shore S4；Carlson：75.3 万条导入里 36.7 万条被其他导入蕴含 | 文件到仓库 | 构建时间（RH 里加载 import 约占一半 CPU）；减少重编连锁 | 重编下游；确认闭包没有因此变大 |
| 8 | **还原机器展开的项**：显式类型类项、完全展开的大项改回正常 elaboration | RH #57（5 个文件 5,412 → 522 行）、#60（8,029 → 45 行，编译 86 → 71 秒） | 定理 | 行数大降，编译小降 | 与原 `.olean` 的陈述做 `isDefEq`；重编 |
| 9 | **收拢薄包装、合并小模块**：只转发一个声明的模块删掉并改引用；小模块沿 import 图合并 | RH #324、#58/#61、#44 | 仓库 | RH 文件 −58%；降低每文件开销 | 全由脚本生成、在新基线上重跑；重编（合并后约 0.7% 出现名字冲突） |
| 10 | **heartbeat 清点与下调**：逐处 `#count_heartbeats in`，删掉或降低 `maxHeartbeats`、`synthInstance.*` 覆盖 | RH #9（366 处）、主干上约 8,400 处待清点 | 定理 | 构建时间、对版本更稳 | 构建通过；计时不回退 |
| 11 | **带计时闸门的自动替换**：TacticAnalysis `tryAtEachStep*`、`terminalToGrind`、LeanPolish 替换菜单、hammer；只收"更短且不更慢"的 | LeanPolish；Mathlib TacticAnalysis；LeanHammer；RH：26 条 `grind` 建议里 22 条更慢 | 定理 | 生成代码上约 20% token；人写代码不到 1% | 重编 + heartbeat 对比 |
| 12 | **抽引理、合并重复片段** | Leanify；Vyskočil 等 LPAR 2010；切规则引入；Kaliszyk–Urban；RH #82（526 → 112 行） | 文件 | 行数、可读性 | 重编；按实际复用次数验收（*Library Learning Doesn't*） |
| 13 | **LLM 改写剩余热点**：长且慢、符号手段动不了的证明 | ImProver、ProofOptimizer、Lean Refactor、Proof-Refactor | 定理 | 研究仓库约 20%；每条定理美元量级 | 编译 + comparator + 人审 |
| 14 | **按蓝图重写** | Anthropic FLT 第二版（约 1/7）；Tau Ceti；Mario 的"200 页"目标 | 仓库 | 最大 | 新形式化需单独审阅；已超出清理 |

## 二、工程流水线

### 1. 依赖图与可达性删除

- **两张图。** import 图从文件头或 `.olean` 读，便宜，用来删整个不可达模块。声明图从内核导出建：用 `leanexport` 导出 NDJSON，或写 Lean 元程序遍历 `Environment` 中每个常量的类型与值（`Expr.getUsedConstants`）。Shore 用三套独立构建的 `.olean` 得到了同一闭包，说明这一步可复现。
- **根。** 最终定理（comparator 的 `theorem_names`），加上保留清单：网站或论文引用的声明、对外 API、`definition_names`。
- **闭包之外不一定能删。** 不出现在证明项里却是编译所需的：实例、simp 与 ext 引理、notation、macro、elab、`deriving` 生成物、结构字段。做法是先删、再重编，失败的放回保留清单；RH 的 #55 保留了被保留文件里所有的 `simp`/`rfl` 引理和实例。
- **输出。** 每个文件的"被用声明数 / 总声明数 / 行数"，按目录汇总；删除按目录分批。
- **反复做。** 去重、换 Mathlib、删陈述之后都会产生新的不可达部分（RH #92 一次替换就让 112 个模块不可达），所以每轮之后重算。

### 2. 去重

- **键。** 规范化后的类型（宇宙参数、绑定变量改名统一）做哈希分组；定义再加上值。RH #295 只在新旧两个工具链都判定类型相等时才合并，并对因 private import 看不到的情况保留原证明（686 个）。
- **选代表。** Mathlib/Core 优先；其次选在 import 顺序中最早、被引用最多的那份；名字还要用的地方改成 `alias`。
- **对 Mathlib。** 为 Mathlib 建同样的类型索引；只在已导入相应模块的文件里替换，避免增加导入；否则要确认新增导入不让闭包变大。
- **近似重复**（只差绑定显式性、差一个可推出的假设）先不自动合并，列清单人工处理；RH 里有过因加载顺序不同而选出不同代表的问题。

### 3. import 精简

- 删除类工作之后再做（删声明会让很多导入变得多余）。
- `lake shake --fix`，保守选项 `--keep-implied`、`--keep-public`；`--explain` 用来解释为什么某条导入不能删。逐文件用 `#min_imports` 抽查。
- module system 下区分 `public import` 和普通 `import`：只改证明体的文件，下游不重编，这是大仓库增量验证的关键。
- 验收：下游重编通过；从最终定理出发的 import 闭包没有变大。

### 4. 批处理：每批都能单独验证

- **一批只做一类变换**（只删除、只去重、只改 import、只改证明体），不和升级工具链混在一起。
- **变换脚本化、可重生成。** RH #324 明确要求在新基线上重跑脚本，而不是 rebase 生成的提交；这样冲突时直接重新生成。
- **按依赖锥切片。** 同一批里的改动尽量落在互不相交的模块集合上；验证单位是"被改模块 + 下游锥体"。
- **串联合并。** 仿照 RH 的批次：把候选 PR 按编号用 `git merge-tree` 依次叠到主干上，留下能干净合并的；冲突只做机械解决，并对改动模块及其直接导入者先编译。失败时二分找出坏的那个 PR。
- **删除和改写分开提交。** 只删不改的 PR 审起来快；改写证明的 PR 要看 diff。

### 5. 增量重编与并行、分布式构建

- **两级检查。** 快速检查只编译改动模块及其直接导入者（RH 的 quick check、按模块直接调用 `lean` 的构建后端）；合并前对整批做一次完整构建（可对着缓存增量）。
- **截断连锁。** module system 让"只改证明"不触发下游重编；不用 module system 时，任何证明改动都会让下游全部重编。
- **回归选择。** 借鉴 iCoq/piCoq：按依赖只重查受影响的模块和证明。
- **分布式。** 沿 import 图分片，产物放内容寻址存储，按每模块实测耗时排程（例如 [OmniCAS/lean-distributed-build][ldb] 里的 lakeshard：`plan`/`build`/`history.json`，以及 `verify` 里的 `leanchecker` 重放）；AFP 用 10–20 节点集群把构建压回 45 分钟以内。
- **成本参照（RH）。** 冷构建约 103 CPU 小时（192 核）；24 线程整机约 6 小时；原始版本 paranoid 内核重放约 69 小时；comparator 单线程。端到端验证不能每批都做，要定期做。

### 6. 每次改动的守卫

| 频率 | 检查 |
|---|---|
| 每个改动 | 改动模块及下游编译通过；源码不新增 `sorry`、`admit`、`axiom`、`native_decide`；不改 Challenge、comparator 配置、最终定理所在文件 |
| 每批 | 完整构建；`lake comparator` 对着冻结的 Challenge 导出（陈述、公理、内核）；最终定理的 `#print axioms`；保留清单里的声明都还在、陈述未变 |
| 定期 / 发布前 | `lake check --paranoid` 或 comparator 加外部内核（nanoda、lean4lean、con-leche、con-ron）；冷构建复测 |

RH 的教训：主干的守卫只到"构建通过 + 陈述文件未改"，完整 comparator 只在原始版本上跑过，清理后的主干至今没有端到端复核；应把"对冻结导出跑 comparator"放进每批，而不是只放在发布前。

### 7. CI 与合并流程，以及顺序

**顺序（便宜且安全的在前）：**

0. 冻结裁判，记录基线指标。
1. 在 import 图上删不可达模块。
2. 按内核闭包删未用声明。
3. 完全相同的声明去重，换成 Mathlib 引理。
4. 删没被证明、没被使用的陈述与字段；回到 1–2 重算闭包。
5. linter 驱动的删除（只改证明体）。
6. import 精简（删完内容之后再做）。
7. 收拢薄包装、合并小模块（为构建性能；脚本可在新基线上重跑，所以放在删除之后）。
8. heartbeat 下调。
9. 带计时闸门的自动替换。
10. 抽引理和 LLM 改写（人审）。

工具链升级单独一条线、单独验收；RH 社区的经验是"先裁剪再移植"，并行做会互相覆盖（#66 覆盖了此前的清理）。

**合并流程：** 打标签 → 快速检查 → 进批次（merge-tree 串联）→ 对着缓存完整构建 → 每批守卫 → 合并；主干保持全绿；脚本化变换在新基线上重新生成；批次说明里列出包含的 PR、检查项和指标变化。

### 8. 度量什么

| 类别 | 指标 | 说明 |
|---|---|---|
| 内容 | 正文行（去空行、import、`module`）、内核层面的声明数、依赖闭包大小（声明、文件、行） | 主指标；闭包大小也是删死代码的下限 |
| 成本 | 冷构建 CPU 小时、固定硬件上的墙钟时间、关键路径、每模块峰值内存、内核重放时间、导出大小 | 主指标；固定硬件和缓存策略才可比 |
| 结构 | 文件数、import 行、薄包装数、heartbeat 覆盖处数、linter 警告数 | 次要；文件数和 import 行会被合并、展开严重干扰，不能单独作目标 |
| 质量 | 抽样人工审读；抽出的引理被复用的次数 | 不以 token 数为目标（RH 社区的 Loeffler 反复强调） |

每批记录相对于基线的变化，写进批次说明。

## 三、落到中小型仓库

- 几百个模块、十万行以内的研究形式化属于小仓库：每批都能全量构建加跑全部 comparator 配置。
- 先做 #1（冻结 Challenge 导出，加上可信定义目录的哈希）、#6（收割已有 linter 警告）、#7（`lake shake`）、#10（高 heartbeat 覆盖处）；再写声明级可达性工具，做 #2–#4。
- 大仓库那一套（锥体切片、分布式验证、定期端到端复核）适合先在公开的大仓库（如 RH 社区仓库）上做实验。

[ldb]: https://github.com/OmniCAS/lean-distributed-build
