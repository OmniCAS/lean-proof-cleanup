# A5 模块重组（module regrouping）

## 1. 一句话判断

它是合并而不是删除：文件数和每文件开销立竿见影地下降，内容几乎不变，指标上最容易被误读。只在"文件多而碎"的仓库上值得做，这是模型生成的大型开发的典型特征；维护者精心维护的库走的是反方向（超长文件要拆），人写研究仓库的文件粒度通常已经合适，不需要做。

## 2. 做什么

- 删薄包装：只含一个"用另一个名字转述已有定理"的模块，把引用改指原定理，再删掉它。
- 沿 import 图把小模块合并成大文件（"clump"），减少每个文件的启动与加载开销。
- 反方向：超长文件按主题拆分，让增量重编和并行构建的粒度变细。
- 全部由脚本生成；换基线时重跑脚本，而不是 rebase 生成的提交。
- 先看诊断指标：只有一个声明的文件占比、每个文件的声明数（[profiles](../cases/profiles.md)）。

## 3. 谁在用

- Mathlib：风格 linter `longFile` 要求文件不超过 1,500 行 [T3]；拆文件是 Mathlib 维护的常规工作 [P50]（见 [Mathlib 案例](../cases/curated-library-mathlib.md)）。
- 其他系统：Mizar 的 MML 定期修订包括重组 [P48]；seL4 的大规模证明管理总结了证明的组织与维护经验 [P51]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#324]（Kim Morrison：删 22,054 个薄包装模块，再按 import 图合并）、[#58] / [#61]（折叠转发包装）、[#44]（草稿）；[#120]（Rohan Arun，合并小文件；没有合并，但启发了 #324）；原因见 issue [#250]：每个文件的导入开销约占编译 CPU 的一半。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 主流在用：Mathlib 的拆分规则；RH 案例里的合并（#324 已合并）。
- 仅声称：RH 案例里 #120 的速度数字（构建不过）。
- "合并能提速"在 RH 之外没有公开证据。

## 5. 作用层级

小仓库到大仓库；只有文件数远超内容需要时才有意义。不需要理解数学。

## 6. 正确性靠什么保证

- 合并文件不改声明，只改它们所在的文件；能编译、陈述文件未改即可。
- 风险是名字冲突与 `open`/`namespace` 作用域变化，要有排除清单和静态检查（例：Lean RH 开发里 #324 合并后约 0.7% 的模块因名字捕获失败 [#324]）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | 只有一个声明的文件 3.7%，每个文件 30.0 个声明；方向是拆而不是合（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PNT） | 只有一个声明的文件 7.3%–18.5%，每个文件 14.3–38.9 个声明（[profiles](../cases/profiles.md)）；没有合并的公开数字 | 本仓库测 |
| 大仓库 × 模型生成（RH） | 原始版本只有一个声明的文件占 45.0%，每个文件 6.1 个声明；文件名含 `Statement` 的文件 48,367 个（28%）（[profiles](../cases/profiles.md)；后者见 [grh-compact-vs-original](../cases/rh/grh-compact-vs-original.md)） | 本仓库测 |
| 大仓库 × 模型生成（RH） | #324：`.lean` 文件 147,945 → 61,935（−58%）；import 行 6,428,170 → 2,950,339（`data/rh_revision_stats.csv`） | 本仓库测 |
| 大仓库 × 模型生成（RH） | 同上，PR 说明：`src/` 148,230 → 62,159 个文件 [#324] | 他人报告 |
| 大仓库 × 模型生成（RH） | #120 自报 47,884 个文件（−67.9%），编译时间 −24%~45%；构建不过，未合并 [z642695795] | 他人报告（仅声称） |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- 文件数不再代表内容多少（例：Lean RH 开发里 #324 之后正文行反而略增，12,047,636 → 12,431,988，因为合并时补了命名空间等脚手架）。
- 大文件让增量重编变粗：改一行要重编更大的单元，并行度也下降；维护的库限制文件长度，方向正好相反。
- 与并行的 PR 冲突极多，只能作为一次性的脚本化变换在空档期落地。

## 9. 什么时候用

- 在删除类工作之后、改写之前；脚本可在新基线上重跑，所以放在删除之后损失最小。
- 先看诊断指标：只有一个声明的文件占比、每个文件的声明数明显偏离人写仓库时才合并；否则不做，或只拆超长文件。

## 10. 未解决的问题

- 合并的"最佳粒度"在哪里？有人认为存在一个甜点 [z642693829]，没人系统测过；它大概还和构建机器的核数有关。
- 合并对峰值内存和增量构建的长期影响。

[#44]: https://github.com/leanprover-community/riemann-hypothesis/pull/44
[#58]: https://github.com/leanprover-community/riemann-hypothesis/pull/58
[#61]: https://github.com/leanprover-community/riemann-hypothesis/pull/61
[#120]: https://github.com/leanprover-community/riemann-hypothesis/pull/120
[#250]: https://github.com/leanprover-community/riemann-hypothesis/pull/250
[#324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[P48]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[P51]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[z642693829]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642693829
[z642695795]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642695795
