# lean-proof-cleanup

**Summary (English).** How to clean up and simplify Lean 4 proofs, from a single theorem to a repository of hundreds of thousands of files, without changing what is proved. This repository collects a survey of methods and tools (LeanPolish and its contemporaries, the cleanup and checking tools built into Lean and Mathlib v4.35, and cross-system literature from Coq/Rocq, Isabelle, HOL, Mizar and Metamath), a layered plan (theorem, file, small repository, large repository) with a semantics-preserving gate (statements unchanged, no new axioms, kernel accepted), fourteen ranked cleanup ideas with an engineering pipeline, a catalogue of datasets and benchmarks, and a measured account of the community cleanup of the November 2026 Lean development that states the Riemann Hypothesis and Dirichlet GRH (reported machine-checked by third parties; its mathematics is unreviewed). Main findings: correctness comes from the gate, not from the editor; the large gains come from dependency pruning, deduplication and replacing lemmas by Mathlib's, not from tactic golf (LeanPolish saves 0.5% of tokens on human-written Mathlib but about 20% on machine-generated proofs); and in the RH repository, by our count from Git objects, `.lean` files fell from 174,793 to 59,254 and body lines by 20.8% with the five final statements unchanged, while no end-to-end comparator run on the cleaned tree has been reported. The documents are in Chinese.

## 这是什么

给一个 Lean 仓库，怎样在**不改变它证明了什么**的前提下把它变小、变快、变得可读。这里放五样东西：

1. **调研** `docs/survey.md`、`docs/literature.md`：LeanPolish（ICLR 2027 在审投稿）与同期工作（LeanLean、Leanify、AXLE、Lean Refactor、Proof-Refactor、ProofOptimizer、ImProver）；Lean / Mathlib v4.35 自带的 linter、TacticAnalysis、`lake shake`、`lake comparator`、`lake check`；以及 Coq/Rocq、Isabelle、HOL、Mizar、Metamath 和证明论里的相关论文，按方法与粒度分组。
2. **分层方案** `docs/layered-plan.md`：单个定理、单个文件、小仓库、大仓库各自的目标、手段、语义不变的验证（G0–G6 闸门）、自动化程度。
3. **优化思路与工程流水线** `docs/ideas-and-engineering.md`：14 条思路按收益、安全与成本排序；依赖图与可达性删除、去重、import 精简、批处理、增量与分布式构建、守卫、合并顺序、度量。
4. **数据集目录** `datasets/`：与证明清理相关的公开数据和基准（许可证、规模、测什么、怎么取），附获取脚本；第三方数据不转载。
5. **大仓库实例** `docs/rh-community-cleanup.md`、`data/`、`scripts/`：Lean RH 开发的社区清理，各项工作的数字与验证方式；我们从 Git 对象统计的规模数据和生成它的脚本。

## 核心判断

1. **正确性来自闸门，不来自编辑器。** 不论改写者是 linter、符号 pass 还是 LLM，都要过"重新编译 + 陈述与公理比对 + 内核接受"。清理前先冻结裁判（导出一份 Challenge，之后用 `lake comparator --challenge-from-export` 判），否则可信定义被一起改时查不出来。
2. **收益按依赖 > 热点 > 语法排序。** 删不可达代码、去重、换成 Mathlib 引理是大头；tactic 级精简在模型生成的证明上约省 20%，在人写的 Mathlib 上不到 1%。
3. **符号手段先于 LLM。** 确定性的 pass 可整库并行、几乎零成本；LLM 改写每条定理是美元量级，只用于剩下的热点和可读性。
4. **小仓库与大仓库的分界是"每批改动能不能全量重编"。** 大仓库要按依赖锥切片、只重编下游、按拓扑层分波并行、串行合并，并先迁到 module system（只改证明时不触发下游重编）。
5. **指标要选对。** 总行数会被 import 展开干扰（RH #185 凭空多出约 560 万行），文件数会被合并干扰；看正文行、声明数、依赖闭包大小和冷构建 CPU 时间。

## 关键数字

标记：**本仓库测**（`scripts/` 算出、`data/` 有结果）、**本仓库核对**（读了源码或原始文件）、**他人报告**（论文、PR、Zulip 上的说法，未独立复核）、**估计**（我们的推算）。

| 结论 | 数字 | 标记 | 出处 |
|---|---|---|---|
| RH 社区仓库 `.lean` 文件，原始 `40e56bab` → `75e2012`（2026-11-25） | 174,793 → 59,254（−66.1%） | 本仓库测 | `data/rh_revision_stats.csv` |
| 同上，正文行（去空行、import 行、`module` 行） | 14,621,937 → 11,577,635（−20.8%） | 本仓库测 | 同上 |
| 同上，theorem/lemma 行 | 813,194 → 583,779（−28.2%） | 本仓库测 | 同上 |
| 同上，总行数与 import 行 | 17,374,215 → 15,351,223（−11.6%）；import 行 909,822 → 2,027,398 | 本仓库测 | 同上 |
| 五个最终定理的陈述 | 六个版本都与原始归档逐字相同 | 本仓库测 | `data/rh_statements.json` |
| 文件数下降的主要来源 | #324：147,945 → 61,935 个文件（删 22,054 个薄包装、合并小模块） | 本仓库测 | `data/`；[#324](https://github.com/leanprover-community/riemann-hypothesis/pull/324) |
| 原始版本的依赖闭包 | 1,061,400 个声明中 804,912 个被五个定理用到（75.8%）；被用声明内部 10,737,728 行（61.8%） | 他人报告 | [D8] rh-proof-dependencies |
| `main` 上剩下的未用声明 | 约 1.5 万 | 他人报告（估计） | Zulip，见 `docs/rh-community-cleanup.md` §4 |
| 单靠删不可达代码的空间 | 已基本用完：主干声明内部的行估计已低于原始闭包的 1,074 万 | 估计 | `docs/rh-community-cleanup.md` §4 |
| 同陈述去重 | 约 1.65 万~1.7 万处（作者自报：完整构建 + nanoda + con-leche） | 他人报告 | [#295](https://github.com/leanprover-community/riemann-hypothesis/pull/295) |
| #185 之后的冷构建 | 约 103 CPU 小时（192 核），约一半花在加载 import | 他人报告 | Zulip，见 `docs/rh-community-cleanup.md` §5 |
| 原始版本的端到端核验 | 陈述比对与公理检查 58 分钟通过；Lean paranoid 内核 68 小时 53 分接受；nanoda 1 小时 33 分接受 | 他人报告 | Zulip，同上 §3 |
| 清理后 `main` 的端到端 comparator / 内核重放 | 截至 2026-11-25 无报告 | 他人报告的缺失 | 同上 §5 |
| LeanPolish 节省的 token | Mathlib 子集 0.53%，Goedel-Prover 证明 20.0%，miniF2F 22.6% | 他人报告 | [D2] `headline.json` |
| LeanPolish 与 AXLE 叠加（miniF2F） | 29.8% 与 27.1% → 先 LeanPolish 后 AXLE 35.9% | 他人报告 | [D2] `experiments/axle` |
| LeanLean：64 个真实仓库、12 小时 | 最强模型平均压缩分 48.3%，大头来自依赖重组 | 他人报告（摘要） | [P30] |
| Lean Refactor | 研究仓库 token 压缩 >20%，编译时间最多 −60% | 他人报告 | [P11] |
| 自动换成 `grind` | RH 主干上 `terminalToGrind` 的 26 条建议有 22 条更慢 | 他人报告（转述） | Zulip，见 `docs/rh-community-cleanup.md` §7 |
| Lean v4.35 已内置 | `lake shake --fix`、`lake comparator`（含 `--challenge-from-export`、`--paranoid`）、`lake check`、`lake lint`；Mathlib TacticAnalysis 的 `tryAtEachStep*` | 本仓库核对 | [T1]、[T4] |

（[P…]、[T…]、[D…] 是 [`REFERENCES.md`](REFERENCES.md) 的编号。）

## 目录

```text
README.md            本页
REFERENCES.md        编号出处：论文 P、工具与文档 T、数据与仓库 D、社区记录 C
LICENSE              Apache-2.0
docs/                文档（从 docs/README.md 开始读）
  layered-plan.md          分层方案与闸门
  ideas-and-engineering.md 优化思路排序与工程流水线
  rh-community-cleanup.md  Lean RH 开发的社区清理
  survey.md                LeanPolish 与 Lean 工具
  literature.md            跨系统文献
  open-problems.md         待解决问题与建议答案
datasets/            数据集与基准目录（README.md）和获取脚本 fetch.py
data/                我们算出的数据（RH 仓库的规模统计）
scripts/             生成 data/ 的脚本
```

## 怎么用

```bash
# 数据集目录与获取（只用标准库与 git）
python3 datasets/fetch.py list
python3 datasets/fetch.py fetch minif2f-lean4 --dest downloads

# 重新计算 RH 仓库的规模统计（只读 Git 对象，不构建）
git clone https://github.com/leanprover-community/riemann-hypothesis.git downloads/rh
python3 scripts/rh_repo_stats.py --repo downloads/rh --out data --head 75e2012dcc6
```

需要 Python 3.9 以上和 `git`。`downloads/` 已在 `.gitignore` 里。

## 关联仓库

| 仓库 | 关系 |
|---|---|
| [leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis) | 社区清理所在的上游仓库；`data/` 的统计对象 |
| [OmniCAS/riemann-hypothesis](https://github.com/OmniCAS/riemann-hypothesis)、[OmniCAS/riemann-hypothesis-omega](https://github.com/OmniCAS/riemann-hypothesis-omega) | 构建实验用的固定副本 |
| [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build) | 大仓库的分布式构建：调度、模拟与基准；本仓库"增量与分布式构建"一节的依据 |

## 关于 RH 的说法

这里只说：该 Lean 开发陈述了 Mathlib 的 `RiemannHypothesis` 与 Dirichlet L 函数的 GRH 形式，第三方报告机器核验通过，数学部分尚无人审阅。本仓库没有构建它，也没有运行 comparator。

## 许可证

本仓库的文字与脚本按 Apache-2.0 发布（见 `LICENSE`）。第三方数据、论文与源码不在本仓库里，各自的许可证见 `datasets/README.md` 与 `REFERENCES.md`。
