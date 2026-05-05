# Network-Disadoption (ADVANCE)

Latest report: [docs/disadoption-study.pdf](docs/disadoption-study.pdf) (v4b — W1–W10, 6 result families).

**Investigators**: Aníbal Olivera, Thomas Valente (USC), Kristina Miljkovic (USC), Yuchan Cao (USC).

This study examines **disadoption** of e-cigarette use among California adolescents — leaving the behaviour after having taken it up. The diffusion-of-innovations literature has paid most of its attention to adoption ($0 \to$ user state); disadoption (user → non-user, conditional on having reached use) has received much less, even though it is the natural counterpart and a substantively different process. From v4 onward this repository is **ADVANCE-only**; the earlier KFP comparison work is archived under `KFP-study/` (locally) and in `reports/disadoption-study-{1,2,3}.{pdf,md}`.

## Data (v4b)

**ADVANCE** longitudinal panel — e-cigarette past-6-month use (`past_6mo_use_3`) among **4,437 unique adolescents** in 15 Southern California high schools, **W1–W10** (10 semester waves, fall 2020 – fall 2024). Two cohorts: class of 2024 (schools 101–114, entering W1 or W2) and class of 2025 (201, 212–214, entering W3 and continuing through W9–W10). Friendship nominations per wave give a time-varying network. Restricted access (data-use agreement). v4b uses the latest **042326 release** (`data/advance/Data/`) and the regenerated edge files in `data/advance/Cleaned-Data-042326/`.

## Three disadoption flavours (v4b definitions)

- **A — Stable**: $1 \to 0$ with no future return to $1$ (one event per person).
- **B — Experimental**: first $1 \to 0$ (any) — captures attempts to quit regardless of relapse (one event per person).
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves (cyclic). Multiple events per person possible. v4b reports $W=1$ as main and $W \le 2$, $W \le 3$ as sensitivity.

The same regression battery is fit at four sample restrictions $Q \in \{5, 6, 7, 8\}$ (minimum consecutive observed waves of e-cig per student). With W1–W10 the high-Q samples are dramatically larger than v4: **Q=8** goes from 371 to **1,040 students**.

## Six result families (v4b)

For each Q ∈ {8, 7, 6, 5}:

- **§5 Main** — $E_D$ = peer share who flipped 1→0 between $w-2$ and $w-1$; C window=1.
- **§6 Alt $E_D$** — $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ (cumulative peak − current).
- **§7 No $E_D$** — refit §5 outcomes without the $E_D$ predictor.
- **§8 Model C window sensitivity** — three columns ($W=1$, $W \le 2$, $W \le 3$).
- **§9 Sensitivity (a)** — $1\to 0$ with NA-only future counted as A.
- **§10 Sensitivity (b)** — observed-wave jumps (skip NA gaps).

All cells are odds ratios $\exp(\hat\beta)$ with cluster-robust (or `glmer`) p-value in parentheses.

## Headline result (v4b §6, Q = 7, alt $E_D$)

OR (p in parens). Bold = $p < 0.05$. The §6 alt-$E_D$ specification at Q=7 is the cleanest combined view of adoption and disadoption: 1,711 / 161 / 182 / 161 students in the four columns, large enough that estimates stabilise, and at Q=7 both cohorts are present.

| Predictor | Adopters | A (Stable) | B (Experimental) | C (Unstable) |
|:---|:---:|:---:|:---:|:---:|
| Cohort (2025 vs 2024) | 0.926 (0.685) | 1.791 (0.147) | **2.268 (0.033)** | 1.229 (0.800) |
| Female | 1.344 (0.105) | 0.830 (0.621) | 1.077 (0.846) | 3.361 (0.144) |
| Sexual Minority | **1.442 (0.033)** | 0.672 (0.282) | 0.918 (0.813) | 1.265 (0.721) |
| Parent Ed. | 0.955 (0.450) | 1.018 (0.896) | 0.946 (0.739) | 0.636 (0.123) |
| Asian | **0.626 (0.019)** | 0.841 (0.704) | 0.972 (0.945) | 0.305 (0.144) |
| Hispanic/Latine | 1.073 (0.723) | 0.772 (0.579) | 0.670 (0.321) | 0.232 (0.077) |
| MDD (Major Depressive S.) | 1.179 (0.341) | 0.712 (0.313) | **0.416 (0.005)** | **0.228 (0.028)** |
| GAD (Generalized Anxiety Dis.) | 0.865 (0.348) | 1.360 (0.366) | 1.133 (0.690) | 1.035 (0.957) |
| Out-degree | 0.921 (0.103) | 1.079 (0.569) | 0.886 (0.364) | 0.922 (0.735) |
| In-degree | **1.098 (0.008)** | 1.123 (0.191) | 1.161 (0.063) | 1.041 (0.810) |
| **Perceived Friend Use** | **1.467 (0.000)** | **0.735 (0.021)** | **0.746 (0.007)** | 0.762 (0.284) |
| **Network Exposure Users** | **5.595 (0.000)** | **0.080 (0.004)** | **0.171 (0.011)** | 0.881 (0.933) |
| $E_D$ alt | 1.809 (0.251) | 0.478 (0.434) | 0.342 (0.182) | 0.019 (0.252) |
| Rho (ICC) | — | — | — | 0.000 |
| N Students | 1,711 | 161 | 182 | 161 |
| N Events | 193 | 89 | 129 | 15 |

The cleanest two-sided lever in the study is **perceived peer use of e-cigarettes** (PFU): each step on the 0–5 scale raises adoption odds by 47% (OR 1.47, $p < 0.001$) and lowers disadoption odds by 26%–25% (A: OR 0.74, $p = 0.021$; B: OR 0.75, $p = 0.007$). **Network Exposure (Users)** — the friendship-network counterpart of PFU — reinforces this: each unit increase (i.e., moving from no using friends to all using friends) multiplies adoption odds by 5.6× ($p < 0.001$) and divides disadoption odds by 12× on Stable A ($p = 0.004$) and 6× on Experimental B ($p = 0.011$). **MDD** (depressive symptoms) predicts non-cessation on B and C. **$E_D$ alt** (the disadoption-specific peer signal) is consistently in the right direction (OR < 1 on disadoption) but does not reach significance, suggesting that once you control for $E_{\text{users}}$ the disadoption-specific signal carries no incremental power — a reading reinforced by §7 (no $E_D$ at all), where the $E_{\text{users}}$ ORs barely shift.

The signal pattern is **stable across all six families** (§5, §6, §7, §8, §9, §10): PFU and $E_{\text{users}}$ stay significant; $E_D$ never reaches significance under any operationalisation; MDD remains a cessation barrier on B; cohort 2025 experiments more (B). See [docs/disadoption-study.pdf](docs/disadoption-study.pdf) for full tables, sensitivity analyses, raw cross-tabs, and degree/exposure visualisations.

## Pipeline

```r
install.packages(c("readxl", "Matrix", "sandwich", "lmtest",
                    "lme4", "here", "ggplot2", "dplyr", "tidyr"))

source("R/00-config.R")
source("R/01b-edges-rebuild.R")    # regenerate edges -> Cleaned-Data-042326/
source("R/01-advance-panel.R")     # W1-W10 long panel + covariates
source("R/02-event-builder.R")     # 5 event-definition modes per Q
source("R/03-network-features.R")  # degree, E_users, E_dis, E_D_alt
source("R/04-regressions.R")       # 5 families × 4 Q (raw logit coefs)
source("R/04b-rebuild-tables-OR.R")# re-emit the 20 CSVs as odds ratios
source("R/04c-section8-tables.R")  # §9 indeterminate compound tables
source("R/04d-no-eD-regressions.R")# §7 (no E_D) family
source("R/05b-section4-figures.R") # §4 effective-N bar plots
source("R/05c-eusers-rate-table.R")# §11 E_users rate cross-tab
source("R/05d-degree-and-exposure-plots.R") # §2 degree, §3 per-wave
source("R/05e-grade-rate-table.R") # §11.3 grade-level rate cross-tab
```

Outputs:

- `outputs/intermediate/advance_panel_v4b.rds` — long panel (44,370 person-waves × 21 cols).
- `outputs/intermediate/v4b_panel_*_Q*_<mode>_full.rds` — 80 per-outcome / per-Q / per-mode panels.
- `outputs/intermediate/v4b_results.rds`, `v4b_results_no_eD.rds` — saved fits.
- `outputs/tables/v4b_table_{5,6,7,8,9}_Q{5,6,7,8}.csv` — 20 main regression tables.
- `outputs/tables/v4b_table_no_eD_Q{5..8}.csv` — §7 no-$E_D$ tables.
- `outputs/tables/v4b_table_8a_E_{dis,alt}.csv` — §9 (a) compound tables.
- `outputs/tables/v4b_table_11_*.csv` — §11 rate cross-tabs.
- `outputs/figures/sec*_*.png` — figures embedded in the PDF.
- `docs/disadoption-study.{md,pdf}` — write-up.

## Repository structure

```
.
├── R/
│   ├── 00-config.R
│   ├── helpers.R
│   ├── 01-advance-panel.R
│   ├── 01b-edges-rebuild.R
│   ├── 02-event-builder.R
│   ├── 03-network-features.R
│   ├── 04-regressions.R
│   ├── 04b-rebuild-tables-OR.R
│   ├── 04c-section8-tables.R
│   ├── 04d-no-eD-regressions.R
│   ├── 05-figures.R
│   ├── 05b-section4-figures.R
│   ├── 05c-eusers-rate-table.R
│   ├── 05d-degree-and-exposure-plots.R
│   └── 05e-grade-rate-table.R
├── data/advance/
│   ├── ADVANCE_W1_to_W10_Codebook_042326.xlsx
│   ├── Data/                       # 042326 release (gitignored)
│   ├── Cleaned-Data/                # legacy CSVs (gitignored; W1 edges only)
│   └── Cleaned-Data-042326/         # NEW v4b edges (gitignored)
├── outputs/
│   ├── intermediate/                # rds artefacts
│   ├── tables/                      # CSV tables
│   └── figures/                     # PNG figures (gitignored)
├── docs/                            # current write-up (v4b)
├── reports/                         # archive (v1, v2, v3, v4)
├── playground/                      # exploratory scripts
├── prompts/                         # AI-assistant context (gitignored)
├── README.md
├── CLAUDE.md
└── LICENSE
```

KFP archive (frozen) lives outside the main repo under `KFP-study/` (gitignored).

## License

MIT (see `LICENSE`).
