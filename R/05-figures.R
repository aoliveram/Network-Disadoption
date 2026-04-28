# ================================================================
# 05-figures.R
#
# Descriptive figures / tables for the v3 report.
#
# Currently builds: e-cig past-6-month prevalence by grade-within-cohort
# (ADVANCE).
#
#   Class of 2024 (schools 101..114): 9th = W1-W2, 10th = W3-W4,
#                                     11th = W5-W6, 12th = W7-W8.
#   Class of 2025 (schools 201, 212..214): 9th = W3-W4, 10th = W5-W6,
#                                          11th = W7-W8.
#
# The grade-within-cohort variation is already absorbed by wave + school
# fixed effects in the regression battery. This figure is descriptive only.
# ================================================================

source(file.path(here::here(), "R", "00-config.R"))

adv <- readRDS(file.path(INTERMEDIATE, "advance_panel.rds"))

# ---- cohort assignment ----
class_2024 <- 101:199           # schools 101..114 in panel after filter
class_2025 <- c(201, 212:214)
adv$cohort <- NA_character_
adv$cohort[adv$schoolid %in% class_2024] <- "Class of 2024"
adv$cohort[adv$schoolid %in% class_2025] <- "Class of 2025"

# ---- grade-within-cohort assignment ----
grade_2024 <- function(w) {
  if (w %in% 1:2) "9th"
  else if (w %in% 3:4) "10th"
  else if (w %in% 5:6) "11th"
  else if (w %in% 7:8) "12th"
  else NA_character_
}
grade_2025 <- function(w) {
  if (w %in% 3:4) "9th"
  else if (w %in% 5:6) "10th"
  else if (w %in% 7:8) "11th"
  else NA_character_
}

adv$grade <- NA_character_
adv$grade[adv$cohort == "Class of 2024"] <-
  vapply(adv$wave[adv$cohort == "Class of 2024"], grade_2024, character(1))
adv$grade[adv$cohort == "Class of 2025"] <-
  vapply(adv$wave[adv$cohort == "Class of 2025"], grade_2025, character(1))

# ---- prevalence + n by cohort x grade x wave ----
agg <- aggregate(
  ecig ~ cohort + grade + wave,
  data = adv[!is.na(adv$cohort) & !is.na(adv$grade), ],
  FUN  = function(x) c(mean = round(mean(x, na.rm = TRUE), 4),
                       n    = sum(!is.na(x)))
)
agg <- data.frame(
  cohort = agg$cohort, grade = agg$grade, wave = agg$wave,
  prev   = agg$ecig[, "mean"], n = as.integer(agg$ecig[, "n"]),
  stringsAsFactors = FALSE
)
grade_order <- c("9th", "10th", "11th", "12th")
agg$grade   <- factor(agg$grade, levels = grade_order)
agg <- agg[order(agg$cohort, agg$grade, agg$wave), ]

cat("\n==== ADVANCE: e-cig past-6mo prevalence by grade-within-cohort ====\n")
print(agg, row.names = FALSE)

# ---- collapsed by cohort x grade (averaged across the 1-2 waves) ----
collapse <- aggregate(
  cbind(prev_w = prev * n, ecig_n = n) ~ cohort + grade,
  data = agg, FUN = sum
)
collapse$prev <- round(collapse$prev_w / collapse$ecig_n, 4)
collapse <- collapse[order(collapse$cohort, collapse$grade),
                     c("cohort", "grade", "prev", "ecig_n")]
names(collapse) <- c("cohort", "grade", "prevalence", "n_person_waves")

cat("\n==== Collapsed by cohort x grade (weighted average over waves) ====\n")
print(collapse, row.names = FALSE)

# ---- save ----
saveRDS(list(by_wave = agg, collapsed = collapse),
        file.path(INTERMEDIATE, "advance_grade_prevalence.rds"))
write.csv(agg,      file.path(TABLES, "advance_grade_prevalence_by_wave.csv"),
          row.names = FALSE)
write.csv(collapse, file.path(TABLES, "advance_grade_prevalence.csv"),
          row.names = FALSE)
cat(sprintf("\nSaved: %s\n", file.path(INTERMEDIATE, "advance_grade_prevalence.rds")))
cat(sprintf("Saved: %s\n",   file.path(TABLES, "advance_grade_prevalence.csv")))
cat(sprintf("Saved: %s\n",   file.path(TABLES, "advance_grade_prevalence_by_wave.csv")))
