# small-compactness：1.7 万行的单文件证明

**Summary (English).** Experiment on `CompactnessAndDegeneracy.lean` from `openai/ten-proofs` (17,236 code lines, 656 theorems, one file, model-generated, Apache-2.0): counterexamples to the compactness conjecture and to the degeneracy conjecture in extremal graph theory, five headline theorems fixed by two upstream challenge files. Stages done and gated so far: baseline, mechanical cleanup (1.001×), unroll by script (654 → 242 theorems at unchanged line count; build time 36 s → 140 s). The simplify, re-fold and shorten stages are not done yet. The text is in Chinese.

状态：**进行中**（2026-11-26）。阶段 0–2 已过闸门；阶段 3–5 未做。

## 问题

对一个单文件、一次生成的 1.7 万行证明：机械清理值多少；展开能不能完全由脚本做，做完以后命题个数、行数、构建时间各变多少。

## 对象

- 仓库与提交：[openai/ten-proofs](https://github.com/openai/ten-proofs) `94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`，Apache-2.0。
- 文件：`CompactnessAndDegeneracy.lean`（18,588 行，只导入 Mathlib）。
- 标题定理（由上游的 `ComparatorChallenges/J_CompactnessConjecture.lean` 与 `J_TwoDegenerateGraphs.lean` 固定）：`CompactnessConjecture.not_erdos_180`、`quantitativeCompactnessCounterexample`、`compactnessCounterexample_bigO`，`TwoDegenerateGraphs.twoDegenerateExtremalCounterexample`、`not_erdos_146`。
- 上游的 lakefile 没有用（它要联网取 Comparator）；工作副本只声明解答、Challenge 与闸门三个库。

## 环境

笔记本（12 核、16 GB），Lean v4.33.1 与 Mathlib `0df444a3`（上游钉的是 v4.32.0，本文件在 v4.33.1 上不改一字通过；同一文件在构建服务器的 v4.32.0 上也通过，107 秒）。构建不联网。闸门与脚本见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。

## 各阶段

| 阶段 | 代码行 | 定理 | 定义 | 只用一次的定理 | 每定理平均行 / 中位 / 最长 | 构建（秒）/ CPU（秒） | `.olean` | 闸门 |
|---|---|---|---|---|---|---|---|---|
| 0 基线 | 17,236 | 656 | 273 | 455（69%） | 22.9 / 15 / 172 | 28 / 118 | 37.3 MB | 过 |
| 1 机械 | 17,219 | 654 | 272 | 453 | 22.9 / 15 / 172 | 36 / 135 | 37.3 MB | 过 |
| 2 展开 | 17,245 | 242 | 272 | 116 | 62.0 / 12 / 4,071 | 140 / 224 | 38.0 MB | 过 |
| 3–5 | 未做 | | | | | | | |

逐阶段的完整指标在 [`metrics.jsonl`](metrics.jsonl)。

### 阶段 0：基线

原样构建；写闸门与度量；从构建后的环境导出声明依赖图。标题定理闭包之外的声明：0。被两处以上使用的定理 196 条，只被一处使用的定义 20 个。`grind` 用了 0 次。

### 阶段 1：机械清理

全部由报告驱动，不读数学。

| 检查 | 工具 | 结果 |
|---|---|---|
| 闭包外的声明 | 依赖图 + 可达性 | 0 |
| 类型完全相同的定理 | `GateAnalysis.dupReport` | 1 组 |
| 别名（证明体只是另一个项目常量作用在自己的绑定变量上） | `GateAnalysis.aliasReport` | 4 个，其中 3 个是纯别名，删掉并改引用 |
| 没用到的参数 | Batteries 的 `#lint only unusedArguments` | 3 个实例参数，去掉 |
| linter 提示 | 构建日志 | 18 处 `letI` / `haveI` 改成 `let` / `have` |

代码行 17,236 → 17,219（1.001 倍），定理 656 → 654。耗时约 10 分钟，构建 5 次。

一个更正：第一版依赖图把自动生成的 `recOn` 当成了用户声明，报出 4 个“不可达”；改了归属规则后是 0。

### 阶段 2：展开

`scripts/refold/unroll.py --retry`，输入是阶段 1 的依赖图。

| | 数量 |
|---|---|
| 候选（只被一条定理使用、不出现在使用者的陈述里） | 419 |
| 内联成功 | 412 |
| 构建失败后撤回 | 10，逐个重试后恢复 3，最终 7（`simp` 在新上下文里不再前进或超步数 4；源码里提到但证明项没有用到、依赖图里看不到的引用 3） |
| 没有尝试的单次使用定理 | 使用者是定义 27；使用者在别的作用域且是项证明 4；带属性 3 |
| 被两处以上使用，不动 | 196 |
| 需要提高心跳上限的声明 | 3（80 万、40 万、320 万） |
| 最深的嵌套 | 15 层 |
| 轮数与耗时 | 6 轮构建加 10 次单独重试，约 25 分钟（笔记本上同时有别的任务） |

结果：定理 654 → 242（2.70 倍），代码行基本不变（+26 行：26 处 `(open … in` 包装行、3 处心跳选项，减去少量合并），gzip 后大小 +13%（缩进变深）。最长的声明 4,071 行。构建从 36 秒变成 140 秒：声明之间原本并行检查，内联以后一个大声明只能顺序检查。

脚本在这个文件上额外要处理的情况（都来自失败的构建）：节变量（22 处 `variable`）按签名里出现的名字复制成绑定；46 处 `omit … in` 前缀里排除的实例不复制；使用者在别的 `namespace` / `open` 范围时用 `(open … in have …)` 包住（26 处）。

报告：[`unroll-s2.json`](unroll-s2.json)（每一次撤回的原因、每一轮的动作）。

## 到目前为止各阶段的贡献

| 阶段 | 代码行的比值 | 定理个数的比值 |
|---|---|---|
| 1 机械 | 1.001 | 1.003 |
| 2 展开 | 0.998 | 2.70 |
| 3–5 | 未做 | 未做 |

## 目前能说的

1. 这类单文件生成证明没有死代码，机械清理不值得期待；参照案例里“机械部分两到三倍”来自那个开发的生成方式。
2. 展开是纯机械的：97% 的候选一次过，剩下的由构建反馈处理。它把命题个数降到 37%，不省行。
3. 展开有构建成本：大声明顺序检查，构建慢了 3.9 倍，并且要提高心跳上限。参照案例的紧凑版全局设了很高的心跳上限，原因相同。
4. 行数的缩减只能来自之后的化简与再分块；这一部分还没做，不下结论。

## 复现

```bash
# 工作副本：上游的解答文件与两个 Challenge 文件（连同它们的 JSON），加上 Gate/Tools.lean、Gate/Analysis.lean
export REFOLD_REPO=<工作副本> REFOLD_OUT=<输出目录>
python3 -I scripts/refold/gate.py compactness s0-baseline
python3 -I scripts/refold/metrics.py compactness s0-baseline
python3 -I scripts/refold/unroll.py $REFOLD_REPO/CompactnessAndDegeneracy.lean \
    $REFOLD_OUT/depgraph/compactness-s1-mechanical.jsonl --headlines <五条标题定理的全名，逗号分隔> \
    --retry --build "cd $REFOLD_REPO && <隔离前缀> lake build CompactnessAndDegeneracy"
python3 -I scripts/refold/gate.py compactness s2-unroll
```

`refold-subjects.json`（放在工作副本里）：`{"compactness": {"solution": "CompactnessAndDegeneracy", "challenges": ["J_CompactnessConjecture", "J_TwoDegenerateGraphs"]}}`。
