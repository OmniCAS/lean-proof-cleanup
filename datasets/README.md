# Datasets and benchmarks

**Summary (English).** A catalogue of public datasets and benchmarks that matter for cleaning up and compressing Lean proofs: what each measures, its licence, its size and how to fetch it. None of the third-party data is copied into this repository; `fetch.py` downloads each item from its own host. Our own derived data is in [`../data/`](../data/). Checked on 2026-11-25; grh-lean and the MIT verification files added on 2026-11-26.

## 目录

"规模"取自托管方的元数据（Hugging Face API 的文件大小合计、GitHub API 的仓库大小），未标注的写"未查"。"许可证"取自数据集卡片、仓库元数据或 LICENSE 文件，没找到的写"未标注"，这类数据只能自己下载使用，不要转载。

### 证明压缩与重构

| 名称（`fetch.py` 中的键） | 链接 | 许可证 | 规模 | 测什么 / 有什么 | 怎么取 |
|---|---|---|---|---|---|
| LeanPolish 数据集（`leanpolish`） | [HF leanpolish-anon/lean-proof-compression](https://huggingface.co/datasets/leanpolish-anon/lean-proof-compression) | Apache-2.0 | 99 个文件，1.48 GB | 33,402 条经内核检查接受的局部编辑、65,596 条同一位置失败的尝试、完整候选池、LoRA 适配器；Lean / Mathlib v4.21.0 | `fetch.py fetch leanpolish --dest DIR`（默认上限 2 GB） |
| LeanPolish 代码（`leanpolish-code`） | [paulinebourigault/leanpolish](https://github.com/paulinebourigault/leanpolish) | Apache-2.0 | 未查 | 管线、独立的新进程验证器、token 计数器、每个实验的脚本与最终指标 | `git clone` |
| Lean Refactor Arena（`lean-refactor-arena`） | [HF Space delta-lab-ai/lean-refactor-arena](https://huggingface.co/spaces/delta-lab-ai/lean-refactor-arena) | 未标注 | — | NeurIPS 2026 证明重构比赛的排行榜 | 只给链接 |
| LeanLean（`leanlean`） | [OpenReview LssUgDHqQj](https://openreview.net/forum?id=LssUgDHqQj) | — | 64 个仓库，最多 17.4 万行（据摘要） | 仓库级压缩：12 小时内缩小仓库且主定理仍然有效 | 截至 2026-11-25 未找到公开数据 |
| Leanify（`leanify`） | [OpenReview ikCmxFDkbM](https://openreview.net/forum?id=ikCmxFDkbM) | — | 未查 | 证明集合压缩（证明项大小）与引理复用 | 截至 2026-11-25 未找到公开数据 |

### 压缩实验常用的输入

| 名称 | 链接 | 许可证 | 规模 | 用途 | 怎么取 |
|---|---|---|---|---|---|
| miniF2F（Lean 4，`minif2f-lean4`） | [yangky11/miniF2F-lean4](https://github.com/yangky11/miniF2F-lean4) | MIT | 浅克隆约 2 MB | 竞赛题陈述；ImProver、ProofOptimizer、LeanPolish 都用它报长度指标 | `git clone` |
| PutnamBench（`putnambench`） | [trishullab/PutnamBench](https://github.com/trishullab/PutnamBench) | Lean 4 与 Isabelle 部分 Apache-2.0，Coq 部分 MIT（README） | 仓库约 3.5 MB | Putnam 竞赛题陈述；较长证明的压缩测试 | `git clone` |
| Lean Workbook（`lean-workbook`） | [HF internlm/Lean-Workbook](https://huggingface.co/datasets/internlm/Lean-Workbook) | Apache-2.0 | 4 个文件，99 MB | 竞赛风格陈述 | `fetch.py fetch lean-workbook` |
| Goedel-Prover 的 Workbook 证明（`goedel-workbook-proofs`） | [HF Goedel-LM/Lean-workbook-proofs](https://huggingface.co/datasets/Goedel-LM/Lean-workbook-proofs) | MIT（数据集内 LICENSE） | 4 个文件，16 MB | 模型生成的证明；LeanPolish 在这类语料上省 token 约 20% | `fetch.py fetch goedel-workbook-proofs` |
| Mathlib（`mathlib4`） | [leanprover-community/mathlib4](https://github.com/leanprover-community/mathlib4) | Apache-2.0 | 未查 | 人写代码的对照：LeanPolish 在 Mathlib 子集上只省 0.53% token | `git clone` |

### 大仓库清理：Lean RH 开发

| 名称 | 链接 | 许可证 | 规模 | 有什么 | 怎么取 |
|---|---|---|---|---|---|
| rh-proof-dependencies（`rh-proof-dependencies`） | [james-shore/rh-proof-dependencies](https://github.com/james-shore/rh-proof-dependencies) | CC0-1.0 | 仓库约 44 MB | 从内核导出算出的五个最终定理的依赖闭包：被用声明、按目录的行数，v0.2.1 | `git clone` |
| rh-proof-trimmed | [james-shore/rh-proof-trimmed](https://github.com/james-shore/rh-proof-trimmed) | 仓库自己的说明：Lean 源码属于原作者，发布时没有许可证 | 未查 | 只用机械步骤的分阶段裁剪，每阶段有回执（构建、nanoda、con-leche 比对） | 只给链接 |
| 社区仓库（`rh-community`） | [leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis) | `original` 与 `alpoge` 分支未标注（原始源码发布时没有许可证）；`main` 现为 grh-lean 可读版 | 仓库约 1.07 GB | 清理的全部历史（`original`、`alpoge`、新 `main`）；`../scripts/rh_repo_stats.py` 的输入 | `fetch.py fetch rh-community --full` |
| grh-lean（`grh-lean`） | [lsernau/grh-lean](https://github.com/lsernau/grh-lean) | Apache-2.0（Copyright 2026 Anthropic, PBC） | 两个工程：可读版 `grh/` 805 个 `.lean` 文件、约 47.7 万行；紧凑版 `grh-compact/` 794 个文件、约 11.4 万行 | 原始开发的一次重写；本仓库 `data/tree_profiles.json` 的输入之一 | `git clone` |
| MIT 短版本核验文件（`mit-short-verification`） | [math.mit.edu/~drew/shortgrh](https://math.mit.edu/~drew/shortgrh/) | 未标注 | 日志与结果；两版导出各 4–5 GB | 构建、重放、外部内核、comparator 的逐项记录 | 只给链接 |
| 原始版本的冻结镜像 | [homeowmorphism/riemann-hypothesis-original](https://github.com/homeowmorphism/riemann-hypothesis-original) | 同上 | 未查 | 原样保存的源码与预建缓存 | 只给链接 |
| riemann-explorer | [bil022.github.io/riemann-explorer](https://bil022.github.io/riemann-explorer/) | 未标注 | — | 按支配树切分的 `riemannHypothesis` 依赖图浏览器（提交 `6c68212`，727,065 个声明） | 只给链接 |
| OmniCAS 的固定副本 | [OmniCAS/riemann-hypothesis](https://github.com/OmniCAS/riemann-hypothesis)、[OmniCAS/riemann-hypothesis-omega](https://github.com/OmniCAS/riemann-hypothesis-omega) | 同上 | 未查 | 构建实验用的固定版本，见 [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build) | 只给链接 |

### 相关但未核实数据链接的

证明修复方向的数据集（Coq 的 PRISM、Lean 的 APRIL、ProofRepairBench）见 [`../REFERENCES.md`](../REFERENCES.md) 里对应的论文；它们的数据下载地址与许可证这次没有核对。

## 为什么不转载

第三方数据要么太大（LeanPolish 1.48 GB、社区仓库约 1 GB），要么没有许可证（RH 源码），要么许可证允许但没必要复制（miniF2F、PutnamBench）。所以这里只放目录和获取脚本；我们自己从这些数据算出的结果在 [`../data/`](../data/)，附生成脚本。

## `fetch.py`

```bash
python3 datasets/fetch.py list
python3 datasets/fetch.py fetch minif2f-lean4 --dest /path/to/data
python3 datasets/fetch.py fetch leanpolish --dest /path/to/data --dry-run   # list files and sizes only
python3 datasets/fetch.py fetch rh-community --dest /path/to/data --full    # full history, about 1 GB
```

只用 Python 标准库与 `git`。Hugging Face 数据按文件逐个下载，总量超过 `--max-gb`（默认 2）时拒绝开始。
