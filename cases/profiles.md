# 结构指标：不同来源与规模的 Lean 仓库

**Summary (English).** Source-level indicators for seven public Lean trees of different provenance and size, computed by us with `scripts/profile_lean_trees.py` (nothing built): Mathlib at a pinned commit, three human-written research repositories (FLT, Carleson, PrimeNumberTheoremAnd), the original model-generated RH development, and the two editions of its rewrite. The indicators that separate a large model-generated development from the rest are the share of single-declaration files, declarations per file, named-`Prop` definitions per thousand lines, comment share and import share; option overrides and repeated short names do not separate them. The text is in Chinese.

数据：[`../data/tree_profiles.csv`](../data/tree_profiles.csv)、[`../data/tree_profiles.json`](../data/tree_profiles.json)；口径见 [`../data/README.md`](../data/README.md)。依赖闭包要从构建产物算，不在这张表里（见 [E5](../methods/e5-dependency-analysis.md)）。

## 树与版本

| 标签 | 来源 | 规模 | 仓库与提交 | 统计的目录 |
|---|---|---|---|---|
| mathlib | 精心维护的库 | 大（134 万行代码） | [leanprover-community/mathlib4](https://github.com/leanprover-community/mathlib4) `56a00585`（2026-10-13） | `Mathlib/` |
| flt | 人写的研究仓库（以人写为主，未逐提交核实） | 小 | [ImperialCollegeLondon/FLT](https://github.com/ImperialCollegeLondon/FLT) `01980581` | `FLT/` |
| carleson | 人写的研究仓库（同上） | 小 | [fpvandoorn/carleson](https://github.com/fpvandoorn/carleson) `f7487cc9` | `Carleson/` |
| pnt | 人写的研究仓库（同上） | 小到中 | [AlexKontorovich/PrimeNumberTheoremAnd](https://github.com/AlexKontorovich/PrimeNumberTheoremAnd) `e9906138` | `PrimeNumberTheoremAnd/` |
| original | 模型生成的大型开发 | 大（1,330 万行代码） | Lean RH 原始归档（社区仓库 `original` 分支 `40e56bab`，另含 394 个未进 Git 的文件） | `src/` |
| readable | 在上一行的骨架上重写（为阅读展开） | 中 | [lsernau/grh-lean](https://github.com/lsernau/grh-lean) `72fead1` | `grh/src/` |
| compact | 同一次重写的最短版本 | 小 | 同上 | `grh-compact/src/` |

## 指标

"代码行"去掉注释、空行、导入与 `namespace`/`open`/`section`/`variable`/`set_option` 等脚手架行；"每千行"都按代码行算。

| 指标 | mathlib | flt | carleson | pnt | original | readable | compact |
|---|---|---|---|---|---|---|---|
| 文件 | 8,624 | 260 | 124 | 233 | 175,187 | 803 | 794 |
| 代码行 | 1,341,536 | 36,067 | 39,396 | 142,434 | 13,295,716 | 283,663 | 69,090 |
| 定理 + 引理 | 190,303 | 2,240 | 2,607 | 8,293 | 818,755 | 18,227 | 7,088 |
| 每个定理的平均行数 | 7.5 | 15.6 | 16.8 | 17.5 | 16.7 | 21.0 | 11.1 |
| 每个文件的声明数 | 30.0 | 14.3 | 24.9 | 38.9 | 6.1 | 29.7 | 13.8 |
| 只有一个声明的文件 | 3.7% | 18.5% | 7.3% | 9.4% | **45.0%** | 0.6% | 9.7% |
| 导入行占全部行 | 1.0% | 2.0% | 0.6% | 0.5% | **5.2%** | 0.4% | 1.2% |
| 注释行占全部行 | 15.0% | 15.1% | 6.0% | 8.5% | **0.0%** | 27.8% | 16.6% |
| 命名 `Prop` 定义（每千行） | 0.8 | 0.3 | 0.3 | 0.6 | **6.0** | 1.1 | 0.06 |
| 选项覆盖（每千行） | 8.3 | 5.9 | 3.1 | 3.0 | 5.0 | 0.15 | 0.64 |
| 重复的短名（占不同短名） | 13.3% | 5.8% | 4.3% | 1.7% | 13.0% | 1.7% | 2.3% |
| `have`（每千行） | 31.8 | 88.1 | 67.5 | 127.2 | 168.0 | 124.8 | 63.4 |
| `simp`（每千行） | 102.1 | 73.3 | 76.1 | 36.5 | 55.0 | 79.2 | 173.4 |
| `grind`（每千行） | 5.0 | 1.2 | 0.7 | 4.3 | 0.0 | 6.2 | 38.4 |

（命名 `Prop` 定义按"单行里 `def … : Prop` 后接 `:=` 或行尾"计，所以原始版本是 80,106 个；[RH 案例](rh/grh-compact-vs-original.md)里的 65,318 个只数 `def X : Prop :=` 的精确形式。）

## 读法

1. **区分来源的指标：** 只有一个声明的文件占比、每个文件的声明数、命名 `Prop` 定义的密度、注释占比、导入行占比。模型生成的大型开发在这五项上都离其他树很远；三个人写研究仓库彼此接近，也接近 Mathlib。
2. **不区分来源的指标：** 选项覆盖密度（Mathlib 最高）、重复短名比例（Mathlib 与原始版本相同，因为库按命名空间复用短名）。它们指向构建与版本问题，不指向冗余。
3. **证明写法：** Mathlib 每个定理平均 7.5 行，人写研究仓库 15.6–17.5 行，原始版本 16.7 行。单看每个定理的长度，模型生成的开发并不比人写研究仓库更啰嗦；它的冗余在命题个数与组织，而不在单个证明。这与 LeanPolish 在 Mathlib 上只省 0.5%、在模型生成的竞赛证明上省约 20% 的结果一起看：竞赛证明的啰嗦在证明内部，大型开发的啰嗦在结构。
4. **策略画像：** `have` 密度从 Mathlib 的 31.8 到原始的 168.0，`grind` 只有紧凑版大量使用；写法是判断能否走 [B2](../methods/b2-tactic-golf-and-automation.md) 的直接依据。

## 怎么用这些指标做诊断

见 [`../methods/README.md`](../methods/README.md) 的"诊断"一节：先算这张表，再按指标指向的路线开工。

## 缺口

- 只有一份模型生成的大型开发（原始 RH 归档）；"模型生成的中小仓库"这一格没有测。
- 依赖闭包、未用声明比例需要构建产物，这里没有算。
