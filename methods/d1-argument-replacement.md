# D1 换掉子论证（argument replacement）

## 1. 一句话判断

缩小最多、也最依赖数学判断的一步：整块理论被更简单的论证取代后，连同它的全部依赖一起消失；它不是清理，是新的数学，验收只能靠闸门，不能靠与原证明对照。

## 2. 做什么

- 对某个子结果，找一条更短的证明路线，或者换一个更合适的库入口（例如换一种函数方程的形式，就省掉大段分类讨论）。
- 换掉之后，原来只为旧论证服务的整片理论变得不可达，交给 [A1](a1-reachability-pruning.md) 删掉。
- 保持最终陈述与主骨架不变；骨架也换掉就是另立的证明（[D2](d2-blueprint-first-reformalization.md)）。

## 3. 谁在用

- grh-lean 的作者说，很多简化来自给子结果找到更简单的证明，所以不少论证是新的 [z643717520]；首帖提到去掉了对 Vandiver 猜想弱形式的依赖、用更简单的整性论证、筛法一步只用 Poisson 求和 [z643702366]。README 说"很多步骤用别的论证证明" [D16]。
- 作者列出被替换或砍掉的部分：奇点消解整个去掉；Gram 行列式的乘积公式代替 slope 不等式；Hecke L 值代替 Shimura 簇上的 covolume；Vandiver、patching、Hida 理论、GSp4、局部 Langlands 被砍 [z643717520]。
- 社区里的另一类做法：[#38]（只证 RH、绕开 GRH 的另一条路线）被维护者认为是改架构而非清理；更短的中间引理（来自非形式化重述）交给专家判断 [z643474280]。

## 4. 证据等级

- **作者自述**：上面列出的替换。
- **本仓库测**：入口选择的样例（见下）；被砍理论对应目录的行数（下限）。
- **推测**：各项替换对总缩小的贡献比例，外部量不出。

## 5. 作用层级

大仓库。需要理解数学，而且需要研究层面的判断。

## 6. 正确性靠什么保证

- 只能靠闸门：陈述文件原样保留，comparator 与多个独立内核检查（[E2](e2-verification-gate.md)）。
- 原始版本的核验结果不能转给新证明；grh-lean 是靠自己发布当天的核验 [D18]。

## 7. 效果

| 数字 | 标记 |
|---|---|
| 同一个推导（由半平面无零点推出 ζ 的零点在临界线上）：原始 62 行，紧凑版 4 行；改用对称的完备 ζ 函数方程，原始那约 25 行关于 cos 零点的分类讨论整个消失 | 本仓库测（[grh-compact-vs-original](../docs/grh-compact-vs-original.md) 样例一） |
| 原始版本里名字明确对应被砍理论的目录：`ResolutionOfSingularities` 约 15 万行，patching 约 5 万行，Hida 约 3 万行，局部 Langlands 约 3 万行（下限，目录名与内容对应得不好） | 本仓库测 |

## 8. 代价与坑

- 需要真正懂这部分数学；换掉的论证必须自己成立。
- 与"清理原证明"的目标冲突：社区维护者把换路线视为另一个项目。
- 换掉的部分越多，新证明越难与原证明对照；可读性要另外补（[D3](d3-thin-then-thick.md)）。

## 9. 什么时候用

在 C 层展开之后（展开后才能看清哪些子论证可以绕开）；换完回到 A 层删掉失去依赖的理论。

## 10. 未解决的问题

- 哪些替换是"更好的库入口"（可机械发现），哪些是真正的新数学？需要逐项对照，目前没人做。

[#38]: https://github.com/leanprover-community/riemann-hypothesis/pull/38
[D16]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[z643474280]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643474280
[z643702366]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643702366
[z643717520]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643717520
