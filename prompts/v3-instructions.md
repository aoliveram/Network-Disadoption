# Instructions for Disadoption-Study-3.pdf

Use this prompt when you are ready to produce v3 of the report. Read
`CLAUDE.md` and `docs/disadoption-study.pdf` (= v2) first for full
context.

## Goals

Five concrete changes from v2. Do not eliminate any v2 content.

1. **Terminology**: replace "cluster" with "community" throughout the
   report and code.
   - $V_{v,t}$ = "community saturation" (was "cluster/village
     saturation").
   - $\gamma_v$ = "community FE" (was "cluster FE" / "village FE").
   - In R code: rename `cluster_fe` to `community_fe`. Keep the
     `vcovCL` cluster-robust SE call as-is (the function name is
     standard); update only the user-facing variable names.

2. **Section 1.3 (new): prevalence by grade-within-cohort (ADVANCE)**.
   Add a table showing e-cig past_6mo prevalence stratified by:
   - Class of 2024 (schools 101–114): 9th (W1–W2), 10th (W3–W4),
     11th (W5–W6), 12th (W7–W8).
   - Class of 2025 (schools 201, 212–214): 9th (W3–W4), 10th (W5–W6),
     11th (W7–W8).
   Show the rise-and-fall pattern within each cohort. Add a short
   caveat explaining that the existing models already absorb this
   variation through wave + school fixed effects, so the figure is
   descriptive only.

3. **OR per 10pp V**: every table that reports a V coefficient must
   add a column or in-text annotation with `OR per 10pp V =
   exp(beta_V * 0.10)`. The raw OR (per unit V) is misleading because
   V never spans the full 0–1 range. Example formatting:
   `V1 OR = 1,915 (per unit); per 10pp = 2.13`.

4. **Valente strict replication (new subsection in §3)**. Add to the
   KFP modern6 adoption section a sub-section labelled "Valente strict
   replication" running ONLY this specification, with NO additional
   community / period FE:

   $$
   \mathrm{logit}(p_{it}) = \alpha + \beta_1 t + \beta_2 \mathrm{Acum}_{v,t-1}
   + \beta_3 n^{\mathrm{sent}}_i + \beta_4 n^{\mathrm{recv}}_i
   + \beta_5 E^{\mathrm{coh}}_{i,t-1} + \beta_6 E^{\mathrm{se}}_{i,t-1}
   + \beta_7 \mathrm{children}_i + \beta_8 \mathrm{media}_i
   $$

   where:
   - `t`: period as continuous integer (NOT a factor).
   - `Acum`: community-level cumulative modern adoption at $t-1$
     (proportion of women in village `v` already adopted modern by
     period $t-1$).
   - `n_sent`: out-degree from the FP-discussion network
     (`rowSums(!is.na(alter_mat))` where `alter_mat` from `net11..net15`).
   - `n_recv`: in-degree across `(village, id)` keys.
   - `E_coh = (W * y_{t-1})_i`: cohesion exposure (W = row-normalised
     adjacency).
   - `E_se`: structural-equivalence exposure via
     `netdiffuseR::struct_equiv(diffnet, v=1)`.
   - `children = sons + daughts`.
   - `media = rowMeans(media6..media14, na.rm = TRUE)` — the
     **frequency-scale media items** (range 0–4), per Tom Valente's
     book. Confirmed `media6..media14` exist in `kfamily`. Do NOT
     use `media1..media5` (those are binary ownership flags).

   Cluster SE by village. Run on KFP modern6 first-adoption events.
   This is for sanity-check / reproduction; the FE-controlled spec
   from v2 stays as the main analysis.

   The script `R/92-valente-replication.R` already does most of this
   but uses `media1..media5` and includes structural equivalence —
   adapt as needed.

5. **TOA match sanity check (note in §3 or in Annex B)**. Currently
   the report quotes the match between the reconstructed TOA and
   `kfamily$toa` as 74.3% (= 500/673 modern adopters with valid
   match). Add a SECOND match metric that imputes T = 11
   ("never adopted in panel") for women whose reconstructed panel
   shows no modern adoption, then compare across all 1,047 women:

   - Numerator: matches between reconstructed TOA (1..10 if
     adopted, 11 otherwise) and `kfamily$toa` (1..10 or 11).
   - Denominator: 1,047.

   Expected: substantially higher match because women with
   `kfamily$toa = 11` and "never modern" in the reconstruction (≈ 374
   women) all match trivially. Reporting both metrics distinguishes
   "match among adopters" (the strict test of the reconstruction)
   from "match overall" (includes the trivial cases). Update
   `R/01-kfp-panel.R` to print both numbers.

6. **Versioning**:
   - Move existing `docs/disadoption-study.pdf` (= v2) to
     `reports/disadoption-study-2.pdf` (already there).
   - Write v3 to `docs/disadoption-study.{md,pdf}` (overwriting v2).
   - Keep all archive copies in `reports/`.

## Maintain (do not change)

- 10 specs per battery: F0, A1, C1, D1, H, ED, V1, V2, AED, VAED.
- 3 risk-set flavours for disadoption: A (stable), B (unstable),
  C (recurrent).
- Two KFP panel variants: canonical (default) and fpt-only
  (robustness).
- Treatment A (NA → 0) is canonical.
- Option II refined for KFP disadoption.
- Covariates `children + age + agemar + prior_modern_nonPC` for
  KFP "+cov" sub-sections.
- ADVANCE has no covariates in this iteration.
- All FN annexes (A: glossary, B: byrt verification, etc.).

## Workflow

```bash
# 1. Edit R/00-config.R if needed.
# 2. Edit R/03-models-kfp.R to rename variables (cluster -> community).
# 3. Edit R/04-models-advance.R similarly.
# 4. Edit R/92-valente-replication.R: switch to media6..media14,
#    confirm spec matches the strict definition above.
# 5. Add R/05-figures.R (or extend) to build the prevalence-by-grade
#    figure for ADVANCE.
# 6. Re-run all scripts:
Rscript R/01-kfp-panel.R
Rscript R/02-advance-panel.R
Rscript R/03-models-kfp.R
Rscript R/04-models-advance.R
Rscript R/90-sanity-checks.R
Rscript R/91-toa-derivation.R
Rscript R/92-valente-replication.R
# 7. Edit docs/disadoption-study.md to reflect changes:
#    - new §1.3 (grade-within-cohort prevalence)
#    - cluster -> community everywhere
#    - V-OR-per-10pp annotations
#    - new Valente strict subsection in §3
# 8. Compile:
pandoc docs/disadoption-study.md -o docs/disadoption-study.pdf \
       --pdf-engine=xelatex -V mainfont="Helvetica Neue" --toc
```

## Acceptance criteria

- The string "cluster" does not appear anywhere in the v3 report
  except possibly in the technical SE-clustering note.
- Every V coefficient row has both representations.
- A new Valente strict table appears in §3.3 with the 8 predictors.
- The grade-within-cohort table appears in §1.3.
- Both TOA match metrics appear in the report (74.3% adopter-only and
  the higher overall metric across all 1,047 women).
- Models tables are otherwise unchanged from v2.
