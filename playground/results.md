# Bake-off results — full numerical detail

## (B) Two-way clustering: SE_2way / SE_comm

**Result: ratio = 1.000 in 34/34 rows, 0 significance flips.**

Reason (mathematical identity): for nested data (individuals in
communities), Cameron-Gelbach-Miller multi-way clustering reduces to
community-only clustering. The intersection cluster
`{community ∩ id}` is just `id` (since each id has one community), so

`V_2way = V_comm + V_id − V_{comm∩id} = V_comm + V_id − V_id = V_comm.`

Confirmed numerically with a small toy in `Rscript -e` (SE_2way matched
SE_comm to all printed digits), and across all 34 v3 specs in
`twoway_results.csv`.

Selected rows from the bake-off (`SE_id` shown for context only — its
value relative to `SE_comm` swings either direction and tells you
nothing actionable, because clustering ONLY by id ignores the
between-community variation that is real):

| Panel | Spec | Term | OR | SE_comm | p_comm | SE_id | p_id | SE_2way | p_2way |
|---|---|---|---|---|---|---|---|---|---|
| ADV adopt | A1 | E | 4.71 | 0.181 | 1e-17 | 0.202 | 2e-14 | 0.181 | 1e-17 |
| ADV adopt | V1 | V | 1e-4 | 1.69 | 2e-7 | 2.60 | 7e-4 | 1.69 | 2e-7 |
| ADV disA | A1 | E | 0.41 | 0.379 | 0.018 | 0.325 | 0.006 | 0.379 | 0.018 |
| ADV disA | VAED V | V | 594 | 3.86 | 0.098 | 4.89 | 0.19 | 3.86 | 0.098 |
| KFP PC disA can | V1 | V_PC | 1915 | 1.93 | 9e-5 | 2.16 | 5e-4 | 1.93 | 9e-5 |
| KFP PC disA can | VAED V | V_PC | 2405 | 2.11 | 2e-4 | 2.18 | 4e-4 | 2.11 | 2e-4 |
| KFP mod6 disA | V1 | V | 22.4 | 1.02 | 0.002 | 1.13 | 0.006 | 1.02 | 0.002 |

Full table: `twoway_results.csv`.

## (C) GLMER `(1|id)` vs GLM cluster-robust on Model C

All 9 GLMER fits converged with `bobyqa`. Wall-time per fit: 3–11 s.

| Panel | Spec | Term | OR_glm | p_glm | OR_glmer | p_glmer | σ²_u | ICC |
|---|---|---|---:|---:|---:|---:|---:|---:|
| ADV disC | A1 | E | 0.42 | 0.019 | 0.39 | **0.007** | 1.19 | 0.27 |
| ADV disC | V1 | V | 428 | 0.035 | 487 | 0.197 | 1.72 | 0.34 |
| ADV disC | VAED | V | 595 | 0.048 | 512 | 0.264 | 1.14 | 0.26 |
| ADV disC | VAED | E | 0.36 | 0.007 | 0.32 | **0.002** | 1.14 | 0.26 |
| ADV disC | VAED | EDis | 0.52 | 0.026 | 0.50 | 0.164 | 1.14 | 0.26 |
| KFP PC disC | A1 | E_PC | 1.18 | 0.65 | 1.18 | 0.71 | 0.50 | 0.13 |
| KFP PC disC | V1 | V_PC | 547 | **0.0007** | 609 | **0.003** | 0.44 | 0.12 |
| KFP PC disC | VAED | V_PC | 613 | **0.0012** | 688 | **0.003** | 0.44 | 0.12 |
| KFP PC disC | VAED | E_PC | 0.92 | 0.81 | 0.92 | 0.85 | 0.44 | 0.12 |
| KFP PC disC | VAED | EDis_PC | 1.07 | 0.92 | 1.11 | 0.86 | 0.44 | 0.12 |
| KFP mod6 disC | A1 | E | 0.90 | 0.55 | 0.90 | 0.67 | 0.82 | 0.20 |
| KFP mod6 disC | V1 | V | 13.5 | **0.009** | 7.5 | 0.079 | 0.77 | 0.19 |
| KFP mod6 disC | VAED | V | 15.3 | **0.011** | 8.8 | 0.064 | 0.76 | 0.19 |
| KFP mod6 disC | VAED | E | 0.78 | 0.27 | 0.80 | 0.38 | 0.76 | 0.19 |
| KFP mod6 disC | VAED | EDis | 0.84 | 0.66 | 0.89 | 0.76 | 0.76 | 0.19 |

Significance flips at α = 0.05: **5 of 15** rows, all on V (3 ×) or EDis
(1 ×) — never on a primary egonet `E`/`E_PC`/`has` term:

| Panel | Spec | Term | p_glm | p_glmer |
|---|---|---|---:|---:|
| ADV disC | V1 | V | 0.035 | 0.197 |
| ADV disC | VAED | V | 0.048 | 0.264 |
| ADV disC | VAED | EDis | 0.026 | 0.164 |
| KFP mod6 disC | V1 | V | 0.009 | 0.079 |
| KFP mod6 disC | VAED | V | 0.011 | 0.064 |

Notes:

- **OR_glmer is subject-specific** (conditional on $u_i$); OR_glm is
  population-averaged. They are not strictly comparable in magnitude;
  the comparison column to focus on is *p-value* and *direction*.
- **σ²_u and ICC** are real but modest (0.12–0.34). The ICC = 0.98
  reported by Valente (2025) reflects a different outcome (repeated
  past-30-day use) and is not directly applicable here.
- **The headline KFP PC canonical V finding is robust** to RE on
  individual: p stays in the 10⁻³ range, OR moves only marginally.
- **The ADVANCE protective E effect is also robust** under RE
  (actually becomes more significant). The community V signal in
  ADVANCE Model C is more fragile.

Full table: `glmer_modelC_results.csv`.
