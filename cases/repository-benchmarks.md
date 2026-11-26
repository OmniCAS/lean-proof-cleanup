# 案例：小仓库与中型仓库 × 仓库级基准

**Summary (English).** Repository-scale evidence outside the RH case: LeanLean (64 real Lean repositories of up to 174k lines, 12-hour agent runs, best model about 48% compression, mostly from restructuring dependencies), Leanify (proof-term compression of model-written proof collections, 94–99%, with reusable lemmas appearing in later stages) and Lean Refactor (more than 20% on research repositories, compile time down by up to 60%). Both LeanLean and Leanify are ICLR 2027 submissions read from abstracts only. The text is in Chinese.

## 判断

到了仓库规模，最大的收益不在证明写法，而在依赖结构：让某些声明不再被需要、合并重复、换成库引理。这与精心维护的库正好相反：那里结构已经被人整理过，收益很小。仓库级的公开证据还很少，而且大多只有摘要。

## 证据（他人报告）

| 工作 | 规模 × 来源 | 结果 | 阅读程度 |
|---|---|---|---|
| LeanLean [P30] | 64 个真实 Lean 仓库，最多 17.4 万行；来源混合 | 12 小时内最强模型平均压缩分 48.3%，小模型不到 25%；大头来自重组依赖，让原本用到的声明变得不再需要；只有最强模型在语法层面有明显收益 | 摘要 |
| Leanify [P29] | 两个模型写的证明集合（一个下界结果、一组反例） | 按证明项大小压缩 94.2% 与最高 99.2%；压缩越往后，被判为非平凡的可复用引理越多；把更多相关结果放在一起压缩，引理复用更广 | 摘要 |
| Lean Refactor [P11] | 研究仓库 | token 压缩 20% 以上，编译时间最多 −60%；长度与编译时间只是弱相关 | 摘要与正文片段 |
| Proof-Refactor [P28] | 模型生成的 PutnamBench 与 Putnam 2025 证明 | 以抽辅助声明为手段，LLM 评审的结构与可读性分数提高；不以长度为目标 | 摘要 |

## 本仓库测的对照：人写研究仓库的结构指标

三个公开的人写研究仓库（FLT、Carleson、PrimeNumberTheoremAnd）的指标见 [profiles](profiles.md)：每个定理 15.6–17.5 行，只有一个声明的文件 7%–19%，命名 `Prop` 定义每千行代码 0.3–0.6 个（模型生成的 RH 原始版本是 45% 与 6.0 个）。它们没有成片的陈述包装层，机械路线可删的东西应当少得多（估计；没有实测删除量）。

## 适用的路线

- 先 [E5](../methods/e5-dependency-analysis.md) 量闭包、[A1](../methods/a1-reachability-pruning.md)、[A2](../methods/a2-statement-dedup.md)、[B1](../methods/b1-library-replacement.md)。
- 依赖重组（LeanLean 的大头）对应 [C1](../methods/c1-unroll-simplify-reroll.md)–[C3](../methods/c3-unwrap-statement-layers.md)，需要理解证明。
- 小仓库每批都能全量重编，闸门用 [E2](../methods/e2-verification-gate.md) 的完整版本。

## 缺口

- LeanLean 与 Leanify 的评测协议（如何判定主定理仍然有效、压缩分怎么算）没读到全文。
- 没有"人写研究仓库 × 机械路线"的公开实测：A 层在这类仓库上能删多少，目前只有本仓库的结构指标作间接证据。

[P11]: ../REFERENCES.md
[P28]: ../REFERENCES.md
[P29]: ../REFERENCES.md
[P30]: ../REFERENCES.md
