# ================================================================
# playground/05-grade-semester-fe.R   (PROVISIONAL — not committed
# results to v4b; this only diagnoses the spec change for v5)
#
# Replace `wave_fe (10 levels = 9 dummies)` with `gs_fe (8 levels =
# 7 dummies)` while KEEPING the cohort dummy. Refit §5 (E_dis), §6
# (E_alt), and §7 (no E_D) at all four Q levels and compare with
# the v4b reported ORs.
#
# We also extract and print the gs_fe coefficient block so we can
# see whether grade-semester carries a meaningful effect that wave
# FE was hiding.
# ================================================================
suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
  library(dplyr)
})
source(file.path(here::here(), "R", "00-config.R"))

PRED_FULL  <- c("cohort", "female", "sex_minority", "par_edu",
                "asian", "hispanic", "mdd", "gad",
                "out_degree", "in_degree",
                "friends_use_ecig_lag", "E_users", "E_D")
PRED_NO_ED <- setdiff(PRED_FULL, "E_D")
PRED_LABEL <- c(
  cohort               = "Cohort (2025 vs 2024)",
  female               = "Female",
  sex_minority         = "Sexual Minority",
  par_edu              = "Parent Ed.",
  asian                = "Asian",
  hispanic             = "Hispanic/Latine",
  mdd                  = "MDD (Major Depressive S.)",
  gad                  = "GAD (Generalized Anxiety Dis.)",
  out_degree           = "Out-degree",
  in_degree            = "In-degree",
  friends_use_ecig_lag = "Perceived Friend Use",
  E_users              = "Network Exposure Users",
  E_D                  = "Network Exposure Dis-adopters"
)

fmt_OR_p <- function(beta, p) {
  if (is.na(beta) || is.na(p)) return("—")
  sprintf("%.3f (%.3f)", exp(beta), p)
}
get_bp <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(NA, NA))
  z <- ct[term, ]
  c(unname(z["Estimate"]),
    unname(z[grep("^Pr", names(z))]))
}

# Map (cohort, wave) -> grade-semester (1..8) ; W9-W10 for cohort
# 2024 are post-HS (NA -> dropped from these regressions).
attach_gs <- function(d) {
  gs_2024 <- c(`1`=1L,`2`=2L,`3`=3L,`4`=4L,`5`=5L,`6`=6L,`7`=7L,`8`=8L,
               `9`=NA_integer_,`10`=NA_integer_)
  gs_2025 <- c(`3`=1L,`4`=2L,`5`=3L,`6`=4L,`7`=5L,`8`=6L,`9`=7L,`10`=8L)
  d$gs <- NA_integer_
  i24 <- !is.na(d$cohort) & d$cohort == "2024"
  i25 <- !is.na(d$cohort) & d$cohort == "2025"
  d$gs[i24] <- as.integer(gs_2024[as.character(d$wave[i24])])
  d$gs[i25] <- as.integer(gs_2025[as.character(d$wave[i25])])
  d
}

prep_data <- function(p, E_D_var) {
  d <- p
  d <- attach_gs(d)                              # use string cohort first
  d$cohort <- as.integer(d$cohort == "2025")     # then convert
  if (E_D_var == "E_dis")    d$E_D <- d$E_dis
  else if (E_D_var == "E_D_alt") d$E_D <- d$E_D_alt
  d
}

fit_glm <- function(formula, data) {
  d <- data; d$gs_fe <- factor(d$gs)
  vars <- all.vars(formula)
  d_cc <- d[complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), ]
  d_cc <- d_cc[!is.na(d_cc$gs), ]    # drop post-HS rows (gs = NA)
  if (nrow(d_cc) < 10) return(NULL)
  fit <- glm(formula, data = d_cc, family = binomial("logit"))
  vc  <- tryCatch(sandwich::vcovCL(fit, cluster = d_cc$record_id, type = "HC0"),
                  error = function(e) sandwich::vcovHC(fit, type = "HC0"))
  ct  <- lmtest::coeftest(fit, vcov. = vc)
  list(fit = fit, ct = ct,
       n  = nrow(fit$model),
       events = sum(fit$model[[1]]),
       n_id = length(unique(d_cc$record_id)))
}
fit_glmer_id <- function(formula, data) {
  d <- data; d$gs_fe <- factor(d$gs)
  vars <- all.vars(formula)
  d_cc <- d[complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), ]
  d_cc <- d_cc[!is.na(d_cc$gs), ]
  if (nrow(d_cc) < 10) return(NULL)
  fit <- lme4::glmer(formula, data = d_cc, family = binomial("logit"),
                     control = lme4::glmerControl(optimizer = "bobyqa",
                                                   optCtrl = list(maxfun = 4e5)))
  ct <- summary(fit)$coefficients
  vc <- lme4::VarCorr(fit)
  s2 <- as.numeric(vc[[1]][1, 1])
  list(fit = fit, ct = ct,
       n = nobs(fit),
       events = sum(model.frame(fit)[[1]]),
       n_id = length(unique(d_cc$record_id)),
       rho = s2 / (s2 + (pi^2)/3))
}

run_one <- function(panel_obj, outcome, E_D_var, pred_set) {
  d   <- prep_data(panel_obj, E_D_var = E_D_var)
  rhs <- paste(c("gs_fe", pred_set), collapse = " + ")
  if (outcome == "C") {
    f <- as.formula(sprintf("event ~ %s + (1 | record_id)", rhs))
    tryCatch(fit_glmer_id(f, d), error = function(e) {
      cat("    GLMER err:", conditionMessage(e), "\n"); NULL })
  } else {
    f <- as.formula(sprintf("event ~ %s", rhs))
    tryCatch(fit_glm(f, d), error = function(e) {
      cat("    GLM err:", conditionMessage(e), "\n"); NULL })
  }
}

load_panel <- function(kind, Q, mode = "main") {
  readRDS(file.path(INTERMEDIATE,
    sprintf("v4b_panel_%s_Q%d_%s_full.rds", kind, Q, mode)))
}

# ----------------------------------------------------------------
# Run §5 / §6 / §7 with gs_fe + cohort across 4 Q levels
# ----------------------------------------------------------------
families <- list(
  "§5 main (E_dis)"  = list(E = "E_dis",    pred = PRED_FULL),
  "§6 alt  (E_alt)"  = list(E = "E_D_alt",  pred = PRED_FULL),
  "§7 no   E_D"      = list(E = "E_dis",    pred = PRED_NO_ED)
)

results <- list()
for (Q in c(5, 6, 7, 8)) {
  for (fam in names(families)) {
    cfg <- families[[fam]]
    cat(sprintf("\n==== %s  Q=%d ====\n", fam, Q))
    s <- list(
      Adopters = run_one(load_panel("adopt", Q), "adopt", cfg$E, cfg$pred),
      A        = run_one(load_panel("A",     Q), "A",     cfg$E, cfg$pred),
      B        = run_one(load_panel("B",     Q), "B",     cfg$E, cfg$pred),
      C        = run_one(load_panel("C",     Q), "C",     cfg$E, cfg$pred))
    for (col in names(s)) {
      r <- s[[col]]
      if (is.null(r)) { cat(sprintf("  %-9s [NULL]\n", col)); next }
      cat(sprintf("  %-9s n=%5d  ev=%4d  n_id=%5d\n",
                  col, r$n, r$events, r$n_id))
    }
    results[[paste(fam, Q, sep = "::")]] <- s
  }
}
saveRDS(results, file.path("playground", "v5_grade_semester_fits.rds"))

# ----------------------------------------------------------------
# Comparison table builder
# ----------------------------------------------------------------
load_v4b_csv <- function(sec, Q) {
  read.csv(file.path(TABLES, sprintf("v4b_table_%s_Q%d.csv", sec, Q)),
           stringsAsFactors = FALSE, check.names = FALSE)
}

emit_block <- function(label, sec_csv_id, Q, fits, pred_set) {
  v4b <- load_v4b_csv(sec_csv_id, Q)
  cat(sprintf("\n## %s — Q=%d  (v4b=wave_fe+cohort  vs  v5=gs_fe+cohort)\n\n", label, Q))
  cat("| Variable | v4b: Adopt | v5: Adopt | v4b: A | v5: A | v4b: B | v5: B | v4b: C | v5: C |\n")
  cat("|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|\n")
  for (var in pred_set) {
    cells <- character(8)
    label_var <- PRED_LABEL[[var]]
    j <- 1
    for (col_v4 in c("Adopters","A","B","C")) {
      v4b_cell <- v4b[v4b$Variable == label_var, col_v4]
      cells[j] <- if (length(v4b_cell)) as.character(v4b_cell) else "—"; j <- j + 1
      r <- fits[[col_v4]]
      if (is.null(r)) { cells[j] <- "—"; j <- j + 1; next }
      bp <- get_bp(r$ct, var)
      cells[j] <- fmt_OR_p(bp[1], bp[2]); j <- j + 1
    }
    cat(sprintf("| %s | %s |\n", label_var,
                paste(cells, collapse = " | ")))
  }
  # gs_fe block (v5 only)
  cat(sprintf("\n   gs_fe (v5) coefficients in column A:\n"))
  rA <- fits[["A"]]
  if (!is.null(rA)) {
    nm <- rownames(rA$ct)
    gs_terms <- nm[grepl("^gs_fe", nm)]
    for (g in gs_terms) {
      bp <- get_bp(rA$ct, g)
      cat(sprintf("     %s : %s\n", g, fmt_OR_p(bp[1], bp[2])))
    }
  }
  cat("\n")
}

sink(file.path("playground", "v5_grade_semester_compare.md"))
cat("# v4b vs v5 (grade-semester FE) — provisional comparison\n\n")
cat("Cells: OR (p). v4b uses `wave_fe + cohort`; v5 uses `gs_fe + cohort`.\n")
cat("Q-eligible students drop slightly in v5 because gs=NA (post-HS at W9/W10\n")
cat("for cohort 2024) is removed.\n\n")
for (Q in c(8, 7, 6, 5)) {
  for (fam in names(families)) {
    cfg <- families[[fam]]
    sec_csv_id <- switch(fam,
                         "§5 main (E_dis)" = "5",
                         "§6 alt  (E_alt)" = "6",
                         "§7 no   E_D"     = "no_eD")
    fits <- results[[paste(fam, Q, sep = "::")]]
    emit_block(fam, sec_csv_id, Q, fits, cfg$pred)
  }
}
sink()
cat("\nWrote playground/v5_grade_semester_compare.md\n")
