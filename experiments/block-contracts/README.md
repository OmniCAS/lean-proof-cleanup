# block-contracts：先固定接口，再逐块专门改写

**Summary (English).** Follow-up to [`small-compactness`](../small-compactness/README.md), where one rewriting run over a 17,000-line file removed 8% of the lines and left the large blocks untouched. Question: does dedicated effort per block move the number? Each large block gets a contract (the one theorem through which the rest of the file uses it, found as a dominator in the declaration graph) and its own rewriting run whose brief fixes only the contract: everything inside may be proved in any way, by a different mathematical argument and with anything in Mathlib. A block gate accepts a result when the file's gate passes, the contract's statement fingerprint is unchanged and every changed line lies inside the block. Recorded per block: lines and theorems before and after, time, tokens, builds, what argument replaced what, what was tried and given up, and whether the block resists because the mathematics is long or because the budget ran out. First result: the entropy block went from 1,446 lines and 31 declarations to 223 lines and 2 theorems in 52 minutes, by a more direct argument (no transfer step between sampling models, no smoothing); the other two runs are in progress. The text is in Chinese.

状态：**进行中**（2026-11-27）。块与契约已固定；entropy 一块已完成并过闸门，upper 与 lower 在跑。

## 问题

[small-compactness](../small-compactness/README.md) 的结论是：一次改写运行读不完也重证不了 1.7 万行，占全文一半以上的几大块原样留下。那是“没有专门去做”，还是“做不动”？这里把每个大块单独交给一次运行，只固定它的接口，看数字动不动。

## 做法

1. **找块。** 在最终文件（阶段 5 的结果）的声明图上算支配树（[`dominators.py`](../../scripts/refold/dominators.py)）：声明 D 支配 E，指从标题定理到 E 的每条依赖路径都经过 D。被 D 支配的声明只为 D 而存在，文件的其余部分只通过 D 的陈述用到它们。D 的陈述就是这一块的**契约**。
2. **每块一次改写运行，同时最多两个。** 提示词模板：[`rewrite-block.md`](../../scripts/refold/prompts/rewrite-block.md)。固定的只有契约定理的名字与陈述、块外的全部内容；块内可以删、可以换、可以加，可以换一个完全不同的数学论证，可以用 Mathlib 里的任何东西。目标是能过闸门的最短证明，然后再整理。预算每块约 3 小时，进展停滞可以提前停。
3. **块闸门**（[`block_gate.py`](../../scripts/refold/block_gate.py)），三条都要成立：文件的普通闸门通过（标题定理的陈述指纹、公理、不联网的完整构建）；契约定理的陈述指纹与改写前相同（它的类型，加上类型里提到的全部项目内常量及其定义体）；每一处改动都落在块的行范围内。第三条保证各块的结果可以合并。
4. 每块记录：前后的行数与定理数、用时、token、构建次数、什么论证换成了什么、试过又放弃的做法，以及结论：压不动是因为数学本身长，还是因为预算用完。

## 块与契约

对象：`CompactnessAndDegeneracy.lean` 在 small-compactness 阶段 5 之后的状态（16,716 行、15,844 代码行、214 条定理、261 个定义）。支配 1,500 行以上的声明有三个互不包含的，加上一个被其中之一包含的：

| 块 | 契约定理 | 契约说什么 | 块内声明（定理 / 定义与实例） | 行 | 文件其余部分怎么用它 |
|---|---|---|---|---|---|
| upper | `CompactnessConjecture.proposedFamilyFree_sixteenth_power_host_bound` | 不含禁用族成员的 n 点图，边数的 16 次方 ≤ C·n²¹ | 93（42 / 51） | 2,961 | 2 处 |
| lower | `CompactnessConjecture.proposedFamily_uniformMemberLower` | 禁用族的每个成员的极值数 ≥ c·n^(4/3) | 120（67 / 53） | 3,914 | 3 处 |
| entropy | `TwoDegenerateGraphs.pairCoordinateConditionalEntropy_empirical_bound` | 一个坐标的条件熵，被经验不一致率与二元熵的组合控制 | 31（14 / 17） | 1,446 | 2 处 |

三块合计 8,321 行，占文件的一半。small-compactness 里说的四大块与这三个契约的对应：超饱和计数在 upper 里；辛几何的坐标计算与 W(q) 的计数都在 lower 里（两者只通过 `proposedFamily_uniformMemberLower` 被外面用到，所以是一个契约）；熵估计是 entropy。文件的第二个开发的其余部分（约 6,700 行）被标题定理 `twoDegenerateExtremalCounterexample` 本身支配，没有更小的单定理接口，这一轮没有动。

## 结果

### 投入—压缩表

| 块 | 行（前 → 后） | 声明（前 → 后） | 比值 | 用时 | token | 构建 / 草稿检查 | 换成了什么 | 压不动的部分 |
|---|---|---|---|---|---|---|---|---|
| entropy | 1,446 → 223 | 31 → 2 | 6.5 | 52 分钟 | 29.3 万 | 7 / 约 30 | 见下 | 数学本身（四块各有不能省的理由） |
| upper | 进行中 | | | | | | | |
| lower | 进行中 | | | | | | | |

行数含空行与注释；用时与 token 是改写代理一次运行的全部消耗（Claude Opus 5.5 子代理）。每个结果都拿回主工作副本重跑了块闸门。

### entropy：1,446 → 223 行

原来的证明分三步：先对独立同分布的权重证不等式；再把它转移到无放回抽样的权重上，付出 1/n 量级的误差项；边界情形（频率为 0 或 1）靠磨光核再取极限。代理换掉了其中四处，日志原样在 [`entropy-log.md`](entropy-log.md)：

| 原来的做法 | 换成 | 省掉 |
|---|---|---|
| 先证独立权重的版本，再转移到无放回权重，带误差项 | 无放回的权重 = 独立的权重 + 一个非负的“混合型”修正 δ = q(1−q)/(n−1)，而这个修正在势函数里的系数 ≤ 0；所以不等式对经验权重直接成立、误差为 0，契约里的误差项只在最后用一次“≥ 0” | 约 450 行（独立版本、1/n 误差引理、熵的连续模与单调性） |
| 边界情形靠磨光核与极限 | 带边界条件的加权 Gibbs 不等式，边界条件由 Σ W_t z_t = v 自动成立 | 约 110 行 |
| 势函数的界：在 √2、√3 处取对数的切线，Cauchy–Schwarz，平方根估计 | 对数的平方形式切线（在 8/9 与 2 处，系数全是有理数），剩下一个二次型，用一条三项平方和恒等式证（`ring` 检查；先用计算机代数验过） | 约 170 行 |
| 手写的二元 Pinsker 不等式（对间隙函数求二阶导） | x ↦ h(x) + 2x² 在 [0,1] 上凹，对 q 与 1−q 取中点 | 115 → 约 20 行 |

试过又放弃的：对整个势函数用权重 w^(3/4) 的 Jensen（在 q = 1/2 处不成立，1.244 > 1.2408）；用比 Pinsker 弱的熵界（Hellinger 型、Topsøe 型，强度不够，需要 KL(q‖½) ≥ 约 0.43·(2q−1)²）；Mathlib 里没有 Pinsker 或 `Real.binEntropy` 的 KL 下界。

**判断：原来的 1,446 行长，是因为绕了路，不是因为数学长。** 剩下的 223 行是四块：每个配对类型上的 Gibbs 不等式（陈述在 q = ½、a = b 处是紧的）、对数项的二次界、一个 Pinsker 强度的熵界（Mathlib 没有，要一步微积分）、把配对类型的计数翻译成权重的约 65 行。代理的结论是这四块压不动是数学本身，不是预算：三小时的预算只用了 52 分钟。
