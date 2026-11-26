# E2 验证闸门（verification gate）

## 1. 一句话判断

所有路线共用的一道门，也是 RH 两条清理线差别最大的地方：逐步清理的 `alpoge` 线从未做过端到端核验，而两个短版本发布当天就被多个独立内核检查完，因为它们小到可以重建。

## 2. 做什么

| 层次 | 内容 |
|---|---|
| 冻结裁判 | Challenge 文件、comparator 配置、导出目标不许任何 PR 改；清理前导出一次 Challenge，之后对着冻结导出判（`lake comparator --challenge-from-export`） |
| 陈述与公理 | comparator：Solution 里每个目标定理的陈述与 Challenge 相同、公理不超出允许集；`#print axioms` |
| 内核 | Lean 默认内核与 paranoid 内核；外部内核 nanoda、lean4lean、con-leche、con-ron；`leanchecker` 逐模块重放 |
| 可复现 | 两台机器分别构建并导出，比对导出哈希 |
| 构建完整性 | `LEAN_ABORT_ON_PANIC=1`；共享缓存的来源与哈希 |

## 3. 谁在用

- MIT（Andrew Sutherland）对原始版本 [D17] 和两个短版本 [D18] 做了上表的全部检查；Jack McCarthy 在另一台机器上对原始版本跑了 comparator [z643222049]。
- 社区仓库：`challenge-files.yml` 冻结 challenge 文件 [C3]；`comparator.json` 列外部内核。
- 工具：Lean v4.35 内置的 `lake comparator`、`lake check` [T1]；外部内核 [T12]。
- 事故：缓存里的一个 `.olean` 在编译器 panic 的情况下产出却没被发现，之后要求构建时设置 `LEAN_ABORT_ON_PANIC=1` [z643107722]。

## 4. 证据等级

主流在用（工具与 MIT 的公开记录）。

## 5. 作用层级

全部层级。

## 6. 正确性靠什么保证

闸门本身就是保证；它的可信度来自"多个独立实现都接受"。共同前提是 Lean 的类型论与三条标准公理、以及导出工具。

## 7. 效果

| 版本 | 端到端核验（MIT 页面与 Zulip） | 标记 |
|---|---|---|
| 原始 | 构建、`#print axioms`、逐模块重放、跨机器导出比对、nanoda、con-leche/con-ron `--compare`、Lean 默认与 paranoid 内核、`lake comparator` 全流程都通过 | 他人报告 |
| `alpoge` 线 | 只有 CI 构建与每批的机械检查；没有报告过端到端核验 | 他人报告的缺失 |
| 可读版（= 新 `main` 起点） | 构建、axioms、803/803 重放、导出比对、全部外部内核、`lake comparator` 通过；单一流程的 `--paranoid` 仍在跑 | 他人报告（02:13 UTC 版） |
| 紧凑版 | 上述全部通过，`lake comparator --paranoid` 在两台机器上通过 | 他人报告（同上） |

成本参照：原始版本的 paranoid 内核跑了 68 小时 53 分 [z643222049]；可读版的 lean4lean 用了 2 小时 35 分、峰值 332 GB 内存 [D18]。

## 8. 代价与坑

- 规模决定能否核验：comparator 是单线程的 [z643463691]，原始规模上一次完整检查以天计。
- 内存：lean4lean 在可读版上需要 332 GB，作者自己的机器在 125 GB 处耗尽 [z643710501]。
- "陈述文本相同"不等于"陈述用到的定义相同"：要用冻结的 Challenge 导出比对。

## 9. 什么时候用

任何路线之前冻结，每批跑机械检查，每个发布点跑完整核验。

## 10. 未解决的问题

- 新 `main` 的后续提交（批次 m1–m4、升 4.37）还没有单独的端到端核验报告。

[C3]: ../REFERENCES.md
[D17]: ../REFERENCES.md
[D18]: ../REFERENCES.md
[T1]: ../REFERENCES.md
[T12]: ../REFERENCES.md
[z643107722]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643107722
[z643222049]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/RH.3A.20conserving.20original.20proof/near/643222049
[z643463691]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643463691
[z643710501]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643710501
