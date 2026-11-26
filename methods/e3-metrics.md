# E3 度量（metrics）

## 1. 一句话判断

压缩的单位是命题个数，不是行数；每个常用指标都能被刷，所以至少同时看"内容"（声明数、正文行、闭包大小）和"成本"（构建 CPU、内核检查量）两类。

## 2. 做什么

| 指标 | 衡量什么 | 怎么被刷 |
|---|---|---|
| 总行数 | 粗略体积 | 展开或收拢 `import` 就能变动几百万行；长行、删注释 |
| 文件数 | 组织 | 合并文件（[A5](a5-module-regrouping.md)）不减少任何内容 |
| 正文行（去空行、导入、`module`） | 内容 | 长行；把内容移到别的库 |
| 定理 + 引理个数 | 命题个数 | 把多条引理塞进一个大证明里（可读性变差） |
| 每个定理的平均行数 | 证明写法 | 拆成大量小引理 |
| token 数 | 写法紧凑程度 | 重度自动化、短名字；Loeffler 用 gzip 作比喻反对以它为目标 [z643362042] |
| 导出大小 / 内核检查时间 | 内核要检查多少 | 不容易刷；但对自动化很敏感 |
| 冷构建 CPU、峰值内存 | 成本 | 只在固定硬件、固定缓存策略下可比 |
| 依赖闭包大小 | 删死代码的下限 | 只对机械路线有意义 |

## 3. 谁在用

- 社区：行数跟踪页（rh-shrink） [z642702787]、技术债统计 [#1508]、heartbeat 设置清点 [z643467299]。
- 论文：token 数（ImProver、ProofOptimizer、LeanPolish）、证明项大小（Leanify）、压缩分（LeanLean） [P8] [P9] [P12] [P29] [P30]。
- 本仓库：`scripts/rh_repo_stats.py`（正文行、import 行、theorem/lemma 行）与 `scripts/compare_versions.py`（代码行、声明、策略用法）。

## 4. 证据等级

有工具；"每种指标怎么被刷"来自本仓库测的实例。

## 5. 作用层级

全部层级。

## 6. 正确性靠什么保证

度量本身不涉及正确性；但每个数字都要写明口径与版本。

## 7. 效果（实例）

| 实例 | 标记 |
|---|---|
| #185 展开 `import Mathlib`（从 #66 到 #324 之前，含 #221）：总行数 15.18M → 20.57M，正文行 12.31M → 12.05M | 本仓库测 |
| #324 合并文件：文件 147,945 → 61,935，正文行反而 +38 万 | 本仓库测 |
| 最长行：原始 5,016 字符、超过 100 字符的行 1,935,318 行；紧凑版 767 字符、60 行 | 本仓库核对（[grh-compact-reliability](../docs/grh-compact-reliability.md) §5） |
| 命题个数：818,755 → 18,227 / 7,088，而每个定理的平均行数只是 16.7 → 21.0 / 11.1 | 本仓库测 |
| 源码与证明项方向相反：紧凑版源码是可读版的 1/4，导出 5.17 GB 对 4.49 GB [D18] | 本仓库测 + 他人报告 |
| 按内核要检查的量，短版本比原始小 12–14 倍（导出 61.6 GB 对 4.49–5.17 GB），不是按行数的 36–150 倍 | 估计（按导出大小） |

## 8. 代价与坑

- 不同工具对"行"的定义不同（`wc -l`、按换行切分、去注释与否），跨报告比较前先统一口径。
- 文件数和总行数最容易出现在标题里，也最容易误导。

## 9. 什么时候用

清理前记基线，每批记录相对于基线的变化，发布时同时给内容和成本两类指标。

## 10. 未解决的问题

- 可读性没有好的自动指标；目前只能抽样人审。

[#1508]: https://github.com/leanprover-community/riemann-hypothesis/pull/1508
[D18]: ../REFERENCES.md
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P29]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[z642702787]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642702787
[z643362042]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643362042
[z643467299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643467299
