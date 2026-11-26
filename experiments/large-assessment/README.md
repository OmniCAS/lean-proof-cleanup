# large-assessment：两个大候选的实建评估

**Summary (English).** Assessment, by actually fetching and building on the build server, of two large model-generated repositories as subjects for the full treatment: `openai/NavierStokesAndEuler` (2,657 modules, 610,684 lines in the headline closure by imports) and `AxiomMath/Mordell` with the part of the Stacks library it uses. So far: NavierStokesAndEuler builds unchanged in 17.9 minutes on 32 cores; its declaration graph has 38,084 theorems, 33.8% of them unreachable from the four headline theorems, and 54% of the reachable ones used exactly once; a first pass of whole-project pruning is running. The Mordell build is in progress. The choice between the two is made when both are measured. The text is in Chinese.

状态：**进行中**（2026-11-26）。

## 问题

哪个大仓库适合做全流程：能在可接受的时间内完整构建并反复重建；为一个标题结果而存在；冗余的形态与数量。

## 候选一：`openai/NavierStokesAndEuler`

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

### 声明依赖图（从环境读，`ProjectGraph.lean`，31 秒）

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

读法：这个仓库有成片的死代码（三分之一的定理从标题定理出发用不到），比例高于参照案例原始开发的 24%；可达部分里过半的定理只被用一次。机械阶段与展开阶段在它上面都有内容。

### 机械阶段的第一次尝试（整库删不可达声明）

工具 [`prune_unreachable.py`](../../scripts/refold/prune_unreachable.py)：按依赖图删掉闭包外的声明，构建，按错误恢复，循环。

- 试算：15,387 个不可达声明里，3,431 个因为短名仍出现在剩余源码里先保留，其余 11,956 个删除，共 128,589 行源码（全库的 20%）。
- 第一次运行失败并已回退：14 轮以后还剩 5 处错误，都是“证明不再成立”而不是“找不到名字”。原因：用 `rfl` 证明的 `@[simp]` 引理由 `simp` 按定义改写，**不在使用它的证明项里留下引用**，依赖图看不到，于是被当成不可达删掉了。
- 改法：带属性的不可达声明一律保留（1,038 个），其余错误按“本模块 → 直接导入 → 传递导入”逐级恢复。按新规则试算删除 11,264 个声明、126,333 行。第二次运行进行中。

## 候选二：`AxiomMath/Mordell` + Stacks

- 提交 `82a30cb7857f6e3cfdb1be91f5533c0ccb57d493`，Apache-2.0，Lean v4.35.0；依赖 `AxiomMath/Stacks` @ `c496df0d`。
- 标题定理：Faltings 定理（lean-eval 的 `faltings` 陈述，只用 Mathlib）。
- 按导入图，Mordell 自身 432 个模块、124,110 行，另依赖 Stacks 的 21,205 个模块、6,436,153 行。
- 构建前扫描：Mordell 有一个定义属性的文件；Stacks 有 38 个文件含 `run_cmd`、宏与属性（EGA / SGA 索引登记），没有文件或进程 IO。
- 这一版 Mathlib（`56a00585`）在服务器上从源码构建：9,030 个模块，23.3 分钟，11.1 核·时。
- Mordell 的构建进行中：前 26 分钟建成 4,639 个模块（平均每个 10.3 秒，同时 31 个进程，系统内存约 66 GB）。

构建完成后补：总用时与内存、标题定理的声明级闭包、指标，以及两个候选的取舍。
