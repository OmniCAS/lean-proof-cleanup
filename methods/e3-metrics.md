# E3 度量（metrics）

## 1. 一句话判断

度量的单位随规模变：单个定理上看 token 数、证明项大小和编译时间；到仓库规模，单位是命题个数（声明数、依赖闭包），不是行数或文件数。每个常用指标都能被刷，所以至少同时看"内容"和"成本"两类。同一指标在不同来源上含义也不同：同一个缩短工具在模型生成的证明上能省两成，在维护者精心维护的库上几乎为零；跨来源比较之前，先看结构画像。

## 2. 做什么

| 指标 | 衡量什么 | 怎么被刷 |
|---|---|---|
| 总行数 | 粗略体积 | 展开或收拢 `import` 就能大幅变动；长行、删注释 |
| 文件数 | 组织 | 合并文件（[A5](a5-module-regrouping.md)）不减少任何内容 |
| 正文行（去空行、导入、`module`） | 内容 | 长行；把内容移到别的库 |
| 定理 + 引理个数 | 命题个数 | 把多条引理塞进一个大证明里（可读性变差） |
| 每个定理的平均行数 | 证明写法 | 拆成大量小引理 |
| token 数 | 写法紧凑程度 | 重度自动化、短名字 |
| 证明项大小 / 导出大小 / 内核检查时间 | 内核要检查多少 | 不容易刷；但对自动化很敏感 |
| 冷构建 CPU、峰值内存 | 成本 | 只在固定硬件、固定缓存策略下可比 |
| 依赖闭包大小 | 删死代码的下限 | 只对机械路线有意义；对库而言叶子是接口 |
| 结构画像（只有一个声明的文件比例、每文件声明数、命名 `Prop` 密度、注释与导入占比） | 冗余在哪、像哪种来源 | 只用于诊断，不作目标 |

## 3. 谁在用

- 论文：token 数（ImProver、ProofOptimizer、LeanPolish） [P8] [P9] [P12]、证明项大小（Leanify） [P29]、压缩分（LeanLean） [P30]、长度加依赖数与模块度（ImProver 2） [P10]、长度加编译时间（Lean Refactor 报告两者只弱相关） [P11]。
- Mathlib：`longFile`（1,500 行）与要求 `maxHeartbeats` 带注释的风格 linter [T3]、`#count_heartbeats` [T5]、技术债计数 [P50]；网络结构分析指出 44.8% 的定理是叶子 [P38]（见 [curated-library-mathlib](../cases/curated-library-mathlib.md)）。
- 本仓库：`scripts/profile_lean_trees.py`（代码行、声明、策略用法；七棵公开树的结构画像见 [profiles](../cases/profiles.md)）与 `scripts/rh_repo_stats.py`（正文行、import 行、theorem/lemma 行）。
- 大仓库示例（Lean RH 开发，模型生成）：社区的行数跟踪页（rh-shrink） [z642702787]、技术债统计 [#1508]、heartbeat 设置清点 [z643467299]；David Loeffler 用 gzip 作比喻反对以 token 数为目标 [z643362042]。

## 4. 证据等级

- **有论文或工具**：各指标的定义与统计工具。
- "每种指标怎么被刷"：§7 里有本仓库测的实例；没有实例的几项是**推测**。

## 5. 作用层级

全部层级。

## 6. 正确性靠什么保证

度量本身不涉及正确性；但每个数字都要写明口径、版本与统计脚本。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | 同一 LeanPolish 管线：Goedel-Prover 证明 token −20.0%，miniF2F −22.6% [P12] | 他人报告 |
| 库 × Mathlib | 同一管线 −0.53% [P12]；ImProver 2 长度改进约 0.016 [P10] | 他人报告 |
| 单个定理 × 竞赛题与研究仓库（Lean Refactor） | 编译时间最多 −60%，与长度只弱相关 [P11] | 他人报告 |
| 单个定理 × 模型生成的竞赛证明（ProofOptimizer） | 约 2/3 的证明编译快 ≥10% [P9] | 他人报告 |
| 库 × Mathlib | 44.8% 的定理不被其他声明引用：是接口，不是死代码 [P38] | 他人报告 |
| 库 × Mathlib | 每个定理平均 7.5 行（[profiles](../cases/profiles.md)） | 本仓库测 |
| 仓库 × 人写研究仓库（FLT、Carleson、PrimeNumberTheoremAnd [D19]–[D21]） | 每个定理平均 15.6–17.5 行，与模型生成的 RH 原始版本（16.7 行）相近：单看每个定理的长度分不出来源 | 本仓库测 |
| 库 × Mathlib | 重复短名比例 13.3%，与 RH 原始版本的 13.0% 相近：这个指标不区分来源 | 本仓库测 |
| 大仓库 × 模型生成（RH） | #185 展开 `import Mathlib`（从 #66 到 #324 之前，含 #221）：总行数 15.18M → 20.57M，正文行 12.31M → 12.05M | 本仓库测 |
| 大仓库 × 模型生成（RH） | #324 合并文件：文件 147,945 → 61,935，正文行反而 +38 万 | 本仓库测 |
| 大仓库 × 模型生成（RH） | 最长行：原始 5,016 字符、超过 100 字符的行 1,935,318 行；紧凑版 767 字符、60 行 | 本仓库测（[grh-compact-reliability](../cases/rh/grh-compact-reliability.md) §5） |
| 大仓库 × 模型生成（RH） | 命题个数：818,755 → 18,227 / 7,088，而每个定理的平均行数只是 16.7 → 21.0 / 11.1 | 本仓库测（`data/tree_profiles.json`） |
| 大仓库 × 模型生成（RH） | 源码与证明项方向相反：紧凑版源码是可读版的 1/4，导出 5.17 GB 对 4.49 GB [D18] | 本仓库测 + 他人报告 |
| 大仓库 × 模型生成（RH） | 按内核要检查的量，短版本比原始小 12–14 倍（导出 61.6 GB 对 4.49–5.17 GB），不是按行数的 36–150 倍 | 估计（按导出大小） |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 不同工具对"行"的定义不同（`wc -l`、按换行切分、去注释与否），跨报告比较前先统一口径。
- 文件数和总行数最容易出现在标题里，也最容易误导。
- 以 token 数为目标会鼓励重度自动化与短名字，构建时间与可读性都可能变差（例：Lean RH 开发的讨论里有人用 gzip 作比喻反对这样做 [z643362042]）。
- 同一指标跨来源不可比：重复短名、未被引用的声明比例在库里另有含义（§7）。
- 仓库级基准的分数口径不一：LeanLean 的压缩分怎么算没有读到全文 [P30]，不能与 token 数直接换算。

## 9. 什么时候用

清理前记基线，每批记录相对于基线的变化，发布时同时给内容和成本两类指标。单个定理的工作报 token 数与编译时间；仓库级的工作报声明数、闭包大小与冷构建 CPU。动手前先算结构画像，判断冗余在证明内部还是在结构上。

## 10. 未解决的问题

- 可读性没有好的自动指标；目前只能抽样人审。
- 结构画像能否预测各路线的收益？目前只有一份模型生成的大型开发，"模型生成的中小仓库"这一格没有测。
- 不同基准（token 数、证明项大小、压缩分）之间能否换算？

[#1508]: https://github.com/leanprover-community/riemann-hypothesis/pull/1508
[D18]: ../REFERENCES.md
[D19]: ../REFERENCES.md
[D21]: ../REFERENCES.md
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P29]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[P50]: ../REFERENCES.md
[T3]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[z642702787]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642702787
[z643362042]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643362042
[z643467299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643467299
