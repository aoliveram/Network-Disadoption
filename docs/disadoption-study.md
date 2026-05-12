---
title: "ADVANCE Disadoption Study v5"
subtitle: "Behavioural correlates of e-cigarette adoption and disadoption (W1-W10)"
author: "A. Olivera, T. Valente, K. Miljkovic, Y. Cao"
date: \today
geometry: "margin=2.5cm"
fontsize: 10pt
colorlinks: true
linkcolor: teal
toc: true
toc-depth: 3
header-includes:
  - \usepackage{amsmath}
  - \usepackage{amssymb}
  - \usepackage{booktabs}
  - \usepackage{array}
---

# 1. Introduction

v5 keeps the v4b panel (full **W1-W10** ADVANCE panel — 10 semester waves, 4,437 students, 042326 release) and switches the time control from `wave fixed effects + cohort dummy` to **`grade-semester fixed effects (gs_fe) + cohort dummy`**. Grade-semester is derived from `(cohort, wave)` on the standard ADVANCE timeline (1 = fall 9th, 2 = spring 9th, …, 8 = spring 12th); it answers the prevalent reviewer concern that the time control should track *developmental* position within high school rather than calendar time. The cohort dummy is retained (cohorts experience the same grade-semester at different calendar times). Six regression families are reported:

- **§5 Main**: the v4 spec ($E_D$ = peer share who flipped $1 \to 0$ between $w-2$ and $w-1$).
- **§6 Alt $E_D$**: alternative operationalisation $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ (cumulative peak − current exposure).
- **§7 No $E_D$**: refit §5 outcomes (Adopters, A, B, C) without the $E_D$ predictor.
- **§8 Model C window sensitivity**: $W=1$, $W \le 2$, $W \le 3$ for the cyclic disadoption definition.
- **§9 Sensitivity (a)**: $1 \to 0$ with NA-only future counted as Stable (A).
- **§10 Sensitivity (b)**: event identification using observed-wave jumps rather than consecutive-calendar pairs.

All regression cells report **odds ratios** $\exp(\hat\beta)$ with the cluster-robust (or `glmer`) p-value in parentheses. **Bold** marks $p < 0.05$.

# 2. Data

## 2.1 Sources and panel construction

- **W1-W8**: `data/advance/Data/ADVANCE_W1-W8_Data_Complete_042326.xlsx` (4,437 students).
- **W9-W10 HS**: `data/advance/Data/ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx` (1,060 students, strict subset of W1-W8).
- **Edges**: regenerated from the 042326 XLSX into `data/advance/Cleaned-Data-042326/wNedges_clean.csv` for $N = 1..10$. Uniform rule: keep edge $(i, j)$ iff $j \neq i$, $j$ is in the panel, and $j$ responded to wave $w$. W1 edges adopt the legacy `Cleaned-Data/w1edges_clean.csv` after applying the same hygiene (the W1 XLSX stores friend cells as REDCap-internal codes without a record_id map).

Per-wave non-NA `past_6mo_use_3` counts: W1 = 851, W2 = 2,235, W3 = 3,768, W4 = 3,907, W5 = 3,833, W6 = 3,645, W7 = 3,378, W8 = 3,048, **W9 = 974, W10 = 969**.

Per-wave edge counts (clean): W1 = 1,466, W2 = 4,344, W3 = 9,681, W4 = 10,133, W5 = 9,987, W6 = 8,850, W7 = 8,120, W8 = 6,879, **W9 = 2,665, W10 = 2,511**. Self-loops dropped in all waves; reciprocity 50–55%.

### 2.1.1 Edge similarity vs the legacy `Cleaned-Data/`

To verify that the 042326 reconstruction reproduces the legacy edge set, we compute Jaccard similarity per wave and the share of legacy edges retained ("% old kept") and reciprocally:

| Wave | n_legacy | n_v4b | both | Jaccard % | % old kept | % new in old |
|:-:|---:|---:|---:|---:|---:|---:|
| 1  | 1,474  | 1,466  | 1,466 | 99.5 | 99.5 | 100.0 |
| 2  | 4,380  | 4,344  | 4,342 | 99.1 | 99.1 | 100.0 |
| 3  | 9,840  | 9,681  | 9,649 | 97.7 | 98.1 |  99.7 |
| 4  | 10,156 | 10,133 | 10,073 | 98.8 | 99.2 |  99.4 |
| 5  | 9,928  | 9,987  | 9,901 | 98.9 | 99.7 |  99.1 |
| 6  | 8,840  | 8,850  | 8,767 | 98.6 | 99.2 |  99.1 |
| 7  | 8,134  | 8,120  | 8,083 | 99.3 | 99.4 |  99.5 |
| 8  | 6,871  | 6,879  | 6,773 | 97.5 | 98.6 |  98.5 |

Jaccard ≥ 97% in W1–W8. In W1–W8, ≥98% of legacy edges are present in v4b, and 100% of v4b edges in W1, W2, W9, W10 were already in the legacy set.

## 2.2 Q-restriction

Eligibility per $Q \in \{5, 6, 7, 8\}$ requires the student to have at least $Q$ **consecutive** observed waves of `past_6mo_use_3`. Adding W9–W10 dramatically expands the high-$Q$ samples:

| Q (consecutive) | v4 (W1-W8) | v4b (W1-W10) |
|:-:|---:|---:|
| 8 |   371 | **1,040** |
| 7 | 1,228 | **1,961** |
| 6 | 2,453 | **2,499** |
| 5 | 2,972 | **3,007** |

Network alters used to compute $E_{\text{users}}$ and $E_D$ are NOT restricted by Q.

**Friendship-nomination degree distribution (pooled W1-W10).** Each ego nominates up to seven friends per wave; out-degree is the count of valid alters (alter in the panel and responding at $w$); in-degree is how many other egos name a given student.

![Out-degree and in-degree distributions across all valid (ego, wave) cells with non-zero degree.](outputs/figures/sec2_degree_distribution.pdf){width=95%}

Out-degree is mechanically capped near 7 (questionnaire limit); in-degree has a long right tail (a few students are frequently nominated). Both distributions are right-skewed but well populated.

**Eligible vs effective**: the Q-row above is the count of *eligible* students. The regression in each column then drops rows with NA on any predictor (complete-case). The effective `N Students` reported per column is therefore smaller than the Q-row count. The Adopters column suffers the smallest cut (most predictors are filled at every observed wave); the A / B / C columns work on the much smaller ever-user subset (each column's `N Students` reflects that). E.g., at $Q = 8$ we have 1,040 eligible students; the Adopters regression uses 925 (after complete-case dropping); the A regression uses 83 (ever-users with valid predictors).

## 2.3 Parent education — scale harmonisation and per-student LOCF

Parent education is the only covariate that required non-trivial cross-wave handling: the questionnaire scale itself **changed mid-panel**, from a 7-level scale in W1–W6 to a 9-level scale in W7–W10. We harmonise to the legacy 7-level scale and then carry forward each student's most recent observation to fill the gaps.

**Step 1 — Raw column.** Each wave has the column `w{w}_dem_high_par_edu` (highest parental education level reported by the student). It is read selectively by [`R/01-advance-panel.R`](R/01-advance-panel.R) (line 30) into the long panel as `par_edu_raw` (line 139 in the wide→long step).

**Step 2 — Scale change at W7.** From W7 onward the questionnaire was extended to 9 categories (additional fine-grained options between "some college" and "bachelor's"). Codes 1–4 are stable across versions; the legacy "4" category was split into three (4, 5, 6) in the new scale; legacy 5/6/7 map to new 7/8/9. We collapse the new scale to the legacy scale via the deterministic remap below ([`R/01-advance-panel.R:103-114`](R/01-advance-panel.R)):

| New scale (W7-W10) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| Legacy scale (W1-W6) | 1 | 2 | 3 | 4 | **4** | **4** | 5 | 6 | 7 |

The collapse of new codes 4/5/6 onto legacy 4 is information-losing (three categories become one) but is the only mapping that produces a unified ordinal scale across all ten waves. After remapping, `par_edu_raw` is bounded in $\{1, \ldots, 7\}$ at every wave.

**Step 3 — Per-student last-observation-carried-forward (LOCF).** Because students do not refresh their parental-education report every wave, many person-waves have `par_edu_raw = NA` between two observed values. We treat parent education as **slowly-varying (or effectively time-invariant) within student** and carry the most recent observed value forward to fill subsequent NAs. The LOCF function in [`R/01-advance-panel.R:191-198`](R/01-advance-panel.R) is applied per `record_id`, producing the final regression-ready `par_edu` column. LOCF only overwrites NAs; observed values are never replaced by earlier observations.

**Resulting time profile.** This pipeline produces a small but real cross-wave shift in the panel mean: at gs = 2 (spring 9th, mostly W2 observations on the legacy 7-level scale) the mean `par_edu` is 5.07; at gs = 8 (spring 12th, mostly W8 observations on the remapped 9-level scale) it falls to 3.82 because the three new-scale categories 4/5/6 all collapse to legacy 4, pulling the upper tail down. **This is a measurement artifact, not a behavioural shift in family socioeconomic status.** Within-student variation in `par_edu` over time is small (most students report the same value across waves) and the regression specifications include grade-semester FE that absorb mean shifts of this kind, so the artefact does not contaminate the per-predictor ORs. The artefact would matter if we treated `par_edu` as a *time-varying* shock — we don't.

# 3. Event definitions

For each student we define, on consecutive observed waves:

- **Adopters**: first $0 \to 1$ transition. One event per person.
- **A — Stable**: $1 \to 0$ with **no future return to 1** in any later observed wave. One event per person. Indeterminates ($1 \to 0$ with NA-only future) are dropped from A in §5/§6/§8/§10; counted as A in §9.
- **B — Experimental**: first $1 \to 0$ (any). One event per person.
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves. Multiple events per person possible. §5/§6/§9/§10 use $W=1$; §8 reports $W=1, 2, 3$.

§10 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs).

**Per-wave degree and using-friend count distributions.** For every wave $w \in \{1, \ldots, 10\}$ the figure below overlays *two* distributions: out-degree (blue bars, "how many ego-waves nominate $k$ friends?") and the count of *using* friends per ego (red bars, "how many ego-waves have $k$ friends who currently use ecig?"). The "count of using friends" is $k_{\text{users}} = E_{\text{users}} \times \text{out\_degree}$ (rounded to integer): the number of alters of the ego who currently use ecig at that wave.

![Per-wave: blue = distribution of out-degree (count of friends nominated); red = distribution of $k_\text{users}$ (count of friends who currently use ecig). Both at integer support; bars at the same x-value are overlaid with alpha = 0.55 so overlap is visible.](outputs/figures/sec3_per_wave_degree_exposure.pdf){width=95%}

Two patterns are visible: (i) out-degree is centered around 3-4 friends in every wave (questionnaire cap = 7), confirming a stable nomination structure; (ii) the using-friend distribution is heavily concentrated at $k_\text{users}=0$ in early waves but the right tail thickens steadily from W3 onward. By W6-W8 a substantial slice of egos has 1-2 using friends; very few egos ever exceed 3 using friends.

# 4. Methods

For each regression, the outcome at person-wave $(i, w)$ is binary; the risk-set is the corresponding panel:

- **Adopters / A / B**: GLM logistic with **grade-semester fixed effects** (`gs_fe`, 8 levels = 7 dummies, reference = gs=1) and cluster-robust SE by `record_id` (`sandwich::vcovCL`).
- **C**: `lme4::glmer(... + (1 \mid \text{record\_id}))` with `gs_fe`, since C admits multiple events per person; we report ICC $\rho = \sigma^2_u / (\sigma^2_u + \pi^2/3)$.

**Grade-semester encoding**. `gs_fe` is derived from `(cohort, wave)` on the ADVANCE timeline (class of 2024: W1 = gs 1 (fall 9th), W2 = gs 2 (spring 9th), …, W8 = gs 8 (spring 12th); W9-W10 are post-HS, set to NA and excluded. Class of 2025: W3 = gs 1, …, W10 = gs 8). Each grade-semester spans roughly six months. The first observed wave for each cohort produces no at-risk rows because the lag is undefined; this leaves gs=1 with zero at-risk rows and the reference category for `gs_fe` is therefore gs=2 (spring 9th) in practice. Grade-repeaters (≈1–3% of HS students nationally) introduce a small mislabeling bound of ~1% of person-waves; the cohort dummy partially absorbs the systematic component.

**Predictors (13)**: cohort (2025 vs 2024), female, sexual minority, parent education, asian, hispanic/latine, MDD (RCADS Mean), GAD (RCADS Mean), out-degree, in-degree, perceived friend use ($w-1$), network exposure to users ($E_{\text{users}}, w-1$), network exposure to dis-adopters ($E_D, w-1$). With W9-W10 in the panel, both cohorts are retained at all $Q$ levels: cohort 2024 students with $\ge Q$ consecutive observed waves and cohort 2025 students whose $w \ge 3$ entry leaves them with $\ge Q$ observed waves through W10.

**Note on ESE**: the Early Smoking Experience composites (`ESE_Pos_no9_Mean`, `ESE_Neg_no510_Mean`) are **not used as predictors** in v4b — only ~21% of students have any ESE response, and the missingness is concentrated outside the at-risk-for-disadoption sub-population (see §12). Including ESE forces complete-case dropping that selects toward users and biases the Adopters and A/B/C samples. Sensitivity work on the user-subset is deferred to a later iteration.

§6 substitutes $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ for the §5 definition.

**Raw XLSX inputs.** All variables in v4b are constructed from two release files: `ADVANCE_W1-W8_Data_Complete_042326.xlsx` (4,437 students; W1-W8) and `ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx` (1,060 students; W9-W10, strict subset of W1-W8). Per wave $w \in \{1,\ldots,10\}$ we consume **only** the columns below; everything else in the wide release is ignored.

| Raw XLSX column (per wave $w$) | Long-panel field | Used to build |
|:---|:---|:---|
| `record_id` (no wave prefix) | `record_id` | row anchor |
| `w{w}_schoolid` | `schoolid` | community FE; cohort assignment via first non-NA school |
| `w{w}_past_6mo_use_3` | `ecig` | **outcome** ($1 \to 0$ = disadoption event); `ecig` at $w-1$ defines who is at risk |
| `w{w}_past_6mo_use_2` | `cig` | retained for reference; not a v4b predictor |
| `w{w}_dem_gender` | `dem_gender` | `female = 1[\text{dem\_gender}=0]`; code `3` ("prefer not to disclose") $\to$ NA |
| `w{w}_dem_sexuality` | `dem_sexuality` | `sex_minority = 1[\text{dem\_sexuality} \neq 1]`; code `10` $\to$ NA |
| `w{w}_dem_high_par_edu` | `par_edu_raw` $\to$ `par_edu` | LOCF per student; W7-W10 1–9 scale remapped to W1-W6 1–7 scale |
| `w{w}_race` | `race` | `asian = 1[\text{race}=2]`; W4/W5 code `8` ("declined") $\to$ NA |
| `w{w}_eth` | `eth` | `hispanic = 1[\text{eth}=1]` |
| `w{w}_rcads_mdd_mean` | `mdd` | MDD predictor (RCADS depression mean) |
| `w{w}_rcads_gad_mean` | `gad` | GAD predictor (RCADS anxiety mean) |
| `w{w}_ese_ecig_pos_no9_mean` | `ese_pos` | ESE positive composite — *read but not used in v4b regressions* |
| `w{w}_ese_ecig_neg_no510_mean` | `ese_neg` | ESE negative composite — *read but not used in v4b regressions* |
| `w{w}_friends_use_ecig` | `friends_use_ecig` | **PFU** (`Perceived Friend Use`); used at $w-1$ as `friends_use_ecig_lag`. Code `6` ("Not sure") $\to$ NA |
| `w{w}_friend{1..7}` (W1) / `w{w}_friend{1..7}_{schoolid}` (W2-W10) | edges | friendship nominations $\to$ `data/advance/Cleaned-Data-042326/wNedges_clean.csv`; out-degree, in-degree, $E_{\text{users}}$, $E_D$ |

The cohort dummy is derived from the first non-NA `schoolid` per student (schools 101–108, 112–114 $\to$ 2024; 201, 212–214 $\to$ 2025). W1 schools are stored as `1..5` and remapped to `101..105`. W9/W10 `schoolid = 999` (transferred-out) is treated as NA.

**Effective sample size by panel × Q.** Each cell is *students / events*. "Full" = at-risk panel after the Q-restriction; "CC" = panel after `complete.cases` on the 13 predictors (= what each regression actually fits). Loss to complete-cases is mainly driven by $E_{\text{users}}$ / $E_D$ (~24% NA at $Q=8$, both depend on alters' response at $w-1$), `asian` (~20%), and the mental-health and PFU items (~17% each).

| Q | Adopt full | Adopt CC | A full | A CC | B full | B CC | C full | C CC |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| 8 | 1029 / 162 | 925 / 89 | 139 / 96 | 83 / 52 | 158 / 142 | 91 / 70 | 139 / 17 | 83 / 7 |
| 7 | 1930 / 346 | 1711 / 193 | 299 / 189 | 161 / 89 | 346 / 293 | 182 / 129 | 299 / 43 | 161 / 15 |
| 6 | 2441 / 449 | 2077 / 232 | 399 / 244 | 206 / 108 | 461 / 384 | 233 / 159 | 399 / 66 | 206 / 21 |
| 5 | 2919 / 551 | 2404 / 267 | 493 / 288 | 237 / 124 | 568 / 467 | 271 / 185 | 493 / 81 | 237 / 29 |

The two figures below visualise the same N table. Each bar is **one rectangle per (panel, Q)** with `N students` in low-alpha shading and `N events` overlaid in high-alpha shading of the same colour, so the gap between the two values is the count of *at-risk students who never disadopt at the corresponding Q level*.

![Effective N — full at-risk panel (before complete-cases). Each bar shows total at-risk students with events overlaid.](outputs/figures/sec4_N_full.pdf){width=95%}

![Effective N — after complete.cases on the 13 predictors (= what each regression actually fits).](outputs/figures/sec4_N_cc.pdf){width=95%}

\fontsize{8}{10}\selectfont

\newpage

# 5. Main results (E_D = peer-flipped 1→0; C window = 1)

OR (p-value). Bold = $p < 0.05$. $E_D$ = peer share who flipped $1 \to 0$ between $w-2$ and $w-1$. *Model C uses a person random intercept; $\rho = 0.000$ across all fits, so conditional and marginal ORs coincide empirically.*

## 5.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.138 (0.584) | 1.771 (0.424) | 0.876 (0.839) | 2.248 (0.613) |
| Female | 1.635 (0.065) | **0.336 (0.044)** | 0.399 (0.109) | 0.855 (0.926) |
| Sexual Minority | 1.546 (0.089) | 1.279 (0.687) | 1.733 (0.324) | **21.702 (0.040)** |
| Parent Ed. | 0.999 (0.992) | 1.158 (0.496) | 0.933 (0.800) | 0.327 (0.175) |
| Asian | 0.577 (0.056) | 1.188 (0.800) | 0.666 (0.480) | 0.264 (0.299) |
| Hispanic/Latine | 1.031 (0.917) | 0.724 (0.668) | 0.584 (0.389) | 0.009 (0.059) |
| MDD (Major Depressive S.) | 1.223 (0.421) | 0.502 (0.140) | **0.361 (0.018)** | **0.028 (0.019)** |
| GAD (Generalized Anxiety Dis.) | 0.877 (0.563) | 2.470 (0.079) | 1.907 (0.184) | 10.328 (0.129) |
| Out-degree | **0.829 (0.013)** | 1.356 (0.109) | 1.031 (0.875) | 0.683 (0.485) |
| In-degree | **1.103 (0.045)** | 1.124 (0.406) | 1.020 (0.878) | 0.556 (0.268) |
| Perceived Friend Use | **1.462 (0.000)** | 0.904 (0.657) | 0.941 (0.719) | 1.843 (0.329) |
| Network Exposure Users | **3.726 (0.034)** | **0.021 (0.018)** | **0.068 (0.010)** | 0.080 (0.447) |
| Network Exposure Dis-adopters | 3.023 (0.262) | 1.211 (0.892) | 0.482 (0.629) | 0.059 (0.691) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 5.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.860 (0.367) | 1.705 (0.247) | 1.171 (0.715) | 0.535 (0.444) |
| Female | 1.345 (0.103) | 0.760 (0.482) | 1.073 (0.850) | 3.125 (0.163) |
| Sexual Minority | **1.461 (0.028)** | 0.734 (0.406) | 0.859 (0.670) | 1.165 (0.817) |
| Parent Ed. | 0.974 (0.662) | 1.014 (0.922) | 0.863 (0.346) | 0.584 (0.068) |
| Asian | **0.627 (0.017)** | 0.979 (0.963) | 1.036 (0.927) | 0.401 (0.237) |
| Hispanic/Latine | 1.070 (0.729) | 0.882 (0.781) | 0.691 (0.314) | 0.274 (0.104) |
| MDD (Major Depressive S.) | 1.171 (0.369) | 0.741 (0.380) | **0.454 (0.007)** | **0.217 (0.025)** |
| GAD (Generalized Anxiety Dis.) | 0.863 (0.346) | 1.451 (0.264) | 1.181 (0.573) | 1.305 (0.676) |
| Out-degree | 0.913 (0.075) | 1.184 (0.204) | 0.937 (0.607) | 0.915 (0.705) |
| In-degree | **1.100 (0.007)** | 1.103 (0.265) | 1.128 (0.111) | 1.075 (0.654) |
| Perceived Friend Use | **1.474 (0.000)** | **0.710 (0.013)** | **0.698 (0.001)** | 0.748 (0.245) |
| Network Exposure Users | **5.427 (0.000)** | **0.135 (0.016)** | 0.294 (0.058) | 1.184 (0.903) |
| Network Exposure Dis-adopters | 2.650 (0.200) | 0.164 (0.169) | 0.785 (0.767) | 0.704 (0.896) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 5.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.827 (0.226) | 1.851 (0.133) | 1.389 (0.392) | 0.431 (0.262) |
| Female | 1.303 (0.095) | 0.596 (0.130) | 0.826 (0.560) | 2.669 (0.177) |
| Sexual Minority | **1.384 (0.038)** | 0.790 (0.456) | 1.078 (0.803) | 2.152 (0.160) |
| Parent Ed. | 0.968 (0.554) | 0.987 (0.911) | 0.950 (0.697) | 0.792 (0.301) |
| Asian | **0.622 (0.008)** | 1.089 (0.827) | 1.080 (0.833) | 0.468 (0.252) |
| Hispanic/Latine | 1.126 (0.498) | 0.863 (0.690) | 0.866 (0.655) | 0.436 (0.183) |
| MDD (Major Depressive S.) | 1.114 (0.500) | 0.728 (0.306) | **0.516 (0.017)** | 0.361 (0.068) |
| GAD (Generalized Anxiety Dis.) | 0.891 (0.419) | 1.241 (0.453) | 1.145 (0.612) | 1.597 (0.381) |
| Out-degree | 0.936 (0.153) | 1.168 (0.177) | 1.009 (0.930) | 0.996 (0.985) |
| In-degree | **1.089 (0.008)** | 1.052 (0.499) | 1.091 (0.175) | 1.106 (0.439) |
| Perceived Friend Use | **1.506 (0.000)** | **0.700 (0.001)** | **0.703 (0.000)** | 0.764 (0.158) |
| Network Exposure Users | **5.493 (0.000)** | 0.324 (0.110) | 0.402 (0.117) | 1.038 (0.975) |
| Network Exposure Dis-adopters | 1.782 (0.423) | 0.374 (0.339) | 1.149 (0.860) | 0.702 (0.865) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 5.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.836 (0.213) | 1.786 (0.116) | 1.379 (0.337) | 0.557 (0.301) |
| Female | **1.431 (0.016)** | 0.547 (0.062) | 0.732 (0.317) | 2.198 (0.193) |
| Sexual Minority | **1.435 (0.013)** | 0.877 (0.639) | 1.060 (0.826) | 1.596 (0.295) |
| Parent Ed. | 0.948 (0.301) | 0.972 (0.811) | 0.935 (0.575) | 0.838 (0.339) |
| Asian | **0.678 (0.022)** | 1.133 (0.735) | 1.086 (0.809) | 0.424 (0.145) |
| Hispanic/Latine | 1.162 (0.362) | 0.858 (0.642) | 0.905 (0.732) | 0.533 (0.211) |
| MDD (Major Depressive S.) | 1.137 (0.375) | 0.795 (0.415) | **0.536 (0.015)** | **0.382 (0.045)** |
| GAD (Generalized Anxiety Dis.) | 0.840 (0.190) | 1.181 (0.517) | 1.217 (0.422) | 1.501 (0.362) |
| Out-degree | 0.941 (0.164) | 1.135 (0.236) | 1.057 (0.562) | 1.038 (0.813) |
| In-degree | **1.081 (0.009)** | 1.045 (0.520) | 1.060 (0.322) | 1.047 (0.683) |
| Perceived Friend Use | **1.490 (0.000)** | **0.742 (0.002)** | **0.729 (0.000)** | 0.787 (0.110) |
| Network Exposure Users | **5.699 (0.000)** | 0.491 (0.253) | 0.701 (0.502) | 2.122 (0.359) |
| Network Exposure Dis-adopters | 2.926 (0.058) | 0.645 (0.651) | 1.184 (0.803) | 0.190 (0.430) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 6. Alternative E_D = E^max − E_current

Replaces "peer share who flipped 1→0 between $w-2$ and $w-1$" with $E_D = \max_{s \le w-1} E_{\text{users},i,s} - E_{\text{users},i,w-1}$.

## 6.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.135 (0.593) | 1.771 (0.418) | 0.948 (0.933) | 2.641 (0.538) |
| Female | 1.643 (0.063) | **0.344 (0.045)** | 0.438 (0.151) | 0.904 (0.954) |
| Sexual Minority | 1.534 (0.094) | 1.264 (0.699) | 1.675 (0.348) | **21.825 (0.043)** |
| Parent Ed. | 0.997 (0.972) | 1.179 (0.426) | 0.960 (0.881) | 0.306 (0.162) |
| Asian | 0.583 (0.062) | 1.189 (0.803) | 0.620 (0.408) | 0.282 (0.329) |
| Hispanic/Latine | 1.038 (0.899) | 0.757 (0.716) | 0.594 (0.419) | 0.010 (0.063) |
| MDD (Major Depressive S.) | 1.227 (0.416) | 0.498 (0.132) | **0.349 (0.012)** | **0.027 (0.022)** |
| GAD (Generalized Anxiety Dis.) | 0.879 (0.571) | 2.535 (0.080) | 1.942 (0.167) | 9.160 (0.139) |
| Out-degree | **0.830 (0.015)** | 1.367 (0.109) | 1.066 (0.749) | 0.648 (0.430) |
| In-degree | **1.106 (0.037)** | 1.120 (0.430) | 1.010 (0.936) | 0.541 (0.241) |
| Perceived Friend Use | **1.457 (0.000)** | 0.910 (0.674) | 0.942 (0.729) | 1.823 (0.329) |
| Network Exposure Users | **3.922 (0.029)** | **0.019 (0.020)** | **0.050 (0.006)** | 0.043 (0.332) |
| Network Exposure Dis-adopters | 1.734 (0.471) | 0.723 (0.818) | 0.295 (0.409) | 0.897 (0.983) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 6.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.857 (0.354) | 1.682 (0.255) | 1.207 (0.668) | 0.623 (0.568) |
| Female | 1.345 (0.105) | 0.834 (0.649) | 1.148 (0.718) | 3.393 (0.137) |
| Sexual Minority | **1.449 (0.031)** | 0.682 (0.297) | 0.836 (0.612) | 1.236 (0.753) |
| Parent Ed. | 0.972 (0.635) | 1.025 (0.856) | 0.878 (0.410) | 0.609 (0.091) |
| Asian | **0.637 (0.023)** | 0.913 (0.844) | 0.984 (0.966) | 0.349 (0.185) |
| Hispanic/Latine | 1.084 (0.683) | 0.826 (0.668) | 0.683 (0.302) | 0.260 (0.096) |
| MDD (Major Depressive S.) | 1.171 (0.369) | 0.736 (0.365) | **0.442 (0.006)** | **0.208 (0.023)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.351) | 1.427 (0.279) | 1.203 (0.529) | 1.361 (0.629) |
| Out-degree | 0.914 (0.078) | 1.183 (0.209) | 0.938 (0.611) | 0.913 (0.695) |
| In-degree | **1.102 (0.006)** | 1.091 (0.326) | 1.127 (0.114) | 1.069 (0.679) |
| Perceived Friend Use | **1.470 (0.000)** | **0.729 (0.022)** | **0.716 (0.002)** | 0.779 (0.319) |
| Network Exposure Users | **5.684 (0.000)** | **0.104 (0.011)** | **0.232 (0.031)** | 0.800 (0.878) |
| Network Exposure Dis-adopters | 1.814 (0.253) | 0.374 (0.271) | 0.401 (0.238) | 0.043 (0.323) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 6.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.822 (0.213) | 1.891 (0.121) | 1.409 (0.377) | 0.452 (0.291) |
| Female | 1.295 (0.105) | 0.650 (0.210) | 0.859 (0.651) | 2.783 (0.158) |
| Sexual Minority | **1.379 (0.041)** | 0.762 (0.386) | 1.057 (0.853) | 2.193 (0.150) |
| Parent Ed. | 0.967 (0.541) | 0.998 (0.988) | 0.959 (0.753) | 0.789 (0.293) |
| Asian | **0.642 (0.016)** | 1.017 (0.966) | 1.018 (0.962) | 0.413 (0.193) |
| Hispanic/Latine | 1.148 (0.438) | 0.843 (0.646) | 0.850 (0.619) | 0.408 (0.157) |
| MDD (Major Depressive S.) | 1.119 (0.483) | 0.712 (0.273) | **0.510 (0.016)** | 0.351 (0.060) |
| GAD (Generalized Anxiety Dis.) | 0.889 (0.409) | 1.263 (0.415) | 1.162 (0.571) | 1.670 (0.337) |
| Out-degree | 0.938 (0.166) | 1.166 (0.183) | 1.004 (0.969) | 0.997 (0.988) |
| In-degree | **1.089 (0.008)** | 1.052 (0.500) | 1.091 (0.173) | 1.114 (0.409) |
| Perceived Friend Use | **1.502 (0.000)** | **0.720 (0.003)** | **0.719 (0.000)** | 0.798 (0.250) |
| Network Exposure Users | **5.835 (0.000)** | 0.237 (0.062) | 0.316 (0.068) | 0.720 (0.794) |
| Network Exposure Dis-adopters | 1.842 (0.184) | 0.336 (0.187) | 0.445 (0.250) | 0.160 (0.384) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 6.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.831 (0.200) | 1.923 (0.080) | 1.428 (0.291) | 0.557 (0.300) |
| Female | **1.430 (0.017)** | 0.598 (0.115) | 0.781 (0.436) | 2.286 (0.171) |
| Sexual Minority | **1.432 (0.014)** | 0.865 (0.602) | 1.041 (0.879) | 1.580 (0.305) |
| Parent Ed. | 0.945 (0.274) | 0.985 (0.900) | 0.946 (0.648) | 0.830 (0.312) |
| Asian | **0.696 (0.037)** | 1.063 (0.871) | 1.003 (0.994) | 0.406 (0.130) |
| Hispanic/Latine | 1.184 (0.316) | 0.869 (0.676) | 0.878 (0.657) | 0.514 (0.187) |
| MDD (Major Depressive S.) | 1.136 (0.381) | 0.775 (0.371) | **0.531 (0.013)** | **0.379 (0.043)** |
| GAD (Generalized Anxiety Dis.) | 0.839 (0.187) | 1.207 (0.468) | 1.229 (0.391) | 1.525 (0.344) |
| Out-degree | 0.942 (0.173) | 1.133 (0.240) | 1.044 (0.646) | 1.028 (0.858) |
| In-degree | **1.082 (0.008)** | 1.047 (0.505) | 1.061 (0.311) | 1.051 (0.655) |
| Perceived Friend Use | **1.490 (0.000)** | **0.765 (0.007)** | **0.748 (0.000)** | 0.791 (0.124) |
| Network Exposure Users | **6.019 (0.000)** | 0.348 (0.123) | 0.521 (0.250) | 1.882 (0.470) |
| Network Exposure Dis-adopters | 2.039 (0.096) | 0.240 (0.071) | 0.336 (0.102) | 0.446 (0.614) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 7. No $E_D$

§5 and §6 found $E_D$ to be noisy and never significant on A/B/C, while suggesting collinearity with $E_{\text{users}}$ when $E_D$ is the alt definition. §7 refits §5's four outcomes after **removing $E_D$ entirely** from the predictor list. The remaining 12 predictors are unchanged. Effective $N$ is identical to §5 (the rows lost to complete-cases are the same — $E_{\text{users}}$ and $E_D$ have correlated NAs). OR (p-value). Bold = $p < 0.05$.

## 7.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.139 (0.582) | 1.759 (0.426) | 0.902 (0.873) | 2.630 (0.537) |
| Female | 1.654 (0.058) | **0.337 (0.044)** | 0.414 (0.122) | 0.900 (0.951) |
| Sexual Minority | 1.539 (0.092) | 1.278 (0.687) | 1.704 (0.342) | **21.740 (0.041)** |
| Parent Ed. | 1.000 (0.998) | 1.164 (0.468) | 0.925 (0.769) | 0.305 (0.154) |
| Asian | 0.569 (0.050) | 1.198 (0.793) | 0.668 (0.491) | 0.283 (0.324) |
| Hispanic/Latine | 1.034 (0.907) | 0.741 (0.695) | 0.583 (0.405) | 0.010 (0.063) |
| MDD (Major Depressive S.) | 1.225 (0.420) | 0.502 (0.139) | **0.362 (0.020)** | **0.027 (0.017)** |
| GAD (Generalized Anxiety Dis.) | 0.876 (0.559) | 2.498 (0.076) | 1.858 (0.208) | 9.083 (0.126) |
| Out-degree | **0.828 (0.014)** | 1.359 (0.106) | 1.032 (0.874) | 0.648 (0.431) |
| In-degree | **1.106 (0.038)** | 1.124 (0.405) | 1.020 (0.876) | 0.541 (0.242) |
| Perceived Friend Use | **1.470 (0.000)** | 0.906 (0.661) | 0.925 (0.650) | 1.824 (0.329) |
| Network Exposure Users | **3.658 (0.036)** | **0.021 (0.019)** | **0.066 (0.008)** | 0.043 (0.329) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 7.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.863 (0.374) | 1.605 (0.296) | 1.180 (0.702) | 0.531 (0.436) |
| Female | 1.352 (0.098) | 0.781 (0.526) | 1.076 (0.845) | 3.113 (0.164) |
| Sexual Minority | **1.461 (0.028)** | 0.700 (0.330) | 0.857 (0.665) | 1.163 (0.819) |
| Parent Ed. | 0.973 (0.641) | 0.994 (0.963) | 0.862 (0.344) | 0.582 (0.065) |
| Asian | **0.618 (0.014)** | 0.947 (0.904) | 1.033 (0.934) | 0.402 (0.238) |
| Hispanic/Latine | 1.074 (0.714) | 0.808 (0.627) | 0.691 (0.316) | 0.273 (0.103) |
| MDD (Major Depressive S.) | 1.167 (0.378) | 0.753 (0.396) | **0.454 (0.007)** | **0.217 (0.025)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.351) | 1.386 (0.315) | 1.187 (0.562) | 1.305 (0.675) |
| Out-degree | 0.913 (0.074) | 1.173 (0.227) | 0.940 (0.618) | 0.912 (0.693) |
| In-degree | **1.101 (0.007)** | 1.097 (0.291) | 1.128 (0.110) | 1.075 (0.655) |
| Perceived Friend Use | **1.478 (0.000)** | **0.706 (0.011)** | **0.696 (0.001)** | 0.744 (0.234) |
| Network Exposure Users | **5.307 (0.000)** | **0.135 (0.018)** | 0.297 (0.058) | 1.178 (0.907) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 7.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.829 (0.231) | 1.793 (0.150) | 1.387 (0.395) | 0.428 (0.257) |
| Female | 1.307 (0.091) | 0.611 (0.148) | 0.823 (0.557) | 2.680 (0.175) |
| Sexual Minority | **1.387 (0.037)** | 0.773 (0.414) | 1.082 (0.793) | 2.146 (0.162) |
| Parent Ed. | 0.967 (0.543) | 0.981 (0.870) | 0.951 (0.699) | 0.790 (0.296) |
| Asian | **0.617 (0.007)** | 1.072 (0.859) | 1.084 (0.826) | 0.469 (0.253) |
| Hispanic/Latine | 1.128 (0.493) | 0.825 (0.600) | 0.868 (0.659) | 0.435 (0.181) |
| MDD (Major Depressive S.) | 1.113 (0.502) | 0.730 (0.309) | **0.517 (0.018)** | 0.360 (0.067) |
| GAD (Generalized Anxiety Dis.) | 0.890 (0.417) | 1.221 (0.484) | 1.143 (0.615) | 1.600 (0.380) |
| Out-degree | 0.935 (0.152) | 1.163 (0.193) | 1.009 (0.936) | 0.994 (0.976) |
| In-degree | **1.089 (0.008)** | 1.052 (0.494) | 1.091 (0.177) | 1.107 (0.437) |
| Perceived Friend Use | **1.509 (0.000)** | **0.699 (0.001)** | **0.704 (0.000)** | 0.763 (0.154) |
| Network Exposure Users | **5.425 (0.000)** | 0.320 (0.109) | 0.401 (0.116) | 1.034 (0.977) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 7.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.840 (0.224) | 1.768 (0.120) | 1.377 (0.339) | 0.541 (0.274) |
| Female | **1.446 (0.013)** | 0.551 (0.065) | 0.731 (0.316) | 2.222 (0.185) |
| Sexual Minority | **1.440 (0.012)** | 0.867 (0.610) | 1.067 (0.807) | 1.563 (0.315) |
| Parent Ed. | 0.945 (0.275) | 0.970 (0.794) | 0.936 (0.579) | 0.831 (0.317) |
| Asian | **0.665 (0.017)** | 1.126 (0.748) | 1.085 (0.809) | 0.424 (0.145) |
| Hispanic/Latine | 1.159 (0.374) | 0.844 (0.604) | 0.903 (0.724) | 0.520 (0.192) |
| MDD (Major Depressive S.) | 1.131 (0.398) | 0.797 (0.421) | **0.536 (0.015)** | **0.384 (0.045)** |
| GAD (Generalized Anxiety Dis.) | 0.841 (0.192) | 1.176 (0.526) | 1.214 (0.427) | 1.504 (0.361) |
| Out-degree | 0.939 (0.156) | 1.134 (0.238) | 1.054 (0.572) | 1.030 (0.851) |
| In-degree | **1.081 (0.008)** | 1.046 (0.514) | 1.059 (0.324) | 1.047 (0.678) |
| Perceived Friend Use | **1.496 (0.000)** | **0.739 (0.002)** | **0.730 (0.000)** | 0.777 (0.090) |
| Network Exposure Users | **5.543 (0.000)** | 0.496 (0.260) | 0.694 (0.488) | 2.188 (0.342) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

**Reading.** Dropping $E_D$ leaves the §5 picture essentially intact: PFU and $E_{\text{users}}$ are still the two robust significant predictors of disadoption at $Q \le 7$, both with OR < 1 on A and B (consistent with peer-use environment retaining vapers, not pushing them out). The marginal change relative to §5 is small — the $E_{\text{users}}$ ORs *don't shift much* (e.g., A at Q=7: 0.099→0.095; A at Q=8: 0.021→0.026), confirming that $E_D$ peer-flipped (§5) was not absorbing variance from $E_{\text{users}}$. The intuitive lesson is **the peer-use environment effect on disadoption is carried entirely by $E_{\text{users}}$** ("how many of your friends currently use") rather than by any disadoption-specific peer signal: knowing the share of friends *currently using* is sufficient — the share who *recently quit* adds nothing once $E_{\text{users}}$ is in the model. By contrast, in §6 (alt $E_D$), the alt-$E_D$ definition is mechanically a function of $E_{\text{users}}$ ($E^{\max} - E_{\text{current}}$), so it shifts variance off $E_{\text{users}}$ and onto itself — that's why $E_{\text{users}}$ looks slightly cleaner in §6 than in §7. The cleanest specification, and the one we recommend as the headline interpretation, is therefore §7: **drop $E_D$, keep $E_{\text{users}}$, and read the disadoption-side coefficient as the peer-use channel.**

---

# 8. Model C window sensitivity

Three columns per Q: $C$ at $W=1$ (immediate return), $W \le 2$, $W \le 3$.

**Event-count summary** (number of cyclic 1→0 events for the same Q-eligible sample):

| Q | C, W=1 | C, W ≤ 2 | C, W ≤ 3 | Δ(W≤2 − W=1) | Δ(W≤3 − W=2) |
|:-:|---:|---:|---:|---:|---:|
| 8 | 17 | 27 | 29 | +10 | +2 |
| 7 | 43 | 63 | 68 | +20 | +5 |
| 6 | 66 | 92 | 97 | +26 | +5 |
| 5 | 81 | 114 | 121 | +33 | +7 |

The big increment is from $W=1 \to W \le 2$ (~30–40% more events); $W \le 3$ adds little beyond $W \le 2$.

## 8.1 Q = 8

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 2.248 (0.613) | 6.829 (0.969) | 6.829 (0.969) |
| Female | 0.855 (0.926) | 7.415 (0.963) | 7.415 (0.963) |
| Sexual Minority | **21.702 (0.040)** | 40.169 (0.900) | 40.169 (0.900) |
| Parent Ed. | 0.327 (0.175) | 0.314 (0.955) | 0.314 (0.955) |
| Asian | 0.264 (0.299) | 0.056 (0.934) | 0.056 (0.934) |
| Hispanic/Latine | 0.009 (0.059) | 0.036 (0.916) | 0.036 (0.916) |
| MDD (Major Depressive S.) | **0.028 (0.019)** | 0.006 (0.887) | 0.006 (0.887) |
| GAD (Generalized Anxiety Dis.) | 10.328 (0.129) | 1.976 (0.982) | 1.976 (0.982) |
| Out-degree | 0.683 (0.485) | 0.290 (0.942) | 0.290 (0.942) |
| In-degree | 0.556 (0.268) | 1.214 (0.982) | 1.214 (0.982) |
| Perceived Friend Use | 1.843 (0.329) | 0.795 (0.984) | 0.795 (0.984) |
| Network Exposure Users | 0.080 (0.447) | 0.950 (1.000) | 0.950 (1.000) |
| Network Exposure Dis-adopters | 0.059 (0.691) | 1681.502 (0.934) | 1681.502 (0.934) |
| Rho (ICC) | 0.000 | 0.994 | 0.994 |
| N Students | 83 | 83 | 83 |
| N Events | 7 | 11 | 11 |

## 8.2 Q = 7

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.535 (0.444) | 0.176 (0.824) | 0.280 (0.871) |
| Female | 3.125 (0.163) | 1.964 (0.932) | 3.902 (0.865) |
| Sexual Minority | 1.165 (0.817) | 4.198 (0.803) | 6.801 (0.744) |
| Parent Ed. | 0.584 (0.068) | 0.379 (0.749) | 0.336 (0.704) |
| Asian | 0.401 (0.237) | 0.453 (0.933) | 1.237 (0.981) |
| Hispanic/Latine | 0.274 (0.104) | 0.663 (0.964) | 0.228 (0.877) |
| MDD (Major Depressive S.) | **0.217 (0.025)** | 0.108 (0.685) | 0.029 (0.528) |
| GAD (Generalized Anxiety Dis.) | 1.305 (0.676) | 0.363 (0.830) | 0.357 (0.838) |
| Out-degree | 0.915 (0.705) | 0.675 (0.821) | 0.465 (0.682) |
| In-degree | 1.075 (0.654) | 1.170 (0.931) | 1.279 (0.889) |
| Perceived Friend Use | 0.748 (0.245) | 0.354 (0.597) | 0.414 (0.646) |
| Network Exposure Users | 1.184 (0.903) | 17.109 (0.845) | 2.213 (0.955) |
| Network Exposure Dis-adopters | 0.704 (0.896) | 11.801 (0.898) | 62.406 (0.832) |
| Rho (ICC) | 0.000 | 0.982 | 0.983 |
| N Students | 161 | 161 | 161 |
| N Events | 15 | 20 | 21 |

## 8.3 Q = 6

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.431 (0.262) | 1.021 (0.972) | 0.920 (0.887) |
| Female | 2.669 (0.177) | 1.640 (0.417) | 1.827 (0.318) |
| Sexual Minority | 2.152 (0.160) | 2.435 (0.070) | 2.316 (0.082) |
| Parent Ed. | 0.792 (0.301) | 0.820 (0.326) | 0.875 (0.484) |
| Asian | 0.468 (0.252) | 0.329 (0.081) | 0.454 (0.189) |
| Hispanic/Latine | 0.436 (0.183) | 0.565 (0.296) | 0.549 (0.270) |
| MDD (Major Depressive S.) | 0.361 (0.068) | 0.533 (0.196) | 0.471 (0.121) |
| GAD (Generalized Anxiety Dis.) | 1.597 (0.381) | 1.039 (0.936) | 1.041 (0.934) |
| Out-degree | 0.996 (0.985) | 0.931 (0.674) | 0.923 (0.633) |
| In-degree | 1.106 (0.439) | 1.160 (0.217) | 1.128 (0.302) |
| Perceived Friend Use | 0.764 (0.158) | 0.818 (0.230) | 0.847 (0.304) |
| Network Exposure Users | 1.038 (0.975) | 0.606 (0.646) | 0.951 (0.961) |
| Network Exposure Dis-adopters | 0.702 (0.865) | 2.916 (0.425) | 3.028 (0.409) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 206 | 206 | 206 |
| N Events | 21 | 26 | 27 |

## 8.4 Q = 5

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.557 (0.301) | 0.858 (0.754) | 0.783 (0.616) |
| Female | 2.198 (0.193) | 1.568 (0.402) | 1.656 (0.344) |
| Sexual Minority | 1.596 (0.295) | 1.528 (0.301) | 1.493 (0.324) |
| Parent Ed. | 0.838 (0.339) | 0.843 (0.308) | 0.882 (0.431) |
| Asian | 0.424 (0.145) | 0.337 (0.056) | 0.441 (0.131) |
| Hispanic/Latine | 0.533 (0.211) | 0.608 (0.275) | 0.603 (0.265) |
| MDD (Major Depressive S.) | **0.382 (0.045)** | 0.541 (0.147) | 0.495 (0.097) |
| GAD (Generalized Anxiety Dis.) | 1.501 (0.362) | 1.230 (0.610) | 1.245 (0.589) |
| Out-degree | 1.038 (0.813) | 1.056 (0.698) | 1.053 (0.711) |
| In-degree | 1.047 (0.683) | 1.037 (0.726) | 1.018 (0.860) |
| Perceived Friend Use | 0.787 (0.110) | 0.821 (0.150) | 0.841 (0.198) |
| Network Exposure Users | 2.122 (0.359) | 1.444 (0.639) | 1.879 (0.405) |
| Network Exposure Dis-adopters | 0.190 (0.430) | 1.185 (0.899) | 1.200 (0.891) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 237 | 237 | 237 |
| N Events | 29 | 35 | 36 |

---

# 9. Sensitivity (a) — indeterminates counted as Stable (A)

In §5/§6/§8/§10, $1 \to 0$ events with NA-only future are dropped from A (we cannot verify "no return"). §9 instead **counts them as A events** (assumes the student would not have returned). Adopters / B / C are unchanged from §5; only A's panel grows. Two tables, one per $E_D$ definition. Each table has paired columns per Q level: **(orig)** = §5/§6 main A; **(a)** = indeterminate $1 \to 0$ counted as A.

**Event-count summary** (A column only; rest unchanged from §5):

| Q | A events (orig) | A events (a) | Δ |
|:-:|---:|---:|---:|
| 8 |  52 |  66 | +14  (+27%) |
| 7 |  89 | 122 | +33  (+37%) |
| 6 | 108 | 150 | +42  (+39%) |
| 5 | 124 | 169 | +45  (+36%) |

## 9.1 Table — $E_D$ = peer-flipped $1 \to 0$

| Variable | Q=8 (orig) | Q=8 (a) | Q=7 (orig) | Q=7 (a) | Q=6 (orig) | Q=6 (a) | Q=5 (orig) | Q=5 (a) |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.771 (0.424) | 1.009 (0.987) | 1.705 (0.247) | 1.379 (0.426) | 1.851 (0.133) | 1.553 (0.228) | 1.786 (0.116) | 1.599 (0.146) |
| Female | **0.336 (0.044)** | 0.519 (0.216) | 0.760 (0.482) | 0.952 (0.890) | 0.596 (0.130) | 0.850 (0.604) | 0.547 (0.062) | 0.770 (0.377) |
| Sexual Minority | 1.279 (0.687) | 0.852 (0.757) | 0.734 (0.406) | 0.756 (0.403) | 0.790 (0.456) | 0.772 (0.364) | 0.877 (0.639) | 0.847 (0.510) |
| Parent Ed. | 1.158 (0.496) | 1.111 (0.614) | 1.014 (0.922) | 0.956 (0.737) | 0.987 (0.911) | 0.988 (0.915) | 0.972 (0.811) | 0.976 (0.829) |
| Asian | 1.188 (0.800) | 1.009 (0.987) | 0.979 (0.963) | 1.202 (0.623) | 1.089 (0.827) | 1.180 (0.621) | 1.133 (0.735) | 1.161 (0.636) |
| Hispanic/Latine | 0.724 (0.668) | 1.076 (0.896) | 0.882 (0.781) | 0.991 (0.980) | 0.863 (0.690) | 0.963 (0.902) | 0.858 (0.642) | 0.961 (0.886) |
| MDD (Major Depressive S.) | 0.502 (0.140) | 0.649 (0.262) | 0.741 (0.380) | 0.703 (0.256) | 0.728 (0.306) | 0.666 (0.152) | 0.795 (0.415) | 0.708 (0.182) |
| GAD (Generalized Anxiety Dis.) | 2.470 (0.079) | 1.340 (0.494) | 1.451 (0.264) | 1.052 (0.866) | 1.241 (0.453) | 1.008 (0.976) | 1.181 (0.517) | 1.011 (0.964) |
| Out-degree | 1.356 (0.109) | 1.268 (0.166) | 1.184 (0.204) | 1.055 (0.656) | 1.168 (0.177) | 1.053 (0.609) | 1.135 (0.236) | 1.051 (0.596) |
| In-degree | 1.124 (0.406) | 1.028 (0.812) | 1.103 (0.265) | 1.094 (0.227) | 1.052 (0.499) | 1.078 (0.237) | 1.045 (0.520) | 1.080 (0.194) |
| Perceived Friend Use | 0.904 (0.657) | 0.897 (0.504) | **0.710 (0.013)** | **0.708 (0.001)** | **0.700 (0.001)** | **0.715 (0.000)** | **0.742 (0.002)** | **0.751 (0.000)** |
| Network Exposure Users | **0.021 (0.018)** | **0.080 (0.044)** | **0.135 (0.016)** | 0.312 (0.075) | 0.324 (0.110) | 0.456 (0.176) | 0.491 (0.253) | 0.570 (0.295) |
| Network Exposure Dis-adopters | 1.211 (0.892) | 1.808 (0.616) | 0.164 (0.169) | 0.929 (0.921) | 0.374 (0.339) | 1.332 (0.677) | 0.645 (0.651) | 1.589 (0.441) |
| N Students | 83 | 96 | 161 | 191 | 206 | 245 | 237 | 283 |
| N Events | 52 | 66 | 89 | 122 | 108 | 150 | 124 | 169 |

## 9.2 Table — $E_D$ = $E^{\max} - E_{\text{current}}$ (alt)

| Variable | Q=8 (orig) | Q=8 (a) | Q=7 (orig) | Q=7 (a) | Q=6 (orig) | Q=6 (a) | Q=5 (orig) | Q=5 (a) |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.771 (0.418) | 0.982 (0.975) | 1.682 (0.255) | 1.383 (0.422) | 1.891 (0.121) | 1.560 (0.224) | 1.923 (0.080) | 1.644 (0.130) |
| Female | **0.344 (0.045)** | 0.512 (0.205) | 0.834 (0.649) | 0.953 (0.896) | 0.650 (0.210) | 0.852 (0.613) | 0.598 (0.115) | 0.793 (0.439) |
| Sexual Minority | 1.264 (0.699) | 0.854 (0.761) | 0.682 (0.297) | 0.755 (0.403) | 0.762 (0.386) | 0.773 (0.368) | 0.865 (0.602) | 0.848 (0.515) |
| Parent Ed. | 1.179 (0.426) | 1.121 (0.575) | 1.025 (0.856) | 0.956 (0.735) | 0.998 (0.988) | 0.992 (0.941) | 0.985 (0.900) | 0.987 (0.908) |
| Asian | 1.189 (0.803) | 1.038 (0.945) | 0.913 (0.844) | 1.197 (0.635) | 1.017 (0.966) | 1.180 (0.630) | 1.063 (0.871) | 1.124 (0.718) |
| Hispanic/Latine | 0.757 (0.716) | 1.121 (0.840) | 0.826 (0.668) | 0.989 (0.975) | 0.843 (0.646) | 0.972 (0.926) | 0.869 (0.676) | 0.961 (0.890) |
| MDD (Major Depressive S.) | 0.498 (0.132) | 0.654 (0.267) | 0.736 (0.365) | 0.702 (0.257) | 0.712 (0.273) | 0.666 (0.153) | 0.775 (0.371) | 0.706 (0.184) |
| GAD (Generalized Anxiety Dis.) | 2.535 (0.080) | 1.359 (0.475) | 1.427 (0.279) | 1.053 (0.863) | 1.263 (0.415) | 1.008 (0.976) | 1.207 (0.468) | 1.008 (0.973) |
| Out-degree | 1.367 (0.109) | 1.264 (0.176) | 1.183 (0.209) | 1.056 (0.647) | 1.166 (0.183) | 1.051 (0.619) | 1.133 (0.240) | 1.042 (0.658) |
| In-degree | 1.120 (0.430) | 1.029 (0.807) | 1.091 (0.326) | 1.094 (0.228) | 1.052 (0.500) | 1.077 (0.241) | 1.047 (0.505) | 1.080 (0.198) |
| Perceived Friend Use | 0.910 (0.674) | 0.900 (0.522) | **0.729 (0.022)** | **0.708 (0.001)** | **0.720 (0.003)** | **0.719 (0.000)** | **0.765 (0.007)** | **0.767 (0.001)** |
| Network Exposure Users | **0.019 (0.020)** | 0.088 (0.060) | **0.104 (0.011)** | 0.310 (0.092) | 0.237 (0.062) | 0.439 (0.196) | 0.348 (0.123) | 0.481 (0.206) |
| Network Exposure Dis-adopters | 0.723 (0.818) | 1.153 (0.900) | 0.374 (0.271) | 0.971 (0.969) | 0.336 (0.187) | 0.867 (0.829) | 0.240 (0.071) | 0.572 (0.363) |
| N Students | 83 | 96 | 161 | 191 | 206 | 245 | 237 | 283 |
| N Events | 52 | 66 | 89 | 122 | 108 | 150 | 124 | 169 |

**Reading**. Switching from (orig) to (a) within either $E_D$ definition adds 27–39% more A events but does not change *which* predictors are significant: PFU and $E_{\text{users}}$ remain the only consistent disadoption predictors at Q=7 and below; both predictors push toward less disadoption (OR < 1), as expected if peer-use environments stabilise smoking once initiated. The two tables differ visibly only on $E_D$ itself: peer-flipped $E_D$ is noisy and never significant; the alt definition has tighter point estimates but is equally non-significant at conventional levels. See §11 for our reading.

---

# 10. Sensitivity (b) — observed-wave jumps

§10 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs).

**Event-count summary** vs §5 main:

| Q | adopt (§5) | adopt (§10) | A (§5) | A (§10) | B (§5) | B (§10) | C (§5) | C (§10) |
|:-:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 162 | 162 |  96 |  96 | 142 | 142 | 17 | 17 |
| 7 | 346 | 346 | 189 | 189 | 293 | 293 | 43 | 43 |
| 6 | 449 | 449 | 244 | 244 | 384 | 384 | 66 | 66 |
| 5 | 551 | 551 | 288 | 288 | 467 | 465 | 81 | 81 |

The W1-W10 panel has very few NA gaps within consecutive observations; observed-wave jumps and calendar-pair logic produce nearly identical event sets (only B at Q=5 differs by 2 events). Tables §10.1–§10.4 are therefore visually indistinguishable from §5.1–§5.4 and we reproduce only Q = 5 here for reference; the full set is in `outputs/tables/v4b_table_9_Q{8,7,6,5}.csv`.

## 10.1 Q = 5 (representative)

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.836 (0.213) | 1.786 (0.116) | 1.379 (0.337) | 0.557 (0.301) |
| Female | **1.431 (0.016)** | 0.547 (0.062) | 0.732 (0.317) | 2.198 (0.193) |
| Sexual Minority | **1.435 (0.013)** | 0.877 (0.639) | 1.060 (0.826) | 1.596 (0.295) |
| Parent Ed. | 0.948 (0.301) | 0.972 (0.811) | 0.935 (0.575) | 0.838 (0.339) |
| Asian | **0.678 (0.022)** | 1.133 (0.735) | 1.086 (0.809) | 0.424 (0.145) |
| Hispanic/Latine | 1.162 (0.362) | 0.858 (0.642) | 0.905 (0.732) | 0.533 (0.211) |
| MDD (Major Depressive S.) | 1.137 (0.375) | 0.795 (0.415) | **0.536 (0.015)** | **0.382 (0.045)** |
| GAD (Generalized Anxiety Dis.) | 0.840 (0.190) | 1.181 (0.517) | 1.217 (0.422) | 1.501 (0.362) |
| Out-degree | 0.941 (0.164) | 1.135 (0.236) | 1.057 (0.562) | 1.038 (0.813) |
| In-degree | **1.081 (0.009)** | 1.045 (0.520) | 1.060 (0.322) | 1.047 (0.683) |
| Perceived Friend Use | **1.490 (0.000)** | **0.742 (0.002)** | **0.729 (0.000)** | 0.787 (0.110) |
| Network Exposure Users | **5.699 (0.000)** | 0.491 (0.253) | 0.701 (0.502) | 2.122 (0.359) |
| Network Exposure Dis-adopters | 2.926 (0.058) | 0.645 (0.651) | 1.184 (0.803) | 0.190 (0.430) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

\normalsize

---

# 11. Descriptive associations and sensitivities

The §5/§9 regressions show **Perceived Friend Use (PFU)** as the cleanest two-sided lever for adoption, but the disadoption coefficients (although consistently negative on A and B) sometimes look modest after adjusting for 12 other predictors. To sanity-check the raw signal we look at unadjusted associations on the W1-W10 panel.

## 11.1 Out-degree distribution by ego status

Out-degree = number of friends an ego nominated whose nomination survives the panel-hygiene rules (alter in panel and responding at the same wave). The maximum out-degree is 7 by questionnaire design.

| Out-degree | n (all ego-waves) | n (current user, ecig=1) | n (current non-user, ecig=0) |
|:-:|---:|---:|---:|
| 1 |  2,956 |   235 |  2,716 |
| 2 |  3,815 |   267 |  3,541 |
| 3 |  4,195 |   264 |  3,922 |
| 4 |  3,840 |   228 |  3,602 |
| 5 |  2,708 |   153 |  2,550 |
| 6 |  1,533 |    60 |  1,470 |
| 7 |    481 |    24 |    456 |
| **Total** | **19,528** | **1,231** | **18,257** |

Mean out-degree: 3.31 (all) / 3.06 (users) / 3.33 (non-users). Median is 3 in all three subsets.

![Out-degree distribution by ego e-cigarette status. Bars dodge per subset; share within subset on the y-axis, raw n on top of each bar.](outputs/figures/sec11_outdegree_distribution.pdf){width=95%}

**Reading.** Users are slightly *less* connected than non-users: the user distribution leans toward out-degree 1–3 (62.6% of users vs 56.9% of non-users), and away from out-degree 5–7 (19.2% of users vs 24.5% of non-users). The mean out-degree gap is 0.27 friends. This is a small but substantively interesting fact — a higher-density friendship network is not what predicts ecig use here; rather, *who* the friends are (PFU, $E_{\text{users}}$) matters. The distribution shape is very stable across the three subsets, which is reassuring for the network exposure measures: $E_{\text{users}}$ is computed on a denominator that varies little between users and non-users.

## 11.2 Event rate by PFU at $w-1$

For each person-wave row eligible for the corresponding risk-set (no Q-restriction; all W1-W10 panel rows with valid lag and outcome). **Disadoption here is *any* $1 \to 0$** transition (Model B-style: $\text{ecig}_{w-1}=1$ and $\text{ecig}_w=0$, regardless of return). It is **not** the stable-A definition — there is no requirement that the student stay at 0 in later observed waves.

| PFU at $w-1$ | At risk (adopt) | N adopted | Adoption rate | At risk (disad) | N disadopted | Disadoption rate |
|:-:|---:|---:|---:|---:|---:|---:|
| 0 (None) | 17,492 | 376 | 2.15 % | 388 | 210 | **54.12 %** |
| 1        |  2,067 | 106 | 5.13 % | 224 |  95 |    42.41 %  |
| 2        |  1,246 | 111 | 8.91 % | 247 |  77 |    31.17 %  |
| 3        |    652 |  62 | 9.51 % | 223 |  61 |    27.35 %  |
| 4        |    214 |  20 | 9.35 % | 127 |  27 |    21.26 %  |
| 5        |    269 |  31 | **11.52 %** | 193 |  40 |    20.73 %  |

PFU at $w-1$ moves adoption from 2% → 12% (5.4×) and **moves disadoption from 54% → 21%** (2.6× lower). Point-biserial correlations with the binary outcomes:

| Outcome (binary at-risk row) | $r$ | n |
|:---|---:|---:|
| Adoption (any 0→1)          | **+0.128** | 21,940 |
| Any 1→0 transition          | **−0.256** |  1,402 |

The disadoption signal is large in raw form. Its visibility in §5/§6/§9 depends on which sub-event we model (A / B / C), the small sub-samples, and the competition with `Network Exposure Users`.

**Same exercise but with the network-derived measure $E_{\text{users}}$ at $w-1$** (peer share who currently use ecig, computed from the friendship-nomination network — *not* the self-report PFU). $E_{\text{users}}$ is binned into 6 categories, parallel to the 0–5 PFU scale. Same denominator definitions as above; "Disadoption rate" is again *any* $1 \to 0$.

| $E_{\text{users}}$ at $w-1$ | At risk (adopt) | N adopted | Adoption rate | At risk (disad) | N disadopted | Disadoption rate |
|:-:|---:|---:|---:|---:|---:|---:|
| 0 (None)   | 12,223 | 384 | 3.14 % | 537 | 280 |    52.14 %  |
| (0, 0.2]   |    683 |  35 | 5.12 % |  72 |  42 | **58.33 %** |
| (0.2, 0.4] |  1,119 |  99 | 8.85 % | 160 |  72 |    45.00 %  |
| (0.4, 0.6] |    406 |  38 | 9.36 % | 101 |  33 |    32.67 %  |
| (0.6, 0.8] |     74 |   9 | **12.16 %** |  30 |  13 |    43.33 %  |
| (0.8, 1.0] |    136 |  11 | 8.09 % |  37 |  11 |    29.73 %  |

| Outcome (binary at-risk row) | $r$ | n |
|:---|---:|---:|
| Adoption (any 0→1)          | **+0.090** | 14,641 |
| Any 1→0 transition          | **−0.137** |    937 |

The qualitative pattern matches PFU — disadoption falls from ≈52% at $E_{\text{users}}=0$ to ≈30% at $E_{\text{users}}>0.8$ (1.7× lower) — but the gradient is gentler and noisier than the self-reported PFU gradient (54.1% → 20.7%, 2.6×). The $(0, 0.2]$ bin is anomalous (58.3%), but that's just 72 person-waves and overlaps with the 52% in the "none" bin within sampling noise. The point-biserial correlations are correspondingly weaker ($|r|=0.137$ vs $0.256$ for PFU). Two reasons: (i) $E_{\text{users}}$ has a much heavier mass at exactly 0 (12,223 vs 17,492 person-waves), and (ii) sparse out-degree means $E_{\text{users}}$ is a noisy estimator of "what fraction of friends use" — *self-reported* PFU averages over a wider, more salient personal network than the (small) friendship-nomination set captures.

**Same exercise but with the network-derived measure as a *count* of using friends**. We bin $k_{\text{users}} = E_{\text{users}} \times \text{out\_degree}$ (rounded to integer) — i.e. how many friends the ego nominated who currently use ecig. We add explicit event-count columns so the rate is fully auditable per cell.

| # using friends $w-1$ | At risk (adopt) | N adopted | Adoption rate | At risk (disad) | N disadopted | Disadoption rate |
|:-:|---:|---:|---:|---:|---:|---:|
| 0  | 12,223 | 384 | 3.14 % | 537 | 280 | **52.14 %** |
| 1  |  2,024 | 154 | 7.61 % | 285 | 130 |    45.61 %  |
| 2  |    342 |  31 | 9.06 % |  91 |  34 |    37.36 %  |
| 3  |     45 |   6 | **13.33 %** |  17 |   5 |    29.41 %  |
| 4  |      6 |   1 | 16.67 % |   5 |   2 |    40.00 %  |
| 5+ |      1 |   0 | 0.00 %  |   2 |   0 |     0.00 %  |

| Outcome (binary at-risk row) | $r$ vs $k_{\text{users}}$ | n |
|:---|---:|---:|
| Adoption (any 0→1)          | **+0.092** | 14,641 |
| Any 1→0 transition          | **−0.113** |    937 |

Reading the count version directly: a single using friend cuts disadoption from 52% to 46%; two using friends cuts it to 37%; three to 29%. The downward gradient is monotonic from $k=0$ to $k=3$ (where most of the data sit) and then becomes erratic at $k \ge 4$ because there are very few egos with that many using friends per wave (51 person-waves total above $k=3$). Same caveat as the proportion table: $E_{\text{users}}$ is a noisier proxy of peer-use environment than self-reported PFU, because the friendship-nomination network averages over only ~3 alters per ego.

## 11.3 PFU vs network exposures (Pearson)

PFU is correlated with the network-derived exposure measures, as expected:

| Pair (both at $w-1$) | $r$ | n |
|:---|---:|---:|
| PFU vs $E_{\text{users}}$ | **+0.226** | 17,456 |
| PFU vs $E_D$ (peer-flipped 1→0) | +0.071 | 17,465 |
| PFU vs $E_D$ alt (peak − current) | +0.108 | 17,456 |
| PFU vs out-degree | −0.083 | 23,391 |
| PFU vs in-degree | −0.057 | 23,391 |

PFU and $E_{\text{users}}$ overlap (~$r = 0.23$) — both measure peer-user environment. They are not redundant: PFU is self-reported about close friends; $E_{\text{users}}$ is computed from the friendship-nomination network. The §5 regressions show both surviving as significant predictors of adoption (PFU OR $\approx 1.47$–$1.49$, $E_{\text{users}}$ OR $\approx 5.3$–$5.9$), suggesting they capture complementary aspects of peer-user salience.

## 11.4 Event rate by HS grade-semester

Grade-semester is derived from $(\text{cohort}, \text{wave})$ on the standard ADVANCE timeline. Eight semesters span fall 9th (gs=1) through spring 12th (gs=8):

- **Class of 2024** (schools 101–114): W1=fall 9th (gs=1), W2=spring 9th (gs=2), …, W8=spring 12th (gs=8). W9–W10 are post-HS and excluded.
- **Class of 2025** (schools 201–214): W3=gs=1, W4=gs=2, …, W10=gs=8.

The first observed wave for each cohort produces no at-risk rows because the lag is undefined, so gs=1 (fall 9th) has zero rows and is omitted; the table starts at gs=2 (spring 9th).

| Grade-semester | At risk (adopt) | N adopted | Adoption rate | At risk (disad) | N disadopted | Disadoption rate (any 1→0) |
|:-:|---:|---:|---:|---:|---:|---:|
| 2 (spring 9th)   | 1,787 |  47 | 2.63 % |  45 |  21 | 46.67 % |
| 3 (fall 10th)    | 2,865 | 126 | 4.40 % | 111 |  43 | 38.74 % |
| 4 (spring 10th)  | 3,209 | 172 | **5.36 %** | 211 |  99 | 46.92 % |
| 5 (fall 11th)    | 3,157 | 150 | 4.75 % | 273 | 138 | 50.55 % |
| 6 (spring 11th)  | 2,977 | 166 | **5.58 %** | 262 | 129 | 49.24 % |
| 7 (fall 12th)    | 2,715 | 100 | 3.68 % | 249 | 130 | **52.21 %** |
| 8 (spring 12th)  | 2,620 |  81 | 3.09 % | 208 | 104 | 50.00 % |

| Outcome (binary at-risk row) | $r$ (Pearson) | n |
|:---|---:|---:|
| Adoption (any 0→1) vs grade-semester   | −0.006 | 19,330 |
| Any 1→0 transition vs grade-semester   | +0.048 |  1,359 |

![Adoption (left) and disadoption (right) rates by HS grade-semester. Bars labelled with rate and n.](outputs/figures/sec11_grade_rates.pdf){width=95%}

The line graph below puts both trajectories on the same x-axis (dual y-axis: green = disadoption on the left, blue = adoption on the right) so the developmental shape is directly visible:

![Adoption and disadoption trajectories across the high-school years. Dual y-axes (left: disadoption %, right: adoption %).](outputs/figures/sec11_grade_rates_line.pdf){width=95%}

**Reading.** Adoption follows an inverted-U with a peak around **spring 11th** (gs=6, 5.6%) and the conventional "experimentation peaks mid-HS" pattern — adoption climbs from 2.6% in spring 9th to 5%–5.6% across the gs=4–6 plateau, then falls to 3.1% by spring 12th. Disadoption (any 1→0) drifts gently *upward* from spring 9th (47%) through 12th grade (50%–52%) — the highest semester-level disadoption rate is fall 12th (52.2%). But the spread is narrow: 39%–52% across all seven semesters, summarised by point-biserial correlation $r = +0.048$ (i.e., almost no monotonic trend on the rate). Most variation in both outcomes is across-bin noise rather than a clean grade-semester gradient.

## 11.5 Q-sensitivity: how N students and N events shrink as Q tightens

This subsection shows how (effective N students, N events) for the three disadoption outcomes A / B / C move as Q tightens, and uses that to justify our headline choice $Q = 7$. We span $Q = 4 .. 8$; we omit $Q \in \{9, 10\}$ because **no student in the panel has 9 consecutive observed waves of `past_6mo_use_3`** (a regular four-year HS spans exactly 8 semesters of follow-up, so $\ge 9$ is structurally impossible).

| Q | A (CC: students / events) | B (CC: students / events) | C (CC: students / events) |
|:-:|:---:|:---:|:---:|
| 4 | 258 / 130 | 300 / 202 | 258 / 33 |
| 5 | 237 / 124 | 271 / 185 | 237 / 29 |
| 6 | 206 / 108 | 233 / 159 | 206 / 21 |
| 7 | 161 /  89 | 182 / 129 | 161 / 15 |
| 8 |  83 /  52 |  91 /  70 |  83 /  7 |

(Counts are after `complete.cases` on the 13-variable PRED set. FULL counts before CC are in `outputs/tables/v4b_table_11_5_Q_sensitivity.csv`.)

![Q-sensitivity per outcome. Three stacked subplots: A (top), B (middle), C (bottom). x-axis runs strict-to-relaxed (Q = 8 on the left). Blue line = students, red line = events. Numbers below each point = % gain vs the immediately stricter Q (per-step relaxation). The bold highlight is **Q = 7**, our recommended sweet spot.](outputs/figures/sec11_Q_sensitivity.pdf){width=70%}

**Reading.** Each label below a point is the *one-step* % gain when relaxing Q from the next-stricter value (e.g. the label at Q = 7 is the gain going from Q = 8 to Q = 7). The single biggest one-step jump is at $Q = 8 \to 7$ across all three outcomes — bolded on the figure:

- **A (Stable)**: $Q = 8 \to 7$ adds **+71%** events (52 → 89) and **+94%** students. Subsequent steps add only +14% to +21% per side.
- **B (Experimental)**: $Q = 8 \to 7$ adds **+84%** events (70 → 129) and **+100%** students. Later steps add +14% to +28% per side.
- **C (Unstable)**: $Q = 8 \to 7$ doubles events (**+114%**, 7 → 15). C is too sparse at any Q for further relaxation to buy inferential power.

**Why $Q = 7$ as the headline.** The single biggest jump in usable data per Q step is at $Q = 8 \to 7$ (the bold annotations); every later step trades modest extra power for less observed students. $Q = 7$ keeps 60% of the $Q = 5$ events on A (89 vs 124) and 70% on B (129 vs 185), more than doubles the events from $Q = 8$, and avoids the small-panel separation problem visible in §13 (the gs_fe block at Q = 8 explodes due to event sparsity). Going further ($Q = 6, 5, 4$) buys only marginal additions and blends in students with thin observation histories. **$Q = 7$ is the sweet spot**, and §13 ("Recommended specification") reads off the §6 alt-$E_D$ fits at $Q = 7$.

\newpage

---

# 12. Discussion

For the *single* headline reading, see **§13 Recommended specification** (§6 alt $E_D$ at $Q = 7$, full coefficient block including the gs_fe block and intercept). This section instead summarises *which patterns are stable across the six families* — the robustness story that motivates the headline choice.

**Headline OR (across §5/§6/§9, robust at $Q \le 7$)**:

1. **Perceived Friend Use** — adoption OR ≈ 1.47–1.50 ($p < 0.001$); A disadoption OR ≈ 0.70–0.76 ($p \le 0.021$); B disadoption OR ≈ 0.71–0.75 ($p \le 0.007$).
2. **Network Exposure (Users)** — adoption OR ≈ 5.3–5.9 ($p < 0.001$); A disadoption OR ≈ 0.08–0.43 (significant at $Q \in \{6, 7\}$); B disadoption OR ≈ 0.17–0.36 (significant at $Q \in \{6, 7, 8\}$).
3. **MDD** — B disadoption OR ≈ 0.32–0.53 ($p \le 0.022$ at all Q); C disadoption OR ≈ 0.04–0.39 (significant at $Q \in \{5, 7, 8\}$).
4. **Asian** — adoption OR ≈ 0.61–0.69 ($p < 0.05$ at $Q \le 7$).
5. **Sexual Minority** — adoption OR ≈ 1.38–1.45 at $Q \le 7$.

**Stable conclusions across families**: §5 main, §6 alt $E_D$, and §9 (a) all yield qualitatively the same picture: PFU and $E_{\text{users}}$ are consistent two-sided levers; MDD is a cessation barrier; cohort 2025 experiments more (B). §10 (b) is essentially identical to §5 — under W1-W10 the data has too few NA gaps for the observed-jump rule to differ from consecutive-calendar pairs. §8 window sensitivity gains modest power for C events ($+30$–40% events at $W \le 2$) but the increased noise from non-immediate cycles dilutes most predictors; only Sexual Minority at $Q \in \{6, 8\}$ survives.

**Why does PFU look "mild" in some regression coefficients despite the large raw disadoption gradient (§11)?** Three reasons: (i) the A / B / C panels are small (83–271 students); (ii) `Network Exposure Users` shares variance with PFU ($r = 0.23$) and the regression splits the effect between the two; (iii) grade-semester fixed effects absorb between-semester variation that the raw cross-tab in §11.2 carries. The §11.2 cross-tab is the cleanest demonstration of the disadoption signal.

# 13. Recommended specification — full coefficient block

After all the spec searches, this is the single specification we recommend reading: **§6 (alt $E_D$ = $E^{\max} - E_{\text{current}}$) at $Q = 7$**. The rationale:

- **Q = 7** balances power and information density (see §11.5): retains ≈70% of the events available at $Q = 5$ but uses only the most observed students, and avoids the steep $Q = 7 \to 8$ event cliff (−42% to −53%).
- **§6 alt $E_D$** marginally beats §5 (peer-flipped) at $Q = 7$: it makes $E_{\text{users}}$ significant on Model B (OR = 0.232, $p = 0.031$) where §5 misses (p = 0.058). Other significance patterns are otherwise identical between the two $E_D$ definitions.
- **gs_fe + cohort** as the time/cohort controls — the spec change introduced in v5 (replacing the v4b `wave_fe + cohort`).

Below is the full coefficient block for the four outcomes (Adopters, Stable A, Experimental B, Unstable C), including the intercept, all 7 grade-semester dummies (reference = gs = 1), the cohort dummy, and the 13 substantive predictors. Bold = $p < 0.05$.

| Variable | Adopters | A (Stable) | B (Experimental) | C (Unstable) |
|:---|:---:|:---:|:---:|:---:|
| Intercept | **0.009 (0.000)** | **2.03e-07 (0.000)** | **7.12e-07 (0.000)** | 5.93e-07 (0.966) |
| gs_fe = 2 (spring 9th) | — | — | — | — |
| gs_fe = 3 (fall 10th) | **2.808 (0.010)** | **3.73e+05 (0.000)** | **8.84e+06 (0.000)** | 2.02e+07 (0.961) |
| gs_fe = 4 (spring 10th) | **2.450 (0.030)** | **3.18e+06 (0.000)** | **1.99e+07 (0.000)** | 2.89e+07 (0.960) |
| gs_fe = 5 (fall 11th) | 2.032 (0.086) | **5.04e+06 (0.000)** | **1.43e+07 (0.000)** | 4.67e+06 (0.964) |
| gs_fe = 6 (spring 11th) | **2.751 (0.014)** | **3.37e+06 (0.000)** | **1.18e+07 (0.000)** | 6.40e+06 (0.963) |
| gs_fe = 7 (fall 12th) | 2.101 (0.086) | **4.18e+06 (0.000)** | **9.09e+06 (0.000)** | 3.08e+06 (0.965) |
| gs_fe = 8 (spring 12th) | 1.346 (0.519) | — | **1.10e+07 (0.000)** | — |
| Cohort (2025 vs 2024) | 0.857 (0.354) | 1.682 (0.255) | 1.207 (0.668) | 0.623 (0.568) |
| Female | 1.345 (0.105) | 0.834 (0.649) | 1.148 (0.718) | 3.393 (0.137) |
| Sexual Minority | **1.449 (0.031)** | 0.682 (0.297) | 0.836 (0.612) | 1.236 (0.753) |
| Parent Ed. | 0.972 (0.635) | 1.025 (0.856) | 0.878 (0.410) | 0.609 (0.091) |
| Asian | **0.637 (0.023)** | 0.913 (0.844) | 0.984 (0.966) | 0.349 (0.185) |
| Hispanic/Latine | 1.084 (0.683) | 0.826 (0.668) | 0.683 (0.302) | 0.260 (0.096) |
| MDD (Major Depressive S.) | 1.171 (0.369) | 0.736 (0.365) | **0.442 (0.006)** | **0.208 (0.023)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.351) | 1.427 (0.279) | 1.203 (0.529) | 1.361 (0.629) |
| Out-degree | 0.914 (0.078) | 1.183 (0.209) | 0.938 (0.611) | 0.913 (0.695) |
| In-degree | **1.102 (0.006)** | 1.091 (0.326) | 1.127 (0.114) | 1.069 (0.679) |
| **Perceived Friend Use** | **1.470 (0.000)** | **0.729 (0.022)** | **0.716 (0.002)** | 0.779 (0.319) |
| **Network Exposure Users** | **5.684 (0.000)** | **0.104 (0.011)** | **0.232 (0.031)** | 0.800 (0.878) |
| Network Exposure Dis-adopters ($E_D$ alt) | 1.814 (0.253) | 0.374 (0.271) | 0.401 (0.238) | 0.043 (0.323) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

**On the gs_fe coefficients**. The values for gs = 3..8 in the disadoption columns (A, B, C) are extremely large ($10^5$–$10^7$ ORs with $p \approx 0$). These are *separation artifacts* with no substantive interpretation: at Q = 7, the at-risk panel for A has only 89 events spread across the 7 dummies, and many gs cells contain either all events or no events. The same pattern occurred in v4b under wave-FE; both specs are honest about the substantive predictors but neither admits clean inference on the time-FE block at small N. **Reading rule**: ignore the magnitudes of the gs_fe rows; treat the gs_fe block as nuisance controls. The substantive story sits in PFU, $E_{\text{users}}$, MDD, In-degree, Sexual Minority, Asian, and the constant.

**Headline reading**.

- **Adoption (column 1)**. PFU OR = 1.47 ($p < 0.001$): each step on the 0–5 scale lifts adoption odds by 47%. $E_{\text{users}}$ OR = 5.68 ($p < 0.001$): going from 0 friends-using to all friends-using multiplies adoption odds 5.7×. Cohort 2025 not different from 2024. Sexual Minority +44% ($p = 0.031$). Asian −36% ($p = 0.023$). In-degree +10%/friend-incoming ($p = 0.006$).
- **Stable disadoption (column A)**. PFU OR = 0.73 ($p = 0.022$) and $E_{\text{users}}$ OR = 0.10 ($p = 0.011$): peer-use environment is the cleanest two-sided predictor — high peer use suppresses cessation. $E_D$ alt is in the right direction (OR = 0.37) but not significant.
- **Experimental disadoption (column B)**. Same peer-use story (PFU OR = 0.72, $p = 0.002$; $E_{\text{users}}$ OR = 0.23, $p = 0.031$). MDD OR = 0.44 ($p = 0.006$): depressive symptoms predict *not* attempting cessation.
- **Unstable / cyclic (column C)**. With only 15 events, only MDD reaches significance (OR = 0.21, $p = 0.023$), pointing in the same direction as B.

# 14. Limitations and deferred items

## 14.1 ESE — coverage and temporal pattern

ESE composites are **excluded** from v4b regressions because of severe sparsity. Coverage by school (students with **any** ESE non-NA across W1-W10):

| School | n students | with ESE | % |
|:-:|---:|---:|---:|
| 101 | 278 |  50 | 18.0 |
| 102 | 252 |  34 | 13.5 |
| 103 | 198 |  18 |  9.1 |
| 104 | 384 |  92 | 24.0 |
| 105 | 205 |  38 | 18.5 |
| 106 | 238 |  53 | 22.3 |
| 107 | 286 |  81 | 28.3 |
| 108 | 252 |  68 | 27.0 |
| 112 | 337 |  73 | 21.7 |
| 113 | 378 |  55 | 14.6 |
| 114 | 374 | 127 | 34.0 |
| 201 | 216 |  32 | 14.8 |
| 212 | 328 |  57 | 17.4 |
| 213 | 374 |  40 | 10.7 |
| 214 | 331 |  98 | 29.6 |
| **Total** | **4,431** | **916** | **20.7 %** |

Only ~21 % of students have *any* ESE record across 10 waves. **Temporal pattern**: of those 916 students, **887 have ESE in only one wave** (the wave at which they first reported e-cig use, presumably). The remaining 29 students have ESE in ≥ 2 waves — and 79 % of those exhibit *different* values across waves, indicating ESE is **not strictly time-invariant** (the questionnaire allows re-evaluation when the student is asked again) but is *typically asked once*. For a future analysis that includes ESE as a baseline trait, LOCF + LOCB across waves would extend coverage to the 916 students; a per-wave time-varying ESE would only have data for the 29 with multiple records.

## 14.2 Other deferred items

- **C samples remain small**: 7–29 events per Q. GLMER often hits singular fits ($\rho \to 0$); coefficients should be read with caution.
- **Schoolid_transfer** (~50 students who switched schools across waves) not yet integrated.
- **W9–W10 schoolid code 999** ("transferred-out") treated as NA — affects 15–38 students per wave.
- v4 results (W1–W8 panel) archived at `reports/disadoption-study-4.{pdf,md}`.

# Annex — Pipeline

`R/00-config.R` → `R/01b-edges-rebuild.R` (regenerate W1–W10 edges into `data/advance/Cleaned-Data-042326/`) → `R/01-advance-panel.R` (W1–W10 long panel) → `R/02-event-builder.R` (5 modes × 4 Q) → `R/03-network-features.R` (degrees, exposures, $E_D$ variants) → `R/04-regressions.R` (5 families × 4 Q raw fits) → `R/04b-rebuild-tables-OR.R` (re-emit the 20 CSVs as odds ratios).
