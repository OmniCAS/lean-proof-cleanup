# E5 依赖分析（dependency analysis）

## 1. 一句话判断

先量再删：依赖闭包给出机械路线的下限，支配树给出"哪一块是承重的"，字段活性补上可达性看不到的死代码；文本匹配会把可删量高估好几倍，必须从内核项或 `.olean` 算。

## 2. 做什么

- 依赖闭包：从最终定理出发，沿内核证明项的常量引用求闭包，按声明、文件、行统计。
- 支配树：一个声明 D 属于 X，当且仅当从最终定理到 D 的每条依赖链都经过 X；用来找"删掉 X 就能删掉的整片"。
- 字段活性：结构的哪些字段从未被读取（可达性分析会因构造子引用而保留它们）。
- 导入图统计：模块数、边数、层数、最宽一层，用来判断并行度与重组方向。

## 3. 谁在用

- James Shore 的 `rh-proof-dependencies`（CC0 数据集）：从 Sutherland 的内核导出算出，三套独立构建得到同一闭包 [D8]。
- Bin 的 riemann-explorer：沿支配树切分 `riemannHypothesis` 的依赖图 [D12] [z643337613]。
- Michael Righi 的字段活性分析（`alpoge` 线与新 `main` 的 [#5642]） [z642699511]；Anton Mellit 在可读版上数未用声明 [z643723346]。
- 文献：Coq/Mizar 的依赖抽取 [P37]、Mathlib 的网络结构（44.8% 的定理是叶子，即对外的 API，不等于死代码） [P38]。

## 4. 证据等级

有工具与公开数据（Shore）；其他分析多为作者自报。

## 5. 作用层级

大仓库。不需要理解数学（但解读支配树需要）。

## 6. 正确性靠什么保证

分析本身不改代码；删除时的正确性见 [A1](a1-reachability-pruning.md)。数据集的可信度来自独立构建的一致性。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 原始版本：1,484,729 个内核常量被五个定理用到，其中项目 1,270,184、Mathlib 204,488（Mathlib 的 35.9%） [D8] | 他人报告 |
| 项目声明 804,912 / 1,061,400 被用；五个定理几乎共享一切，每一个单独就用了其中至少 804,889 个 [D8] | 他人报告 |
| riemann-explorer：提交 `6c68212` 上 `riemannHypothesis` 的依赖图有 727,065 个声明（是否含 Mathlib 未说明） [z643337613] | 他人报告 |
| 文本追踪的高估：issue #3 先估可删约 45%，构建失败后改为约 9% [C2] | 他人报告 |
| 导入图：原始 175,187 个模块、753,261 条内部边、203 层、最宽一层 5,927；紧凑版 794、1,398、55、32 | 本仓库测 |

## 8. 代价与坑

- 导出很大（原始 61.6 GB），算闭包要大内存。
- 闭包只覆盖证明项里的依赖；编译依赖（实例、simp 集合、notation）要另外确认。
- 支配树的结果依赖根的选取；换根就要重算。

## 9. 什么时候用

清理开始之前与每个大阶段之后；结果交给 [A1](a1-reachability-pruning.md)、[A2](a2-statement-dedup.md) 和 [C1](c1-unroll-simplify-reroll.md)（找可以整体换掉的子论证）。

## 10. 未解决的问题

- `alpoge` 线当前版本与新 `main` 的闭包都没人公开量过。

[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[C2]: ../REFERENCES.md
[D8]: ../REFERENCES.md
[D12]: ../REFERENCES.md
[P37]: ../REFERENCES.md
[P38]: ../REFERENCES.md
[z642699511]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699511
[z643337613]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Explorer.20for.20the.20formalization/near/643337613
[z643723346]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643723346
