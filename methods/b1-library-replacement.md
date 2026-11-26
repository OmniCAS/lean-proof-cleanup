# B1 换成库里已有的引理（library replacement）

## 1. 一句话判断

每次只换一条证明，却常常顺带截断一整片依赖；在 AI 生成的仓库里，"Mathlib 早就有"的定理数以万计，这是局部改写里收益最高的一种。

## 2. 做什么

- 对每条自有引理，在隐藏它自身的环境里试 `exact?` / `apply?`，或用类型索引查 Mathlib 与项目内的同型声明；一步能关闭的就换掉证明。
- 只在已导入相应模块的文件里替换，避免新增导入；否则确认新增导入不让闭包变大。
- 换完之后重跑 [A1](a1-reachability-pruning.md)：原证明用到的辅助引理可能整片变得不可达。

## 3. 谁在用

- 社区 `alpoge` 线：[#221]（Serdnad 等：用 Mathlib 引理或项目内已有证明替换冗余证明，合并时净 −221,158 行）、[#92]（一次替换让 112 个模块不可达）、[#389]（46 个与 Mathlib 相同的声明）。
- #295 在已导入 Mathlib 对应引理的文件里改用 Mathlib 的名字 [#295]。
- 文献：MathlibLemma 反过来挖掘 Mathlib 缺的常识引理 [P36]；hammer 类工具（LeanHammer）可把长证明换成一次调用 [P15]。

## 4. 证据等级

主流在用（#221、#92 已合并）。"隐藏自身后试 `exact?`"的批量做法是我们的建议，未见公开实现（推测）。

## 5. 作用层级

定理到大仓库。需要一点判断（换成的引理是否在可见范围内），不需要理解整个证明。

## 6. 正确性靠什么保证

- 陈述不动，只换证明体；重编通过即可。
- 换成的引理不能比原来引入更多公理：对最终定理跑 `#print axioms`，或用 `lake check` 全库检查 [T1]。

## 7. 效果

| 数字 | 标记 |
|---|---|
| #221 合并：净 −221,158 行（含 import 行） | 本仓库测（`data/rh_mainline_merges.csv`） |
| #92：可达模块 164,282 → 164,170，非空行 −6,779，其中 6,751 行来自变得不可达的模块 [#92] | 他人报告 |
| 导出上约 6.6 万个定理已在 Mathlib/Core 中有同型的 [z642652193] | 他人报告 |

## 8. 代价与坑

- `exact?` 对每条引理都要一次搜索，大仓库上计算量大；先用类型哈希筛。
- 换成 Mathlib 的引理后，项目对 Mathlib 版本更敏感。
- 名字相同但陈述不同的引理很多（原始版本里同一个短名被定义多次的有 98,631 个），不能按名字替换。

## 9. 什么时候用

在 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 之后；每换一批就回到 A1 重算闭包。

## 10. 未解决的问题

- 6.6 万个已在 Mathlib 中的定理，替换后整体能截断多少依赖？没人做过全量实验。

[#92]: https://github.com/leanprover-community/riemann-hypothesis/pull/92
[#221]: https://github.com/leanprover-community/riemann-hypothesis/pull/221
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[#389]: https://github.com/leanprover-community/riemann-hypothesis/pull/389
[P15]: ../REFERENCES.md
[P36]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
