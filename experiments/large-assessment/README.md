# large-assessment：两个大候选的实建评估与取舍

**Summary (English).** Two large model-generated repositories were fetched and built on the build server to choose the subject of the large experiment. `openai/NavierStokesAndEuler` builds unchanged in 17.9 minutes on 32 cores (6.7 core-hours); `AxiomMath/Mordell` with the part of the Stacks library it imports takes 3 h 17 min (96 core-hours, 21,637 modules). In NavierStokesAndEuler 33.8% of 38,084 theorems are unreachable from its four headline theorems; in Mordell + Stacks the headline theorems reach 23.9% of the 214,156 theorems in the imported modules. NavierStokesAndEuler is chosen: a full gate is eleven times cheaper and the repository is self-contained on Mathlib. Its mechanical stage (whole-project pruning in two passes) is done and gated: 38,084 → 28,746 theorems, 498,912 → 386,279 code lines; the later stages are recorded in [`../large-navierstokes/`](../large-navierstokes/README.md). The text is in Chinese.

状态：评估**完成**，对象已选定；大实验的阶段 1 已过闸门，之后的阶段见 [large-navierstokes](../large-navierstokes/README.md)（2026-11-26）。

## 结论

1. **选 `openai/NavierStokesAndEuler`。** 一次整库闸门 18 分钟（Mordell + Stacks 是 3 小时 17 分钟）；仓库只依赖 Mathlib；两个标题结果各有上游的 Challenge 文件。
2. **两个候选的死代码比例都高，但性质不同。** NavierStokesAndEuler 里 33.8% 的定理从标题定理出发不可达，这些是为这个结果生成、最后没用上的东西。Mordell 的标题定理只用到它所导入的 Stacks 模块里 22.9% 的定理，其余是库的其它部分；对一个库来说它们不是死代码。
3. **整库删不可达声明可以做，但依赖图有三种看不见的依赖**，每一种都让第一次尝试失败过：用 `rfl` 证明的 `@[simp]` 引理、强制转换实例（`CoeFun` 等）、`autoImplicit` 下被当成隐式变量的缺失名字。修正后两遍删掉了 15,387 个不可达声明里的 10,629 个。
4. **机械阶段在这个对象上值 1.29 倍（代码行）、1.32 倍（定理）**，与参照案例“两到三倍”同向而小；单文件对象上是 1.00 倍。

## 候选一：`openai/NavierStokesAndEuler`（选定）

- 提交 `f9e8bc5b38b6e212696e8a30e3e91517af887bbd`，Apache-2.0，Lean v4.34.0-rc2。
- 两个互不导入的开发：Navier–Stokes（标题定理 `NavierStokes.Comparator.navier_stokes_breakdown_R3`、`…_periodic`）与 Euler（`Euler.euler_breakdown_R3`、`Euler.exists_compact_smooth_euler_singularity`），各有上游的 Challenge 文件。
- 构建前扫描：没有 `#eval`、自定义宏或展开器、`axiom`、`native_decide`。

### 整库构建（原生工具链，代码未改，32 个物理核）

| 指标 | 值 |
|---|---|
| 模块 | 2,657 |
| 墙钟 | 17.9 分钟 |
| CPU | 5.8 核·时（用户）+ 0.9（系统） |
| 最慢的模块 | 157 秒 |
| 同时的 Lean 进程 | 32 |
| 系统内存增量 | 约 12 GB |
| 构建目录 | 8.7 GB |
| 错误 | 0 |

两个标题模块的闸门（陈述指纹与 Challenge 模块一致、公理只有三条标准公理）：通过。

### 声明依赖图（从环境读，`lean/ProjectGraph.lean`，约 30 秒）

| | 整库 | Navier–Stokes 一半 | Euler 一半 |
|---|---|---|---|
| 用户声明 | 50,597 | | |
| 定理 | 38,084 | 26,918 | 11,166 |
| 定义 | 11,822 | 8,305 | 3,517 |
| 从标题定理可达的定理 | 25,210（66.2%） | 16,725（62.1%） | 8,485（76.0%） |
| **不可达的定理** | **12,874（33.8%）** | 10,193（37.9%） | 2,681（24.0%） |
| 可达定理的行数 / 全部定理的行数 | 296,152 / 443,767 | 196,341 | 99,811 |
| 可达部分里只被一处使用的定理 | 13,586（53.9%） | 9,043（54.1%） | 4,543（53.5%） |
| 含可达声明的模块 / 含声明的模块 | 2,295 / 2,652 | 594 | 1,701 |

## 候选二：`AxiomMath/Mordell` + Stacks

- 提交 `82a30cb7857f6e3cfdb1be91f5533c0ccb57d493`，Apache-2.0，Lean v4.35.0；依赖 `AxiomMath/Stacks` @ `c496df0d`。
- 标题定理：Faltings 定理的三种陈述（`LeanEval.AlgebraicGeometry.Faltings.faltings`，即 lean-eval 的陈述，只用 Mathlib；`Faltings.finite_setOf_comp_eq_id_of_two_le_genus`；`Faltings.finite_setOf_place_isDegreeOne`）。
- 构建前扫描：Mordell 有一个定义属性的文件；Stacks 有 38 个文件含 `run_cmd`、宏与属性（EGA / SGA 索引登记），没有文件或进程 IO。

### 整库构建（原生工具链，代码未改，32 个物理核）

| 指标 | Mathlib `56a00585`（从源码） | Mordell + 它导入的 Stacks 模块 |
|---|---|---|
| 模块 | 9,030 | 21,637（Mordell 432，StacksCore 446，StacksFrontier 20,759） |
| 墙钟 | 23.3 分钟 | **3 小时 17 分钟** |
| CPU | 9.7 核·时（用户）+ 1.5（系统） | **88.5 核·时（用户）+ 7.8（系统）** |
| 最慢的模块 | 73 秒 | 1,284 秒 |
| 单个进程最大常驻内存 | 2.9 GB | 18.3 GB |
| 系统内存增量 | 约 7 GB | 约 78 GB |
| 构建产物 | — | Stacks 80 GB，Mordell 3.9 GB |
| 错误 | 0 | 0 |

（Mordell 构建期间同一台机器的其它核上还跑着我们的另外两个任务，墙钟略受影响。Mathlib 之所以从源码构建，见 [`../../docs/experiment-infra.md`](../../docs/experiment-infra.md)。）

### 标题定理的声明级闭包

两万多个模块系统的模块不能一次导入同一个环境：每个模块要三个内存映射，超过了内核对映射数的上限。改用 [`lean/ClosureFromOleans.lean`](../../scripts/refold/lean/ClosureFromOleans.lean)：逐个模块读 `.olean` 的各部分，只留名字的哈希与引用关系，读完即释放；21,637 个模块、503,820 个常量，4 分 22 秒。

| 库 | 定理（含 `private`） | 从三条标题定理可达 | 可达的里只被一处使用 |
|---|---|---|---|
| Mordell | 3,703 | 3,191（86.2%） | 2,102（65.9%） |
| StacksCore（被导入的部分） | 2,627 | 232（8.8%） | 110 |
| StacksFrontier（被导入的部分） | 207,826 | 47,670（22.9%） | 30,086（63.1%） |
| 合计 | 214,156 | 51,093（23.9%） | 32,298（63.2%） |

读法：Faltings 定理的证明实际用到约 5.1 万条定理，其中 4.8 万条在 Stacks 里。Stacks 是同一批代理写的通用库，标题定理只用到它被导入部分的不到四分之一。

## 取舍

| | NavierStokesAndEuler | Mordell + Stacks |
|---|---|---|
| 一次整库闸门 | 17.9 分钟，6.7 核·时 | 3 小时 17 分钟，96 核·时 |
| 标题定理用到的定理 | 25,210 | 51,093 |
| 不可达的比例 | 33.8%（为本结果生成而没用上） | 76.1%（多数是库的其它部分） |
| 可达部分里只用一次的定理 | 53.9% | 63.2% |
| 自成一体 | 是（只依赖 Mathlib） | 否（主体在另一个仓库 Stacks 里） |
| 许可 | Apache-2.0 | Apache-2.0 |

选 NavierStokesAndEuler：闸门便宜十一倍，才能在一个阶段里重建多次；改动都落在一个仓库里；它的不可达声明确实是可以删的东西。Mordell + Stacks 的数字保留在这里，作为“标题定理加上它用到的库”这一形态的一个测量。

## 大实验的阶段 1：整库删不可达声明（已过闸门）

工具 [`prune_unreachable.py`](../../scripts/refold/prune_unreachable.py)：按依赖图删掉闭包外的声明，构建，按错误恢复，循环到构建通过。

| | 声明 | 定理 | 定义 | 代码行（NS / Euler / 合计） | 含声明的模块 |
|---|---|---|---|---|---|
| 基线 | 50,597 | 38,084 | 11,822 | 346,809 / 152,103 / 498,912 | 2,652 |
| 第一遍 | 44,047 | 32,471 | 10,914 | 296,846 / 131,374 / 428,220 | 2,437 |
| 第二遍 | 39,968 | 28,746 | 10,566 | 254,905 / 131,374 / 386,279 | 2,434 |
| 比值（基线 / 第二遍） | 1.27 | 1.32 | 1.12 | 1.36 / 1.16 / 1.29 | |

两个标题模块的闸门在两遍之后都通过；可达的 25,210 条定理原样保留。源码共删 129,436 行，改动 1,443 个文件。

**三种依赖图看不见的依赖**（依赖图是从证明项读的）：

| 现象 | 原因 | 处理 |
|---|---|---|
| 删完以后 `simp` 证明不再成立，报的是“目标未解决”而不是“找不到名字” | 用 `rfl` 证明的 `@[simp]` 引理由 `simp` 按定义改写，不在使用它的证明项里留下引用 | 带属性的不可达声明一律保留（1,038 个） |
| “此处需要函数”“类型不匹配”一类错误成片出现（一遍 64 处） | 强制转换实例（如 `CoeFun`）在展开阶段被展开，生成的项里不再提到它 | 实例一律保留 |
| “此处需要函数，但该项的类型是 `?m`” | 该库开着 `autoImplicit`，签名里一个被删掉的名字被当成了隐式绑定变量，错误信息的正文里才说这个标识符未知 | 从错误正文里取名字并恢复 |

另外，删除前先保留“短名仍出现在剩余源码里”的不可达声明（约 3,100 个，偏保守：短名相同就算），避免把只在 `simp […]` 列表、`attribute` 行或记号里提到的名字删掉。

过程：第一遍 6 轮构建（其中一步把某个模块传递导入的全部已删声明都恢复了，过于粗；删掉 6,550 个）；找出实例这一条以后做第二遍，3 轮，再删 4,079 个。最终 15,387 个不可达声明里删了 10,629 个（69%），留下 4,758 个（带属性、实例、名字被提到的，以及少量修复时恢复的）。有 218 个模块不再含任何声明，文件还在（合并或删除模块属于模块重组，没有做）。

## 之后

阶段 2（按模块展开）已完成并过闸门，记录在 [`../large-navierstokes/README.md`](../large-navierstokes/README.md)：定理 28,746 → 22,005，代码行不变。
