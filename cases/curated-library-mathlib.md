# 案例：精心维护的库 × Mathlib

**Summary (English).** Mathlib is the curated end of the provenance axis: maintainers review every change, so there is little to compress and cleanup is continuous rather than a project. Its practice is still the reference for every Lean repository: linters on by default, `lake shake` in CI, deprecation aliases with dates, technical-debt counters, timing-guarded tactic analysis, the module system. Proof-shortening tools gain almost nothing here (LeanPolish 0.53% of tokens; ImProver 2 about 0.016 in length). The text is in Chinese.

## 判断

在精心维护的库里，证明已经被人和 linter 反复磨过，单个证明几乎压不动；维护的重点是接口稳定、构建时间、导入结构和技术债，而不是缩短。它对其他仓库的价值在于一整套"持续、自动、可审"的做法，可以直接照搬。

## 做法（本仓库核对 Mathlib v4.35.0 源码与文档，见 [`../docs/survey.md`](../docs/survey.md) §3）

| 做法 | 内容 |
|---|---|
| 默认开启的 linter | 未用 tactic、未用 simp 参数、多余 `simpa`、未用变量等，构建时就报告 [T2] [T3] |
| 风格集合 | `longFile`（1,500 行）、`style.maxHeartbeats`（每处覆盖要写原因）、`flexible`（非终结 `simp`）等；下游可用 `weak.linter.mathlibStandardSet` 打开 [T3] |
| 环境 linter | `#lint` / `lake lint`：未用参数、`unusedHavesSuffices`、simp 正规形等 [T8] |
| 导入 | CI 里跑 `lake shake --add-public --keep-implied --keep-prefix --fix --explain` [T1] |
| 改名与删除 | `@[deprecated new (since := …)]` 别名；过期的弃用由 CI 的定时工作流清理（默认约 6 个月）；维护论文讨论了这套弃用流程 [P50] |
| 技术债 | 技术债计数脚本定期统计（已移到 `mathlib-ci` 仓库）；维护论文把技术债跟踪列为维护手段之一 [P50] |
| tactic 分析 | TacticAnalysis 的若干 pass 默认开启，昂贵的定期运行并发到 Zulip [T4] |
| 构建 | 全部 8,624 个文件已迁到 module system；只改证明不触发下游重编 [T10] |

## 证据（他人报告与本仓库测）

| 结论 | 数字 | 标记 |
|---|---|---|
| LeanPolish 在 Mathlib 子集上节省的 token | 0.53%（对照：模型生成的证明约 20%） | 他人报告 [P12] |
| ImProver 2 在 Mathlib 上的长度改进 | 约 0.016 | 他人报告 [P10] |
| 44.8% 的定理不被其他声明引用 | 是对外的 API，不是死代码 | 他人报告 [P38] |
| 每个定理的平均行数 | 7.5（研究仓库 15.6–17.5，见 [profiles](profiles.md)） | 本仓库测 |

## 能带走的

- 清理是流程，不是一次性运动：linter、shake、弃用与技术债统计都进 CI。
- "未被引用"不等于"可删"：库的叶子是给用户的接口。对以几个最终定理为目标的仓库则相反，从目标出发的闭包之外都是候选（[A1](../methods/a1-reachability-pruning.md)）。
- 在这一格里，B 层的缩短收益很小，A3、A4、A6 和 E 层的流程收益最大。

## 缺口

- Mathlib 的维护经验主要写在两篇维护论文 [P49] [P50] 和 CI 配置里；技术债的长期数字没有系统的公开统计。

[P10]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[P49]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T2]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[T4]: ../REFERENCES.md
[T8]: ../REFERENCES.md
[T10]: ../REFERENCES.md
