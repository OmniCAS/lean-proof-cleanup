# A6 选项与性能清理（options and performance）

## 1. 一句话判断

针对构建时间和对版本的稳健性，不针对长度；最大的风险是"自动换成更强的 tactic"往往更慢，所以每处改动都要计时。

## 2. 做什么

- 清点 `set_option maxHeartbeats`、`synthInstance.*`、`backward.*` 等覆盖：`#count_heartbeats in` 测实际用量，删掉或降到实测值附近 [T5]。
- 清掉兼容性选项（`backward.isDefEq.respectTransparency` 等）与 `attribute [-instance]` 之类的权宜做法。
- 带计时闸门的 tactic 替换：只收"更短且不更慢"的（工具见 [B2](b2-tactic-golf-and-automation.md)）。

## 3. 谁在用

- 社区 `alpoge` 线：[#9]（366 处 heartbeat 覆盖）、[#71]（删 `backward.*` 选项）、Jonathan Roy 对约 8,400 处设置的清点 [z643467299]；社区仓库的 `AGENTS.md` 规定先试 `lia`/`grind` 再改写 `nlinarith`，避免 `attribute [-instance]` [#312]。
- 新 `main`：升到 v4.37.0-rc1 [#5769]。
- Mathlib：`linter.style.maxHeartbeats` 要求每处覆盖写明原因 [T3]。

## 4. 证据等级

主流在用；效果数字零散。

## 5. 作用层级

定理到大仓库。不需要理解数学。

## 6. 正确性靠什么保证

- 选项只影响搜索与 elaboration，不影响内核；能编译即可。
- 替换 tactic 时要重编并比较 heartbeats，变慢就拒。

## 7. 效果

| 数字 | 标记 |
|---|---|
| `maxHeartbeats` 设置：原始 64,937 处，可读版 5 处，紧凑版 9 处 | 他人报告（[grh-compact-reliability](../docs/grh-compact-reliability.md) §5，本仓库核对源码） |
| #66 在移植时反而加了约 2.45 万处 `synthInstance.maxHeartbeats` [#66] | 他人报告 |
| `terminalToGrind` 在 `alpoge` 线上给出的 26 条建议中 22 条更慢，最多慢 170 倍 [z643461700] | 他人报告（转述） |
| 紧凑版全局设 `maxHeartbeats 4000000`，并有 30 处 `respectTransparency false` | 本仓库核对 |

## 8. 代价与坑

- 升工具链时常常要先加覆盖才能编译通过，清理与移植方向相反，要分开验收。
- 重度自动化的证明对库版本更敏感：紧凑版靠全局放宽 heartbeats 才能编译。
- 计时有噪声，单次测量不能作为拒绝依据；用 `#count_heartbeats!` 多次取样 [T5]。

## 9. 什么时候用

删除与导入工作之后、改写之前；每次升工具链之后单独做一轮。

## 10. 未解决的问题

- 8,400 处设置里有多少是真正需要的？清点还在进行。
- heartbeat 上限与实际编译时间的关系在大仓库上没有系统数据。

[#9]: https://github.com/leanprover-community/riemann-hypothesis/pull/9
[#66]: https://github.com/leanprover-community/riemann-hypothesis/pull/66
[#71]: https://github.com/leanprover-community/riemann-hypothesis/pull/71
[#312]: https://github.com/leanprover-community/riemann-hypothesis/pull/312
[#5769]: https://github.com/leanprover-community/riemann-hypothesis/pull/5769
[T3]: ../REFERENCES.md
[T5]: ../REFERENCES.md
[z643461700]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643461700
[z643467299]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/Cleaning.20up.20the.20proof/near/643467299
