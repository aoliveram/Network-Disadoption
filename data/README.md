# Data

Raw data is **not** committed to this repository. This file documents
where each dataset comes from and how to make it locally available.

## KFP

KFP data is included in the `netdiffuseR` R package as
`netdiffuseR::kfamily`. No separate download required.

```r
library(netdiffuseR)
data(kfamily)
```

See `data/kfp/README.md` for a description of the variables we use.

## ADVANCE

ADVANCE data requires a data-use agreement with the USC ADVANCE study
team. Once authorised, place the cleaned CSVs (one per wave) in
`data/advance/Cleaned-Data/`. The directory is gitignored.

Required files (W1 through W8):

```
data/advance/Cleaned-Data/
  w1_adv_data.csv          w1edges_clean.csv
  w2_adv_data.csv          w2edges_clean.csv
  ...
  w8_adv_data.csv          w8edges_clean.csv
```

See `data/advance/README.md` for variable conventions and access
instructions.
