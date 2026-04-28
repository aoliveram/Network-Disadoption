# ADVANCE — USC ADVANCE study panel

USC ADVANCE is a longitudinal school-based study of substance use and
mental health among California high-school students (Class of 2024 +
partial Class of 2025). Eleven public high schools across seven school
districts in Southern California participated, with semester-spaced
waves W1–W8 covering Fall 2020 through Spring 2024.

## Access

ADVANCE data requires a data-use agreement. Contact the USC ADVANCE
study team to request access. Once authorised, place the files in
this directory:

```
data/advance/Cleaned-Data/
  w1_adv_data.csv         w1edges_clean.csv
  w2_adv_data.csv         w2edges_clean.csv
  w3_adv_data.csv         w3edges_clean.csv
  w4_adv_data.csv         w4edges_clean.csv
  w5_adv_data.csv         w5edges_clean.csv
  w6_adv_data.csv         w6edges_clean.csv
  w7_adv_data.csv         w7edges_clean.csv
  w8_adv_data.csv         w8edges_clean.csv
```

These files are gitignored. They are NOT committed to the repository.

## Variables we use

### Outcome

- `wX_past_6mo_use_3`: e-cigarette use in the past 6 months at wave X
  (binary 0/1). Primary outcome.
- `wX_past_6mo_use_2`: cigarette use (used as a sanity-check positive
  control).

### Identifiers

- `record_id`: stable across waves.
- `schoolid` (or `wX_schoolid`): one of {101..114, 201, 212–214}.

### Network

- `wXedges_clean.csv`: edge list (ego, alter, schoolid) of
  friendship nominations within school at wave X.

### Demographics (per wave)

- `wX_dem_gender`, `wX_race`, `wX_eth`: standard demographics.
  Coding may shift slightly across waves; see the codebook.

## Cohort and grade structure

```
Schools 101–105:    class of 2024, present W1..W8
Schools 106–114:    class of 2024, present W2..W8
Schools 201, 212–214: class of 2025, present W3..W8
```

Class of 2024 grade-by-wave:
- 9th: W1, W2
- 10th: W3, W4
- 11th: W5, W6
- 12th: W7, W8

Class of 2025 grade-by-wave:
- 9th: W3, W4
- 10th: W5, W6
- 11th: W7, W8

## Reference

USC ADVANCE study team (Jessica Barrington-Trimis, Adam Leventhal et al.).
University of Southern California, Keck School of Medicine.
