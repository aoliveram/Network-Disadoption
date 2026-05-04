---
title: "ADVANCE Disadoption Study v4"
subtitle: "Behavioural correlates of e-cigarette adoption and disadoption in California adolescents"
author: "A. Olivera, T. Valente, K. Miljkovic, Y. Cao"
date: \today
geometry: "margin=2.5cm"
fontsize: 11pt
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

This iteration drops the comparative KFP analysis from earlier versions (archived in `KFP-study/`) and focuses entirely on **disadoption of e-cigarette use among California high-school adolescents** in the ADVANCE longitudinal cohort. The diffusion-of-innovations literature has primarily studied adoption ($0 \to 1$); we attend instead to **disadoption** ($1 \to 0$, conditional on $1$ at some prior wave) — its substantive correlates and the way our peer-network environment shapes it.

Three operational definitions of disadoption are reported side by side, each capturing a substantively different leaving pattern. The same regression battery is run across four sample restrictions to test the robustness of conclusions to potentially-misclassified events introduced by missing trailing observations.

---

# 2. Data

## 2.1 Cohort and waves

We use the **ADVANCE 042326 release** (`ADVANCE_W1-W8_Data_Complete_042326.xlsx`), the latest available at the time of this analysis. The high-school panel covers waves W1–W8 (Fall 2020 – Spring 2024), with 4,437 unique students enrolled across 15 schools.

Class-of-2024 schools (101–105, 106–108, 112–114) entered the panel at W1 or W2; class-of-2025 schools (201, 212–214) entered at W3. The class assignment is time-invariant per student.

## 2.2 Outcome variable

`past_6mo_use_3` — past-6-month e-cigarette use (0/1). Per-wave non-NA counts in our panel: W1=851, W2=2,235, W3=3,768, W4=3,907, W5=3,833, W6=3,645, W7=3,378, W8=3,048 (24,265 person-waves total).

## 2.3 Network

Friendship nominations from `wXedges_clean.csv`. Out-degree (i nominates) and in-degree (i is nominated) computed per wave. Network exposures based on alters' e-cig states.

## 2.4 Covariates

Thirteen substantive predictors (ESE deferred — see §6.2):

| Predictor | Source variable(s) | Encoding |
|:---|:---|:---|
| Cohort | derived from schoolid | binary (2025 vs 2024) |
| Female | `W#_DEM_GENDER` | binary (1 if Female-at-birth) |
| Sexual Minority | `W#_DEM_sexuality` | binary (1 if non-Straight, code 10 "refused" → NA) |
| Parent Ed. | `W#_DEM_High_Par_Edu` | continuous 1..7 (W7-W8 nine-level scale harmonised: 5,6→4, 7→5, 8→6, 9→7); LOCF per student |
| Asian | `W#_Race == 2` | binary |
| Hispanic/Latine | `W#_eth == 1` | binary |
| MDD | `W#_RCADS_MDD_Mean` | continuous (0..3 scale; mean of 10 items) |
| GAD | `W#_RCADS_GAD_Mean` | continuous (0..3 scale; mean of 6 items) |
| Out-degree | edges, at $w-1$ | integer count |
| In-degree | edges, at $w-1$ | integer count |
| Perceived Friend Use | `W#_friends_use_ecig` at $w-1$ | 0..5 scale (code 6 "Not sure" → NA) |
| Network Exposure Users | $E_{i,w-1} = (W \mathbf{s}_{w-1})_i$ | peer share currently using e-cig |
| Network Exposure Dis-adopters | $E^{\mathrm{dis}}_{i,w-1} = (W \cdot \mathbb{1}[\mathbf{s}_{w-2}=1, \mathbf{s}_{w-1}=0])_i$ | peer share who flipped 1→0 between $w-2$ and $w-1$ |

---

# 3. Event definitions

## 3.1 Adoption

Outcome at person-wave $(i, w)$: $\mathrm{event} = 1$ if $\mathrm{ecig}_{i,w-1} = 0$, $\mathrm{ecig}_{i,w} = 1$, and the student had not previously adopted in any earlier wave. **One event per person.** The risk-set leaves the panel at the first adoption.

## 3.2 A — Stable Disadoption

A $1 \to 0$ transition between two consecutive observed waves, with **no future return to $1$ in any later observed wave** of the student's trajectory. **One event per person.** Students whose only $1\to 0$ transition is followed by NA-only future observations are *indeterminate* and dropped from A (see §6.1).

## 3.3 B — Experimental Disadoption

The **first** $1 \to 0$ transition in the student's observed sequence, regardless of what comes after. **One event per person.** B ⊇ A at the person level, since every A-event is also B's first $1\to 0$.

## 3.4 C — Unstable Disadoption (window = 1)

A $1 \to 0$ transition where the **immediately next observed wave** registers $1$ again. **A student can contribute multiple events** if they have multiple $1 \to 0 \to 1$ cycles. We use window = 1 for the main analysis and defer window = 2 (allowing $1 \to 0 \to 0 \to 1$) to a later iteration.

C-students are a strict subset of B-students at the person level (every cyclic $1\to 0$ implies a first $1\to 0$).

## 3.5 Q-restriction

The above definitions can mis-classify events when a student exits the panel after a $1 \to 0$. To bound this, we report results separately for $Q \in \{5, 6, 7, 8\}$ where $Q$ is the **minimum number of consecutive observed waves** of `past_6mo_use_3` per student. Higher $Q$ = stricter; $Q=8$ admits only the 5 schools that started at W1 (cohort 2024 only).

Network alters used to compute $E_{i,w-1}$ and $E^{\mathrm{dis}}_{i,w-1}$ are **not** restricted by Q — any nominated peer counts as long as their state is observed at the relevant wave.

Eligible students per Q:

| Q | Eligible students | Cohort 2024 | Cohort 2025 |
|:-:|---:|---:|---:|
| 5 | 2,972 | mostly | yes |
| 6 | 2,453 | yes | yes |
| 7 | 1,228 | yes | partial |
| 8 |   371 | schools 101–105 only | none |

---

# 4. Methods

For each $Q$, four logistic event-history regressions are fit, one per outcome column (Adopters, A, B, C). All four share the **same 13-predictor set**.

**Adopters / A / B**: GLM logistic with wave fixed effects and **cluster-robust SE by `record_id`** (Liang–Zeger via `sandwich::vcovCL`). One event per person makes a random intercept poorly identified.

**C**: Generalised linear mixed model with `lme4::glmer((1 | record_id))` and wave fixed effects, since C admits multiple events per person. We additionally report the intra-class correlation:

$$
\rho \;=\; \mathrm{ICC} \;=\; \frac{\sigma^2_u}{\sigma^2_u + \pi^2/3}.
$$

**No school fixed effects** in v4 — the cohort dummy and the network-exposure variables absorb the cohort-level peer environment, and the user-facing tables prioritise interpretability of the substantive predictors.

**Cohort dummy** is dropped at $Q=7$ and $Q=8$ where its variation collapses (rank-deficient).

Each regression cell reports the **logit coefficient** with its **clustered/glmer p-value** in parentheses: `coef (p)`.

---

# 5. Results

\fontsize{8}{10}\selectfont

## 5.1 Q = 5 (n_eligible = 2,972)

| Predictor | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.130 (0.422) | 0.444 (0.156) | **0.621 (0.034)** | -0.042 (0.946) |
| Female | **0.353 (0.022)** | **-0.728 (0.032)** | -0.464 (0.167) | 1.176 (0.091) |
| Sexual Minority | **0.380 (0.011)** | 0.049 (0.876) | 0.279 (0.335) | 0.348 (0.492) |
| Parent Ed. | -0.079 (0.135) | -0.020 (0.868) | -0.015 (0.907) | -0.061 (0.743) |
| Asian | **-0.440 (0.012)** | -0.198 (0.613) | 0.188 (0.620) | -0.844 (0.193) |
| Hispanic/Latine | 0.066 (0.703) | -0.275 (0.442) | -0.167 (0.616) | -0.716 (0.203) |
| MDD | 0.108 (0.471) | -0.173 (0.594) | **-0.714 (0.010)** | **-1.141 (0.038)** |
| GAD | -0.156 (0.257) | 0.052 (0.863) | 0.262 (0.325) | 0.526 (0.298) |
| Out-degree | -0.035 (0.432) | 0.096 (0.391) | 0.045 (0.663) | 0.054 (0.760) |
| In-degree | **0.072 (0.017)** | 0.052 (0.484) | 0.049 (0.425) | -0.007 (0.958) |
| Perceived Friend Use | **0.390 (0.000)** | **-0.263 (0.009)** | **-0.372 (0.000)** | **-0.413 (0.020)** |
| Network Exposure Users | **1.752 (0.000)** | -0.936 (0.172) | -0.107 (0.849) | 0.906 (0.320) |
| Network Exposure Dis-adopters | 1.061 (0.078) | -0.568 (0.594) | -0.058 (0.938) | -1.334 (0.563) |
| **Rho (ICC)** | — | — | — | 0.000 |
| **N Students** | 2,365 | 209 | 254 | 209 |
| **N Events** | 250 | 105 | 175 | 24 |

## 5.2 Q = 6 (n_eligible = 2,453)

| Predictor | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.121 (0.496) | 0.623 (0.070) | **0.724 (0.031)** | 0.123 (0.870) |
| Female | 0.260 (0.114) | -0.640 (0.080) | -0.379 (0.283) | 1.573 (0.070) |
| Sexual Minority | **0.354 (0.026)** | 0.016 (0.964) | 0.326 (0.321) | 0.550 (0.358) |
| Parent Ed. | -0.051 (0.383) | 0.006 (0.961) | 0.012 (0.931) | -0.150 (0.514) |
| Asian | **-0.549 (0.003)** | -0.215 (0.596) | 0.191 (0.640) | -1.007 (0.161) |
| Hispanic/Latine | 0.057 (0.756) | -0.224 (0.571) | -0.204 (0.577) | -1.041 (0.120) |
| MDD | 0.109 (0.508) | -0.287 (0.431) | **-0.739 (0.016)** | -1.045 (0.091) |
| GAD | -0.094 (0.525) | 0.037 (0.911) | 0.172 (0.566) | 0.449 (0.440) |
| Out-degree | -0.041 (0.379) | 0.123 (0.313) | -0.004 (0.975) | 0.002 (0.992) |
| In-degree | **0.082 (0.012)** | 0.094 (0.241) | 0.088 (0.196) | 0.041 (0.780) |
| Perceived Friend Use | **0.408 (0.000)** | **-0.285 (0.013)** | **-0.404 (0.000)** | **-0.459 (0.039)** |
| Network Exposure Users | **1.700 (0.000)** | -1.423 (0.056) | -0.660 (0.284) | 0.458 (0.717) |
| Network Exposure Dis-adopters | 0.440 (0.589) | -1.289 (0.281) | 0.022 (0.979) | -0.197 (0.931) |
| **Rho (ICC)** | — | — | — | 0.000 |
| **N Students** | 2,026 | 180 | 217 | 180 |
| **N Events** | 217 | 92 | 149 | 18 |

## 5.3 Q = 7 (n_eligible = 1,228)

Cohort dropped (rank deficient: very few class-of-2025 students remain).

| Predictor | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort | — | — | — | — |
| Female | 0.187 (0.398) | 0.008 (0.987) | 0.205 (0.653) | 6.828 (0.655) |
| Sexual Minority | 0.373 (0.073) | -0.184 (0.685) | -0.316 (0.453) | -0.963 (0.939) |
| Parent Ed. | -0.064 (0.374) | 0.065 (0.648) | -0.049 (0.786) | -1.750 (0.706) |
| Asian | **-0.489 (0.035)** | -0.325 (0.547) | 0.650 (0.187) | -3.200 (0.831) |
| Hispanic/Latine | -0.050 (0.831) | 0.140 (0.813) | 0.047 (0.922) | -4.132 (0.787) |
| MDD | 0.092 (0.664) | -0.186 (0.673) | -0.743 (0.067) | -5.667 (0.615) |
| GAD | -0.080 (0.680) | 0.307 (0.497) | 0.278 (0.466) | -0.891 (0.938) |
| Out-degree | -0.067 (0.270) | 0.230 (0.226) | -0.053 (0.759) | -0.775 (0.852) |
| In-degree | **0.109 (0.012)** | 0.076 (0.563) | 0.082 (0.396) | 0.991 (0.773) |
| Perceived Friend Use | **0.414 (0.000)** | -0.121 (0.424) | **-0.358 (0.004)** | -2.707 (0.506) |
| Network Exposure Users | **1.503 (0.001)** | **-2.556 (0.022)** | -0.605 (0.458) | 0.436 (0.985) |
| Network Exposure Dis-adopters | 1.075 (0.232) | -2.371 (0.082) | 0.012 (0.989) | 3.576 (0.951) |
| **Rho (ICC)** | — | — | — | 0.974 |
| **N Students** | 1,064 | 95 | 115 | 95 |
| **N Events** | 132 | 46 | 78 | 10 |

## 5.4 Q = 8 (n_eligible = 371; cohort 2024 only)

| Predictor | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort | — | — | — | — |
| Female | 0.248 (0.592) | -2.779 (0.058) | 0.235 (0.912) | 24.586 (1.000) |
| Sexual Minority | 0.264 (0.525) | **2.246 (0.045)** | -1.271 (0.479) | -34.559 (1.000) |
| Parent Ed. | -0.102 (0.351) | 0.603 (0.302) | **1.791 (0.023)** | -9.973 (1.000) |
| Asian | -0.833 (0.066) | 0.758 (0.550) | **4.255 (0.045)** | -60.095 (1.000) |
| Hispanic/Latine | -0.362 (0.439) | 1.953 (0.346) | **14.466 (0.011)** | -33.962 (1.000) |
| MDD | 0.204 (0.608) | -2.844 (0.099) | **-6.152 (0.044)** | -24.301 (1.000) |
| GAD | 0.163 (0.669) | **3.750 (0.016)** | **7.009 (0.014)** | -5.731 (1.000) |
| Out-degree | **-0.229 (0.047)** | **1.475 (0.009)** | 2.033 (0.112) | 12.853 (1.000) |
| In-degree | 0.144 (0.093) | 0.416 (0.381) | -1.130 (0.150) | -24.050 (1.000) |
| Perceived Friend Use | **0.485 (0.000)** | 0.898 (0.105) | -1.117 (0.222) | -22.117 (1.000) |
| Network Exposure Users | -0.603 (0.663) | -11.799 (0.065) | 2.944 (0.333) | -14.072 (1.000) |
| Network Exposure Dis-adopters | 1.337 (0.371) | 0.993 (0.747) | 11.344 (0.069) | 79.169 (1.000) |
| **Rho (ICC)** | — | — | — | 0.099 |
| **N Students** | 340 | 24 | 29 | 24 |
| **N Events** | 35 | 14 | 23 | 3 |

\normalsize

**Bold** marks $p < 0.05$.

---

# 6. Read across Q

## 6.1 Adopters

The **most stable adoption signals across Q** are:

- **Perceived Friend Use** at $w-1$: positive in all four samples ($\beta \approx 0.39$–$0.49$, $p < 0.001$). A 1-unit increase on the 0–5 scale corresponds to roughly $\mathrm{OR} \approx 1.5$ for adopting in the next wave.
- **Network Exposure Users**: positive at $Q \in \{5, 6, 7\}$ ($\beta \approx 1.5$–$1.8$, $p < 0.01$). A 10-percentage-point rise in peer e-cig prevalence corresponds to $\mathrm{OR} \approx 1.18$. The signal weakens at $Q=8$ where the sample is small (340 students, 35 events).
- **Asian** is consistently negative ($\beta \approx -0.44$ to $-0.83$, $p < 0.05$ at $Q \le 7$): Asian students adopt at lower rates conditional on the rest.
- **In-degree**: positive at $Q \le 7$ ($\beta \approx 0.07$–$0.14$, $p \le 0.017$). More popular kids have somewhat higher adoption odds.
- **Sexual Minority**: positive at $Q \in \{5, 6\}$, marginal at $Q=7$, ns at $Q=8$.
- **Female**: positive at $Q=5$ only.

## 6.2 A — Stable Disadoption

Stable disadoption (permanent quitters) shows fewer robust predictors. The most consistent is:

- **Perceived Friend Use** at $w-1$: **negative** in all four samples ($\beta \approx -0.12$ to $-0.29$, $p < 0.05$ at $Q=5$ and $Q=6$). Students whose friends use are **less** likely to permanently quit. Mirror image of the adoption signal — the same peer norm acts in opposite directions for entry vs permanent exit.
- **Female**: negative at $Q=5$ ($\beta = -0.73$, $p = 0.03$); marginal at $Q=6$. Female students are *less* likely to permanently quit conditional on having ever used.
- **Network Exposure Users**: marginal-to-significant negative at $Q \in \{6, 7\}$ ($\beta \approx -1.4$ to $-2.6$, $p \le 0.06$). Higher peer-user environment depresses the odds of permanent exit.

## 6.3 B — Experimental Disadoption

Experimental disadoption ("first $1\to 0$, regardless of return") is largely driven by:

- **Perceived Friend Use**: negative in all four samples (significant at $p \le 0.004$ in $Q \in \{5, 6, 7\}$). Larger magnitudes than for A, suggesting that peer-user norms protect *especially* against a student's first attempt to stop, regardless of whether the stop sticks.
- **MDD**: negative at $Q \in \{5, 6\}$ ($\beta \approx -0.71$ to $-0.74$, $p \le 0.016$); marginal at $Q=7$. Students with more depressive symptoms are **less** likely to attempt cessation.
- **Cohort 2025**: positive at $Q \in \{5, 6\}$ ($\beta \approx 0.62$–$0.72$, $p < 0.04$). The younger cohort experimented with cessation more often.

## 6.4 C — Unstable Disadoption (cyclic)

C is a small-event regime: only 24 / 18 / 10 / 3 cyclic events at $Q = 5/6/7/8$. The estimates are noisy, but at $Q \in \{5, 6\}$ where we have ≥18 events:

- **Perceived Friend Use**: negative ($\beta \approx -0.41$ to $-0.46$, $p \le 0.04$). Same direction as A and B.
- **MDD**: negative at $Q=5$ ($\beta = -1.14$, $p = 0.04$); marginal at $Q=6$. Like B.
- **Female**: positive marginal at $Q=5$ and $Q=6$ ($p \approx 0.07$–$0.09$).

The ICC $\rho$ is essentially 0 at $Q \in \{5, 6\}$ — almost no within-person variance is left after the fixed effects + 13 predictors, consistent with most cyclic students contributing only one event each. At $Q=7$, $\rho = 0.97$ with only 10 events is meaningless (boundary fit). At $Q=8$, the GLMM SE blows up (3 events).

---

# 7. Discussion

The clearest substantive picture is the role of **perceived peer use of e-cigarettes** as a two-sided lever:

- **Promotes adoption** — Perceived Friend Use raises adoption odds in every sample we look at, and Network Exposure Users does the same at $Q \le 7$.
- **Inhibits cessation** of every kind — A, B, and C all show negative Perceived Friend Use coefficients. The protective effect against permanent (A) cessation is somewhat smaller than against first-attempted (B) or cyclic (C), but the directional consistency is striking.

Two clinical-symptom predictors stand out as **cessation barriers**: students with higher MDD scores are less likely to make a first attempt at quitting (B) and less likely to successfully cycle out (C), in the larger samples. GAD does not show a comparable pattern.

**Demographics**: Asian students adopt at lower rates (consistent across $Q$); Female students adopt more in some samples but are less likely to permanently quit (A) at $Q=5$. Sexual Minority status raises adoption odds at $Q \in \{5, 6\}$.

**Network position**: in-degree (popularity) raises adoption odds; out-degree (nominations sent) shows a small negative trend on adoption at $Q=8$ but is otherwise null. Out-degree at $Q=8$ shows a positive coefficient on A (stable disadoption, $\beta=1.5, p=0.009$) — students who nominate more friends in the surveyed network are more likely to permanently quit — but this is a very small sample.

**Network exposure to dis-adopters** ($E^{\mathrm{dis}}$) is largely null in this iteration; the signal-to-noise ratio of "alters who flipped 1→0 in the previous wave" at the small sample sizes that subset to current users is too low. We expect this to stabilise with longer windows or pooled across more iterations.

---

# 8. Limitations and deferred items

1. **ESE excluded from main regressions.** The ESE composites (`Pos_no9_Mean`, `Neg_no510_Mean`) are only filled when a student has reported at least one e-cigarette use, and even then only ~40% of user-waves have valid scores. Including them would force complete-case dropping that biases the sample toward users; we defer ESE to a future sub-analysis on ever-users.
2. **Indeterminate $1\to 0$ cases.** ~36 events in the full panel are $1\to 0$ followed by NA-only future observations. Currently dropped from A. A future iteration could revisit with a missing-at-random imputation.
3. **Window=2 for C.** We use window=1 (immediate return) for the main analysis. Window=2 (1→0→0→1) is a planned sensitivity.
4. **Single-cohort restriction at $Q \in \{7, 8\}$.** The cohort dummy collapses; future work could pool with school random intercepts.
5. **W9-W10 HS extension** (post-W8 high-school waves for class of 2025) is not used here.

---

# 9. Annexes

## Annex A — Data quirks fixed in `R/01-advance-panel.R`

- **W1 schoolid encoding**: in the 042326 release, W1 schools appear with internal codes 1–5. Empirical mapping to W2+ codes (verified by tracking `record_id` between waves): 1→101, 2→104, 3→102, 4→103, 5→105.
- **Race code 8 (declined)** in W4–W5 (legacy not always recoded): we re-apply the NA recoding.
- **DEM_GENDER code 3** ("prefer not to disclose") set to NA for the Female dummy.
- **DEM_sexuality code 10** ("prefer not to disclose") set to NA for the Sexual Minority dummy.
- **friends_use_ecig code 6** ("Not sure") set to NA.
- **par_edu W7-W8 nine-level → W1-W6 seven-level**: 1→1, 2→2, 3→3, 4→4, 5→4 (vocational ≈ some college), 6→4 (associate's ≈ some college), 7→5, 8→6, 9→7. LOCF per student across waves.

## Annex B — Pipeline

Run `R/00-config.R` first; then `R/01-advance-panel.R`, `R/02-event-builder.R`, `R/03-network-features.R`, `R/04-regressions.R` in order. Outputs land in `outputs/intermediate/v4_*.rds` and `outputs/tables/v4_regression_table_Q*.csv`.

## Annex C — KFP archive

Earlier KFP-vs-ADVANCE comparative work (v1–v3) is archived locally at `KFP-study/` and in `reports/disadoption-study-{1,2,3}.{pdf,md}`.
