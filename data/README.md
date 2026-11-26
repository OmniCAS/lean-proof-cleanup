# Derived data

**Summary (English).** Statistics we computed ourselves, without building anything. (1) Source-level indicators for seven public Lean trees of different provenance and size: Mathlib, three human-written research repositories (FLT, Carleson, PrimeNumberTheoremAnd), the original model-generated RH development and the two editions of its rewrite `lsernau/grh-lean` (`tree_profiles.*`). (2) For the large-repository example, the size of the community Lean RH repository ([leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis)) at the original archive, along the step-by-step cleanup line (branch `alpoge`) and on the new `main` (`rh_*`). Regenerate with the scripts in `../scripts/`.

## 文件

| 文件 | 内容 | 脚本 |
|---|---|---|
| `rh_revision_stats.csv` | 九个版本：`.lean` 文件数、总行数、正文行、import 行、theorem/lemma 行、Lean 工具链 | `scripts/rh_repo_stats.py` |
| `rh_mainline_merges.csv` | 两条线的每个主线提交（first-parent）：`alpoge` 线从 `7cce738` 到 `756a702`（146 个），新 `main` 从 `47fcde5` 到 `b7642ae`（13 个）；UTC 时间、PR 编号、改动文件数、增删行数 | 同上 |
| `rh_statements.json` | 五个最终定理的陈述文本（去多余空白）的 SHA-256，每个版本一份，并标出是否与原始归档相同 | 同上 |
| `tree_profiles.json`、`tree_profiles.csv` | 七棵树（Mathlib、FLT、Carleson、PrimeNumberTheoremAnd、RH 原始、grh-lean 可读版与紧凑版）的结构指标：文件、代码行、导入与注释占比、定理与引理数、每个定理的平均行数、每个文件的声明数、只有一个声明的文件占比、命名 `Prop` 定义、选项覆盖、重复短名、每千行代码的策略用法；版本与目录见 [`../cases/profiles.md`](../cases/profiles.md) | `scripts/profile_lean_trees.py` + `scripts/summarize_profiles.py` |

`tree_profiles.json` 只含计数。`profile_lean_trees.py` 的原始输出还列出声明名（含原始归档里的名字），因为原始归档没有许可证，原始输出不放进仓库。

## 口径

- **`.lean` 文件**：`git ls-tree -r` 里以 `.lean` 结尾的路径。`profile_lean_trees.py` 数的是目录里的全部 `.lean` 文件；`tree_profiles.json` 里的原始版本取自公开归档解压后的源码，共 175,187 个，比社区仓库 `original` 分支跟踪的 174,793 个多 394 个（差别没有追查），所以用 `original` 分支重跑时数字会略有出入。
- **正文行**：不是空行、不是 `import` 行（含 `public`/`meta`/`private` 前缀）、也不是单独的 `module` 行。#185 把 `import Mathlib` 展开成逐个模块的导入，凭空多出约 560 万行，所以不用总行数做主指标。
- **代码行**（`tree_profiles.json`）：再去掉注释，以及 `namespace`、`open`、`section`、`variable`、`set_option` 等脚手架行。
- **theorem/lemma 行**：以 `theorem` 或 `lemma` 开头的行（允许前面有 `@[...]`、`private`、`protected`）。是行数，不是内核层面的声明数。
- **主线提交的增删行**：`git log --first-parent --no-renames --shortstat`，即每个提交相对第一个父提交的差异；不识别改名，合并文件（#324）会表现为大量删除加大量新增。
- **陈述**：从 `src/Main.lean` 里取每个定理名与 `:=` 之间的文本。

## 重新生成

```bash
git clone https://github.com/leanprover-community/riemann-hypothesis.git rh   # about 1 GB
python3 scripts/rh_repo_stats.py --repo rh --out data                         # about 2 minutes

git clone https://github.com/lsernau/grh-lean.git grh-lean
git clone --depth 1 https://github.com/ImperialCollegeLondon/FLT.git        # 019805815d7d
git clone --depth 1 https://github.com/fpvandoorn/carleson.git             # f7487cc9da4d
git clone --depth 1 https://github.com/AlexKontorovich/PrimeNumberTheoremAnd.git   # e9906138410f
git clone https://github.com/leanprover-community/mathlib4.git && git -C mathlib4 checkout 56a00585
python3 scripts/profile_lean_trees.py raw-small.json compact=grh-lean/grh-compact/src \
    readable=grh-lean/grh/src flt=FLT/FLT carleson=carleson/Carleson \
    pnt=PrimeNumberTheoremAnd/PrimeNumberTheoremAnd mathlib=mathlib4/Mathlib
git -C rh worktree add ../rh-original 40e56bab                                # the original archive
python3 scripts/profile_lean_trees.py raw-original.json original=rh-original/src
python3 scripts/summarize_profiles.py --out data/tree_profiles.json --csv data/tree_profiles.csv \
    raw-small.json raw-original.json
```

浅克隆的三个仓库要先切到上面注释里的提交（`git fetch --depth 1 origin <commit> && git checkout FETCH_HEAD`），否则得到的是更新的版本。

每次调用里最大的树放在最后（`profile_lean_trees.py` 只为它记录其他树的名字出现在哪里）。

## 主要结果（2026-11-26）

| 版本 | `.lean` 文件 | 总行 | 正文行 | import 行 | theorem/lemma 行 | 工具链 |
|---|---|---|---|---|---|---|
| `40e56bab` 原始归档 | 174,793 | 17,374,215 | 14,621,937 | 909,822 | 813,194 | v4.33.1 |
| `7cce738` 11-22 快照 | 163,900 | 16,563,088 | 13,946,704 | 842,923 | 780,139 | v4.33.1 |
| `14f383e` #66 | 149,104 | 15,179,048 | 12,306,612 | 841,881 | 663,842 | v4.36.0 |
| `f38c099` #185、#221 之后 | 147,945 | 20,569,125 | 12,047,636 | 6,428,170 | 659,933 | v4.37.0-rc1 |
| `ecc801f` #324 | 61,935 | 17,249,054 | 12,431,988 | 2,950,339 | 637,897 | v4.37.0-rc1 |
| `75e2012` 11-25 上午 | 59,254 | 15,351,223 | 11,577,635 | 2,027,398 | 583,779 | v4.37.0-rc1 |
| `756a702` `alpoge` 第 23 批 | 58,735 | 13,710,772 | 11,217,763 | 817,983 | 566,775 | v4.37.0-rc1 |
| `47fcde5` 新 `main`：可读版移到根目录 | 805 | 477,151 | 430,803 | 1,744 | 18,133 | v4.35.0 |
| `b7642ae` 新 `main`：m1–m4 与升级之后 | 805 | 477,086 | 430,787 | 1,743 | 18,092 | v4.37.0-rc1 |

五个最终陈述在这九个版本里都与原始归档相同。

七棵树的指标并排见 [`../cases/profiles.md`](../cases/profiles.md)。摘要：

| 指标 | mathlib | flt | carleson | pnt | original | readable | compact |
|---|---|---|---|---|---|---|---|
| 代码行 | 1,341,536 | 36,067 | 39,396 | 142,434 | 13,295,716 | 283,663 | 69,090 |
| 定理 + 引理 | 190,303 | 2,240 | 2,607 | 8,293 | 818,755 | 18,227 | 7,088 |
| 每个定理的平均行数 | 7.5 | 15.6 | 16.8 | 17.5 | 16.7 | 21.0 | 11.1 |
| 只有一个声明的文件 | 3.7% | 18.5% | 7.3% | 9.4% | 45.0% | 0.6% | 9.7% |
