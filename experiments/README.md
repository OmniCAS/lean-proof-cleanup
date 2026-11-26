# 实验：在别的仓库上复现“展开—化简—再分块”

**Summary (English).** Our own measured experiments: the staged compression process described for the large-repository case (mechanical cleanup, then unroll single-use lemmas into long flat proofs, simplify across the old lemma boundaries, fold back into lemmas where reuse really happens, then shorten) is run on other public Lean repositories, from a 3,000-line single file to repositories of several hundred thousand lines. Every stage passes the same gate (statement files frozen, headline statements fingerprinted against the challenge module, no new axioms, full offline build) and is recorded with what was done, how, how long it took and the numbers before and after. The first complete run (a 3,000-line file) ends at 589 code lines and 9 theorems from 2,902 and 96; 91% of the line reduction comes from the one stage in which sub-arguments were replaced. The second (17,000 lines, same method) ends at 15,844 code lines from 17,236: the five-fold reduction does not carry over. This page is the index by scale and provenance, with the status of each experiment, the findings so far, and the survey of candidate subjects. Tools are in [`../scripts/refold/`](../scripts/refold/), the environment in [`../docs/experiment-infra.md`](../docs/experiment-infra.md). The text is in Chinese.

状态日期：2026-11-26。**进行中**的实验只报已经过闸门的阶段；没做的写“未做”。

## 目前的结论

1. **机械清理值多少，取决于生成方式，不取决于“是不是模型生成”。** 单文件、一次生成的证明（`openai/ten-proofs`）在机械层面是干净的：两个文件里闭包外的声明为 0，机械阶段 1.000 与 1.001 倍。多文件的大型生成开发才有成片的死代码：`openai/NavierStokesAndEuler` 的 38,084 条定理里 33.8% 从四条标题定理出发不可达（参照案例的原始开发是 24%）。
2. **引理边界是主要的冗余。** 在环境的依赖图里数“只被一处使用的定理”：两个 ten-proofs 文件 70% 与 69%，NavierStokesAndEuler 的可达部分 54%。
3. **展开可以完全由脚本做。** 把单次使用的定理改写成使用者证明里的 `have`，带构建反馈的脚本在两个文件上分别内联了 57 个候选中的 55 个、419 个中的 412 个：定理个数 96 → 41 与 654 → 242，代码行不变。代价是声明变大：最长的证明从 86 行变成 1,071 行、从 172 行变成 4,071 行，较大的那个文件构建从 36 秒变成 140 秒，3 个声明要提高心跳上限（最高 320 万）。
4. **盲目的自动化替换收益很小。** 给每个多行证明块试一组收尾策略（`grind`、`simp_all`、`omega` 等，以及带上原证明块里出现的定理名的版本），219 个块里只有 24 个能被一行替换，省 3% 的代码行，一次探测要几十分钟。紧凑的写法来自知道该给自动化哪些事实，不来自逐块乱试。
5. **行数的缩减来自换论证。** 第一个做完全流程的对象（3 千行）：2,902 → 589 代码行（4.9 倍），定理 96 → 9，定义 42 → 3；行数缩减的 91% 来自一个阶段，改写代理在那里把子论证本身换掉了（贪心 Hamming 码代替子集的 packing，一个覆盖函数代替一族矩阵定义，对普通函数的归纳代替证书结构体），用时 22 分钟，以闸门为验收。
6. **大对象选定 `openai/NavierStokesAndEuler`，机械阶段值 1.3 倍。** 它整库 18 分钟建完，另一个候选（Mordell 加上它导入的 Stacks 模块，21,637 个模块）要 3 小时 17 分钟、96 核·时。整库删不可达声明两遍以后：定理 38,084 → 28,746，代码行 498,912 → 386,279，闸门通过。依赖图有三种看不见的依赖（`rfl` 证明的 `@[simp]` 引理、强制转换实例、`autoImplicit` 下的缺失名字），每一种都让一次尝试失败过。
7. **小对象上的五倍不能外推。** 同一类提示词、同一个模型、同一道闸门，用在 1.7 万行的对象上：17,236 → 15,844 代码行（1.09 倍），2 小时 49 分钟。代理换掉了三处有现成短论证的地方（Markov 代替二阶矩、对边数归纳代替势函数、取平均代替逐点翻转），占全文一半以上的三大块长论证原样留下。定理 656 → 214 里 89% 来自脚本展开。
8. 大对象上需要读数学的阶段还没做，不在这里下结论。

## 规模 × 来源

| 规模 \ 来源 | 模型生成的证明（单文件） | 模型生成的大型开发（多文件） |
|---|---|---|
| 单个文件，约 3 千行 | [small-ramsey](small-ramsey/README.md)：**完成**，2,902 → 589 代码行，96 → 9 条定理 | — |
| 单个文件，约 1.7 万行 | [small-compactness](small-compactness/README.md)：**完成**，17,236 → 15,844 代码行，656 → 214 条定理 | — |
| 单个文件，约 3.4 万行 | [medium-nonsofic](medium-nonsofic/README.md)：**进行中** | — |
| 仓库，数十万行 | — | [large-assessment](large-assessment/README.md)：两个候选的整库构建、依赖图与取舍，**完成**；选定的对象（NavierStokesAndEuler，50 万代码行）阶段 1 已过闸门，阶段 2 **进行中** |

参照案例（大仓库 × 模型生成的大型开发，一千多万行）在 [`../cases/rh/`](../cases/rh/README.md)；它是别人做的重写，这里的实验是我们自己做、自己量的。

## 各阶段的数字（已过闸门的）

“定理”“定义”从构建后的环境数，只算源码里写出的声明；“代码行”去掉注释、空行、导入与 `open` / `namespace` 等。

| 对象 | 阶段 | 代码行 | 定理 | 定义 | 只用一次的定理 | 最长证明（行） | 构建（秒） | 做法 |
|---|---|---|---|---|---|---|---|---|
| small-ramsey | 0 基线 | 2,902 | 96 | 42 | 67 | 86 | 17 | 上游文件原样 |
| | 1 机械 | 2,902 | 96 | 42 | 67 | 86 | 17 | 无可删 |
| | 2 展开 | 2,902 | 41 | 42 | 14 | 1,071 | 11 | `unroll.py` |
| | 3a 自动化替换 | 2,815 | 43 | 42 | 16 | 733 | 10 | `golf_blocks.py`，24 处 |
| | 3b 化简 | 2,639 | 37 | 42 | 19 | 950 | 31 | 改写代理 |
| | 4 再分块（换论证） | 616 | 9 | 3 | 4 | 180 | 10 | 改写代理 |
| | 5 压短 | 589 | 9 | 3 | 4 | 176 | 9 | 改写代理 |
| small-compactness | 0 基线 | 17,236 | 656 | 273 | 455 | 172 | 28 | 上游文件原样 |
| | 1 机械 | 17,219 | 654 | 272 | 453 | 172 | 36 | 删 3 个别名、3 个没用的实例参数、18 处风格提示 |
| | 2 展开 | 17,245 | 242 | 272 | 116 | 4,071 | 140 | `unroll.py` |
| | 3 化简 | 16,724 | 236 | 266 | 116 | 3,991 | 124 | 改写代理 |
| | 4 再分块 | 16,225 | 214 | 261 | 99 | 3,747 | 96 | 改写代理（换了三处论证） |
| | 5 压短 | 15,844 | 214 | 261 | 99 | 3,691 | 96 | 改写代理（主要是排版） |
| NavierStokesAndEuler（整库） | 0 基线 | 498,912 | 38,084 | 11,822 | 13,586（可达部分） | — | 1,073（32 核） | 上游原样，2,657 个模块 |
| | 1 机械 | 386,279 | 28,746 | 10,566 | — | — | — | `prune_unreachable.py` 两遍，删 10,629 个声明 |
| | 2 展开 | 进行中 | | | | | | `unroll_project.py` |

（small-ramsey 的 3a 是先在阶段 1 的文件上做替换、再展开，所以定理数与阶段 2 略有出入：替换后的证明在外层上下文里有两处内联不再成立。）

## 对象怎么选的

要的是：模型生成或组织松散；为一个标题结果而存在，陈述只用 Mathlib；规模尽量大而仍能完整构建。下面是看过的候选与结论；指标口径同 [`../cases/profiles.md`](../cases/profiles.md)，闭包与层数由 `candidate_graph.py` 从源码的导入图数。

| 候选 | 许可 | 标题定理的导入闭包（模块 / 行） | 定理 | 工具链 | 结论 |
|---|---|---|---|---|---|
| [openai/ten-proofs](https://github.com/openai/ten-proofs) `94bc0feb` | Apache-2.0 | 10 个单文件，3 千到 13 万行，共 548,226 行 | 18,261 | v4.32.0 | 小与中实验的对象：一个文件一个结果，天然分片，构建快 |
| [openai/NavierStokesAndEuler](https://github.com/openai/NavierStokesAndEuler) `f9e8bc5b` | Apache-2.0 | 2,524 / 610,684；两个互不导入的开发：Navier–Stokes 753 / 405,273，Euler 1,771 / 205,411 | 38,084 | v4.34.0-rc2 | **大实验的对象**：服务器上 18 分钟建完 |
| [AxiomMath/Mordell](https://github.com/AxiomMath/Mordell) `82a30cb7` | Apache-2.0 | 自身 432 个模块、124,110 行，另经导入图依赖 Stacks 库的 21,205 个模块、6,436,153 行 | 214,156（连同导入的 Stacks 模块；标题定理可达 51,093） | v4.35.0 | 实建评估过：能建，3 小时 17 分钟、96 核·时；没有选它 |
| [plby/Erdos90](https://github.com/plby/Erdos90) `2062b0e6` | 无许可文件 | 1,461 / 860,449（全库 2,638 / 1,201,169），一条定理 | 36,738 | v4.30.0 | 形态最接近参照案例（28% 的行不在闭包里）；没有许可，结果不能发布，暂不做 |
| [frenzymath/FormalPantheon](https://github.com/frenzymath/FormalPantheon) `5b7e1288`：RestrictedDigits | Apache-2.0 | 3,313 / 597,863 | 18,707 | v4.32.0 | 后段是数值证书（1,714 处 `maxHeartbeats 0`），压缩的是证书的组织，不合本题 |
| 同上：MordellLang | Apache-2.0 | 4,623 / 360,805 | 14,328 | v4.32.0 | 每个小模块都导入整个 Mathlib，构建时间由模块数决定；先要合并模块 |
| [math-inc/strongpnt](https://github.com/math-inc/strongpnt) `2f5835c3` | 无许可文件 | 7 个文件，21,514 代码行 | 1,080 | v4.21.0 | 工具链太旧，没有许可 |
| 人写的研究仓库（PNT+、Carleson、FLT、Sphere-Packing-Lean） | Apache-2.0 | — | — | — | 只作对照：指标接近 Mathlib，引理边界由蓝图决定 |

候选的结构指标（源码口径）：

| 指标 | ten-proofs | NS 一半 | Euler 一半 | Erdos90 | RestrictedDigits | MordellLang |
|---|---|---|---|---|---|---|
| 代码行 | 495,807 | 346,809 | 152,103 | 917,119 | 505,529 | 386,495 |
| 每个定理的平均行数 | 24.9 | 13.4 | 13.5 | 23.1 | 17.7 | 23.3 |
| 只有一个声明的文件 | 0% | 1.7% | 9.4% | 7.8% | 15.0% | 30.3% |
| 注释行占比 | 0% | 4.5% | 5.4% | 10.4% | 3.1% | 0% |
| `have`（每千行） | 66 | 98 | 112 | 44 | 75 | 90 |
| `grind`（每千行） | 0 | 0 | 0 | 0 | 0 | 0 |

## 每个实验的记录里有什么

问题；对象（提交与许可）；环境；每个阶段做了什么、用的脚本或提示词、耗时与机器成本；前后的指标；失败与放弃的做法；各阶段对总缩减的贡献（阶段 i 的比值 rᵢ 取对数后占总比值对数的份额）；结论。原始日志不进仓库，整理过的记录在各实验目录里。Apache-2.0 的对象附结果文件或补丁，保留原许可与出处并写明改动。
