# medium-nonsofic：3.4 万行的单文件证明

**Summary (English).** Experiment on `NonSoficGroup.lean` from `openai/ten-proofs` (model-generated, Apache-2.0, 32,084 code lines, 1,073 theorems, one headline theorem: a finitely presented non-sofic group exists). In progress: the baseline is gated on the build server with the native toolchain; the unroll stage is running. Baseline findings: no declaration outside the headline closure, 74% of theorems used exactly once, 14 groups of theorems with identical statements. The text is in Chinese.

状态：**进行中**（2026-11-26）。阶段 0 已过闸门；阶段 2 在跑；其余未做。

## 对象

- 仓库与提交：[openai/ten-proofs](https://github.com/openai/ten-proofs) `94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`，Apache-2.0。
- 文件：`NonSoficGroup.lean`（34,440 行，只导入 Mathlib）。
- 标题定理（上游 `ComparatorChallenges/D_NonSoficGroup.lean` 固定）：`SoficGroups.SourceTopLevelCompressionFinal.exists_finitelyPresented_nonsofic_group`。

## 环境

构建服务器，Lean v4.32.0 与 Mathlib `v4.32.0`（上游钉的版本，代码未改），16 个物理核，无网络。见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。

## 阶段 0：基线（已过闸门）

| 指标 | 值 |
|---|---|
| 代码行 / 总行 | 32,084 / 34,441 |
| 定理 / 定义 / 全部声明 | 1,073 / 335 / 1,437 |
| 标题定理闭包之外的声明 | 0 |
| 只被一处使用的定理 | 794（74%） |
| 被两处以上使用的定理 | 278 |
| 每个定理的平均行数 / 中位 / 最长 | 27.4 / 17 / 275 |
| 构建 | 113 秒墙钟，597 秒 CPU |
| `.olean` | 39.6 MB |

机械检查的发现（还没有处理）：

| 检查 | 结果 |
|---|---|
| 类型完全相同的定理 | 14 组，共 29 条（可删 15 条，占定理的 1.4%）；多数是同一条引理在两个命名空间里各证了一遍 |
| 别名（证明体只是另一个项目常量作用在自己的绑定变量上） | 31 个，其中多数是实例的转述 |
| 没用到的参数 | 0 |

与两个小对象相比，这个文件有少量重复陈述，仍然没有死代码。

## 之后的阶段

未做的不报数字。展开的结果出来后更新本页。
