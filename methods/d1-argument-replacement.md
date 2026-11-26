# D1 换掉子论证（argument replacement）

## 1. 一句话判断

缩小最多、也最依赖数学判断的一步：一个子结果换成更短的论证或更合适的库入口后，只为旧论证服务的整片理论连同依赖一起消失。单个定理上它就是"找一条更短的证明"，搜索、hammer 和模型改写都能做，在模型生成的证明上收益大，在维护者精心维护的库里很小；到大仓库上它是新的数学，验收只能靠闸门，不能靠与原证明对照。

## 2. 做什么

- 对某个子结果，找一条更短的证明路线，或者换一个更合适的库入口（例如换成一条更对称的库引理作起点，省掉整段分类讨论）。
- 换掉之后，原来只为旧论证服务的整片理论变得不可达，交给 [A1](a1-reachability-pruning.md) 删掉。
- 保持最终陈述与主骨架不变；骨架也换掉就是另立的证明（[D2](d2-blueprint-first-reformalization.md)）。
- 单个定理上：用 `exact?`、hammer 或模型在库里找更短的路线，只收更短且通过的。

## 3. 谁在用

- 单个定理：Metamath 的 `minimize_with` 用库里已有定理找更短的证明，每一两年对整个 set.mm 跑一遍 [T15]，GPT-f 找到的 23 个更短证明被 set.mm 采纳 [P5]；HOL4 的 TacticToe 在找到证明后做长度与引理列表最小化 [P4]；Lean 的 LeanHammer 可以把一段长证明换成一次 `hammer` 调用 [P15] [T13]；ProofOptimizer、ImProver、Lean Refactor 用模型重写整个证明 [P9] [P8] [P11]（见 [theorem-scale-generated-proofs](../cases/theorem-scale-generated-proofs.md)）。
- 仓库：LeanLean 的智能体在三层上压缩，其一就是简化数学论证 [P30]。
- 大仓库示例（Lean RH 开发，模型生成）：grh-lean 的作者说，很多简化来自给子结果找到更简单的证明，所以不少论证是新的 [z643717520]；首帖提到去掉了对 Vandiver 猜想弱形式的依赖、用更简单的整性论证、筛法一步只用 Poisson 求和 [z643702366]；README 说"很多步骤用别的论证证明" [D16]；作者列出的替换：奇点消解整个去掉，Gram 行列式的乘积公式代替 slope 不等式，Hecke L 值代替 Shimura 簇上的 covolume，Vandiver、patching、Hida 理论、GSp4、局部 Langlands 被砍 [z643717520]。社区里的另一类做法：[#38]（只针对 RH 陈述、绕开 GRH 的另一条证明路线）被维护者认为是改架构而非清理，更短的中间引理（来自非形式化重述）交给专家判断 [z643474280]。

## 4. 证据等级

- **有论文或工具**：单个定理上的最小化与重写（[P4] [P5] [P9] [P15] [T15]）；仓库层面只有 LeanLean 的摘要 [P30]。
- **作者自述**：RH 案例里上面列出的替换。
- **推测**：RH 案例里各项替换对总缩小的贡献比例，外部量不出；§7 的入口样例与目录行数是本仓库测，只能给下限。

## 5. 作用层级

单个定理到大仓库。单个定理上换路线可以靠搜索与模型，只需局部理解；大仓库上换掉整片理论，需要理解数学，而且需要研究层面的判断。

## 6. 正确性靠什么保证

- 单个定理：重新 elaborate 加内核检查，陈述不动；Metamath 另加"不引入新公理"的约束 [T15]。
- 大仓库只能靠闸门：陈述文件原样保留，comparator 与多个独立内核检查（[E2](e2-verification-gate.md)）。
- 原始版本的核验结果不能转给新证明（例：Lean RH 开发里 grh-lean 靠的是自己发布当天的核验 [D18]）。

## 7. 效果

| 规模 × 来源 | 数字 | 标记 |
|---|---|---|
| 单个定理 × 模型生成的竞赛证明 | ProofOptimizer：miniF2F −87%、PutnamBench −57%（总长度，不区分换路线与删步骤） [P9] | 他人报告 |
| 库 × Metamath set.mm | GPT-f 的 23 个更短证明被采纳 [P5] | 他人报告 |
| 库 × Mathlib | ImProver 2 长度改进约 0.016（整体改写，不单是换路线） [P10] | 他人报告 |
| 仓库 × LeanLean 的 64 个真实仓库 | 简化论证是三层之一；最佳模型平均压缩分 48.3%，大头来自依赖重组，换论证单独的份额未报告 [P30] | 他人报告 |
| 大仓库 × 模型生成（RH） | 同一个推导（由半平面无零点推出 ζ 的零点在临界线上）：原始 62 行，紧凑版 4 行；改用对称的完备 ζ 函数方程，原始那约 25 行关于 cos 零点的分类讨论整个消失 | 本仓库测（[grh-compact-vs-original](../cases/rh/grh-compact-vs-original.md) 样例一） |
| 大仓库 × 模型生成（RH） | 原始版本里名字明确对应被砍理论的目录：`ResolutionOfSingularities` 约 15 万行，patching 约 5 万行，Hida 约 3 万行，局部 Langlands 约 3 万行（下限，目录名与内容对应得不好） | 本仓库测 |
| 其他规模与来源（人写研究仓库） | 没有公开数字 | — |

RH 各行只是「大仓库 × 模型生成的大型开发」这一格的证据。

## 8. 代价与坑

- 需要真正懂这部分数学；换掉的论证必须自己成立。
- 与"清理原证明"的目标冲突，维护者常把换路线视为另一个项目（例：Lean RH 开发里 [#38] 被看作改架构而非清理 [z643474280]）。
- 换掉的部分越多，新证明越难与原证明对照；可读性要另外补（[D3](d3-thin-then-thick.md)）。
- 单个定理上，换成 hammer 或重度自动化的证明可能更短但更慢、对库版本更敏感，要加计时闸门（[A6](a6-option-and-performance-cleanup.md)、[B2](b2-tactic-golf-and-automation.md)）。

## 9. 什么时候用

大仓库上在 C 层展开之后（展开后才能看清哪些子论证可以绕开），换完回到 A 层删掉失去依赖的理论。单个定理上的换路线随时可做，但要过计时闸门。对模型生成的代码最值得做，生成过程常绕远路；对精心维护的库几乎没有收益。

## 10. 未解决的问题

- 哪些替换是"更好的库入口"（可以用 `exact?`、hammer 机械发现），哪些是真正的新数学？没有分类方法。
- Metamath 式的定期整库最小化 [T15] 能否在 Lean 仓库上做成流水线，并按依赖重新计算哪些理论因此失去用途？
- （RH 案例）各项替换需要逐项对照原始版本，目前没人做。

[#38]: https://github.com/leanprover-community/riemann-hypothesis/pull/38
[D16]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[P4]: ../REFERENCES.md
[P5]: ../REFERENCES.md
[P8]: ../REFERENCES.md
[P9]: ../REFERENCES.md
[P10]: ../REFERENCES.md
[P11]: ../REFERENCES.md
[P15]: ../REFERENCES.md
[P30]: ../REFERENCES.md
[T13]: ../REFERENCES.md
[T15]: ../REFERENCES.md
[z643474280]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643474280
[z643702366]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643702366
[z643717520]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643717520
