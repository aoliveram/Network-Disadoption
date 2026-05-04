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
- **§7 Model C window sensitivity**: $W=1$, $W \le 2$, $W \le 3$ for the cyclic disadoption definition.
- **§8 Sensitivity (a)**: $1 \to 0$ with NA-only future counted as Stable (A).
- **§9 Sensitivity (b)**: event identification using observed-wave jumps rather than consecutive-calendar pairs.

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
| 9  | 2,833  | 2,665  | 2,665 | 94.4 | 94.1 | 100.0 |
| 10 | 2,806  | 2,511  | 2,511 | 90.4 | 89.5 | 100.0 |

Jaccard ≥ 97% in W1–W8; W9–W10 lower (94% / 90%) reflecting that the legacy CSVs there had additional edges from a slightly more permissive cleaning rule. **In W1–W8, ≥98% of legacy edges are present in v4b**, and 100% of v4b edges in W1, W2, W9, W10 were already in the legacy set.

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
- **A — Stable**: $1 \to 0$ with **no future return to 1** in any later observed wave. One event per person. Indeterminates ($1 \to 0$ with NA-only future) are dropped from A in §5/§6/§7/§9; counted as A in §8.
- **B — Experimental**: first $1 \to 0$ (any). One event per person.
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves. Multiple events per person possible. §5/§6/§8/§9 use $W=1$; §7 reports $W=1, 2, 3$.

§9 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs).

# 4. Methods

For each regression, the outcome at person-wave $(i, w)$ is binary; the risk-set is the corresponding panel:

- **Adopters / A / B**: GLM logistic with wave fixed effects and cluster-robust SE by `record_id` (`sandwich::vcovCL`).
- **C**: `lme4::glmer(... + (1 \mid \text{record\_id}))` with wave FE, since C admits multiple events per person; we report ICC $\rho = \sigma^2_u / (\sigma^2_u + \pi^2/3)$.

**Predictors (13)**: cohort (2025 vs 2024), female, sexual minority, parent education, asian, hispanic/latine, MDD (RCADS Mean), GAD (RCADS Mean), out-degree, in-degree, perceived friend use ($w-1$), network exposure to users ($E_{\text{users}}, w-1$), network exposure to dis-adopters ($E_D, w-1$). The cohort dummy is dropped at $Q=8$ (only cohort 2024 schools 101–105 remain).

**Note on ESE**: the Early Smoking Experience composites (`ESE_Pos_no9_Mean`, `ESE_Neg_no510_Mean`) are **not used as predictors** in v4b — only ~21% of students have any ESE response, and the missingness is concentrated outside the at-risk-for-disadoption sub-population (see §11). Including ESE forces complete-case dropping that selects toward users and biases the Adopters and A/B/C samples. Sensitivity work on the user-subset is deferred to a later iteration.

§6 substitutes $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ for the §5 definition.

\fontsize{8}{10}\selectfont

---

# 5. Main results (E_D = peer-flipped 1→0; C window = 1)

OR (p-value). Bold = $p < 0.05$.

## 5.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 1.620 (0.069) | 0.368 (0.076) | 0.336 (0.056) | 0.403 (0.624) |
| Sexual Minority | 1.536 (0.089) | 1.043 (0.944) | 1.896 (0.255) | **28.020 (0.042)** |
| Parent Ed. | 0.961 (0.633) | 1.209 (0.346) | 1.113 (0.631) | 0.324 (0.228) |
| Asian | 0.568 (0.051) | 0.898 (0.874) | 0.576 (0.395) | 0.242 (0.445) |
| Hispanic/Latine | 1.019 (0.949) | 0.674 (0.558) | 0.624 (0.496) | 0.021 (0.175) |
| MDD | 1.228 (0.401) | 0.514 (0.139) | **0.323 (0.022)** | **0.045 (0.029)** |
| GAD | 0.883 (0.574) | 2.123 (0.155) | 1.863 (0.202) | 6.669 (0.263) |
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
| MDD | 1.177 (0.345) | 0.715 (0.323) | **0.431 (0.006)** | **0.245 (0.034)** |
| GAD | 0.865 (0.348) | 1.365 (0.364) | 1.099 (0.762) | 0.980 (0.976) |
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
| MDD | 1.125 (0.457) | 0.733 (0.323) | **0.504 (0.017)** | 0.395 (0.082) |
| GAD | 0.892 (0.418) | 1.224 (0.495) | 1.112 (0.712) | 1.363 (0.561) |
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
| MDD | 1.133 (0.385) | 0.817 (0.477) | **0.533 (0.016)** | **0.393 (0.047)** |
| GAD | 0.850 (0.214) | 1.175 (0.541) | 1.182 (0.512) | 1.384 (0.470) |
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
| MDD | 1.236 (0.387) | 0.503 (0.128) | **0.310 (0.014)** | **0.021 (0.041)** |
| GAD | 0.882 (0.573) | 2.201 (0.144) | 1.916 (0.190) | 12.901 (0.198) |
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
| MDD | 1.180 (0.341) | 0.713 (0.313) | **0.416 (0.005)** | **0.228 (0.028)** |
| GAD | 0.865 (0.348) | 1.359 (0.366) | 1.131 (0.690) | 1.036 (0.957) |
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
| MDD | 1.130 (0.440) | 0.717 (0.288) | **0.494 (0.014)** | 0.376 (0.067) |
| GAD | 0.890 (0.407) | 1.244 (0.459) | 1.130 (0.664) | 1.439 (0.496) |
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
| MDD | 1.132 (0.390) | 0.797 (0.423) | **0.524 (0.013)** | **0.392 (0.046)** |
| GAD | 0.849 (0.209) | 1.196 (0.498) | 1.193 (0.480) | 1.406 (0.449) |
| Out-degree | 0.946 (0.208) | 1.087 (0.422) | 1.020 (0.850) | 1.037 (0.817) |
| In-degree | **1.079 (0.010)** | 1.065 (0.360) | 1.080 (0.201) | 1.054 (0.638) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.756 (0.003)** | **0.751 (0.001)** | 0.788 (0.121) |
| **Network Exposure Users** | **5.953 (0.000)** | 0.316 (0.094) | 0.505 (0.251) | 1.775 (0.514) |
| $E_D$ alt | 2.024 (0.097) | 0.265 (0.112) | 0.321 (0.090) | 0.373 (0.554) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 7. Model C window sensitivity

Three columns per Q: $C$ at $W=1$ (immediate return), $W \le 2$, $W \le 3$.

**Event-count summary** (number of cyclic 1→0 events for the same Q-eligible sample):

| Q | C, W=1 | C, W ≤ 2 | C, W ≤ 3 | Δ(W≤2 − W=1) | Δ(W≤3 − W=2) |
|:-:|---:|---:|---:|---:|---:|
| 8 | 17 | 27 | 29 | +10 | +2 |
| 7 | 43 | 63 | 68 | +20 | +5 |
| 6 | 66 | 92 | 97 | +26 | +5 |
| 5 | 81 | 114 | 121 | +33 | +7 |

The big increment is from $W=1 \to W \le 2$ (~30–40% more events); $W \le 3$ adds little beyond $W \le 2$.

## 7.1 Q = 8

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — |
| Female | 0.403 (0.624) | 1.132 (0.918) | 1.132 (0.918) |
| Sexual Minority | **28.020 (0.042)** | **12.456 (0.037)** | **12.456 (0.037)** |
| Parent Ed. | 0.324 (0.228) | 0.960 (0.926) | 0.960 (0.926) |
| Asian | 0.242 (0.445) | 0.378 (0.439) | 0.378 (0.439) |
| Hispanic/Latine | 0.021 (0.175) | 1.270 (0.852) | 1.270 (0.852) |
| MDD | **0.045 (0.029)** | 0.373 (0.212) | 0.373 (0.212) |
| GAD | 6.669 (0.263) | 0.957 (0.966) | 0.957 (0.966) |
| Out-degree | 1.644 (0.382) | 0.933 (0.831) | 0.933 (0.831) |
| In-degree | 0.323 (0.113) | 0.727 (0.288) | 0.727 (0.288) |
| Perceived Friend Use | 2.308 (0.236) | 0.888 (0.775) | 0.888 (0.775) |
| Network Exposure Users | 0.206 (0.640) | 0.296 (0.604) | 0.296 (0.604) |
| Network Exposure Dis-adopters | 0.015 (0.511) | 0.801 (0.923) | 0.801 (0.923) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 83 | 83 | 83 |
| N Events | 7 | 11 | 11 |

## 7.2 Q = 7

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.367 (0.698) | 2.628 (0.861) | 4.860 (0.834) |
| Female | 3.045 (0.180) | 2.789 (0.828) | 2.331 (0.901) |
| Sexual Minority | 1.200 (0.779) | 4.524 (0.658) | 2.358 (0.869) |
| Parent Ed. | 0.607 (0.089) | 0.342 (0.526) | 0.438 (0.745) |
| Asian | 0.355 (0.194) | 0.395 (0.866) | 0.114 (0.770) |
| Hispanic/Latine | 0.245 (0.085) | 0.284 (0.816) | 0.037 (0.671) |
| MDD | **0.245 (0.034)** | 0.066 (0.454) | 0.144 (0.711) |
| GAD | 0.980 (0.976) | 0.675 (0.908) | 0.178 (0.737) |
| Out-degree | 0.935 (0.785) | 0.595 (0.636) | 0.451 (0.607) |
| In-degree | 1.057 (0.743) | 1.243 (0.838) | 1.317 (0.849) |
| Perceived Friend Use | 0.726 (0.203) | 0.786 (0.818) | 0.586 (0.728) |
| Network Exposure Users | 1.477 (0.784) | 0.628 (0.957) | 2.790 (0.924) |
| Network Exposure Dis-adopters | 0.277 (0.660) | 0.851 (0.991) | 5.358 (0.933) |
| Rho (ICC) | 0.000 | 0.953 | 0.975 |
| N Students | 161 | 161 | 161 |
| N Events | 15 | 20 | 21 |

## 7.3 Q = 6

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.621 (0.479) | 2.537 (0.123) | 2.586 (0.111) |
| Female | 2.507 (0.211) | 1.508 (0.504) | 1.649 (0.412) |
| Sexual Minority | 2.333 (0.117) | **2.743 (0.046)** | 2.622 (0.051) |
| Parent Ed. | 0.835 (0.420) | 0.840 (0.399) | 0.905 (0.609) |
| Asian | 0.412 (0.187) | 0.310 (0.073) | 0.431 (0.174) |
| Hispanic/Latine | 0.444 (0.193) | 0.554 (0.289) | 0.548 (0.279) |
| MDD | 0.395 (0.082) | 0.573 (0.237) | 0.516 (0.160) |
| GAD | 1.363 (0.561) | 0.885 (0.802) | 0.885 (0.801) |
| Out-degree | 0.999 (0.994) | 0.953 (0.777) | 0.946 (0.739) |
| In-degree | 1.107 (0.445) | 1.144 (0.270) | 1.118 (0.349) |
| Perceived Friend Use | 0.756 (0.150) | 0.818 (0.235) | 0.850 (0.317) |
| Network Exposure Users | 1.149 (0.906) | 0.662 (0.708) | 1.083 (0.938) |
| Network Exposure Dis-adopters | 0.431 (0.703) | 2.036 (0.607) | 2.098 (0.595) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 206 | 206 | 206 |
| N Events | 21 | 26 | 27 |

## 7.4 Q = 5

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 1.614 (0.357) | 2.005 (0.146) | 1.996 (0.148) |
| Female | 2.111 (0.221) | 1.464 (0.481) | 1.530 (0.429) |
| Sexual Minority | 1.646 (0.261) | 1.628 (0.241) | 1.609 (0.247) |
| Parent Ed. | 0.862 (0.413) | 0.844 (0.316) | 0.890 (0.473) |
| Asian | 0.413 (0.135) | 0.333 (0.055) | 0.437 (0.132) |
| Hispanic/Latine | 0.538 (0.223) | 0.588 (0.251) | 0.591 (0.256) |
| MDD | **0.393 (0.047)** | 0.552 (0.156) | 0.510 (0.107) |
| GAD | 1.384 (0.470) | 1.125 (0.775) | 1.131 (0.766) |
| Out-degree | 1.049 (0.763) | 1.078 (0.606) | 1.075 (0.613) |
| In-degree | 1.054 (0.648) | 1.028 (0.789) | 1.014 (0.892) |
| Perceived Friend Use | 0.783 (0.105) | 0.818 (0.144) | 0.842 (0.202) |
| Network Exposure Users | 2.082 (0.375) | 1.451 (0.638) | 1.969 (0.380) |
| Network Exposure Dis-adopters | 0.145 (0.377) | 0.987 (0.992) | 0.980 (0.989) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 237 | 237 | 237 |
| N Events | 29 | 35 | 36 |

---

# 8. Sensitivity (a) — indeterminates counted as Stable (A)

In §5/§6/§7/§9, $1 \to 0$ events with NA-only future are dropped from A (we cannot verify "no return"). §8 instead **counts them as A events** (assumes the student would not have returned). Adopters / B / C are unchanged from §5; only A's panel grows.

**Event-count summary** (A column only; rest unchanged from §5):

| Q | A events §5 | A events §8 | Δ |
|:-:|---:|---:|---:|
| 8 |  96 | 129 | +33  (+34%) |
| 7 | 189 | 261 | +72  (+38%) |
| 6 | 244 | 338 | +94  (+39%) |
| 5 | 288 | 404 | +116 (+40%) |

Adopters / B / C cells in §8 are byte-identical to §5 (visual consistency only).

## 8.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 1.620 (0.069) | 0.508 (0.201) | 0.336 (0.056) | 0.403 (0.624) |
| Sexual Minority | 1.536 (0.089) | 0.840 (0.734) | 1.896 (0.255) | **28.020 (0.042)** |
| Parent Ed. | 0.961 (0.633) | 1.163 (0.449) | 1.113 (0.631) | 0.324 (0.228) |
| Asian | 0.568 (0.051) | 0.745 (0.589) | 0.576 (0.395) | 0.242 (0.445) |
| Hispanic/Latine | 1.019 (0.949) | 0.884 (0.818) | 0.624 (0.496) | 0.021 (0.175) |
| MDD | 1.228 (0.401) | 0.598 (0.196) | **0.323 (0.022)** | **0.045 (0.029)** |
| GAD | 0.883 (0.574) | 1.176 (0.702) | 1.863 (0.202) | 6.669 (0.263) |
| Out-degree | **0.828 (0.011)** | 1.176 (0.337) | 1.033 (0.876) | 1.644 (0.382) |
| In-degree | 1.097 (0.058) | 1.066 (0.597) | 1.066 (0.633) | 0.323 (0.113) |
| **Perceived Friend Use** | **1.471 (0.000)** | 0.916 (0.562) | 1.026 (0.887) | 2.308 (0.236) |
| **Network Exposure Users** | **3.772 (0.034)** | **0.067 (0.041)** | **0.047 (0.016)** | 0.206 (0.640) |
| Network Exposure Dis-adopters | 3.027 (0.254) | 2.972 (0.324) | 0.462 (0.494) | 0.015 (0.511) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 96 | 91 | 83 |
| N Events | 89 | 66 | 70 | 7 |

## 8.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.915 (0.634) | 1.527 (0.208) | **2.436 (0.017)** | 1.367 (0.698) |
| Female | 1.343 (0.104) | 0.922 (0.818) | 0.997 (0.995) | 3.045 (0.180) |
| Sexual Minority | **1.454 (0.030)** | 0.780 (0.465) | 0.939 (0.863) | 1.200 (0.779) |
| Parent Ed. | 0.957 (0.471) | 0.971 (0.826) | 0.928 (0.650) | 0.607 (0.089) |
| Asian | **0.617 (0.014)** | 1.133 (0.738) | 1.041 (0.923) | 0.355 (0.194) |
| Hispanic/Latine | 1.060 (0.769) | 0.948 (0.889) | 0.676 (0.327) | 0.245 (0.085) |
| MDD | 1.177 (0.345) | 0.676 (0.205) | **0.431 (0.006)** | **0.245 (0.034)** |
| GAD | 0.865 (0.348) | 0.999 (0.996) | 1.099 (0.762) | 0.980 (0.976) |
| Out-degree | 0.920 (0.100) | 0.996 (0.974) | 0.881 (0.348) | 0.935 (0.785) |
| In-degree | **1.096 (0.010)** | 1.113 (0.150) | 1.161 (0.063) | 1.057 (0.743) |
| **Perceived Friend Use** | **1.471 (0.000)** | **0.733 (0.003)** | **0.727 (0.003)** | 0.726 (0.203) |
| **Network Exposure Users** | **5.331 (0.000)** | **0.247 (0.034)** | **0.222 (0.027)** | 1.477 (0.784) |
| Network Exposure Dis-adopters | 2.916 (0.160) | 0.939 (0.936) | 0.572 (0.496) | 0.277 (0.660) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 191 | 182 | 161 |
| N Events | 193 | 122 | 129 | 15 |

## 8.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.856 (0.372) | 1.453 (0.213) | **2.235 (0.017)** | 1.621 (0.479) |
| Female | 1.296 (0.102) | 0.819 (0.521) | 0.752 (0.396) | 2.507 (0.211) |
| Sexual Minority | **1.385 (0.037)** | 0.763 (0.354) | 1.149 (0.661) | 2.333 (0.117) |
| Parent Ed. | 0.953 (0.393) | 1.027 (0.816) | 1.024 (0.858) | 0.835 (0.420) |
| Asian | **0.613 (0.007)** | 1.177 (0.628) | 1.120 (0.764) | 0.412 (0.187) |
| Hispanic/Latine | 1.121 (0.520) | 0.971 (0.924) | 0.881 (0.712) | 0.444 (0.193) |
| MDD | 1.125 (0.457) | 0.670 (0.160) | **0.504 (0.017)** | 0.395 (0.082) |
| GAD | 0.892 (0.418) | 0.983 (0.950) | 1.112 (0.712) | 1.363 (0.561) |
| Out-degree | 0.942 (0.191) | 1.008 (0.935) | 0.969 (0.787) | 0.999 (0.994) |
| In-degree | **1.087 (0.010)** | 1.101 (0.135) | 1.123 (0.086) | 1.107 (0.445) |
| **Perceived Friend Use** | **1.502 (0.000)** | **0.726 (0.000)** | **0.713 (0.000)** | 0.756 (0.150) |
| **Network Exposure Users** | **5.388 (0.000)** | 0.381 (0.100) | 0.359 (0.088) | 1.149 (0.906) |
| Network Exposure Dis-adopters | 1.929 (0.368) | 1.333 (0.687) | 0.872 (0.863) | 0.431 (0.703) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 245 | 233 | 206 |
| N Events | 232 | 150 | 159 | 21 |

## 8.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.871 (0.389) | 1.322 (0.288) | **1.851 (0.030)** | 1.614 (0.357) |
| Female | **1.428 (0.017)** | 0.755 (0.335) | 0.694 (0.248) | 2.111 (0.221) |
| Sexual Minority | **1.438 (0.013)** | 0.838 (0.492) | 1.108 (0.709) | 1.646 (0.261) |
| Parent Ed. | 0.932 (0.181) | 1.014 (0.903) | 0.992 (0.946) | 0.862 (0.413) |
| Asian | **0.668 (0.017)** | 1.170 (0.614) | 1.121 (0.740) | 0.413 (0.135) |
| Hispanic/Latine | 1.148 (0.407) | 0.973 (0.926) | 0.915 (0.772) | 0.538 (0.223) |
| MDD | 1.133 (0.385) | 0.718 (0.202) | **0.533 (0.016)** | **0.393 (0.047)** |
| GAD | 0.850 (0.214) | 0.995 (0.982) | 1.182 (0.512) | 1.384 (0.470) |
| Out-degree | 0.946 (0.198) | 1.017 (0.859) | 1.029 (0.773) | 1.049 (0.763) |
| In-degree | **1.079 (0.011)** | 1.096 (0.125) | 1.078 (0.212) | 1.054 (0.648) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.756 (0.000)** | **0.732 (0.000)** | 0.783 (0.105) |
| **Network Exposure Users** | **5.625 (0.000)** | 0.510 (0.217) | 0.683 (0.495) | 2.082 (0.375) |
| Network Exposure Dis-adopters | **3.067 (0.050)** | 1.662 (0.408) | 1.083 (0.910) | 0.145 (0.377) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 283 | 271 | 237 |
| N Events | 267 | 169 | 185 | 29 |

---

# 9. Sensitivity (b) — observed-wave jumps

§9 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs).

**Event-count summary** vs §5 main:

| Q | adopt (§5) | adopt (§9) | A (§5) | A (§9) | B (§5) | B (§9) | C (§5) | C (§9) |
|:-:|---:|---:|---:|---:|---:|---:|---:|---:|
| 8 | 162 | 162 |  96 |  96 | 142 | 142 | 17 | 17 |
| 7 | 346 | 346 | 189 | 189 | 293 | 293 | 43 | 43 |
| 6 | 449 | 449 | 244 | 244 | 384 | 384 | 66 | 66 |
| 5 | 551 | 551 | 288 | 288 | 467 | 465 | 81 | 81 |

The W1-W10 panel has very few NA gaps within consecutive observations; observed-wave jumps and calendar-pair logic produce nearly identical event sets (only B at Q=5 differs by 2 events). Tables §9.1–§9.4 are therefore visually indistinguishable from §5.1–§5.4 and we reproduce only Q = 5 here for reference; the full set is in `outputs/tables/v4b_table_9_Q{8,7,6,5}.csv`.

## 9.1 Q = 5 (representative)

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.871 (0.389) | 1.395 (0.271) | **1.851 (0.030)** | 1.614 (0.357) |
| Female | **1.428 (0.017)** | 0.553 (0.060) | 0.694 (0.248) | 2.111 (0.221) |
| Sexual Minority | **1.438 (0.013)** | 0.839 (0.541) | 1.108 (0.709) | 1.646 (0.261) |
| Asian | **0.668 (0.017)** | 1.159 (0.686) | 1.121 (0.740) | 0.413 (0.135) |
| MDD | 1.133 (0.385) | 0.817 (0.477) | **0.533 (0.016)** | **0.393 (0.047)** |
| In-degree | **1.079 (0.011)** | 1.063 (0.370) | 1.078 (0.212) | 1.054 (0.648) |
| **Perceived Friend Use** | **1.486 (0.000)** | **0.737 (0.001)** | **0.732 (0.000)** | 0.783 (0.105) |
| **Network Exposure Users** | **5.625 (0.000)** | 0.432 (0.186) | 0.683 (0.495) | 2.082 (0.375) |
| Network Exposure Dis-adopters | **3.067 (0.050)** | 0.722 (0.746) | 1.083 (0.910) | 0.145 (0.377) |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

\normalsize

---

# 10. Perceived Friend Use — direct event-rate and exposure correlations

The §5/§8 regressions show **Perceived Friend Use (PFU)** as the cleanest two-sided lever for adoption, but the disadoption coefficients (although consistently negative on A and B) sometimes look modest after adjusting for 12 other predictors. To sanity-check the raw signal we look at unadjusted associations on the W1-W10 panel.

## 10.1 Event rate by PFU at $w-1$

For each person-wave row eligible for the corresponding risk-set (no Q-restriction; all W1-W10 panel rows with valid lag and outcome):

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

The disadoption signal is large in raw form. Its visibility in §5/§6/§8 depends on which sub-event we model (A / B / C), the small sub-samples, and the competition with `Network Exposure Users`.

## 10.2 PFU vs network exposures (Pearson)

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

# 11. Discussion

**Headline OR (across §5/§6/§8, robust at $Q \le 7$)**:

1. **Perceived Friend Use** — adoption OR ≈ 1.47–1.50 ($p < 0.001$); A disadoption OR ≈ 0.70–0.76 ($p \le 0.021$); B disadoption OR ≈ 0.71–0.75 ($p \le 0.007$).
2. **Network Exposure (Users)** — adoption OR ≈ 5.3–5.9 ($p < 0.001$); A disadoption OR ≈ 0.08–0.43 (significant at $Q \in \{6, 7\}$); B disadoption OR ≈ 0.17–0.36 (significant at $Q \in \{6, 7, 8\}$).
3. **MDD** — B disadoption OR ≈ 0.32–0.53 ($p \le 0.022$ at all Q); C disadoption OR ≈ 0.04–0.39 (significant at $Q \in \{5, 7, 8\}$).
4. **Asian** — adoption OR ≈ 0.61–0.69 ($p < 0.05$ at $Q \le 7$).
5. **Sexual Minority** — adoption OR ≈ 1.38–1.45 at $Q \le 7$.

**Stable conclusions across families**: §5 main, §6 alt $E_D$, and §8 (a) all yield qualitatively the same picture: PFU and $E_{\text{users}}$ are consistent two-sided levers; MDD is a cessation barrier; cohort 2025 experiments more (B). §9 (b) is essentially identical to §5 — under W1-W10 the data has too few NA gaps for the observed-jump rule to differ from consecutive-calendar pairs. §7 window sensitivity gains modest power for C events ($+30$–40% events at $W \le 2$) but the increased noise from non-immediate cycles dilutes most predictors; only Sexual Minority at $Q \in \{6, 8\}$ survives.

**Why does PFU look "mild" in some regression coefficients despite the large raw disadoption gradient (§10)?** Three reasons: (i) the A / B / C panels are small (83–271 students); (ii) `Network Exposure Users` shares variance with PFU ($r = 0.23$) and the regression splits the effect between the two; (iii) wave fixed effects absorb between-wave variation that the raw cross-tab in §10.1 carries. The §10.1 cross-tab is the cleanest demonstration of the disadoption signal.

# 12. Limitations and deferred items

## 12.1 ESE — coverage and temporal pattern

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

## 12.2 Other deferred items

- **C samples remain small**: 7–29 events per Q. GLMER often hits singular fits ($\rho \to 0$); coefficients should be read with caution.
- **Schoolid_transfer** (~50 students who switched schools across waves) not yet integrated.
- **W9–W10 schoolid code 999** ("transferred-out") treated as NA — affects 15–38 students per wave.
- v4 results (W1–W8 panel) archived at `reports/disadoption-study-4.{pdf,md}`.

# Annex — Pipeline

`R/00-config.R` → `R/01b-edges-rebuild.R` (regenerate W1–W10 edges into `data/advance/Cleaned-Data-042326/`) → `R/01-advance-panel.R` (W1–W10 long panel) → `R/02-event-builder.R` (5 modes × 4 Q) → `R/03-network-features.R` (degrees, exposures, $E_D$ variants) → `R/04-regressions.R` (5 families × 4 Q raw fits) → `R/04b-rebuild-tables-OR.R` (re-emit the 20 CSVs as odds ratios).
