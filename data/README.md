# Derived data

**Summary (English).** Size statistics of the community Lean RH repository ([leanprover-community/riemann-hypothesis](https://github.com/leanprover-community/riemann-hypothesis)) computed by us from Git objects only, at the original archive, at five later commits and at `75e2012` (fetched 2026-11-25). Nothing was built and no Lean code was run. Regenerate with `scripts/rh_repo_stats.py`.

## 文件

| 文件 | 内容 |
|---|---|
| `rh_revision_stats.csv` | 每个版本：`.lean` 文件数、总行数、正文行、import 行、theorem/lemma 行、Lean 工具链 |
| `rh_mainline_merges.csv` | 从 `7cce738` 到 `75e2012` 主线上的每个提交（first-parent）：UTC 时间、PR 编号、改动文件数、增删行数 |
| `rh_statements.json` | 五个最终定理的陈述文本（去多余空白）的 SHA-256，每个版本一份，并标出是否与原始归档相同 |

## 口径

- **`.lean` 文件**：`git ls-tree -r` 里以 `.lean` 结尾的路径。
- **正文行**：不是空行、不是 `import` 行（含 `public`/`meta`/`private` 前缀）、也不是单独的 `module` 行。用它而不用总行数，是因为 #185 把 `import Mathlib` 展开成逐个模块的导入，凭空多出约 560 万行。
- **theorem/lemma 行**：以 `theorem` 或 `lemma` 开头的行（允许前面有 `@[...]`、`private`、`protected`）。这是行数，不是内核层面的声明数，只用来做前后对比。
- **主线合并的增删行**：`git log --first-parent --no-renames --shortstat`，即每个提交相对第一个父提交的差异；不识别改名，所以合并文件（#324）会表现为大量删除加大量新增。
- **陈述**：从 `src/Main.lean` 里取每个定理名与 `:=` 之间的文本。

## 重新生成

```bash
git clone https://github.com/leanprover-community/riemann-hypothesis.git rh   # about 1 GB
python3 scripts/rh_repo_stats.py --repo rh --out data --head 75e2012dcc6
```

在一台普通笔记本上约 2 分钟。换 `--head` 可以算更新的版本；`--rev REV:LABEL` 可以指定要统计的版本。

## 主要结果（2026-11-25）

| 版本 | `.lean` 文件 | 总行 | 正文行 | import 行 | theorem/lemma 行 | 工具链 |
|---|---|---|---|---|---|---|
| `40e56bab` 原始归档 | 174,793 | 17,374,215 | 14,621,937 | 909,822 | 813,194 | v4.33.1 |
| `7cce738` 11-22 快照 | 163,900 | 16,563,088 | 13,946,704 | 842,923 | 780,139 | v4.33.1 |
| `14f383e` #66 | 149,104 | 15,179,048 | 12,306,612 | 841,881 | 663,842 | v4.36.0 |
| `f38c099` #185、#221 之后 | 147,945 | 20,569,125 | 12,047,636 | 6,428,170 | 659,933 | v4.37.0-rc1 |
| `ecc801f` #324 | 61,935 | 17,249,054 | 12,431,988 | 2,950,339 | 637,897 | v4.37.0-rc1 |
| `75e2012` | 59,254 | 15,351,223 | 11,577,635 | 2,027,398 | 583,779 | v4.37.0-rc1 |

五个最终陈述在这六个版本里都与原始归档相同。从 `7cce738` 到 `75e2012` 的主线上有 135 个提交。
