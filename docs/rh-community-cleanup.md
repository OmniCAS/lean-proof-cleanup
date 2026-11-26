# Lean RH/GRH 开发的社区清理：进展与削减量

**Summary (English).** How the community has cleaned up the November 2026 Lean development by Alpöge with Claude, whose five final statements are Mathlib's `RiemannHypothesis` and Dirichlet GRH forms. On 2026-11-25 the picture changed: `lsernau/grh-lean` (Luke Sernau with colleagues at Anthropic, and Claude) published a rewrite in two editions, readable `grh/` (about 477k lines) and compact `grh-compact/` (about 113k lines); the community repository moved its old `main` to the branch `alpoge` and replaced `main` with the readable edition, on which cleanup has restarted. Section 0 gives the versions and how each was verified; the rest of the document is the history of the `alpoge` line (by our count from Git objects: `.lean` files 174,793 → 58,735, body lines −23.3% at batch 23, the five statements unchanged, no end-to-end check). Both short editions were checked by several independent kernels on the day they appeared. The developments state RH and are reported machine-checked by third parties; the mathematics is unreviewed. The text is in Chinese.

§0 的快照是 2026-11-26 03:00 UTC（社区仓库 `main` 为 `b7642ae`，`alpoge` 为 `756a702`；MIT 短版本核验页为 02:50 UTC 版，全部检查已结束）；§1 起是 `alpoge` 线的历史，快照为 2026-11-25（当时的 `main` 为 `75e2012`，Zulip 消息到 11-25 08:00 UTC）。对象是 2026 年 11 月 Alpöge 与 Claude 发布的 Lean 4 开发：它陈述了 Mathlib 的 `RiemannHypothesis` 和 Dirichlet L 函数的 GRH 形式，第三方报告已做机器核验，数学部分尚无人审阅。社区清理在 [leanprover-community/riemann-hypothesis][repo] 进行，讨论在 Lean Zulip 的 "Riemann Hypothesis" 频道（2026-11-25 从 #general 迁入，话题改名为 "Cleaning up the proof" 等）。

**口径。** "本仓库测"是 [`../scripts/rh_repo_stats.py`](../scripts/rh_repo_stats.py) 在一份 `git clone` 上只读 Git 对象数出来的（没有构建，数据在 [`../data/`](../data/)）；"据报告"是 Zulip 或 PR 里的说法，没有独立复核。行数分三种：总行数；正文行（去掉空行、`import` 行和 `module` 行）；theorem/lemma 行（以 `theorem`/`lemma` 开头的行，与 Shore 的声明计数口径不同，只用于前后对比）。

## 0 2026-11-25 的切换（最新）

### 发生了什么

- 2026-11-25 21:26 UTC，Luke Sernau 在 Zulip 发布 [lsernau/grh-lean][grh]（与 Anthropic 的同事合作，借助 Claude）：同一组五个陈述的一次重写，分可读版 `grh/` 与紧凑版 `grh-compact/` 两个独立工程 [z643702366]。官方口径是"基于原证明的方法，很多步骤用别的论证证明" [D16]。
- 社区仓库把原来的 `main` 移到分支 `alpoge`，把 `main` 换成可读版：换上时（`47fcde5`、`9211277`）的 `src` 与 grh-lean `72fead1:grh/src` 的 Git 树哈希相同（`55fe9c6c…`，本仓库核对）。
- 新 `main` 上的清理已重新开始：批次 m1–m4（[#5631]、[#5636]、[#5645]、[#5657]）、剪枝 [#5652]、未用字段 [#5642]、升到 v4.37.0-rc1 [#5769]、challenge 文件检查 [#5615]。到 `b7642ae`（11-26 02:40 UTC），`src` 改了 445 个文件（+2,085 / −2,159 行，本仓库测）。

### 新的核心判断

1. **最大的削减不再来自逐步清理，而来自重写。** 定理 + 引理：原始 818,755 个，可读版 18,227 个，紧凑版 7,088 个；同期 `alpoge` 线到第 23 批是正文行 −23.3%、theorem/lemma 行 −30.3%（本仓库测）。逐步清理的上限约两到三倍，重写拿到了两个数量级（见 [grh-compact-vs-original](grh-compact-vs-original.md) 与 [`../methods/`](../methods/README.md)）。
2. **验证的差别来自规模。** `alpoge` 线没有人报告过端到端核验；两个短版本发布当天就被 MIT 用六个检查器检查完，`lake comparator --paranoid` 对两版都通过（紧凑版两台机器，可读版一台） [D18]。我们在断网沙箱里独立构建紧凑版通过（Mathlib 为预建副本），`#print axioms` 只有三条标准公理（[grh-compact-reliability](grh-compact-reliability.md) §6）。
3. **新数学的风险转移了。** 短版本换了多处子论证（去掉奇点消解、Vandiver 弱形式、patching、Hida、局部 Langlands 等） [z643717520]，原始版本的核验不能转给它们；它们靠自己的核验，数学同样无人审阅。
4. **社区以可读版为准。** 紧凑版难读，也有人批评它是在刷行数；可读版上清理从 A 层的机械路线重新开始（Anton Mellit 数出约 2.3 万个声明中 1,151 个未用 [z643723346]）。

### 版本与验证

规模一栏：文件为 Git 跟踪的 `.lean` 文件，行为总行数（本仓库测，`data/rh_revision_stats.csv`；两个短版本为 grh-lean 仓库里各自的目录）。验证一栏是他人报告，注明出处。

| 版本 | 仓库与提交 | 规模 | 工具链 | 验证 |
|---|---|---|---|---|
| 原始 | 社区仓库 `original` 分支 `40e56bab`；冻结镜像 [D11] | 174,793 个文件、17,374,215 行 | v4.33.1 | 完整：MIT 全部模块编译、`#print axioms`、沙箱内重建并重新导出（与公开导出逐字节相同）、175,187 个模块的 `leanchecker` 重放、nanoda、con-leche / con-ron `--compare`、Lean 默认与 paranoid 内核、`lake comparator` 全流程 [D17]；Jack McCarthy 的 comparator 运行通过陈述比对、paranoid 内核与 nanoda [z643222049] |
| grh-lean 可读版 | `lsernau/grh-lean` `grh/`，`72fead1` [D16] | 805 个文件、477,151 行 | v4.35.0 | 独立：MIT 沙箱构建 9,852 个任务零错误；`#print axioms`；803 / 803 模块重放；两机导出逐字节相同（4,485,867,644 字节）；con-leche / con-ron `--compare`；nanoda；默认与 paranoid 内核；lean4lean（2 小时 35 分，峰值 332 GB）；`lake comparator` 通过；`lake comparator --paranoid` 在较大的机器上给出 "Your solution is okay!"（4 小时 9 分 59 秒，其中 lean4lean 约 2 小时 40 分）；在较小的机器上因 lean4lean 需要约 332 GB 内存而被停止、没有结论（不是拒绝） [D18]；Riccardo Brasca 的 nanoda 接受 [z643720223] |
| 社区新 `main` | `9211277`（换上时）→ `b7642ae`（11-26 02:40 UTC） | 806 → 805 个文件；477,160 → 477,086 行 | v4.35.0 → v4.37.0-rc1 | 换上时与可读版源码相同，可读版的核验适用；之后的提交没有单独的端到端核验报告 |
| grh-lean 紧凑版 | `lsernau/grh-lean` `grh-compact/`，`72fead1` [D16] | 794 个文件、约 11.4 万行 | v4.35.0 | 独立：MIT 全部检查通过，`lake comparator --paranoid` 在两台机器上给出 "Your solution is okay!" [D18]；本仓库在断网沙箱里构建通过（9,843 个任务，零错误；Mathlib 与依赖为预建副本，只编译项目模块），`#print axioms` 只有三条标准公理；本机完整导出因内存不够没有完成，没有本机的独立内核检查 |
| `alpoge` 线（原 `main`） | 分支 `alpoge`，`756a702`（第 23 批） | 58,735 个文件、13,710,772 行（正文 11,217,763） | v4.37.0-rc1 | 只有构建：CI 分片构建（多数批次对着共享缓存增量构建）与每批的机械检查；五个陈述的文本与原始一致（本仓库测）；没有端到端核验 |
| Shore 的机械裁剪 | `james-shore/rh-proof-trimmed` [D9] | 150,632 个文件、14,252,250 行（S4，作者统计） | v4.33.1 | 作者自报：每阶段完整构建、nanoda 接受、con-leche `--compare` 通过；无第三方复核 |
| Devin Watson 的分解压缩 | 无公开仓库 | 自称 528,681 行 | — | 仅声称：结构去重、hash-consing、DAG 内联 [z643715299] |
| riemann.verifytask.cn | — | 自称压缩约 50% | — | 仅声称；有人估算折算约 8%，最多 26% [z642818785] |
| RH#120 文件合并 | PR [#120] | 自报 47,884 个文件 | — | 未通过：构建不过 [z642695795] |

---

以下是 `alpoge` 线（2026-11-20 至 11-25）的历史，写于切换之前。

## `alpoge` 线当时的核心判断（截至 2026-11-25 上午）

1. **（已过时，见 §0）当时最大的削减在社区主仓库 `main` 上，不在某个 fork。** 本仓库测：从原始归档 `40e56bab` 到 HEAD `75e2012`，`.lean` 文件 174,793 → 59,254（−66.1%），正文行 14,621,937 → 11,577,635（−20.8%），theorem/lemma 行 813,194 → 583,779（−28.2%）。总行数只少 11.6%（17,374,215 → 15,351,223），因为 import 行从 909,822 涨到 2,027,398（`import Mathlib` 被展开成逐个模块的导入）。五个最终定理的陈述文本与原始归档逐字一致。
2. **文件数的削减主要是合并，不是删除。** #324 一次把 147,945 个文件变成 61,935 个：先删 22,054 个薄包装模块，再沿 import 图把小模块合并成大文件（"clump"），目的是降低每个文件的导入开销（约占编译 CPU 的一半）。真正删掉证明内容的，是 #66 的不可达裁剪、#221 和后续批次的复用与去重、#295 的同陈述去重、#243 的 linter 清理。
3. **纯死代码基本已经删完，下一步要靠去重、换 Mathlib 和重写。** Shore 用内核证明项算出原始版本的依赖闭包：1,061,400 个项目声明中有 804,912 个被用到（75.8%），被用声明内部的源码 10,737,728 行（61.8%）。main 的 theorem/lemma 行已比原始少 28.2%，超过了"未用声明"所占的 24.2%；Shore 估计 main 上只剩约 1.5 万个未用声明。再往下需要去重、换成 Mathlib 引理、删掉没被证明的文献陈述（#318），或者换数学路线。
4. **验证是最弱的一环。** 主干的保护是：CI 禁止改 Challenge 与 comparator 文件、批次检查不新增 `sorry`/`admit`/`axiom`、构建全绿（多数是对着缓存的增量构建）。完整的 comparator 和内核重放只在**原始版本**上做过；清理后的 `main` 没有报告过端到端的 comparator 或内核重放。所以 main 上的削减目前只能算"构建通过、陈述文本未变"，不算"独立复核过"。
5. **进度很快，上限未知。** 据报告，过去 24 小时每分钟超过 1 个 PR，Kim Morrison 用带 AI 智能体的批处理合并，每批几十到一百多个 PR。有人估计每天删掉原始规模的约 5%；对最终能缩到多少，有人猜 80%–90%，Mario Carneiro 猜 98%–99.5%，但两者都只是猜测。当前 main 的依赖闭包没人量过。

## 1. `alpoge` 线在关键提交上的规模（本仓库测）

| 提交 | 说明 | `.lean` 文件 | 总行 | 正文行 | import 行 | theorem/lemma 行 | 工具链 |
|---|---|---|---|---|---|---|---|
| `40e56bab` | 原始归档 | 174,793 | 17,374,215 | 14,621,937 | 909,822 | 813,194 | v4.33.1 |
| `7cce738` | 2026-11-22 快照（#93） | 163,900 | 16,563,088 | 13,946,704 | 842,923 | 780,139 | v4.33.1 |
| `14f383e` | #66：升 4.36、转 module system、删不可达文件 | 149,104 | 15,179,048 | 12,306,612 | 841,881 | 663,842 | v4.36.0 |
| `ecc801f^` | #185 升 4.37 rc1（展开 `import Mathlib`）与 #221 之后 | 147,945 | 20,569,125 | 12,047,636 | 6,428,170 | 659,933 | v4.37.0-rc1 |
| `ecc801f` | #324：删薄包装、按 import 图合并模块 | 61,935 | 17,249,054 | 12,431,988 | 2,950,339 | 637,897 | v4.37.0-rc1 |
| `75e2012` | 当时的 HEAD，批次 b1–b15 之后 | 59,254 | 15,351,223 | 11,577,635 | 2,027,398 | 583,779 | v4.37.0-rc1 |
| `756a702` | 第 23 批（分支 `alpoge` 的当前头） | 58,735 | 13,710,772 | 11,217,763 | 817,983 | 566,775 | v4.37.0-rc1 |


## 2. 各项清理工作

"作者自报"指只有作者本人跑过的检查；"他人复核"注明是谁。

| 工作 | 方法 | 数字 | 陈述与验证 | 状态 |
|---|---|---|---|---|
| [#66][pr66]（Vasily Ilin） | 升 4.36，全部转 module system，删不可达文件 | 正文行 13.95M → 12.31M（本仓库测）；删 15,068 个文件；据 PR 说明，同时加了约 2.45 万处 `synthInstance.maxHeartbeats` 覆盖 | 作者用增量驱动复用旧模块，未从零构建 | 已合并 |
| [#134][pr134] / [#185][pr185]（Vasily Ilin） | 精简 heartbeats 与导入，升 4.37 rc1 | 据报告编译时间 −22%~25% [z642699975] [z642715788] | 构建通过 | 已合并 |
| [#221][pr221]（Serdnad，合入多人 PR） | 用 Mathlib 引理或项目内已有证明替换冗余证明，删不可达 tactic 和无用脚手架 | 净 −221,158 行（本仓库测，含 import 行） | 构建通过 | 已合并 |
| [#324][pr324]（Kim Morrison） | 脚本删 22,054 个薄包装模块，再沿 import 图合并小模块 | 文件 147,945 → 61,935（−58%，本仓库测）；PR 写 `src/` 148,230 → 62,159 | 全由脚本生成；早期部分构建约 0.7% 模块合并后失败，已列入排除清单 | 已合并 |
| [#295][pr295]（James Shore） | 同陈述的定理、同类型同值的定义只留一份，其余删掉或改成 `alias`；4.36 和 4.37 都判定类型相等才算重复 | 约 1.65 万~1.7 万处删除 [z642796623] [z643005632] | 作者自报：完整构建 + nanoda + con-leche；移植到合并后的树上 60,932/60,932 个模块编译 | 已合并 |
| [#243][pr243]（James Shore） | 删 linter 标为无用的语法（未用 simp 参数、不可达分支、无效 tactic） | 约 10.7 万~11.2 万行删除，"unused" 类警告 −94% [z642796623] [z643005632] | 作者自报：完整构建 + nanoda + con-leche | 并入 #438 |
| [#378][pr378] → [#438][pr438]（Vasily Ilin、Andres Gutierrez） | 收窄导入、删死模块；合入 #243、#55 的删除部分等 | #378 编译 −10% [z642956589]；#438 净 −183,684 行（本仓库测） | Andres 自报干净构建 | 已合并 |
| 批次 b1–b15（Kim Morrison） | 把所有能干净合并的小 PR 串起来一次构建；冲突只做机械解决 | 例：b6 合 68 个 PR、净 −377,039 行；b15 合 139 个 PR、净 −172,395 行（本仓库测） | 每批检查：import 可解析、无删除模块仍被导入、无新增 `sorry`/`admit`/`axiom`、不改 Challenge/comparator/`Main.lean` | 已合并 |
| [#318][pr318]（David Loeffler） | 删 `GlobalTheory.Published` 里从未被证明也未被使用的文献陈述（如 `LocalLanglandsExists`） | 1,370 个声明；完整的 LLC 陈述被约 6,000 个文件导入 [z643015203] [z642804360] | — | 排队中 |
| [#55][pr55] 重跑（James Shore） | 按内核依赖删五个定理用不到的声明 | 在当时的 main 上约 1.5 万个，若在 #378 之后约 1.8 万个 [z643026403] | — | 提议 |
| #1595（Andres Gutierrez） | 删重复定义 | 约 −15 万行 [z643396699] | — | 提议 |
| [RH#120][pr120]（Rohan Arun） | 合并小文件 | 自报 47,884 个文件（−67.9%）、512 vCPU 上约 50 分钟构建 | Vasily 指出它构建不过、CI 被跳过 [z642695795] [z642696252]；Snir 指出行数几乎没变 [z642820019] | 未合并；启发了 #324 |
| Martin Hanzlowsky 的脚本 | 把 `import Mathlib.*` 换成预制的 prelude 模块 | 约 −200 万行（几乎全是 import 行）[z643065436] | Thomas Murrills 问 import 闭包是否真的变了 [z643077118] | 只有脚本 |

## 3. 主仓库之外的工作

| 工作 | 内容 | 数字与验证 |
|---|---|---|
| [rh-proof-dependencies][shore-deps]（James Shore） | 从 Sutherland 的内核导出算五个定理的依赖闭包，CC0 数据集 | 见 §4；三套独立构建的 `.olean` 得到同一闭包（1,484,729 个常量） |
| [rh-proof-trimmed][shore-trim]（James Shore） | 只用机械步骤的分阶段裁剪，每阶段有回执 | 以 `7da4577e` 为基：S1 删未用声明 164,463 → 150,632 个文件、16,588,671 → 14,473,033 行、1,024,669 → 858,404 个声明；S2 删 linter 标记的语法；S4 删多余 import 到 14,252,250 行。每阶段 Lean 4.33.1 完整构建 + nanoda 接受导出 + con-leche `--compare` 对照原始 challenge（作者自报） |
| [riemann-explorer][explorer]（Bin） | 从 `.olean` 建 `riemannHypothesis` 的依赖图，沿支配树切分 | 提交 `6c68212` 上 727,065 个声明；是否包含 Mathlib 未说明，无人复核 [z643337613] |
| [riemann-hypothesis-original][original]（Hang Lu Su） | 原始源码的冻结镜像，附预建缓存 | 保存原状，不做清理 |
| Jack McCarthy 的 comparator 运行（`original` 分支） | 原始版本的端到端核验 | 构建 8 h 17 min（183,893 个任务）；陈述比对与公理检查 58 min 通过；Lean paranoid 内核 68 h 53 min 接受；nanoda 1 h 33 min 接受；默认内核截至 11-24 运行了 11 h 45 min 仍未结束 [z643222049] |
| riemann.verifytask.cn（中文社区） | 子任务级 token 压缩 | 自称约 50%；Snir 认为折算下来约 8%，最多 26% [z642818785] [z642818437] |
| Tau Ceti 路线图 | 不改这个仓库，把已知数学重新形式化成通用库 | 已从 RH 所需而 Mathlib 没有的内容新开 41 个路线图 [z642819551]；进行中 [z643280191] |
| rh-shrink.github.io、Michael Righi 的字段活性分析等 | 进度跟踪；从 lean4export 导出算死字段 | 进行中 [z642702787] [z642699511] |

## 4. 依赖闭包：删死代码的下限

- **唯一完整的测量在原始版本上**（Shore，[rh-proof-dependencies][shore-deps] v0.2.1）。"被用"指被五个定理的内核证明项直接或间接引用：
  - 项目声明 804,912 / 1,061,400 被用（75.8%）；含被用声明的文件 146,287 / 175,187（83.5%）；被用声明内部的源码 10,737,728 / 17,374,215 行（61.8%）。
  - 未用声明内部 2,692,541 行（15.5%）；声明之外的行 3,922,942 行（22.6%，含空行、import、namespace、open 等）。
  - 与另一被用定理陈述相同的定理最多再省 606,362 行（5.6%）；删掉从未用到的假设最多再省 0.1%–0.3%。
  - 五个定理几乎共享一切：每一个单独就用了 804,889 个被用声明中的至少这么多。
  - 注意：编译时还需要一些不在证明项里的东西（notation、tactic、simp 引理、实例），所以这是声明层面的下限，不是"能删到这么多还能编译"的保证。
- **当前 main 的闭包没人量过。** 只有 riemann-explorer 给出 `6c68212` 上 727,065 个声明，口径不明；Shore 估计 main 上还剩约 1.5 万个未用声明 [z643026403]，并说 #66、#134 已删掉约 85% 的未用声明 [z643005632]。
- **粗略对照**（口径不同，只看量级）：main 的正文行 11.58M 中，声明之外的行原本约 126 万（namespace/section/end、open、variable 等），由此估计 main 上声明内部的行已低于原始闭包的 10.74M。也就是说，单靠删不可达代码能拿到的部分已基本拿完，后面靠去重、换 Mathlib 和缩短证明。

## 5. 构建与验证现状

- **构建**：#185 之后的冷构建在 192 核 Xeon 上约 103 CPU 小时，约一半花在加载 import，72% 的 CPU 花在 5 秒以内的小模块上 [z642808607]；Anton Mellit 在 24 线程上构建 rh#440 用了 6 h 11 min，内存未测，估计低于 192 GB [z643193268]。核数每翻一倍约快 1.6 倍 [z643369073]。原始版本在 48 核、503 GB 内存的机器上预计 7–10 小时（[verification/NOTES.md][notes]）。
- **CI**：大机器（FRO 付费的 AWS 加捐赠机器）分片构建，小机器做限时快速检查；批次对着共享缓存增量构建，最快 55 分钟合并一批 [z642719038] [z643352115]。`challenge-files.yml` 禁止任何 PR 改 Challenge 与 comparator 配置；`checks.yml` 只对一个 formal-conjectures 的小型对照做 `lake comparator`，不对完整的 `Main` 做。
- **事故**：一个缓存的 `.olean` 在编译器 panic 的情况下产出却没被发现，已由 #589 修复，之后要求构建时设置 `LEAN_ABORT_ON_PANIC=1` [z643107722]。有人问共享缓存能否被投毒 [z643465849]。
- **本仓库核对的**：五个最终定理在 `src/Main.lean` 里的陈述，与 `40e56bab` 逐字一致（去空白后比较），也与 HEAD 的 `src/Challenge.lean` 一致；HEAD 的 `comparator.json` 列出这五个定理，允许三条标准公理，外部内核为 Lean paranoid 和 nanoda。本仓库没有构建，也没有跑 comparator。

## 6. 方针与争议（影响还能删多少）

- **范围**：保持原证明的基本结构，换数学路线的大改另立项目（如基于 Masullo 的路线）[z642780503] [z643474280]。`original` 分支和冻结镜像保留原状。
- **先性能还是先可读**：Thomas Murrills 主张先性能、局部丑陋的改动暂时可接受；David Loeffler 反对把 token 或 heartbeat 当目标（"gzip"的比喻）；Jack McCarthy 不允许 `-instance` 之类的权宜做法 [z643161746] [z643362042] [z643170349]。
- **为什么要清理**：Loeffler 认为清理能显出真正用到了哪些深层结果；Mario Carneiro 想要的是约 200 页的人类可读证明，并预测还能缩掉 98%–99.5%；Buzzard、Michael Stoll 主张先写出非形式化证明再重新形式化，这正是 Tau Ceti 在做的 [z642804360] [z642816120] [z642851744] [z643185395]。
- **文档 PR 暂停**：AI 生成的文献引用被发现有错，文档类 PR 一律延后 [z643418033] [z643424144]。

## 7. 还能做什么

按"便宜且安全"在前排序：

1. **补上端到端验证**：对当前 main 跑一次完整的 `lake comparator`（或至少把 Challenge 导出冻结后判），否则所有削减都停留在"构建通过"。comparator 是单线程的 [z643463691]，原始版本的 paranoid 内核跑了约 69 小时，需要专门安排机器。
2. **在当前 main 上重算依赖闭包**，给出新的下限，再重跑 #55 删掉剩下的约 1.5 万个未用声明。
3. **合入 #318**，删掉没被证明也没被使用的文献陈述（1,370 个声明，且它们拖着约 6,000 个文件的导入）。
4. **继续去重和换 Mathlib**：11-22 时 Tanner Clary 在 Sutherland 的导出上找到约 24.1 万个与先前定理类型相同的定理，其中约 6.6 万个已在 Mathlib/Core 中 [z642652193]；#295 只处理了"陈述完全相同"的一类。
5. **降导入成本**：import 约占一半 CPU；module system 下继续收窄 `public import`，或用 prelude 模块。
6. **清理约 8,400 处 heartbeat/深度设置** [z643467299]；据 Jonathan Roy 转述，`terminalToGrind` 的 26 条建议里 22 条更慢（最多慢 170 倍），自动替换要以计时为准 [z643461700]。
7. **重写**：缩到原规模的几个百分点，需要人类可读的证明和新的形式化（Tau Ceti 路线），已超出"清理"的范围。

## 8. 未解决问题

1. 当前 main 的依赖闭包（声明、文件、行）是多少？没人量过。
2. 清理后的 main 能否通过完整的 comparator 和多个外部内核？没人报告过。
3. 哪些数学成分已经被删掉或替换？Jack 说目前没有跟踪系统，只凭人工审阅判断没有大块变化 [z643280942]。
4. 文件合并（#324）对增量重编和内存的长期影响如何？只有构建时间的零散报告。
5. 共享缓存的完整性怎么保证（panic 事件、投毒风险）？
6. 以哪个指标为准？行数被 import 展开严重干扰；建议以正文行、声明数和冷构建 CPU 时间为主。

[shore-deps]: https://github.com/james-shore/rh-proof-dependencies
[shore-trim]: https://github.com/james-shore/rh-proof-trimmed
[explorer]: https://bil022.github.io/riemann-explorer/
[original]: https://github.com/homeowmorphism/riemann-hypothesis-original
[pr55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[pr66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[pr120]: https://github.com/leanprover-community/riemann-hypothesis/pull/120
[pr134]: https://github.com/leanprover-community/riemann-hypothesis/pull/134
[pr185]: https://github.com/leanprover-community/riemann-hypothesis/pull/185
[pr221]: https://github.com/leanprover-community/riemann-hypothesis/pull/221
[pr243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[pr295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[pr318]: https://github.com/leanprover-community/riemann-hypothesis/pull/318
[pr324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[pr378]: https://github.com/leanprover-community/riemann-hypothesis/pull/378
[pr438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[z642695795]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642695795
[z642696252]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642696252
[z642699511]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699511
[z642699975]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642699975
[z642702787]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642702787
[z642715788]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642715788
[z642719038]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642719038
[z642780503]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642780503
[z642796623]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642796623
[z642804360]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642804360
[z642808607]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642808607
[z642816120]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642816120
[z642818437]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642818437
[z642818785]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642818785
[z642820019]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642820019
[z642851744]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/642851744
[z642956589]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642956589
[z643005632]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643005632
[z643015203]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643015203
[z643026403]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643026403
[z643065436]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643065436
[z643077118]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643077118
[z643107722]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643107722
[z643161746]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643161746
[z643170349]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643170349
[z643185395]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Why.20clean.20up.20the.20proof/near/643185395
[z643193268]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643193268
[z643222049]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/RH.3A.20conserving.20original.20proof/near/643222049
[z643280191]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643280191
[z643280942]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643280942
[z643337613]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Explorer.20for.20the.20formalization/near/643337613
[z643352115]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643352115
[z643362042]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643362042
[z643369073]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643369073
[z643396699]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643396699
[z643418033]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643418033
[z643424144]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643424144
[z643461700]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643461700
[z643463691]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643463691
[z643465849]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643465849
[z643467299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643467299
[z643474280]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643474280
[z642819551]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642819551
[repo]: https://github.com/leanprover-community/riemann-hypothesis
[notes]: https://github.com/leanprover-community/riemann-hypothesis/blob/alpoge/verification/NOTES.md
[z642652193]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/642652193
[grh]: https://github.com/lsernau/grh-lean
[#55]: https://github.com/leanprover-community/riemann-hypothesis/pull/55
[#66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[#120]: https://github.com/leanprover-community/riemann-hypothesis/pull/120
[#134]: https://github.com/leanprover-community/riemann-hypothesis/pull/134
[#185]: https://github.com/leanprover-community/riemann-hypothesis/pull/185
[#221]: https://github.com/leanprover-community/riemann-hypothesis/pull/221
[#243]: https://github.com/leanprover-community/riemann-hypothesis/pull/243
[#295]: https://github.com/leanprover-community/riemann-hypothesis/pull/295
[#318]: https://github.com/leanprover-community/riemann-hypothesis/pull/318
[#324]: https://github.com/leanprover-community/riemann-hypothesis/pull/324
[#378]: https://github.com/leanprover-community/riemann-hypothesis/pull/378
[#438]: https://github.com/leanprover-community/riemann-hypothesis/pull/438
[#5615]: https://github.com/leanprover-community/riemann-hypothesis/pull/5615
[#5631]: https://github.com/leanprover-community/riemann-hypothesis/pull/5631
[#5636]: https://github.com/leanprover-community/riemann-hypothesis/pull/5636
[#5642]: https://github.com/leanprover-community/riemann-hypothesis/pull/5642
[#5645]: https://github.com/leanprover-community/riemann-hypothesis/pull/5645
[#5652]: https://github.com/leanprover-community/riemann-hypothesis/pull/5652
[#5657]: https://github.com/leanprover-community/riemann-hypothesis/pull/5657
[#5769]: https://github.com/leanprover-community/riemann-hypothesis/pull/5769
[D9]: ../REFERENCES.md
[D11]: ../REFERENCES.md
[D16]: ../REFERENCES.md
[D17]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[z643702366]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643702366
[z643715299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643715299
[z643717520]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643717520
[z643720223]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643720223
[z643723346]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643723346
