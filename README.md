# lean-proof-cleanup

**Summary (English).** How to clean up, simplify and compress Lean 4 proofs, from a single theorem to a repository of hundreds of thousands of files, without changing what is proved. This repository collects twenty-three cleanup routes in five tiers, one file each (`methods/`); a survey of tools and literature (LeanPolish and its contemporaries, the cleanup and checking tools built into Lean and Mathlib v4.35, and cross-system work on Coq/Rocq, Isabelle, HOL, Mizar and Metamath); a layered plan with a semantics-preserving gate (statements unchanged, no new axioms, kernel accepted); ranked ideas and an engineering pipeline; a catalogue of datasets; and a measured account of the November 2026 Lean development that states the Riemann Hypothesis and Dirichlet GRH, both the community's step-by-step cleanup and the two-edition rewrite `lsernau/grh-lean`. These developments are reported machine-checked by third parties; their mathematics is unreviewed. Main findings: the unit of compression is the number of statements, not the length of proofs (theorems and lemmas: 818,755 in the original, 18,227 and 7,088 in the two short editions, while lines per theorem stay at 16.7, 21.0 and 11.1); mechanical, statement-preserving cleanup has a ceiling of roughly two to three times (the community line reached −23% of body lines in five days), and the two orders of magnitude came from rewriting on the same proof skeleton; correctness comes from the gate, not from the editor, and the short editions could be checked by several independent kernels within hours because they are small enough to rebuild. The documents are in Chinese.

## 这是什么

给一个 Lean 仓库，怎样在**不改变它证明了什么**的前提下把它变小、变快、变得可读。这里放：

1. **路线** `methods/`：23 条清理与压缩路线，分五层：A 机械且保持陈述、B 逐个定理的局部改写、C 跨定理的结构重构、D 重写数学、E 所有路线共用的流程与闸门。每条一个文件，先给判断，再写做法、谁在用、证据等级、作用层级、正确性保证、效果、代价、适用时机和未解决的问题。从 [`methods/README.md`](methods/README.md) 开始读。
2. **分层方案** `docs/layered-plan.md`：单个定理、单个文件、小仓库、大仓库各自的目标、手段、语义不变的验证（G0–G6 闸门）与自动化程度。
3. **优化思路与工程流水线** `docs/ideas-and-engineering.md`：依赖图与可达性删除、去重、import 精简、批处理、增量与分布式构建、守卫、合并顺序、度量。
4. **大仓库实例**：Lean RH 开发的社区清理与 2026-11-25 的切换（`docs/rh-community-cleanup.md`），grh-lean 两个短版本与原始代码的对比（`docs/grh-compact-vs-original.md`），紧凑版的可靠性审查（`docs/grh-compact-reliability.md`）；统计数据在 `data/`，生成脚本在 `scripts/`。
5. **调研** `docs/survey.md`、`docs/literature.md`，**数据集目录** `datasets/`，**待解决问题** `docs/open-problems.md`。

## 核心判断

1. **正确性来自闸门，不来自编辑器。** 不论改写者是 linter、符号 pass 还是 LLM，都要过"重新编译 + 陈述与公理比对 + 内核接受"。清理前先冻结裁判（导出一份 Challenge，之后用 `lake comparator --challenge-from-export` 判），否则可信定义被一起改时查不出来。
2. **压缩的单位是命题个数。机械路线的上限约两到三倍，两个数量级要靠重写。** 原始版本里 24% 的声明没被用到，约 24.1 万个定理重复先前的陈述，48,367 个文件是陈述包装，12.8% 的行是导入与脚手架；社区逐步清理五天做到正文行 −23%。grh-lean 在同一个证明骨架上重写，命题个数缩小 115 倍（紧凑版），而每个定理的平均长度几乎不变。
3. **先机械，后重写；符号手段先于 LLM。** 确定性的 pass 可整库并行、几乎零成本；LLM 逐个改写定理是美元量级，碰不到命题个数这个大头；结构性缩小需要理解证明（展开、通用化、去包装层、换论证）。
4. **小仓库与大仓库的分界是"每批改动能不能全量重编"。** 大仓库要按依赖锥切片、只重编下游、按拓扑层分波并行、串行合并；能缩到整体重建的规模，核验就从"构建通过"变成"多内核检查完"。
5. **指标要选对。** 总行数会被 import 展开干扰（RH #185 一次净增约 560 万行），文件数会被合并干扰，源码长度与证明项大小可以反向（紧凑版源码是可读版的 1/4，导出却大 15%）；看命题个数、正文行、依赖闭包大小和冷构建 CPU 时间。

## 关键数字

标记：**本仓库测**（`scripts/` 算出、`data/` 有结果，或本机运行）、**本仓库核对**（读了源码或原始文件）、**他人报告**（论文、PR、Zulip、MIT 核验页上的说法，未独立复核）、**估计**（我们的推算）。

| 结论 | 数字 | 标记 | 出处 |
|---|---|---|---|
| 定理 + 引理：原始 / grh-lean 可读版 / 紧凑版 | 818,755 / 18,227 / 7,088 | 本仓库测 | `data/versions_summary.json` |
| 每个定理的平均行数（同上三版） | 16.7 / 21.0 / 11.1 | 本仓库测 | 同上 |
| 代码行（去注释、空行、导入、脚手架） | 13,295,716 / 283,663 / 69,090 | 本仓库测 | 同上 |
| 紧凑版的声明名在原始版本出现过的比例 | 14%（1,344 / 9,916） | 本仓库测 | 同上 |
| 社区 `alpoge` 线（原 `main`）第 23 批 `756a702` 相对原始 `40e56bab` | `.lean` 文件 174,793 → 58,735；正文行 −23.3%；theorem/lemma 行 −30.3% | 本仓库测 | `data/rh_revision_stats.csv` |
| 五个最终陈述 | 九个统计版本（原始、`alpoge` 线各点、新 `main`）都与原始文本相同 | 本仓库测 | `data/rh_statements.json` |
| 新 `main` 换上时与 grh-lean 可读版的关系 | `src` 的 Git 树哈希相同（`55fe9c6c`） | 本仓库核对 | `docs/rh-community-cleanup.md` §0 |
| 原始版本的依赖闭包 | 1,061,400 个声明中 804,912 个被用到（75.8%） | 他人报告 | [D8] |
| 机械路线的合计上限 | 约两到三倍 | 估计 | `docs/grh-compact-vs-original.md` §3 |
| 导出大小：原始 / 可读版 / 紧凑版 | 61.6 GB / 4.49 GB / 5.17 GB | 他人报告 | [D17]、[D18] |
| 紧凑版的完整核验 | MIT：六个检查器接受，`lake comparator --paranoid` 两台机器通过 | 他人报告 | [D18]（02:13 UTC 版） |
| 紧凑版的本机断网构建 | 9,843 个任务零错误（12 核、16 GB，约 2 小时 33 分）；`#print axioms` 只有三条标准公理 | 本仓库测 | `docs/grh-compact-reliability.md` §6 |
| 清理后的 `alpoge` 线的端到端核验 | 截至 2026-11-26 无报告 | 他人报告的缺失 | `docs/rh-community-cleanup.md` §0 |
| LeanPolish 节省的 token | Mathlib 子集 0.53%，Goedel-Prover 证明 20.0%，miniF2F 22.6% | 他人报告 | [D2] |
| LeanLean：64 个真实仓库、12 小时 | 最强模型平均压缩分 48.3%，大头来自依赖重组 | 他人报告（摘要） | [P30] |
| 自动换成 `grind` | `alpoge` 线上 `terminalToGrind` 的 26 条建议有 22 条更慢 | 他人报告（转述） | `methods/b2-tactic-golf-and-automation.md` |
| Lean v4.35 已内置 | `lake shake --fix`、`lake comparator`（含 `--challenge-from-export`、`--paranoid`）、`lake check`、`lake lint`；Mathlib TacticAnalysis 的 `tryAtEachStep*` | 本仓库核对 | [T1]、[T4] |

（[P…]、[T…]、[D…] 是 [`REFERENCES.md`](REFERENCES.md) 的编号。）

## 目录

```text
README.md            本页
REFERENCES.md        编号出处：论文 P、工具与文档 T、数据与仓库 D、社区记录 C
LICENSE              Apache-2.0
methods/             23 条路线，每条一个文件；README.md 是总览、矩阵与推荐顺序
docs/                文档（从 docs/README.md 开始读）
  layered-plan.md            分层方案与闸门
  ideas-and-engineering.md   优化思路排序与工程流水线
  rh-community-cleanup.md    Lean RH 开发的社区清理与 2026-11-25 的切换
  grh-compact-vs-original.md grh-lean 两个短版本与原始代码的对比
  grh-compact-reliability.md 紧凑版的陈述与信任面审查
  survey.md                  LeanPolish 与 Lean 工具
  literature.md              跨系统文献
  open-problems.md           待解决问题与建议答案
datasets/            数据集与基准目录（README.md）和获取脚本 fetch.py
data/                我们算出的数据：RH 仓库各版本的规模、主线提交、陈述哈希、三版源码的汇总统计
scripts/             生成 data/ 的脚本：rh_repo_stats.py、compare_versions.py、summarize_versions.py
```

## 怎么用

```bash
# 数据集目录与获取（只用标准库与 git）
python3 datasets/fetch.py list
python3 datasets/fetch.py fetch minif2f-lean4 --dest downloads

# 重新计算 RH 仓库各版本的规模统计（只读 Git 对象，不构建）
git clone https://github.com/leanprover-community/riemann-hypothesis.git downloads/rh
python3 scripts/rh_repo_stats.py --repo downloads/rh --out data

# 比较几份源码树（代码行、声明、策略用法），再汇总成只含计数的 JSON
git clone https://github.com/lsernau/grh-lean.git downloads/grh-lean
python3 scripts/compare_versions.py downloads/versions.json \
    compact=downloads/grh-lean/grh-compact/src readable=downloads/grh-lean/grh/src
python3 scripts/summarize_versions.py downloads/versions.json downloads/versions_summary.json
```

需要 Python 3.9 以上和 `git`。`downloads/` 已在 `.gitignore` 里。`data/versions_summary.json` 另含原始版本，输入是公开归档解压后的源码；用社区仓库 `original` 分支的 `src/` 重跑会少 394 个文件，数字略有出入（见 `data/README.md`）。

## 关联仓库

| 仓库 | 关系 |
|---|---|
| [leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis) | 社区清理所在的上游仓库：`original` 分支是原始归档，`alpoge` 分支是逐步清理线，`main` 现为 grh-lean 可读版 |
| [lsernau/grh-lean](https://github.com/lsernau/grh-lean) | 两个短版本（可读版与紧凑版）；Apache-2.0，Copyright 2026 Anthropic, PBC |
| [OmniCAS/riemann-hypothesis](https://github.com/OmniCAS/riemann-hypothesis)、[OmniCAS/riemann-hypothesis-omega](https://github.com/OmniCAS/riemann-hypothesis-omega) | 构建实验用的固定副本 |
| [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build) | 大仓库的分布式构建：调度、模拟与基准 |

## 关于 RH 的说法

这里只说：这些 Lean 开发陈述了 Mathlib 的 `RiemannHypothesis` 与 Dirichlet L 函数的 GRH 形式，第三方报告机器核验通过，数学部分尚无人审阅。本仓库只构建了 grh-lean 紧凑版并打印了它的公理，没有构建其他版本，也没有运行 comparator。

## 许可证

本仓库的文字与脚本按 Apache-2.0 发布（见 `LICENSE`）。第三方数据、论文与源码不在本仓库里，各自的许可证见 `datasets/README.md` 与 `REFERENCES.md`。文档里引用的 grh-lean 代码按其 Apache-2.0 许可证注明出处；对没有许可证的原始归档只作评论所需的短节选。

[D2]: REFERENCES.md
[D8]: REFERENCES.md
[D17]: REFERENCES.md
[D18]: REFERENCES.md
[P30]: REFERENCES.md
[T1]: REFERENCES.md
[T4]: REFERENCES.md
