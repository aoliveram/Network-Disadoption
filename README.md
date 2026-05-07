# Network-Disadoption (ADVANCE)

Latest report: [docs/disadoption-study.pdf](docs/disadoption-study.pdf) (**v5** — W1–W10, **grade-semester FE**, 6 result families, recommended spec at Q = 7).

**Investigators**: Aníbal Olivera, Thomas Valente (USC), Kristina Miljkovic (USC), Yuchan Cao (USC).

This study examines **disadoption** of e-cigarette use among California adolescents — leaving the behaviour after having taken it up. The diffusion-of-innovations literature has paid most of its attention to adoption ($0 \to$ user state); disadoption (user → non-user, conditional on having reached use) has received much less, even though it is the natural counterpart and a substantively different process. From v4 onward this repository is **ADVANCE-only**; the earlier KFP comparison work is archived under `KFP-study/` (locally) and in `reports/disadoption-study-{1,2,3}.{pdf,md}`. v4b is archived as `reports/disadoption-study-5.{md,pdf}`.

## What changed in v5

- Time/cohort control switched from `wave_fe + cohort` (v4b) to **`grade-semester fixed effects (gs_fe) + cohort`**. `gs_fe` is derived from `(cohort, wave)` on the standard ADVANCE timeline (1 = fall 9th, …, 8 = spring 12th); the cohort dummy is retained because the two cohorts experience the same grade-semester at different calendar times.
- New §13 "Recommended specification — full coefficient block" reads off **§6 (alt $E_D$) at Q = 7** with all coefficients including the 7 gs_fe dummies, cohort, and intercept.
- §11 reorganised around descriptive analyses (out-degree distribution, PFU rates, network-exposure rates, grade-semester rates, Q-sensitivity).

## Data

**ADVANCE** longitudinal panel — e-cigarette past-6-month use (`past_6mo_use_3`) among **4,437 unique adolescents** in 15 Southern California high schools, **W1–W10** (10 semester waves, fall 2020 – fall 2024). Two cohorts: class of 2024 (schools 101–114, entering W1 or W2) and class of 2025 (201, 212–214, entering W3 and continuing through W9–W10). Friendship nominations per wave give a time-varying network. Restricted access (data-use agreement). v5 uses the **042326 release** (`data/advance/Data/`) and the regenerated edge files in `data/advance/Cleaned-Data-042326/`.

## Three disadoption flavours

- **A — Stable**: $1 \to 0$ with no future return to $1$ (one event per person).
- **B — Experimental**: first $1 \to 0$ (any) — captures attempts to quit regardless of relapse (one event per person).
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves (cyclic). Multiple events per person possible. Main reports use $W=1$; $W \le 2$, $W \le 3$ as sensitivity.

The same regression battery is fit at four sample restrictions $Q \in \{5, 6, 7, 8\}$ (minimum consecutive observed waves of e-cig per student). With W1–W10 the high-Q samples are dramatically larger than v4: **Q=8** goes from 371 to **1,040 students**.

## Six result families

For each Q ∈ {8, 7, 6, 5}:

- **§5 Main** — $E_D$ = peer share who flipped 1→0 between $w-2$ and $w-1$; C window=1.
- **§6 Alt $E_D$** — $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ (cumulative peak − current). **← headline.**
- **§7 No $E_D$** — refit §5 outcomes without the $E_D$ predictor.
- **§8 Model C window sensitivity** — three columns ($W=1$, $W \le 2$, $W \le 3$).
- **§9 Sensitivity (a)** — $1\to 0$ with NA-only future counted as A.
- **§10 Sensitivity (b)** — observed-wave jumps (skip NA gaps).

All cells are odds ratios $\exp(\hat\beta)$ with cluster-robust (or `glmer`) p-value in parentheses.

## Headline result (v5, §6 alt $E_D$ at Q = 7, gs_fe + cohort)

OR (p in parens). Bold = $p < 0.05$. The §6 alt-$E_D$ specification at Q=7 is the cleanest combined view of adoption and disadoption: 1,711 / 161 / 182 / 161 students in the four columns. Q = 7 is the sweet spot identified in §11.5 (relaxing $Q = 8 \to 7$ alone gains +71% events on A, +84% on B, +114% on C — all subsequent Q steps add far less). The 7 grade-semester dummies are absorbed as nuisance controls and not shown here; see §13 in the report for the full coefficient block including the gs_fe block.

| Predictor | Adopters | A (Stable) | B (Experimental) | C (Unstable) |
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
| **Perceived Friend Use** | **1.470 (0.000)** | **0.729 (0.022)** | **0.716 (0.002)** | 0.779 (0.319) |
| **Network Exposure Users** | **5.684 (0.000)** | **0.104 (0.011)** | **0.232 (0.031)** | 0.800 (0.878) |
| $E_D$ alt | 1.814 (0.253) | 0.374 (0.271) | 0.401 (0.238) | 0.043 (0.323) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

The cleanest two-sided lever in the study is **perceived peer use of e-cigarettes** (PFU): each step on the 0–5 scale raises adoption odds by 47% (OR 1.47, $p < 0.001$) and lowers disadoption odds by 27%–28% (A: OR 0.73, $p = 0.022$; B: OR 0.72, $p = 0.002$). **Network Exposure (Users)** — the friendship-network counterpart of PFU — reinforces this: each unit increase (i.e., moving from no using friends to all using friends) multiplies adoption odds by 5.7× ($p < 0.001$) and divides disadoption odds by 10× on Stable A ($p = 0.011$) and 4× on Experimental B ($p = 0.031$). **MDD** (depressive symptoms) predicts non-cessation on B and C. **$E_D$ alt** (the disadoption-specific peer signal) is consistently in the right direction (OR < 1 on disadoption) but does not reach significance, suggesting that once you control for $E_{\text{users}}$ the disadoption-specific signal carries no incremental power — a reading reinforced by §7 (no $E_D$ at all), where the $E_{\text{users}}$ ORs barely shift.

The signal pattern is **stable across all six families** (§5, §6, §7, §8, §9, §10): PFU and $E_{\text{users}}$ stay significant; $E_D$ never reaches significance under any operationalisation; MDD remains a cessation barrier on B; cohort 2025 experiments more (B). See [docs/disadoption-study.pdf](docs/disadoption-study.pdf) for full tables, sensitivity analyses, raw cross-tabs, degree/exposure visualisations, and the full coefficient block (with gs_fe) in §13.

## Pipeline

```r
install.packages(c("readxl", "Matrix", "sandwich", "lmtest",
                    "lme4", "here", "ggplot2", "dplyr", "tidyr"))

source("R/00-config.R")
source("R/01b-edges-rebuild.R")    # regenerate edges -> Cleaned-Data-042326/
source("R/01-advance-panel.R")     # W1-W10 long panel + covariates
source("R/02-event-builder.R")     # 5 event-definition modes per Q
source("R/03-network-features.R")  # degree, E_users, E_dis, E_D_alt
source("R/04-regressions.R")       # 5 families × 4 Q (raw logit coefs, gs_fe + cohort)
source("R/04b-rebuild-tables-OR.R")# re-emit the 20 CSVs as odds ratios
source("R/04c-section8-tables.R")  # §9 indeterminate compound tables
source("R/04d-no-eD-regressions.R")# §7 (no E_D) family
source("R/05b-section4-figures.R") # §4 effective-N bar plots
source("R/05c-eusers-rate-table.R")# §11.2 E_users-by-proportion rate cross-tab
source("R/05d-degree-and-exposure-plots.R") # §2 degree, §3 per-wave
source("R/05e-grade-rate-table.R") # §11.4 grade-semester rate cross-tab + line graph
source("R/05f-kusers-rate-table.R")# §11.2 k_users-by-count rate cross-tab
source("R/05g-nomination-distribution.R") # §11.1 out-degree distribution by ego status
source("R/05h-Q-sensitivity.R")    # §11.5 Q-sensitivity table + plot
```

`R/helpers.R` defines `attach_gs()`, the `(cohort, wave) → grade-semester` mapping used by all four regression scripts.

Outputs:

- `outputs/intermediate/advance_panel_v4b.rds` — long panel (44,370 person-waves × 21 cols).
- `outputs/intermediate/v4b_panel_*_Q*_<mode>_full.rds` — 80 per-outcome / per-Q / per-mode panels.
- `outputs/intermediate/v4b_results.rds`, `v4b_results_no_eD.rds` — saved fits.
- `outputs/tables/v4b_table_{5,6,7,8,9}_Q{5,6,7,8}.csv` — 20 main regression tables.
- `outputs/tables/v4b_table_no_eD_Q{5..8}.csv` — §7 no-$E_D$ tables.
- `outputs/tables/v4b_table_8a_E_{dis,alt}.csv` — §9 (a) compound tables.
- `outputs/tables/v4b_table_11_*.csv` — §11 rate cross-tabs and Q-sensitivity.
- `outputs/figures/sec*_*.png` — figures embedded in the PDF.
- `docs/disadoption-study.{md,pdf}` — current write-up (v5).
- `reports/disadoption-study-5.{md,pdf}` — frozen v4b archive.

## Repository structure

```
.
├── R/
│   ├── 00-config.R
│   ├── helpers.R                    # incl. attach_gs() (cohort,wave) -> grade-semester
│   ├── 01-advance-panel.R
│   ├── 01b-edges-rebuild.R
│   ├── 02-event-builder.R
│   ├── 03-network-features.R
│   ├── 04-regressions.R              # gs_fe + cohort
│   ├── 04b-rebuild-tables-OR.R
│   ├── 04c-section8-tables.R
│   ├── 04d-no-eD-regressions.R
│   ├── 05-figures.R
│   ├── 05b-section4-figures.R
│   ├── 05c-eusers-rate-table.R
│   ├── 05d-degree-and-exposure-plots.R
│   ├── 05e-grade-rate-table.R
│   ├── 05f-kusers-rate-table.R
│   ├── 05g-nomination-distribution.R
│   └── 05h-Q-sensitivity.R
├── data/advance/
│   ├── ADVANCE_W1_to_W10_Codebook_042326.xlsx
│   ├── Data/                       # 042326 release (gitignored)
│   ├── Cleaned-Data/                # legacy CSVs (gitignored; W1 edges only)
│   └── Cleaned-Data-042326/         # NEW v4b edges (gitignored)
├── outputs/
│   ├── intermediate/                # rds artefacts
│   ├── tables/                      # CSV tables
│   └── figures/                     # PNG figures (gitignored)
├── docs/                            # current write-up (v5)
├── reports/                         # archive (v1, v2, v3, v4, v5 = frozen v4b)
├── playground/                      # exploratory scripts
├── prompts/                         # AI-assistant context (gitignored)
├── README.md
├── CLAUDE.md
└── LICENSE
```

KFP archive (frozen) lives outside the main repo under `KFP-study/` (gitignored).

## License

MIT (see `LICENSE`).
