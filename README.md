# Network-Disadoption

Comparative network-effects study of adoption and disadoption in two
panels:

- **ADVANCE**: e-cigarette use among 1,047 adolescents in 11 California
  high schools, 2020–2024 (8 waves, semester-spaced).
- **KFP**: Pill or Condom use among 1,047 women in 25 Korean villages,
  1964–1973 (10 calendar years).

The current report (`docs/disadoption-study.pdf`) covers v2 of the
analysis, with corrected episode-to-calendar reconstruction of the
KFP panel.

## Headline findings

| Outcome | Egonet effect | Community effect |
|:---|:---|:---|
| ADVANCE adoption (e-cig) | OR 1.6 to 4.7, *p* < 1e-10 | hazard-denominator artifact |
| KFP modern6 adoption | OR 1.4 to 2.3, *p* < 1e-7 | hazard-denominator artifact |
| KFP Pill+Condom adoption | OR 1.5 to 2.0, *p* < 0.01 | hazard-denominator artifact |
| ADVANCE disadoption (A/B/C) | OR 0.4, *p* < 0.02 (protective) | OR 400 to 2200, *p* < 0.05 |
| KFP Pill+Condom disadoption | null (OR 1.0 to 1.2) | OR 547 to 2400, *p* < 0.005 |

## Methodological correction

`netdiffuseR::kfamily` encodes FP-related episodes (not calendar-year
states) in `fpt_p` and `byrt_p`. A calendar-year reconstruction is
required for valid panel-state inference. Without it, regression
coefficients on egonet-level peer exposure are biased toward spurious
significance. See `docs/methodology.md` for the construction algorithm.

## Repository structure

```
.
├── R/                  # numbered scripts (run in order)
│   ├── 00-config.R     # paths configuration
│   ├── helpers.R       # shared utilities
│   ├── 01-kfp-panel.R
│   ├── 02-advance-panel.R
│   ├── 03-models-kfp.R
│   ├── 04-models-advance.R
│   ├── 90-sanity-checks.R
│   ├── 91-toa-derivation.R
│   └── 92-valente-replication.R
├── data/               # raw data instructions, not committed
├── outputs/            # generated artefacts
│   ├── intermediate/   # .rds files (committed; regeneratable)
│   ├── tables/         # CSV/TeX tables
│   └── figures/        # plots
├── docs/               # current write-up (latest only)
├── reports/            # archive of past report versions
├── prompts/            # AI-assistant context and prompts
├── README.md
├── CLAUDE.md           # context loaded automatically by Claude Code
└── LICENSE
```

## Reproduction

KFP data ships with `netdiffuseR::kfamily` (public, no setup needed).

ADVANCE data requires a data-use agreement; see `data/advance/README.md`
for access instructions. Once obtained, place the cleaned CSV files in
`data/advance/Cleaned-Data/` (gitignored).

```r
# install required packages once
install.packages(c("netdiffuseR", "Matrix", "sandwich", "lmtest", "dplyr",
                   "here", "readxl"))

# from the repo root, run scripts in order
source("R/01-kfp-panel.R")
source("R/02-advance-panel.R")
source("R/03-models-kfp.R")
source("R/04-models-advance.R")
source("R/90-sanity-checks.R")
source("R/91-toa-derivation.R")
source("R/92-valente-replication.R")
```

All intermediate artefacts land in `outputs/intermediate/`; published
tables in `outputs/tables/`.

## Working with AI assistants

`CLAUDE.md` is loaded automatically by Claude Code at session start.
Read `prompts/onboarding-AI.md` for a short briefing or
`prompts/v3-instructions.md` to drive the next iteration of the report.

## License

MIT (see `LICENSE`).
