# Network-Disadoption — context for Claude Code

This file is loaded automatically by Claude Code at session start. It
gives you everything you need to be useful from minute one. If you have
not read this conversation before, this is the entire briefing.

## The project in one paragraph

Comparative event-history study of peer effects on adoption AND
disadoption of two health behaviours: e-cigarette use among US
high-school adolescents (ADVANCE, 2020–2024, 8 waves) and Pill or
Condom use among 1960s–70s rural Korean women (KFP, 1964–1973, 10
years). The methodological centrepiece is a careful comparison of
how the same set of network specifications behaves in two structurally
different settings.

## Key paths

```
ROOT          = repo root (use here::here())
DATA          = ROOT/data
KFP_DATA      = via netdiffuseR::kfamily (public)
ADVANCE_DATA  = ROOT/data/advance/Cleaned-Data (gitignored, restricted)
INTERMEDIATE  = ROOT/outputs/intermediate (committed *.rds files)
TABLES        = ROOT/outputs/tables
FIGURES       = ROOT/outputs/figures
```

`R/00-config.R` defines all of these. Source it at the top of every
script.

## Data quirks you must know

### KFP: episode-indexed encoding

`fpt_p` and `byrt_p` (p = 1..12) are **episode-indexed**, NOT calendar-
year-indexed. Each row's p-th column refers to the woman's p-th FP
episode in chronological order, with `byrt_p` giving its calendar
start year. v1 of this analysis treated `fpt_p` as "state at calendar
year p" and produced a spurious "egonet protective" finding for
disadoption (OR = 0.06, p = 0.049). v2 rebuilt the panel correctly
and the egonet effect disappears.

The current canonical reconstruction:

1. Collect all `(byrt_p, fpt_p)` episodes plus the `(cbyr, cfp)`
   survey-time anchor.
2. Sort by start year ascending. Within ties: FP-active class wins
   over noFP; `cfp` wins over `fpt` episodes.
3. State at calendar year `t` (= 1964..1973, indexed 1..10) = method
   of the latest episode whose start year is <= 1963 + t.

See `docs/methodology.md` for full algorithm.

### KFP: cyclic year encoding

`byrt_p` and `cbyr` use a single-digit cyclic encoding: '4'=1964,
'5'=1965, ..., '3'=1973. There is no mapping outside 1964–1973;
'4' always means 1964 (never 1974).

### ADVANCE: staggered cohorts

- Schools 101–105: class of 2024, present from W1.
- Schools 106–114: class of 2024, present from W2.
- Schools 201–214: class of 2025, present from W3.

Wave + school fixed effects absorb grade-by-cohort variation in the
regressions.

## Method classification (KFP)

```
PC            = {Pill (5), Condom (4)}
modern_nonPC  = {Loop (3), Vasectomy (6), TL (15), Injection (18)}
trad          = {Rhythm (14), Withdrawal (16), Pessary (17),
                 Jelly (19), Foam (20)}
noFP          = {Pregnant (1), NormalB (2), Menopause (7),
                 Want more (8), No more (9), Infertile (10),
                 Stillbirth (11), Newlywed (12), Abortion (13),
                 Other (21)}
```

## Option II refined (substitution censoring)

For Pill+Condom disadoption analysis:

- Disadoption event = transition from PC to {trad, noFP}.
- Substitution = transition from PC to {modern_nonPC} (Loop, TL,
  Vasectomy, Injection). Treated as right-censure (woman leaves the
  at-risk set without an event).
- Within-PC switches (Pill ↔ Condom) leave state at 1.

## Three risk-set flavours

For every disadoption battery:

- **Model A (stable)**: drop person-waves where 1→0 is followed by
  back-to-1 (transient).
- **Model B (unstable)**: walk forward from first adoption; first 1→0
  counts; person leaves risk set.
- **Model C (recurrent)**: every person-wave with state[t-1]=1 is at
  risk; person can contribute multiple events.

## Spec ladder

For every battery (adoption and each disadoption flavour):

```
F0:    period FE + cluster FE
A1:    + E         (continuous peer share)
C1:    + has       (1[N^c >= 1])
D1:    + Nc        (peer count)
H:     + Emax      (cumulative peak of E)
ED:    + EDis      (Emax - E)
V1:    + V         (community saturation)
V2:    + V + E
AED:   + E + EDis
VAED:  + V + E + EDis
```

For KFP, "+ cov" versions add `children + age + agemar`. ADVANCE has
no covariates in this iteration.

## Standard naming

- Period FE: `t` factor (KFP) or `wave` factor (ADVANCE).
- Community FE: `village_fe` factor (KFP) or `schoolid` factor
  (ADVANCE). **Use the term "community" in user-facing text and v3+
  code.** v2 used "cluster" but we are migrating away from that term
  because it has a different specific meaning in network theory.
- Cluster-robust SE via `sandwich::vcovCL`.

## Two KFP panel variants

- **`kfp_canonical.rds`**: episodes from `fpt`/`byrt` plus the `cfp`
  anchor. Default.
- **`kfp_fptonly.rds`**: episodes from `fpt`/`byrt` only. Provides a
  "less informed" comparison.

Treatment A (NA → 0 for alter pre-history-FP states) is the default
for exposure computations.

## False-negative classification (uses fpt-only as basis)

- **FN_A**: end-censored on PC + `cfp` non-PC (post-panel exit).
- **FN_B**: ambiguous trajectory + `cfp` non-PC. Recovered as
  stable exits in the v1 framework; the canonical panel reconstruction
  handles them implicitly.
- **FN_C**: ambiguous + `cfp` PC. Resolved as continued PC.
- **FN_D**: apparent stable PC exit + `cfp` PC. Continuation.
- **FN_F**: never PC in fpt + `cfp` PC. Late adoption.

## Past mistakes to avoid

1. **DO NOT** treat `fpt_p` as state at calendar year `p`. Always
   reconstruct via the episode → calendar mapping in 01-kfp-panel.R.
2. **DO NOT** impute alter state NA -> 0 implicitly when computing
   peer exposure E without thinking about it. Treatment A (canonical)
   does this deliberately; document the choice.
3. **DO NOT** raise "egonet protective effect in KFP" as the headline
   finding. v2 showed this was an artifact under the corrected panel
   for canonical KFP; only the fpt-only sub-panel hints at the
   protective direction (and not significantly).

## Standard utilities (`R/helpers.R`)

- `decode_year(x)` — single-digit cyclic year decoder
- `fit_logit(formula, data, cluster_var)` — glm + clustered SE
- `row_of(label, fit, term)` — extract one term as a tidy row
- `make_emax_edis(M)` — cumulative peak + gap from a (n × T) matrix
- `build_W(A)` — row-normalised adjacency

## Current state

- v1: `reports/disadoption-study-1.pdf` (frozen, contains the
  spurious egonet result).
- **v2: `docs/disadoption-study.pdf` and `reports/disadoption-study-2.pdf`** (current).
- v3: pending. See `prompts/v3-instructions.md` for the planned
  modifications.

## Pending tasks for v3

1. Replace "cluster" with "community" throughout.
2. Add prevalence-by-grade-within-cohort table for ADVANCE.
3. Report each V coefficient as OR per unit V *and* OR per 10pp V.
4. Add Valente strict replication (no extra FE) on KFP modern6 with
   the specific predictor set listed in `prompts/v3-instructions.md`.
5. Use `media6..media14` (mean) for the Valente media exposure index,
   not `media1..media5`.
6. Keep everything else from v2.

## Conventions

- Coefficients reported as OR + p + AIC.
- Numbered scripts run in order; `R/helpers.R` and `R/00-config.R`
  are sourced as needed.
- Reports written in `docs/disadoption-study.md`, compiled to
  `docs/disadoption-study.pdf` via pandoc + xelatex.
