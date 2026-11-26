# Lean 证明清理与简化：调研

**Summary (English).** LeanPolish (an ICLR 2027 submission) and its contemporaries (LeanLean, Leanify, AXLE, Lean Refactor, Proof-Refactor, ProofOptimizer, ImProver), and the built-in Lean / Mathlib v4.35 tools for cleanup: linters, TacticAnalysis, `lake shake`, `lake comparator`, `lake check`, with granularity, correctness guarantee and cost. The text is in Chinese.

快照 2026-11-25。内容：LeanPolish 及同期 ICLR 2027 投稿，Lean / Mathlib 现成工具的粒度与正确性保证。跨系统的论文（Coq/Rocq、Isabelle、HOL、Mizar、Metamath、证明论）按方法与粒度整理在 [literature.md](literature.md)；Lean RH 开发的社区清理在 [rh-community-cleanup.md](../cases/rh/rh-community-cleanup.md)；优化思路与工程流水线在 [ideas-and-engineering.md](ideas-and-engineering.md)。编号出处见 [`../REFERENCES.md`](../REFERENCES.md)。

## 0. 核心判断

1. **LeanPolish 是 ICLR 2027 的在审投稿**（不是已接收论文）：arXiv [2609.38384][lp-arxiv]，OpenReview forum `yRmdNlDhJS`，标注为 "ICLR 2027 Conference Submission"。它本质上是一个**符号式、局部、逐处编译把关**的压缩器，加一份已验证编辑的数据集；LLM 只是在它之上做排序和补充。
2. **收益取决于代码来源。** 同一个 LeanPolish 管线：Mathlib（人写）token 只省 0.53%，Goedel-Prover 生成的证明省 20.0%，miniF2F 省 22.6%（[headline.json][lp-headline]）。模型写成的研究仓库应按"生成代码"预期。
3. **仓库级的大头在依赖结构，不在语法。** LeanLean（ICLR 2027 投稿，64 个真实仓库）报告压缩主要来自"让原本用到的声明变得不再需要"，语法优化只有最强模型才有明显贡献。这与 Lean RH 开发的社区清理一致（删不可达模块、声明级裁剪、同型去重，见 [rh-community-cleanup.md](../cases/rh/rh-community-cleanup.md)）。
4. **删除类和替换类两种符号 pass 互补。** LeanPolish（替换菜单）与 AXLE `simplify_theorems`（删无用 tactic/have）在 miniF2F 上分别省 29.8% 和 27.1%，串起来省 35.9%（[AXLE 对比][lp-axle]）。Mathlib 的 linter 已经覆盖了删除类的大部分，成本最低。
5. **正确性靠重新编译加陈述比对，不靠编辑器。** 所有可靠的工具都是"生成候选 → 重新 elaborate 并过内核 → 检查陈述和公理不变"。用 comparator 验证目标定理的仓库已经有这个闸门，可以直接接任何编辑器。

## 1. LeanPolish

| 项 | 内容 |
|---|---|
| 论文 | Pauline Bourigault（Imperial College London），*LeanPolish: Verified Supervision for Lean Proof Compression*，arXiv [2609.38384][lp-arxiv]，2026-09-29 v1。OpenReview 记录为 ICLR 2027 Conference Submission，[forum `yRmdNlDhJS`][or-lp]（论坛页要过人机验证，审稿意见未读）。 |
| 代码与数据 | [paulinebourigault/leanpolish][lp-gh]（Apache-2.0，固定 Lean / Mathlib v4.21.0）；数据集 [leanpolish-anon/lean-proof-compression][lp-hf]（编辑记录、候选池、LoRA 适配器）。 |
| 方法 | 四个阶段循环到不动点：① **tactic 替换**：在每个关闭目标的叶子 tactic 处，按固定顺序试 15 个候选（`rfl`、`ring`、`abel`、`norm_num`、`norm_cast`、`positivity`、`decide`、`linarith`、`omega`、`field_simp`、`contradiction`、`ext`、`gcongr`、`tauto`、`simp?` 压成 `simp only [...]`），只接受更短的；在 InfoTree 保存的证明状态上试，昂贵 tactic 限时 5 秒；不替换 `exact`/`rw`/`apply`/`calc` 等显式项。② **局部事实合并**：把近似重复的 `have` 反统一成一个（只占 0.8% 的编辑）。③ **删未用 `have`**：用使用图找后面没被引用的 `have`。④ **删不可达代码**（`<;>` 链等）。 |
| 正确性 | 每次编辑后重新 elaborate 并在进程内过内核；基准语料再用独立的 `lake env lean` 进程从头编译；整体失败时保留能编译的子集。只改证明体，所以陈述不变。AXLE 对比实验另做了审计：陈述一致、无新增 `sorry`/`admit`/`axiom`/`native_decide`、公理只有 `propext`、`Classical.choice`、`Quot.sound`（[audit][lp-axle]）。 |
| 数据 | 33,402 条被接受的编辑、65,596 条同一位置的失败尝试。来源：Mathlib 子集（人写）、Goedel-Workbook、PutnamBench、miniF2F、Putnam 2025（AxiomProver）等。编辑构成：删除 51.6%、tactic 替换 47.6%、合并 0.8%。 |
| 结果 | 符号 pass 迭代到不动点，miniF2F 节省从 19.7% 升到 27.5%，高于他们测的神经混合方案。训练出的排序器在留出状态上 70.1% 选中最优候选（最强冻结基线 36.9%）；每个状态只做一次 Lean 检查时回收穷举节省的 81%。用其编辑对微调后，DeepSeek-Prover 单样本能缩短 58% 的 miniF2F 证明（原 12%），省 8.6% token（原 3.4%）；对更长的 PutnamBench 证明不再有效。前沿证明器的长证明上收益很小：AxiomProver 1.3–1.8%，Aristotle IMO 题 0.3–0.5%（[frontier][lp-frontier]）。全量 Goedel-Workbook 约 96 核跑一小时（摘要转述，未逐字核实）。 |
| 局限 | 作者明说输出不保证最短、不保证更易读。只在单文件内做局部编辑，不改陈述、不删声明、不跨文件抽引理；评测几乎全是竞赛题；人写的 Mathlib 几乎压不动；固定在 Lean 4.21。 |
| 借鉴价值 | 方法可以借鉴，代码不能直接用在新版本上（固定在 4.21，换到 v4.35 要移植 InfoTree 相关部分）。价值在于"替换菜单 + 逐处编译 + 迭代到不动点"这套做法，以及它证明了这类 pass 与删除类 pass 叠加有效。 |

## 2. 同期相关工作（2025–2026，按与仓库级清理的相关度排序）

| 工作 | 状态 | 粒度 | 做法与正确性 | 关键数字 | 成本 |
|---|---|---|---|---|---|
| **LeanLean**：*Benchmarking Repository-Scale Lean Proof Compression* | ICLR 2027 投稿（[OpenReview `LssUgDHqQj`][or-leanlean]），全文未读 | 仓库 | 64 个真实 Lean 仓库（最多 17.4 万行），智能体 12 小时内缩小仓库，主定理保持有效；三层：简化数学论证、重组依赖（删/加声明）、语法优化 | 最佳模型 Opus 5 平均压缩分 48.3%，小模型 <25%；大头来自依赖重组。社交媒体转述的新榜单数字（Opus 5.5 64.3%）未核实（[digg][leanlean-digg]） | 每仓库 12 小时智能体 |
| **Leanify**：*Verified Proof Compression and Reusable Lemma Discovery* | ICLR 2027 投稿（[OpenReview `ikCmxFDkbM`][or-leanify]），全文未读 | 证明集合 / 仓库 | 在保留原陈述的前提下压缩一组证明，以证明项大小为指标；配一个引理发现管线 | OpenAI 两个结果的 Lean 证明压缩 94.2% 和最高 99.2%（证明项大小）；越往后的压缩阶段产生的非平凡引理越多，FLT 相关结果一起压缩时引理复用更广 | 智能体，未报告 |
| **AXLE**（Axiom Lean Engine） | ICML 2026 AI4Math Workshop Oral；arXiv 2606.26442；[文档][axle-docs] | 定理 / 文件 | 托管服务，14 个元编程工具。`simplify_theorems` 默认做 `remove_unused_tactics`、`rename_unused_vars`（改成 `_`，不改签名）、`remove_unused_haves`，可选 `apply_try_this`、`apply_linter_hints`；另有 `verify_proof`、`check`、`extract_decls`、`repair_proofs`、`have2lemma`、`normalize` 等 | 在 LeanPolish 的对比里 PutnamBench 省 25.6%（几乎全是死代码） | 免费托管；有开源仓库 [axiom-lean-engine][axle-gh]（许可证未核实）。**发送代码到外部服务，私有仓库需先征得同意** |
| **Lean Refactor** | NeurIPS 2026 poster；arXiv [2605.20244][refactor] | 定理 | 冻结 LLM 智能体 + 检索带版本标注的重构策略库；编译把关；多目标（长度、编译时间、版本兼容） | 竞赛题 token 压缩 >70%，研究仓库 >20%，编译时间最多降 60%；长度与编译时间弱相关 | 每题美元量级 |
| **Proof-Refactor** | ICML 2026 AI4Math Workshop；arXiv [2606.03743][proofrefactor] | 定理 → 辅助声明 | Claude Code + lean-lsp-mcp + 抽取工具：抽片段、设计辅助声明、证明、修回原证明 | LLM 评审的重构分数提高，主要在签名质量和可读性；**不以长度为目标** | 智能体 |
| **ProofOptimizer** | ICLR 2026；arXiv [2510.15700][optimizer] | 定理 | 符号 linter 先删冗余 + 7B 模型（专家迭代、RL）+ 推理时迭代缩短；编译把关 | miniF2F −87%、PutnamBench −57%；约 2/3 证明编译快 ≥10% | 7B，可本地跑 |
| **ImProver / ImProver 2** | ICLR 2025 / arXiv 2026（[2410.04753][improver]、[2605.22885][improver2]） | 定理 | LLM 按自定义指标（长度、可读性、依赖数、模块度）改写；编译把关 | Mathlib 上长度几乎不降（ImProver 2 长度 0.016），依赖数、模块度有改进 | LLM 调用 |
| DreamProver、MathlibLemma | arXiv 2604.26311；ICML 2026 | 库 | 证明过程中积累并裁剪引理库；挖掘 Mathlib 缺的常识引理 | MathlibLemma 1,506 条已验证引理，少量合入 Mathlib | — |

**读法**：单定理的 LLM 改写在竞赛题上数字很大，在人写库上很小；仓库级（LeanLean、Leanify）才是大仓库清理关心的场景，但两篇都还在审、全文未读，数字只来自摘要。

## 3. Lean / Mathlib 现成工具

以下按 Lean / Mathlib v4.35.0 的源码（elan 安装的工具链与 Lake 拉下的 Mathlib）核对，另对照 GitHub master 和 v4.22–v4.37 的发布说明复核，链接指向对应 tag。"自动修复"指工具本身会改源码或给出可一键应用的 Try-this。所有改写都要重新编译才算数，linter 只是基于语法和 InfoTree 的诊断。

**2025 年以来的变化**（影响工具选择）：`lake shake`、`leanchecker` 在 v4.28 进入核心；`lake lint` 在 v4.31 有了内置环境 linter；`lake check`、`lake comparator` 在 v4.35 加入并捆绑 lean4lean、nanoda、con-leche、con-ron，独立的 `leanprover/comparator` 和 `lean4checker` 仓库随之弃用；module system 在 v4.27 稳定。当前 Lean 稳定版 v4.36.0，Mathlib master 在 v4.37.0-rc1。

### 3.1 linter（定理、文件粒度；成本 = 正常构建）

| 工具 | 作用 | 默认 | 自动修复 | 链接 |
|---|---|---|---|---|
| `linter.unusedVariables`（核心） | 未用变量、未用 `have` 名 | 开 | Mathlib `scripts/fix_unused.py` 读构建日志改成 `_` | [UnusedVariables][l-unusedvars] · [fix_unused][s-fixunused] |
| `linter.unusedSimpArgs`（核心） | `simp [...]` 里没用到的参数 | 开 | `scripts/fix_unused_simp_args.py` | [Simp.lean][l-simp] · [脚本][s-fixsimp] |
| `linter.unnecessarySimpa`、`unnecessaryRwa`（核心） | `simpa`/`rwa` 可换成 `simp`/`rw` | 开 | 代码动作提示 | [Simpa.lean][l-simpa] |
| `linter.unusedSectionVars`（核心） | 自动引入却没用到的 section 变量 | 开 | 否 | [MutualDef.lean][l-mutualdef] |
| `linter.extra.unreachableTactic`、`unnecessarySeqFocus` 等（核心 `Lean/Linter/Extra`） | 永不执行的 tactic、多余的 `<;>` | 关 | 否 | [Extra][l-extra] |
| `linter.unusedTactic`（Mathlib） | 不改变目标的 tactic | 开 | 否 | [UnusedTactic][l-unusedtactic] |
| `linter.mathlibStandardSet`（Mathlib 风格集合） | `flexible`（非终结 `simp` 后接依赖其结果的 tactic，附 `simp only [...]` 的 Try-this）、`multiGoal`、`style.maxHeartbeats`（要求 `maxHeartbeats` 带注释）、`longFile`（Mathlib 内 1,500 行）、`setOption`、`header`、`unusedDecidableInType` 等 | 下游关；lakefile 加 `weak.linter.mathlibStandardSet = true` 打开 | 否 | [Init.lean][l-init] · [Style][l-style] |
| 环境 linter：`#lint` 或 `lake lint`（Batteries `@[env_linter]`，核心框架在 `Lean/Linter/EnvLinter`） | 逐声明检查已 elaborate 的环境：**`unusedHavesSuffices`**（未用的 `have`/`suffices`，是环境 linter 而不是 `linter.*` 选项）、`unusedArguments`、`simpNF`（重跑 simp，慢）、`synTaut`、`docBlame` 等 | 按需，要全量构建 | `lake lint --record-exceptions` 插入 `set_option … false in` | [Batteries Misc][b-lint] · [Lake Help][lake-help] |

### 3.2 TacticAnalysis 与 Try-this 写回（定理粒度；成本 = 每个目标多跑一次候选 tactic）

Mathlib 的 tactic 分析框架（Baanen、van de Meent，2025）在 InfoTree 上回放证明，逐步试替换，用 Try-this 报告结果，并比较 heartbeats。功能上等于 LeanPolish 替换菜单的"找位置"部分。[Declarations.lean][ta]

| 选项 | 作用 | 默认 |
|---|---|---|
| `rwaSuggestion`、`introMerge` | `rw` 后接 `assumption` 合成 `rwa`；合并相邻 `intro` | 开 |
| `rwMerge`、`mergeWithGrind`、`terminalToGrind` | 合并相邻 `rw`；`tac; grind` 合成 `grind`；末尾一串 tactic 换成 `grind`（变慢时警告） | 关 |
| `tryAtEachStepGrind`/`SimpAll`/`Aesop`、`...Suggestions`、`tryAtEachStepFromEnv` | 在每一步试 `grind`、`simp_all`、`aesop` 或环境变量 `TRY_AT_EACH_STEP_TACTIC` 指定的任意 tactic，报告在哪里能直接关掉目标；`tryAtEachStep.fraction` 抽样 | 关 |
| `omegaToLia`、`verifyGrind*` | `omega` 换 `lia`；校验 `grind?` 建议确实成立 | 关 |

写回：实验工具 [Skimmer][skimmer]（Thomas Murrills）通过 `lake build <tgt>:applyCurrentTryThis` 批量应用库里的 Try-this 建议，Mathlib 带了启动脚本 [runSkimmer.sh][s-skimmer]。交互式的 `simp?`、`simp_all?`、`exact?`、`apply?`、`rw?`、`aesop?`、`hint`、`grind?`（给出 `grind only [...]`）、`grind => finish?`（给出不含搜索的 grind 脚本）、`try?`（核心，[Try.lean][try]，`only := true` 时给出 `simp only`/`grind only`）同样输出 Try-this；`X says Y`（[Says][says]）把搜索结果固定下来，`says.verify` 在 CI 里复查。`omega`、`lia`、`decide +kernel` 是判定过程，不给建议。[LeanHammer][hammer] 的 `hammer` 搜索证明并给出替换脚本，支持 v4.20–v4.35。

### 3.3 import（文件、仓库粒度；成本 = 一次构建后读 `.olean`）

| 工具 | 作用 | 自动修复 | 链接 |
|---|---|---|---|
| `lake shake`（v4.35 Lake 内置） | 分析 `.olean` 推断每个文件真正需要的导入；`--explain` 列出每个导入贡献了哪些常量；`--keep-implied`、`--keep-public` 等控制保守程度；源码注释 `-- shake: keep` 保留 | `--fix` 直接改源码 | [Lake Help][lake-help] |
| `#min_imports`（import-graph / Mathlib）、`#redundant_imports`、`#find_home for <cmd>` | 文件或单条命令的最小导入；冗余导入；声明可以挪去哪个模块 | 否 | [MinImports][minimports] · [import-graph][importgraph] |
| `lake exe graph`、`lake exe unused_transitive_imports`（import-graph） | 导入图（dot/html）；传递意义上没用的导入 | 否 | [import-graph][importgraph] |
| module system（`module`、`public import`、`import all`、`@[expose]`） | v4.27 稳定。手册说明证明、注释、docstring 这类不导出的内容改动不会触发文件外的重编。Mathlib v4.35 的 8,624 个文件全部已是 `module`（`requiresModuleSystem := true`）；不少下游仓库还没用 | — | [手册][modules] |

### 3.4 heartbeats 与性能（定理粒度；成本 = 正常构建）

- `#count_heartbeats in <命令>`：测单条声明的实际 heartbeats；整文件用 `set_option trace.profiler true` 加 `trace.profiler.useHeartbeats true`。旧的 `linter.countHeartbeats` 自 2026-07-30 起弃用。[CountHeartbeats][heartbeats]
- `linter.style.maxHeartbeats`：要求每处 `set_option maxHeartbeats` 带说明注释，方便清点。
- Mathlib `scripts/grind_unused_lemmas.sh`：统计 `grind` 激活很多次却没用上的 E-matching 引理，用于清理 `@[grind]` 标注。[脚本][s-grindunused]

### 3.5 陈述与公理不变（定理到仓库粒度；成本 = 导出 + 内核重放）

| 工具 | 保证什么 | 链接 |
|---|---|---|
| `#print axioms` | 单条声明依赖的公理 | 核心命令 |
| `lake comparator`（v4.35 Lake 内置） | 每个 `theorem_names` 在 Solution 里证明的陈述与 Challenge 相同（Challenge 陈述用到的每个声明都必须与 Solution 导出里的完全一致）、公理不超出 `permitted_axioms`、内核接受、`definition_names` 的定义空位一致；`--challenge-from-export` 可对着一份冻结的导出判；`--paranoid` 再跑 `leanchecker-paranoid`、`lean4lean`、`nanoda`、`con-leche`、`con-ron`。默认在 `bwrap` 沙箱里跑（仅 Linux）。此前的独立版 [comparator][comparator]（landrun + lean4export）已弃用 | [Lake Help][lake-help] |
| `lake check` | 构建默认目标、导出、内核重放，出现非标准公理即报错（全库公理检查） | [Lake Help][lake-help] |
| `leanchecker`（v4.28 进核心） | 把 `.olean` 重放过**同一个**内核，`--fresh` 单模块从空环境重放；能抓环境篡改，但不独立 | [旧仓库（已弃用）][lean4checker] |
| `lean4lean`、`nanoda_bin`、`con-leche`、`con-ron`、`leanexport` | v4.35 工具链 `bin/` 自带的外部内核与导出器 | [外部内核手册][extkernels] · [nanoda][nanoda] · [lean4export][lean4export] |

### 3.6 死代码与重复声明（仓库粒度）

- **没有仓库级的"未用声明"工具。** Lean 核心、Mathlib 都没有；mathlib3 的 `#list_unused_decls` 没有经核实的 Lean 4 移植。单文件内有 Batteries 的 `#show_unused d₁ d₂`（标出当前文件里目标用不到的声明）和 `#print dependents`（[ShowUnused][b-showunused]）。RH 社区用的是自建的内核依赖图脚本（见 [rh-community-cleanup.md](../cases/rh/rh-community-cleanup.md) §4）。做法是从保留根出发遍历常量依赖（`Expr.getUsedConstants`），内核图之外 elaboration 用到的实例、simp 引理要靠重编确认。
- `@[deprecated]` 加别名是 Mathlib 删除、改名公开声明的标准做法；`lake shake` 的 `--explain` 可以反查某个导入为何不能删。
- 重复声明：按类型（规范化后）建索引找同型声明；对每条自有引理在 Mathlib 下试 `exact?` 是找"Mathlib 已有"的低成本办法。两者都要自写脚本。

## 4. 未核实与缺口

- OpenReview 论坛页和 PDF 接口要求人机验证，LeanPolish、LeanLean、Leanify 的审稿意见和全文都没有读；三者的数字只来自 arXiv HTML 摘录、仓库 README 和 OpenReview 搜索接口返回的摘要。
- LeanLean 的压缩分怎么定义、"主定理有效"怎么检查（是否用 comparator 之类）未知。
- AXLE 开源仓库的许可证、是否支持 Lean 4.35、能否本地部署，未核实。

[lp-arxiv]: https://arxiv.org/abs/2609.38384
[lp-gh]: https://github.com/paulinebourigault/leanpolish
[lp-hf]: https://huggingface.co/datasets/leanpolish-anon/lean-proof-compression
[lp-headline]: https://github.com/paulinebourigault/leanpolish/blob/main/experiments/metrics/results/headline.json
[lp-axle]: https://github.com/paulinebourigault/leanpolish/tree/main/experiments/axle
[lp-frontier]: https://github.com/paulinebourigault/leanpolish/tree/main/experiments/frontier
[leanlean-digg]: https://digg.com/ai/95jtkfae
[axle-docs]: https://axle.axiommath.ai/v1/docs/tools/simplify_theorems/
[axle-gh]: https://github.com/AxiomMath/axiom-lean-engine
[refactor]: https://arxiv.org/abs/2605.20244
[proofrefactor]: https://arxiv.org/abs/2606.03743
[optimizer]: https://arxiv.org/abs/2510.15700
[improver]: https://arxiv.org/abs/2410.04753
[improver2]: https://arxiv.org/abs/2605.22885
[or-lp]: https://openreview.net/forum?id=yRmdNlDhJS
[or-leanlean]: https://openreview.net/forum?id=LssUgDHqQj
[or-leanify]: https://openreview.net/forum?id=ikCmxFDkbM
[l-unusedvars]: https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Linter/UnusedVariables.lean
[l-simp]: https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Elab/Tactic/Simp.lean
[l-simpa]: https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Elab/Tactic/Simpa.lean
[l-extra]: https://github.com/leanprover/lean4/tree/v4.35.0/src/Lean/Linter/Extra
[try]: https://github.com/leanprover/lean4/blob/v4.35.0/src/Init/Try.lean
[lake-help]: https://github.com/leanprover/lean4/blob/v4.35.0/src/lake/Lake/CLI/Help.lean
[l-unusedtactic]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Linter/UnusedTactic.lean
[l-init]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Init.lean
[l-style]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Linter/Style.lean
[ta]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/TacticAnalysis/Declarations.lean
[says]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Says.lean
[minimports]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/MinImports.lean
[heartbeats]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Util/CountHeartbeats.lean
[s-fixunused]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/scripts/fix_unused.py
[s-fixsimp]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/scripts/fix_unused_simp_args.py
[s-skimmer]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/scripts/runSkimmer.sh
[s-grindunused]: https://github.com/leanprover-community/mathlib4/blob/v4.35.0/scripts/grind_unused_lemmas.sh
[comparator]: https://github.com/leanprover/comparator
[lean4checker]: https://github.com/leanprover/lean4checker
[nanoda]: https://github.com/ammkrn/nanoda_lib
[lean4export]: https://github.com/leanprover/lean4export
[l-mutualdef]: https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Elab/MutualDef.lean
[b-lint]: https://github.com/leanprover-community/batteries/blob/main/Batteries/Tactic/Lint/Misc.lean
[b-showunused]: https://github.com/leanprover-community/batteries/blob/main/Batteries/Tactic/ShowUnused.lean
[skimmer]: https://github.com/thorimur/skimmer
[hammer]: https://github.com/JOSHCLUNE/LeanHammer
[importgraph]: https://github.com/leanprover-community/import-graph
[modules]: https://lean-lang.org/doc/reference/latest/Source-Files-and-Modules/
[extkernels]: https://lean-lang.org/doc/reference/latest/External-Kernels/
