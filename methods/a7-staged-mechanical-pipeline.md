# A7 分阶段的机械流水线（staged mechanical pipeline）

## 1. 一句话判断

把 A1–A4 串成可重放、每步有回执的流水线，是机械路线里最可信的做法；它不提高上限，但让每一步都可以被别人独立复核。

## 2. 做什么

- 固定基线提交和工具链；每个阶段只做一类变换（删未用声明、删 linter 标记的语法、去重、删多余 import）。
- 每个阶段是一个提交，附回执：变换脚本与参数、输入输出的树指纹、完整构建结果、独立内核结果、陈述比对结果。
- 任何人用同样的脚本从基线重放，指纹必须一致。

## 3. 谁在用

- James Shore 的 `rh-proof-trimmed`：S1 删未用声明、S2 删 linter 标记的语法、S3 去重（只在 4.37 上）、S4 删多余 import；S1–S3 已并入社区线（[#55]、[#67]、[#243]、[#295]） [D9]。
- 同类的定期整库流程：Mizar 的修订 [P48]、Metamath 的 `minimize_with` [T15]；LeanPolish 的"迭代到不动点" [P12]。

## 4. 证据等级

有工具（公开仓库与回执）；结果为作者自报，没有第三方复核报告。

## 5. 作用层级

小仓库到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 每个阶段：Lean 4.33.1 完整构建；nanoda 接受导出；con-leche `--compare` 对照公开的 challenge；逐条比较导出里的陈述与原始归档 [D9]。
- 变换不写任何证明（"no proof is written by hand or by a model"），只删或改指向。

## 7. 效果

| 阶段 | 文件 | 行 | 声明 | 标记 |
|---|---|---|---|---|
| 基线（社区 `7da4577e`） | 164,463 | 16,588,671 | 1,024,669 | 他人报告 |
| S1 | 150,632 | 14,473,033 | 858,404 | 他人报告 |
| S2 | 150,632 | 14,453,805 | 858,404 | 他人报告 |
| S4（分支 `s4-on-s1`） | 150,632 | 14,252,250 | 858,404 | 他人报告 |

从基线算：行 −14.1%、声明 −16.2%（估计，按上表）。

## 8. 代价与坑

- 每个阶段都要完整构建和导出，在原始规模上每次以小时计。
- 社区主线同时在变，阶段需要在新基线上重做（S2、S3 都移植过）。
- 上限受 A1–A4 本身限制。

## 9. 什么时候用

大仓库清理的第一阶段，或任何需要向第三方证明"只做了机械变换"的场合。之后的改写类路线（B、C、D）各自另立回执。

## 10. 未解决的问题

- 回执格式没有标准；可以考虑把树指纹与导出哈希写进 CI，由第三方机器复算。

[#55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[#67]: https://github.com/leanprover-community/riemann-hypothesis/pull/67
[#243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[D9]: ../REFERENCES.md
[P12]: ../REFERENCES.md
[P48]: ../REFERENCES.md
[T15]: ../REFERENCES.md
