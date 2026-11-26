# 参考文献与出处

**Summary (English).** Numbered list of every public source used in this repository: papers [P], tools and documentation [T], datasets and repositories [D], and community records [C], each with venue, year, link and how closely we read it. Checked on 2026-11-25; D16–D18, C5 and C6 added on 2026-11-26.

文档里直接给出链接；本文件按类编号，方便核对。每条标明阅读程度：

- **全文**：读了全文或全部相关内容（对数据与仓库，指我们自己读了或计算过其内容）；
- **相关段落**：读了支撑我们说法的那几段（源码文件、文档的某一节、帖子的某一条）；
- **摘要**：只读了摘要、检索摘要、元数据或书目条目，结论未对照原文；
- **未重新核对**：沿用先前整理的书目信息，这次没有再查。

## P 论文

### 证明压缩与最短化

| 编号 | 作者（年份） | 题目 | 出处 | 链接 | 阅读程度 |
|---|---|---|---|---|---|
| P1 | S. Berghofer, T. Nipkow (2000) | Proof terms for simply typed higher order logic | TPHOLs 2000 | [tum.de](https://www21.in.tum.de/~nipkow/pubs/tphols00.html) | 摘要 |
| P2 | P. Fontaine, S. Merz, B. Woltzenlogel Paleo (2011) | Compression of propositional resolution proofs via partial regularization | CADE-23, LNCS 6803:237–251 | [loria.fr](https://members.loria.fr/SMerz/papers/cade2011compression.html) | 摘要 |
| P3 | J. C. Blanchette et al. (2016) | Semi-intelligible Isar proofs from machine-generated proofs | J. Automated Reasoning | [Semantic Scholar](https://www.semanticscholar.org/paper/c53038bff3ab70292aafcdabfccc25220af55594) | 摘要 |
| P4 | T. Gauthier, C. Kaliszyk, J. Urban, R. Kumar, M. Norrish (2021) | TacticToe: learning to prove with tactics | J. Automated Reasoning 65(2):257–286 | [arXiv:1804.00596](https://arxiv.org/abs/1804.00596) | 相关段落（最小化一节，arXiv 版） |
| P5 | S. Polu, I. Sutskever (2020) | Generative language modeling for automated theorem proving | arXiv | [arXiv:2009.03393](https://arxiv.org/abs/2009.03393) | 摘要 |
| P6 | K. Pąk (2014) | Automated improving of proof legibility in the Mizar system | CICM 2014 | [Springer](https://link.springer.com/chapter/10.1007/978-3-319-08434-3_27) | 摘要 |
| P7 | K. Pąk (2014) | Improving legibility of natural deduction proofs is not trivial | arXiv | [arXiv:1407.1140](https://arxiv.org/abs/1407.1140) | 摘要 |
| P8 | R. Ahuja, J. Avigad, P. Tetali, S. Welleck (2025) | ImProver: agent-based automated proof optimization | ICLR 2025 | [arXiv:2410.04753](https://arxiv.org/abs/2410.04753) | 摘要 |
| P9 | A. Gu, B. Piotrowski, F. Gloeckle, K. Yang, A. H. Markosyan (2026) | ProofOptimizer: training language models to simplify proofs without human demonstrations | ICLR 2026 | [arXiv:2510.15700](https://arxiv.org/abs/2510.15700) | 摘要 |
| P10 | R. Ahuja 等 (2026) | ImProver 2: iteratively self-improving LMs for neurosymbolic proof optimization | arXiv | [arXiv:2605.22885](https://arxiv.org/abs/2605.22885) | 摘要 |
| P11 | J. Lu, S. Kong, R. Stehling, K. Yang, Z. Wang, W. Sun, W. Chen (2026) | Lean Refactor: multi-objective controllable proof optimization via agentic strategy search | NeurIPS 2026 | [arXiv:2605.20244](https://arxiv.org/abs/2605.20244) | 摘要 |
| P12 | P. Bourigault (2026) | LeanPolish: verified supervision for Lean proof compression | ICLR 2027 在审投稿 | [arXiv:2609.38384](https://arxiv.org/abs/2609.38384)、[OpenReview](https://openreview.net/forum?id=yRmdNlDhJS) | 相关段落（arXiv HTML 前约三分之一、代码仓库 README 与结果文件） |
| P13 | J. Xin, A. M. Schneidman, C. Cummins, K. Ram, S. Ganesh, J. Limperg (2026) | AXLE: a cloud infrastructure for Lean 4 theorem proving utilities | ICML 2026 AI4Math Workshop | [arXiv:2606.26442](https://arxiv.org/abs/2606.26442) | 摘要 |
| P14 | B. Cheng (2026) | Compile-gated Lean proof refactoring with enterprise agent practices | arXiv（Lean Refactor Arena 参赛报告） | [arXiv:2611.13011](https://arxiv.org/abs/2611.13011) | 未重新核对 |
| P15 | T. Zhu, J. Clune, J. Avigad, A. Q. Jiang, S. Welleck (2026) | Premise selection for a Lean hammer | ICLR 2026 | [arXiv:2506.07477](https://arxiv.org/abs/2506.07477) | 摘要 |

### 抽引理、发明定义与重构

| 编号 | 作者（年份） | 题目 | 出处 | 链接 | 阅读程度 |
|---|---|---|---|---|---|
| P16 | J. Vyskočil, D. Stanovský, J. Urban (2010) | Automated proof compression by invention of new definitions | LPAR-16 | [PDF](https://www.karlin.mff.cuni.cz/~stanovsk/math/komprese.pdf) | 摘要 |
| P17 | S. Hetzl, A. Leitsch, G. Reis, D. Weller (2014) | Algorithmic introduction of quantified cuts | Theoretical Computer Science 549:1–16 | [arXiv:1401.4330](https://arxiv.org/abs/1401.4330) | 摘要 |
| P18 | C. Kaliszyk, J. Urban (2013) | Lemma mining over HOL Light | LPAR 2013 | [Springer](https://link.springer.com/chapter/10.1007/978-3-642-45221-5_34) | 摘要 |
| P19 | K. Pąk (2013) | Methods of lemma extraction in natural deduction proofs | J. Automated Reasoning 50(2):217–228 | [Springer](https://link.springer.com/journal/10817/volumes-and-issues/50-2) | 未重新核对 |
| P20 | I. Whiteside, D. Aspinall, L. Dixon, G. Grov (2011) | Towards formal proof script refactoring | CICM 2011, LNCS 6824 | [Springer](https://link.springer.com/chapter/10.1007/978-3-642-22673-1_18) | 摘要 |
| P21 | M. Adams (2015) | Refactoring proofs with Tactician | SEFM 2015 Collocated Workshops (HOFM), LNCS 9509:53–67 | [doi:10.1007/978-3-662-49224-6_6](https://doi.org/10.1007/978-3-662-49224-6_6) | 摘要 |
| P22 | C. Cohen, K. Sakaguchi, E. Tassi (2020) | Hierarchy Builder: algebraic hierarchies made easy in Coq with Elpi | FSCD 2020, LIPIcs 167 | [Dagstuhl](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.FSCD.2020.34) | 未重新核对 |
| P23 | A. Baanen (2022) | Use and abuse of instance parameters in the Lean mathematical library | ITP 2022, LIPIcs 237 | [Dagstuhl](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2022.4) | 未重新核对 |
| P24 | M. Bowers et al. (2023) | Top-down synthesis for library learning（Stitch） | POPL 2023 | [NSF PAR](https://par.nsf.gov/servlets/purl/10404367) | 摘要 |
| P25 | D. Cao, R. Kunkel, C. Nandi, M. Willsey, Z. Tatlock, N. Polikarpova (2023) | babble: learning better abstractions with e-graphs and anti-unification | POPL 2023 | [arXiv:2212.04596](https://arxiv.org/abs/2212.04596) | 摘要 |
| P26 | H. Wang et al. (2024) | LEGO-Prover: neural theorem proving with growing libraries | ICLR 2024 | [ICLR](https://iclr.cc/virtual/2024/oral/19793) | 摘要 |
| P27 | I. Berlot-Attwell, F. Rudzicz, X. Si (2024) | Library learning doesn't: the curious case of the single-use "library" | arXiv | [arXiv:2410.20274](https://arxiv.org/abs/2410.20274) | 摘要 |
| P28 | Y. Fu, P. Liu, Z. Wang, K. Yuan (2026) | Proof-Refactor: refactoring generated formal proofs into modular artifacts | ICML 2026 AI4Math Workshop | [arXiv:2606.03743](https://arxiv.org/abs/2606.03743) | 摘要 |
| P29 | 匿名（2026） | Leanify: verified proof compression and reusable lemma discovery | ICLR 2027 在审投稿 | [OpenReview](https://openreview.net/forum?id=ikCmxFDkbM) | 摘要 |
| P30 | 匿名（2026） | LeanLean: benchmarking repository-scale Lean proof compression | ICLR 2027 在审投稿 | [OpenReview](https://openreview.net/forum?id=LssUgDHqQj) | 摘要 |

### 去重、依赖与对齐

| 编号 | 作者（年份） | 题目 | 出处 | 链接 | 阅读程度 |
|---|---|---|---|---|---|
| P31 | T. Gauthier, C. Kaliszyk (2014, 2019) | Matching concepts across HOL libraries；Aligning concepts across proof assistant libraries | CICM 2014；J. Symbolic Computation 90 | [arXiv:1405.3906](https://arxiv.org/abs/1405.3906)、[JSC](https://www.sciencedirect.com/science/article/pii/S0747717118300348) | 未重新核对 |
| P32 | D. Müller, M. Kohlhase, F. Rabe (2018) | Automatically finding theory morphisms for knowledge management | CICM 2018 | [Springer](https://link.springer.com/chapter/10.1007/978-3-319-96812-4_18) | 摘要 |
| P33 | J. Heras, E. Komendantskaya et al. (2013–2014) | Recycling proof patterns in Coq；Proof-pattern recognition and lemma discovery in ACL2 | Math. in Computer Science 2014；LPAR 2013 | [arXiv:1308.1780](https://arxiv.org/abs/1308.1780) | 未重新核对 |
| P34 | F. Huch (2025) | Supporting maintenance of formal mathematics with similarity search | CICM 2025 | [Springer](https://link.springer.com/chapter/10.1007/978-3-032-07021-0_6) | 摘要 |
| P35 | A. Ghanbari (2025) | Automatic goal clone detection in Rocq | ECOOP 2025 | [arXiv:2504.19129](https://arxiv.org/abs/2504.19129) | 摘要 |
| P36 | X. Liu et al. (2026) | MathlibLemma: folklore lemma generation and benchmark for formal mathematics | ICML 2026 | [arXiv:2602.02561](https://arxiv.org/abs/2602.02561) | 摘要 |
| P37 | J. Alama, L. Mamane, J. Urban (2012) | Dependencies in formal mathematics: applications and extraction for Coq and Mizar | CICM 2012, LNCS 7362 | [Springer](https://link.springer.com/chapter/10.1007/978-3-642-31374-5_1) | 摘要 |
| P38 | X. Li, N. Peng, S. Severini, P. Shafto (2026) | The network structure of Mathlib | arXiv | [arXiv:2604.24797](https://arxiv.org/abs/2604.24797) | 摘要 |

### 修复与跨版本维护

| 编号 | 作者（年份） | 题目 | 出处 | 链接 | 阅读程度 |
|---|---|---|---|---|---|
| P39 | T. Ringer, N. Yazdani, J. Leo, D. Grossman (2018) | Adapting proof automation to adapt proofs（PUMPKIN PATCH） | CPP 2018 | [doi:10.1145/3167094](https://doi.org/10.1145/3167094) | 摘要 |
| P40 | T. Ringer et al. (2021) | Proof repair across type equivalences | PLDI 2021 | [arXiv:2010.00774](https://arxiv.org/abs/2010.00774) | 摘要 |
| P41 | K. Gopinathan, M. Keoliya, I. Sergey (2023) | Mostly automated proof repair for verified libraries（Sisyphus） | PLDI 2023 | [ACM](https://dl.acm.org/doi/10.1145/3591221) | 摘要 |
| P42 | T. Reichel et al. (2023) | Proof repair infrastructure for supervised models: building a large proof repair dataset（PRISM） | ITP 2023, LIPIcs 268 | [Dagstuhl](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2023.26) | 摘要 |
| P43 | E. First, M. Rabe, T. Ringer, Y. Brun (2023) | Baldur: whole-proof generation and repair with large language models | ESEC/FSE 2023 | [arXiv:2303.04910](https://arxiv.org/abs/2303.04910) | 摘要 |
| P44 | Wang et al. (2026) | Learning to repair Lean proofs from compiler feedback（APRIL） | arXiv | [arXiv:2602.02990](https://arxiv.org/abs/2602.02990) | 摘要 |
| P45 | M. Patel, B. Piotrowski, L. Haller, H. J. Leather (2026) | ProofRepairBench: exploring proof repair in Lean | ICLR 2026 VerifAI-2 Workshop | [OpenReview](https://openreview.net/forum?id=6SwWVNwEJK) | 摘要 |
| P46 | J. Gross, T. Zimmermann, M. Poddar-Agrawal, A. Chlipala (2022) | Automatic test-case reduction in proof assistants: a case study in Coq | ITP 2022 | [Dagstuhl](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2022.18) | 摘要 |
| P47 | Luan et al. (2025) | Why the proof fails in different versions of theorem provers: an empirical study of compatibility issues in Isabelle | FSE 2025 | [ACM](https://dl.acm.org/doi/10.1145/3715787) | 摘要 |

### 库维护与构建工程

| 编号 | 作者（年份） | 题目 | 出处 | 链接 | 阅读程度 |
|---|---|---|---|---|---|
| P48 | A. Grabowski, C. Schwarzweller (2007) | Revisions as an essential tool to maintain mathematical repositories | MKM/Calculemus 2007, LNCS 4573 | [Springer](https://link.springer.com/doi/10.1007/978-3-540-73086-6_20) | 摘要 |
| P49 | F. van Doorn, G. Ebner, R. Y. Lewis (2020) | Maintaining a library of formal mathematics | CICM 2020 | [arXiv:2004.03673](https://arxiv.org/abs/2004.03673) | 摘要 |
| P50 | A. Baanen et al. (2025) | Growing Mathlib: maintenance of a large scale mathematical library | CICM 2025 | [arXiv:2508.21593](https://arxiv.org/abs/2508.21593) | 摘要 |
| P51 | T. Bourke, M. Daum, G. Klein, R. Kolanski (2012) | Challenges and experiences in managing large-scale proofs | CICM 2012, LNCS 7362 | [Springer](https://link.springer.com/chapter/10.1007/978-3-642-31374-5_3) | 摘要 |
| P52 | J. C. Blanchette, M. Haslbeck, D. Matichuk, T. Nipkow (2015) | Mining the Archive of Formal Proofs | CICM 2015, LNCS 9150 | [Springer](https://link.springer.com/chapter/10.1007/978-3-319-20615-8_1) | 摘要 |
| P53 | A. Celik, K. Palmskog, M. Gligoric (2017) | iCoq: regression proof selection for large-scale verification projects | ASE 2017 | [ACM](https://dl.acm.org/doi/10.5555/3155562.3155588) | 摘要 |
| P54 | K. Palmskog, A. Celik, M. Gligoric (2018) | piCoq: parallel regression proving for large-scale verification projects | ISSTA 2018 | [doi:10.1145/3213846.3213877](https://doi.org/10.1145/3213846.3213877) | 摘要 |
| P55 | F. Huch, M. Wenzel (2024) | Distributed parallel build for the Isabelle Archive of Formal Proofs | ITP 2024, LIPIcs 309 | [Dagstuhl](https://drops.dagstuhl.de/entities/document/10.4230/LIPIcs.ITP.2024.22) | 摘要 |
| P56 | J. S. Gross (2021) | Performance engineering of proof-based software systems at scale | MIT 博士论文 | [DSpace](https://dspace.mit.edu/handle/1721.1/130763) | 未重新核对 |
| P57 | T. Ringer, K. Palmskog, I. Sergey, M. Gligoric, Z. Tatlock (2019) | QED at large: a survey of engineering of formally verified software | Foundations and Trends in PL 5(2–3) | [now publishers](https://www.nowpublishers.com/article/Details/PGL-045) | 摘要 |

## T 工具与文档

源码链接指向 v4.35.0 tag，是我们核对时所用的版本。

| 编号 | 名称 | 内容 | 链接 | 阅读程度 |
|---|---|---|---|---|
| T1 | Lake CLI 帮助（Lean v4.35.0） | `lake shake`、`lake comparator`、`lake check`、`lake lint` 的参数与保证 | [Help.lean](https://github.com/leanprover/lean4/blob/v4.35.0/src/lake/Lake/CLI/Help.lean) | 相关段落 |
| T2 | Lean 核心 linter 与 `try?` | `unusedVariables`、`unusedSimpArgs`、`unnecessarySimpa`、`Linter/Extra`、`try?` | [UnusedVariables](https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Linter/UnusedVariables.lean)、[Simp](https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Elab/Tactic/Simp.lean)、[Simpa](https://github.com/leanprover/lean4/blob/v4.35.0/src/Lean/Elab/Tactic/Simpa.lean)、[Extra](https://github.com/leanprover/lean4/tree/v4.35.0/src/Lean/Linter/Extra)、[Try](https://github.com/leanprover/lean4/blob/v4.35.0/src/Init/Try.lean) | 相关段落 |
| T3 | Mathlib linter | 标准集合 `mathlibStandardSet`、`unusedTactic`、风格 linter | [Init.lean](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Init.lean)、[UnusedTactic](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Linter/UnusedTactic.lean)、[Style](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Linter/Style.lean) | 相关段落 |
| T4 | Mathlib TacticAnalysis | `tryAtEachStep*`、`terminalToGrind`、`rwMerge` 等 | [Declarations.lean](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/TacticAnalysis/Declarations.lean) | 相关段落 |
| T5 | Mathlib `#min_imports`、`#count_heartbeats`、`says` | — | [MinImports](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/MinImports.lean)、[CountHeartbeats](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Util/CountHeartbeats.lean)、[Says](https://github.com/leanprover-community/mathlib4/blob/v4.35.0/Mathlib/Tactic/Says.lean) | 相关段落 |
| T6 | Mathlib 修复脚本 | `fix_unused.py`、`fix_unused_simp_args.py`、`runSkimmer.sh`、`grind_unused_lemmas.sh` | [scripts/](https://github.com/leanprover-community/mathlib4/tree/v4.35.0/scripts) | 相关段落 |
| T7 | Skimmer | 批量应用 Try-this 建议（实验性） | [thorimur/skimmer](https://github.com/thorimur/skimmer) | 摘要 |
| T8 | Batteries | 环境 linter（含 `unusedHavesSuffices`）、`#show_unused` | [Lint/Misc.lean](https://github.com/leanprover-community/batteries/blob/main/Batteries/Tactic/Lint/Misc.lean)、[ShowUnused.lean](https://github.com/leanprover-community/batteries/blob/main/Batteries/Tactic/ShowUnused.lean) | 摘要 |
| T9 | import-graph | `#min_imports`、`#redundant_imports`、`lake exe graph`、`unused_transitive_imports` | [import-graph](https://github.com/leanprover-community/import-graph) | 摘要 |
| T10 | Lean 参考手册 | 模块系统；外部内核；证明的核验 | [模块](https://lean-lang.org/doc/reference/latest/Source-Files-and-Modules/)、[外部内核](https://lean-lang.org/doc/reference/latest/External-Kernels/)、[核验](https://lean-lang.org/doc/reference/latest/ValidatingProofs/) | 摘要 |
| T11 | comparator（独立版，已弃用） | 陈述、公理、内核三项保证的原始说明 | [leanprover/comparator](https://github.com/leanprover/comparator) | 相关段落（README） |
| T12 | 独立检查器 | lean4checker（已弃用，`leanchecker` 进入核心）、nanoda、lean4export、lean4lean | [lean4checker](https://github.com/leanprover/lean4checker)、[nanoda_lib](https://github.com/ammkrn/nanoda_lib)、[lean4export](https://github.com/leanprover/lean4export)、[lean4lean](https://github.com/digama0/lean4lean) | 摘要 |
| T13 | LeanHammer | `hammer` tactic | [LeanHammer](https://github.com/JOSHCLUNE/LeanHammer) | 摘要 |
| T14 | AXLE 文档 | `simplify_theorems` 等工具 | [axle.axiommath.ai](https://axle.axiommath.ai/v1/docs/tools/simplify_theorems/) | 相关段落 |
| T15 | Metamath set.mm wiki | 证明最小化的约定 | [Minimizing](https://github.com/metamath/set.mm/wiki/Minimizing) | 摘要 |
| T16 | Isabelle | `unused_thms` 的文档化提交；`find_unused_assms` 的加入提交 | [unused_thms](https://isabelle.in.tum.de/repos/isabelle/rev/237328506a42)、[find_unused_assms](https://isabelle.in.tum.de/repos/isabelle/rev/689311986778) | 摘要 |
| T17 | Mizar | MML 修订记录 | [mizar.uwb.edu.pl](https://mizar.uwb.edu.pl/library/revisions/) | 摘要 |

## D 数据与仓库

| 编号 | 名称 | 链接 | 阅读程度 |
|---|---|---|---|
| D1 | LeanPolish 数据集 | [HF leanpolish-anon/lean-proof-compression](https://huggingface.co/datasets/leanpolish-anon/lean-proof-compression) | 摘要（元数据） |
| D2 | LeanPolish 代码与结果 | [paulinebourigault/leanpolish](https://github.com/paulinebourigault/leanpolish)：README、`experiments/metrics/results/headline.json`、`experiments/axle/README.md`、`experiments/frontier/README.md` | 相关段落 |
| D3 | miniF2F（Lean 4） | [yangky11/miniF2F-lean4](https://github.com/yangky11/miniF2F-lean4) | 摘要 |
| D4 | PutnamBench | [trishullab/PutnamBench](https://github.com/trishullab/PutnamBench) | 摘要 |
| D5 | Lean Workbook | [HF internlm/Lean-Workbook](https://huggingface.co/datasets/internlm/Lean-Workbook) | 摘要（元数据） |
| D6 | Goedel-Prover 的 Workbook 证明 | [HF Goedel-LM/Lean-workbook-proofs](https://huggingface.co/datasets/Goedel-LM/Lean-workbook-proofs) | 摘要（元数据与 LICENSE） |
| D7 | Mathlib | [leanprover-community/mathlib4](https://github.com/leanprover-community/mathlib4) | 相关段落（v4.35.0 的 linter 与脚本） |
| D8 | rh-proof-dependencies（James Shore） | [james-shore/rh-proof-dependencies](https://github.com/james-shore/rh-proof-dependencies) | 相关段落（README v0.2.1） |
| D9 | rh-proof-trimmed（James Shore） | [james-shore/rh-proof-trimmed](https://github.com/james-shore/rh-proof-trimmed) | 相关段落（README） |
| D10 | 社区 RH 仓库 | [leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis)，HEAD `75e2012` | 全文（Git 对象统计，见 `data/`；README、`verification/NOTES.md`、CI 工作流） |
| D11 | 原始版本的冻结镜像 | [homeowmorphism/riemann-hypothesis-original](https://github.com/homeowmorphism/riemann-hypothesis-original) | 摘要 |
| D12 | riemann-explorer | [bil022.github.io/riemann-explorer](https://bil022.github.io/riemann-explorer/) | 摘要 |
| D13 | Lean Refactor Arena | [HF Space delta-lab-ai/lean-refactor-arena](https://huggingface.co/spaces/delta-lab-ai/lean-refactor-arena) | 摘要 |
| D14 | OmniCAS 的固定副本 | [OmniCAS/riemann-hypothesis](https://github.com/OmniCAS/riemann-hypothesis)、[OmniCAS/riemann-hypothesis-omega](https://github.com/OmniCAS/riemann-hypothesis-omega) | 摘要 |
| D15 | Lean 分布式构建 | [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build) | 全文 |
| D16 | grh-lean：可读版 `grh/` 与紧凑版 `grh-compact/`（Luke Sernau 与 Anthropic 同事，借助 Claude；Apache-2.0，Copyright 2026 Anthropic, PBC） | [lsernau/grh-lean](https://github.com/lsernau/grh-lean)，提交 `72fead1` | 全文（两版源码统计、README、NOTICE、GUIDE、ATTRIBUTION） |
| D17 | MIT 对原始版本的核验页（Andrew Sutherland） | [math.mit.edu/~drew/grh](https://math.mit.edu/~drew/grh/) | 摘要（按版本追踪整理） |
| D18 | MIT 对两个短版本的核验页（Andrew Sutherland） | [math.mit.edu/~drew/shortgrh](https://math.mit.edu/~drew/shortgrh/) | 相关段落（页面 2026-11-26 02:13 UTC 版，02:48 UTC 读取） |

## C 社区记录

| 编号 | 内容 | 链接 | 阅读程度 |
|---|---|---|---|
| C1 | 社区 RH 仓库 `alpoge` 线（原 `main`）的 PR：#4、#9、#38、#44、#45、#55、#57、#58、#60、#61、#66、#67、#71、#74、#75、#90、#92、#120、#134、#185、#221、#243、#250（issue）、#295、#312、#318、#324、#378、#389、#438、#1508，以及批次 #1198、#2318、#4761（b6、b15、b23） | [pulls](https://github.com/leanprover-community/riemann-hypothesis/pulls?q=is%3Apr)；各 PR 在文档中单独链接 | 相关段落（#221、#295、#324、#438、#1198、#2318 读了说明；其余据 Zulip 与早先整理） |
| C2 | issue #3（文本追踪估计被更正为约 9%） | [issue #3](https://github.com/leanprover-community/riemann-hypothesis/issues/3) | 未重新核对 |
| C3 | 社区仓库的核验记录与 CI | [verification/NOTES.md](https://github.com/leanprover-community/riemann-hypothesis/blob/alpoge/verification/NOTES.md)、[challenge-files.yml](https://github.com/leanprover-community/riemann-hypothesis/blob/alpoge/.github/workflows/challenge-files.yml) | 相关段落 |
| C4 | Lean Zulip "Riemann Hypothesis" 频道（2026-11-25 从 #general 迁入）："Cleaning up the proof"、"Why clean up the proof"、"Conserving the original proof"、"Discussion: Alpöge Proves the Riemann Hypothesis" 等话题 | [频道](https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis)；`docs/rh-community-cleanup.md` 按消息逐条链接（44 条） | 相关段落（2026-11-22 至 11-25 的公开消息） |
| C5 | Lean Zulip "Riemann Hypothesis" 频道的 "New proof in 300k lines" 话题：grh-lean 作者对方法与改动的说明、各方的核验与统计 | [话题](https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines) | 相关段落（2026-11-25 21:26 至 11-26 02:49 UTC 的公开消息） |
| C6 | 社区仓库新 `main`（可读版）上的 PR：批次 m1–m4（#5631、#5636、#5645、#5657）、剪枝 #5652、未用字段 #5642、升 v4.37.0-rc1 #5769、challenge 文件检查 #5615 | [main 的提交记录](https://github.com/leanprover-community/riemann-hypothesis/commits/main) | 相关段落（提交记录与 `data/rh_mainline_merges.csv`） |
