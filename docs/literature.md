# 形式化证明的清理、简化与重构：跨系统文献

**Summary (English).** Cross-system literature on cleaning up, simplifying and refactoring formal proofs (Lean 4/3, Coq/Rocq, Isabelle, HOL, Mizar, Metamath, proof theory), grouped by method and granularity, with venue, year and link. The text is in Chinese.

快照 2026-11-25。覆盖 Lean 4/Mathlib、Lean 3、Coq/Rocq、Isabelle、HOL Light/HOL4、Mizar、Metamath，以及证明论与自动推理里的证明压缩。这里给分组、出处和一句话；编号出处见 [`../REFERENCES.md`](../REFERENCES.md)。标"未核实"的只看过摘要或二手记录。

## 核心判断

1. **两条老传统在 2024 年后汇合。** 一条是证明论与 ATP 的证明压缩（归结证明压缩、切规则引入、发明新定义），对象是证明项的大小；另一条是 ITP 库的维护（Mizar 修订、AFP、Mathlib），关心的是可维护性和构建成本。LLM 工作（ImProver 起）把前者搬到了 Lean 的证明脚本上，LeanLean、Leanify 才开始把它推到仓库层面。
2. **每个成熟系统都有"整库定期跑"的删冗余工具。** Mizar 的 irrelevant utilities、Metamath 的 `minimize_with`（每一两年对整个 set.mm 跑一遍）、Isabelle 的 `unused_thms` 和 `find_unused_assms`、Lean 的 linter 加 `lake shake`。Lean 缺的是仓库级的未用声明工具；RH 社区用内核导出自己算闭包补上了。
3. **压缩的最大杠杆是抽引理、发明定义，而不是删 tactic。** 理论上有切规则引入（反转切消）和定义发明，实践上有 Leanify（证明项缩小 94%–99%，并发现可复用引理）和 LeanLean（依赖重组是大头）。但 *Library Learning Doesn't* 提醒，LLM 产出的"可复用引理"大多没被复用，所以验收要看实际复用次数，不能只看提出了多少引理。
4. **正确性几乎全靠"生成后检查"。** 只有少数方法本身带保证：Whiteside 等人形式化定义的 refactoring、Pumpkin Pi 沿类型等价的迁移、切规则引入的证明论保证。其余方法（包括全部 LLM 工作）都靠重新编译或内核重放，所以验证成本决定了能做多大规模。
5. **大仓库的前提是回归证明选择和分布式构建。** iCoq/piCoq（只重查受影响的证明）、AFP 的分布式构建（10–20 节点恢复 45 分钟上限）、seL4 的大规模证明管理经验，都是"清理能不能跑得动"的前提，与清理方法本身同样重要。

## 1. 方法 × 粒度总览

| 方法族 | 定理 | 文件 | 小仓库 | 大仓库 |
|---|---|---|---|---|
| 删冗余步骤与前提 | Mathlib linter、Isabelle Sledgehammer 最小化、TacticToe 最小化、Metamath `minimize_with`、Mizar `relprem`/`relinfer` | linter 批量修复、`lake shake` | Mizar/Metamath 整库定期跑 | RH #67（linter 删无用语法） |
| 自动化替换 | `simp?`/`exact?`/`grind?`、hammer（Sledgehammer、CoqHammer、LeanHammer）、LeanPolish 替换菜单 | Mathlib TacticAnalysis | — | — |
| LLM 改写 | ImProver 1/2、ProofOptimizer、Lean Refactor、LeanPolish 神经混合、AXLE | — | Lean Refactor（研究仓库 >20%） | LeanLean（12 小时智能体） |
| 抽引理与发明定义 | Proof-Refactor、AXLE `have2lemma` | Pąk 引理抽取、Adams Tactician | Leanify、Kaliszyk–Urban lemma mining | LeanLean 依赖重组 |
| 去重与对齐 | — | 同型声明合并 | Huch 相似搜索（Isabelle）、Ghanbari goal clone（Rocq） | RH #295（同陈述只留一份）、HOL 库概念对齐 |
| 死代码与依赖 | Isabelle `find_unused_assms` | Batteries `#show_unused` | Isabelle `unused_thms`、Coq/Mizar 依赖抽取 | RH 内核闭包（Shore）、#45/#55 可达性裁剪 |
| 修复与迁移 | Baldur、APRIL、PRISM | — | PUMPKIN PATCH、Sisyphus | Pumpkin Pi、mathport（Lean 3→4） |
| 构建工程 | — | — | iCoq | piCoq、AFP 分布式构建、lakeshard |

## 2. 证明内压缩与最短化（定理粒度）

| 工作 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Berghofer & Nipkow, [*Proof Terms for Simply Typed HOL*][berghofer] | TPHOLs 2000 | Isabelle | 证明项省掉可重建的子项，检查时再重建 |
| Fontaine, Merz, Woltzenlogel Paleo, [*Compression of Propositional Resolution Proofs via Partial Regularization*][rpi] | CADE 2011 | SAT/SMT 证明 | RecyclePivotsWithIntersection 与 LowerUnits 两个线性时间压缩算法 |
| Blanchette et al., [*Semi-intelligible Isar Proofs from Machine-Generated Proofs*][isar] | JAR 2016 | Isabelle | ATP 证明转直接 Isar 证明，回放加压缩；Sledgehammer 自带事实集最小化 |
| Gauthier, Kaliszyk, Urban, Kumar, Norrish, [*TacticToe*][tactictoe] | JAR 2021 | HOL4 | 找到证明后做长度最小化和 tactic 参数（引理列表）最小化 |
| Metamath [`minimize_with`][mm-min] | set.mm 社区实践 | Metamath | 提交前必须最小化；每一两年对整个 set.mm 跑一次；加 `/no_new_axioms_from` 防止引入新公理 |
| Polu & Sutskever, [GPT-f][gptf] | arXiv 2020 | Metamath | 23 个更短的证明被 set.mm 采纳，是 LLM 缩短证明被主库接受的最早案例 |
| Pąk, [*Automated Improving of Proof Legibility in the Mizar System*][pak14]；[arXiv 1407.1140][pak-np] | CICM 2014 | Mizar | irrelevant utilities（`relprem`、`relinfer` 等）找多余前提与步骤；某些可读性优化是 NP-hard |
| Ahuja et al., [ImProver][improver] | ICLR 2025 | Lean 4 | LLM 智能体按自定义指标改写，编译把关 |
| Gu et al., [ProofOptimizer][optimizer] | ICLR 2026 | Lean 4 | 符号 linter + 7B 模型 + 迭代缩短；miniF2F −87%，PutnamBench −57% |
| Ahuja et al., [ImProver 2][improver2] | arXiv 2026 | Lean 4 | 长度、依赖数、模块度多指标；Mathlib 上长度几乎不降 |
| Lu et al., [Lean Refactor][refactor] | NeurIPS 2026 | Lean 4 | 带版本标注的策略库 + 冻结智能体；研究仓库 >20%，编译时间最多 −60% |
| Bourigault, [LeanPolish][leanpolish] | ICLR 2027 在审 | Lean 4 | 符号替换菜单 + 删未用 `have`，迭代到不动点；见 [survey.md](survey.md) §1 |
| Xin et al., [AXLE][axle] | ICML 2026 AI4Math | Lean 4 | 托管工具集；`simplify_theorems` 删未用 tactic 和 `have` |
| Cheng, [*Compile-Gated Lean Proof Refactoring*][arena] | arXiv 2026（比赛报告） | Lean 4 | Lean Refactor Arena 参赛；每题约 2.8 美元；固定改写规则可复现 |
| Zhu et al., [*Premise Selection for a Lean Hammer*][hammer] | ICLR 2026 | Lean 4 | LeanHammer：premise selection + 重建，可用来把长证明换成一次 `hammer` 调用 |

## 3. 抽引理、发明定义与重构（定理到文件粒度）

| 工作 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Vyskočil, Stanovský, Urban, [*Automated Proof Compression by Invention of New Definitions*][vyskocil] | LPAR 2010 | 一阶证明 | 在证明项里找重复模式，发明新定义来缩短 |
| Hetzl, Leitsch, Reis, Weller, [*Algorithmic Introduction of Quantified Cuts*][cutintro] | TCS 2014 | 证明论（GAPT） | 反转切消，自动引入带量词的引理来结构化、压缩证明 |
| Kaliszyk & Urban, [*Lemma Mining over HOL Light*][lemmamining] | LPAR 2013 | HOL Light | 在完整推理轨迹上给中间结论打分，提成可复用引理 |
| Pąk, *Methods of Lemma Extraction in Natural Deduction Proofs* | JAR 50(2), 2013 | Mizar | 引理抽取方法与复杂度 |
| Whiteside, Aspinall, Dixon, Grov, [*Towards Formal Proof Script Refactoring*][whiteside] | CICM 2011 | 形式化脚本语言 | 重命名、抽引理等 refactoring 有形式定义并证明保持正确性 |
| Adams, [*Refactoring Proofs with Tactician*][tactician] | SEFM 2015 Workshops（HOFM） | HOL Light | tactic 步骤的打包（`THEN`/`THENL`）与展开 |
| Cohen, Sakaguchi, Tassi, *Hierarchy Builder*；Baanen, *Use and Abuse of Instance Parameters* | FSCD 2020；ITP 2022 | Coq；Lean | 代数层级与实例参数的重构 |
| Bowers et al., [Stitch][stitch]；Cao et al., [babble][babble] | POPL 2023 | 程序语料 | 以压缩为目标的库学习（抽象发现），babble 用 e-graph 反统一 |
| Wang et al., LEGO-Prover；Berlot-Attwell et al., *Library Learning Doesn't* | ICLR 2024；arXiv 2024 | Isabelle | 证明中积累引理库；后者发现所学引理大多没被复用 |
| Fu et al., [Proof-Refactor][proofrefactor] | ICML 2026 AI4Math | Lean 4 | 抽片段、设计辅助声明、证明、修回原证明；目标是结构和可读性，不是长度 |
| [Leanify][leanify] | ICLR 2027 在审 | Lean 4 | 证明集合压缩（证明项大小）+ 引理发现；越往后压缩越能发现非平凡引理 |

## 4. 去重与跨库对齐（文件到仓库粒度）

| 工作 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Gauthier & Kaliszyk, *Matching Concepts across HOL Libraries*；*Aligning Concepts across Proof Assistant Libraries* | CICM 2014；JSC 2019 | HOL 系 | 按性质模式匹配不同库中的同一概念 |
| Müller, Kohlhase, Rabe, [*Automatically Finding Theory Morphisms*][morphisms] | CICM 2018 | MMT | 自动找理论态射，用于知识去重 |
| Heras & Komendantskaya, ML4PG | LPAR 2013 等 | Coq、ACL2 | 证明模式聚类，发现可复用引理 |
| Huch, [*Supporting Maintenance of Formal Mathematics with Similarity Search*][huch25] | CICM 2025 | Isabelle | 相似声明检索，支持维护去重 |
| Ghanbari, [*Automatic Goal Clone Detection in Rocq*][clone] | ECOOP 2025 | Rocq | 目标级克隆检测 |
| Liu et al., [MathlibLemma][mathliblemma] | ICML 2026 | Lean 4 | 挖掘 Mathlib 缺的常识引理，少量合入 Mathlib |

## 5. 死代码、依赖与 import（仓库粒度）

| 工作或工具 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Isabelle [`unused_thms`][unusedthms] | Isabelle 2008 起（Isar 参考手册） | Isabelle | 列出给定理论范围内没被用到的定理；同一命令产生的定理成组处理 |
| Isabelle [`find_unused_assms`][unusedassms] | Bulwahn, 2012 | Isabelle | 逐个去掉前提跑 Quickcheck，标出可能多余的假设（启发式） |
| Alama, Mamane, Urban, [*Dependencies in Formal Mathematics*][deps] | CICM 2012 | Coq、Mizar | 依赖抽取的方法与应用 |
| Li et al., *The Network Structure of Mathlib* | arXiv 2026 | Lean 4 | 44.8% 的定理不被任何声明引用；库的叶子是 API，不等于死代码 |
| Shore, [rh-proof-dependencies][shore-deps] | 数据集 v0.2.1，2026-11 | Lean 4 | 从内核证明项算 RH 五个定理的依赖闭包；见 [rh-community-cleanup.md](../cases/rh/rh-community-cleanup.md) |
| `lake shake`、import-graph、Batteries `#show_unused` | Lean 工具 | Lean 4 | 见 [survey.md](survey.md) §3 |

## 6. 修复与跨版本维护（仓库粒度）

| 工作 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Ringer, Yazdani, Leo, Grossman, [*Adapting Proof Automation to Adapt Proofs*][pumpkin]（PUMPKIN PATCH） | CPP 2018 | Coq | 从一次示范改动泛化出补丁，修其他受影响的证明 |
| Ringer et al., [*Proof Repair across Type Equivalences*][pumpkinpi]（Pumpkin Pi） | PLDI 2021 | Coq | 沿类型等价自动迁移证明，带构造性保证 |
| Gopinathan, Keoliya, Sergey, [Sisyphus][sisyphus] | PLDI 2023 | Coq | 库版本变化后的大部分自动修复 |
| Reichel et al., [PRISM][prism] | ITP 2023 | Coq | 大规模修复数据集 |
| First et al., [Baldur][baldur]；Wang et al., [APRIL][april] | ESEC/FSE 2023；arXiv 2026 | Isabelle；Lean 4 | LLM 整证明生成后带报错修复 |
| Gross et al., [*Automatic Test-Case Reduction in Proof Assistants*][coqmin] | ITP 2022 | Coq | Coq bug minimizer：89% 产出独立用例，平均约为原来的 1/3；用于最小复现，不是清理 |
| Luan et al., *Compatibility Issues in Isabelle* | FSE 2025 | Isabelle | 跨版本失败的实证研究 |

## 7. 库维护与构建工程（仓库粒度）

| 工作 | 出处 | 系统 | 要点 |
|---|---|---|---|
| Grabowski & Schwarzweller, [*Revisions as an Essential Tool to Maintain Mathematical Repositories*][mizar-rev] | MKM/Calculemus 2007 | Mizar | MML 由核心团队定期修订：重组、去冗余、提质量；有[修订记录][mml-rev] |
| van Doorn, Ebner, Lewis, [*Maintaining a Library of Formal Mathematics*][maintain] | CICM 2020 | Lean 3 | mathlib 的 linter（`#lint`）、整环境检查、豁免机制 |
| Baanen et al., [*Growing Mathlib*][growing] | CICM 2025 | Lean 4 | deprecation 别名、linter、拆文件、技术债跟踪、mathport 迁移 |
| Bourke, Daum, Klein, Kolanski, [*Challenges and Experiences in Managing Large-Scale Proofs*][bourke] | CICM 2012 | Isabelle（seL4） | 大规模证明的组织与维护经验 |
| Blanchette et al., [*Mining the Archive of Formal Proofs*][afp-mining] | CICM 2015 | Isabelle | AFP 的结构与使用统计 |
| Celik, Palmskog, Gligoric, [iCoq][icoq]；Palmskog et al., [piCoq][picoq] | ASE 2017；ISSTA 2018 | Coq | 回归证明选择：只重查受改动影响的文件或证明，并行执行 |
| Huch & Wenzel, [*Distributed Parallel Build for the AFP*][afp-build] | ITP 2024 | Isabelle | 10–20 节点集群，目标恢复 AFP 45 分钟构建上限 |
| Gross, [*Performance Engineering of Proof-Based Software Systems at Scale*][gross-phd] | MIT 博士论文 2021 | Coq | 证明系统性能工程 |
| Ringer et al., [*QED at Large*][qed] | FnT PL 2019 | 综述 | 形式化验证工程综述，含回归证明分类 |

## 8. 评测与基准

| 基准 | 出处 | 粒度 | 要点 |
|---|---|---|---|
| [LeanLean][leanlean] | ICLR 2027 在审 | 仓库 | 64 个真实仓库（最多 17.4 万行），12 小时；Opus 5 平均 48.3% |
| [Leanify][leanify] | ICLR 2027 在审 | 证明集合 | 以证明项大小计的压缩 + 引理复用 |
| Lean Refactor Arena | NeurIPS 2026 比赛 | 定理 | 参赛报告见 [Cheng][arena]；官方排行榜未核实 |
| miniF2F、PutnamBench 上的长度指标 | ImProver、ProofOptimizer、LeanPolish 共用 | 定理 | 竞赛题，单文件，不涉及跨文件依赖 |

## 9. 对分层方案的含义

- **定理层**：先用确定性的删除与替换（linter、TacticAnalysis、hammer 风格替换），再用 LLM；参照 Metamath，最小化要加"不引入新公理"的约束，对应分层方案里的 G4。
- **文件层**：抽引理和发明定义收益最大，但要按实际复用次数验收（*Library Learning Doesn't*）。
- **小仓库**：按 Mizar 修订和 Metamath 整库最小化的做法，做成定期整库跑的流水线，而不是一次性运动。
- **大仓库**：照搬 iCoq/piCoq 的回归证明选择和 AFP 的分布式构建，落到 lakeshard；去重和依赖重组（LeanLean、RH #295）才是大头。

具体的优化思路排序和工程流水线见 [ideas-and-engineering.md](ideas-and-engineering.md)。

[berghofer]: https://www21.in.tum.de/~nipkow/pubs/tphols00.html
[rpi]: https://members.loria.fr/SMerz/papers/cade2011compression.html
[isar]: https://www.semanticscholar.org/paper/c53038bff3ab70292aafcdabfccc25220af55594
[tactictoe]: https://arxiv.org/abs/1804.00596
[mm-min]: https://github.com/metamath/set.mm/wiki/Minimizing
[gptf]: https://arxiv.org/abs/2009.03393
[pak14]: https://link.springer.com/chapter/10.1007/978-3-319-08434-3_27
[pak-np]: https://arxiv.org/abs/1407.1140
[improver]: https://arxiv.org/abs/2410.04753
[optimizer]: https://arxiv.org/abs/2510.15700
[improver2]: https://arxiv.org/abs/2605.22885
[refactor]: https://arxiv.org/abs/2605.20244
[leanpolish]: https://arxiv.org/abs/2609.38384
[axle]: https://arxiv.org/abs/2606.26442
[arena]: https://arxiv.org/abs/2611.13011
[hammer]: https://arxiv.org/abs/2506.07477
[vyskocil]: https://www.karlin.mff.cuni.cz/~stanovsk/math/komprese.pdf
[cutintro]: https://arxiv.org/abs/1401.4330
[lemmamining]: https://link.springer.com/chapter/10.1007/978-3-642-45221-5_34
[whiteside]: https://link.springer.com/chapter/10.1007/978-3-642-22673-1_18
[tactician]: https://doi.org/10.1007/978-3-662-49224-6_6
[stitch]: https://par.nsf.gov/servlets/purl/10404367
[babble]: https://arxiv.org/abs/2212.04596
[proofrefactor]: https://arxiv.org/abs/2606.03743
[leanify]: https://openreview.net/forum?id=ikCmxFDkbM
[leanlean]: https://openreview.net/forum?id=LssUgDHqQj
[morphisms]: https://link.springer.com/chapter/10.1007/978-3-319-96812-4_18
[huch25]: https://link.springer.com/chapter/10.1007/978-3-032-07021-0_6
[clone]: https://arxiv.org/abs/2504.19129
[mathliblemma]: https://arxiv.org/abs/2602.02561
[unusedthms]: https://isabelle.in.tum.de/repos/isabelle/rev/237328506a42
[unusedassms]: https://isabelle.in.tum.de/repos/isabelle/rev/689311986778
[deps]: https://link.springer.com/chapter/10.1007/978-3-642-31374-5_1
[shore-deps]: https://github.com/james-shore/rh-proof-dependencies
[pumpkin]: https://doi.org/10.1145/3167094
[pumpkinpi]: https://arxiv.org/abs/2010.00774
[sisyphus]: https://dl.acm.org/doi/10.1145/3591221
[prism]: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2023.26
[baldur]: https://arxiv.org/abs/2303.04910
[april]: https://arxiv.org/abs/2602.02990
[coqmin]: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2022.18
[mizar-rev]: https://link.springer.com/doi/10.1007/978-3-540-73086-6_20
[mml-rev]: https://mizar.uwb.edu.pl/library/revisions/
[maintain]: https://arxiv.org/abs/2004.03673
[growing]: https://arxiv.org/abs/2508.21593
[bourke]: https://link.springer.com/chapter/10.1007/978-3-642-31374-5_3
[afp-mining]: https://link.springer.com/chapter/10.1007/978-3-319-20615-8_1
[icoq]: https://dl.acm.org/doi/10.5555/3155562.3155588
[picoq]: https://doi.org/10.1145/3213846.3213877
[afp-build]: https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2024.22
[gross-phd]: https://dspace.mit.edu/handle/1721.1/130763
[qed]: https://www.nowpublishers.com/article/Details/PGL-045
