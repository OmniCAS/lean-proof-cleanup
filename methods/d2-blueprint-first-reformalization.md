# D2 先写非形式化证明，再重新形式化（blueprint-first reformalization）

## 1. 一句话判断

被许多数学家看作唯一真正让人读懂的路线：先得到一份人能审阅的证明，再从它重新形式化，旧代码只作参考；它最慢，但产物既可读又可复用，而且数学有人审过。

## 2. 做什么

1. 从代码（或原作者的说明）整理出一份完整的非形式化证明，按章节与引理组织。
2. 由专家审阅这份证明，把已知部分标到现有文献与库。
3. 以它为蓝图重新形式化：新数学放在项目里，已知数学进通用库（[C4](c4-upstreaming-known-math.md)）。

## 3. 谁在用

- 立场：Kevin Buzzard 问为什么不先非形式化 [z642851744]；Michael Stoll 设想"代码 → 非形式化证明 → 重新形式化，且最后一步不看原代码" [z643185395]；Mario Carneiro 想要的是约 200 页的人类可读证明，并猜测还能缩掉 98%–99.5% [z642816120]。
- Tau Ceti 的路线图就是这种做法在背景理论上的落地 [z642819551]。
- 其他项目：Lean 社区大型形式化常用的蓝图（blueprint）工作流，先写带依赖图的非形式化文档，再逐条形式化。

## 4. 证据等级

有先例（蓝图工作流、Tau Ceti）；对 RH 开发目前只有立场和计划，没有完成的产物。

## 5. 作用层级

大仓库与生态。需要理解数学，也需要专家审阅。

## 6. 正确性靠什么保证

- 形式化部分：同一套闸门（最终陈述不变，多内核检查）。
- 数学部分：人工审阅蓝图；这是其他路线都不提供的保证。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 对 RH 开发尚无完成的非形式化证明或重新形式化 | — |
| 预测的上限：缩掉 98%–99.5% [z642816120] | 他人报告（猜测） |
| grh-lean 可读版 47.7 万行（约原始的 1/36），作者说明它没有配套论文、没有数学家通读 [D16] | 本仓库测（行数）+ 他人报告 |

## 8. 代价与坑

- 时间以月计，需要专家投入。
- 非形式化证明若由模型从代码生成，同样需要逐条核对（社区已发现模型生成的文献引用有错） [z643418033]。
- 重新形式化时容易无意改变陈述；陈述文件必须冻结。

## 9. 什么时候用

当目标是"让人理解"而不只是"让机器接受"时；可以在 [D3](d3-thin-then-thick.md) 的可读版基础上做，而不必从原始版本做。

## 10. 未解决的问题

- 从 grh-lean 可读版写出非形式化证明，是否比从原始版本写容易一个数量级？看起来如此，但没人试过。

[D16]: ../REFERENCES.md
[z642816120]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642816120
[z642819551]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642819551
[z642851744]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642851744
[z643185395]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/643185395
[z643418033]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643418033
