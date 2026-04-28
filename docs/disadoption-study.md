---
title: "Disadoption Study v3"
subtitle: "Peer effects on adoption and disadoption: ADVANCE e-cig vs KFP Pill+Condom (community terminology, V per-10pp, Valente strict replication)"
author: "A. Olivera"
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
  - \usepackage{colortbl}
  - \usepackage[table]{xcolor}
---

# 0. What changed since v2

v2 corrected the v1 episode-vs-calendar bug in KFP and froze the methodological framework. v3 keeps that framework intact and makes the following five additive changes (all numerical results from v2 are preserved):

1. **Terminology**: "cluster" → "community" throughout. $V_{v,t}$ is now "community saturation" and $\gamma_v$ is the "community FE". In the R code, the model factor `village_fe` is renamed to `community_fe`. The `sandwich::vcovCL` call (cluster-robust SE) keeps its API name because it is a standard function signature.
2. **§1.3 (new): grade-within-cohort prevalence (ADVANCE)** — a descriptive table showing the rise-and-fall pattern of e-cig past-6-month prevalence within each cohort. The table is descriptive only; the regression battery already absorbs this variation through wave + school fixed effects.
3. **OR per 10pp V annotations** — every reported $V$ coefficient now also shows $\mathrm{OR}_{\Delta V = 0.10} = \exp(\beta_V \cdot 0.10) = \mathrm{OR}^{0.1}$. The raw OR (per unit $V$) is misleading because $V$ never spans the full $0$–$1$ range; the per-10pp summary makes effect sizes interpretable.
4. **Valente strict replication (new §3.3)** — a strict reproduction of Valente (2010) Table 10-2 KFP column on the 1,047-woman / 10-period panel, with NO additional community / period fixed effects. Predictors: `t` (continuous), $A^{\mathrm{cum}}_{v,t-1}$, $n^{\mathrm{sent}}_i$, $n^{\mathrm{recv}}_i$, $E^{\mathrm{coh}}_{i,t-1}$, $E^{\mathrm{se}}_{i,t-1}$, $\mathrm{children}_i$, $\mathrm{media}_i$. The media index is the **mean of `media6..media14`** (frequency-scale, 0–4) per Valente's book, not `media1..media5` (which are binary ownership flags). With this corrected media coding and strict event-history accounting (never-adopters never contribute an event), the strict model yields **n = 7,103 person-periods, 673 events** — exactly matching the figure reported in Valente Table 10-2. The FE-controlled spec from v2 (§3.2/§3.3 main batteries) remains the main analysis.
5. **TOA match sanity-check (Annex B)** — the 74.3% match between the reconstructed modern-TOA and `kfamily$toa` is an **adopter-only** metric (numerator: 500/673 adopters with `kfamily$toa <= 10`). v3 adds an **overall** match metric that imputes T = 11 (= "never adopted in panel") for women whose reconstruction shows no modern adoption, then compares across all 1,047 women: **874/1047 (83.5%)**. Of these, 374 are trivial matches (both sides = 11). Reporting both numbers distinguishes "match among adopters" (the strict reconstruction test) from "match overall" (which includes the trivial cases).

The v2 file is archived at `reports/disadoption-study-2.{pdf,md}`. v1 is archived at `reports/disadoption-study-1.pdf`.

---

# 1. Datasets

## 1.1 ADVANCE — e-cig in California high-schoolers

USC ADVANCE longitudinal study. Class of 2024 + partial class of 2025 from 11 public high schools in Southern California. I use HS waves W1–W8 (Fall 2020 — Spring 2024). Outcome: `past_6mo_use_3` (any e-cigarette / vaping nicotine in last 6 months).

**Schools × waves enrollment** (cohort × wave matrix):

| Cohort | W1 | W2 | W3 | W4 | W5 | W6 | W7 | W8 |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Schools 101–105 | ● | ● | ● | ● | ● | ● | ● | ● |
| Schools 106–114 |  | ● | ● | ● | ● | ● | ● | ● |
| Second cohort (201, 212–214) |  |  | ● | ● | ● | ● | ● | ● |

Conteos exactos por school × wave en Annex F.

**E-cig prevalence by wave**: 2.2% → 3.0% → 5.4% → 7.5% → 8.4% → **10.1% (W6)** → 8.0% → 6.8%. Rises and falls — gives statistical power on disadoption.

**Network**: friendship nominations (up to 7), median out-degree 2-3.

**Panel**: 24,089 person-wave rows. Adoption events: 654. Stable disadoption events: 506.

## 1.2 KFP — Pill+Condom in Korean Family Planning villages

`netdiffuseR::kfamily`. 1,047 women, 25 villages, 10 calendar periods (1964–1973). For Disadoption-Study, behaviour of interest is **Pill or Condom** (PC), the user-discretion methods.

**Method classification**:

- **PC**: Oral Pill (5), Condom (4)
- **modern_nonPC**: Loop (3), Vasectomy (6), TL (15), Injection (18)
- **trad**: Rhythm (14), Withdrawal (16), Pessary (17), Jelly (19), Foam (20)
- **noFP**: Pregnant (1), NormalB (2), Menopause (7), Want more (8), No more (9), Infertile (10), Stillbirth (11), Newlywed (12), Abortion (13), Other (21)

**Panel construction (corrected)**: each woman has a list of FP episodes from `fpt`/`byrt` (up to 12) plus a `cfp`/`cbyr` survey-time anchor. Episodes are sorted by start year. State at each calendar year $t \in \{1964, \ldots, 1973\}$ is the **active episode** at year $t$ — the most recently started episode whose start year $\le t$. Within ties (same year), FP-active class wins over noFP, and `cfp` anchor wins over `fpt` episodes.

**Two panel variants** are constructed:

- **Canonical** = `fpt + cfp/cbyr` episodes. The default for all reported results below.
- **fpt-only** = `fpt`/`byrt` episodes alone, no `cfp` anchor. Reported as a "less informed" comparison.

**PC prevalence by year (canonical panel)**: 1.5% → 2.6% → 4.5% → 4.9% → 7.2% → 10.2% → 12.3% → 12.4% → 15.0% → 15.4%. Rising trajectory throughout.

**Panel summary** (canonical):

- Ever on PC: 343 women (vs 292 in fpt-only).
- Stay-in-PC observations: 414. Substitution to modern_nonPC (right-censored): 30. Disadoption to trad: 12. Disadoption to noFP: 195. **Raw 1→0 disadoption events: 207**.

**Network**: FP-discussion ties (`net11`–`net15`, up to 5 per woman, static). Mean out-degree 2.83.

## 1.3 ADVANCE — e-cig prevalence by grade-within-cohort (new in v3)

Each ADVANCE wave is a fall or spring semester; combining each pair of waves for each cohort recovers a "grade level" view. The Class of 2024 enters W1 in 9th grade; the Class of 2025 enters W3 in 9th grade.

**Per-wave prevalence within grade-within-cohort**:

| Cohort | Grade | Wave | E-cig prevalence | n person-waves |
|:---|:---:|:---:|:---:|:---:|
| Class of 2024 | 9th  | W1 | 2.2%  |  851 |
| Class of 2024 | 9th  | W2 | 3.0%  | 2235 |
| Class of 2024 | 10th | W3 | 6.4%  | 2593 |
| Class of 2024 | 10th | W4 | 8.3%  | 2657 |
| Class of 2024 | 11th | W5 | 9.1%  | 2572 |
| Class of 2024 | 11th | W6 | 10.9% | 2409 |
| Class of 2024 | 12th | W7 | 8.3%  | 2234 |
| Class of 2024 | 12th | W8 | 7.6%  | 2047 |
| Class of 2025 | 9th  | W3 | 3.2%  | 1166 |
| Class of 2025 | 9th  | W4 | 5.6%  | 1160 |
| Class of 2025 | 10th | W5 | 6.8%  | 1128 |
| Class of 2025 | 10th | W6 | 8.4%  | 1075 |
| Class of 2025 | 11th | W7 | 7.4%  | 1009 |
| Class of 2025 | 11th | W8 | 5.0%  |  894 |

**Collapsed by cohort × grade (weighted average over the two waves)**:

| Cohort | 9th | 10th | 11th | 12th |
|:---|:---:|:---:|:---:|:---:|
| Class of 2024 | 2.8% | 7.3% | **9.9%** | 8.0% |
| Class of 2025 | 4.4% | 7.6% | 6.3%  | n/a  |

**Read.** Within each cohort, e-cig past-6mo prevalence rises from 9th grade through 11th grade and then falls in 12th (Class of 2024 reaches its peak in 11th grade at 9.9%). Class of 2025 shows the same rise-and-fall shape one cohort later, with its currently-observed peak at 7.6% in 10th grade and a clear drop in 11th. This descriptive shape is consistent with adolescent peak vaping in the upper-middle high-school years.

**Caveat.** The regression battery in §3–§6 already absorbs this grade-within-cohort variation through wave + school fixed effects (each school × wave cell pins down the cohort's grade), so this table is descriptive only and does not motivate any additional control.

## 1.4 Why these two pairs are comparable

| | ADVANCE | KFP |
|:---|:---|:---|
| Unit | Person × semester | Person × calendar year |
| Time points | 8 waves | 10 years |
| Community | School (15) | Village (25) |
| Tie type | Friendship | FP-discussion |
| Network | Time-varying | Static |
| Panel | Direct survey | Episode-reconstructed |
| Disadoption events | 506 | 188 (canonical) |

ADVANCE has higher density and more events. KFP is smaller but theoretically classical.

---

# 2. Notation and model framework

## 2.1 Basic objects

- $s_{iw} \in \{0, 1\}$ — state on the target behaviour at wave/year $w$.
- $A$ — adjacency matrix; $W = D^{-1} A$ is the row-normalised version.

## 2.2 Predictors (lagged one period)

- $E_{i,w} = (W \mathbf{s}_{w-1})_i$ — peer share.
- $N^c_{i,w} = (A \mathbf{s}_{w-1})_i$ — peer count.
- $\mathbb{1}[N^c_{i,w} \ge 1]$ — has-any-peer.
- $E^{\max}_{i,w} = \max_{s \le w} E_{i,s}$ — peak exposure.
- $E^{\text{Dis}}_{i,w} = E^{\max}_{i,w} - E_{i,w} \ge 0$ — gap to peak.
- $V_{v,w} = \frac{1}{|v|}\sum_{i \in v} s_{i,w-1}$ — **community saturation** (was "cluster/village saturation" in v1/v2 prose).

For KFP adoption batteries we additionally compute $E^{\text{modern}}$ (peer share on any modern method) and $V^{\text{modern}}$ (modern community saturation).

## 2.3 Option II refined for disadoption

Disadoption = transition from PC to {trad, noFP}. Substitution = transition from PC to {modern_nonPC} = right-censured (woman leaves the at-risk pool without an event). Within-PC switches (Pill ↔ Condom) keep state at 1.

For KFP, this rule produces (canonical panel): **207 raw disadoption events** and **30 substitutions censored**.

## 2.4 Three risk-set flavours for disadoption

- **Model A (stable)**: drop transient $1 \to 0 \to 1$.
- **Model B (unstable)**: first $1 \to 0$ counts; person leaves risk set.
- **Model C (recurrent)**: every $1 \to 0$ transition counts; person stays.

## 2.5 Specifications

For each battery we report:

| Spec | $x_{iw}$ |
|:---:|:---|
| F0 | $\alpha_w + \gamma_v$ (no network; period FE $\alpha_w$ + community FE $\gamma_v$) |
| A1 | $+ \beta_E E_{i,w-1}$ |
| C1 | $+ \beta_C \mathbb{1}[N^c \ge 1]$ |
| D1 | $+ \beta_N N^c_{i,w-1}$ |
| H | $+ \beta_H E^{\max}_{i,w-1}$ |
| ED | $+ \beta_D E^{\text{Dis}}_{i,w-1}$ |
| V1 | $+ \beta_V V_{v,w-1}$ |
| V2 | $+ \beta_V V + \beta_E E$ |
| AED | $+ \beta_E E + \beta_D E^{\text{Dis}}$ |
| **VAED** | $+ \beta_V V + \beta_E E + \beta_D E^{\text{Dis}}$ |

Discrete-time logistic, period FE, community FE, SE clustered by community (Liang-Zeger; the SE-clustering routine is `sandwich::vcovCL`).

For KFP, "+ cov" versions add `children + age + agemar`.

## 2.6 Reading the V coefficients (new in v3)

Every $V$ coefficient is reported in two equivalent forms:

- **OR per unit $V$** = $\exp(\beta_V)$. The standard logistic OR — but this corresponds to a $V$ change from 0 to 1 (i.e. from no-one to everyone in the community having state $= 1$), which never occurs in our data ($V$ ranges roughly 0.01–0.40 across community-periods).
- **OR per 10pp $V$** = $\exp(\beta_V \cdot 0.10) = \mathrm{OR}^{0.1}$. The change in odds for a 10-percentage-point increase in community saturation. This is on the scale of changes that actually occur period-to-period.

Example: $V_1$ in KFP PC canonical disA has raw OR = 1,915 and OR per 10pp = 2.13.

---

# 3. Adoption

## 3.1 ADVANCE e-cig adoption

Risk set: 16,605 person-waves, 654 first-adoption events.

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| F0 | — | — | — | 5388 |
| **A1** ($E$) | **4.71** | — | $< 10^{-17}$ | 3859 |
| C1 (has) | 1.97 | — | $< 10^{-13}$ | 5349 |
| D1 ($N^c$) | 1.64 | — | $< 10^{-16}$ | 5348 |
| H ($E^{\max}$) | 3.07 | — | $< 10^{-10}$ | 4401 |
| ED | 1.34 | — | 0.453 | 3901 |
| V1 ($V$) | $10^{-4}$ | **0.398** | $< 10^{-6}$ | 5378 |
| V2: V/E | $10^{-6}$ / 5.12 | **0.251** / — | both $\ll 0.001$ | 3842 |
| AED: E/ED | 5.00 / 1.82 | — | $< 10^{-18}$ / 0.089 | 3858 |
| **VAED**: V/E/ED | $10^{-7}$ / 5.45 / 1.89 | **0.200** / — / — | $< 10^{-8}$ / $< 10^{-20}$ / 0.060 | **3840** |

Strong contagion. Each spec captures it. $V$ is mechanically negative (hazard-denominator artifact: in saturated schools, the residual at-risk pool is selected toward resisters); the per-10pp reading shows the magnitude — a 10pp rise in school-level e-cig prevalence cuts the residual at-risk's odds of new adoption by roughly 60–80%. VAED gives the best AIC.

## 3.2 KFP Pill+Condom adoption

Risk set: 8,254 person-periods, 336 first-PC-adoption events.

### 3.2.1 Two exposure operationalisations

We compute exposure on PC peers ($E^{PC}$) and on any-modern peers ($E^{\text{modern}}$). They give different signals:

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| F0 | — | — | $< 10^{-27}$ | 2738 |
| A1 $E^{PC}$ | **1.96** | — | 0.006 | 2733 |
| A1 $E^{\text{modern}}$ | 1.40 | — | 0.055 | 2737 |
| C1 has^PC | 1.47 | — | 0.005 | 2732 |
| **C1 has^modern** | **1.57** | — | **0.0002** | **2725** |
| D1 Nc^PC | 1.24 | — | 0.016 | 2734 |
| D1 Nc^modern | 1.17 | — | 0.006 | 2733 |
| H ($E^{\max,PC}$) | 1.51 | — | 0.066 | 2737 |
| ED ($E^{\text{Dis},PC}$) | 0.74 | — | 0.438 | 2739 |
| V1 $V^{PC}$ | 0.13 | **0.815** | 0.115 | 2738 |
| V2: $V^{PC} / E^{PC}$ | 0.06 / 2.19 | **0.755** / — | 0.034 / 0.002 | 2731 |
| AED: $E^{PC} / E^{\text{Dis},PC}$ | 1.93 / 0.86 | — | 0.008 / 0.692 | 2735 |
| **VAED**: V/E/ED | 0.05 / 2.15 / 0.81 | **0.741** / — / — | 0.032 / 0.002 / 0.598 | 2733 |

**Read.**

1. Both peer exposure operationalisations give significant signals; $E^{PC}$ has higher OR (1.96) than $E^{\text{modern}}$ (1.40), but `has^modern` (any-modern peer) gives the cleanest AIC. The "FP-normalised network" effect (broader exposure) is at least as informative as the substance-specific peer-PC effect.
2. $V^{PC}$ negative — same hazard-denominator artifact as ADVANCE. Per 10pp, the OR is 0.74–0.82.
3. $E^{\text{Dis}}$ alone is null and doesn't add to the joint AED/VAED specs.

### 3.2.2 With covariates (children, age, agemar) and `prior_modern_nonPC`

| Spec | OR | *p* | AIC |
|:---:|:---:|:---:|:---:|
| F0 (FE + cov only) | — | $< 10^{-9}$ | 2689 |
| A1 $E^{PC}$ + cov | 1.89 | 0.012 | 2685 |
| C1 has^modern + cov | 1.46 | 0.002 | 2681 |
| **prior_modern_nonPC alone (+ cov)** | **1.50** | **0.004** | **2682** |
| A1 + prior_modern_nonPC + cov | $E^{PC}$=1.80 / prior=1.47 | 0.024 / 0.007 | 2680 |
| VAED + cov | 0.07 / 2.06 / 0.80 (V per 10pp = **0.766**) | 0.046 / 0.005 / 0.578 | 2685 |

**Read.** Covariates absorb some signal but the egonet $E^{PC}$ effect survives (OR = 1.80, $p = 0.024$ jointly with prior_modern_nonPC). `prior_modern_nonPC` is itself a strong predictor: women who have already used Loop/TL/Vasectomy/Injection are 1.5× more likely to start PC than naive women.

### 3.2.3 Subset of communities with $V^{\max}_v \ge 0.10$ (23/25 communities, n = 7,506, ev = 317)

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| A1 ($E$) | 1.92 | — | 0.009 | 2553 |
| C1 (has) | 1.50 | — | 0.004 | 2550 |
| H ($E^{\max}$) | 1.46 | — | 0.101 | 2556 |
| V1 | 0.15 | **0.827** | 0.158 | 2557 |
| V2: V/E | 0.07 / 2.13 | **0.768** / — | 0.054 / 0.003 | 2551 |

The contagion signal survives community subsetting and is essentially unchanged.

## 3.3 KFP modern6 adoption

### 3.3.1 Main analysis (with period FE + community FE)

Risk set: 6,707 person-periods, 508 first-modern-adoption events.

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| F0 | — | — | $< 10^{-22}$ | 3599 |
| **A1** ($E$) | **2.29** | — | $< 10^{-7}$ | 3576 |
| **C1** (has) | **2.09** | — | $< 10^{-12}$ | **3547** |
| D1 ($N^c$) | 1.40 | — | $< 10^{-10}$ | 3563 |
| H ($E^{\max}$) | 2.20 | — | $< 10^{-7}$ | 3575 |
| ED | 1.24 | — | 0.395 | 3601 |
| V1 ($V$) | 0.34 | **0.899** | 0.144 | 3599 |
| V2: V/E | 0.16 / 2.47 | **0.833** / — | 0.017 / $< 10^{-8}$ | 3572 |
| AED: E/ED | 2.41 / 1.61 | — | $< 10^{-7}$ / 0.064 | 3575 |
| **VAED**: V/E/ED | 0.18 / 2.58 / 1.54 | **0.842** / — / — | 0.022 / $< 10^{-9}$ / 0.097 | **3572** |

**Read.** The classical Valente-style contagion finding **survives and strengthens** under the corrected panel. ORs comparable to (or larger than) the v1 KFP-Models-Summary numbers (which had A1=2.26, C1=1.81, D1=1.50, H=2.44 — ours are slightly higher across the board). The methodology bug had no destructive effect on this finding because Valente-style adoption uses the first-modern detection, which works correctly under either interpretation.

With covariates: A1 $E$ = 1.84 ($p < 10^{-3}$), still highly significant. VAED+cov: V per unit = 0.196, **per 10pp = 0.850**.

### 3.3.2 Valente strict replication (new in v3)

The §3.3.1 numbers are FE-controlled. As a separate sanity check, we run the **strict** Valente Table 10-2 specification with NO additional community / period fixed effects:

$$
\mathrm{logit}(p_{it}) = \alpha + \beta_1 t + \beta_2 A^{\mathrm{cum}}_{v,t-1}
+ \beta_3 n^{\mathrm{sent}}_i + \beta_4 n^{\mathrm{recv}}_i
+ \beta_5 E^{\mathrm{coh}}_{i,t-1} + \beta_6 E^{\mathrm{se}}_{i,t-1}
+ \beta_7 \mathrm{children}_i + \beta_8 \mathrm{media}_i
$$

with `t` entering as a continuous integer; $A^{\mathrm{cum}}$ as community-level cumulative modern adoption; $n^{\mathrm{sent}}$ as out-degree of the FP-discussion network; $n^{\mathrm{recv}}$ as in-degree across (village, id) keys; $E^{\mathrm{coh}}$ as the row-normalised cohesion exposure; $E^{\mathrm{se}}$ as the structural-equivalence exposure (`netdiffuseR::struct_equiv(diffnet, v=1)`); $\mathrm{children} = \mathrm{sons} + \mathrm{daughts}$; and **$\mathrm{media} = \mathrm{rowMeans}(\mathrm{media6}\ldots\mathrm{media14}, \,\mathrm{na.rm=TRUE})$** — the frequency-scale media items (range 0–4) per Valente's book. This deliberately replaces the `media1..media5` ownership-flag index used in earlier iterations of the script.

**Strict-replication result on `kfamily$toa` (modern6 first adoption)**: n = 7,103 person-periods, 673 events (matches Valente Table 10-2 reference of n = 7,103). Cluster-robust SE by village.

| Term | $\beta$ | OR | *p* |
|:---|:---:|:---:|:---:|
| (Intercept) | -4.07 | 0.017 | $1.4\times10^{-108}$ |
| t (continuous) | -0.006 | 0.994 | 0.869 |
| $A^{\mathrm{cum}}_{v,t-1}$ | 1.228 | **3.41** | **0.016** |
| $n^{\mathrm{sent}}_i$ | 0.122 | **1.13** | $1.4\times10^{-6}$ |
| $n^{\mathrm{recv}}_i$ | 0.080 | **1.08** | $9.2\times10^{-6}$ |
| $E^{\mathrm{coh}}_{i,t-1}$ | 0.312 | **1.37** | **0.019** |
| $E^{\mathrm{se}}_{i,t-1}$ | -0.051 | 0.95 | 0.763 |
| $\mathrm{children}_i$ | 0.208 | **1.23** | $9.8\times10^{-11}$ |
| $\mathrm{media}_i$ | 0.169 | **1.18** | **0.049** |

**Read.** The Valente strict replication shows the canonical contagion picture: cohesion exposure $E^{\mathrm{coh}}$ enters significantly positive (OR 1.37, $p = 0.019$); structural-equivalence exposure $E^{\mathrm{se}}$ is null (OR 0.95, $p = 0.76$); community-level cumulative adoption $A^{\mathrm{cum}}$ is the largest single effect (OR 3.41, $p = 0.016$); and the personal-tie out- and in-degree both contribute ($n^{\mathrm{sent}}$ OR 1.13, $n^{\mathrm{recv}}$ OR 1.08). Children and media exposure are positive and significant. With `t` as a continuous integer and no fixed effects, period itself is null (OR ≈ 1.0) — variation is fully picked up by the substantive predictors.

This strict spec is reported as a sanity-check / reproduction; the main analysis with FE-controlled specifications (§3.3.1) is the primary report.

A side-by-side fit on `TOA_derivado` (the alternative TOA reconstruction in `R/91-toa-derivation.R`) is in the supplementary CSV (`outputs/tables/table10-2_TOA_derivado.csv`) and gives a qualitatively identical picture (n = 7,594, events = 597; Acum OR 1.79 [ns], Ecoh OR 1.71 ($p < 10^{-4}$), Ese OR 0.92 [ns]).

## 3.4 Cross-dataset adoption comparison

| Dataset | A1 ($E$) | C1 (has) | H ($E^{\max}$) | V2: V (per 10pp) / E | VAED V (per 10pp) / E / ED |
|:---|:---:|:---:|:---:|:---:|:---:|
| ADVANCE e-cig | 4.71 *** | 1.97 *** | 3.07 *** | **0.251** / 5.12 | **0.200** / 5.45 / 1.89† |
| KFP modern6 | 2.29 *** | 2.09 *** | 2.20 *** | **0.833** / 2.47 *** | **0.842** / 2.58 / 1.54† |
| KFP PC | 1.96 ** | 1.47 ** | 1.51† | **0.755** / 2.19 ** | **0.741** / 2.15 / 0.81 |

\*** $p < 10^{-3}$, ** $p < 0.01$, † $p < 0.10$

Adoption shows **interpersonal contagion in both datasets**. Effect sizes are larger in ADVANCE (consistent with adolescent peer salience). KFP modern6 ≈ KFP PC in effect size; the broader (modern6) outcome doesn't gain power, suggesting the contagion is largely about FP normalisation rather than method-specific imitation. $E^{\text{Dis}}$ is marginally positive in joint AED/VAED for both ADVANCE and KFP modern6 — suggestive but not decisive.

---

# 4. Disadoption — Model A (stable)

## 4.1 ADVANCE (no covariates) — n = 1,132, events = 506

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| F0 | — | — | 0.122 | 1527 |
| **A1** | **0.41** | — | 0.018 | 1081 |
| C1 | 0.80 | — | 0.065 | 1527 |
| D1 | 0.82 | — | 0.011 | 1524 |
| H | 0.46 | — | 0.014 | 1254 |
| ED | 0.75 | — | 0.303 | 1090 |
| V1 | 396 | **1.82** | 0.065 | 1527 |
| V2: V/E | 735 / 0.39 | **1.94** / — | 0.088 / 0.014 | 1081 |
| AED: E/ED | 0.36 / 0.54 | — | 0.011 / 0.051 | 1080 |
| **VAED**: V/E/ED | **594 / 0.35 / 0.55** | **1.89** / — / — | 0.098 / 0.008 / 0.062 | **1081** |

Egonet protective + community positive, **both surviving in VAED jointly**.

## 4.2 KFP PC, fpt-only panel — n = 568, events = 150

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| A1 | 0.51 | — | 0.252 | 640 |
| C1 | 0.66 | — | 0.131 | 639 |
| D1 | 0.85 | — | 0.343 | 640 |
| H | 0.51 | — | 0.148 | 639 |
| ED | 0.73 | — | 0.615 | 641 |
| V1 | 144 | **1.64** | 0.029 | 636 |
| V2: V/E | 308 / 0.39 | **1.77** / — | 0.014 / 0.114 | 636 |
| AED: E/ED | 0.45 / 0.60 | — | 0.183 / 0.412 | 641 |
| **VAED**: V/E/ED | 295 / 0.34 / 0.62 | **1.77** / — / — | 0.015 / 0.082 / 0.443 | **637** |

**Read.** With fpt-only data (the "less-informed" panel), egonet predictors hint at a protective effect (OR 0.34–0.66) but only the $V$ coefficient is significant. VAED gives V positive significant + E marginal protective. This is the closest the KFP data comes to ADVANCE's pattern.

## 4.3 KFP PC, fpt-only + covariates — n = 567, events = 150

Covariates absorb some egonet effect; $V$ remains positive significant. Detailed table in supplementary.

## 4.4 KFP PC, canonical (fpt+cfp) — n = 602, events = 188

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| F0 | — | — | 0.123 | 754 |
| A1 | 1.14 | — | 0.735 | 755 |
| C1 | 1.12 | — | 0.613 | 755 |
| D1 | 1.08 | — | 0.572 | 755 |
| H | 1.14 | — | 0.717 | 755 |
| ED | 1.03 | — | 0.959 | 756 |
| **V1** | **1,915** | **2.13** | **0.0006** | **743** |
| V2: V/E | 2,347 / 0.83 | **2.17** / — | 0.0005 / 0.649 | 745 |
| AED: E/ED | 1.16 / 1.09 | — | 0.707 / 0.881 | 757 |
| **VAED**: V/E/ED | **2,405 / 0.86 / 1.17** | **2.18** / — / — | **0.0005** / 0.707 / 0.788 | 746 |

Egonet null. Community very strongly positive. Adding the cfp-extension's 38 events doesn't change the qualitative story but kills the marginal egonet signal that fpt-only had.

## 4.5 KFP PC, canonical + covariates

V remains strong; egonet null; covariates add modest improvement.

## 4.6 KFP modern6 disA — n = 1,779, events = 302 (canonical)

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---:|:---:|:---:|:---:|:---:|
| A1 | 0.85 | — | 0.480 | 1599 |
| H | 0.79 | — | 0.264 | 1599 |
| **V1** | **22.4** | **1.37** | **0.005** | **1592** |
| V2: V/E | 29.1 / 0.75 | **1.40** / — | 0.003 / 0.218 | 1592 |
| **VAED**: V/E/ED | 27.1 / 0.73 / 0.85 | **1.39** / — / — | 0.004 / 0.183 / 0.641 | 1594 |

Same pattern: egonet null, community strong.

## 4.7 Cross-dataset comparison (Model A)

| | ADVANCE | KFP PC fpt-only | KFP PC canonical | KFP modern6 |
|:---|:---:|:---:|:---:|:---:|
| n / ev | 1132 / 506 | 568 / 150 | 602 / 188 | 1779 / 302 |
| A1 ($E$) | **0.41** ** | 0.51 | 1.14 | 0.85 |
| H ($E^{\max}$) | **0.46** ** | 0.51 | 1.14 | 0.79 |
| V1 ($V$, per unit) | 396 † | **144** ** | **1,915** *** | **22.4** *** |
| V1 ($V$, per 10pp) | **1.82** | **1.64** | **2.13** | **1.37** |
| V2: V (per 10pp) / E | **1.94** / **0.39** ** | **1.77** ** / 0.39 | **2.17** *** / 0.83 | **1.40** *** / 0.75 |
| **AED**: E / ED | **0.36** ** / **0.54** † | 0.45 / 0.60 | 1.16 / 1.09 | 0.80 / 0.75 |
| **VAED**: V (per 10pp) / E / ED | **1.89** † / **0.35** ** / **0.55** † | **1.77** ** / **0.34** † / 0.62 | **2.18** *** / 0.86 / 1.17 | **1.39** ** / 0.73 / 0.85 |

\*** $< 0.001$, ** $< 0.01$, * $< 0.05$, † $< 0.10$

ADVANCE shows both effects clearly. KFP PC fpt-only echoes the pattern weakly (V significant, E marginal). KFP PC canonical and KFP modern6 show only the community effect.

---

# 5. Disadoption — Model B (unstable)

## 5.1 ADVANCE — n = 1,196, events = 582

| Spec | OR (per unit) | OR per 10pp $V$ | *p* | AIC |
|:---|:---:|:---:|:---:|:---:|
| A1 | 0.38 | — | 0.019 | 1079 |
| **H** | **0.36** | — | **0.003** | **1319** |
| V1 | 520 | **1.87** | 0.050 | 1528 |
| V2: V/E | 2,207 / 0.36 | **2.16** / — | 0.013 / 0.013 | 1079 |
| **AED**: E/ED | **0.34** / **0.44** | — | **0.010** / **0.005** | 1077 |
| **VAED**: V/E/ED | 1,526 / 0.32 / 0.45 | **2.08** / — / — | 0.020 / 0.007 / 0.008 | **1077** |

Strongest joint signal in the entire study. All three (V, E, ED) significant in VAED.

## 5.2 KFP PC, fpt-only — n = 525, events = 151

A1 OR = 0.59, p = 0.36; H OR = 0.53, p = 0.17; V1 OR = 88, **per 10pp = 1.57**, p = 0.045. Egonet protective trend, V significant. VAED: V = 166 (**per 10pp = 1.67**, $p = 0.028$), E = 0.39 (p = 0.13), ED = 0.57 (p = 0.38).

## 5.3 KFP PC, fpt-only + cov

Similar to 5.2 with covariates absorbing modest egonet signal.

## 5.4 KFP PC, canonical — n = 557, events = 188

A1 OR = 1.13, p = 0.77; H OR = 1.05, p = 0.90; **V1 OR = 590** (**per 10pp = 1.89**), $p = 0.005$; V2: V = 725 (**per 10pp = 1.93**) / E = 0.84. Egonet null; V strong.

## 5.5 KFP PC, canonical + cov

V remains strong.

## 5.6 KFP modern6 disB — n = 1,582, events = 323

A1 OR = 0.93; **V1 OR = 15.9** (**per 10pp = 1.32**), $p = 0.014$; V2: V = 19.3 (**per 10pp = 1.34**) / E = 0.83.

## 5.7 Cross-dataset comparison (Model B)

| | ADVANCE | KFP PC fpt-only | KFP PC canonical | KFP modern6 |
|:---|:---:|:---:|:---:|:---:|
| n / ev | 1196 / 582 | 525 / 151 | 557 / 188 | 1582 / 323 |
| A1 ($E$) | **0.38** * | 0.59 | 1.13 | 0.93 |
| H | **0.36** ** | 0.53 | 1.05 | 0.80 |
| V1 (per unit) | 520 † | 88 * | **590** ** | **15.9** * |
| V1 (per 10pp) | **1.87** | **1.57** | **1.89** | **1.32** |
| V2 V (per 10pp) / E | **2.16** * / **0.36** * | **1.68** * / 0.44 | **1.93** ** / 0.84 | **1.34** ** / 0.83 |
| **VAED**: V (per 10pp) / E / ED | **2.08** * / **0.32** ** / **0.45** ** | **1.67** * / 0.39 / 0.57 | **1.93** ** / 0.82 / 0.92 | **1.33** * / 0.78 / 0.75 |

ADVANCE B is the cleanest joint signal. KFP PC fpt-only echoes faintly. Canonical and modern6: only V.

---

# 6. Disadoption — Model C (recurrent)

## 6.1 ADVANCE — n = 1,217, events = 591

A1 OR = 0.42 ($p = 0.019$); H OR = 0.44 ($p = 0.006$); V1 OR = 428 (**per 10pp = 1.83**, $p = 0.035$); V2: 761 (**per 10pp = 1.94**) / 0.40; **VAED**: V = 595 (**per 10pp = 1.89**, $p = 0.048$) / E = 0.36 ($p = 0.007$) / ED = 0.52 ($p = 0.026$).

## 6.2 KFP PC, fpt-only — n = 579, events = 161

A1 OR = 0.60 (p = 0.35); V1 OR = 79 (**per 10pp = 1.55**, p = 0.041); V2: 149 (**per 10pp = 1.65**) / 0.46.

## 6.3 KFP PC, fpt-only + cov

Similar with covariates.

## 6.4 KFP PC, canonical — n = 621, events = 207

A1 OR = 1.18; **V1 OR = 547** (**per 10pp = 1.88**), $p = 0.003$; V2: V = 609 (**per 10pp = 1.90**) / E = 0.90.

## 6.5 KFP PC, canonical + cov

V remains strong.

## 6.6 KFP modern6 disC — n = 1,850, events = 373

A1 OR = 0.90; **V1 OR = 13.5** (**per 10pp = 1.30**), $p = 0.011$; V2: 16.6 (**per 10pp = 1.32**) / 0.81.

## 6.7 Cross-dataset comparison (Model C)

| | ADVANCE | KFP PC fpt-only | KFP PC canonical | KFP modern6 |
|:---|:---:|:---:|:---:|:---:|
| n / ev | 1217 / 591 | 579 / 161 | 621 / 207 | 1850 / 373 |
| A1 ($E$) | **0.42** * | 0.60 | 1.18 | 0.90 |
| H | **0.44** ** | 0.60 | 1.13 | 0.82 |
| V1 (per unit) | 428 * | 79 * | **547** ** | **13.5** * |
| V1 (per 10pp) | **1.83** | **1.55** | **1.88** | **1.30** |
| V2 V (per 10pp) / E | **1.94** * / 0.40 * | **1.65** * / 0.46 | **1.90** ** / 0.90 | **1.32** ** / 0.81 |
| **VAED**: V (per 10pp) / E / ED | **1.89** * / **0.36** ** / **0.52** * | **1.64** * / 0.43 / 0.69 | **1.90** ** / 0.91 / 1.07 | **1.31** ** / 0.78 / 0.84 |

Very similar to Model A. ADVANCE keeps both signals; KFP only V.

---

# 7. Sanity checks

## 7.1 ADVANCE — positive control (cigarette adoption) and placebo

| | OR | *p* |
|:---|:---:|:---:|
| **Positive control**: $E^{\text{cig}} \to$ cig adopt | 4.56 | 0.019 |
| **Positive control**: has^cig $\to$ cig adopt | 1.51 | 0.160 |
| **Placebo**: $E^{\text{cig}} \to$ e-cig adopt | 2.58 | 0.059 |
| **Placebo**: has^cig $\to$ e-cig adopt | 1.68 | 0.003 |

Cig peers do predict e-cig uptake (cross-substance effect, common-liability). Not a clean placebo null but the within-substance ($E^{ecig}$) effect is much larger (OR 4.71).

## 7.2 KFP — community subset robustness

Restricting to communities with $V^{\max}_v \ge 0.10$ (23 of 25 communities, drops villages 3 and 21 with very low PC penetration):

- PC adoption: A1 OR = 1.92 ($p = 0.009$); C1 OR = 1.50 ($p = 0.004$). Contagion robust.
- PC disadoption A: A1 OR = 1.15 (ns); V1 OR = 888 (**per 10pp = 1.97**, $p = 0.002$). Same pattern as full sample, V even stronger.

---

# 8. Synthesis

## 8.1 Main findings

| | Egonet ($E$, has, $E^{\max}$) | Community ($V$) per 10pp |
|:---|:---|:---|
| **ADVANCE adoption** | + strong (OR 1.6–4.7) | hazard-denominator artifact (OR ≈ 0.20 per 10pp) |
| **KFP modern6 adoption** | + strong (OR 1.4–2.3) | hazard-denominator artifact (OR ≈ 0.84 per 10pp) |
| **KFP PC adoption** | + moderate (OR 1.5–2.0) | hazard-denominator artifact (OR ≈ 0.75 per 10pp) |
| **ADVANCE disadoption** (A/B/C) | **− moderate** (OR ≈ 0.4) | **+ strong** (OR ≈ 1.85–2.16 per 10pp) |
| **KFP PC disadoption canonical** | null (OR 1.1) | **+ very strong** (OR ≈ 1.88–2.18 per 10pp) |
| **KFP PC disadoption fpt-only** | − marginal (OR 0.5–0.7) | + moderate (OR ≈ 1.55–1.77 per 10pp) |
| **KFP modern6 disadoption** | null (OR 0.8–0.9) | + moderate (OR ≈ 1.30–1.40 per 10pp) |

## 8.2 Reading

- **Adoption is contagion in both datasets**. Stronger in ADVANCE (adolescent peer salience), present in KFP whether we use modern6 or PC narrowly. The Valente strict replication on KFP modern6 (§3.3.2) reproduces the canonical contagion picture even with no FE: $E^{\mathrm{coh}}$ OR 1.37 ($p = 0.019$), $A^{\mathrm{cum}}$ OR 3.41 ($p = 0.016$), out- and in-degree both significant.
- **Disadoption is two-level in ADVANCE** (close ties protect, community ambient pushes out) but **community-only in KFP**. The cleanest joint signal is **ADVANCE Model B with VAED**: V per 10pp = 2.08, E = 0.32, ED = 0.45, all significant at $\le 0.02$.
- **$E^{\text{Dis}}$ alone is null everywhere**. In joint AED/VAED specs it adds marginal information in ADVANCE B/C (negative direction = "bigger drop from peak protects further"). In KFP it doesn't add.
- The KFP egonet null on disadoption is robust to covariates, community subsetting, and choice of risk-set flavour A/B/C. The fpt-only panel hints at the protective direction but the cfp-augmented canonical panel washes it out.

## 8.3 What changed substantively from v1

The corrected panel altered three substantive results in KFP:

1. The "egonet protective" PC disadoption finding from v1 (OR = 0.06, $p = 0.049$) does not survive. Under the corrected panel it's null at the canonical level and only marginal in the fpt-only sub-panel.
2. The Valente-style adoption contagion finding *strengthens* (modern6 OR 2.29, $p < 10^{-7}$ vs v1's 2.26).
3. The community saturation effect is preserved and even strengthened (modern6 disA: V went from 4.85 to 22.4, **per 10pp from 1.17 to 1.37**).

The "egonet anchor" narrative for KFP that v1 emphasised was an artifact. The new narrative: KFP and ADVANCE agree on adoption (contagion) but diverge on disadoption (ADVANCE has both levels, KFP has only community).

## 8.4 What changed in v3

- **Terminology**: "cluster" → "community" throughout the narrative. The R model factor `village_fe` is renamed to `community_fe`. (`sandwich::vcovCL` keeps its API name.)
- **V coefficient interpretation**: per-10pp annotations everywhere. The community effect now reads more sensibly — e.g. "ADVANCE disadoption: each 10pp rise in school e-cig prevalence roughly doubles the odds of stopping" (OR per 10pp ≈ 1.83–2.16) instead of "OR ≈ 400–2200 per unit V".
- **Valente strict replication (§3.3.2)**: with the corrected media coding (`mean(media6..media14)`) and strict event-history accounting, the spec reproduces n = 7,103 and recovers the textbook contagion picture. This is reported as a sanity check; the FE-controlled spec stays the main analysis.
- **Grade-within-cohort prevalence (§1.3)**: descriptive table showing the rise-and-fall of e-cig past-6mo prevalence within each ADVANCE cohort.
- **TOA match (Annex B)**: both 74.3% (adopter-only) and 83.5% (overall) reported.

## 8.5 Open question for future work

Why do close ties anchor adolescents to e-cig but not 1960s-70s Korean women to PC? Hypotheses worth pursuing:

- **Behaviour visibility**: e-cig use is publicly visible at school; FP is private.
- **Peer-tie type**: friendship vs FP-discussion-tie carry different content.
- **Age and life stage**: identity formation in adolescents vs settled adult contraceptive routines.
- **Network dynamics**: ADVANCE network changes wave to wave; KFP network is static.

None of these are testable without additional data, but they're useful framing.

---

# Annex A — FN_A/B/C/D/F glossary and examples

Definitions reference the **fpt-only panel** as basis for "what we'd see without `cfp` augmentation". Counts under that frame:

- **FN_A** (end-censored on PC + `cfp` non-PC): **116** women. Trajectory ends with PC at last calendar year; `cfp` says she's not on PC at survey.
- **FN_B** (ambig + `cfp` non-PC): **0** under the corrected episode reconstruction. The episode-based panel propagates the last-known state forward, so "ambiguous" trajectories (gap with no info) don't arise the same way as in v1.
- **FN_C** (ambig + `cfp` PC): **0**, same reason.
- **FN_D** (apparent stable PC exit + `cfp` PC): **40** women.
- **FN_F** (never on PC in fpt + `cfp` PC): **82** women.

Three real examples per case:

**FN_F — late PC adoption picked up only by `cfp`**:

```
Row 27 (id=38, village=1):
  fpt:    NormalB  WantMore  NormalB  WantMore  NormalB  Loop  NormalB  Loop  NormalB  NA  NA  NA
  byrt:    4         5        5         6        7       8     0       1       2     .   .   .
  cfp = Condom  cbyr = 3 (= 1973)
```

This woman is never on PC in `fpt` alone but `cfp = Condom` with `cbyr = 1973` (= period 10) tells us she adopted Condom at the very end of the panel. Under canonical reconstruction, state_PC[10] = 1.

**FN_D — apparent exit contradicted by `cfp`**:

```
Row 6 (id=8, village=1):
  fpt:    NoMore  NormalB  NoMore  Loop  Pill  Abortion  NA  NA  NA  NA  NA  NA
  byrt:    4       6        6      7     8       9      .   .   .   .   .   .
  cfp = Pill  cbyr = 9 (= 1969)
```

`fpt` shows Pill in 1968, then Abortion in 1969 (apparent disadoption). But `cfp = Pill, cbyr = 1969` says she was on Pill from 1969 onwards continuously. The canonical reconstruction integrates this: she had an Abortion event in 1969 *while* continuing on Pill (events that can co-exist in the same year). State_PC stays 1 from 1968 onwards.

**FN_A — end-censored + `cfp` non-PC (post-panel exit)**:

Most common case. Woman is on PC at $T = 10$ but `cfp` shows non-PC at survey time. In the canonical panel, the cfp anchor (with its `cbyr`) determines whether the exit happened within or after the panel.

---

# Annex B — `byrt` semantics verification and TOA match metrics

**Test 1: monotonicity of `byrt` across $p$ within woman**

For each woman with ≥2 observed `byrt_p` values:

- **Total**: 829 women
- **`byrt` non-decreasing**: 776 (93.6%)
- **Violations**: 53 (6.4%)

Violations are typically of the form `byrt_1 > byrt_2`, suggesting `byrt_1` represents a "current state at survey" while `byrt_2..byrt_k` represent past episodes in chronological order — a minor data-entry convention difference for some women.

**Test 2: `byrt_year > 1963 + p`**

Of 4,827 observed (i, p) pairs, **2,706 (56.1%)** have `byrt_year > 1963 + p` — impossible if $p$ were a calendar period index. Confirms episode-indexing.

**Test 3: TOA recovery match against `kfamily$toa` — two metrics (v3)**

For 673 modern adopters with `kfamily$toa ≤ 10`:

- "Episode-interp" (decode `byrt_p` for first modern `fpt_p` as TOA): **54.5% match**.
- "Year-interp" (treat $p$ as calendar period): 19.5% match.

Episode-interp wins clearly. The 45.5% of "non-matches" under episode-interp typically come from women whose `kfamily$toa` was derived from `cfp/cbyr` rather than `fpt/byrt`, where the original cleaning used a slightly different rule.

Under our full canonical reconstruction (with `cfp` anchor):

- **Adopter-only match** (numerator: matches between reconstructed TOA-of-modern and `kfamily$toa` among the 673 women with `kfamily$toa ≤ 10`):

  $$ \text{Adopter-only match} = \frac{500}{673} = 74.3\%. $$

  This is the strict test of the reconstruction.

- **Overall match** (numerator: matches across all 1,047 women, after imputing $T = 11$ ("never adopted in panel") for women whose reconstruction shows no modern adoption; `kfamily$toa = 11` for never-adopters likewise):

  $$ \text{Overall match} = \frac{874}{1047} = 83.5\%. $$

  Of these 874 matches, **374 are trivial** (women with both reconstructed TOA = 11 and `kfamily$toa = 11` — i.e. never modern in either dataset). The non-trivial matches are 874 − 374 = 500, which equals the adopter-only-match numerator (consistent).

Reporting both numbers distinguishes "match among adopters" (the strict reconstruction test) from "match overall" (which includes the trivial cases).

---

# Annex C — Treatment B (obs-only) robustness

Treatment A (canonical, NA → 0 for alter pre-history-FP states) is the default. Treatment B excludes pre-history-FP alters from the denominator of $E$. Differences between A and B are small ($\le 5$ percentage points in any coefficient) and don't change any qualitative conclusion. Detailed tables in supplementary material.

---

# Annex D — Substitution and Option II refined counts (canonical KFP panel)

For all person-period transitions starting from PC at $t-1$ (n = 651 such transitions):

| Destination | Count | Treatment |
|:---|:---:|:---|
| Stay in PC (within-PC switch) | 414 | No event |
| Substitute to modern_nonPC | 30 | Right-censured |
| Disadopt to trad | 12 | Event |
| Disadopt to noFP | 195 | Event |
| **Total disadoption events (raw)** | **207** | |

The 30 substitutions are women going PC → {Loop, TL, Vasectomy, Injection}, treated as right-censure under Option II refined. Without this rule (counting them as events), we'd have 237 events; the egonet results don't change qualitatively in either case.

---

# Annex E — KFP panel construction details

Episode list per woman:

- **Source 1**: each `(byrt_p, fpt_p)` pair for $p = 1, \ldots, 12$.
- **Source 2**: `(cbyr, cfp)` survey-time anchor.

Sort key: `byrt_year * 10000 + class_priority * 100 + p`, where class_priority = 1 for FP-active (PC, modern_nonPC, trad), 0 for noFP. cfp gets $p = 99$ (wins ties).

State at calendar year $t$:

- Find latest episode (max sort_key) with `byrt_year ≤ 1963 + t`.
- State = method of that episode; class = its class.

Result: state_PC, state_modern, class matrices over 1047 women × 10 years.

---

# Annex F — ADVANCE schools × waves exact counts

| School | W1 | W2 | W3 | W4 | W5 | W6 | W7 | W8 |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| 101 | 217 | 215 | 236 | 233 | 225 | 215 | 187 | 143 |
| 102 | 92 | 94 | 171 | 208 | 171 | 161 | 153 | 133 |
| 103 | 149 | 169 | 142 | 171 | 164 | 157 | 151 | 145 |
| 104 | 253 | 273 | 314 | 329 | 311 | 299 | 255 | 231 |
| 105 | 141 | 148 | 135 | 138 | 161 | 156 | 149 | 139 |
| 106 | — | 153 | 177 | 178 | 168 | 156 | 158 | 165 |
| 107 | — | 167 | 217 | 229 | 219 | 213 | 191 | 199 |
| 108 | — | 151 | 216 | 214 | 202 | 180 | 137 | 128 |
| 112 | — | 287 | 317 | 295 | 298 | 262 | 274 | 251 |
| 113 | — | 307 | 349 | 354 | 344 | 318 | 321 | 297 |
| 114 | — | 276 | 339 | 329 | 309 | 292 | 258 | 216 |
| 201 | — | — | 190 | 206 | 194 | 188 | 151 | 99 |
| 212 | — | — | 316 | 314 | 306 | 292 | 284 | 277 |
| 213 | — | — | 365 | 351 | 347 | 332 | 328 | 295 |
| 214 | — | — | 302 | 294 | 281 | 263 | 246 | 223 |

---

# Annex G — Code

- `R/00-config.R` — paths configuration (sourced by every script).
- `R/01-kfp-panel.R` — builds canonical and fpt-only panels; outputs txt tables and rds objects. v3 also prints the two TOA match metrics (adopter-only and overall).
- `R/02-advance-panel.R` — builds the ADVANCE long panel and computes per-wave peer exposures.
- `R/03-models-kfp.R` — runs all KFP regressions (adoption, disadoption A/B/C × canonical/fpt-only × with/without covariates). v3 uses `community_fe` in place of `village_fe`.
- `R/04-models-advance.R` — ADVANCE adoption and disadoption A/B/C with VAED added.
- `R/05-figures.R` (new in v3) — builds the grade-within-cohort prevalence table for ADVANCE.
- `R/90-sanity-checks.R` — community subset robustness, byrt verification, FN counts/examples, Option II breakdown.
- `R/91-toa-derivation.R` — TOA reconstruction prioritising fpt/byrt then cfp/cbyr (used by 92).
- `R/92-valente-replication.R` — Valente strict replication; v3 uses `media = rowMeans(media6..media14)` and panel length Tt = 10 (so toa = 11 stays as never-adopted, no spurious events).
