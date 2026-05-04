# Network-Disadoption (ADVANCE)

Latest report: [docs/disadoption-study.pdf](docs/disadoption-study.pdf) (v4b — W1–W10, 5 result families).

**Investigators**: Aníbal Olivera, Thomas Valente (USC), Kristina Miljkovic (USC), Yuchan Cao (USC).

This study examines **disadoption** of e-cigarette use among California adolescents — leaving the behaviour after having taken it up. The diffusion-of-innovations literature has paid most of its attention to adoption ($0 \to$ user state); disadoption (user → non-user, conditional on having reached use) has received much less, even though it is the natural counterpart and a substantively different process. From v4 onward this repository is **ADVANCE-only**; the earlier KFP comparison work is archived under `KFP-study/` (locally) and in `reports/disadoption-study-{1,2,3}.{pdf,md}`.

## Data (v4b)

**ADVANCE** longitudinal panel — e-cigarette past-6-month use (`past_6mo_use_3`) among **4,437 unique adolescents** in 15 Southern California high schools, **W1–W10** (10 semester waves, fall 2020 – fall 2024). Two cohorts: class of 2024 (schools 101–114, entering W1 or W2) and class of 2025 (201, 212–214, entering W3 and continuing through W9–W10). Friendship nominations per wave give a time-varying network. Restricted access (data-use agreement). v4b uses the latest **042326 release** (`data/advance/Data/`) and the regenerated edge files in `data/advance/Cleaned-Data-042326/`.

## Three disadoption flavours (v4b definitions)

- **A — Stable**: $1 \to 0$ with no future return to $1$ (one event per person).
- **B — Experimental**: first $1 \to 0$ (any) — captures attempts to quit regardless of relapse (one event per person).
- **C — Unstable** (window $W$): $1 \to 0$ followed by $1$ within the next $W$ observed waves (cyclic). Multiple events per person possible. v4b reports $W=1$ as main and $W \le 2$, $W \le 3$ as sensitivity.

The same regression battery is fit at four sample restrictions $Q \in \{5, 6, 7, 8\}$ (minimum consecutive observed waves of e-cig per student). With W1–W10 the high-Q samples are dramatically larger than v4: **Q=8** goes from 371 to **1,040 students**.

## Five result families (v4b)

For each Q ∈ {8, 7, 6, 5}:

- **§5 Main** — $E_D$ = peer share who flipped 1→0 between $w-2$ and $w-1$; C window=1.
- **§6 Alt $E_D$** — $E_D = E^{\max}_{i,1..w-1} - E_{\text{users},i,w-1}$ (cumulative peak − current).
- **§7 Model C window sensitivity** — three columns ($W=1$, $W \le 2$, $W \le 3$).
- **§8 Sensitivity (a)** — $1\to 0$ with NA-only future counted as A.
- **§9 Sensitivity (b)** — observed-wave jumps (skip NA gaps).

Total: **5 sections × 4 Q levels = 20 tables** at `outputs/tables/v4b_table_<sec>_Q<q>.csv`.

## Headline findings (v4b, Q = 5)

Logit coefficients (p in parens). Bold = $p < 0.05$.

| Predictor | Adopters | A (Stable) | B (Experimental) | C (Unstable) |
|:---|:---:|:---:|:---:|:---:|
| Perceived Friend Use | **+0.40 (0.000)** | **−0.31 (0.001)** | **−0.31 (0.000)** | −0.25 (0.105) |
| Network Exposure (Users) | **+1.73 (0.000)** | −0.84 (0.186) | −0.38 (0.495) | +0.73 (0.375) |
| Network Exposure (Dis-adopters) | **+1.12 (0.050)** | −0.33 (0.746) | +0.08 (0.910) | −1.93 (0.377) |
| MDD (depression) | +0.13 (0.385) | −0.20 (0.477) | **−0.63 (0.016)** | **−0.94 (0.047)** |
| Asian | **−0.40 (0.017)** | +0.15 (0.686) | +0.11 (0.740) | −0.88 (0.135) |
| In-degree | **+0.08 (0.011)** | +0.06 (0.370) | +0.08 (0.212) | +0.05 (0.648) |
| Sexual Minority | **+0.36 (0.013)** | −0.18 (0.541) | +0.10 (0.709) | +0.50 (0.261) |
| Female | **+0.36 (0.017)** | −0.59 (0.060) | −0.37 (0.248) | +0.75 (0.221) |

The cleanest two-sided lever in the study is **perceived peer use of e-cigarettes**: it raises adoption odds and lowers cessation odds (A and B). Network Exposure (Users) reinforces it on adoption. **MDD** predicts non-cessation (B and C). The signal pattern is robust across §5/§6/§8 (alt $E_D$ and indeterminates-as-A leave conclusions essentially unchanged); §9 is nearly identical to §5 because the W1–W10 panel has fewer NA gaps than W1–W8.

## Pipeline

```r
install.packages(c("readxl", "Matrix", "sandwich", "lmtest",
                    "lme4", "here"))

source("R/00-config.R")
source("R/01b-edges-rebuild.R")    # regenerate edges -> Cleaned-Data-042326/
source("R/01-advance-panel.R")     # W1-W10 long panel + covariates
source("R/02-event-builder.R")     # 5 event-definition modes per Q
source("R/03-network-features.R")  # degree, E_users, E_dis, E_D_alt
source("R/04-regressions.R")       # 5 families × 4 Q = 20 tables
```

Outputs:

- `outputs/intermediate/advance_panel_v4b.rds` — long panel (44,370 person-waves × 21 cols).
- `outputs/intermediate/v4b_panel_*_Q*_<mode>_full.rds` — 80 per-outcome / per-Q / per-mode panels.
- `outputs/tables/v4b_table_{5,6,7,8,9}_Q{5,6,7,8}.csv` — 20 final tables.
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
│   └── 05-figures.R
├── data/advance/
│   ├── ADVANCE_W1_to_W10_Codebook_042326.xlsx
│   ├── Data/                       # 042326 release (gitignored)
│   ├── Cleaned-Data/                # legacy CSVs (gitignored; W1 edges only)
│   └── Cleaned-Data-042326/         # NEW v4b edges (gitignored)
├── outputs/
│   ├── intermediate/                # rds artefacts
│   └── tables/                      # CSV tables
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
