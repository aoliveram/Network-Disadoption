# ================================================================
# 12-network-coverage.R
#
# Network coverage descriptives for the PLOS ONE revision (R2.5).
# Counts every friendship nomination in the raw 042326 XLSX releases
# (W2..W10; W1 friend cells are REDCap-internal codes, see 01b) and
# follows it through the filters applied in 01b-edges-rebuild.R.
#
# Per school x wave:
#   respondents        egos with a valid schoolid at that wave
#   nominations        roster selections + typed ("other") names
#   roster             roster selections (alter record_id), self-loops dropped
#   typed              names typed by hand (not matched to the roster)
#   in_study           roster alters with a record_id in the study data
#   alter_responded    ... who also answered that wave (= kept as an edge)
#   alter_valid_ecig   ... with non-missing past-6-month e-cig use
#   roster_ids         distinct student IDs seen in the school-wave
#                      (respondents + every nominated roster ID)
#   zero_valid         respondents with no responding alter with e-cig
#                      data (network exposure undefined)
#
# Outputs:
#   outputs/tables/rev_network_coverage_school_wave.csv
#   outputs/tables/rev_network_coverage_wave.csv
#   outputs/tables/rev_exposure_missing_Q7.csv
# ================================================================
suppressMessages(library(readxl))
source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

XL_W1W8  <- file.path(ADVANCE_DATA, "..", "Data", "ADVANCE_W1-W8_Data_Complete_042326.xlsx")
XL_W9W10 <- file.path(ADVANCE_DATA, "..", "Data", "ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx")
SCHOOLS  <- c(101:108, 112:114, 201, 212:214)
EMPTY    <- c("", "NA", "-999", "-99", "0")

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
ALL_IDS <- unique(panel$record_id)

read_wave <- function(w) {
  f  <- if (w <= 8) XL_W1W8 else XL_W9W10
  nm <- tolower(names(read_excel(f, n_max = 1, .name_repair = "minimal")))
  keep <- c("record_id", sprintf("w%d_schoolid", w),
            grep(sprintf("^w%d_friend[1-7]_(other_)?[0-9]{3}$", w), nm, value = TRUE))
  ct <- rep("skip", length(nm)); ct[nm %in% keep] <- "text"
  d <- read_excel(f, col_types = ct, na = c("", "NA", "."), .name_repair = "minimal")
  names(d) <- tolower(names(d))
  d
}

rows <- list()
for (w in 2:10) {
  cat("Wave", w, "\n")
  d <- read_wave(w)
  s <- suppressWarnings(as.integer(d[[sprintf("w%d_schoolid", w)]]))
  s[!is.na(s) & s == 999L] <- NA
  resp_ids <- d$record_id[!is.na(s)]
  pw <- panel[panel$wave == w, ]
  valid_ecig <- pw$record_id[!is.na(pw$ecig)]

  for (sch in intersect(SCHOOLS, unique(s))) {
    idx <- which(s == sch)
    egos <- d$record_id[idx]
    rc <- intersect(sprintf("w%d_friend%d_%d", w, 1:7, sch), names(d))
    oc <- intersect(sprintf("w%d_friend%d_other_%d", w, 1:7, sch), names(d))
    R <- if (length(rc)) as.matrix(d[idx, rc]) else matrix(NA, length(idx), 0)
    O <- if (length(oc)) as.matrix(d[idx, oc]) else matrix(NA, length(idx), 0)
    R[R %in% EMPTY] <- NA; O[trimws(O) %in% EMPTY] <- NA
    R[!is.na(R) & R == egos[row(R)]] <- NA            # self-nominations
    alt  <- R[!is.na(R)]
    ego_of <- egos[row(R)][!is.na(R)]
    in_study  <- alt %in% ALL_IDS
    responded <- alt %in% resp_ids
    valid     <- responded & alt %in% valid_ecig
    n_valid_by_ego <- tapply(valid, factor(ego_of, levels = egos), sum)
    n_valid_by_ego[is.na(n_valid_by_ego)] <- 0
    rows[[length(rows) + 1]] <- data.frame(
      wave = w, schoolid = sch,
      respondents = length(egos),
      nominators = sum(rowSums(!is.na(R)) + rowSums(!is.na(O)) > 0),
      nominations = sum(!is.na(R)) + sum(!is.na(O)),
      roster = length(alt), typed = sum(!is.na(O)),
      in_study = sum(in_study), alter_responded = sum(responded),
      alter_valid_ecig = sum(valid),
      roster_ids = length(unique(c(egos, alt))),
      zero_valid = sum(n_valid_by_ego == 0))
  }
}
cov <- do.call(rbind, rows)
cov <- within(cov, {
  pct_zero_valid      <- round(100 * zero_valid / respondents, 1)
  pct_valid_of_roster <- round(100 * alter_valid_ecig / roster, 1)
  pct_responded       <- round(100 * alter_responded / roster, 1)
  pct_roster_match    <- round(100 * roster / nominations, 1)
  coverage_est        <- round(100 * respondents / roster_ids, 1)
  mean_outdeg_raw     <- round(nominations / respondents, 2)
})
write.csv(cov, file.path(TABLES, "rev_network_coverage_school_wave.csv"), row.names = FALSE)

agg <- aggregate(cbind(respondents, nominators, nominations, roster, typed, in_study,
                       alter_responded, alter_valid_ecig, roster_ids, zero_valid) ~ wave,
                 data = cov, FUN = sum)
agg <- within(agg, {
  pct_zero_valid      <- round(100 * zero_valid / respondents, 1)
  pct_valid_of_roster <- round(100 * alter_valid_ecig / roster, 1)
  pct_responded       <- round(100 * alter_responded / roster, 1)
  pct_roster_match    <- round(100 * roster / nominations, 1)
  coverage_est        <- round(100 * respondents / roster_ids, 1)
  mean_outdeg_raw     <- round(nominations / respondents, 2)
})
write.csv(agg, file.path(TABLES, "rev_network_coverage_wave.csv"), row.names = FALSE)
print(agg)

# ----------------------------------------------------------------
# Rows lost because network exposure is undefined (Q = 7 panels)
# ----------------------------------------------------------------
PRED_NONET <- c("cohort", "female", "sex_minority", "par_edu", "asian", "hispanic",
                "mdd", "gad", "out_degree", "in_degree", "friends_use_ecig_lag")
miss <- do.call(rbind, lapply(c(Adopters = "adopt", A = "A", B = "B", C = "C"), function(k) {
  d <- attach_gs(readRDS(file.path(INTERMEDIATE, sprintf("v4b_panel_%s_Q7_main_full.rds", k))))
  d <- d[!is.na(d$gs) & complete.cases(d[, c("event", PRED_NONET)]), ]
  lost <- is.na(d$E_users) | is.na(d$E_D_alt)
  data.frame(outcome = k, rows_complete_except_exposure = nrow(d),
             rows_exposure_undefined = sum(lost),
             pct = round(100 * mean(lost), 1),
             events_lost = sum(d$event[lost]),
             outdeg0_among_lost = sum(d$out_degree[lost] == 0, na.rm = TRUE))
}))
write.csv(miss, file.path(TABLES, "rev_exposure_missing_Q7.csv"), row.names = FALSE)
print(miss)
