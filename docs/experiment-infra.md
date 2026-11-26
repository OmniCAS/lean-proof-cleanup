# 实验环境与工作流

**Summary (English).** How the experiments under [`../experiments/`](../experiments/README.md) are run: two machines (a 12-core, 16 GB laptop and a shared 64-core, 503 GB build server), toolchains and sources fetched as verified archives, builds without network access on a pinned block of cores, a four-part gate (frozen statement files, statement fingerprint against the challenge module, axioms, full build), and the scripts that implement each stage. It also records what went wrong while setting up, since most of the setup time went there. The text is in Chinese.

## 1. 判断

1. **环境搭建的时间主要花在“把东西弄到机器上”。** 构建服务器直连只够得到 GitHub 的网页、API 与 Mathlib 的缓存；发布资产连不上，源码包只有约 20 KB/s，从笔记本上传约 9 KB/s。能用的路是镜像与中转站，前提是每个文件都能对上官方的校验值。
2. **“不可信的下载”可以变成可信的，只要校验值来自官方渠道。** 工具链用 GitHub API 给出的发布包 SHA-256；源码用该提交的 git tree 哈希。对不上就不用：有一个二进制（缓存工具要的静态 curl）没有官方校验值，我们放弃它，改为从源码构建那一版 Mathlib。
3. **多文件工程的构建时间由模块个数决定。** 每个模块有几秒到几十秒的固定导入开销；16 GB 的机器上 12 个进程并行会用到 4–7 GB 交换区。单文件的大证明没有这项开销。
4. **闸门必须便宜到每次改动都能跑。** 小对象一分钟内；大对象分两级：改动只重建受影响的部分，阶段末跑全库。

## 2. 机器

| | 笔记本 | 构建服务器 |
|---|---|---|
| 处理器 | Apple arm64，12 核 | 2 × AMD EPYC 7502，64 核 128 线程 |
| 内存 | 16 GB | 503 GB |
| 用途 | 编辑、分析、小对象的构建与闸门 | 大对象的构建、整库依赖图、耗时的批量试探 |
| 约束 | 12 个 Lean 进程并行时空闲内存降到 23–32% | 共用机器：先看负载，固定一个 NUMA 节点的 32 个物理核，`nice -n 10`，不用管理员权限，只写自己的目录 |
| 隔离 | `sandbox-exec -p '(version 1)(allow default)(deny network*)'` | `unshare -r -n`（无网络的用户命名空间） |

服务器上所有东西放在一个工作目录下：`toolchains/`、`dl/`、`src/`（源码包）、`work/<项目>/`、`mathlib-cache/`、`logs/`、`results/`、`tools/`。

## 3. 取工具链、源码与 Mathlib

脚本在 [`../scripts/refold/server/`](../scripts/refold/server/)。

| 步骤 | 脚本 | 做法 | 校验 |
|---|---|---|---|
| Lean 工具链 | `fetch_toolchain.sh` | 从镜像或中转站取官方的 `lean-<版本>-linux.tar.zst`，解到工作目录；不经 elan，按路径调用 `bin/lake` | 与 `api.github.com/repos/leanprover/lean4/releases/tags/v<版本>` 给出的该资产的 SHA-256 相等才解包 |
| 项目与依赖的源码 | `setup_project.py` | 取项目在指定提交的源码包；读它的 `lake-manifest.json`，把每个 git 依赖在 manifest 提交处的源码包解到 `.lake/packages/<名字>`，提交成本地快照，manifest 的 `rev` 改指快照；Lake 此后不联网 | 每棵解出的树的 git tree 哈希与 GitHub API 报告的该提交的 tree 相等；不等时逐文件比对，只接受“源码包里没有子模块指针”这一种差异 |
| Mathlib 的 olean | `cache_get.sh` | 用 Mathlib 自己的缓存工具 | 工具按文件内容算哈希再取对应的包 |

三处实际遇到的问题：

1. **缓存工具拒绝运行。** 它比较工程 manifest 与 Mathlib manifest 里共同依赖的提交号，不一致就退出；快照的提交号必然不同（内容相同）。做法：先在快照 manifest 下构建工具并用 `lake env printenv` 取环境，再把上游 manifest 换回去、直接运行工具的二进制，结束后换回快照 manifest。
2. **较新的缓存工具要求 curl ≥ 7.84。** 服务器是 7.81，工具会去 GitHub 发布资产下载一个静态 curl；这个资产没有官方校验值，我们没有用。那一版 Mathlib 改为在服务器上从源码构建（见第 5 节的用时）。
3. **源码包与提交的 tree 可以不同。** 一个依赖的某个提交里有子模块指针（gitlink），源码包不含它；逐文件比对后其余 258 个文件一致。

本次共取 3 个工具链、35 个源码包，全部通过校验。

## 4. 构建与度量

| 做什么 | 脚本 | 输出 |
|---|---|---|
| 整库构建（绑核、降优先级、无网络、计时、内存采样） | `server/build_project.sh`、`server/memsample.py` | 墙钟、CPU、每个模块的秒数、同时的 Lean 进程数、内存、构建目录大小 |
| 整库声明依赖图（从环境读，辅助常量归到所属声明） | `lean/ProjectGraph.lean`、`server/project_graph.sh`、`graph_summary.py` | 每个用户声明一行（种类、模块、行范围、用到的声明）；从标题定理出发的可达性；被 0 / 1 / 2+ 处使用的定理数 |
| 单个对象的闸门 | `gate.py`、`lean/GateTools.lean` | G1–G4 的结论与构建用时 |
| 单个对象的度量 | `metrics.py`（源码口径同 `../scripts/profile_lean_trees.py`） | 行、代码行、gzip 字节、定理与定义个数、单次使用的定理数、证明长度分布、策略密度 |
| 候选筛选（不构建） | `candidate_graph.py`、`reference_counts.py` | 导入图的闭包、层数、最长链；按短名估计的引用次数 |

## 5. 闸门

每个阶段的产物都要同时满足四条；小对象每次都跑，大对象阶段内只重建受影响的部分、阶段末跑全库。

| 编号 | 检查 | 做法 |
|---|---|---|
| G1 | 陈述文件与闸门代码未动 | SHA-256 与首次记录一致 |
| G2 | 最终陈述不变 | 对每条标题定理，取它的类型以及类型里出现的全部项目内常量（递归到它们的类型与定义体）的结构哈希；在 Challenge 模块与 Solution 模块里各算一次，逐行相同 |
| G3 | 没有新公理 | 每条标题定理的公理集合 ⊆ {`propext`, `Classical.choice`, `Quot.sound`}；这同时排除 `sorry` 与 `native_decide` |
| G4 | 完整构建 | 删掉对象自己的构建产物后重建，无网络，零错误 |

G2 是 `lake comparator` 在“陈述相等”这一项上的替代，不做独立内核重放。反向测试：把一条标题定理陈述里的 `(k : ℝ)` 改成 `(k : ℝ) + 0` 并证掉，构建与公理都正常，G2 报不一致。

## 6. 阶段与脚本

| 阶段 | 脚本 | 说明 |
|---|---|---|
| 1 机械清理 | `metrics.py` 的依赖图、`lean/GateAnalysis.lean`（类型相同的定理、别名）、Batteries 的 `#lint only unusedArguments` | 闭包外的声明、重复陈述、别名、没用到的参数、linter 提示 |
| 2 展开 | `unroll.py` | 把只被一条定理使用的定理改写成使用者证明开头的 `have`；构建失败时按错误位置撤回对应的内联或提高心跳上限，最后把被撤回的逐个重试 |
| 3 化简（自动部分） | `lean/Golf.lean`、`golf_blocks.py` | 给每个证明块加探针，一次编译得出哪些块能被一行自动化替换；替换后重建，失败的撤回 |
| 3–5 化简、再分块、压短（要读数学的部分） | 改写代理，提示词在 `prompts/` | 每个子阶段过一次闸门并提交；代理写日志，按操作类型计数 |

展开脚本处理的情况（每一条都来自一次构建失败）：`Type*` 在证明内的 `have` 里会给外层定理凭空加宇宙参数，改写成 `Type _`；节变量按签名里出现的名字复制成绑定，`omit … in` 排除的实例不复制；使用者在别的命名空间或 `open` 范围时用 `(open … in have …)` 包住；限定名引用改成局部名；源码里提到但证明项没有用到的引用（依赖图里看不到）在构建报“未知标识符”时撤回；内联后的大声明超过心跳预算时逐级加倍并记录。

## 7. 整库构建的实测（构建服务器，32 个物理核，上游代码未改，原生工具链）

| 项目 | 模块 | 墙钟 | CPU（用户 + 系统） | 最慢的模块 | 同时的 Lean 进程 | 系统内存增量 | 构建目录 |
|---|---|---|---|---|---|---|---|
| `openai/ten-proofs` @ `94bc0feb`（十个单文件证明，Lean v4.32.0） | 10 | 19.8 分钟 | 4.0 + 0.05 核·时 | 955 秒 | 9 | 约 25 GB（单进程最大 15.6 GB） | 0.7 GB |
| `openai/NavierStokesAndEuler` @ `f9e8bc5b`（Lean v4.34.0-rc2） | 2,657 | 17.9 分钟 | 5.8 + 0.9 核·时 | 157 秒 | 32 | 约 12 GB | 8.7 GB |

同一批对象在笔记本上的限时探测（没有建完）见 [`../experiments/README.md`](../experiments/README.md) 的候选一节。
