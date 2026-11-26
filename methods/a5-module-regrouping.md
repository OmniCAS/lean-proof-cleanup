# A5 模块重组（module regrouping）

## 1. 一句话判断

对文件数和构建开销立竿见影，但它是合并而不是删除：文件数大降，内容几乎不变；指标上最容易被误读。

## 2. 做什么

- 删薄包装：只含一个"用另一个名字转述已有定理"的模块，把引用改指原定理，再删掉它。
- 沿 import 图把小模块合并成大文件（"clump"），减少每个文件的启动与加载开销。
- 全部由脚本生成；换基线时重跑脚本，而不是 rebase 生成的提交。

## 3. 谁在用

- 社区 `alpoge` 线：[#324]（Kim Morrison：删 22,054 个薄包装模块，再按 import 图合并）、[#58] / [#61]（折叠转发包装）、[#44]（草稿）。
- [#120]（Rohan Arun，合并小文件；没有合并，但启发了 #324）。
- 原因见 issue [#250]：每个文件的导入开销约占编译 CPU 的一半。

## 4. 证据等级

主流在用（#324 已合并）。#120 的速度数字只有声称，且构建不过。

## 5. 作用层级

大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 合并文件不改声明，只改它们所在的文件；能编译、陈述文件未改即可。
- 风险是名字冲突：合并后约 0.7% 的模块因名字捕获失败，#324 用排除清单和静态检查处理 [#324]。

## 7. 效果

| 数字 | 标记 |
|---|---|
| #324：`.lean` 文件 147,945 → 61,935（−58%）；import 行 6,428,170 → 2,950,339 | 本仓库测 |
| 同上，PR 说明：`src/` 148,230 → 62,159 个文件 [#324] | 他人报告 |
| 原始版本：文件名含 `Statement` 的文件 48,367 个（28%）；只有一个声明的文件占 45% | 本仓库测（`data/versions_summary.json`；前者见 [grh-compact-vs-original](../docs/grh-compact-vs-original.md)） |
| #120 自报 47,884 个文件（−67.9%），编译时间 −24%~45%；构建不过，未合并 [z642695795] | 仅声称 |

## 8. 代价与坑

- 文件数不再代表内容多少；#324 之后正文行反而略增（12,047,636 → 12,431,988），因为合并时补了命名空间等脚手架。
- 大文件让增量重编变粗：改一行要重编更大的单元。
- 与并行的 PR 冲突极多，只能作为一次性的脚本化变换在空档期落地。

## 9. 什么时候用

在删除类工作之后、改写之前；脚本可在新基线上重跑，所以放在删除之后损失最小。

## 10. 未解决的问题

- 合并的"最佳粒度"在哪里？Rohan Arun 认为存在一个甜点 [z642693829]，没人系统测过。
- 合并对峰值内存和增量构建的长期影响。

[#44]: https://github.com/leanprover-community/riemann-hypothesis/pull/44
[#58]: https://github.com/leanprover-community/riemann-hypothesis/pull/58
[#61]: https://github.com/leanprover-community/riemann-hypothesis/pull/61
[#120]: https://github.com/leanprover-community/riemann-hypothesis/pull/120
[#250]: https://github.com/leanprover-community/riemann-hypothesis/pull/250
[#324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[z642693829]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642693829
[z642695795]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642695795
