# Network-Disadoption

Latest report: [docs/disadoption-study.pdf](docs/disadoption-study.pdf) (v3).

**Investigators**: Aníbal Olivera, Thomas Valente (USC), Kristina Miljkovic (USC), Yuchan Cao (USC).

This study focuses on **disadoption** — leaving a behaviour after having taken it up. The diffusion-of-innovations literature has paid most of its attention to adoption (the 1 → state); disadoption (the 0 → state, conditional on having reached 1) has received much less, even though it is the natural counterpart and a substantively different process. Here we examine peer effects on both, side by side, in two structurally different longitudinal panels.

## Data

- **ADVANCE**: e-cigarette past-6-month use among 1,047 adolescents in 11 Southern California high schools, fall 2020 – spring 2024 (8 semester waves). Friendship nominations per wave, time-varying network. Outcome: `past_6mo_use_3`. Two cohorts: class of 2024 (schools 101–114, present from W1–W2) and class of 2025 (201, 212–214, present from W3). 24,089 person-wave rows; 654 first-adoption events; 506 stable disadoption events. Restricted access (data-use agreement required).
- **KFP** (`netdiffuseR::kfamily`): Pill or Condom (PC) use among 1,047 women in 25 Korean villages, 1964–1973 (10 calendar years). FP-discussion network (up to 5 alters, static). Public via the `netdiffuseR` package. Episodes are stored as `fpt_p` / `byrt_p` (episode-indexed, **not** calendar-year-indexed); a corrected reconstruction is required and described in `docs/methodology.md`.

## Headline findings (v3)

Disadoption Models A and B use cluster-robust GLM (population-averaged OR); Model C uses `glmer((1|i))` (subject-specific OR, ICC reported). Per-10pp summaries are robust to the marginal-vs-conditional gap.

| Outcome | Egonet effect | Community effect (per 10pp) |
|:---|:---|:---|
| ADVANCE adoption | OR 1.6–4.7, *p* < 1e-10 | hazard-denominator artifact (OR ≈ 0.20) |
| KFP modern6 adoption | OR 1.4–2.3, *p* < 1e-7 | hazard-denominator artifact (OR ≈ 0.84) |
| KFP PC adoption | OR 1.3–2.0, *p* < 0.05 | hazard-denominator artifact (OR ≈ 0.77) |
| ADVANCE disadoption A/B (GLM) | OR ≈ 0.4 (protective), *p* < 0.02 | OR ≈ 1.85–2.16 |
| ADVANCE disadoption C (GLMM, ICC 0.27) | OR 0.32 in VAED, *p* = 0.002 | OR 1.87 (marginal, *p* = 0.26) |
| KFP PC disadoption canonical A/B (GLM) | null | OR ≈ 1.88–2.18 |
| KFP PC disadoption canonical C (GLMM, ICC 0.12) | null | OR 1.94, *p* = 0.003 (robust) |
| KFP modern6 disadoption A/B (GLM) | null | OR ≈ 1.30–1.40 |
| KFP modern6 disadoption C (GLMM, ICC 0.19) | null | OR 1.22, *p* = 0.08 |

The Valente strict replication on KFP modern6 adoption (no FE; predictors `t`, $A^{\mathrm{cum}}$, in/out-degree, cohesion + structural-equivalence exposure, children, media) reproduces n = 7,103 person-periods / 673 events and recovers the canonical contagion picture ($E^{\mathrm{coh}}$ OR 1.37, *p* = 0.019; $A^{\mathrm{cum}}$ OR 3.41, *p* = 0.016).

## Methodological note

`netdiffuseR::kfamily` encodes FP-related episodes (not calendar-year states) in `fpt_p` and `byrt_p`. A calendar-year reconstruction is required for valid panel-state inference; without it, egonet peer-exposure coefficients are biased. See `docs/methodology.md`.

## Repository structure

```
.
├── R/                  # numbered scripts (run in order)
│   ├── 00-config.R
│   ├── helpers.R
│   ├── 01-kfp-panel.R
│   ├── 02-advance-panel.R
│   ├── 03-models-kfp.R
│   ├── 04-models-advance.R
│   ├── 05-figures.R
│   ├── 90-sanity-checks.R
│   ├── 91-toa-derivation.R
│   └── 92-valente-replication.R
├── data/               # raw data instructions, not committed
├── outputs/
│   ├── intermediate/   # .rds files (committed; regeneratable)
│   ├── tables/         # CSV/TeX tables
│   └── figures/        # plots
├── docs/               # current write-up (latest only)
├── reports/            # archive of past report versions
├── playground/         # exploratory scripts (not part of pipeline)
├── prompts/            # AI-assistant context and prompts
├── README.md
├── CLAUDE.md
└── LICENSE
```

## Reproduction

KFP data is public via `netdiffuseR::kfamily`. ADVANCE data requires a data-use agreement; see `data/advance/README.md`.

```r
install.packages(c("netdiffuseR", "Matrix", "sandwich", "lmtest", "lme4",
                   "dplyr", "here", "readxl"))

source("R/01-kfp-panel.R")
source("R/02-advance-panel.R")
source("R/03-models-kfp.R")
source("R/04-models-advance.R")
source("R/05-figures.R")
source("R/90-sanity-checks.R")
source("R/91-toa-derivation.R")
source("R/92-valente-replication.R")
```

Intermediate artefacts land in `outputs/intermediate/`; published tables in `outputs/tables/`.

## Working with AI assistants

`CLAUDE.md` is loaded automatically by Claude Code at session start. Read `prompts/onboarding-AI.md` for a short briefing or `prompts/v3-instructions.md` for the v3 spec.

## License

MIT (see `LICENSE`).
