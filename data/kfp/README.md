# KFP — Korean Family Planning panel

Loaded from the `netdiffuseR` package:

```r
library(netdiffuseR)
data(kfamily)
```

`kfamily` is a data frame with 1,047 rows (women) and ~430 columns.

## Variables we use

### Outcome construction

- `fpt1..fpt12`: episode-indexed family planning method codes.
  See `attr(kfamily, "label.table")$fpstatus` for the dictionary.
- `byrt1..byrt12`: calendar start year of episode `p` (cyclic
  encoding '4'..'3' = 1964..1973).
- `cfp`: current method at survey time (1973–74).
- `cbyr`: calendar year that `cfp` started.

**Important**: `fpt_p` is episode-indexed, NOT calendar-year-indexed.
See `docs/methodology.md` for the reconstruction algorithm.

### Network

- `net11..net15`: up to 5 nominations of women in i's FP-discussion
  network at period 1 (treated as the static network in this study).
- `net21..net25`, ..., `net81..net85` exist but are not currently
  used. Future work could exploit time-varying network data.

### Identifiers

- `id`: within-village id.
- `village` (or `comm`): village identifier (1..25).

### Demographics (time-invariant, measured at survey)

- `sons`, `daughts`: number of sons/daughters.
- `age`: age at survey.
- `agemar`: age at marriage.
- `media1..media5`: ownership flags (1=yes, 2=no) for media items.
- `media6..media14`: media frequency scale (0..4).

## Reference

Rogers, E. M., & Kincaid, D. L. (1981). *Communication Networks:
Toward a New Paradigm for Research*. The Free Press.
