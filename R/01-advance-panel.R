# ================================================================
# 01-advance-panel.R  (v4)
#
# Build the ADVANCE long person-wave panel from the 042326 release
# (`data/advance/Data/ADVANCE_W1-W8_Data_Complete_042326.xlsx`),
# wide -> long, with all the covariates the v4 regression battery
# needs.
#
# Output: outputs/intermediate/advance_panel_v4.rds.
# ================================================================

suppressMessages({
  library(readxl)
  library(dplyr)
})

source(file.path(here::here(), "R", "00-config.R"))

WAVES <- 1:8
XL    <- file.path(ADVANCE_DATA, "..", "Data",
                    "ADVANCE_W1-W8_Data_Complete_042326.xlsx")
stopifnot(file.exists(XL))

# ----------------------------------------------------------------
# 1) Selectively read only the columns we need (the wide XLSX has
#    10,341 columns; loading all of them is wasteful).
# ----------------------------------------------------------------
hdr <- read_excel(XL, n_max = 1, .name_repair = "minimal")
nm  <- tolower(names(hdr))

# Variable families per wave
need_per_wave <- function(w) {
  c(sprintf("w%d_schoolid",                    w),
    sprintf("w%d_past_6mo_use_3",              w),
    sprintf("w%d_past_6mo_use_2",              w),  # cig (positive control)
    sprintf("w%d_dem_gender",                  w),
    sprintf("w%d_dem_sexuality",               w),
    sprintf("w%d_dem_high_par_edu",            w),
    sprintf("w%d_race",                        w),
    sprintf("w%d_eth",                         w),
    sprintf("w%d_rcads_mdd_mean",              w),
    sprintf("w%d_rcads_gad_mean",              w),
    sprintf("w%d_ese_ecig_pos_no9_mean",       w),
    sprintf("w%d_ese_ecig_neg_no510_mean",     w),
    sprintf("w%d_friends_use_ecig",            w))
}
need <- c("record_id", unlist(lapply(WAVES, need_per_wave)))
ix   <- match(need, nm)
ix   <- ix[!is.na(ix)]

cat(sprintf("Reading %d / %d columns from %s ...\n",
            length(ix), length(nm), basename(XL)))
ct <- rep("skip", length(nm))
ct[ix] <- "numeric"
ct[which(nm == "record_id")] <- "text"

dw <- read_excel(XL, col_types = ct, na = c("", "NA", "."),
                  .name_repair = "minimal")
names(dw) <- tolower(names(dw))
cat(sprintf("Wide: %d rows x %d cols\n", nrow(dw), ncol(dw)))

# ----------------------------------------------------------------
# 2) Apply legacy patches (042326 already corrects most; we double-up).
# ----------------------------------------------------------------
# Race code 8 (declined) -> NA in W4 / W5 (legacy fix per track-changes).
for (w in 4:5) {
  v <- sprintf("w%d_race", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 8] <- NA_real_
}

# DEM_GENDER: code 3 = "prefer not to disclose" -> NA for the female
# dummy (we don't want to interpret refusals as Male).
for (w in WAVES) {
  v <- sprintf("w%d_dem_gender", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 3] <- NA_real_
}

# DEM_sexuality: code 10 = "prefer not to disclose" -> NA for sex_minority.
for (w in WAVES) {
  v <- sprintf("w%d_dem_sexuality", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 10] <- NA_real_
}

# friends_use_ecig: code 6 = "Not sure" -> NA (treated as missing).
for (w in WAVES) {
  v <- sprintf("w%d_friends_use_ecig", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 6] <- NA_real_
}

# ----------------------------------------------------------------
# 3) Wave-by-wave par_edu harmonisation (W7-W8 nine-level scale ->
#    W1-W6 seven-level scale).  Mapping: 1->1 2->2 3->3 4->4
#    5->4 6->4 7->5 8->6 9->7.
# ----------------------------------------------------------------
remap_w78_par <- c(`1`=1L, `2`=2L, `3`=3L, `4`=4L, `5`=4L, `6`=4L,
                    `7`=5L, `8`=6L, `9`=7L)
for (w in 7:8) {
  v <- sprintf("w%d_dem_high_par_edu", w)
  if (v %in% names(dw)) {
    x <- as.integer(dw[[v]])
    out <- rep(NA_integer_, length(x))
    ok <- !is.na(x) & as.character(x) %in% names(remap_w78_par)
    out[ok] <- as.integer(remap_w78_par[as.character(x[ok])])
    dw[[v]] <- out
  }
}

# ----------------------------------------------------------------
# 3b) Patch W1 schoolid: the 042326 release encodes W1 schools as
#     internal codes 1..5; from W2 onwards they appear as 101..105.
#     Empirical mapping (verified by tracking record_id between W1 and
#     W2 in `playground/`): 1->101, 2->104, 3->102, 4->103, 5->105.
# ----------------------------------------------------------------
w1_school_map <- c(`1`=101L, `2`=104L, `3`=102L, `4`=103L, `5`=105L)
v <- "w1_schoolid"
if (v %in% names(dw)) {
  x <- as.integer(dw[[v]])
  out <- x
  for (k in names(w1_school_map)) {
    out[!is.na(x) & x == as.integer(k)] <- w1_school_map[[k]]
  }
  dw[[v]] <- out
}

# ----------------------------------------------------------------
# 4) Wide -> Long transformation.
# ----------------------------------------------------------------
build_wave_long <- function(w) {
  fields <- list(
    schoolid          = sprintf("w%d_schoolid", w),
    ecig              = sprintf("w%d_past_6mo_use_3", w),
    cig               = sprintf("w%d_past_6mo_use_2", w),
    dem_gender        = sprintf("w%d_dem_gender", w),
    dem_sexuality     = sprintf("w%d_dem_sexuality", w),
    par_edu_raw       = sprintf("w%d_dem_high_par_edu", w),
    race              = sprintf("w%d_race", w),
    eth               = sprintf("w%d_eth", w),
    mdd               = sprintf("w%d_rcads_mdd_mean", w),
    gad               = sprintf("w%d_rcads_gad_mean", w),
    ese_pos           = sprintf("w%d_ese_ecig_pos_no9_mean", w),
    ese_neg           = sprintf("w%d_ese_ecig_neg_no510_mean", w),
    friends_use_ecig  = sprintf("w%d_friends_use_ecig", w))
  out <- data.frame(record_id = dw$record_id, wave = w,
                    stringsAsFactors = FALSE)
  for (nm_out in names(fields)) {
    src <- fields[[nm_out]]
    if (src %in% names(dw)) out[[nm_out]] <- dw[[src]]
    else                    out[[nm_out]] <- NA_real_
  }
  out
}
adv <- do.call(rbind, lapply(WAVES, build_wave_long))
cat(sprintf("\nLong panel: %d person-waves\n", nrow(adv)))

# ----------------------------------------------------------------
# 5) Cohort assignment (time-invariant; from the FIRST observed schoolid).
# ----------------------------------------------------------------
schools_2024 <- c(101:105, 106:108, 112:114)
schools_2025 <- c(201, 212:214)
adv_sorted <- adv[order(adv$record_id, adv$wave), ]
first_school <- aggregate(schoolid ~ record_id, data = adv_sorted,
                          FUN = function(x) x[which(!is.na(x))[1]])
first_school$cohort <- ifelse(first_school$schoolid %in% schools_2024, "2024",
                              ifelse(first_school$schoolid %in% schools_2025, "2025",
                                     NA_character_))
adv <- merge(adv, first_school[, c("record_id", "cohort")],
             by = "record_id", all.x = TRUE)
adv <- adv[order(adv$record_id, adv$wave), ]

# ----------------------------------------------------------------
# 6) Derived dummies: female, sex_minority, asian, hispanic.
# ----------------------------------------------------------------
adv$female       <- ifelse(is.na(adv$dem_gender), NA_integer_,
                            as.integer(adv$dem_gender == 0))
adv$sex_minority <- ifelse(is.na(adv$dem_sexuality), NA_integer_,
                            as.integer(adv$dem_sexuality != 1))
adv$asian        <- ifelse(is.na(adv$race), NA_integer_,
                            as.integer(adv$race == 2))
adv$hispanic     <- ifelse(is.na(adv$eth), NA_integer_,
                            as.integer(adv$eth == 1))

# ----------------------------------------------------------------
# 7) par_edu LOCF per student (carry-forward only, no carry-back).
# ----------------------------------------------------------------
locf <- function(x) {
  out <- x
  last <- NA_integer_
  for (i in seq_along(out)) {
    if (!is.na(out[i])) last <- out[i] else out[i] <- last
  }
  out
}
adv$par_edu <- ave(adv$par_edu_raw, adv$record_id, FUN = locf)

# ----------------------------------------------------------------
# 8) Diagnostics
# ----------------------------------------------------------------
cat(sprintf("\nUnique students: %d\n", length(unique(adv$record_id))))
cat("\nPer-wave non-NA ecig counts:\n")
print(tapply(!is.na(adv$ecig), adv$wave, sum))
cat("\nCohort by wave (non-NA ecig only):\n")
print(with(adv[!is.na(adv$ecig), ], table(cohort, wave)))
cat("\npar_edu fill-rate before vs after LOCF (per wave):\n")
for (w in WAVES) {
  rows <- adv$wave == w
  cat(sprintf("  W%d: raw=%4d / after LOCF=%4d / total=%d\n",
              w,
              sum(!is.na(adv$par_edu_raw[rows])),
              sum(!is.na(adv$par_edu[rows])),
              sum(rows)))
}
cat("\nfriends_use_ecig non-NA per wave (after dropping code 6):\n")
print(tapply(!is.na(adv$friends_use_ecig), adv$wave, sum))

# ----------------------------------------------------------------
# 9) Save
# ----------------------------------------------------------------
saveRDS(adv, file.path(INTERMEDIATE, "advance_panel_v4.rds"))
cat(sprintf("\nSaved: %s (%d rows, %d cols)\n",
            file.path(INTERMEDIATE, "advance_panel_v4.rds"),
            nrow(adv), ncol(adv)))
