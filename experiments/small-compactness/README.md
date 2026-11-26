# small-compactness：1.7 万行的单文件证明，全流程

**Summary (English).** Complete run of the staged process on `CompactnessAndDegeneracy.lean` from `openai/ten-proofs` (model-generated, Apache-2.0, 17,236 code lines, 656 theorems, 273 definitions): counterexamples to the compactness conjecture and to the degeneracy conjecture in extremal graph theory, five headline theorems fixed by two upstream challenge files. Result after six gated stages: **15,844 code lines (1.09×), 214 theorems (3.07×), 261 definitions**. The theorem count fell almost entirely in the scripted unroll stage (654 → 242). The rewriting agent, with the same brief that took a 3,000-line file to one fifth, removed 8% of the lines here in 2 h 49 min: it replaced three sub-arguments by shorter standard ones and let automation close 84 local proofs, but the bulk of the file (coordinate computations in symplectic geometry, a supersaturation count, an entropy bound) is long genuine argument for which it found no replacement. The text is in Chinese.

状态：**完成**（2026-11-26）。六个阶段全部过闸门；最终文件在 [`result/`](result/)。

## 结论

1. **同一套做法，3 千行的对象缩到五分之一，1.7 万行的对象只缩了 8%。** 代码行 17,236 → 15,844（1.09 倍）；定理 656 → 214（3.07 倍），其中 89% 来自脚本展开，改写代理只贡献了 11%。
2. **换论证只在“有现成的更短论证”的地方发生。** 代理换掉了三处：用 Markov 不等式代替一段 249 行的二阶矩计算；用对边数的归纳代替“最大化带平局规则的势函数”；用对全部二染色取平均代替逐点翻转的最大割论证。每处从一两百行降到十几到三十几行。占全文一半以上的三大块（辛几何里的坐标计算约 2,700 行、超饱和计数约 1,500 行、熵估计约 1,200 行）是实打实的长论证，代理没有找到可以替换它们的标准构造或库结论，原样留下。
3. **展开让构建变慢，化简又把它拉回来一部分。** 构建 36 秒（阶段 1）→ 140 秒（展开后）→ 96 秒（最终）。
4. **所以“小对象上的五倍”不能外推。** 对象变大以后，一次代理运行读不完也重证不了全部内容；要再往下压，得把大块子开发各自交给专门的一次运行，并明确要求重新推导，而这已经是在做新的数学。这里没有做。

## 对象

- 仓库与提交：[openai/ten-proofs](https://github.com/openai/ten-proofs) `94bc0feb6a9ff12c7d31d6de640a725c9d43d2b6`，Apache-2.0。
- 文件：`CompactnessAndDegeneracy.lean`（18,588 行，只导入 Mathlib）。两个开发：`CompactnessConjecture`（约 8,500 行）与 `TwoDegenerateGraphs`（约 8,700 行，用到前者的一些声明）。
- 标题定理（由上游的 `ComparatorChallenges/J_CompactnessConjecture.lean` 与 `J_TwoDegenerateGraphs.lean` 固定）：`CompactnessConjecture.not_erdos_180`、`quantitativeCompactnessCounterexample`、`compactnessCounterexample_bigO`，`TwoDegenerateGraphs.twoDegenerateExtremalCounterexample`、`not_erdos_146`，以及两个 Challenge 文件里的全部定义。

## 环境

笔记本（12 核、16 GB），Lean v4.33.1 与 Mathlib `0df444a3`（上游钉 v4.32.0，本文件在两个版本上都不改一字通过），构建不联网。闸门与脚本见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。

## 各阶段

| 阶段 | 做法 | 代码行 | 定理 | 定义 | 只用一次的定理 | 最长证明（行） | gzip 字节 | 构建（秒）/ CPU（秒） | 闸门 |
|---|---|---|---|---|---|---|---|---|---|
| 0 基线 | 上游文件原样 | 17,236 | 656 | 273 | 455（69%） | 172 | 110,159 | 28 / 118 | 过 |
| 1 机械 | 报告驱动 | 17,219 | 654 | 272 | 453 | 172 | 110,078 | 36 / 135 | 过 |
| 2 展开 | `unroll.py --retry` | 17,245 | 242 | 272 | 116 | 4,071 | 124,893 | 140 / 224 | 过 |
| 3 化简 | 改写代理 | 16,724 | 236 | 266 | 116 | 3,991 | 121,897 | 124 / 207 | 过 |
| 4 再分块 | 改写代理（换了三处论证） | 16,225 | 214 | 261 | 99 | 3,747 | 119,230 | 96 / 200 | 过 |
| 5 压短 | 改写代理（主要是排版） | 15,844 | 214 | 261 | 99 | 3,691 | 118,905 | 96 / 198 | 过 |

逐阶段的完整指标在 [`metrics.jsonl`](metrics.jsonl)。阶段 3–5 的数字是把代理各阶段的结果文件拿回主工作副本、用主副本的陈述文件与闸门代码重跑得到的。

### 阶段 1：机械清理

| 检查 | 工具 | 结果 |
|---|---|---|
| 闭包外的声明 | 依赖图 + 可达性 | 0 |
| 类型完全相同的定理 | `GateAnalysis.dupReport` | 1 组 |
| 别名 | `GateAnalysis.aliasReport` | 4 个，其中 3 个是纯别名，删掉并改引用 |
| 没用到的参数 | Batteries 的 `#lint only unusedArguments` | 3 个实例参数，去掉 |
| linter 提示 | 构建日志 | 18 处 `letI` / `haveI` 改成 `let` / `have` |

1.001 倍。一个更正：第一版依赖图把自动生成的 `recOn` 当成了用户声明，报出 4 个“不可达”；改了归属规则后是 0。

### 阶段 2：展开

`unroll.py --retry`，输入是阶段 1 的依赖图。

| | 数量 |
|---|---|
| 候选（只被一条定理使用、不出现在使用者的陈述里） | 419 |
| 内联成功 | 412 |
| 构建失败后撤回 | 10，逐个重试后恢复 3，最终 7（`simp` 在新上下文里不再前进或超步数 4；源码里提到但证明项没有用到、依赖图里看不到的引用 3） |
| 没有尝试的单次使用定理 | 使用者是定义 27；使用者在别的作用域且是项证明 4；带属性 3 |
| 被两处以上使用，不动 | 196 |
| 需要提高心跳上限的声明 | 3（80 万、40 万、320 万） |
| 最深的嵌套 | 15 层 |
| 轮数与耗时 | 6 轮构建加 10 次单独重试，约 25 分钟 |

定理 654 → 242，代码行基本不变，gzip 后 +13%（缩进变深），构建 36 → 140 秒：声明之间原本并行检查，内联以后一个大声明只能顺序检查。脚本额外处理的情况：22 处 `variable` 按签名里出现的名字复制成绑定；46 处 `omit … in` 排除的实例不复制；使用者在别的 `namespace` / `open` 范围时用 `(open … in have …)` 包住（26 处）。报告：[`unroll-s2.json`](unroll-s2.json)。

### 阶段 3–5：改写代理

提示词：[`../../scripts/refold/prompts/rewrite-compactness.md`](../../scripts/refold/prompts/rewrite-compactness.md)（与小对象的提示词相同的结构，加了“先画出全文的分块、按子开发逐块推进并逐块存档”）。代理是一个 Claude Opus 5.5 子代理；日志原样在 [`agent-log.md`](agent-log.md)。

| | 3 化简 | 4 再分块 | 5 压短 | 合计 |
|---|---|---|---|---|
| 用时 | 41 分钟（含通读与分块 9 分钟） | 约 2 小时 | 6 分钟 | 2 小时 49 分钟 |
| 构建 | 4 次，另 3 次带探针的整文件检查 | 6 次，另约 25 次由展开脚本发起（三次放弃的尝试） | 2 次 | 加闸门共约 45 次 |
| 代理消耗 | | | | 约 40.4 万 token，252 次工具调用 |

**3（化简）。**
- 自动化扫描：对约 1,000 个多行局部证明各试一组策略（带上限，失败则回到原证明），84 处被替换（`grind` 60、`positivity` 9、`nlinarith` 8、`simp_all` 5、`simp [*]` 2），省约 280 行。代理自己写了一个只在探测副本里存在的限时展开器：它验证了 `set_option maxHeartbeats N in 策略` 并不能给一个策略限时。
- 去掉一条绕路：`FamilyLittleO`、证书结构体 `SeparationCertificate` 与三条过渡定理（约 150 行）删掉，非紧性直接从 16 次幂上界与一致下界推出（22 行）；`not_erdos_180` 变成一行。
- 内联 9 个包装引理与定义；C4 与 C6 两种情形并到与其它成员相同的引理上。

**4（再分块）。** 按子开发从大到小推进，每换掉一块过一次闸门并存档。

| 子开发 | 规模（行） | 结果 |
|---|---|---|
| 第二部分主论证（熵排除、抽样） | 约 4,000 | 换了一处：保留顶点数的上尾，249 行的二阶矩计算 → Markov 不等式 13 行（失败概率的界从趋于 0 变成趋于 2/3，仍小于 1，而被用到的只有这一点） |
| 第一部分上界（16 次幂上界） | 约 2,000 | 换了两处：最小度修剪（约 140 行加 2 个定义 → 对边数归纳 30 行）；最大割（126 行加 5 个声明 → 对全部二染色取平均 33 行）。超饱和计数留下 |
| 第一部分的特征 2 与奇特征回避（辛几何里直线的坐标） | 约 2,700 | 留下 |
| 第二部分的经验熵界 | 约 1,200 | 留下（Mathlib 有二元熵，没有 Pinsker 不等式） |
| W(q) 的计数、填充、夹逼 | 约 900 | 留下 |

另把因上述改动而变成单次使用的 20 条引理内联。

**5（压短）。** 主要是排版：能放进 100 列的陈述头并成一行（省 267 行），单行策略体接到 `:= by` 后面（97 处），`:= by exact t` 改成 `:= t`（17 处）。没有做逐条的策略级压缩。

失败与放弃：不限时的 `grind` 在某些分情形里挂住；`aesop` 失败时只报警告，破坏了成败的判定，从扫描里去掉；把 80 条新出现的单次使用引理全部内联让四个最大的声明超时，展开脚本把其中一个的心跳上限一路加倍到约 4·10¹¹（脚本的缺陷，已加上限），代理撤回了这几次尝试，约一小时的构建时间花在这里；边数的下尾（Chebyshev，约 490 行）不能换成 Markov。

## 各阶段的贡献

| 阶段 | 代码行的比值 | 份额 | 定理个数的比值 | 份额 |
|---|---|---|---|---|
| 1 机械 | 1.001 | 1.2% | 1.003 | 0.3% |
| 2 展开 | 0.998 | −1.8% | 2.702 | 88.8% |
| 3 化简 | 1.031 | 36.4% | 1.025 | 2.2% |
| 4 再分块 | 1.031 | 36.0% | 1.103 | 8.7% |
| 5 压短 | 1.024 | 28.2% | 1.000 | 0% |
| **合计** | **1.088** | 100% | **3.065** | 100% |

定义 273 → 261（1.05 倍）；gzip 后 110,159 → 118,905 字节（**变大 8%**：展开加深了缩进，后面的阶段没有把它全部拉回来）；`.olean` 37.3 → 37.8 MB。

## 与 3 千行对象的对比

| | [small-ramsey](../small-ramsey/README.md) | 本实验 |
|---|---|---|
| 基线 | 2,902 代码行，96 条定理 | 17,236 代码行，656 条定理 |
| 最终 | 589 行，9 条定理 | 15,844 行，214 条定理 |
| 代码行的比值 | 4.93 | 1.09 |
| 换论证的阶段省掉的行 | 2,023（基线的 70%） | 499（基线的 2.9%） |
| 代理用时与消耗 | 47 分钟，43.6 万 token | 2 小时 49 分钟，40.4 万 token |
| 被换掉的部分 | 整个构造 | 三处局部论证 |

两次用的是同一类提示词、同一个模型、同一道闸门。差别在对象：3 千行的证明可以整篇读懂后另起炉灶；1.7 万行里有两条研究级的论证链，代理只在认出“这里有更短的标准论证”的地方动手。消耗的 token 相近，说明第二次运行并没有读到、更没有重做大部分内容。

## 这个结果不说明什么

- 不说明 1.7 万行的对象压不动：这是一次代理运行、一份提示词、不许提高心跳上限、每次构建一两分钟的结果。把三大块各自交给专门的运行可能还能往下压，没有试。
- 闸门与小对象相同：能构建、标题陈述及其定义与 Challenge 模块结构相同、只用三条标准公理；没有用第二个检查器重放。

## 文件

| 文件 | 内容 |
|---|---|
| [`result/CompactnessAndDegeneracy.lean`](result/CompactnessAndDegeneracy.lean) | 最终文件（阶段 5）。派生自上游同名文件，Apache-2.0，见 [`result/NOTICE.md`](result/NOTICE.md) |
| [`metrics.jsonl`](metrics.jsonl) | 每个阶段一行指标 |
| [`unroll-s2.json`](unroll-s2.json) | 展开脚本的报告 |
| [`agent-log.md`](agent-log.md) | 改写代理的日志（含它对证明结构的概述与每块子开发的处理） |

## 复现

```bash
export REFOLD_REPO=<工作副本> REFOLD_OUT=<输出目录>
python3 -I scripts/refold/gate.py compactness s0-baseline && python3 -I scripts/refold/metrics.py compactness s0-baseline
python3 -I scripts/refold/unroll.py $REFOLD_REPO/CompactnessAndDegeneracy.lean \
    $REFOLD_OUT/depgraph/compactness-s1-mechanical.jsonl --headlines <五条标题定理的全名，逗号分隔> \
    --retry --build "cd $REFOLD_REPO && <隔离前缀> lake build CompactnessAndDegeneracy"
python3 -I scripts/refold/gate.py compactness s2-unroll
# 阶段 3–5：把 prompts/rewrite-compactness.md 交给改写代理，每个子阶段后跑 gate.py
```

`refold-subjects.json`（放在工作副本里）：`{"compactness": {"solution": "CompactnessAndDegeneracy", "challenges": ["J_CompactnessConjecture", "J_TwoDegenerateGraphs"]}}`。
