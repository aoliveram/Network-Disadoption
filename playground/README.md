# playground — robustness bake-off for v3

This folder is exploratory: scripts that probe whether the v3 SE
clustering / random-effects choices need to change before we freeze
the report. **It does not modify any v3 result.**

## Scripts

- `01-twoway-clustering.R` — refits a representative slice of the v3
  battery and reports OR + SE + p under three SE schemes:
  - cluster by community (= village/school; the v3 default)
  - cluster by individual (id)
  - two-way Cameron-Gelbach-Miller (community + id)
- `02-glmer-modelC.R` — refits Model C (recurrent disadoption) on
  ADVANCE, KFP PC canonical, and KFP modern6 as `glmer(... + (1|id))`,
  and compares OR / p / ICC against the v3 GLM-cluster-robust spec.

Outputs land in `playground/twoway_results.{rds,csv}` and
`playground/glmer_modelC_results.{rds,csv}`.

## Bottom line

1. **(B) Two-way clustering is mathematically equivalent to
   community-only clustering in our data because individuals are
   strictly nested within communities.** Cameron-Gelbach-Miller
   collapses: `V_2way = V_comm + V_id − V_{comm∩id} = V_comm + V_id − V_id
   = V_comm`. The bake-off confirms this empirically: ratio
   `SE_2way / SE_comm = 1.000` in **all 34 rows**, zero significance
   flips. So my earlier recommendation of switching to two-way SE was
   misguided — the v3 community-only clustering already gives the
   correct two-way SE under nesting, and no change is needed.

2. **(C) GLMER `(1|id)` on Model C — the headline finding survives,
   but some V coefficients become borderline.** Reviewed across 15
   coefficient rows:

   | Panel          | ICC  | Notes |
   |---|---|---|
   | KFP PC disC    | 0.12 | Headline result robust: V_PC OR per-unit drops marginally (547 → 609 GLM-vs-GLMER), but p stays at 0.001–0.003. |
   | KFP mod6 disC  | 0.19 | V loses conventional significance (p = 0.011 → 0.064 under GLMER). E stays null. |
   | ADV disC       | 0.28 | E (egonet protective) becomes *more* significant (p = 0.019 → 0.007). V loses significance (p = 0.048 → 0.26). EDis loses significance (p = 0.026 → 0.16). |

   ICCs of 0.12–0.28 are real but far below Valente (2025)'s ρ = 0.98
   — the difference is that Valente models a repeated past-30-day
   binary (where chronic users repeat themselves), while we model an
   event-history transition (mostly 0s with at most one 1 per person
   in A/B; recurrent in C).

3. **5 of 15 GLMER comparisons flip at α = 0.05** — and *all* the
   flips are on V or EDis, never on a primary egonet E or has term.
   The "ADVANCE shows both levels, KFP shows only V" narrative needs
   a careful reading once we acknowledge id-level dependence: in
   ADVANCE Model C, the V signal is partly a within-individual
   dependence artefact; in KFP PC canonical, it is robust.

## Recommendation for v3 vs v4

**Don't rewrite v3 model tables. Add a short robustness note in §7
(Sanity checks) that:**

1. Notes the concern raised by Valente et al. (2025, *Soc. Sci. & Med.*)
   about within-individual dependence.
2. Reports the math identity: with individuals nested in communities,
   two-way clustering ≡ cluster-by-community. So the v3 SE are already
   appropriate for the *community* level of dependence.
3. Reports the GLMER `(1|id)` sanity check on Model C:
   - **Robust:** KFP PC canonical V (the headline community-effect
     finding), ADVANCE Model C E (the headline egonet-protective
     finding), and the strict null for KFP egonet on disadoption.
   - **Sensitive:** V in ADVANCE Model C and KFP modern6 Model C lose
     conventional significance under RE.
4. Defers a full RE-on-individual refit to **v4**, because subject-
   specific OR (from `glmer`) are on a different scale than the
   population-averaged OR reported throughout v3, and a full
   re-interpretation would be intrusive.

This keeps v3's commitments (terminology rename, V per-10pp, Valente
strict, grade-within-cohort, both TOA metrics) and adds an honest,
brief robustness paragraph rather than reopening the whole spec ladder.
