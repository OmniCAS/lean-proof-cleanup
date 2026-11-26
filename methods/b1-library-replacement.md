# B1 换成库里已有的引理（library replacement）

## 1. 一句话判断

每次只换一条证明，却常常顺带截断一整片依赖，是局部改写里收益最高的一种；收益看来源：维护者精心维护的库本身就是被换成的那一方；人写研究仓库里有一部分自证的引理通用库早有，每次升级库版本都可能冒出新的可换项；模型生成的大型开发最常重新证明通用库里已有的事实。反方向同样重要：项目里通用的引理补进库（[C4](c4-upstreaming-known-math.md)）。

## 2. 做什么

- 对每条自有引理，在隐藏它自身的环境里试 `exact?`、`apply?` 或 hammer，或用类型索引查通用库与项目内的同型声明；一步能关闭的就换掉证明，或删掉引理、把引用改指库里的名字。
- 只在已导入相应模块的文件里替换，避免新增导入；否则确认新增导入不让闭包变大。
- 换完之后重跑 [A1](a1-reachability-pruning.md)：原证明用到的辅助引理可能整片变得不可达。

## 3. 谁在用

- Lean 工具：`exact?`、`apply?`、`rw?`、`hint` 等搜索式 tactic 给出可写回的建议（[survey](../docs/survey.md) §3.2）；LeanHammer 的 `hammer` 做前提选择并重建证明，可把长证明换成一次调用 [P15] [T13]。
- 反方向：MathlibLemma 挖掘 Mathlib 缺的常识引理，1,506 条已验证，少量合入 Mathlib [P36]。
- 其他系统：Isabelle 的 Sledgehammer 找到证明后做事实集最小化 [P3]；HOL 系库之间的概念对齐用来找另一个库里的同一概念 [P31]。
- 大仓库示例（Lean RH 开发，模型生成）：社区 `alpoge` 线的 [#221]（Serdnad 等：用 Mathlib 引理或项目内已有证明替换冗余证明，合并时净 −221,158 行）、[#92]（一次替换让 112 个模块不可达）、[#389]（46 个与 Mathlib 相同的声明）；[#295] 在已导入 Mathlib 对应引理的文件里改用 Mathlib 的名字；Tanner Clary 在导出上数出约 6.6 万个定理已在 Mathlib/Core [z642652193]。过程见 [RH 社区清理](../cases/rh/rh-community-cleanup.md)。

## 4. 证据等级

- 有论文或工具：搜索式 tactic、hammer、MathlibLemma。
- 主流在用：RH 案例里的替换 PR（#221、#92 已合并）。
- 推测："隐藏自身后批量试 `exact?`"是我们的建议，未见公开实现。

## 5. 作用层级

单个定理到大仓库。需要一点判断（换成的引理是否在可见范围内、是否带来新导入），不需要理解整个证明。

## 6. 正确性靠什么保证

- 陈述不动，只换证明体；重编通过即可。
- 删掉自有引理、改指库里的名字时，两者类型必须内核判定相等（同 [A2](a2-statement-dedup.md)）。
- 换成的引理不能引入更多公理：对最终定理跑 `#print axioms`，或用 `lake check` 全库检查 [T1]。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 库 × Mathlib | MathlibLemma 找到 1,506 条 Mathlib 缺的常识引理并验证，少量已合入（反方向：补库） [P36] | 他人报告 |
| 库 × Mathlib | 重复短名占不同短名 13.3%，与 RH 原始版本（13.0%）几乎相同：同名不代表同陈述，按名字替换不可行（[profiles](../cases/profiles.md)） | 本仓库测 |
| 其他规模与来源（竞赛证明、人写研究仓库） | 换成库引理的单独数字没有公开 | — |
| 大仓库 × 模型生成（RH） | #221 合并：净 −221,158 行（含 import 行）（`data/rh_mainline_merges.csv`） | 本仓库测 |
| 大仓库 × 模型生成（RH） | #92：可达模块 164,282 → 164,170，非空行 −6,779，其中 6,751 行来自变得不可达的模块 [#92] | 他人报告 |
| 大仓库 × 模型生成（RH） | 导出上约 6.6 万个定理已在 Mathlib/Core 中有同型的 [z642652193] | 他人报告 |

RH 的行只对「大仓库 × 模型生成的大型开发」这一格有效。

## 8. 代价与坑

- `exact?` 对每条引理都要一次搜索，仓库越大计算量越大；先用类型哈希筛。
- 不隐藏自身时，搜索会直接找到这条引理自己。
- 换成通用库的引理后，项目对库版本更敏感：库改名或 deprecate 时要跟着改。
- 名字相同但陈述不同的情形在任何来源里都常见（见 §7 的短名统计），不能按名字替换。

## 9. 什么时候用

- 在 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 之后；每换一批就回到 A1 重算闭包。
- 人写研究仓库：每次升级通用库版本时顺手跑一遍，新版本可能已经收进了你的引理。
- 模型生成的大型开发：对每条自有引理都跑，收益最大。

## 10. 未解决的问题

- 批量"隐藏自身后试 `exact?` 或 hammer"在仓库规模上的成本和命中率；没有公开实验。
- 人写研究仓库里有多少自有引理通用库已有？没有公开数字。
- （RH 案例）约 6.6 万个已在 Mathlib 中的定理，替换后整体能截断多少依赖？没人做过全量实验。

[#92]: https://github.com/leanprover-community/riemann-hypothesis/pull/92
[#221]: https://github.com/leanprover-community/riemann-hypothesis/pull/221
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[#389]: https://github.com/leanprover-community/riemann-hypothesis/pull/389
[P3]: ../REFERENCES.md
[P15]: ../REFERENCES.md
[P31]: ../REFERENCES.md
[P36]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T13]: ../REFERENCES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
