# B4 证明项层面的压缩（term-level compression）

## 1. 一句话判断

在导出的证明项上做去重、hash-consing、DAG 内联，理论上干净、可机器复核；但目前除了一次可达性加去重的导出实验，其余都只有声称，而且源码长度和证明项大小常常走向相反。

## 2. 做什么

- 在 `leanexport` 导出的内核项上工作：按结构哈希合并相同子项、合并类型相同的 `Prop` 定理、把只用一次的定理内联进 DAG。
- 结果是一份更小的导出，可以直接交给独立内核和 `--compare` 检查；是否能还原成可读源码是另一个问题。

## 3. 谁在用

- Tanner Clary：在 Sutherland 的导出上做可达性加 `Prop` 去重，导出缩小约 20%，`con-ron --compare` 约 3 分钟仍通过 [z642652193]。
- Devin Watson：自称把原始版本分解成原子函数，做结构去重、hash-consing 和 DAG 定理内联，压到 528,681 行；没有公开代码 [z643715299]。
- 文献：证明项的可重建压缩 [P1]、归结证明压缩 [P2]、发明新定义 [P16]、切规则引入 [P17]。

## 4. 证据等级

Clary 的实验：他人报告，有可复核的方法描述。Watson：仅声称。文献：有论文，但不针对 Lean。

## 5. 作用层级

大仓库（整份导出）。不需要理解数学。

## 6. 正确性靠什么保证

- 产物是导出，独立内核（nanoda、con-leche、con-ron、lean4lean）可以直接检查，`--compare` 对照 challenge 确认陈述。
- 源码层面的正确性不在这个路线的范围内。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 导出：原始 61.6 GB，可读版 4.49 GB，紧凑版 5.17 GB [D17] [D18] | 他人报告 |
| 紧凑版源码是可读版的 1/4，导出却大 15% | 本仓库测（源码）+ 他人报告（导出） |
| Clary：可达性加去重后导出约 −20% [z642652193] | 他人报告 |
| Watson：528,681 行 [z643715299] | 仅声称 |

## 8. 代价与坑

- 源码短不等于证明项小：自动化 tactic 生成的项往往比手写推导大。
- 导出本身很大（原始 61.6 GB），处理需要大内存；lean4lean 在可读版上用了 332 GB [D18]。
- 压缩后的项难以映射回源码，不能直接变成可合并的 PR。

## 9. 什么时候用

作为核验与度量工具（衡量"内核要检查多少"），而不是源码清理的主路线；可与 [E5](e5-dependency-analysis.md) 的依赖分析共用导出。

## 10. 未解决的问题

- 证明项大小与构建时间、内核检查时间的关系。
- 项层面的压缩能否反推出源码层面的重构建议。

[D17]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[P1]: ../REFERENCES.md
[P2]: ../REFERENCES.md
[P16]: ../REFERENCES.md
[P17]: ../REFERENCES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
[z643715299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643715299
