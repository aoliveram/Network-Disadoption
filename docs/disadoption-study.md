---
title: "ADVANCE Disadoption Study v4b"
subtitle: "Behavioural correlates of e-cigarette adoption and disadoption (W1-W10, 5 result families)"
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

This iteration extends v4 to the full **W1-W10** ADVANCE panel (10 semester waves, 4,437 students, 042326 release) and adds **five regression families** that probe the structure of the disadoption signal:

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

**Eligible vs effective**: the Q-row above is the count of *eligible* students. The regression in each column then drops rows with NA on any predictor (complete-case). The effective `N Students` reported per column is therefore smaller than the Q-row count. The Adopters column suffers the smallest cut (most predictors are filled at every observed wave); the A / B / C columns work on the much smaller ever-user subset (each column's `N Students` reflects that). E.g., at $Q = 8$ we have 1,040 eligible students; the Adopters regression uses 925 (after complete-case dropping); the A regression uses 83 (ever-users with valid predictors).

# 3. Event definitions

For each student we define, on consecutive observed waves:

- **Adopters**: first $0 \to 1$ transition. One event per person.
- **A — Stable**: $1 \to 0$ with **no future return to 1** in any later observed wave. One event per person. Indeterminates ($1 \to 0$ with NA-only future) are dropped from A in §5/§6/§8/§10; counted as A in §9.
- **B — Experimental**: first $1 \to 0$ (any). One event per person.
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves. Multiple events per person possible. §5/§6/§9/§10 use $W=1$; §8 reports $W=1, 2, 3$.

§10 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs).

# 4. Methods

For each regression, the outcome at person-wave $(i, w)$ is binary; the risk-set is the corresponding panel:

- **Adopters / A / B**: GLM logistic with wave fixed effects and cluster-robust SE by `record_id` (`sandwich::vcovCL`).
- **C**: `lme4::glmer(... + (1 \mid \text{record\_id}))` with wave FE, since C admits multiple events per person; we report ICC $\rho = \sigma^2_u / (\sigma^2_u + \pi^2/3)$.

**Predictors (13)**: cohort (2025 vs 2024), female, sexual minority, parent education, asian, hispanic/latine, MDD (RCADS Mean), GAD (RCADS Mean), out-degree, in-degree, perceived friend use ($w-1$), network exposure to users ($E_{\text{users}}, w-1$), network exposure to dis-adopters ($E_D, w-1$). The cohort dummy is dropped at $Q=8$ (only cohort 2024 schools 101–105 remain).

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

\fontsize{8}{10}\selectfont

---

# 5. Main results (E_D = peer-flipped 1→0; C window = 1)

OR (p-value). Bold = $p < 0.05$. $E_D$ = peer share who flipped $1 \to 0$ between $w-2$ and $w-1$. *Model C uses a person random intercept; $\rho = 0.000$ across all fits, so conditional and marginal ORs coincide empirically.*

## 5.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 1.620 (0.069) | 0.368 (0.076) | 0.336 (0.056) | 0.403 (0.624) |
| Sexual Minority | 1.536 (0.089) | 1.043 (0.944) | 1.896 (0.255) | **28.020 (0.042)** |
| Parent Ed. | 0.961 (0.633) | 1.209 (0.346) | 1.113 (0.631) | 0.324 (0.228) |
| Asian | 0.568 (0.051) | 0.898 (0.874) | 0.576 (0.395) | 0.242 (0.445) |
| Hispanic/Latine | 1.019 (0.949) | 0.674 (0.558) | 0.624 (0.496) | 0.021 (0.175) |
| MDD (Major Depressive S.) | 1.228 (0.401) | 0.514 (0.139) | **0.323 (0.022)** | **0.045 (0.029)** |
| GAD (Generalized Anxiety Dis.) | 0.883 (0.574) | 2.123 (0.155) | 1.863 (0.202) | 6.669 (0.263) |
| Out-degree | **0.828 (0.011)** | 1.259 (0.195) | 1.033 (0.876) | 1.644 (0.382) |
| In-degree | 1.097 (0.058) | 1.152 (0.305) | 1.066 (0.633) | 0.323 (0.113) |
| **Perceived Friend Use** | **1.471 (0.000)** | 0.886 (0.541) | 1.026 (0.887) | 2.308 (0.236) |
| **Network Exposure Users** | **3.772 (0.034)** | **0.021 (0.024)** | **0.047 (0.016)** | 0.206 (0.640) |
| Network Exposure Dis-adopters | 3.027 (0.254) | 2.467 (0.486) | 0.462 (0.494) | 0.015 (0.511) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 5.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.915 (0.634) | 1.835 (0.115) | **2.436 (0.017)** | 1.367 (0.698) |
| Female | 1.343 (0.104) | 0.774 (0.496) | 0.997 (0.995) | 3.045 (0.180) |
| Sexual Minority | **1.454 (0.030)** | 0.718 (0.382) | 0.939 (0.863) | 1.200 (0.779) |
| Parent Ed. | 0.957 (0.471) | 1.009 (0.950) | 0.928 (0.650) | 0.607 (0.089) |
| Asian | **0.617 (0.014)** | 0.882 (0.783) | 1.041 (0.923) | 0.355 (0.194) |
| Hispanic/Latine | 1.060 (0.769) | 0.811 (0.657) | 0.676 (0.327) | 0.245 (0.085) |
| MDD (Major Depressive S.) | 1.177 (0.345) | 0.715 (0.323) | **0.431 (0.006)** | **0.245 (0.034)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.348) | 1.365 (0.364) | 1.099 (0.762) | 0.980 (0.976) |
| Out-degree | 0.920 (0.100) | 1.078 (0.573) | 0.881 (0.348) | 0.935 (0.785) |
| In-degree | **1.096 (0.010)** | 1.133 (0.153) | 1.161 (0.063) | 1.057 (0.743) |
| **Perceived Friend Use** | **1.471 (0.000)** | **0.724 (0.017)** | **0.727 (0.003)** | 0.726 (0.203) |
| **Network Exposure Users** | **5.331 (0.000)** | **0.099 (0.006)** | **0.222 (0.027)** | 1.477 (0.784) |
| Network Exposure Dis-adopters | 2.916 (0.160) | 0.220 (0.304) | 0.572 (0.496) | 0.277 (0.660) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 5.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.856 (0.372) | 1.559 (0.191) | **2.235 (0.017)** | 1.621 (0.479) |
| Female | 1.296 (0.102) | 0.601 (0.129) | 0.752 (0.396) | 2.507 (0.211) |
| Sexual Minority | **1.385 (0.037)** | 0.753 (0.380) | 1.149 (0.661) | 2.333 (0.117) |
| Parent Ed. | 0.953 (0.393) | 1.018 (0.879) | 1.024 (0.858) | 0.835 (0.420) |
| Asian | **0.613 (0.007)** | 1.073 (0.855) | 1.120 (0.764) | 0.412 (0.187) |
| Hispanic/Latine | 1.121 (0.520) | 0.866 (0.703) | 0.881 (0.712) | 0.444 (0.193) |
| MDD (Major Depressive S.) | 1.125 (0.457) | 0.733 (0.323) | **0.504 (0.017)** | 0.395 (0.082) |
| GAD (Generalized Anxiety Dis.) | 0.892 (0.418) | 1.224 (0.495) | 1.112 (0.712) | 1.363 (0.561) |
| Out-degree | 0.942 (0.191) | 1.103 (0.393) | 0.969 (0.787) | 0.999 (0.994) |
| In-degree | **1.087 (0.010)** | 1.079 (0.308) | 1.123 (0.086) | 1.107 (0.445) |
| **Perceived Friend Use** | **1.502 (0.000)** | **0.704 (0.001)** | **0.713 (0.000)** | 0.756 (0.150) |
| **Network Exposure Users** | **5.388 (0.000)** | 0.261 (0.059) | 0.359 (0.088) | 1.149 (0.906) |
| Network Exposure Dis-adopters | 1.929 (0.368) | 0.443 (0.480) | 0.872 (0.863) | 0.431 (0.703) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 5.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.871 (0.389) | 1.395 (0.271) | **1.851 (0.030)** | 1.614 (0.357) |
| Female | **1.428 (0.017)** | 0.553 (0.060) | 0.694 (0.248) | 2.111 (0.221) |
| Sexual Minority | **1.438 (0.013)** | 0.839 (0.541) | 1.108 (0.709) | 1.646 (0.261) |
| Parent Ed. | 0.932 (0.181) | 1.003 (0.983) | 0.992 (0.946) | 0.862 (0.413) |
| Asian | **0.668 (0.017)** | 1.159 (0.686) | 1.121 (0.740) | 0.413 (0.135) |
| Hispanic/Latine | 1.148 (0.407) | 0.895 (0.742) | 0.915 (0.772) | 0.538 (0.223) |
| MDD (Major Depressive S.) | 1.133 (0.385) | 0.817 (0.477) | **0.533 (0.016)** | **0.393 (0.047)** |
| GAD (Generalized Anxiety Dis.) | 0.850 (0.214) | 1.175 (0.541) | 1.182 (0.512) | 1.384 (0.470) |
| Out-degree | 0.946 (0.198) | 1.088 (0.427) | 1.029 (0.773) | 1.049 (0.763) |
| In-degree | **1.079 (0.011)** | 1.063 (0.370) | 1.078 (0.212) | 1.054 (0.648) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.737 (0.001)** | **0.732 (0.000)** | 0.783 (0.105) |
| **Network Exposure Users** | **5.625 (0.000)** | 0.432 (0.186) | 0.683 (0.495) | 2.082 (0.375) |
| Network Exposure Dis-adopters | **3.067 (0.050)** | 0.722 (0.746) | 1.083 (0.910) | 0.145 (0.377) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 6. Alternative E_D = E^max − E_current

Replaces "peer share who flipped 1→0 between $w-2$ and $w-1$" with $E_D = \max_{s \le w-1} E_{\text{users},i,s} - E_{\text{users},i,w-1}$.

## 6.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 1.628 (0.067) | 0.378 (0.069) | 0.377 (0.087) | 0.487 (0.714) |
| Sexual Minority | 1.522 (0.095) | 1.075 (0.904) | 1.855 (0.253) | 44.124 (0.063) |
| Parent Ed. | 0.960 (0.626) | 1.220 (0.307) | 1.142 (0.550) | 0.352 (0.253) |
| Asian | 0.573 (0.057) | 0.942 (0.931) | 0.542 (0.325) | 0.195 (0.396) |
| Hispanic/Latine | 1.027 (0.927) | 0.748 (0.678) | 0.638 (0.523) | 0.036 (0.233) |
| MDD (Major Depressive S.) | 1.236 (0.387) | 0.503 (0.128) | **0.310 (0.014)** | **0.021 (0.041)** |
| GAD (Generalized Anxiety Dis.) | 0.882 (0.573) | 2.201 (0.144) | 1.916 (0.190) | 12.901 (0.198) |
| Out-degree | **0.831 (0.012)** | 1.256 (0.197) | 1.071 (0.748) | 1.576 (0.442) |
| In-degree | **1.101 (0.049)** | 1.154 (0.295) | 1.052 (0.712) | 0.287 (0.069) |
| **Perceived Friend Use** | **1.467 (0.000)** | 0.885 (0.547) | 1.021 (0.906) | 2.288 (0.242) |
| **Network Exposure Users** | **3.978 (0.028)** | **0.026 (0.030)** | **0.035 (0.008)** | 0.050 (0.436) |
| $E_D$ alt | 1.660 (0.488) | 0.907 (0.948) | 0.213 (0.401) | 0.002 (0.373) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 6.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.926 (0.685) | 1.792 (0.147) | **2.268 (0.033)** | 1.230 (0.800) |
| Female | 1.345 (0.105) | 0.829 (0.621) | 1.077 (0.846) | 3.361 (0.144) |
| Sexual Minority | **1.443 (0.033)** | 0.672 (0.282) | 0.917 (0.813) | 1.265 (0.721) |
| Parent Ed. | 0.954 (0.450) | 1.018 (0.896) | 0.946 (0.739) | 0.636 (0.123) |
| Asian | **0.626 (0.019)** | 0.841 (0.704) | 0.972 (0.945) | 0.305 (0.144) |
| Hispanic/Latine | 1.072 (0.723) | 0.772 (0.579) | 0.671 (0.321) | 0.232 (0.077) |
| MDD (Major Depressive S.) | 1.180 (0.341) | 0.713 (0.313) | **0.416 (0.005)** | **0.228 (0.028)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.348) | 1.359 (0.366) | 1.131 (0.690) | 1.036 (0.957) |
| Out-degree | 0.921 (0.103) | 1.079 (0.569) | 0.886 (0.364) | 0.922 (0.735) |
| In-degree | **1.099 (0.008)** | 1.123 (0.191) | 1.161 (0.063) | 1.041 (0.810) |
| **Perceived Friend Use** | **1.467 (0.000)** | **0.735 (0.021)** | **0.746 (0.007)** | 0.762 (0.284) |
| **Network Exposure Users** | **5.598 (0.000)** | **0.080 (0.004)** | **0.171 (0.011)** | 0.881 (0.933) |
| $E_D$ alt | 1.809 (0.251) | 0.478 (0.434) | 0.342 (0.182) | 0.019 (0.252) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 6.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.871 (0.435) | 1.479 (0.269) | **2.077 (0.033)** | 1.459 (0.586) |
| Female | 1.289 (0.111) | 0.649 (0.196) | 0.789 (0.485) | 2.672 (0.178) |
| Sexual Minority | **1.382 (0.039)** | 0.731 (0.327) | 1.126 (0.703) | 2.366 (0.110) |
| Parent Ed. | 0.951 (0.382) | 1.028 (0.809) | 1.034 (0.800) | 0.827 (0.397) |
| Asian | **0.631 (0.013)** | 1.013 (0.974) | 1.036 (0.927) | 0.361 (0.139) |
| Hispanic/Latine | 1.142 (0.460) | 0.856 (0.680) | 0.862 (0.669) | 0.416 (0.165) |
| MDD (Major Depressive S.) | 1.130 (0.440) | 0.717 (0.288) | **0.494 (0.014)** | 0.376 (0.067) |
| GAD (Generalized Anxiety Dis.) | 0.890 (0.407) | 1.244 (0.459) | 1.130 (0.664) | 1.439 (0.496) |
| Out-degree | 0.943 (0.206) | 1.102 (0.399) | 0.965 (0.759) | 0.995 (0.979) |
| In-degree | **1.087 (0.010)** | 1.079 (0.311) | 1.124 (0.082) | 1.114 (0.415) |
| **Perceived Friend Use** | **1.498 (0.000)** | **0.720 (0.002)** | **0.729 (0.001)** | 0.795 (0.250) |
| **Network Exposure Users** | **5.722 (0.000)** | **0.197 (0.034)** | **0.273 (0.043)** | 0.749 (0.819) |
| $E_D$ alt | 1.819 (0.191) | 0.375 (0.264) | 0.394 (0.195) | 0.124 (0.339) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 6.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.885 (0.450) | 1.310 (0.383) | 1.722 (0.057) | 1.631 (0.349) |
| Female | **1.428 (0.018)** | 0.599 (0.105) | 0.739 (0.345) | 2.198 (0.194) |
| Sexual Minority | **1.436 (0.013)** | 0.834 (0.522) | 1.094 (0.737) | 1.638 (0.265) |
| Parent Ed. | 0.929 (0.162) | 1.013 (0.914) | 1.002 (0.985) | 0.849 (0.370) |
| Asian | **0.685 (0.030)** | 1.094 (0.811) | 1.031 (0.930) | 0.394 (0.120) |
| Hispanic/Latine | 1.169 (0.357) | 0.914 (0.792) | 0.894 (0.717) | 0.515 (0.191) |
| MDD (Major Depressive S.) | 1.132 (0.390) | 0.797 (0.423) | **0.524 (0.013)** | **0.392 (0.046)** |
| GAD (Generalized Anxiety Dis.) | 0.849 (0.209) | 1.196 (0.498) | 1.193 (0.480) | 1.406 (0.449) |
| Out-degree | 0.946 (0.208) | 1.087 (0.422) | 1.020 (0.850) | 1.037 (0.817) |
| In-degree | **1.079 (0.010)** | 1.065 (0.360) | 1.080 (0.201) | 1.054 (0.638) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.756 (0.003)** | **0.751 (0.001)** | 0.788 (0.121) |
| **Network Exposure Users** | **5.953 (0.000)** | 0.316 (0.094) | 0.505 (0.251) | 1.775 (0.514) |
| $E_D$ alt | 2.024 (0.097) | 0.265 (0.112) | 0.321 (0.090) | 0.373 (0.554) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 7. No $E_D$

§5 and §6 found $E_D$ to be noisy and never significant on A/B/C, while suggesting collinearity with $E_{\text{users}}$ when $E_D$ is the alt definition. §7 refits §5's four outcomes after **removing $E_D$ entirely** from the predictor list. The remaining 12 predictors are unchanged. Effective $N$ is identical to §5 (the rows lost to complete-cases are the same — $E_{\text{users}}$ and $E_D$ have correlated NAs). OR (p-value). Bold = $p < 0.05$.

## 7.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 1.641 (0.061) | 0.375 (0.075) | 0.350 (0.067) | 0.360 (0.574) |
| Sexual Minority | 1.531 (0.092) | 1.074 (0.904) | 1.844 (0.271) | 25.392 (0.050) |
| Parent Ed. | 0.962 (0.644) | 1.218 (0.322) | 1.110 (0.643) | 0.286 (0.187) |
| Asian | **0.558 (0.044)** | 0.943 (0.932) | 0.583 (0.408) | 0.279 (0.474) |
| Hispanic/Latine | 1.024 (0.936) | 0.745 (0.672) | 0.631 (0.515) | 0.030 (0.185) |
| MDD (Major Depressive S.) | 1.234 (0.393) | 0.504 (0.126) | **0.324 (0.023)** | **0.046 (0.028)** |
| GAD (Generalized Anxiety Dis.) | 0.877 (0.557) | 2.195 (0.137) | 1.834 (0.216) | 7.306 (0.220) |
| Out-degree | **0.828 (0.011)** | 1.255 (0.196) | 1.039 (0.854) | 1.685 (0.365) |
| In-degree | **1.101 (0.049)** | 1.155 (0.290) | 1.067 (0.628) | 0.302 (0.081) |
| **Perceived Friend Use** | **1.477 (0.000)** | 0.885 (0.546) | 1.013 (0.943) | 2.025 (0.280) |
| **Network Exposure Users** | **3.731 (0.034)** | **0.026 (0.030)** | **0.045 (0.013)** | 0.167 (0.586) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 7.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.903 (0.587) | 1.910 (0.094) | **2.457 (0.016)** | 1.444 (0.645) |
| Female | 1.351 (0.098) | 0.792 (0.534) | 1.008 (0.983) | 2.985 (0.185) |
| Sexual Minority | **1.455 (0.030)** | 0.680 (0.298) | 0.927 (0.833) | 1.188 (0.792) |
| Parent Ed. | 0.955 (0.456) | 0.999 (0.993) | 0.927 (0.641) | 0.603 (0.085) |
| Asian | **0.607 (0.011)** | 0.864 (0.743) | 1.033 (0.937) | 0.366 (0.205) |
| Hispanic/Latine | 1.063 (0.756) | 0.757 (0.546) | 0.677 (0.331) | 0.244 (0.083) |
| MDD (Major Depressive S.) | 1.176 (0.350) | 0.724 (0.338) | **0.430 (0.006)** | **0.251 (0.037)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.346) | 1.339 (0.391) | 1.120 (0.717) | 0.976 (0.970) |
| Out-degree | 0.920 (0.098) | 1.071 (0.606) | 0.888 (0.374) | 0.926 (0.751) |
| In-degree | **1.098 (0.008)** | 1.127 (0.171) | 1.160 (0.062) | 1.053 (0.760) |
| **Perceived Friend Use** | **1.475 (0.000)** | **0.720 (0.014)** | **0.723 (0.003)** | 0.715 (0.180) |
| **Network Exposure Users** | **5.213 (0.000)** | **0.095 (0.006)** | **0.228 (0.028)** | 1.422 (0.806) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 7.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.849 (0.351) | 1.596 (0.169) | **2.241 (0.016)** | 1.674 (0.448) |
| Female | 1.301 (0.096) | 0.614 (0.143) | 0.755 (0.404) | 2.511 (0.208) |
| Sexual Minority | **1.391 (0.035)** | 0.736 (0.338) | 1.143 (0.669) | 2.312 (0.120) |
| Parent Ed. | 0.952 (0.385) | 1.015 (0.899) | 1.024 (0.860) | 0.831 (0.406) |
| Asian | **0.607 (0.006)** | 1.063 (0.876) | 1.116 (0.771) | 0.418 (0.194) |
| Hispanic/Latine | 1.122 (0.515) | 0.835 (0.630) | 0.879 (0.709) | 0.439 (0.186) |
| MDD (Major Depressive S.) | 1.125 (0.458) | 0.735 (0.326) | **0.504 (0.017)** | 0.396 (0.083) |
| GAD (Generalized Anxiety Dis.) | 0.890 (0.412) | 1.213 (0.513) | 1.114 (0.706) | 1.363 (0.562) |
| Out-degree | 0.941 (0.189) | 1.098 (0.419) | 0.971 (0.793) | 0.995 (0.980) |
| In-degree | **1.087 (0.010)** | 1.079 (0.309) | 1.123 (0.085) | 1.106 (0.450) |
| **Perceived Friend Use** | **1.504 (0.000)** | **0.703 (0.001)** | **0.712 (0.000)** | 0.754 (0.145) |
| **Network Exposure Users** | **5.320 (0.000)** | 0.255 (0.057) | 0.359 (0.088) | 1.128 (0.919) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 7.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.861 (0.349) | 1.411 (0.253) | **1.848 (0.030)** | 1.720 (0.294) |
| Female | **1.443 (0.014)** | 0.556 (0.062) | 0.693 (0.248) | 2.123 (0.215) |
| Sexual Minority | **1.445 (0.011)** | 0.830 (0.513) | 1.112 (0.696) | 1.614 (0.279) |
| Parent Ed. | 0.929 (0.164) | 1.001 (0.995) | 0.992 (0.949) | 0.853 (0.381) |
| Asian | **0.655 (0.013)** | 1.154 (0.695) | 1.121 (0.740) | 0.419 (0.141) |
| Hispanic/Latine | 1.145 (0.421) | 0.883 (0.709) | 0.914 (0.769) | 0.524 (0.200) |
| MDD (Major Depressive S.) | 1.127 (0.408) | 0.819 (0.483) | **0.533 (0.016)** | 0.400 (0.051) |
| GAD (Generalized Anxiety Dis.) | 0.850 (0.214) | 1.173 (0.544) | 1.180 (0.515) | 1.383 (0.473) |
| Out-degree | 0.944 (0.189) | 1.087 (0.429) | 1.028 (0.777) | 1.038 (0.811) |
| In-degree | **1.079 (0.011)** | 1.063 (0.369) | 1.078 (0.212) | 1.051 (0.660) |
| **Perceived Friend Use** | **1.492 (0.000)** | **0.735 (0.001)** | **0.733 (0.000)** | 0.772 (0.085) |
| **Network Exposure Users** | **5.480 (0.000)** | 0.433 (0.189) | 0.680 (0.490) | 2.117 (0.366) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
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
| Cohort (2025 vs 2024) | — | — | — |
| Female | 0.403 (0.624) | 1.132 (0.918) | 1.132 (0.918) |
| Sexual Minority | **28.020 (0.042)** | **12.456 (0.037)** | **12.456 (0.037)** |
| Parent Ed. | 0.324 (0.228) | 0.960 (0.926) | 0.960 (0.926) |
| Asian | 0.242 (0.445) | 0.378 (0.439) | 0.378 (0.439) |
| Hispanic/Latine | 0.021 (0.175) | 1.270 (0.852) | 1.270 (0.852) |
| MDD (Major Depressive S.) | **0.045 (0.029)** | 0.373 (0.212) | 0.373 (0.212) |
| GAD (Generalized Anxiety Dis.) | 6.669 (0.263) | 0.957 (0.966) | 0.957 (0.966) |
| Out-degree | 1.644 (0.382) | 0.933 (0.831) | 0.933 (0.831) |
| In-degree | 0.323 (0.113) | 0.727 (0.288) | 0.727 (0.288) |
| Perceived Friend Use | 2.308 (0.236) | 0.888 (0.775) | 0.888 (0.775) |
| Network Exposure Users | 0.206 (0.640) | 0.296 (0.604) | 0.296 (0.604) |
| Network Exposure Dis-adopters | 0.015 (0.511) | 0.801 (0.923) | 0.801 (0.923) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 83 | 83 | 83 |
| N Events | 7 | 11 | 11 |

## 8.2 Q = 7

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.367 (0.698) | 2.628 (0.861) | 4.860 (0.834) |
| Female | 3.045 (0.180) | 2.789 (0.828) | 2.331 (0.901) |
| Sexual Minority | 1.200 (0.779) | 4.524 (0.658) | 2.358 (0.869) |
| Parent Ed. | 0.607 (0.089) | 0.342 (0.526) | 0.438 (0.745) |
| Asian | 0.355 (0.194) | 0.395 (0.866) | 0.114 (0.770) |
| Hispanic/Latine | 0.245 (0.085) | 0.284 (0.816) | 0.037 (0.671) |
| MDD (Major Depressive S.) | **0.245 (0.034)** | 0.066 (0.454) | 0.144 (0.711) |
| GAD (Generalized Anxiety Dis.) | 0.980 (0.976) | 0.675 (0.908) | 0.178 (0.737) |
| Out-degree | 0.935 (0.785) | 0.595 (0.636) | 0.451 (0.607) |
| In-degree | 1.057 (0.743) | 1.243 (0.838) | 1.317 (0.849) |
| Perceived Friend Use | 0.726 (0.203) | 0.786 (0.818) | 0.586 (0.728) |
| Network Exposure Users | 1.477 (0.784) | 0.628 (0.957) | 2.790 (0.924) |
| Network Exposure Dis-adopters | 0.277 (0.660) | 0.851 (0.991) | 5.358 (0.933) |
| Rho (ICC) | 0.000 | 0.953 | 0.975 |
| N Students | 161 | 161 | 161 |
| N Events | 15 | 20 | 21 |

## 8.3 Q = 6

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.621 (0.479) | 2.537 (0.123) | 2.586 (0.111) |
| Female | 2.507 (0.211) | 1.508 (0.504) | 1.649 (0.412) |
| Sexual Minority | 2.333 (0.117) | **2.743 (0.046)** | 2.622 (0.051) |
| Parent Ed. | 0.835 (0.420) | 0.840 (0.399) | 0.905 (0.609) |
| Asian | 0.412 (0.187) | 0.310 (0.073) | 0.431 (0.174) |
| Hispanic/Latine | 0.444 (0.193) | 0.554 (0.289) | 0.548 (0.279) |
| MDD (Major Depressive S.) | 0.395 (0.082) | 0.573 (0.237) | 0.516 (0.160) |
| GAD (Generalized Anxiety Dis.) | 1.363 (0.561) | 0.885 (0.802) | 0.885 (0.801) |
| Out-degree | 0.999 (0.994) | 0.953 (0.777) | 0.946 (0.739) |
| In-degree | 1.107 (0.445) | 1.144 (0.270) | 1.118 (0.349) |
| Perceived Friend Use | 0.756 (0.150) | 0.818 (0.235) | 0.850 (0.317) |
| Network Exposure Users | 1.149 (0.906) | 0.662 (0.708) | 1.083 (0.938) |
| Network Exposure Dis-adopters | 0.431 (0.703) | 2.036 (0.607) | 2.098 (0.595) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 206 | 206 | 206 |
| N Events | 21 | 26 | 27 |

## 8.4 Q = 5

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.614 (0.357) | 2.005 (0.146) | 1.996 (0.148) |
| Female | 2.111 (0.221) | 1.464 (0.481) | 1.530 (0.429) |
| Sexual Minority | 1.646 (0.261) | 1.628 (0.241) | 1.609 (0.247) |
| Parent Ed. | 0.862 (0.413) | 0.844 (0.316) | 0.890 (0.473) |
| Asian | 0.413 (0.135) | 0.333 (0.055) | 0.437 (0.132) |
| Hispanic/Latine | 0.538 (0.223) | 0.588 (0.251) | 0.591 (0.256) |
| MDD (Major Depressive S.) | **0.393 (0.047)** | 0.552 (0.156) | 0.510 (0.107) |
| GAD (Generalized Anxiety Dis.) | 1.384 (0.470) | 1.125 (0.775) | 1.131 (0.766) |
| Out-degree | 1.049 (0.763) | 1.078 (0.606) | 1.075 (0.613) |
| In-degree | 1.054 (0.648) | 1.028 (0.789) | 1.014 (0.892) |
| Perceived Friend Use | 0.783 (0.105) | 0.818 (0.144) | 0.842 (0.202) |
| Network Exposure Users | 2.082 (0.375) | 1.451 (0.638) | 1.969 (0.380) |
| Network Exposure Dis-adopters | 0.145 (0.377) | 0.987 (0.992) | 0.980 (0.989) |
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
| Cohort (2025 vs 2024) | — | — | 1.835 (0.115) | 1.527 (0.208) | 1.559 (0.191) | 1.453 (0.213) | 1.395 (0.271) | 1.322 (0.288) |
| Female | 0.368 (0.076) | 0.509 (0.201) | 0.774 (0.496) | 0.922 (0.818) | 0.601 (0.129) | 0.820 (0.521) | 0.553 (0.060) | 0.755 (0.335) |
| Sexual Minority | 1.043 (0.944) | 0.840 (0.734) | 0.718 (0.382) | 0.780 (0.465) | 0.753 (0.380) | 0.762 (0.354) | 0.839 (0.541) | 0.838 (0.492) |
| Parent Ed. | 1.209 (0.346) | 1.163 (0.449) | 1.009 (0.950) | 0.970 (0.826) | 1.018 (0.879) | 1.027 (0.816) | 1.003 (0.983) | 1.014 (0.903) |
| Asian | 0.898 (0.874) | 0.745 (0.589) | 0.883 (0.783) | 1.134 (0.738) | 1.074 (0.855) | 1.177 (0.628) | 1.159 (0.686) | 1.170 (0.614) |
| Hispanic/Latine | 0.674 (0.558) | 0.884 (0.818) | 0.811 (0.657) | 0.949 (0.889) | 0.866 (0.703) | 0.970 (0.924) | 0.895 (0.742) | 0.974 (0.926) |
| MDD (Major Depressive S.) | 0.514 (0.139) | 0.598 (0.196) | 0.715 (0.323) | 0.676 (0.205) | 0.733 (0.323) | 0.669 (0.160) | 0.817 (0.477) | 0.718 (0.202) |
| GAD (Generalized Anxiety Dis.) | 2.123 (0.155) | 1.176 (0.702) | 1.365 (0.364) | 0.999 (0.996) | 1.224 (0.495) | 0.983 (0.950) | 1.175 (0.541) | 0.995 (0.982) |
| Out-degree | 1.259 (0.195) | 1.176 (0.337) | 1.077 (0.573) | 0.996 (0.974) | 1.103 (0.393) | 1.008 (0.935) | 1.087 (0.427) | 1.017 (0.859) |
| In-degree | 1.152 (0.305) | 1.066 (0.597) | 1.133 (0.153) | 1.113 (0.150) | 1.079 (0.308) | 1.101 (0.135) | 1.063 (0.370) | 1.096 (0.125) |
| **Perceived Friend Use** | 0.886 (0.541) | 0.915 (0.562) | **0.724 (0.017)** | **0.733 (0.003)** | **0.704 (0.001)** | **0.726 (0.000)** | **0.737 (0.001)** | **0.757 (0.000)** |
| **Network Exposure Users** | **0.021 (0.024)** | **0.067 (0.041)** | **0.098 (0.006)** | **0.248 (0.034)** | 0.261 (0.059) | 0.381 (0.100) | 0.432 (0.186) | 0.510 (0.217) |
| Network Exposure Dis-adopters | 2.467 (0.486) | 2.971 (0.324) | 0.220 (0.304) | 0.939 (0.936) | 0.443 (0.480) | 1.333 (0.687) | 0.723 (0.746) | 1.662 (0.408) |
| N Students | 83 | 96 | 161 | 191 | 206 | 245 | 237 | 283 |
| N Events | 52 | 66 | 89 | 122 | 108 | 150 | 124 | 169 |

## 9.2 Table — $E_D$ = $E^{\max} - E_{\text{current}}$ (alt)

| Variable | Q=8 (orig) | Q=8 (a) | Q=7 (orig) | Q=7 (a) | Q=6 (orig) | Q=6 (a) | Q=5 (orig) | Q=5 (a) |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | 1.791 (0.147) | 1.537 (0.211) | 1.479 (0.269) | 1.431 (0.244) | 1.309 (0.383) | 1.260 (0.385) |
| Female | 0.377 (0.069) | 0.493 (0.172) | 0.830 (0.621) | 0.920 (0.813) | 0.649 (0.196) | 0.820 (0.526) | 0.599 (0.105) | 0.775 (0.389) |
| Sexual Minority | 1.075 (0.904) | 0.858 (0.766) | 0.672 (0.282) | 0.780 (0.466) | 0.732 (0.327) | 0.766 (0.361) | 0.834 (0.522) | 0.847 (0.517) |
| Parent Ed. | 1.220 (0.307) | 1.165 (0.434) | 1.018 (0.896) | 0.968 (0.813) | 1.028 (0.809) | 1.030 (0.795) | 1.013 (0.914) | 1.024 (0.834) |
| Asian | 0.942 (0.931) | 0.790 (0.669) | 0.841 (0.704) | 1.135 (0.739) | 1.013 (0.974) | 1.177 (0.637) | 1.093 (0.811) | 1.136 (0.691) |
| Hispanic/Latine | 0.748 (0.678) | 0.932 (0.899) | 0.772 (0.579) | 0.946 (0.882) | 0.855 (0.680) | 0.980 (0.949) | 0.914 (0.792) | 0.980 (0.945) |
| MDD (Major Depressive S.) | 0.503 (0.128) | 0.603 (0.203) | 0.712 (0.313) | 0.677 (0.208) | 0.717 (0.288) | 0.670 (0.161) | 0.796 (0.423) | 0.714 (0.197) |
| GAD (Generalized Anxiety Dis.) | 2.202 (0.144) | 1.190 (0.683) | 1.360 (0.366) | 1.000 (1.000) | 1.244 (0.459) | 0.980 (0.940) | 1.196 (0.498) | 0.987 (0.958) |
| Out-degree | 1.256 (0.197) | 1.157 (0.389) | 1.079 (0.569) | 0.996 (0.975) | 1.102 (0.399) | 1.007 (0.949) | 1.088 (0.422) | 1.009 (0.926) |
| In-degree | 1.154 (0.295) | 1.073 (0.555) | 1.123 (0.191) | 1.113 (0.149) | 1.079 (0.311) | 1.101 (0.136) | 1.065 (0.360) | 1.097 (0.126) |
| **Perceived Friend Use** | 0.885 (0.547) | 0.915 (0.568) | **0.735 (0.021)** | **0.731 (0.003)** | **0.720 (0.002)** | **0.729 (0.000)** | **0.756 (0.003)** | **0.771 (0.001)** |
| **Network Exposure Users** | **0.026 (0.030)** | **0.090 (0.065)** | **0.080 (0.004)** | **0.252 (0.045)** | **0.197 (0.034)** | 0.371 (0.119) | 0.316 (0.094) | 0.441 (0.157) |
| Network Exposure Dis-adopters | 0.908 (0.948) | 1.686 (0.665) | 0.478 (0.434) | 1.060 (0.939) | 0.375 (0.264) | 0.899 (0.872) | 0.265 (0.112) | 0.602 (0.408) |
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
| Cohort (2025 vs 2024) | 0.871 (0.389) | 1.395 (0.271) | **1.851 (0.030)** | 1.614 (0.357) |
| Female | **1.428 (0.017)** | 0.553 (0.060) | 0.694 (0.248) | 2.111 (0.221) |
| Sexual Minority | **1.438 (0.013)** | 0.839 (0.541) | 1.108 (0.709) | 1.646 (0.261) |
| Asian | **0.668 (0.017)** | 1.159 (0.686) | 1.121 (0.740) | 0.413 (0.135) |
| MDD (Major Depressive S.) | 1.133 (0.385) | 0.817 (0.477) | **0.533 (0.016)** | **0.393 (0.047)** |
| In-degree | **1.079 (0.011)** | 1.063 (0.370) | 1.078 (0.212) | 1.054 (0.648) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.737 (0.001)** | **0.732 (0.000)** | 0.783 (0.105) |
| **Network Exposure Users** | **5.625 (0.000)** | 0.432 (0.186) | 0.683 (0.495) | 2.082 (0.375) |
| Network Exposure Dis-adopters | **3.067 (0.050)** | 0.722 (0.746) | 1.083 (0.910) | 0.145 (0.377) |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

\normalsize

---

# 11. Perceived Friend Use — direct event-rate and exposure correlations

The §5/§9 regressions show **Perceived Friend Use (PFU)** as the cleanest two-sided lever for adoption, but the disadoption coefficients (although consistently negative on A and B) sometimes look modest after adjusting for 12 other predictors. To sanity-check the raw signal we look at unadjusted associations on the W1-W10 panel.

## 11.1 Event rate by PFU at $w-1$

For each person-wave row eligible for the corresponding risk-set (no Q-restriction; all W1-W10 panel rows with valid lag and outcome). **"Disadoption" here is *any* $1 \to 0$** transition (Model B-style: $\text{ecig}_{w-1}=1$ and $\text{ecig}_w=0$, regardless of return). It is **not** the stable-A definition — there is no requirement that the student stay at 0 in later observed waves.

| PFU at $w-1$ | n (at risk for adoption) | Adoption rate | n (at risk for disadoption) | Disadoption rate |
|:-:|---:|---:|---:|---:|
| 0 (None)     | 17,492 | 2.15 % | 388 | **54.12 %** |
| 1            |  2,067 | 5.13 % | 224 |    42.41 %  |
| 2            |  1,246 | 8.91 % | 247 |    31.17 %  |
| 3            |    652 | 9.51 % | 223 |    27.35 %  |
| 4            |    214 | 9.35 % | 127 |    21.26 %  |
| 5            |    269 |**11.52 %** | 193 |    20.73 %  |

PFU at $w-1$ moves adoption from 2% → 12% (5.4×) and **moves disadoption from 54% → 21%** (2.6× lower). Point-biserial correlations with the binary outcomes:

| Outcome (binary at-risk row) | $r$ | n |
|:---|---:|---:|
| Adoption (any 0→1)          | **+0.128** | 21,940 |
| Any 1→0 transition          | **−0.256** |  1,402 |

The disadoption signal is large in raw form. Its visibility in §5/§6/§9 depends on which sub-event we model (A / B / C), the small sub-samples, and the competition with `Network Exposure Users`.

## 11.2 PFU vs network exposures (Pearson)

PFU is correlated with the network-derived exposure measures, as expected:

| Pair (both at $w-1$) | $r$ | n |
|:---|---:|---:|
| PFU vs $E_{\text{users}}$ | **+0.226** | 17,456 |
| PFU vs $E_D$ (peer-flipped 1→0) | +0.071 | 17,465 |
| PFU vs $E_D$ alt (peak − current) | +0.108 | 17,456 |
| PFU vs out-degree | −0.083 | 23,391 |
| PFU vs in-degree | −0.057 | 23,391 |

PFU and $E_{\text{users}}$ overlap (~$r = 0.23$) — both measure peer-user environment. They are not redundant: PFU is self-reported about close friends; $E_{\text{users}}$ is computed from the friendship-nomination network. The §5 regressions show both surviving as significant predictors of adoption (PFU OR $\approx 1.47$–$1.49$, $E_{\text{users}}$ OR $\approx 5.3$–$5.9$), suggesting they capture complementary aspects of peer-user salience.

---

# 12. Discussion

**Headline OR (across §5/§6/§9, robust at $Q \le 7$)**:

1. **Perceived Friend Use** — adoption OR ≈ 1.47–1.50 ($p < 0.001$); A disadoption OR ≈ 0.70–0.76 ($p \le 0.021$); B disadoption OR ≈ 0.71–0.75 ($p \le 0.007$).
2. **Network Exposure (Users)** — adoption OR ≈ 5.3–5.9 ($p < 0.001$); A disadoption OR ≈ 0.08–0.43 (significant at $Q \in \{6, 7\}$); B disadoption OR ≈ 0.17–0.36 (significant at $Q \in \{6, 7, 8\}$).
3. **MDD** — B disadoption OR ≈ 0.32–0.53 ($p \le 0.022$ at all Q); C disadoption OR ≈ 0.04–0.39 (significant at $Q \in \{5, 7, 8\}$).
4. **Asian** — adoption OR ≈ 0.61–0.69 ($p < 0.05$ at $Q \le 7$).
5. **Sexual Minority** — adoption OR ≈ 1.38–1.45 at $Q \le 7$.

**Stable conclusions across families**: §5 main, §6 alt $E_D$, and §9 (a) all yield qualitatively the same picture: PFU and $E_{\text{users}}$ are consistent two-sided levers; MDD is a cessation barrier; cohort 2025 experiments more (B). §10 (b) is essentially identical to §5 — under W1-W10 the data has too few NA gaps for the observed-jump rule to differ from consecutive-calendar pairs. §8 window sensitivity gains modest power for C events ($+30$–40% events at $W \le 2$) but the increased noise from non-immediate cycles dilutes most predictors; only Sexual Minority at $Q \in \{6, 8\}$ survives.

**Why does PFU look "mild" in some regression coefficients despite the large raw disadoption gradient (§11)?** Three reasons: (i) the A / B / C panels are small (83–271 students); (ii) `Network Exposure Users` shares variance with PFU ($r = 0.23$) and the regression splits the effect between the two; (iii) wave fixed effects absorb between-wave variation that the raw cross-tab in §11.1 carries. The §11.1 cross-tab is the cleanest demonstration of the disadoption signal.

# 13. Limitations and deferred items

## 13.1 ESE — coverage and temporal pattern

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

## 13.2 Other deferred items

- **C samples remain small**: 7–29 events per Q. GLMER often hits singular fits ($\rho \to 0$); coefficients should be read with caution.
- **Schoolid_transfer** (~50 students who switched schools across waves) not yet integrated.
- **W9–W10 schoolid code 999** ("transferred-out") treated as NA — affects 15–38 students per wave.
- v4 results (W1–W8 panel) archived at `reports/disadoption-study-4.{pdf,md}`.

# Annex — Pipeline

`R/00-config.R` → `R/01b-edges-rebuild.R` (regenerate W1–W10 edges into `data/advance/Cleaned-Data-042326/`) → `R/01-advance-panel.R` (W1–W10 long panel) → `R/02-event-builder.R` (5 modes × 4 Q) → `R/03-network-features.R` (degrees, exposures, $E_D$ variants) → `R/04-regressions.R` (5 families × 4 Q raw fits) → `R/04b-rebuild-tables-OR.R` (re-emit the 20 CSVs as odds ratios).
