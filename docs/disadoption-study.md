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

- **§5 Main**: the v4 spec (network exposure to dis-adopters, $E_D$, defined as the peer share who flipped $1 \to 0$ between $w-2$ and $w-1$).
- **§6 Alt $E_D$**: an alternative operationalisation using $E_D = E^{\max}_{i,1..w-1} - E_{i,w-1}$ (cumulative peak of the user-exposure minus current exposure).
- **§7 Model C window sensitivity**: $W=1$, $W \le 2$, $W \le 3$ for the cyclic disadoption definition.
- **§8 Sensitivity (a)**: $1 \to 0$ events with NA-only future ("indeterminate") **counted as Stable disadoption (A)**.
- **§9 Sensitivity (b)**: event identification using **observed-wave jumps** rather than consecutive-calendar pairs.

The same 13-predictor set is used in every regression (ESE excluded due to sparsity; deferred to a future iteration).

# 2. Data

## 2.1 Sources and panel construction

- **W1-W8**: `data/advance/Data/ADVANCE_W1-W8_Data_Complete_042326.xlsx` (4,437 students, 10,341 columns).
- **W9-W10 HS**: `data/advance/Data/ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx` (1,060 students, all a strict subset of W1-W8).
- **Edges**: regenerated from the 042326 XLSX into `data/advance/Cleaned-Data-042326/wNedges_clean.csv` for $N=1..10$. Uniform construction rule: keep edge $(i, j)$ iff $j \neq i$, $j$ is in the panel, and $j$ responded to wave $w$. W1 edges adopt the legacy `Cleaned-Data/w1edges_clean.csv` after applying the same hygiene rules (the W1 XLSX stores friend cells as REDCap-internal codes without an embedded record_id mapping).

Per-wave panel non-NA `past_6mo_use_3` counts: W1 = 851, W2 = 2,235, W3 = 3,768, W4 = 3,907, W5 = 3,833, W6 = 3,645, W7 = 3,378, W8 = 3,048, **W9 = 974, W10 = 969**.

Per-wave edge counts (clean): W1 = 1,466, W2 = 4,344, W3 = 9,681, W4 = 10,133, W5 = 9,987, W6 = 8,850, W7 = 8,120, W8 = 6,879, **W9 = 2,665, W10 = 2,511**. Self-loops dropped in all waves; reciprocity 50–55% throughout.

## 2.2 Q-restriction

Eligibility per Q ∈ {5, 6, 7, 8} requires the student to have at least Q **consecutive** observed waves of `past_6mo_use_3`. Adding W9-W10 dramatically expands the high-Q samples:

| Q (consecutive) | v4 (W1-W8) | **v4b (W1-W10)** |
|:-:|---:|---:|
| 8 | 371 | **1,040** |
| 7 | 1,228 | **1,961** |
| 6 | 2,453 | **2,499** |
| 5 | 2,972 | **3,007** |

Network alters used in $E_{\text{users}}$ and $E_D$ are not restricted by Q.

# 3. Event definitions (v4b)

For each student we define, on consecutive observed waves:

- **Adopters**: first $0 \to 1$ transition. One event per person.
- **A — Stable**: $1 \to 0$ with **no future return to 1** in any later observed wave. One event per person. Indeterminates ($1 \to 0$ with NA-only future) are **dropped from A** in §5/§6/§7/§9; **counted as A** in §8.
- **B — Experimental**: first $1 \to 0$ (any). One event per person.
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves. Multiple events per person possible. §5/§6/§8/§9 use $W=1$; §7 reports $W=1, 2, 3$.

§9 uses **observed-wave jumps** (skip NA gaps; use the last observed value as the prev-wave state) instead of consecutive-calendar pairs.

# 4. Methods

For each regression: outcome at person-wave $(i, w)$ is binary; risk-set is the corresponding panel.

- **Adopters / A / B**: GLM logistic with wave fixed effects and **cluster-robust SE by `record_id`** (Liang–Zeger, `sandwich::vcovCL`).
- **C**: `lme4::glmer((1 \mid \text{record\_id}))` with wave FE, since C admits multiple events per person; we report ICC $\rho = \sigma^2_u / (\sigma^2_u + \pi^2/3)$.

Predictors (13): cohort (2025 vs 2024), female, sexual minority, parent education, asian, hispanic/latine, MDD (RCADS Mean), GAD (RCADS Mean), out-degree, in-degree, perceived friend use, network exposure to users ($E_{\text{users}}$), network exposure to dis-adopters ($E_D$). The cohort dummy is dropped at $Q=8$ (only cohort 2024 schools 101–105 remain).

§6 substitutes $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ for the §5 definition.

Each cell of every table reports `coef (p-value)`. **Bold** marks $p < 0.05$.

\fontsize{8}{10}\selectfont

---

# 5. Main results (E_D = peer-flipped 1→0; C window=1)

## 5.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 0.482 (0.069) | -0.999 (0.076) | -1.090 (0.056) | -0.909 (0.624) |
| Sexual Minority | 0.429 (0.089) | 0.042 (0.944) | 0.640 (0.255) | **3.333 (0.042)** |
| Parent Ed. | -0.040 (0.633) | 0.190 (0.346) | 0.107 (0.631) | -1.128 (0.228) |
| Asian | -0.566 (0.051) | -0.108 (0.874) | -0.552 (0.395) | -1.418 (0.445) |
| Hispanic/Latine | 0.019 (0.949) | -0.395 (0.558) | -0.471 (0.496) | -3.850 (0.175) |
| MDD | 0.205 (0.401) | -0.666 (0.139) | **-1.131 (0.022)** | **-3.101 (0.029)** |
| GAD | -0.124 (0.574) | 0.753 (0.155) | 0.622 (0.202) | 1.897 (0.263) |
| Out-degree | **-0.189 (0.011)** | 0.230 (0.195) | 0.032 (0.876) | 0.497 (0.382) |
| In-degree | 0.093 (0.058) | 0.141 (0.305) | 0.064 (0.633) | -1.129 (0.113) |
| **Perceived Friend Use** | **0.386 (0.000)** | -0.121 (0.541) | 0.025 (0.887) | 0.836 (0.236) |
| **Network Exposure Users** | **1.327 (0.034)** | **-3.870 (0.024)** | **-3.049 (0.016)** | -1.578 (0.640) |
| Network Exposure Dis-adopters | 1.107 (0.254) | 0.903 (0.486) | -0.772 (0.494) | -4.188 (0.511) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 5.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.089 (0.634) | 0.607 (0.115) | **0.890 (0.017)** | 0.313 (0.698) |
| Female | 0.295 (0.104) | -0.256 (0.496) | -0.003 (0.995) | 1.113 (0.180) |
| Sexual Minority | **0.374 (0.030)** | -0.332 (0.382) | -0.063 (0.863) | 0.183 (0.779) |
| Parent Ed. | -0.044 (0.471) | 0.009 (0.950) | -0.074 (0.650) | -0.498 (0.089) |
| Asian | **-0.483 (0.014)** | -0.125 (0.783) | 0.040 (0.923) | -1.036 (0.194) |
| Hispanic/Latine | 0.058 (0.769) | -0.210 (0.657) | -0.391 (0.327) | -1.406 (0.085) |
| MDD | 0.163 (0.345) | -0.336 (0.323) | **-0.842 (0.006)** | **-1.407 (0.034)** |
| GAD | -0.145 (0.348) | 0.311 (0.364) | 0.095 (0.762) | -0.020 (0.976) |
| Out-degree | -0.083 (0.100) | 0.075 (0.573) | -0.127 (0.348) | -0.067 (0.785) |
| In-degree | **0.092 (0.010)** | 0.125 (0.153) | 0.149 (0.063) | 0.055 (0.743) |
| **Perceived Friend Use** | **0.386 (0.000)** | **-0.323 (0.017)** | **-0.319 (0.003)** | -0.321 (0.203) |
| **Network Exposure Users** | **1.674 (0.000)** | **-2.318 (0.006)** | **-1.506 (0.027)** | 0.390 (0.784) |
| Network Exposure Dis-adopters | 1.070 (0.160) | -1.514 (0.304) | -0.558 (0.496) | -1.284 (0.660) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 5.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.156 (0.372) | 0.444 (0.191) | **0.804 (0.017)** | 0.483 (0.479) |
| Female | 0.259 (0.102) | -0.509 (0.129) | -0.285 (0.396) | 0.919 (0.211) |
| Sexual Minority | **0.326 (0.037)** | -0.284 (0.380) | 0.139 (0.661) | 0.847 (0.117) |
| Parent Ed. | -0.048 (0.393) | 0.018 (0.879) | 0.024 (0.858) | -0.180 (0.420) |
| Asian | **-0.490 (0.007)** | 0.071 (0.855) | 0.113 (0.764) | -0.887 (0.187) |
| Hispanic/Latine | 0.114 (0.520) | -0.144 (0.703) | -0.127 (0.712) | -0.812 (0.193) |
| MDD | 0.118 (0.457) | -0.310 (0.323) | **-0.685 (0.017)** | -0.930 (0.082) |
| GAD | -0.114 (0.418) | 0.202 (0.495) | 0.106 (0.712) | 0.310 (0.561) |
| Out-degree | -0.060 (0.191) | 0.098 (0.393) | -0.031 (0.787) | -0.001 (0.994) |
| In-degree | **0.083 (0.010)** | 0.076 (0.308) | 0.116 (0.086) | 0.102 (0.445) |
| **Perceived Friend Use** | **0.407 (0.000)** | **-0.351 (0.001)** | **-0.338 (0.000)** | -0.280 (0.150) |
| **Network Exposure Users** | **1.684 (0.000)** | -1.344 (0.059) | -1.025 (0.088) | 0.139 (0.906) |
| Network Exposure Dis-adopters | 0.657 (0.368) | -0.813 (0.480) | -0.137 (0.863) | -0.842 (0.703) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 5.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.138 (0.389) | 0.333 (0.271) | **0.616 (0.030)** | 0.479 (0.357) |
| Female | **0.356 (0.017)** | -0.592 (0.060) | -0.365 (0.248) | 0.747 (0.221) |
| Sexual Minority | **0.363 (0.013)** | -0.175 (0.541) | 0.102 (0.709) | 0.498 (0.261) |
| Parent Ed. | -0.070 (0.181) | 0.003 (0.983) | -0.008 (0.946) | -0.149 (0.413) |
| Asian | **-0.404 (0.017)** | 0.148 (0.686) | 0.114 (0.740) | -0.883 (0.135) |
| Hispanic/Latine | 0.138 (0.407) | -0.111 (0.742) | -0.089 (0.772) | -0.619 (0.223) |
| MDD | 0.125 (0.385) | -0.202 (0.477) | **-0.630 (0.016)** | **-0.935 (0.047)** |
| GAD | -0.163 (0.214) | 0.161 (0.541) | 0.167 (0.512) | 0.325 (0.470) |
| Out-degree | -0.056 (0.198) | 0.084 (0.427) | 0.029 (0.773) | 0.048 (0.763) |
| In-degree | **0.076 (0.011)** | 0.061 (0.370) | 0.075 (0.212) | 0.052 (0.648) |
| **Perceived Friend Use** | **0.396 (0.000)** | **-0.305 (0.001)** | **-0.312 (0.000)** | -0.245 (0.105) |
| **Network Exposure Users** | **1.727 (0.000)** | -0.840 (0.186) | -0.381 (0.495) | 0.733 (0.375) |
| Network Exposure Dis-adopters | **1.121 (0.050)** | -0.325 (0.746) | 0.079 (0.910) | -1.931 (0.377) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 6. Alternative E_D = E^max − E_current

Replaces "peer share who flipped 1→0 between w-2 and w-1" with $E_D = \max_{s \le w-1} E_{\text{users},i,s} - E_{\text{users},i,w-1}$ (cumulative peak minus current).

## 6.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 0.487 (0.067) | -0.974 (0.069) | -0.975 (0.087) | -0.719 (0.714) |
| Sexual Minority | 0.420 (0.095) | 0.072 (0.904) | 0.618 (0.253) | 3.786 (0.063) |
| Parent Ed. | -0.041 (0.626) | 0.199 (0.307) | 0.133 (0.550) | -1.043 (0.253) |
| Asian | -0.557 (0.057) | -0.060 (0.931) | -0.613 (0.325) | -1.634 (0.396) |
| Hispanic/Latine | 0.027 (0.927) | -0.290 (0.678) | -0.450 (0.523) | -3.317 (0.233) |
| MDD | 0.212 (0.387) | -0.688 (0.128) | **-1.171 (0.014)** | **-3.861 (0.041)** |
| GAD | -0.126 (0.573) | 0.789 (0.144) | 0.650 (0.190) | 2.557 (0.198) |
| Out-degree | **-0.186 (0.012)** | 0.228 (0.197) | 0.068 (0.748) | 0.455 (0.442) |
| In-degree | **0.096 (0.049)** | 0.143 (0.295) | 0.050 (0.712) | -1.249 (0.069) |
| **Perceived Friend Use** | **0.383 (0.000)** | -0.122 (0.547) | 0.021 (0.906) | 0.828 (0.242) |
| **Network Exposure Users** | **1.381 (0.028)** | **-3.650 (0.030)** | **-3.360 (0.008)** | -2.986 (0.436) |
| $E_D$ alt | 0.507 (0.488) | -0.097 (0.948) | -1.546 (0.401) | -6.338 (0.373) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 83 | 91 | 83 |
| N Events | 89 | 52 | 70 | 7 |

## 6.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.077 (0.685) | 0.583 (0.147) | **0.819 (0.033)** | 0.207 (0.800) |
| Female | 0.296 (0.105) | -0.187 (0.621) | 0.074 (0.846) | 1.212 (0.144) |
| Sexual Minority | **0.366 (0.033)** | -0.397 (0.282) | -0.086 (0.813) | 0.235 (0.721) |
| Parent Ed. | -0.047 (0.450) | 0.018 (0.896) | -0.055 (0.739) | -0.453 (0.123) |
| Asian | **-0.469 (0.019)** | -0.173 (0.704) | -0.028 (0.945) | -1.189 (0.144) |
| Hispanic/Latine | 0.070 (0.723) | -0.259 (0.579) | -0.400 (0.321) | -1.460 (0.077) |
| MDD | 0.165 (0.341) | -0.339 (0.313) | **-0.877 (0.005)** | **-1.478 (0.028)** |
| GAD | -0.145 (0.348) | 0.307 (0.366) | 0.124 (0.690) | 0.035 (0.957) |
| Out-degree | -0.082 (0.103) | 0.076 (0.569) | -0.121 (0.364) | -0.081 (0.735) |
| In-degree | **0.094 (0.008)** | 0.116 (0.191) | 0.149 (0.063) | 0.040 (0.810) |
| **Perceived Friend Use** | **0.383 (0.000)** | **-0.308 (0.021)** | **-0.293 (0.007)** | -0.272 (0.284) |
| **Network Exposure Users** | **1.722 (0.000)** | **-2.527 (0.004)** | **-1.765 (0.011)** | -0.127 (0.933) |
| $E_D$ alt | 0.593 (0.251) | -0.738 (0.434) | -1.073 (0.182) | -3.955 (0.252) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

## 6.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.138 (0.435) | 0.391 (0.269) | **0.731 (0.033)** | 0.378 (0.586) |
| Female | 0.254 (0.111) | -0.433 (0.196) | -0.237 (0.485) | 0.983 (0.178) |
| Sexual Minority | **0.323 (0.039)** | -0.313 (0.327) | 0.119 (0.703) | 0.861 (0.110) |
| Parent Ed. | -0.050 (0.382) | 0.028 (0.809) | 0.034 (0.800) | -0.190 (0.397) |
| Asian | **-0.461 (0.013)** | 0.013 (0.974) | 0.035 (0.927) | -1.019 (0.139) |
| Hispanic/Latine | 0.133 (0.460) | -0.156 (0.680) | -0.149 (0.669) | -0.878 (0.165) |
| MDD | 0.122 (0.440) | -0.332 (0.288) | **-0.705 (0.014)** | -0.979 (0.067) |
| GAD | -0.117 (0.407) | 0.218 (0.459) | 0.123 (0.664) | 0.364 (0.496) |
| Out-degree | -0.058 (0.206) | 0.097 (0.399) | -0.035 (0.759) | -0.005 (0.979) |
| In-degree | **0.083 (0.010)** | 0.076 (0.311) | 0.117 (0.082) | 0.108 (0.415) |
| **Perceived Friend Use** | **0.404 (0.000)** | **-0.328 (0.002)** | **-0.316 (0.001)** | -0.230 (0.250) |
| **Network Exposure Users** | **1.744 (0.000)** | **-1.625 (0.034)** | **-1.299 (0.043)** | -0.289 (0.819) |
| $E_D$ alt | 0.598 (0.191) | -0.980 (0.264) | -0.931 (0.195) | -2.088 (0.339) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 206 | 233 | 206 |
| N Events | 232 | 108 | 159 | 21 |

## 6.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.122 (0.450) | 0.270 (0.383) | 0.543 (0.057) | 0.489 (0.349) |
| Female | **0.356 (0.018)** | -0.512 (0.105) | -0.302 (0.345) | 0.788 (0.194) |
| Sexual Minority | **0.362 (0.013)** | -0.181 (0.522) | 0.090 (0.737) | 0.493 (0.265) |
| Parent Ed. | -0.074 (0.162) | 0.013 (0.914) | 0.002 (0.985) | -0.164 (0.370) |
| Asian | **-0.379 (0.030)** | 0.089 (0.811) | 0.031 (0.930) | -0.932 (0.120) |
| Hispanic/Latine | 0.156 (0.357) | -0.090 (0.792) | -0.112 (0.717) | -0.665 (0.191) |
| MDD | 0.124 (0.390) | -0.228 (0.423) | **-0.646 (0.013)** | **-0.938 (0.046)** |
| GAD | -0.164 (0.209) | 0.179 (0.498) | 0.177 (0.480) | 0.341 (0.449) |
| Out-degree | -0.055 (0.208) | 0.084 (0.422) | 0.019 (0.850) | 0.036 (0.817) |
| In-degree | **0.076 (0.010)** | 0.063 (0.360) | 0.077 (0.201) | 0.053 (0.638) |
| **Perceived Friend Use** | **0.396 (0.000)** | **-0.280 (0.003)** | **-0.287 (0.001)** | -0.238 (0.121) |
| **Network Exposure Users** | **1.784 (0.000)** | -1.151 (0.094) | -0.683 (0.251) | 0.574 (0.514) |
| $E_D$ alt | 0.705 (0.097) | -1.328 (0.112) | -1.135 (0.090) | -0.985 (0.554) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

---

# 7. Model C window sensitivity

Three columns per Q: $C$ at $W=1$ (immediate return), $W \le 2$ (within 2 next observed waves), $W \le 3$.

## 7.1 Q = 8

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — |
| Female | -0.909 (0.624) | 0.124 (0.918) | 0.124 (0.918) |
| Sexual Minority | **3.333 (0.042)** | **2.522 (0.037)** | **2.522 (0.037)** |
| Parent Ed. | -1.128 (0.228) | -0.041 (0.926) | -0.041 (0.926) |
| Asian | -1.418 (0.445) | -0.973 (0.439) | -0.973 (0.439) |
| Hispanic/Latine | -3.850 (0.175) | 0.239 (0.852) | 0.239 (0.852) |
| MDD | **-3.101 (0.029)** | -0.987 (0.212) | -0.987 (0.212) |
| GAD | 1.897 (0.263) | -0.043 (0.966) | -0.043 (0.966) |
| Out-degree | 0.497 (0.382) | -0.069 (0.831) | -0.069 (0.831) |
| In-degree | -1.129 (0.113) | -0.319 (0.288) | -0.319 (0.288) |
| Perceived Friend Use | 0.836 (0.236) | -0.119 (0.775) | -0.119 (0.775) |
| Network Exposure Users | -1.578 (0.640) | -1.218 (0.604) | -1.218 (0.604) |
| Network Exposure Dis-adopters | -4.188 (0.511) | -0.222 (0.923) | -0.222 (0.923) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 83 | 83 | 83 |
| N Events | 7 | 11 | 11 |

## 7.2 Q = 7

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.313 (0.698) | 0.966 (0.861) | 1.581 (0.834) |
| Female | 1.113 (0.180) | 1.026 (0.828) | 0.846 (0.901) |
| Sexual Minority | 0.183 (0.779) | 1.509 (0.658) | 0.858 (0.869) |
| Parent Ed. | -0.498 (0.089) | -1.073 (0.526) | -0.826 (0.745) |
| Asian | -1.036 (0.194) | -0.928 (0.866) | -2.168 (0.770) |
| Hispanic/Latine | -1.406 (0.085) | -1.258 (0.816) | -3.301 (0.671) |
| MDD | **-1.407 (0.034)** | -2.721 (0.454) | -1.942 (0.711) |
| GAD | -0.020 (0.976) | -0.393 (0.908) | -1.725 (0.737) |
| Out-degree | -0.067 (0.785) | -0.518 (0.636) | -0.796 (0.607) |
| In-degree | 0.055 (0.743) | 0.217 (0.838) | 0.275 (0.849) |
| Perceived Friend Use | -0.321 (0.203) | -0.241 (0.818) | -0.535 (0.728) |
| Network Exposure Users | 0.390 (0.784) | -0.466 (0.957) | 1.026 (0.924) |
| Network Exposure Dis-adopters | -1.284 (0.660) | -0.162 (0.991) | 1.679 (0.933) |
| Rho (ICC) | 0.000 | 0.953 | 0.975 |
| N Students | 161 | 161 | 161 |
| N Events | 15 | 20 | 21 |

## 7.3 Q = 6

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.483 (0.479) | 0.931 (0.123) | 0.950 (0.111) |
| Female | 0.919 (0.211) | 0.411 (0.504) | 0.500 (0.412) |
| Sexual Minority | 0.847 (0.117) | **1.009 (0.046)** | 0.964 (0.051) |
| Parent Ed. | -0.180 (0.420) | -0.174 (0.399) | -0.100 (0.609) |
| Asian | -0.887 (0.187) | -1.172 (0.073) | -0.842 (0.174) |
| Hispanic/Latine | -0.812 (0.193) | -0.590 (0.289) | -0.601 (0.279) |
| MDD | -0.930 (0.082) | -0.557 (0.237) | -0.661 (0.160) |
| GAD | 0.310 (0.561) | -0.122 (0.802) | -0.122 (0.801) |
| Out-degree | -0.001 (0.994) | -0.048 (0.777) | -0.056 (0.739) |
| In-degree | 0.102 (0.445) | 0.134 (0.270) | 0.111 (0.349) |
| Perceived Friend Use | -0.280 (0.150) | -0.201 (0.235) | -0.163 (0.317) |
| Network Exposure Users | 0.139 (0.906) | -0.412 (0.708) | 0.080 (0.938) |
| Network Exposure Dis-adopters | -0.842 (0.703) | 0.711 (0.607) | 0.741 (0.595) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 206 | 206 | 206 |
| N Events | 21 | 26 | 27 |

## 7.4 Q = 5

| Variable | C, W=1 | C, W ≤ 2 | C, W ≤ 3 |
|:---|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.479 (0.357) | 0.696 (0.146) | 0.691 (0.148) |
| Female | 0.747 (0.221) | 0.381 (0.481) | 0.425 (0.429) |
| Sexual Minority | 0.498 (0.261) | 0.487 (0.241) | 0.475 (0.247) |
| Parent Ed. | -0.149 (0.413) | -0.169 (0.316) | -0.116 (0.473) |
| Asian | -0.883 (0.135) | -1.100 (0.055) | -0.827 (0.132) |
| Hispanic/Latine | -0.619 (0.223) | -0.531 (0.251) | -0.525 (0.256) |
| MDD | **-0.935 (0.047)** | -0.594 (0.156) | -0.674 (0.107) |
| GAD | 0.325 (0.470) | 0.118 (0.775) | 0.123 (0.766) |
| Out-degree | 0.048 (0.763) | 0.075 (0.606) | 0.072 (0.613) |
| In-degree | 0.052 (0.648) | 0.028 (0.789) | 0.014 (0.892) |
| Perceived Friend Use | -0.245 (0.105) | -0.201 (0.144) | -0.172 (0.202) |
| Network Exposure Users | 0.733 (0.375) | 0.372 (0.638) | 0.677 (0.380) |
| Network Exposure Dis-adopters | -1.931 (0.377) | -0.013 (0.992) | -0.020 (0.989) |
| Rho (ICC) | 0.000 | 0.000 | 0.000 |
| N Students | 237 | 237 | 237 |
| N Events | 29 | 35 | 36 |

---

# 8. Sensitivity (a) — indeterminates counted as Stable (A)

In §5/§6/§7/§9, $1\to 0$ events with NA-only future are dropped from A (we cannot verify "no return"). §8 instead **counts them as A events** (assuming the student would not have returned). Adopters, B, and C panels are unchanged from §5; only A's panel grows.

## 8.1 Q = 8

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | — | — | — | — |
| Female | 0.482 (0.069) | -0.676 (0.201) | -1.090 (0.056) | -0.909 (0.624) |
| Sexual Minority | 0.429 (0.089) | -0.174 (0.734) | 0.640 (0.255) | **3.333 (0.042)** |
| Parent Ed. | -0.040 (0.633) | 0.151 (0.449) | 0.107 (0.631) | -1.128 (0.228) |
| Asian | -0.566 (0.051) | -0.294 (0.589) | -0.552 (0.395) | -1.418 (0.445) |
| Hispanic/Latine | 0.019 (0.949) | -0.123 (0.818) | -0.471 (0.496) | -3.850 (0.175) |
| MDD | 0.205 (0.401) | -0.515 (0.196) | **-1.131 (0.022)** | **-3.101 (0.029)** |
| GAD | -0.124 (0.574) | 0.162 (0.702) | 0.622 (0.202) | 1.897 (0.263) |
| Out-degree | **-0.189 (0.011)** | 0.162 (0.337) | 0.032 (0.876) | 0.497 (0.382) |
| In-degree | 0.093 (0.058) | 0.064 (0.597) | 0.064 (0.633) | -1.129 (0.113) |
| **Perceived Friend Use** | **0.386 (0.000)** | -0.088 (0.562) | 0.025 (0.887) | 0.836 (0.236) |
| **Network Exposure Users** | **1.327 (0.034)** | **-2.703 (0.041)** | **-3.049 (0.016)** | -1.578 (0.640) |
| Network Exposure Dis-adopters | 1.107 (0.254) | 1.089 (0.324) | -0.772 (0.494) | -4.188 (0.511) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 925 | 96 | 91 | 83 |
| N Events | 89 | 66 | 70 | 7 |

## 8.2 Q = 7

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.089 (0.634) | 0.423 (0.208) | **0.890 (0.017)** | 0.313 (0.698) |
| Female | 0.295 (0.104) | -0.081 (0.818) | -0.003 (0.995) | 1.113 (0.180) |
| Sexual Minority | **0.374 (0.030)** | -0.249 (0.465) | -0.063 (0.863) | 0.183 (0.779) |
| Parent Ed. | -0.044 (0.471) | -0.030 (0.826) | -0.074 (0.650) | -0.498 (0.089) |
| Asian | **-0.483 (0.014)** | 0.125 (0.738) | 0.040 (0.923) | -1.036 (0.194) |
| Hispanic/Latine | 0.058 (0.769) | -0.053 (0.889) | -0.391 (0.327) | -1.406 (0.085) |
| MDD | 0.163 (0.345) | -0.391 (0.205) | **-0.842 (0.006)** | **-1.407 (0.034)** |
| GAD | -0.145 (0.348) | -0.001 (0.996) | 0.095 (0.762) | -0.020 (0.976) |
| Out-degree | -0.083 (0.100) | -0.004 (0.974) | -0.127 (0.348) | -0.067 (0.785) |
| In-degree | **0.092 (0.010)** | 0.107 (0.150) | 0.149 (0.063) | 0.055 (0.743) |
| **Perceived Friend Use** | **0.386 (0.000)** | **-0.311 (0.003)** | **-0.319 (0.003)** | -0.321 (0.203) |
| **Network Exposure Users** | **1.674 (0.000)** | **-1.396 (0.034)** | **-1.506 (0.027)** | 0.390 (0.784) |
| Network Exposure Dis-adopters | 1.070 (0.160) | -0.063 (0.936) | -0.558 (0.496) | -1.284 (0.660) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 191 | 182 | 161 |
| N Events | 193 | 122 | 129 | 15 |

## 8.3 Q = 6

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.156 (0.372) | 0.374 (0.213) | **0.804 (0.017)** | 0.483 (0.479) |
| Female | 0.259 (0.102) | -0.199 (0.521) | -0.285 (0.396) | 0.919 (0.211) |
| Sexual Minority | **0.326 (0.037)** | -0.271 (0.354) | 0.139 (0.661) | 0.847 (0.117) |
| Parent Ed. | -0.048 (0.393) | 0.027 (0.816) | 0.024 (0.858) | -0.180 (0.420) |
| Asian | **-0.490 (0.007)** | 0.163 (0.628) | 0.113 (0.764) | -0.887 (0.187) |
| Hispanic/Latine | 0.114 (0.520) | -0.030 (0.924) | -0.127 (0.712) | -0.812 (0.193) |
| MDD | 0.118 (0.457) | -0.401 (0.160) | **-0.685 (0.017)** | -0.930 (0.082) |
| GAD | -0.114 (0.418) | -0.017 (0.950) | 0.106 (0.712) | 0.310 (0.561) |
| Out-degree | -0.060 (0.191) | 0.008 (0.935) | -0.031 (0.787) | -0.001 (0.994) |
| In-degree | **0.083 (0.010)** | 0.096 (0.135) | 0.116 (0.086) | 0.102 (0.445) |
| **Perceived Friend Use** | **0.407 (0.000)** | **-0.321 (0.000)** | **-0.338 (0.000)** | -0.280 (0.150) |
| **Network Exposure Users** | **1.684 (0.000)** | -0.965 (0.100) | -1.025 (0.088) | 0.139 (0.906) |
| Network Exposure Dis-adopters | 0.657 (0.368) | 0.287 (0.687) | -0.137 (0.863) | -0.842 (0.703) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,077 | 245 | 233 | 206 |
| N Events | 232 | 150 | 159 | 21 |

## 8.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.138 (0.389) | 0.279 (0.288) | **0.616 (0.030)** | 0.479 (0.357) |
| Female | **0.356 (0.017)** | -0.281 (0.335) | -0.365 (0.248) | 0.747 (0.221) |
| Sexual Minority | **0.363 (0.013)** | -0.177 (0.492) | 0.102 (0.709) | 0.498 (0.261) |
| Parent Ed. | -0.070 (0.181) | 0.014 (0.903) | -0.008 (0.946) | -0.149 (0.413) |
| Asian | **-0.404 (0.017)** | 0.157 (0.614) | 0.114 (0.740) | -0.883 (0.135) |
| Hispanic/Latine | 0.138 (0.407) | -0.027 (0.926) | -0.089 (0.772) | -0.619 (0.223) |
| MDD | 0.125 (0.385) | -0.331 (0.202) | **-0.630 (0.016)** | **-0.935 (0.047)** |
| GAD | -0.163 (0.214) | -0.005 (0.982) | 0.167 (0.512) | 0.325 (0.470) |
| Out-degree | -0.056 (0.198) | 0.017 (0.859) | 0.029 (0.773) | 0.048 (0.763) |
| In-degree | **0.076 (0.011)** | 0.092 (0.125) | 0.075 (0.212) | 0.052 (0.648) |
| **Perceived Friend Use** | **0.396 (0.000)** | **-0.279 (0.000)** | **-0.312 (0.000)** | -0.245 (0.105) |
| **Network Exposure Users** | **1.727 (0.000)** | -0.674 (0.217) | -0.381 (0.495) | 0.733 (0.375) |
| Network Exposure Dis-adopters | **1.121 (0.050)** | 0.508 (0.408) | 0.079 (0.910) | -1.931 (0.377) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 2,404 | 283 | 271 | 237 |
| N Events | 267 | 169 | 185 | 29 |

---

# 9. Sensitivity (b) — observed-wave jumps

§9 walks through observed waves regardless of calendar gaps (instead of consecutive-calendar pairs). Under W1-W10 the panel has fewer NA gaps within consecutive observations than under W1-W8, so §9 results are **near-identical to §5**. We reproduce §9.4 (Q=5) here as the reference; §9.1–§9.3 are visually indistinguishable from §5.1–§5.3 and are saved at `outputs/tables/v4b_table_9_Q{8,7,6}.csv` for audit.

## 9.4 Q = 5

| Variable | Adopters | A | B | C |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | -0.138 (0.389) | 0.333 (0.271) | **0.616 (0.030)** | 0.479 (0.357) |
| Female | **0.356 (0.017)** | -0.592 (0.060) | -0.365 (0.248) | 0.747 (0.221) |
| Sexual Minority | **0.363 (0.013)** | -0.175 (0.541) | 0.102 (0.709) | 0.498 (0.261) |
| Asian | **-0.404 (0.017)** | 0.148 (0.686) | 0.114 (0.740) | -0.883 (0.135) |
| MDD | 0.125 (0.385) | -0.202 (0.477) | **-0.630 (0.016)** | **-0.935 (0.047)** |
| In-degree | **0.076 (0.011)** | 0.061 (0.370) | 0.075 (0.212) | 0.052 (0.648) |
| **Perceived Friend Use** | **0.396 (0.000)** | **-0.305 (0.001)** | **-0.312 (0.000)** | -0.245 (0.105) |
| **Network Exposure Users** | **1.727 (0.000)** | -0.840 (0.186) | -0.381 (0.495) | 0.733 (0.375) |
| Network Exposure Dis-adopters | **1.121 (0.050)** | -0.325 (0.746) | 0.079 (0.910) | -1.931 (0.377) |
| N Students | 2,404 | 237 | 271 | 237 |
| N Events | 267 | 124 | 185 | 29 |

\normalsize

---

# 10. Discussion

**Headline findings — robust across Q in §5/§6/§8** (the families with full 4-outcome tables):

1. **Perceived Friend Use** is the cleanest two-sided lever — positive on adoption ($\beta \approx 0.39$, $p < 0.001$ at every Q ≥ 5) and negative on every flavour of disadoption (A in $Q \in \{5,6,7\}$, B in all $Q \le 7$). The pattern survives in §6 (alt $E_D$) and §8 (a). Effect sizes are comparable across families.
2. **Network Exposure (Users)** mirrors Perceived Friend Use at the network-aggregate level: positive on adoption ($\beta \approx 1.3$–$1.8$, $p < 0.001$) and negative on B (and on A at $Q=7$). The signal is stronger and more consistent at $Q=7$ than at $Q=5$.
3. **MDD** predicts non-cessation among ever-users: B ($p \le 0.022$ at $Q \in \{5,6,7,8\}$ in §5/§6/§8) and C ($p \le 0.047$ at $Q \in \{5,7,8\}$). Higher depressive symptoms → less likely to attempt or succeed in cessation.
4. **Sexual Minority** raises adoption at $Q \le 7$ ($\beta \approx 0.32$–$0.43$).
5. **Asian** lowers adoption consistently ($\beta \approx -0.40$ to $-0.57$ at $Q \le 7$).
6. **Cohort 2025** shows higher experimental disadoption (B) at $Q \in \{5, 6, 7\}$.

**§7 Window sensitivity** — the cyclic-disadoption signal is dominated by the small sample at every Q. Sexual Minority becomes significant in $Q=8$ at $W=1$ (and $W \le 2$), which is the only stable cross-window finding for C. Under $W \le 2$ and $W \le 3$ the additional events are mostly equivalent (most cycles return at $w$ or $w+1$, not later).

**§9 vs §5** — the v4b panel over W1-W10 has fewer NA gaps within consecutive observations than v4 (W1-W8 only), so observed-wave jumps and consecutive-calendar pairs produce nearly identical event sets. This is a useful check: the §5 conclusions are not sensitive to the lag definition under the new data.

**§8 vs §5** — counting indeterminates as A increases the A event count (≈ +25–40% per Q) but the **A column results are qualitatively unchanged**: the same predictors (Perceived Friend Use, Network Exposure Users) come up significant. This argues that the v4b main results are not driven by the indeterminate decision.

# 11. Limitations and deferred items

- **ESE composites** (`Pos_no9_Mean`, `Neg_no510_Mean`) excluded from main regressions — only ~40% of user-waves carry valid ESE. Future iteration: ever-users-only sub-analysis with ESE.
- **C samples remain small**: 7–29 events per Q. The GLMER often hits a singular fit ($\rho \to 0$); coefficients should be read with caution.
- **Schoolid_transfer** for the ~50 students who switched schools across waves not yet integrated.
- The W9-W10 file's `dem_high_par_edu_new` (1–9 scale) is harmonised to the W1-W6 1–7 scale via the same mapping used for W7-W8 (`5,6 → 4`, `7 → 5`, `8 → 6`, `9 → 7`).
- v4 results (W1-W8 panel) archived at `reports/disadoption-study-4.{pdf,md}`.

# Annex — Pipeline

`R/00-config.R`, then `R/01b-edges-rebuild.R` (regenerate edges into `data/advance/Cleaned-Data-042326/`), then `R/01-advance-panel.R` (read W1-W10), `R/02-event-builder.R` (5 modes × 4 Q), `R/03-network-features.R` (degree, exposures, $E_D$ variants), `R/04-regressions.R` (5 families × 4 Q = 20 CSVs).
