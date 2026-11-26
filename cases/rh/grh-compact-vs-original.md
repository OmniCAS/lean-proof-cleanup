# grh-lean 的两个短版本与原始代码的对比

**Summary (English).** How the two short editions of `lsernau/grh-lean` (readable `grh/`, about 477k lines; compact `grh-compact/`, about 113k lines; commit `72fead1`) relate to the original 17.4M-line development, counted by us from the three source trees without building them. The reduction is a rewrite, not a cleanup: theorems and lemmas fall from 818,755 to 18,227 and 7,088, while lines per theorem stay at 16.7, 21.0 and 11.1. Dead code explains about 1.3 times; mechanical cleanup as a whole about two to three times. Only 14% of the compact edition's names occur in the original; the proof skeleton is the same, the organisation is new. The text is in Chinese.

对象：原始归档（社区仓库 `original` 分支，提交 `40e56bab`）、[grh-lean][grh]（提交 `72fead1`）的可读版 `grh/` 与紧凑版 `grh-compact/`。数字由 [`../scripts/profile_lean_trees.py`](../../scripts/profile_lean_trees.py) 从三份源码直接数出，汇总在 [`../data/tree_profiles.json`](../../data/tree_profiles.json)；没有构建。作者的说法引自 Zulip 话题 "New proof in 300k lines" [C5]。该开发陈述了 RH 与 Dirichlet GRH，第三方报告机器核验通过，数学尚无人审阅。

## 核心判断

1. **这是重写，不是清理。** 定理和引理从 818,755 个降到 7,088 个（115 倍），每个定理的平均行数只从 16.7 降到 11.1（1.5 倍）。缩小几乎全部来自"少了两个数量级的命题"。
2. **死代码只能解释约 1.3 倍。** 原始版本 75.8% 的声明被最终定理用到（Shore 的依赖闭包 [D8]）。机械清理合计的上限约两到三倍，社区五天做到正文行 −23%。
3. **不是改名移植。** 紧凑版 9,916 个声明名里只有 1,344 个（14%）在原始版本出现过，其中 14 个字符以上的具体名字只有 275 个，多是 `strong_approximation` 一类的通用叫法；同名引理的陈述和证明也不同。
4. **作者说的做法是三件事：** 展开成一条长证明、跨边界化简、再卷回去；一部分子结果换了论证；先压到最短（紧凑版），再为可读性展开（可读版）。
5. **能带走的认知：** 压缩的单位是命题个数；手段是提高每个命题的通用性、选对 Mathlib 的入口、把逐步推导交给自动化、去掉包装层（§4）。

## 1 数字（本仓库测）

| | 原始 | 可读版 | 紧凑版 |
|---|---|---|---|
| 文件 | 175,187 | 803 | 794 |
| 代码行（去掉注释、空行、导入、`open` 等） | 13,295,716 | 283,663 | 69,090 |
| 定理 + 引理 | 818,755 | 18,227 | 7,088 |
| 每个定理的平均行数（含陈述） | 16.7 | 21.0 | 11.1 |
| 每个文件的声明数 | 6.1 | 29.7 | 13.8 |
| 只有一个声明的文件 | 45.0% | 0.6% | 9.7% |
| 导入行占全部行 | 5.2% | 0.4% | 1.2% |
| 注释行占全部行 | 0% | 27.8% | 16.6% |
| 命名的 `Prop` 定义（`def X : Prop :=`） | 65,318 | 274 | 4 |
| 文件名含 `Statement` 的文件 | 48,367 | — | — |
| 同一个短名被定义多次的名字 | 98,631 | 378 | 225 |

原始版本这里数的是归档里全部 175,187 个 `.lean` 文件；`data/rh_revision_stats.csv` 数的是 Git 跟踪的 174,793 个，口径略有不同。原始版本里重复最多的短名：`Statement`（4,225 次）、`proof`（3,234）、`main`（2,922）、`full`（1,412）。

**策略用法（每千行代码出现次数）：**

| | 原始 | 可读版 | 紧凑版 |
|---|---|---|---|
| `have` | 168.0 | 124.8 | 63.4 |
| `rw` | 133.7 | 52.7 | 16.1 |
| `exact` | 81.5 | 37.7 | 12.7 |
| `intro` | 38.4 | 5.0 | 4.2 |
| `unfold` | 8.4 | 0.6 | 0.7 |
| `simp` | 55.0 | 79.2 | 173.4 |
| `simpa` | 8.6 | 33.1 | 66.4 |
| `simp_all` | 0.1 | 1.7 | 29.5 |
| `grind` | 0.0 | 6.2 | 38.4 |
| `aesop` | 0.0 | 1.4 | 18.2 |
| `grw` | 0.0 | 5.4 | 19.3 |
| `fun_prop` | 0.6 | 6.8 | 16.7 |
| `field` | 0.0 | 2.1 | 10.3 |
| `bound` | 0.1 | 0.6 | 8.4 |
| `calc` | 3.1 | 9.0 | 0.1 |
| `·` 开头的分支 | 51.9 | 25.8 | 4.4 |

原始版本是逐步推导的写法，完全不用 `grind`；紧凑版把事实列表交给收尾的自动化；可读版介于两者之间，多用 `calc` 和注释。

## 2 样例

原始归档发布时没有许可证文件，下面对它只作评论所需的短节选（共四段，每段不超过 12 行，注明路径与提交）。grh-lean 的节选按其 Apache-2.0 许可证引用（Copyright 2026 Anthropic, PBC）。

### 样例一：同一个命题，三种写法

命题：由"Re s > 1/2 无零点"推出 ζ 的非平凡零点都在临界线上。三版都只依赖 Mathlib。

原始（`src/Formalism/GammaFactorNonvanishing/RhOfRight.lean`，提交 `40e56bab`，全文 62 行，节选开头 12 行）：

```lean
theorem Formalism.VW.rh_of_right (hz : ∀ s : ℂ, 1 / 2 < s.re → s ≠ 1 → riemannZeta s ≠ 0) : RiemannHypothesis := by
  unfold RiemannHypothesis
  intro s hs htriv hs1
  rcases lt_trichotomy s.re (1 / 2) with hlt | heq | hgt
  · exfalso
    have hpi : (Real.pi : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    have hs0 : s ≠ 0 := by
      rintro rfl
      rw [riemannZeta_zero] at hs
      norm_num at hs
    have ht : 1 / 2 < (1 - s).re := by
      rw [Complex.sub_re, Complex.one_re]
```

后面用带 cos 和 Γ 的非对称函数方程 `riemannZeta_one_sub`，再对整数 k 分三种情况证明 cos 不为零（约 25 行）。

可读版（`grh/src/New/Main.lean`）约 15 行：改用完备 ζ 的对称函数方程，分三步写出，每步一行注释。

紧凑版（`grh-compact/src/New/Main.lean`，grh-lean，Apache-2.0，Copyright 2026 Anthropic, PBC）：

```lean
lemma New.zeta_zeros_on_line (h : DirichletLNonvanishingRightOfHalf) :
    RiemannZetaZerosOnLine := fun s ↦ by
  obtain _ := h 1 1 s, h 1 1 (1 - s), @Nat.or_exists_add_one, riemannZeta_zero
  simp_all
  grind [riemannZeta_def_of_ne_zero, completedRiemannZeta_one_sub, Complex.Gammaℝ_eq_zero_iff]
```

差别有两层。数学上换了入口：对称的 `completedRiemannZeta_one_sub` 不需要处理 cos 的零点，原始那约 25 行分类讨论整个消失。写法上，不再一步步推，只把几个事实放进上下文，把三条引理交给 `grind`。原始版本里这个推导还出现了三次（`Formalism.VW.rh_of_every`、`UpperTheory.riemannHypothesis_of_everyCharacter`、`Claim.zeta`）；整个末端（半平面形式推出其余四条）在原始版本里约 450 行（其中约 200 行是导入）、分在 5 个文件，在紧凑版里约 15 行。

### 样例二：同名的小引理

命题：矩阵幂的迹等于特征值幂的和。

原始（`src/Development/AbelianVarietyTheory/Proofs/InertiaEigenvalues/CharpolyEqOfTracePowers.lean`，提交 `40e56bab`，节选）：

```lean
theorem trace_pow_eq_sum_roots {V : Type} [AddCommGroup V] [Module ℂ V] [FiniteDimensional ℂ V]
    (f : Module.End ℂ V) (k : ℕ) :
    LinearMap.trace ℂ V (f ^ k) =
      ((LinearMap.toMatrix (Module.finBasis ℂ V) (Module.finBasis ℂ V) f).charpoly.roots.map
        (· ^ k)).sum := by
  classical
  rw [LinearMap.trace_eq_matrix_trace ℂ (Module.finBasis ℂ V), ← GlobalTheory.CharpolyPow.roots_charpoly_pow,
    ← Matrix.trace_eq_sum_roots_charpoly]
  congr 1
  induction k with
  | zero => simp [LinearMap.toMatrix_one]
  | succ n ih => rw [pow_succ, LinearMap.toMatrix_mul, ih, pow_succ]
```

紧凑版（`grh-compact/src/Lib/GaloisRep/Pseudocharacter/FibreSum.lean`，grh-lean，Apache-2.0，Copyright 2026 Anthropic, PBC）：

```lean
lemma trace_pow_eq_sum_roots m : (A ^ m).trace = (A.charpoly.roots.map (· ^ m)).sum := by
  rw [trace_eq_sum_roots_charpoly, (charpoly _).funext, roots_multiset_prod_X_sub_C]
  simpa [eval_charpoly, eval_multiset_prod] using!
    (det_aeval_neg_eq_prod_roots A <| C · - (-X) ^ m :)
```

原始版本对线性映射陈述，再经一组选定的基转成矩阵，并依赖另一个文件里的辅助引理；紧凑版直接对矩阵陈述，公共参数放进 `variable`，陈述只有一行。

### 样例三：按项目的数据包陈述，还是按通用对象陈述

原始（`src/Development/AbelianVarietyTheory/Proofs/FlagMeasures/ClassNumberRootDiscFactorLeHHZ.lean`，提交 `40e56bab`，陈述）：

```lean
theorem classNumber_le (D : D7) (b : ℝ) (hb : 1 ≤ b) (hrd : D.host.rdE ≤ b) (hf : 1 ≤ D.R.f)
    (hr : 1 ≤ D.R.rS) (hlog : Real.log D.R.f ≤ Real.sqrt D.R.rS) :
    (classNumber D.host.E : ℝ) ≤ b ^ ((D.R.m : ℝ) * D.R.f) := by
```

紧凑版（`grh-compact/src/Lib/General/NumberTheory/ClassNumberBound.lean`，grh-lean，Apache-2.0，Copyright 2026 Anthropic, PBC）：

```lean
lemma classNumber_le F [Field F] [NumberField F] :
    classNumber F ≤ (2 ^ finrank ℚ F * (discr F).natAbs) ^ (finrank ℚ F + 1) := by
```

原始的引理绑在项目自己的数据结构 `D7` 和五条尺度假设上，只能用在一处；紧凑版是对任意数域的一条教科书式的界，可以反复用。这种差别在两版之间很普遍，是命题个数下降的主要来源之一。

### 样例四：原始版本里的包装层（紧凑版没有对应物）

原始（`src/Development/AutomorphicArithmetic/ThetaCorrespondence/ThetaPairLifts/ThirdPlaceSeries/TypePlacesCoverStatement.lean`，提交 `40e56bab`，全文 22 行，节选并截断长行）：

```lean
set_option synthInstance.maxHeartbeats 200000

section
open Formalism.BasicNotions Formalism.MainNotions Formalism.MainNotions.N Formalism.L2 …
set_option maxHeartbeats 1000000 in
theorem _root_.GlobalTheory.T.gPlaces_of_levelA : ∀ hL : _root_.UpperTheory.Zero.LLC.RecTExists, …
  first | exact @_root_.GlobalTheory.TypePlacesCover.gPlaces_all_alt | exact … | (intros; apply … <;> assumption)
end
```

文件前面还有 5 行导入、另外 8 行 `open` / `attribute` / `set_option`。它只是把隔壁文件里的定理换个名字再证一遍，证明是一行机械生成的"试三种写法"。原始版本里文件名含 `Statement` 的有 48,367 个，占全部文件的 28%；社区的 #324 一次删掉了 22,054 个这样的薄包装模块。

## 3 115 倍是怎么分的

| 来源 | 量级 | 依据 |
|---|---|---|
| 没被用到的声明 | 约 24% | Shore 的依赖闭包 [D8]（他人报告） |
| 类型与先前定理完全相同的定理 | 约 24.1 万个 | Tanner Clary 在导出上的统计（Zulip，见 [rh-community-cleanup](rh-community-cleanup.md)） |
| 包装与别名 | `Statement` 文件 48,367 个；命名 `Prop` 定义 65,318 个 | 本仓库测 |
| 导入、`open`、选项等行 | 占全部行的 12.8% | 本仓库测 |

这些加起来大约是两到三倍（估计）。其余的四五十倍来自重写：通用化、内联后重新分块、换论证；三者各占多少，从外部量不出来。作者的说法：

- 基于同一个证明；做法是把定义展开成一条长而平的证明，在那里找化简，再卷回去，这样可以跨边界化简；有些地方需要全新的论证，比如去掉 Vandiver [z643710501]。
- 很多简化来自给子结果找到更简单的证明：奇点消解整个去掉；Gram 行列式的乘积公式代替 slope 不等式；Hecke L 值代替 Shimura 簇上的 covolume；Vandiver、patching、Hida 理论、GSp4、局部 Langlands 都被砍掉 [z643717520]。
- 先压到约 7.6 万行代码，再为清晰重写成约 30 万行 [z643719896]。

按目录名粗查原始版本，名字明确对应被砍理论的目录并不大：`ResolutionOfSingularities` 约 15 万行，patching 约 5 万行，Hida 约 3 万行，局部 Langlands 约 3 万行。原始版本的目录名与内容对应得不好（810 万行都在 `Development/AbelianVarietyTheory` 下），所以这只是下限。

## 4 关于压缩的认知

1. **以命题个数为目标，不以行数为目标。** 先问"这条引理能不能不存在"。
2. **展开、化简、再分块。** 只用一次的引理先内联，在展开后的证明里找跨引理的化简，再按真正被复用的边界重新切。原始版本的边界是生成时留下的，不是数学上的边界。
3. **把陈述写到自然的通用程度。** 对任意矩阵、任意数域陈述，而不是对项目的数据包陈述。
4. **选对 Mathlib 的入口。** 样例一里换一个函数方程的形式，就省掉了大半证明。
5. **把逐步推导换成"给事实，交给自动化"。** `grind [...]`、`simp_all [...]`、`grw`、`bound`、`fun_prop`、`field`。
6. **去掉包装层。** 不为每条陈述单独定义命名的 `Prop`，不写别名定理，不把一串假设包成结构再层层传递。
7. **两步走。** 先压到最短，再为阅读展开。可读版是紧凑版的四倍，多出来的是注释（28% 的行）、`calc` 和分步。
8. **代价。** 源码短不等于证明项小：紧凑版的导出（5.17 GB）比可读版（4.49 GB）还大 [D18]；重度自动化的证明对库版本更敏感：紧凑版全局设了 `maxHeartbeats 4000000`，并有 30 处 `backward.isDefEq.respectTransparency false`；紧凑版不适合人读，社区以可读版为准。
9. **机械清理与语义重写是两回事。** 删死代码、去重、收窄导入不需要理解数学，上限是二三成；两个数量级需要理解证明后重写。各条路线见 [`../methods/`](../../methods/README.md)。

## 5 与原始版本的关系

### 官方说了什么

没有论文，也没有方法说明。

| 出处 | 说法 |
|---|---|
| 仓库 README | 证明基于 Alpöge 的；这是一个更短的版本，与 Anthropic 的同事和 Claude 合作完成；研究成品，不维护，不接受贡献 [D16] |
| 两版各自的 README | 这是 Alpöge 的 Lean 证明的一次更短的重写，沿用那个证明的方法；很多步骤用别的论证证明；其中一部分，主要是背景材料，是从那里移植过来再重写的 [D16] |
| NOTICE | `Statements.lean` 以及 `Main.lean` 里五个定理的名字和类型原样取自原证明；`lakefile.toml` 由它改编 [D16] |
| 作者在 Zulip | 基于同一个证明，方法不能多说；之后只给了上面三点 [C5] |

所以官方的口径是：基于原始版本重写。不是从头独立做的，也不是对原始代码的机械压缩。具体步骤没有公开。

### 骨架对得上（本仓库核对）

对照的是我们先前对原始源码的阅读，以及紧凑版 `New/Main.lean` 的说明。

| 原始版本 | 紧凑版 |
|---|---|
| 末端：由函数方程把 RH、GRH 归为 Re s > 1/2 无零点 | 相同（`New.zeros_on_line`、`New.zeta_zeros_on_line`） |
| 带窗口的 Landau 判据，目标是 x^(1/2+O(ε)) 的单侧界 | 相同：窗口 log x₁ ∈ [t, t²]，Landau 引理，单侧界 x^(8ε−1/2) |
| 辅助参数 (q, d) 与宿主域 | 对应但取法不同：模 N₀ = 18480·q，素数 d，宿主域 E = K(ζ)，K = ℚ(√−d)；原始版本里没有 18480 这个常数 |
| theta 对应，迭代提升链长 m ≍ √x | 相同：m ∈ [√x, 2√x] 个 theta 提升 |
| 行与列（`IsRow`、`IsCol`、`ColMatch`、`Rows.Data`） | 行是不定 U(r) 上的形式，列是定 U(k) 上的形式；定义与原始的不同 |
| Hermite 格的斜率不等式 | 换成 Gram 行列式的乘积公式与高度 |
| Ш 窗口界（Vandiver 型）、部分局部 Langlands、大量文献定理 | 去掉 Vandiver；局部 Langlands、Hida 理论、GSp4 等被砍 |

### 组织全部另起（本仓库测）

| 检查 | 结果 |
|---|---|
| 原始版本的命名空间和核心标识符（`GlobalTheory`、`UpperTheory`、`Formalism.`、`D7`、`VWin`、`Row0b` 等 21 个）在紧凑版里出现的次数 | 0 |
| 紧凑版的参数（`18480`、`primeError`、`towerDeg` 等）在原始版本里出现的次数 | 0 |
| 具体名字（14 个字符以上）与原始版本重合的比例 | `Lib` 5.3%（260 / 4,883），`New` 1.1%（17 / 1,516） |
| 重名的定义是否同一个东西（`IsPolar`、`IsRow`、`HeightLe`） | 都不是：原始的 `IsPolar` 是行列式律的性质，紧凑版的是 Landau 引理里的极点条件 |
| 核心数据记录 | 原始是 `D7`（含 `Ranks`、`Host`、`Rows.Data`、词与权的若干层）；紧凑版是 `Parameters` 与 `Data`，字段完全不同 |
| 目录 | 原始按 `Development` / `Formalism` / `GroundTheory` 等分；紧凑版按数学主题分（`Lib/Weil`、`Lib/Shimura`、`New/Selmer`、`New/Seesaw` 等） |

**导入图的形状**（用 [OmniCAS/lean-distributed-build](https://github.com/OmniCAS/lean-distributed-build) 的 `bench/gen/dag_stats.py`）：

| | 模块 | 内部导入边 | 每模块导入数 | 层数（最长链） | 最宽一层 |
|---|---|---|---|---|---|
| 原始 | 175,187 | 753,261 | 4.3 | 203 | 5,927 |
| 可读版 | 803 | 1,733 | 2.2 | 54 | 27 |
| 紧凑版 | 794 | 1,398 | 1.8 | 55 | 32 |

原始版本宽而浅，有 5,927 个互不依赖的起点；两个短版本窄而深，接近一条链。

### 留下的痕迹

1. `Statements.lean` 与五个定理的名字、类型原样保留，`lakefile.toml` 改编自原始的。
2. 数学词汇与参数一致：行与列、seesaw、Chowla–Selberg、宿主域、约 √x 个提升、窗口加 Landau。
3. `Lib` 里约 5% 的具体名字与原始相同，与 README 说的"背景材料从原处移植再重写"一致。
4. 开发环境的痕迹：可读版的 GUIDE 写着清空 `Lib/Speed` 后每个文件在 Lean v4.33.1 上仍能编译，ATTRIBUTION 注明所引的 Mathlib 名字在提交 `0df444a3` 的同一文件里也有；v4.33.1 与 `0df444a3` 正是原始版本的工具链和 Mathlib。说明工作在原始版本的环境里起步，后来才移到 v4.35.0。

### 步骤只能推断

从成品能推断的顺序（推测，不是作者的说法）：固定陈述与最终定理；保留证明的骨架和参数；背景材料移植后按通用陈述重写；论证主体展开、跨边界化简、重新分块，其中一部分换成新论证；压到最短得到紧凑版；再展开加注释得到可读版。

## 6 紧凑版与可读版之间的关系（本仓库测）

两者是同一次重写的两个版本，各自是独立的 Lake 工程，互不导入，证明同样的五个定理，分别核验。

| 项目 | 结果 |
|---|---|
| 声明名 | 紧凑版 9,910 个，可读版 22,492 个；紧凑版的名字有 75%（7,477 个）在可读版出现 |
| 只在一版出现的名字 | 只在可读版 15,015 个，只在紧凑版 2,433 个 |
| 同名定理的陈述文本 | 4,756 条里只有 560 条（12%）逐字相同；其余多是变量命名和写法不同 |
| 同名定理的总行数 | 紧凑版 33,548 行，可读版 74,881 行，后者是 2.2 倍 |
| `Lib` 的目录 | 16 个主题目录名字一一对应 |
| `New` 的目录 | 重排过：紧凑版按构件分（`Filling`、`Seesaw`、`RealPlace` 等），可读版按论证顺序分（`Reduction`、`UpperBound`、`Spanning`、`Congruences` 等） |

可读版比紧凑版多出来的四倍行数，来自三处：同一条引理写得更展开（2.2 倍）；拆出更多中间引理（声明数是 2.3 倍）；注释（占 28% 的行）。与原始版本相比，可读版的声明名只有不到 8% 在原始版本出现过。

[grh]: https://github.com/lsernau/grh-lean
[C5]: ../../REFERENCES.md
[D8]: ../../REFERENCES.md
[D16]: ../../REFERENCES.md
[D18]: ../../REFERENCES.md
[z643710501]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643710501
[z643717520]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643717520
[z643719896]: https://leanprover.zulipchat.com/#narrow/channel/658556-Riemann-Hypothesis/topic/New.20proof.20in.20300k.20lines/near/643719896
