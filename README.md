# Network-Disadoption (ADVANCE)

Code for **"E-cigarette Cessation as a Disadoption Process: Social Network
Influences on Stable and Temporary Quitting"** (PLOS ONE, PONE-D-26-32768,
under revision).

**Investigators**: Aníbal Olivera, Kristina Miljkovic, Yuchan Cao, Sarah Piombo,
Jessica L. Barrington-Trimis, Thomas W. Valente.

The study examines **disadoption** of e-cigarette use among Southern California
adolescents: leaving the behaviour after having taken it up. Diffusion research
has focused on adoption (non-user → user); disadoption (user → non-user) is its
natural counterpart and a substantively different process.

## Data

**ADVANCE** longitudinal panel: past-6-month e-cigarette use among 4,437
adolescents in 14 school cohorts from 11 high schools, surveyed twice a year
from 9th to 12th grade (W1–W10, fall 2020 – spring 2025). School codes: the first
digit is the cohort (1 = class of 2024, 2 = class of 2025) and the last two
digits the school, so 112 and 212 are the same high school. Friendship
nominations at each wave give a time-varying network.

Restricted access (data-use agreement). The code uses the **042326 release**
(`data/advance/Data/`, gitignored) and the edge files regenerated in
`data/advance/Cleaned-Data-042326/` (gitignored).

## Outcomes

Discrete-time event-history logistic regressions at the student-wave level:

- **Adoption**: first transition from non-use to use.
- **Stable disadoption (A)**: use → non-use with no later return to use.
- **Temporary disadoption (B)**: first use → non-use, regardless of later use.
- **Unstable disadoption (C)**: use → non-use followed by use at the next wave
  (several events per student allowed).

## Paper specification

- Predictors, all at the previous wave: perceived friend use, network exposure
  to users (share of nominated friends who use), network exposure to
  disadopters (`E_D_alt`: peak exposure to users up to t − 1 minus exposure at
  t − 1), depressive (MDD) and anxiety (GAD) symptoms, out- and in-degree,
  sex, sexual minority status, parent education, Asian, Hispanic/Latine, and
  cohort.
- Grade-semester fixed effects (1 = fall 9th, …, 8 = spring 12th).
- GLM logistic regression with standard errors clustered by student, for all
  four outcomes. The unstable outcome is also fitted with a student random
  intercept for the supplement (between-student variance = 0).
- Sample: students with at least Q = 7 consecutive waves of e-cigarette data
  (Q = 5, 6 and 8 as robustness checks).

## Pipeline

```r
install.packages(c("readxl", "Matrix", "sandwich", "lmtest", "lme4", "here",
                   "ggplot2", "dplyr", "tidyr", "car", "splines", "pROC",
                   "logistf", "ResourceSelection", "igraph"))

source("R/00-config.R")
source("R/01b-edges-rebuild.R")       # friendship edges W1-W10
source("R/01-advance-panel.R")        # long student-wave panel + covariates
source("R/02-event-builder.R")        # at-risk panels per outcome and Q
source("R/03-network-features.R")     # degree, E_users, E_dis, E_D_alt
source("R/04-regressions.R")          # Table 2 (Q = 7), S2a-c (Q = 8, 6, 5), S random intercept
source("R/05d-degree-and-exposure-plots.R") # Figures S6a-S6b
source("R/05e-grade-rate-table.R")    # adoption / disadoption rates by grade-semester
source("R/05f-kusers-rate-table.R")   # Table 4
source("R/05h-Q-sensitivity.R")       # Figure S1
source("R/05i-pfu-rate-table.R")      # Table 3
source("R/06-diagnostics.R")          # S3 (VIF, leave-one-school-out)
source("R/07-block-variations.R")     # Table S4 (alternative peer-cessation measures)
source("R/08-network-plots.R")        # Figure 2
source("R/10-figure1-plos.R")         # Figure 1
source("R/11-revision-analyses.R")    # revision: included vs. excluded, IPW
source("R/12-network-coverage.R")     # revision: network coverage per school and wave
```

`R/helpers.R` defines `attach_gs()`, the `(cohort, wave) → grade-semester`
mapping used by the regression scripts.

Intermediate `.rds` files are written to `report-support/intermediate/`
(gitignored). `outputs/tables/` is gitignored; figures are committed.

## Repository structure

```
.
├── R/                 # paper pipeline (see above)
├── data/              # README files; ADVANCE data are gitignored
├── outputs/
│   ├── tables/        # CSV tables (gitignored)
│   └── figures/       # paper and supplement figures
├── presentations/
├── README.md
└── LICENSE
```

Local only (gitignored): `report-support/` (intermediate files and the scripts
behind the internal reports), `docs/` and `reports/` (internal reports),
`playground/` (exploratory scripts), `papers/` (manuscript drafts).

## License

MIT (see `LICENSE`).
