---
title: "Methodology — Network-Disadoption"
---

# 1. KFP panel: episode-to-calendar reconstruction

## 1.1 The encoding problem

`netdiffuseR::kfamily` stores each woman's family-planning history in
two parallel sequences:

- `fpt_p` for `p` in 1..12: method status of the woman's `p`-th
  FP-related episode.
- `byrt_p` for `p` in 1..12: calendar year that episode started,
  encoded as a single digit ('4'=1964, '5'=1965, ..., '3'=1973).

The crucial point: **`p` is an episode index, not a calendar year**.
Empirical evidence:

- 56% of all observed `(i, p)` pairs have `byrt_year > 1963 + p`
  (impossible if `p` were a calendar period).
- `byrt_p` is monotonically non-decreasing across `p` for 93.6% of
  women (the typical signature of an episode-ordered structure).
- Comparing `kfamily$toa` with the two interpretations: the
  episode-based reading matches 54.5% of modern adopters; the
  year-based reading matches only 19.5%. With cfp augmentation, the
  episode-based reading climbs to 74.3%.

Some women have anomalous `byrt_1` (e.g. 1973 with later episodes
starting in 1964). These look like "current state at survey" records
followed by chronologically ordered past episodes — about 6.4% of
women. The reconstruction handles them by sorting all (year, episode)
pairs.

## 1.2 The reconstruction algorithm

For each woman `i`:

1. Build an episode list. Each entry: `(byrt_year, method, source, key)`.
   - From `fpt_p`/`byrt_p` for valid `p`: source = `fpt_p`, key = `byrt_year * 10000 + class * 100 + p`.
   - Optionally append the survey anchor `(cbyr, cfp)` with key = `byrt_year * 10000 + class * 100 + 99`.
   - `class = 1` if FP-active (PC, modern_nonPC, trad), `0` otherwise.
2. Sort by key ascending.
3. For calendar year `t = 1, ..., 10` (= 1964..1973):
   - Find the latest episode with `byrt_year <= 1963 + t`.
   - State at year `t` is the method of that episode.

This produces three n × T matrices: `state_PC[i, t]`,
`state_modern[i, t]`, and `class_at_t[i, t]`.

## 1.3 Two panel variants

- **Canonical**: episodes from `fpt`/`byrt` plus the `cfp`/`cbyr`
  anchor. Contains the most information.
- **fpt-only**: episodes from `fpt`/`byrt` only. A "less informed"
  comparison panel.

The default in all reported regressions is the canonical panel.
fpt-only is reported in subsections labelled "fpt-only".

## 1.4 Tie-breaking rules

Within episodes of the same start year:

- FP-active class (PC, modern_nonPC, trad) takes precedence over
  noFP. Rationale: `NormalB` (a birth event) and `Pill` can co-occur
  in the same year — the woman gave birth and was/is on Pill.
- The cfp anchor wins ties over `fpt` episodes (because it gets
  position 99 in the key).

## 1.5 Option II refined (substitution censoring)

For Pill+Condom disadoption: a 1→0 transition counts as an event
only if the destination is `trad` or `noFP`. Transitions to
`modern_nonPC` (Loop, TL, Vasectomy, Injection) are right-censured
as substitutions.

# 2. ADVANCE panel

ADVANCE has direct survey responses per wave with no episode/year
ambiguity. The construction is straightforward:

- Read `wX_adv_data.csv` for wave 1..8.
- Outcome `past_6mo_use_3` (e-cig) coded 0/1 per wave.
- Network from `wXedges_clean.csv`.

For each person-wave we compute lagged peer exposure metrics:
`E_ecig[i, w]`, `Nc_ecig[i, w]`, `has_ecig[i, w]`, `V_ecig[v, w]`.

# 3. Specifications

For every battery (adoption, and disadoption flavours A, B, C):

```
F0:    period FE + community FE
A1:    + E
C1:    + 1[N^c >= 1]
D1:    + N^c
H:     + E^max
ED:    + E^Dis
V1:    + V
V2:    + V + E
AED:   + E + E^Dis
VAED:  + V + E + E^Dis
```

- E = (W * y_{t-1})_i, peer share (row-normalised).
- N^c = (A * y_{t-1})_i, peer count.
- E^max = max over s <= t of E_{i,s}, cumulative peak.
- E^Dis = E^max - E.
- V = (1/|v|) * sum_{j in v} y_{j,t-1}, community saturation.

Standard errors clustered at the community (village or school) level
via `sandwich::vcovCL`.

# 4. Risk-set flavours for disadoption

- **A (stable)**: drop person-waves where 1→0 is followed by
  back-to-1 (transient).
- **B (unstable)**: from first adoption forward, first 1→0 is the
  event; person leaves the risk set.
- **C (recurrent)**: every person-wave with state[t-1]=1 is at risk;
  person can contribute multiple events.

# 5. Substitution counts (KFP canonical)

Of 651 person-period transitions starting from PC:

| Destination | Count | Treatment |
|:---|:---:|:---|
| Stay in PC | 414 | Non-event |
| modern_nonPC | 30 | Right-censured |
| trad | 12 | Event |
| noFP | 195 | Event |
| **Disadoption events (raw)** | **207** | |

# 6. False-negative classification (using fpt-only as basis)

| Code | Trajectory | cfp at survey | Count | Treatment |
|:---:|:---|:---|:---:|:---|
| FN_A | end-censored on PC at T | non-PC | 116 | post-panel exit |
| FN_B | ambiguous (no obs after last PC) | non-PC | 0 | (rare under episode reconstruction) |
| FN_C | ambiguous | PC | 0 | continued PC |
| FN_D | apparent stable PC exit | PC | 40 | continuation; cfp wins |
| FN_F | never PC in fpt | PC | 82 | late PC adoption |

The canonical panel handles all five categories implicitly because
it integrates the `cfp` anchor into the episode list before
reconstruction. The FN classification still has documentary value
for tracing how `cfp` augments the fpt-only baseline.
