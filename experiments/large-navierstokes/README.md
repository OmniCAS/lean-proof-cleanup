# large-navierstokes：50 万行的多文件生成开发，分阶段压缩

**Summary (English).** The staged process on `openai/NavierStokesAndEuler` (model-generated, Apache-2.0, 2,657 modules, 498,912 code lines, 38,084 theorems; four headline theorems fixed by upstream challenge files), run on the build server. Two stages are done and gated on the whole project: pruning what the headline theorems do not reach (38,084 → 28,746 theorems, 498,912 → 386,279 code lines) and unrolling single-use lemmas module by module (28,746 → 22,005 theorems, code lines unchanged, longest proof 185 → 811 lines, clean build 17.9 → 19.2 minutes). Together: 1.29× in code lines, 1.73× in theorems, all of the line reduction from pruning. The stages that need the mathematics are run on sub-developments with a one-statement contract, chosen from the dominator tree of the declaration graph; three are set up and their rewriting runs are recorded here as they finish. The text is in Chinese.

状态：阶段 1、2 **完成并过闸门**；按块改写（阶段 3–5）**进行中**（2026-11-26）。

## 结论（到阶段 2 为止）

1. **整库上，脚本能做的两个阶段合计 1.29 倍（代码行）、1.73 倍（定理）。** 行数的缩减全部来自删不可达声明；展开把定理数再降 23%，行数不变。
2. **按模块展开在多文件工程里有两个新问题，都靠构建反馈解决。** 一是单次使用的引理有四分之一的使用者在别的模块里（3,616 / 14,355），按模块做就够不着；二是一个模块在源码里提到了另一个模块里被内联掉的引理（证明项里没有引用，依赖图看不到），逐模块检查都通过，整库构建才失败。后者用“整库构建 → 恢复出错模块及它提到的模块 → 再构建”的循环修复，3 轮、17 个模块。
3. **展开没有让整库构建明显变慢。** 清空后重建 19.2 分钟、6.4 核·时（基线 17.9 分钟、6.7 核·时）；最慢的模块 157 → 183 秒。单文件对象上展开让构建慢了四倍，这里因为模块多、单个声明小，没有出现。
4. **读数学的阶段只能按块做。** 展开后的声明图里，从标题定理往下是一条很深的支配链；行数在 1,500 到 4,600 之间、契约是一条定理、文件数不超过 12 的子开发有 18 个。选了其中三个。

## 对象

- 仓库与提交：[openai/NavierStokesAndEuler](https://github.com/openai/NavierStokesAndEuler) `f9e8bc5b38b6e212696e8a30e3e91517af887bbd`，Apache-2.0，Lean v4.34.0-rc2。
- 两个互不导入的开发：Navier–Stokes（标题定理 `NavierStokes.Comparator.navier_stokes_breakdown_R3`、`…_periodic`）与 Euler（`Euler.euler_breakdown_R3`、`Euler.exists_compact_smooth_euler_singularity`），各有上游的 Challenge 文件。
- 怎么选的、整库构建与声明图的基线：[`../large-assessment/README.md`](../large-assessment/README.md)。

## 环境

构建服务器（2 × AMD EPYC 7502，64 核，503 GB），固定一个 NUMA 节点的 32 个物理核，降优先级，构建不联网；原生工具链，Mathlib 用缓存的 olean。闸门：两个标题模块各跑一次（陈述指纹与 Challenge 模块一致、公理只有三条标准公理、构建零错误）。见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。

## 各阶段

| 阶段 | 做法 | 代码行（NS / Euler / 合计） | 定理 | 定义 | 可达部分里只用一次的定理 | 最长的定理（行） | 清空后整库构建 | 闸门 |
|---|---|---|---|---|---|---|---|---|
| 0 基线 | 上游原样 | 346,809 / 152,103 / 498,912 | 38,084 | 11,822 | 13,586 | — | 17.9 分钟，6.7 核·时，最慢模块 157 秒 | 过 |
| 1 机械 | `prune_unreachable.py` 两遍 | 254,905 / 131,374 / 386,279 | 28,746 | 10,566 | 13,586 | 185 | 未单独计时 | 过 |
| 2 展开 | `unroll_project.py` + `repair_modules.py` | 255,018 / 131,411 / 386,429 | 22,005 | 10,566 | 8,021 | 811 | 19.2 分钟，6.4 核·时，最慢模块 183 秒 | 过 |
| 比值（0 → 2） | | 1.36 / 1.16 / 1.29 | 1.73 | 1.12 | | | | |

定理与定义从构建后的环境数；代码行是源码口径（去掉注释、空行、导入与 `open` / `namespace` 等）。

各阶段的贡献（比值取对数后的份额）：

| | 代码行 | 定理 |
|---|---|---|
| 1 机械 | 100% | 51% |
| 2 展开 | 0% | 49% |

### 阶段 1：整库删不可达声明

细节（两遍、三种依赖图看不见的依赖、保留规则）在 [`../large-assessment/README.md`](../large-assessment/README.md) 的同名一节。15,387 个不可达声明删掉 10,629 个；可达的 25,210 条定理原样保留。

### 阶段 2：按模块展开

工具：[`unroll_project.py`](../../scripts/refold/unroll_project.py)。对每个模块单独运行展开脚本（在模块文件的副本上内联、用 `lake env lean` 检查该文件、按错误撤回或提心跳、循环），30 个模块并行；全部结束后一次写回。

| | 数量 |
|---|---|
| 只被一处使用的定理（阶段 1 之后） | 14,355：使用者在同一模块 10,739，在别的模块 3,616（按模块做够不着，没有尝试） |
| 候选（使用者是同模块的定理、不出现在使用者的陈述里等） | 8,905，分布在 1,603 个模块 |
| 成功的模块 | 1,580：全部候选都内联的 896 个，部分撤回的 224 个，一个也没成的 183 个，逐模块复查后没有候选的 277 个 |
| 内联的引理 | 6,843 |
| 失败、保持原样的模块 | 23（候选 637，其中一个模块占 317）：错误无法归到某一次内联 9 个；撤回后同样的错误反复出现 9 个；超过轮数上限 5 个 |
| 每个模块的轮数 | 一轮通过 1,157 个；最多 11 轮 |
| 提高心跳上限的声明 | 28 个，分布在 24 个模块；全库的 `maxHeartbeats` 选项 5 → 30 |
| 用时 | 66 分钟（32 核，30 个并行任务） |

**整库构建在逐模块都通过之后仍然失败**：13 个模块、42 处错误。原因是这些模块在源码里（`simp […]` 列表、`open … in`、策略块里没被用上的 `have` 等）提到了别的模块里的引理，而那条引理在自己的模块里只被一处使用、已被内联；证明项里没有这次引用，依赖图看不到，逐模块检查用的又是内联前的 `.olean`。

修复工具：[`repair_modules.py`](../../scripts/refold/repair_modules.py)。整库构建；把出错的模块、以及错误里“未知标识符”原本所在的模块，恢复到阶段 1 的版本；重复到构建通过。

| 轮 | 错误 | 本轮恢复的模块 |
|---|---|---|
| 1 | 42 | 12 |
| 2 | 8 | 5 |
| 3 | 0 | — |

恢复 17 个模块，11 分钟。结果：定理 28,746 → 22,005（少 6,741 条），最长的定理 185 → 811 行，定理平均 11.6 → 15.0 行，代码行 +150。两个闸门通过；随后清空构建目录重建一次（19.2 分钟，2,657 个模块，零错误），再过一次闸门。

剩下的单次使用定理 8,197 条：使用者在别的模块 3,654 条，同模块 4,543 条（撤回的、失败模块里的、使用者是定义的、带属性的）。跨模块的内联没有做：它要移动声明并改导入，属于模块重组。

## 阶段 3–5：按块改写

做法与 [`../block-contracts/README.md`](../block-contracts/README.md) 相同：

1. 在声明图上算支配树（[`dominators.py`](../../scripts/refold/dominators.py)）。声明 D 支配 E，指从标题定理到 E 的每条依赖路径都经过 D；被 D 支配的声明只为 D 而存在。D 的陈述就是这一块的**契约**。
2. 每块一份工作副本、一次改写运行。块内怎么证都行；契约的陈述指纹不变、改动只落在块的行范围内、标题模块的闸门通过，才算数（[`block_gate.py`](../../scripts/refold/block_gate.py)）。
3. 各块的改动互不重叠，可以合并。

展开之后的支配结构：可达声明 29,095 个、338,068 行；支配 1,200 行以上的声明 124 个，一层套一层（最外层的 `NavierStokesR3.theorem_1_1_with_initial_rest` 支配 218,960 行）。契约是定理、行数 1,500–4,600、文件不超过 12 个的有 18 个。选了三个互不相交的：

| 块 | 契约 | 声明（定理） | 行 | 文件 | 行范围段数 |
|---|---|---|---|---|---|
| pulse | `NavierStokes.PulseCone.exists_corrected_pulse_threshold` | 98（58） | 2,035 | 5 | 21 |
| matching | `NavierStokes.MatchingDebtBounds.exists_ordered_matching_threshold` | 51（32） | 1,571 | 3 | 19 |
| repair | `NavierStokes.ModulatedCone.Repaired.exists_with_moment_repair` | 123（88） | 3,067 | 10 | 45 |

三个块各有一份服务器上的工作副本（各 8.4 GB，Mathlib 的构建产物共用），契约的指纹已在阶段 2 的状态上记录（分别 216、762、209 行指纹：契约的类型加上它提到的全部项目内常量）。改写运行的结果出来后记在这里。

## 机器成本（阶段 1、2）

| 步骤 | 墙钟 | 说明 |
|---|---|---|
| 基线整库构建 | 17.9 分钟 | 32 核 |
| 声明图 | 约 30 秒 | 每个阶段一次 |
| 阶段 1 | 两遍共 9 轮整库构建（多数是增量） | 见 large-assessment |
| 阶段 2 展开 | 66 分钟 | 30 个并行的单文件检查 |
| 阶段 2 修复 | 11 分钟 | 3 轮增量构建 |
| 阶段 2 清空重建 | 19.2 分钟 | 验收用 |

没有用模型的地方：阶段 1、2 全部由脚本完成。
