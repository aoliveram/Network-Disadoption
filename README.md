# Network-Disadoption (ADVANCE)

Latest report: [docs/disadoption-study.pdf](docs/disadoption-study.pdf) (v4).

**Investigators**: Aníbal Olivera, Thomas Valente (USC), Kristina Miljkovic (USC), Yuchan Cao (USC).

This study examines **disadoption** of e-cigarette use among California adolescents — leaving the behaviour after having taken it up. The diffusion-of-innovations literature has paid most of its attention to adoption ($0 \to$ user state); disadoption (user → non-user, conditional on having reached use) has received much less, even though it is the natural counterpart and a substantively different process. From v4 onward this repository is **ADVANCE-only**; the earlier KFP comparison work is archived under `KFP-study/` (locally) and in `reports/disadoption-study-{1,2,3}.{pdf,md}`.

## Data

**ADVANCE** longitudinal panel — e-cigarette past-6-month use (`past_6mo_use_3`) among **4,437 unique adolescents** in 15 Southern California high schools, fall 2020 – spring 2024 (8 semester waves W1–W8). Two cohorts: class of 2024 (schools 101–114, entering W1 or W2) and class of 2025 (201, 212–214, entering W3). Friendship nominations per wave give a time-varying network. Restricted access (data-use agreement). v4 uses the latest **042326 release** (`data/advance/Data/ADVANCE_W1-W8_Data_Complete_042326.xlsx`) and codebook `data/advance/ADVANCE_W1_to_W10_Codebook_042326.xlsx`.

## Three disadoption flavours (v4 definitions)

- **A — Stable**: $1 \to 0$ with no future return to $1$ (one event per person).
- **B — Experimental**: first $1 \to 0$ (any) — captures attempts to quit regardless of relapse (one event per person).
- **C — Unstable** (window = 1): $1 \to 0$ followed by $1$ at the next observed wave (cyclic). Multiple events per person possible.

The same regression battery is fit at four sample restrictions $Q \in \{5, 6, 7, 8\}$ (minimum consecutive observed waves of e-cig per student) to test robustness against missing-trailing-observation misclassification.

## Headline findings (v4, Q = 5)

Logit coefficients (p in parens). Bold = $p < 0.05$.

| Predictor | Adopters | A (Stable) | B (Experimental) | C (Unstable) |
|:---|:---:|:---:|:---:|:---:|
| Perceived Friend Use | **+0.39 (0.000)** | **−0.26 (0.009)** | **−0.37 (0.000)** | **−0.41 (0.020)** |
| Network Exposure (Users) | **+1.75 (0.000)** | −0.94 (0.17) | −0.11 (0.85) | +0.91 (0.32) |
| MDD (depression) | +0.11 (0.47) | −0.17 (0.59) | **−0.71 (0.010)** | **−1.14 (0.038)** |
| Asian | **−0.44 (0.012)** | −0.20 (0.61) | +0.19 (0.62) | −0.84 (0.19) |
| In-degree | **+0.07 (0.017)** | +0.05 (0.48) | +0.05 (0.43) | −0.01 (0.96) |
| Sexual Minority | **+0.38 (0.011)** | +0.05 (0.88) | +0.28 (0.34) | +0.35 (0.49) |

The cleanest two-sided lever in the study is **perceived peer use of e-cigarettes**: it raises adoption odds and lowers cessation odds of every kind (A, B, C). MDD predicts non-cessation among ever-users (B and C). See `docs/disadoption-study.pdf` for the full 13-predictor tables across all four Q levels.

## Pipeline

```r
install.packages(c("readxl", "dplyr", "Matrix", "sandwich", "lmtest",
                    "lme4", "here"))

source("R/00-config.R")
source("R/01-advance-panel.R")     # wide XLSX -> long panel + covariates
source("R/02-event-builder.R")     # A / B / C events + Q-restriction
source("R/03-network-features.R")  # degree, E_users, E_dis-adopters
source("R/04-regressions.R")       # 4 outcomes x 4 Q levels
```

Outputs:

- `outputs/intermediate/advance_panel_v4.rds` — long panel (35,496 person-waves × 21 covariates).
- `outputs/intermediate/v4_panel_*_Q*_full.rds` — per-outcome / per-Q panels with all features attached.
- `outputs/tables/v4_regression_table_Q{5,6,7,8}.csv` — final tables.
- `docs/disadoption-study.{md,pdf}` — write-up.

## Repository structure

```
.
├── R/
│   ├── 00-config.R
│   ├── helpers.R
│   ├── 01-advance-panel.R
│   ├── 02-event-builder.R
│   ├── 03-network-features.R
│   ├── 04-regressions.R
│   └── 05-figures.R
├── data/advance/
│   ├── ADVANCE_W1_to_W10_Codebook_042326.xlsx
│   ├── Data/                       # 042326 release (gitignored)
│   └── Cleaned-Data/               # legacy CSVs (edges still used)
├── outputs/
│   ├── intermediate/
│   └── tables/                     # gitignored except .gitkeep
├── docs/                           # current write-up
├── reports/                        # archive of v1, v2, v3
├── playground/                     # exploratory scripts
├── prompts/                        # AI-assistant context
├── README.md
├── CLAUDE.md
└── LICENSE
```

KFP archive (frozen) lives outside the main repo under `KFP-study/` (gitignored).

## License

MIT (see `LICENSE`).
