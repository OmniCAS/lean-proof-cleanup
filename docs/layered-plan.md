# Lean 证明清理：分层方案

**Summary (English).** A layered plan for cleaning up Lean proofs at four granularities (single theorem, single file, small repository, large repository): the goal of each layer, its means, how to check that semantics are unchanged (statements unchanged, no new axioms, via comparator and `#print axioms`), how far it can be automated, and the problems specific to large repositories (build time, dependency graph, incremental checking, parallel and distributed builds). The text is in Chinese.

配套文档：[survey.md](survey.md)（LeanPolish 与 Lean 工具）、[literature.md](literature.md)（跨系统文献）、[rh-community-cleanup.md](rh-community-cleanup.md)（Lean RH 开发的社区清理）。**优化思路的排序和工程流水线见 [ideas-and-engineering.md](ideas-and-engineering.md)**，本文只给分层目标与判断。

## 核心判断

1. **先建闸门，再选编辑器。** 清理的正确性只由"重新编译 + 陈述与公理比对"保证，与改写者是 linter、符号 pass 还是 LLM 无关。用 comparator 验证目标定理的仓库已有大半个闸门，缺的是把它和"可信闭包不变、引用根仍在、无新 `sorry`/公理"串成一个命令。
2. **按收益排序是：依赖 > 热点 > 语法。** 仓库级压缩的大头来自删掉不再需要的声明和模块，构建时间的大头来自少数热点，tactic 级 golf 排最后。可参照的量级：语法类 pass 在模型生成的证明上约省 20%（LeanPolish 在 Goedel 语料上 20.0%，Lean Refactor 在研究仓库上 >20%），在人写的 Mathlib 上不到 1%；Lean RH 开发的声明级裁剪是 9%–16%（声明数）；LeanLean 里最强智能体靠依赖重组平均 48%。
3. **符号手段先于 LLM。** linter、import 精简、替换菜单、删未用 `have` 都是确定性的、可整库并行、几乎零成本；LLM 改写每条定理是美元量级，只用于符号手段处理不了的长证明，以及为可读性抽辅助引理。
4. **小仓库与大仓库的分界是"每批改动能不能全量重编"。** 能，就每批全量构建加全部 comparator；不能（RH 量级），就必须做下游锥体增量验证、按依赖层分波并行、线性化合并。
5. **长度、构建时间、可读性分开验收。** 三者弱相关甚至冲突（`simp` 固化成 `simp only [...]` 更长但更快更稳）。主指标是构建时间和声明数，token 数次之，可读性单独人工看。

## 文献与 RH 实测带来的修正

- **每层都有跨系统先例，Lean 缺的只是仓库级未用声明工具。** 定理层有 Sledgehammer 最小化、TacticToe 最小化、Metamath `minimize_with`；文件层有 Mizar 的 irrelevant utilities、Adams 的 Tactician；仓库层有 Isabelle `unused_thms`、Mizar 定期修订、iCoq/piCoq 回归选择、AFP 分布式构建（[literature.md](literature.md)）。
- **最小化必须带"不引入新公理"的约束**（Metamath 的 `/no_new_axioms_from`），对应下面的 G4。
- **抽引理要按复用次数验收**，不能按提出了多少个（*Library Learning Doesn't*）。
- **RH 主干的经验**：文件 −66%、正文行 −21%、theorem/lemma 行 −28%，大头来自可达性裁剪、去重和合并模块；但清理后的主干至今没有端到端的 comparator 复核报告，只有"构建通过、陈述文件未改"。闸门应每批跑 comparator，而不是只在发布前。
- **行数会被 import 展开严重干扰**（RH #185 凭空多出 560 万行），验收以正文行、声明数、闭包大小和冷构建 CPU 时间为准。

## 共用的语义不变闸门

假定仓库按 comparator 的约定组织：`Challenge` 模块写目标陈述（证明为 `sorry`），`Solution` 模块给出证明，陈述用到的定义放在一个可信目录里，两边都导入它。

| 编号 | 检查 | 手段 | 何时必跑 |
|---|---|---|---|
| G0 | 编译通过，无新增 `sorry` | `lake build` 默认目标；扫 "declaration uses 'sorry'" 警告和源码 | 每批 |
| G1 | 目标定理陈述不变、公理不超出允许集、内核接受 | 全部 comparator 配置 | 每批 |
| G2 | 可信闭包冻结 | 清理前用 `leanexport` 导出一次 Challenge，之后用 `lake comparator --challenge-from-export` 对着这份冻结导出判；外加 Challenge 与可信定义目录的源码哈希不变 | 每批 |
| G3 | 引用根仍在、陈述不变 | 文档、网站、论文引用的声明清单逐条核对 | 每批 |
| G4 | 全库无新公理 | `lake check`（构建默认目标、导出、内核重放，遇到非标准公理即报错）；另扫源码里新增的 `sorry`、`native_decide`、`axiom` | 每批 |
| G5 | 性能不回退 | 每模块编译时间、峰值内存；`maxHeartbeats` 覆盖处数量不增 | 每批记录，回退则拒 |
| G6 | 独立核验 | `lake comparator --paranoid` / `lake check --paranoid`：再跑工具链自带的 `leanchecker-paranoid`、`lean4lean`、`nanoda`、`con-leche`、`con-ron` | 发布前 |

**G2 是容易漏的坑。** 清理若改了可信定义目录，Challenge 和 Solution 会一起变，按常规用法跑的 comparator 仍然通过。冻结的 Challenge 导出能堵住这个口子：判定时陈述所用的定义必须与冻结版本一致。规定可信定义与 Challenge 冻结，改它们走"改陈述"流程（人审，加数值测试之类的独立检查）。

**工具链说明。** v4.35 的 Lake 已内置 `lake comparator`、`lake check`、`lake shake`、`lake lint`，工具链 `bin/` 里带着 `leanexport`、`leanchecker`、`nanoda_bin` 等外部检查器。`lake comparator`/`lake check` 默认在 `bwrap` 沙箱里跑，只有 Linux 有；在 macOS 上检查自己的代码可以加 `--inadvisably-no-sandbox`，对不可信代码不要这样做。

## 第 1 层：单个定理

- **目标**：证明体更短、更快、对版本更稳；陈述文本不动。
- **手段**（成本递增）：
  1. 按 linter 警告删无效 tactic、未用 `have`、多余 `simpa`、未用 simp 参数、未用变量。
  2. 搜索式 tactic 固化：`simp?`、`exact?`、`apply?`、`aesop?`、`try?` 的建议写回源码，仓库不留搜索 tactic；非终结 `simp` 固化成 `simp only [...]`。
  3. 替换菜单（LeanPolish 式）：在关闭目标的叶子 tactic 处试 `omega`、`ring`、`norm_num`、`linarith`、`positivity`、`decide` 等，只收更短且通过的。Mathlib v4.35 的 TacticAnalysis 已能做"找位置"这一半（`tryAtEachStep*`、`terminalToGrind`、`mergeWithGrind`、`rwMerge`），以 Try-this 输出并报告 heartbeats 是否变慢；缺的是"批量写回 + 重编"。
  4. heartbeats：`#count_heartbeats in` 测实际用量（整文件用 `set_option trace.profiler true` 加 `trace.profiler.useHeartbeats true`），把 `maxHeartbeats` 降到实测值附近，或把慢证明拆成引理。
  5. LLM 改写：只用于长且慢、符号手段动不了的证明。
- **验证**：只改 `:=` 之后的证明体时，重编该文件即可覆盖 G0；G1、G4 按批跑。
- **自动化**：1–4 全自动；5 半自动，人看 diff。

## 第 2 层：单个文件

- **目标**：文件内无死声明、无重复、导入最小、长度可读。
- **手段**：
  1. import 精简：`#min_imports`、`lake shake`；`import Mathlib` 整库导入先换成具体模块。
  2. 文件内未用的辅助引理：以"本文件被下游用到的声明 + 保留根"为根算可达性，不可达的列为删除候选；单文件可先用 Batteries 的 `#show_unused`。
  3. 近似重复引理合并；长证明里的 `have` 抽成命名引理（为可读性，不为长度）。
  4. 超长文件拆分（Mathlib 的 longFile 阈值是 1,500 行）。
- **验证**：本文件重编之外，还要重编下游锥体，因为删 import 或删引理会影响依赖传递导入的下游文件；G1–G4。
- **自动化**：import 精简可自动修复但要下游重编；删引理是"自动出候选、重编确认"。

## 第 3 层：小仓库

判据：单机全量构建在一小时内，模块数在 10³ 以下，可以每批全量验证。几百个模块、十万行以内的研究形式化通常属于这一层。

- **目标**：以保留根为中心的最小闭包，无死代码、无重复，构建时间下降。
- **步骤**：
  1. **基线**：冷构建总时间与每模块时间、声明数、正文行、comparator 全过。
  2. **定保留根**：comparator 各配置的 `theorem_names` ∪ 文档引用的声明 ∪ Challenge 闭包。
  3. **依赖裁剪**：声明级可达性 → 删不可达声明 → 删空文件和不可达模块。
  4. **与 Mathlib 对齐**：对每条自有引理在隐藏自身的情况下试 `exact?`/`apply?`，一步可证的换成 Mathlib 引理；同型引理合并。
  5. **热点**：按每模块时间和 `maxHeartbeats` 处排序先处理。
  6. **全库符号 pass**：linter 修复、替换菜单、删未用 `have`，迭代到不动点。
  7. **剩余热点和可读性**：LLM 处理，人审。
- **验证**：每批全量构建加 G0–G5；一晚可跑完，按小批提交 PR，PR 里附删掉的声明列表、改动的证明、时间变化。
- **自动化**：1–6 可做成无人值守的流水线；7 和合并要人。

## 第 4 层：大仓库

判据：全量构建以小时计，模块 10⁴–10⁵（Lean RH 开发的原始归档有 174,793 个 `.lean` 文件）。小仓库的步骤都适用，额外的问题是验证太贵：

1. **构建时间**：每个候选都全量重编不可行。改成"一个模块内所有通过局部检查的编辑一起应用，只重编该模块的下游锥体；失败就二分"。
2. **依赖图**：先在 import 图上删不可达模块（最便宜，RH #45 一次删 1.1 万个文件），再在声明图上裁剪。声明图从 `.olean` 或导出建，不靠文本匹配（RH issue #3 的文本估计把可删量高估了几倍）；内核图之外，elaboration 用到的实例、simp 引理要靠重编确认。
3. **增量检查**：不用 module system 时，证明一变下游就重编；module system 把定理证明排除在公开接口之外，手册明确说这类改动不触发文件外重编。大仓库清理前应先迁到 module system（Mathlib 已全量使用）。
4. **并行**：符号 pass 按模块天然并行；冲突来自同一锥体上的编辑，所以按拓扑层分波，从叶子往根。分布式构建可以沿 import 图分片、产物放内容寻址存储、按每模块实测耗时排程，见 [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build)。
5. **合并顺序**：多条清理线并行时互相覆盖（RH #66 覆盖了此前的清理）。要线性化合并，每批针对当前主干重放。
6. **架构级重组**：LeanLean 显示仓库级压缩靠重组依赖，这需要数学判断；用智能体出方案、人审，单独分支做。

## 对中小型研究仓库的判断

### 马上可用（不需要开发或只需小脚本）

1. **闸门脚本**：串起 G0–G4（构建、全部 comparator 配置、冻结的 Challenge 导出、可信目录哈希、引用清单核对、`lake check`、禁用 token 扫描）。先于任何清理落地。
2. **收割已有警告，再打开标准集合。** v4.35 下 `linter.unusedVariables`、`linter.unnecessarySimpa`、`linter.unusedSimpArgs`（Lean 核心）和 `linter.unusedTactic`（Mathlib）默认就开着，构建日志里已经有这些警告，先统计并用 Mathlib 的 `fix_unused.py`、`fix_unused_simp_args.py` 机械修复。再在 lakefile 加 `weak.linter.mathlibStandardSet = true`，拿到 `flexible`、`multiGoal`、`style.maxHeartbeats`、`longFile` 等警告。未用的 `have`/`suffices` 由 Batteries 的环境 linter `unusedHavesSuffices` 报告，走 `#lint` 或 `lake lint`。
3. **import 精简**：`lake shake --fix` 加 `#min_imports`，先处理整库导入。
4. **heartbeats 清点**：逐处 `#count_heartbeats in` 测实际值，降下来或拆分。高 heartbeat 覆盖往往集中在少数计算证书类文件里，是构建时间最可能的热点。
5. 仓库里不留搜索 tactic（`exact?`、`simp?` 等）。

### 需要自建

| 工具 | 作用 | 规模 | 优先级 |
|---|---|---|---|
| 声明级可达性 | 以保留根遍历常量依赖，输出可删声明并按文件汇总 | Lean 元程序，几百行 | 高：决定依赖裁剪能省多少 |
| Try-this 批量写回 | 打开 TacticAnalysis 的 `tryAtEachStep*`、`terminalToGrind` 等，收集建议，按"更短且不更慢"筛选、写回、重编确认；写回可先试实验工具 Skimmer | 小 | 中 |
| Mathlib 对齐 | 每条引理试 `exact?`，列替换候选 | 小脚本，计算量大 | 中 |
| 热点报告 | 每模块编译时间 + 每声明 heartbeats | 小 | 高 |
| 增量验证调度 | 下游锥体重编、按拓扑层分波、失败二分 | 较大 | 只在面向大仓库时做 |

### 暂不做

- 训练自己的编辑模型（ProofOptimizer、LeanPolish 的 7B 编辑器）：投入大，对人写或前沿证明器写的长证明收益小（LeanPolish 在 AxiomProver 证明上 1%–2%）。
- 整库 LLM 改写：按每条定理约 3 美元计，几千条定理就是上万美元；只做热点。
- 把私有仓库发给托管服务（如 AXLE）：先看能否本地运行开源引擎。

具体的待解决问题与建议答案见 [open-problems.md](open-problems.md)。
