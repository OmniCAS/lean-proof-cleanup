# A4 导入收窄（import narrowing）

## 1. 一句话判断

对构建时间最有效的机械手段（大仓库里加载导入约占一半 CPU），但几乎不减少内容，而且会让"行数"指标失真。

## 2. 做什么

- `lake shake --fix` 按 `.olean` 推断每个文件真正需要的导入 [T1]；`#min_imports` 逐文件抽查 [T5]。
- 把 `import Mathlib` 整库导入换成具体模块，或换成项目自己的几个 prelude 模块。
- 迁到 module system：区分 `public import` 与普通 `import`，让只改证明的改动不再触发下游重编 [T10]。

## 3. 谁在用

- 社区 `alpoge` 线：[#9]（删重复导入与 heartbeat 覆盖）、[#4]（`agitate`，读 `.olean` 的 shake 变体）、[#134]、[#185]（升 4.37 时把 `import Mathlib` 展开）、[#378] → [#438]（收窄导入、删死模块）。
- Martin Hanzlowsky 的 prelude 脚本（只有脚本） [z643065436]。
- Shore 的 S4 阶段（删多余 import） [D9]。

## 4. 证据等级

主流在用。速度数字多为作者自报。

## 5. 作用层级

文件到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 导入只影响能看到哪些声明，不影响已检查的证明；能编译就说明没删多。
- 要额外确认：从最终定理出发的 import 闭包没有变大，Challenge 文件未改。

## 7. 效果

| 数字 | 标记 |
|---|---|
| #185 之后冷构建约 103 CPU 小时，约一半花在加载导入，72% 的 CPU 在 5 秒以内的小模块上 [z642808607] | 他人报告 |
| #134 编译 −22%~25%，#378 −10% [z642699975] [z642956589] | 他人报告 |
| 原始版本 753,261 条项目内导入中 367,050 条被其他导入蕴含 | 他人报告（Drew Carlson，11-21 Zulip） |
| `alpoge` 线 import 行：909,822 → 6,428,170（#185 展开后）→ 2,950,339（#324 后）→ 817,983（第 23 批） | 本仓库测（`data/rh_revision_stats.csv`） |
| import 行占全部行：原始 5.2%，可读版 0.4%，紧凑版 1.2% | 本仓库测（`data/versions_summary.json`） |

## 8. 代价与坑

- 展开 `import Mathlib` 会让总行数凭空增加几百万（#185 一次多出约 560 万行），所以验收要用正文行（[E3](e3-metrics.md)）。
- `lake shake` 可能删掉只被 tactic 或 simp 集合用到的导入；用 `-- shake: keep` 标注。
- module system 迁移要理顺 `public`/`@[expose]`，在大仓库上是一次性大改动。

## 9. 什么时候用

在删除类工作（[A1](a1-reachability-pruning.md)–[A3](a3-linter-driven-cleanup.md)）之后做，在合并模块（[A5](a5-module-regrouping.md)）之前或同时做；module system 迁移最好在大规模改证明之前完成。

## 10. 未解决的问题

- prelude 模块是否真的缩小了 import 闭包，还是只减少了行数？没人验证 [z643077118]。
- module system 下只改证明时，下游重编在 RH 规模上实际省多少？

[#4]: https://github.com/leanprover-community/riemann-hypothesis/pull/4
[#9]: https://github.com/leanprover-community/riemann-hypothesis/pull/9
[#134]: https://github.com/leanprover-community/riemann-hypothesis/pull/134
[#185]: https://github.com/leanprover-community/riemann-hypothesis/pull/185
[#378]: https://github.com/leanprover-community/riemann-hypothesis/pull/378
[#438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[D9]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[T10]: ../REFERENCES.md
[z642699975]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699975
[z642808607]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642808607
[z642956589]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642956589
[z643065436]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643065436
[z643077118]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643077118
