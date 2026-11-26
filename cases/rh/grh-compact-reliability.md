# grh-lean 紧凑版的可靠性

**Summary (English).** A statement and trust-surface audit of the compact edition of `lsernau/grh-lean` (`grh-compact/`, commit `72fead1`, Lean v4.35.0, Mathlib `56a00585`). Its five theorems are the same statements as the original development's: the first is Mathlib's `RiemannHypothesis`, the four definitions in `Statements.lean` match the original text exactly, and the Mathlib definitions of ζ and Dirichlet L-functions did not change between the two Mathlib versions. The source contains no `sorry`, no custom axiom, no kernel bypass, no macro or metaprogram. MIT reports that all six checkers accept its export and that `lake comparator --paranoid` passes on two machines; our own build in a sandbox without network (12 cores, 16 GB; Mathlib and its dependencies prebuilt at the pinned revisions, so only the project's own modules were compiled) completed with 9,843 jobs and no errors, and `#print axioms` shows only the three standard axioms; our full export did not finish in 16 GB of memory, so we ran no independent kernel locally. The mathematics is unreviewed. The text is in Chinese.

对象：[grh-lean][grh] 提交 `72fead1` 的 `grh-compact/`（Lean v4.35.0，Mathlib `56a00585`）。口径：**本仓库核对**＝我们读源码或运行得到；**本仓库测**＝我们在本机运行得到；**他人报告**＝MIT 核验页 [D18] 或作者 README 的说法，我们没有复现。

## 核心判断

1. **命题没有问题。** 五个定理与原始版本是同一组陈述：第一个就是 Mathlib 的 `RiemannHypothesis`，另外四个定义的文本与原始归档的 `Statements.lean` 逐字相同；两版所用的 Mathlib 里，ζ 与 Dirichlet L 函数的定义没有变（§1）。
2. **"Lean 接受了这个证明"很可靠。** 源码里没有 `sorry`、自定义公理、绕过内核的手段，也没有自定义宏或元程序（§2）。据 MIT，六个检查器都接受完整导出，两个独立的陈述比对确认五个定理，`lake comparator --paranoid` 在两台机器上通过（§3）。我们在断网沙箱里独立构建通过，`#print axioms` 只有三条标准公理（§6）。
3. **剩下的风险不在这个版本本身。** 一是检查链共用的部分（Lean 的类型论、导出工具）出问题，概率很小；二是数学没有人读过，这不影响机器结论，但没人能说明证明为何成立（§4）。
4. **紧凑版不适合阅读，但这不降低可靠性。** 内核检查的是证明项，不是写法。它比原始版本小两个数量级是真的，不是靠超长行凑出来的（§5）。要研究证明应读可读版。

准确的说法是：这份开发陈述了 RH 与 Dirichlet GRH，多个独立检查器报告接受其证明；数学上尚无人审阅。

## 1 命题（本仓库核对）

| 检查 | 结果 |
|---|---|
| `src/Statements.lean` 的四个定义，与原始归档的 `Statements.lean`（社区仓库 `original` 分支，提交 `40e56bab`）比较（去空白） | 四个都逐字相同 |
| `src/Main.lean` 的五个定理名与类型，与原始 `Main.lean` 比较 | 相同；第一个的类型是 Mathlib 的 `RiemannHypothesis` |
| `Statements.lean` 的导入 | 只有 `import Mathlib` |
| `Challenge.lean` | 只导入 `Statements`，五个定理写成 `sorry`，没有别的内容 |
| `comparator.json` | 五个定理名；允许的公理只有 `propext`、`Quot.sound`、`Classical.choice`；启用 nanoda |
| Mathlib 版本 | `56a00585`，是官方仓库 master 的祖先提交（"bump toolchain to v4.35.0"，2026-10-13）；其余 8 个依赖的版本与 Mathlib 自己的清单一致 |
| 原始版本所用 Mathlib（`0df444a3`）与本版之间，定义 ζ、L 函数、Dirichlet 特征的 8 个 Mathlib 文件的差别 | 只有导入行、`open` 行和证明脚本的写法；没有定义改动 |

这些陈述的含义由 Mathlib 里已证的定理固定：

- `riemannZeta`：`zeta_eq_tsum_one_div_nat_cpow` 说 Re s > 1 时它等于 ∑ n^(−s)，`differentiableAt_riemannZeta` 说它在 s ≠ 1 处可微；ℂ∖{1} 连通，所以满足这两条的函数唯一，就是 ζ。
- `DirichletCharacter.LFunction`：同理，由 `LFunction_eq_LSeries`（Re s > 1 时等于 L 级数）与 `differentiableAt_LFunction`（s ≠ 1 或 χ ≠ 1 时可微）固定。
- 例外点处理正确：ζ 的陈述排除 s = 1 和 −2, −4, …；L 函数的半平面形式只排除"主特征在 s = 1"，带状形式限制在 0 < Re s < 1；非本原特征多出的零点都在 Re s = 0 上，不在陈述范围内。

MIT 页另有把五个陈述完全展开（含所有实例）的输出，与上面的读法一致 [D18]。

## 2 源码里有没有绕过检查的东西（本仓库核对）

对 `src/` 下 794 个文件去掉注释后扫描：

| 项目 | 次数 |
|---|---|
| `sorry` / `admit` | 0 |
| `axiom` 声明 | 0 |
| `native_decide`、`ofReduceBool`、`trustCompiler` | 0 |
| `implemented_by`、`extern`、`unsafe`、`opaque`、`partial` | 0 |
| `#eval`、`run_cmd`、`initialize`、`IO` | 0 |
| 自定义 `macro` / `elab` / `syntax` / `notation` | 0 |
| `open Lean`、`Lean.Elab`、`Lean.Meta` | 0 |
| 关闭内核检查的选项（`debug.skipKernelTC` 等） | 0 |

- `set_option` 只有四种：`backward.isDefEq.respectTransparency false`（30）、`synthInstance.maxHeartbeats 200000`（9）、`synthInstance.maxSize 999`（5）、`warning.simp.varHead false`（1），都只影响搜索，不影响内核。
- `lakefile.toml` 只设了栈大小、`autoImplicit false`、`maxSynthPendingDepth 3`、`maxHeartbeats`，没有脚本。
- 全局设置集中在 `src/Lib/General/LinearAlgebra/Base.lean`：实例优先级和 simp 集合的调整，同样只影响搜索。
- `decide` 出现 24 次，是内核内求值，受内核检查。
- 仓库里除 `.lean` 外只有 README、许可证和配置文件，没有预编译产物。

所以构建时不会运行这份仓库自带的任何程序，只有 Lean 与 Mathlib 自己的策略。

## 3 机器核验（他人报告，MIT 核验页 2026-11-26 02:50 UTC 版，全部检查已结束；03:09 UTC 读取）

| 检查 | 紧凑版的结果 |
|---|---|
| 沙箱内 `lake build` | 通过，9,843 个任务，零错误，33 分 32 秒 |
| `#print axioms`（五个定理） | 只有三条标准公理 |
| `leanchecker` 逐模块内核重放 | 794 / 794 接受 |
| 两台机器分别导出 | 逐字节相同，5,172,274,528 字节 |
| nanoda、con-leche、con-ron 跑完整导出 | 都接受（con-leche 接受 204,583 个声明） |
| con-leche / con-ron `--compare` 对照 challenge | 五个定理都确认 |
| Lean 默认内核与 paranoid 内核、lean4lean 跑导出 | 都接受 |
| `lake comparator --paranoid`（构建、陈述比对、公理检查，再依次跑 nanoda、paranoid 内核、lean4lean、nanoda、con-leche、con-ron、默认内核） | 两台机器上都给出 "Your solution is okay!"（分别在 00:49 与 01:39 UTC 结束） |

作者自报：Comparator v4.35.0 接受（用替代品代替其沙箱） [D16]。

## 4 剩余风险

| 风险 | 评估 |
|---|---|
| 陈述与通常的 RH 不符 | 可以排除（§1） |
| 源码绕过内核 | 可以排除（§2），且有逐模块重放 |
| 单个内核实现有 bug | 六个检查器、至少四套独立实现都接受，同一 bug 同时存在的可能很小 |
| Lean 的类型论加三条公理本身不一致 | 所有检查器共用这一前提；没有已知迹象 |
| 导出工具出错 | 外部检查器共用它；Lean 自己的内核在构建和重放时不经过它，起到交叉作用 |
| 检查的不是公开的那份 | MIT 与我们取的是同一提交 `72fead1` |
| MIT 页面的说法不实 | 我们的本机构建与 `#print axioms`（§6）是独立的一份；其余检查我们没有复现 |
| 数学无人审阅 | 不影响机器结论，但没人能说明证明为何成立；作者 README 明说没有论文、没有数学家通读 |

需要注意：

- **它不是原始证明的压缩。** 作者说很多步骤换了论证（去掉了奇点消解、Vandiver 弱形式、patching、Hida 理论、局部 Langlands 等），紧凑版与可读版之间也有步骤不同。原始版本的核验结果不能转给它，它靠的是自己的核验。
- **会改变判断的事：** 有人在 Lean v4.35.0 里找到同时影响各检查器的可靠性问题；或者有人指出同样的论证能推出已知为假的命题。

## 5 规模（本仓库核对）

| | 文件 | 总行数 | 字节 | zlib 压缩后 | 最长行 | 超过 100 字符的行 | `maxHeartbeats` 设置 |
|---|---|---|---|---|---|---|---|
| 原始版本 | 175,187 | 17,549,402 | 1,030.5 MB | 226.2 MB | 5,016 | 1,935,318 | 64,937 |
| 可读版 | 803 | 477,927 | 30.1 MB | 8.1 MB | 100 | 0 | 5 |
| 紧凑版 | 794 | 113,621 | 7.4 MB | 2.6 MB | 767 | 60 | 9 |

- 行数按换行切分统计，比 `wc -l` 略多。
- 紧凑版平均每行 65 字节，与另外两版相近，只有 60 行超长；"约 7.6 万行代码"不是靠长行得到的。
- 源码短不等于证明项小：据 MIT，紧凑版的导出 5.17 GB，可读版 4.49 GB，原始版本 61.6 GB；按内核要检查的量，短版本比原始小 12–14 倍，不是 150 倍。
- 结构：`src/Lib`（573 个文件）是 Mathlib 缺少的背景（Weil 表示、Shimura 簇、adele、上同调、类域论、离散序列、p 进 Hodge 等）；`src/New`（219 个文件）是论证本身。
- 顶层在 `src/New/Main.lean`：定理 A、B、C 合成主不等式 `star_inequality`，得到素数计数误差的单侧上界 x^(8ε−1/2)，再用 Landau 引理得到 Re s > 1/2 无零点（`New.grh`），最后两条十行以内的引理用函数方程推出其余四个陈述。

## 6 本机构建（本仓库测）

- 方式：Mathlib 与其依赖用预建副本，每个包的版本都对照清单核对过、工作区干净，所以这里只编译了项目自己的模块；`lake build` 在拒绝网络访问的沙箱里运行，随后用仓库自带的 `scripts/PrintAxioms.lean` 打印五个定理的公理。
- 机器：12 核、16 GB 内存（作者建议 24 GB）。
- 结果：2026-11-26 00:13:54 UTC 开始，02:47:10 UTC 结束（约 2 小时 33 分），"Build completed successfully (9843 jobs)"，零错误；五个定理都只依赖 `propext`、`Classical.choice`、`Quot.sound`。
- 导出与哈希比对：没有可比的结果。MIT 公布的哈希来自 `lake comparator` 自己做的导出；MIT 另外单独导出的紧凑版（其 `compact-export-timeline.txt`，5,173,283,067 字节）与 comparator 的导出（5,172,274,528 字节）本来就不是同一个文件，所以不同方式做的导出不会逐字节相同。我们用 `lake env leanexport` 做的 challenge 导出是 354,906,655 字节，comparator 的是 354,827,875 字节。
- 完整证明的导出没有完成：16 GB 内存不够，15 分钟后停止，几乎没有输出（MIT 在大服务器上不到 5 分钟）。
- 所以本机没有做独立内核检查；我们自己的结果只有构建与 `#print axioms`。Mathlib 本身没有在本机重编。

[grh]: https://github.com/lsernau/grh-lean
[D16]: ../../REFERENCES.md
[D18]: ../../REFERENCES.md