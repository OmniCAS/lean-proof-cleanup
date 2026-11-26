# A4 导入收窄（import narrowing）

## 1. 一句话判断

对构建时间最有效的机械手段之一，几乎不减少内容，而且会让"行数"指标失真。要不要做看导入结构而不是证明质量：维护者精心维护的库已把 `lake shake` 和 module system 放进 CI，没有存量；人写研究仓库最常见的问题是整库 `import Mathlib`，换成具体模块就是最便宜的提速；模型生成的大型开发文件多而小，每个文件都背一份导入，导入行占比明显偏高，加载导入可能占构建的大头。

## 2. 做什么

- `lake shake --fix` 按 `.olean` 推断每个文件真正需要的导入 [T1]；`#min_imports` 逐文件抽查 [T5]；`#redundant_imports`、`unused_transitive_imports` 找冗余与传递意义上没用的导入 [T9]。
- 把 `import Mathlib` 整库导入换成具体模块，或换成项目自己的少数几个 prelude 模块。
- 迁到 module system：区分 `public import` 与普通 `import`，让只改证明的改动不再触发下游重编 [T10]。
- 验收：从最终定理出发的 import 闭包没有变大，Challenge 文件未改。

## 3. 谁在用

- Mathlib：CI 里跑 `lake shake --add-public --keep-implied --keep-prefix --fix --explain` [T1]；8,624 个文件全部已是 module [T10]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 工具：Lake 内置的 `lake shake`（`--explain` 解释某条导入为何不能删，`-- shake: keep` 保留）[T1]，import-graph 的 `#min_imports`、`lake exe graph` 等 [T5] [T9]。
- 其他系统：iCoq/piCoq 的回归证明选择 [P53] [P54] 与 AFP 的分布式构建 [P55] 处理的是同一个成本，即改一处要重查多少下游（[E4](e4-build-acceleration.md)）。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#9]（删重复导入与 heartbeat 覆盖）、[#4]（`agitate`，读 `.olean` 的 shake 变体）、[#134]、[#185]（升 4.37 时把 `import Mathlib` 展开）、[#378] → [#438]（收窄导入、删死模块）；Martin Hanzlowsky 的 prelude 脚本（只有脚本）[z643065436]；Shore 的 S4 阶段（删多余 import）[D9]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Mathlib 的 CI 与 Lake 内置工具。
- 作者自述：RH 案例里的速度数字；RH 之外没有公开的收窄前后对比。

## 5. 作用层级

单个文件到大仓库：单个文件可以手工收窄，整库收窄后要重编下游锥体。module system 迁移是仓库级的一次性改动。不需要理解数学。

## 6. 正确性靠什么保证

- 导入只影响能看到哪些声明，不影响已检查的证明；能编译就说明没删多。
- 要额外确认：从最终定理出发的 import 闭包没有变大，Challenge 文件未改。
- `lake shake` 可能删掉只被 tactic、simp 集合或属性用到的导入；编译失败的放回并用 `-- shake: keep` 标注 [T1]。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | 导入行占全部行 1.0%（[profiles](../cases/profiles.md)）；8,624 个文件全部是 module（v4.35 源码） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 导入行占全部行 0.5%–2.0%（[profiles](../cases/profiles.md)）；收窄前后的构建对比没有公开数字 | 本仓库测 |
| 大仓库 × 模型生成（RH） | 导入行占全部行：原始 5.2%，重写后的可读版 0.4%、紧凑版 1.2%（[profiles](../cases/profiles.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | #185 之后冷构建约 103 CPU 小时，约一半花在加载导入，72% 的 CPU 在 5 秒以内的小模块上 [z642808607] | 他人报告 |
| 大仓库 × 模型生成（RH） | #134 编译 −22%~25%，#378 −10% [z642699975] [z642956589] | 他人报告 |
| 大仓库 × 模型生成（RH） | 原始版本 753,261 条项目内导入中 367,050 条被其他导入蕴含 | 他人报告（Drew Carlson，11-21 Zulip） |
| 大仓库 × 模型生成（RH） | `alpoge` 线 import 行：909,822 → 6,428,170（#185 展开后）→ 2,950,339（#324 后）→ 817,983（第 23 批） | 本仓库测（`data/rh_revision_stats.csv`） |

导入行占比只是可收窄空间的间接指标。RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 展开 `import Mathlib` 会让总行数凭空增加，验收要用正文行（[E3](e3-metrics.md)）（例：Lean RH 开发里 #185 一次多出约 560 万行）。
- `lake shake` 可能删掉只被 tactic 或 simp 集合用到的导入；用 `-- shake: keep` 标注。
- 收窄后对上游库的拆文件、改名更敏感：整库导入不怕上游挪动，具体模块会。
- module system 迁移要理顺 `public`/`@[expose]`，仓库越大越是一次性的大改动。

## 9. 什么时候用

- 在删除类工作（[A1](a1-reachability-pruning.md)–[A3](a3-linter-driven-cleanup.md)）之后做，在合并模块（[A5](a5-module-regrouping.md)）之前或同时做；module system 迁移最好在大规模改证明之前完成。
- 按来源：人写研究仓库先换掉整库导入；模型生成的大型开发把它当构建提速的第一项；维护的库只需保持 CI。

## 10. 未解决的问题

- 项目级 prelude 模块（把常用导入收拢到少数几个文件）是否真的缩小了 import 闭包，还是只减少了行数？没人验证 [z643077118]。
- module system 下只改证明时，下游重编在大仓库上实际省多少？没有公开测量。
- 人写研究仓库收窄导入之后冷构建能快多少？没有公开数字。

[#4]: https://github.com/leanprover-community/riemann-hypothesis/pull/4
[#9]: https://github.com/leanprover-community/riemann-hypothesis/pull/9
[#134]: https://github.com/leanprover-community/riemann-hypothesis/pull/134
[#185]: https://github.com/leanprover-community/riemann-hypothesis/pull/185
[#378]: https://github.com/leanprover-community/riemann-hypothesis/pull/378
[#438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[D9]: ../REFERENCES.md
[P53]: ../REFERENCES.md
[P54]: ../REFERENCES.md
[P55]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[T9]: ../REFERENCES.md
[T10]: ../REFERENCES.md
[z642699975]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699975
[z642808607]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642808607
[z642956589]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642956589
[z643065436]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643065436
[z643077118]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643077118
