# ================================================================
# 01-advance-panel.R  (v4b)
#
# Build the ADVANCE long person-wave panel over W1..W10 from the
# 042326 release (W1-W8 wide XLSX + W9-W10 HS wide XLSX).
#
# Output: outputs/intermediate/advance_panel_v4b.rds.
# ================================================================

suppressMessages({
  library(readxl)
})

source(file.path(here::here(), "R", "00-config.R"))

WAVES   <- 1:10
XL_W1W8 <- file.path(ADVANCE_DATA, "..", "Data",
                      "ADVANCE_W1-W8_Data_Complete_042326.xlsx")
XL_W9W10<- file.path(ADVANCE_DATA, "..", "Data",
                      "ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx")
stopifnot(file.exists(XL_W1W8), file.exists(XL_W9W10))

# Variable families per wave
need_per_wave <- function(w) {
  c(sprintf("w%d_schoolid",                    w),
    sprintf("w%d_past_6mo_use_3",              w),
    sprintf("w%d_past_6mo_use_2",              w),
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

# ----------------------------------------------------------------
# 1) Read both XLSX files (only required columns)
# ----------------------------------------------------------------
read_selective <- function(xl, need) {
  hdr <- read_excel(xl, n_max = 1, .name_repair = "minimal")
  nm  <- tolower(names(hdr))
  ix  <- match(need, nm); ix <- ix[!is.na(ix)]
  ct  <- rep("skip", length(nm)); ct[ix] <- "numeric"
  ct[which(nm == "record_id")] <- "text"
  d <- read_excel(xl, col_types = ct, na = c("", "NA", "."),
                  .name_repair = "minimal")
  names(d) <- tolower(names(d))
  d
}

need_w1w8  <- c("record_id", unlist(lapply(1:8,  need_per_wave)))
need_w9w10 <- c("record_id", unlist(lapply(9:10, need_per_wave)))

cat("Reading W1-W8 XLSX...\n")
dw1 <- read_selective(XL_W1W8, need_w1w8)
cat(sprintf("  %d rows x %d cols\n", nrow(dw1), ncol(dw1)))

cat("Reading W9-W10 HS XLSX...\n")
dw2 <- read_selective(XL_W9W10, need_w9w10)
cat(sprintf("  %d rows x %d cols\n", nrow(dw2), ncol(dw2)))

# Merge on record_id (W9-W10 is a strict subset of W1-W8)
dw <- merge(dw1, dw2, by = "record_id", all.x = TRUE)
cat(sprintf("Merged wide: %d rows x %d cols\n", nrow(dw), ncol(dw)))

# ----------------------------------------------------------------
# 2) Apply legacy patches (042326 already corrects most; we double-up).
# ----------------------------------------------------------------
# Race code 8 (declined) -> NA in W4 / W5
for (w in 4:5) {
  v <- sprintf("w%d_race", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 8] <- NA_real_
}
# DEM_GENDER code 3 = "prefer not to disclose" -> NA
for (w in WAVES) {
  v <- sprintf("w%d_dem_gender", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 3] <- NA_real_
}
# DEM_sexuality code 10 = "prefer not to disclose" -> NA
for (w in WAVES) {
  v <- sprintf("w%d_dem_sexuality", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 10] <- NA_real_
}
# friends_use_ecig code 6 = "Not sure" -> NA
for (w in WAVES) {
  v <- sprintf("w%d_friends_use_ecig", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 6] <- NA_real_
}
# W9/W10 schoolid code 999 (transferred-out / unknown) -> NA
for (w in 9:10) {
  v <- sprintf("w%d_schoolid", w)
  if (v %in% names(dw)) dw[[v]][dw[[v]] == 999] <- NA_real_
}

# ----------------------------------------------------------------
# 3) par_edu harmonisation: W7-W8 and W9-W10 use the new 1..9 scale;
#    map back to W1-W6 1..7 scale.
# ----------------------------------------------------------------
remap_par <- c(`1`=1L, `2`=2L, `3`=3L, `4`=4L, `5`=4L, `6`=4L,
                `7`=5L, `8`=6L, `9`=7L)
for (w in 7:10) {
  v <- sprintf("w%d_dem_high_par_edu", w)
  if (v %in% names(dw)) {
    x <- as.integer(dw[[v]])
    out <- rep(NA_integer_, length(x))
    ok  <- !is.na(x) & as.character(x) %in% names(remap_par)
    out[ok] <- as.integer(remap_par[as.character(x[ok])])
    dw[[v]] <- out
  }
}

# ----------------------------------------------------------------
# 4) Patch W1 schoolid: codes 1..5 -> 101..105 (verified empirically)
# ----------------------------------------------------------------
w1_school_map <- c(`1`=101L, `2`=104L, `3`=102L, `4`=103L, `5`=105L)
v <- "w1_schoolid"
if (v %in% names(dw)) {
  x <- as.integer(dw[[v]]); out <- x
  for (k in names(w1_school_map)) {
    out[!is.na(x) & x == as.integer(k)] <- w1_school_map[[k]]
  }
  dw[[v]] <- out
}

# ----------------------------------------------------------------
# 5) Wide -> Long
# ----------------------------------------------------------------
build_wave_long <- function(w) {
  fields <- list(
    schoolid          = sprintf("w%d_schoolid",                w),
    ecig              = sprintf("w%d_past_6mo_use_3",          w),
    cig               = sprintf("w%d_past_6mo_use_2",          w),
    dem_gender        = sprintf("w%d_dem_gender",              w),
    dem_sexuality     = sprintf("w%d_dem_sexuality",           w),
    par_edu_raw       = sprintf("w%d_dem_high_par_edu",        w),
    race              = sprintf("w%d_race",                    w),
    eth               = sprintf("w%d_eth",                     w),
    mdd               = sprintf("w%d_rcads_mdd_mean",          w),
    gad               = sprintf("w%d_rcads_gad_mean",          w),
    ese_pos           = sprintf("w%d_ese_ecig_pos_no9_mean",   w),
    ese_neg           = sprintf("w%d_ese_ecig_neg_no510_mean", w),
    friends_use_ecig  = sprintf("w%d_friends_use_ecig",        w))
  out <- data.frame(record_id = dw$record_id, wave = w,
                    stringsAsFactors = FALSE)
  for (nm_out in names(fields)) {
    src <- fields[[nm_out]]
    out[[nm_out]] <- if (src %in% names(dw)) dw[[src]] else NA_real_
  }
  out
}
adv <- do.call(rbind, lapply(WAVES, build_wave_long))
cat(sprintf("\nLong panel: %d person-waves\n", nrow(adv)))

# ----------------------------------------------------------------
# 6) Cohort assignment
# ----------------------------------------------------------------
schools_2024 <- c(101:105, 106:108, 112:114)
schools_2025 <- c(201, 212:214)
adv_sorted <- adv[order(adv$record_id, adv$wave), ]
first_school <- aggregate(schoolid ~ record_id, data = adv_sorted,
                          FUN = function(x) {
                            ix <- which(!is.na(x))
                            if (length(ix)) x[ix[1]] else NA
                          })
first_school$cohort <- ifelse(first_school$schoolid %in% schools_2024, "2024",
                              ifelse(first_school$schoolid %in% schools_2025, "2025",
                                     NA_character_))
adv <- merge(adv, first_school[, c("record_id", "cohort")],
             by = "record_id", all.x = TRUE)
adv <- adv[order(adv$record_id, adv$wave), ]

# ----------------------------------------------------------------
# 7) Derived dummies
# ----------------------------------------------------------------
adv$female       <- ifelse(is.na(adv$dem_gender),    NA_integer_,
                            as.integer(adv$dem_gender    == 0))
adv$sex_minority <- ifelse(is.na(adv$dem_sexuality), NA_integer_,
                            as.integer(adv$dem_sexuality != 1))
adv$asian        <- ifelse(is.na(adv$race),          NA_integer_,
                            as.integer(adv$race          == 2))
adv$hispanic     <- ifelse(is.na(adv$eth),           NA_integer_,
                            as.integer(adv$eth           == 1))

# ----------------------------------------------------------------
# 8) par_edu LOCF per student
# ----------------------------------------------------------------
locf <- function(x) {
  out <- x; last <- NA_integer_
  for (i in seq_along(out)) {
    if (!is.na(out[i])) last <- out[i] else out[i] <- last
  }
  out
}
adv$par_edu <- ave(adv$par_edu_raw, adv$record_id, FUN = locf)

# ----------------------------------------------------------------
# 9) Diagnostics
# ----------------------------------------------------------------
cat(sprintf("\nUnique students: %d\n", length(unique(adv$record_id))))
cat("\nPer-wave non-NA ecig counts:\n")
print(tapply(!is.na(adv$ecig), adv$wave, sum))
cat("\nCohort by wave (non-NA ecig only):\n")
print(with(adv[!is.na(adv$ecig), ], table(cohort, wave)))

# ----------------------------------------------------------------
# 10) Save
# ----------------------------------------------------------------
saveRDS(adv, file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
cat(sprintf("\nSaved: %s (%d rows, %d cols)\n",
            file.path(INTERMEDIATE, "advance_panel_v4b.rds"),
            nrow(adv), ncol(adv)))
