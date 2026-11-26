# 待解决问题

**Summary (English).** Open problems in cleaning up Lean proofs, each with our suggested answer where we have one: trusted definitions, keep lists, the module system, comparator usage, hotspots, tooling gaps, metrics, parallel development, and the open questions of the Lean RH cleanup. The text is in Chinese.

每条先写问题，再写建议的答案；没有答案的写明缺什么。

## 一般仓库

1. **可信定义（Challenge 导入的定义目录）能不能清理？** 建议不动。它是陈述的一部分，清理只碰证明。确实要换某个定义（比如换成 Mathlib 的）时，单独做"改陈述"的变更：写新旧定义的等价引理、跑独立的数值或性质测试、人审。
2. **保留根是否完整？** 保留根取 comparator 的 `theorem_names`、文档与网站引用的声明、Challenge 闭包。可达性工具第一版就应把"删除候选里在文档文本中出现的名字"列出来交叉检查，未登记的先补登记再裁剪。
3. **小仓库要不要迁 module system？** 不急：每批全量构建的成本可以接受。做大仓库时再迁，先在一个子目录上试，测只改证明时下游重编是否消失（手册说会消失）。
4. **comparator 怎么用才能防住"可信定义被一起改"？** 清理前用 `leanexport` 导出一次 Challenge 并冻结，之后用 `lake comparator --challenge-from-export` 判；发布前在 Linux 上跑带 `bwrap` 沙箱和 `--paranoid` 的版本。
5. **构建时间花在哪？** 先量再改：每模块耗时（计时的 `lake build` 或按模块的构建后端）加每声明 heartbeats。高 heartbeat 覆盖和大量 `decide` 往往集中在少数计算证书类文件里。
6. **Mathlib TacticAnalysis 够不够用？** 先用 `tryAtEachStep.fraction` 抽样跑一遍，量时间和命中率；够用就不必移植 LeanPolish。注意它只报告、不改写，写回要另外的工具（Skimmer 或自写），而且要以计时为准：RH 主干上 `terminalToGrind` 的 26 条建议有 22 条更慢。
7. **托管的 AXLE 用不用？** 不用于私有代码。它的 `simplify_theorems` 默认三项（删未用 tactic、未用 `have`、未用变量改 `_`）已被 `unusedTactic`、`unusedHavesSuffices`、`unusedVariables` 加 Mathlib 的修复脚本覆盖。
8. **验收指标怎么定？** 主指标：冷构建 CPU 时间、声明数、正文行；次要：token 数；可读性只对被引用的证明人工抽查。任何一批让构建变慢就拒，哪怕更短。
9. **怎样和正在进行的开发并行？** 清理在独立 worktree 或分支里做，小批 PR，每批不超过一个目录，合并前对着当前主干重放闸门。
10. **缺什么工具？** 仓库级的未用声明工具（Lean 核心与 Mathlib 都没有）、规范化类型的去重索引、Try-this 的批量写回与计时筛选、下游锥体的增量验证调度。

## Lean RH 开发

1. **当前 `main` 的依赖闭包（声明、文件、行）是多少？** 没人量过。只有原始版本的闭包（James Shore：1,061,400 个声明中 804,912 个被用）和一个口径不明的 727,065（riemann-explorer，提交 `6c68212`）。
2. **清理后的 `main` 能否通过完整的 comparator 和多个外部内核？** 没人报告过；完整运行只在原始版本上做过。comparator 单线程，原始版本的 paranoid 内核跑了约 69 小时，需要专门安排机器。
3. **哪些数学成分已经被删掉或替换？** 目前没有跟踪系统，只凭维护者人工审阅判断没有大块变化。
4. **合并文件（#324）对增量重编和内存的长期影响如何？** 只有构建时间的零散报告。
5. **共享缓存的完整性怎么保证？** 有过编译器 panic 后仍产出缓存 `.olean` 的事故，也有人提出投毒风险；现在要求构建时设置 `LEAN_ABORT_ON_PANIC=1`。
6. **以哪个指标为准？** 总行数被 import 展开严重干扰（#185 多出约 560 万行），文件数被合并干扰；建议以正文行、声明数、闭包大小和冷构建 CPU 时间为主。
7. **最终能缩到多少？** 已部分回答：grh-lean 在同一组陈述上把命题个数缩小了两个数量级（可读版 18,227 个定理与引理，紧凑版 7,088 个，原始 818,755 个），但那是换了多处论证的重写，不是清理。逐步清理的上限仍估计为两到三倍。
8. **新 `main`（可读版）上的清理能走多远？** 起点约 2.3 万个声明里有 1,151 个未用；批次 m1–m4 与升级已开始。可读版是为人读写的，机械清理不应以行数为目标。
9. **新 `main` 之后的提交有没有端到端核验？** 换上时与可读版源码相同，可读版的核验适用；之后的 445 个文件改动没有单独的核验报告。
10. **可读版的 `lake comparator --paranoid` 单一流程会不会完成？** 截至 MIT 页 02:13 UTC 版，一台已过 lean4lean 阶段、仍在收尾；lean4lean 在这一版上需要约 332 GB 内存。

## 文献与基准

1. **LeanLean、Leanify 的评测协议是什么？** 两篇都是 ICLR 2027 在审投稿，OpenReview 的全文需要人机验证，没读到；它们如何判定"主定理仍然有效"、压缩分怎么算，读到后再对照分层方案的闸门。
2. **仓库级清理有没有公开数据？** 截至 2026-11-25 没找到 LeanLean、Leanify 的数据发布；RH 开发的完整历史与 Shore 的依赖闭包数据是目前最好的公开素材。
3. **grh-lean 的方法能否复现？** 作者只说了三点（展开再卷回去、一部分新论证、先压后展）。哪些步骤可以工具化，见 [`../methods/`](../methods/README.md) 的 C、D 层。
4. **LLM 抽出的引理有没有被复用？** 需要按复用次数验收（*Library Learning Doesn't* 的教训），目前的压缩论文大多只报长度。
