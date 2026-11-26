# small-ramsey：3 千行的单文件证明，全流程

**Summary (English).** Complete run of the staged process on `MulticolorTriangleRamsey.lean` from `openai/ten-proofs` (model-generated, Apache-2.0, 2,902 code lines, 96 theorems, 42 definitions): a superexponential lower bound for multicolour triangle Ramsey numbers, four headline theorems fixed by the upstream challenge file. Result after six gated stages: **589 code lines, 9 theorems, 3 definitions** (4.9× in code lines, 10.7× in theorems, 14× in definitions), same headline statements, standard axioms only, clean offline build. Mechanical cleanup contributed nothing (the file has no dead code); unrolling by script took the theorem count from 96 to 41 at unchanged line count; blind automation replacement saved 3% of the lines; and 91% of the line reduction came from one stage in which a rewriting agent replaced the sub-arguments themselves (a greedy Hamming code instead of a packing of subsets, one covering function instead of a family of matrix definitions, an induction over plain functions instead of a certificate structure). That stage took 22 minutes of an agent's time with the gate as its acceptance test. The text is in Chinese.

状态：**完成**（2026-11-26）。六个阶段全部过闸门；最终文件在 [`result/`](result/)。

## 结论

1. **4.9 倍的行数缩减里，91% 来自“换论证”这一个阶段。** 机械清理 0%，展开 0%（它不省行），盲目的自动化替换 1.9%，就地化简 4.0%，压短 2.8%。
2. **命题个数的缩减分两半：** 展开（脚本）贡献 36%，换论证贡献 60%。展开后的结构随后被整体换掉，所以它的作用是“让改写者面对一条长证明”，不是最终结构的一部分。
3. **定义是被忽略的一块。** 42 个定义降到 3 个（只剩标题陈述用到的三个）。原文件的构造是一层层具名数据（标号、嵌入、证书结构体）；新证明直接在函数上做归纳，这些定义全部消失。参照案例里“命名的 `Prop` 定义从 6.5 万降到 4”是同一现象。
4. **闸门是让这件事可行的条件。** 改写代理在 47 分钟里做了 39 次构建；每一步是否保持了被证明的命题，由陈述指纹与公理检查判定，不靠阅读。
5. **这不是“同一个证明写短了”。** 标题陈述逐字相同，下界的常数也相同，但中间的构造换了。与参照案例作者的说法一致：很多简化是给子结果找到更简单的证明。

## 对象

- 仓库与提交：[openai/ten-proofs](https://github.com/openai/ten-proofs) `94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`，Apache-2.0。
- 文件：`MulticolorTriangleRamsey.lean`（3,053 行，只导入 Mathlib）。
- 标题定理（上游 `ComparatorChallenges/I_MulticolorTriangleRamsey.lean` 固定）：`erdos_183`、`erdos_problem_183_explicit`、`triangleRamseyNumber_log_sharp_coefficients`、`triangleRamseyNumber_log_isTheta`，以及陈述用到的三个定义 `TriangleFree`、`ForcesMonochromaticTriangle`、`triangleRamseyNumber`。

## 环境

笔记本（12 核、16 GB），Lean v4.33.1、Mathlib `0df444a3`，构建不联网；上游钉 v4.32.0，本文件在两个版本上都不改一字通过。一次完整构建 9–35 秒。闸门、脚本与机器见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。

## 各阶段

| 阶段 | 做法 | 代码行 | 定理 | 定义 | 只用一次的定理 | 最长证明（行） | gzip 字节 | 构建（秒） | 闸门 |
|---|---|---|---|---|---|---|---|---|---|
| 0 基线 | 上游文件原样 | 2,902 | 96 | 42 | 67（70%） | 86 | 21,861 | 17 | 过 |
| 1 机械 | 报告驱动 | 2,902 | 96 | 42 | 67 | 86 | 21,861 | — | 过（无改动） |
| 2 展开 | `unroll.py --retry` | 2,902 | 41 | 42 | 14 | 1,071 | 23,438 | 11 | 过 |
| 3a 自动化替换 | `Golf.lean` + `golf_blocks.py`，再展开一次 | 2,815 | 43 | 42 | 16 | 733 | 22,561 | 10 | 过 |
| 3b 化简 | 改写代理 | 2,639 | 37 | 42 | 19 | 950 | 21,838 | 31 | 过 |
| 4 再分块 | 改写代理（换论证） | 616 | 9 | 3 | 4 | 180 | 9,369 | 10 | 过 |
| 5 压短 | 改写代理 | 589 | 9 | 3 | 4 | 176 | 9,262 | 9 | 过 |

逐阶段的完整指标（含策略计数）在 [`metrics.jsonl`](metrics.jsonl)。

### 阶段 1：机械清理

| 检查 | 结果 |
|---|---|
| 标题定理闭包之外的声明（环境里的依赖图） | 0 |
| 类型完全相同的定理 | 0 |
| 别名与薄包装 | 0 |
| 没用到的参数（`#lint only unusedArguments`） | 0 |
| 编译器与 linter 警告 | 0 |

没有可做的。

### 阶段 2：展开

`unroll.py --retry`：57 个候选（只被一条定理使用、不出现在使用者陈述里），内联 55 个。没成的两个：一个靠点记号使用（`certificate.noMonochromaticTriangle`，改成局部 `have` 就要改调用处）；一个的证明在外层上下文里类型推断不同。没有尝试的单次使用定理：使用者是定义的 10 个。一个声明要把心跳上限提到 40 万。5 轮构建加 5 次重试，约 3 分钟。报告：[`unroll-s2.json`](unroll-s2.json)。

写脚本时的第一个系统性失败：证明内的 `have … {V : Type*}` 会给外层定理凭空加宇宙参数（54 个候选里 25 个因此被撤回），改写成 `Type _` 后全部通过。

### 阶段 3a：自动化替换

给每个多行 `:= by` 证明块加探针：依次试 `rfl`、`omega`、`simp`、`norm_num`、`positivity`、`linarith`、`simp_all`、`grind`、`aesop`、`nlinarith`、`tauto`，以及带上原证明块里出现的定理名的 `simp […]`、`simp_all […]`、`grind […]`，每次有心跳上限，都不行就跑原证明块。

| | 数量 |
|---|---|
| 被探测的证明块 | 219 |
| 能被一行替换的 | 24（`grind` 10、`simp_all` 7、`aesop` 3、`simp` 3、`omega` 1） |
| 省掉的行 | 87（3.0%） |
| 一次探测的用时 | 30 分钟以上（约 3,000 次尝试；笔记本上提前停止，结果按已得的 24 处算） |

替换是在阶段 1 的文件上做的（引理各自独立，可以并行检查），然后再展开一次；所以这一行的定理数是 43 而不是 41（替换后的证明在外层上下文里多两处内联不成立）。在已展开的文件上直接探测更慢：一个大声明里的嵌套块只能顺序试。报告：[`automation-s3a.json`](automation-s3a.json)、[`unroll-s3a.json`](unroll-s3a.json)。

判断：这类逐步推导的证明，整块能被一行自动化替换的很少。紧凑的写法需要知道该给哪些事实，逐块乱试得不到。

### 阶段 3b、4、5：改写代理

提示词：[`../../scripts/refold/prompts/rewrite-small-ramsey.md`](../../scripts/refold/prompts/rewrite-small-ramsey.md)（原样，只把本地路径换成占位符）。代理是一个 Claude Opus 5.5 子代理，在自己的工作副本里做；每个子阶段结束时自己跑闸门、记指标、提交。我们随后把三个阶段的结果文件逐个拿回主工作副本，用主副本自己的陈述文件与闸门代码重新过了一遍闸门，上表是重跑的数字。代理的日志原样在 [`agent-log.md`](agent-log.md)。

| | 3b 化简 | 4 再分块 | 5 压短 | 合计 |
|---|---|---|---|---|
| 用时 | 18 分钟（含通读全文 5 分钟） | 22 分钟 | 4 分钟 | 47 分钟 |
| 构建次数 | 5 + 1 | 24 + 2 | 6 + 1 | 35 + 4 |
| 代理消耗 | | | | 约 43.6 万 token，95 次工具调用 |

**3b（就地化简，不新增顶层引理）。** 代理读完全文后决定这一阶段只动末尾：四条标题定理原来各自把构造重跑一遍，改成互相推出（`erdos_183` 是显式下界的第二个分量；`…_log_isTheta` 是 `…_sharp_coefficients` 取 ε = 1/6，118 行变 9 行）；另把 5 条单次使用的定理内联。构造本身留给下一阶段整体替换。

**4（再分块，实际是换论证）。** 新文件在旧文件旁边一条引理一条引理地写，每条单独构建，最后切换并一次删掉旧声明。

| 原来 | 换成 | 行数 |
|---|---|---|
| t 元子集的 palette packing：贪心极大分离族、shell、transversal、二项式单调性、两个 Stirling 型估计 | `[q]^t` 上的贪心 Hamming 码（Gilbert–Varshamov），用 Mathlib 的 `hammingDist` | → `exists_code` 42 行 |
| 饱和矩阵、`forwardGuess` / `backwardGuess`、`IsCoordinateCovering`（11 个定义） | 一个覆盖函数 Φ，只带构造用到的两条性质 | 约 360 → `exists_covering` 89 行 |
| 递归 palette 染色：`TopEdgeLabeling`、重标号等价、5 个字段的证书结构体、可染性（23 个定义、17 条定理、1 个结构体） | 对普通对称函数的一次归纳，颜色是（位置，层）对 | 约 1,000 → `exists_stage` 180 行 |
| 上界 `R(k) ≤ 4·k!`：标号的拉回与删色 | 函数层面的鸽巢归纳，`R(k) ≤ 2(k+1)^k` | → `forces_pow` 48 行 |
| 参数选取：用 `Nat.find` 夹出 `count(H) ≤ k < count(H+1)`，相邻比值、立方根控制、`count 3 = 342` | 直接取 `H = ⌊e³⁷β⌋`、`a = ⌊k/(Hs)⌋` | 约 870 → 166 行 |
| Stirling 下界 + 15 行 | Mathlib 的 `Real.pow_div_factorial_le_exp` | 5 行 |

留下的 5 条非标题定理：`exists_covering` 与 `exists_code` 是自成一体的一般事实；`forces_pow` 被用两次；`lt_triangleRamseyNumber` 是把任意无单色三角的染色接到 Ramsey 数上的桥，在同一条定理里用两次；`exists_stage` 只用一次，但并进标题定理会超出默认心跳预算，代理选择保留它而不提高上限。

**5（压短）。** 去掉 `Finset.` / `SimpleGraph.` / `Real.` 前缀（标题陈述原文不动）、用 `<;>` 合并分支、缩短项证明。616 → 589 行。

失败与放弃（详见代理日志）：把 `exists_stage` 内联进标题定理（超心跳）；大上下文里的 `nlinarith` 两次超时，换成显式的 `linear_combination`；`rw [Real.log_div]` 匹配进了 `set` 变量的定义体，用 `clear_value` 解决。

## 各阶段的贡献

阶段 i 的比值 rᵢ 取对数后占总比值对数的份额；负数表示这一步让该指标变差。

| 阶段 | 代码行的比值 | 份额 | 定理个数的比值 | 份额 |
|---|---|---|---|---|
| 1 机械 | 1.000 | 0% | 1.000 | 0% |
| 2 展开 | 1.000 | 0% | 2.341 | 35.9% |
| 3a 自动化替换 | 1.031 | 1.9% | 0.953 | −2.0% |
| 3b 化简 | 1.067 | 4.0% | 1.162 | 6.3% |
| 4 再分块（换论证） | 4.284 | 91.2% | 4.111 | 59.7% |
| 5 压短 | 1.046 | 2.8% | 1.000 | 0% |
| **合计** | **4.927** | 100% | **10.67** | 100% |

其它总量：定义 42 → 3（14 倍）；全部声明 139 → 12（11.6 倍）；gzip 后 21,861 → 9,262 字节（2.36 倍）；`.olean` 4.15 → 3.86 MB（只小 7%：证明项没有随源码一起变小）；构建 17 → 9 秒。

## 写法的变化

| 每千行代码 | 基线 | 展开后 | 最终 |
|---|---|---|---|
| `have` | 104 | 123 | 219 |
| `simp` | 17 | 17 | 80 |
| `omega` | 28 | 28 | 59 |
| `grind` | 0 | 0 | 0 |

最终版每千行的 `have`、`simp`、`omega` 都更密：行数少了五倍，每行做的事更多。它没有走参照案例紧凑版“把事实交给 `grind`”的写法。

## 与参照案例对比

| | 参照案例（原始 → 紧凑版） | 本实验 |
|---|---|---|
| 规模 | 1,330 万代码行 → 6.9 万 | 2,902 → 589 |
| 定理 | 818,755 → 7,088（115 倍） | 96 → 9（10.7 倍） |
| 每个定理的平均行数 | 16.7 → 11.1 | 25.4 → 64.7（留下的是几条大定理） |
| 机械部分 | 约两到三倍 | 1.00 倍 |
| 其余来自 | 同一骨架上的重写，部分子论证换新 | 展开（命题个数）与换论证（行数与命题个数） |
| 代价 | 全局高心跳上限；导出反而更大 | 没有提高心跳上限；`.olean` 只小 7% |

## 第二方的独立检查

发布之后，另一个会话（不用本实验的闸门代码）做了一次独立检查：从 GitHub 直接取上游提交 `94bc0feb` 的 Challenge 文件；把发布的 [`result/MulticolorTriangleRamsey.lean`](result/MulticolorTriangleRamsey.lean) 放进一个新的 Lake 工程（Lean v4.33.1、Mathlib `0df444a3`，不联网）；写一个检查文件，把 Challenge 的三个定义放在另一个命名空间里，逐条重述 Challenge 的四条定理，并各用结果文件里对应的定理去证。构建通过（8,709 个任务，39 秒），即内核在 Challenge 的陈述上接受了结果文件的四条定理；四条定理的 `#print axioms` 都是 `propext`、`Classical.choice`、`Quot.sound`。

这是对闸门 G2（陈述指纹）的一个不依赖我们工具的交叉验证：它把“陈述相同”直接交给了内核。

## 这个结果不说明什么

- 只是一个 3 千行的对象；换论证能不能在几万行、几十万行的对象上以同样的比例发生，要看后面的实验。
- 闸门与第二方检查都用同一个 Lean 内核；没有用第二个独立的检查器（如 `lake comparator` 或另一个内核实现）重放。
- 新证明的数学没有经人审阅；它被 Lean 的内核接受。

## 文件

| 文件 | 内容 |
|---|---|
| [`result/MulticolorTriangleRamsey.lean`](result/MulticolorTriangleRamsey.lean) | 最终文件（阶段 5）。派生自上游同名文件，Apache-2.0，见 [`result/NOTICE.md`](result/NOTICE.md) |
| [`metrics.jsonl`](metrics.jsonl) | 每个阶段一行指标 |
| [`unroll-s2.json`](unroll-s2.json)、[`unroll-s3a.json`](unroll-s3a.json) | 展开脚本的报告（每次撤回的原因） |
| [`automation-s3a.json`](automation-s3a.json) | 自动化替换的报告（每处替换的行号与策略） |
| [`agent-log.md`](agent-log.md) | 改写代理的日志 |

## 复现

```bash
export REFOLD_REPO=<工作副本> REFOLD_OUT=<输出目录>      # 工作副本的布局见 docs/experiment-infra.md
python3 -I scripts/refold/gate.py ramsey s0-baseline && python3 -I scripts/refold/metrics.py ramsey s0-baseline
python3 -I scripts/refold/unroll.py $REFOLD_REPO/MulticolorTriangleRamsey.lean \
    $REFOLD_OUT/depgraph/ramsey-s0-baseline.jsonl --headlines <四条标题定理的全名，逗号分隔> --retry \
    --build "cd $REFOLD_REPO && <隔离前缀> lake build MulticolorTriangleRamsey"
python3 -I scripts/refold/golf_blocks.py instrument <文件> <探测文件>     # 再用带 Golf 库的环境编译探测文件
python3 -I scripts/refold/golf_blocks.py apply <文件> <探测文件>.blocks.json <编译日志> --build "…"
# 阶段 3b–5：把 prompts/rewrite-small-ramsey.md 交给改写代理，每个子阶段后跑 gate.py
```
