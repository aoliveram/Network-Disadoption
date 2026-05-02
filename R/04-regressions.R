# ================================================================
# 04-regressions.R  (v4)
#
# Per Q in {5,6,7,8} fit four logistic event-history regressions
# (Adopters, A-Stable, B-Experimental, C-Unstable) with the same
# 15-predictor set, plus wave fixed effect.
#
# Adopters / A / B : GLM logistic, cluster-robust SE by record_id.
# C                : glmer((1|record_id)) for recurrent events.
#                    Reports rho = ICC = sigma_u^2 / (sigma_u^2 + pi^2/3).
#
# Output: a 17-row x 4-column table per Q (coef + p-value per cell),
# saved as outputs/tables/v4_regression_table_Q{Q}.csv plus the raw
# fit objects in outputs/intermediate/v4_results.rds.
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
})

source(file.path(here::here(), "R", "00-config.R"))

# Predictors used in every regression.
# NOTE on ESE: `ese_ecig_pos_no9_mean` and `ese_ecig_neg_no510_mean` are
# only filled in waves where the student reports e-cig use (and even
# then ~40% complete). Including them here would force complete-case
# dropping that biases the sample toward users. We DROP ESE from the
# main v4 battery and document it as a sensitivity item for a future
# iteration.
PRED <- c("cohort", "female", "sex_minority", "par_edu",
          "asian", "hispanic",
          "mdd", "gad",
          "out_degree", "in_degree",
          "friends_use_ecig_lag",
          "E_users", "E_dis")

# Pretty names for the table.
PRED_LABEL <- c(
  cohort               = "Cohort (2025 vs 2024)",
  female               = "Female",
  sex_minority         = "Sexual Minority",
  par_edu              = "Parent Ed.",
  asian                = "Asian",
  hispanic             = "Hispanic/Latine",
  mdd                  = "MDD (RCADS Mean)",
  gad                  = "GAD (RCADS Mean)",
  out_degree           = "Out-degree",
  in_degree            = "In-degree",
  friends_use_ecig_lag = "Perceived Friend Use",
  E_users              = "Network Exposure Users",
  E_dis                = "Network Exposure Dis-adopters"
)

fmt_cell <- function(beta, p) {
  if (is.na(beta) || is.na(p)) return("—")
  sprintf("%.3f (%.3f)", beta, p)
}

# Fit GLM with cluster-robust SE; return tidy coef table.
fit_glm <- function(formula, data) {
  d <- data
  d$wave_fe <- factor(d$wave)
  # Pre-filter to complete cases on outcome + predictors so we can
  # compute n_id correctly; GLM will agree with this filtering.
  vars <- all.vars(formula)
  d_cc <- d[complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), ]
  fit <- glm(formula, data = d_cc, family = binomial("logit"))
  vc  <- tryCatch(sandwich::vcovCL(fit, cluster = d_cc$record_id, type = "HC0"),
                  error = function(e) sandwich::vcovHC(fit, type = "HC0"))
  ct  <- lmtest::coeftest(fit, vcov. = vc)
  list(fit = fit, ct = ct,
       n  = nrow(fit$model),
       events = sum(fit$model[[1]]),
       n_id = length(unique(d_cc$record_id)))
}

# Fit GLMER with (1|record_id); return tidy coef table.
fit_glmer_id <- function(formula, data) {
  d <- data
  d$wave_fe <- factor(d$wave)
  vars <- all.vars(formula)
  d_cc <- d[complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), ]
  fit <- lme4::glmer(formula, data = d_cc, family = binomial("logit"),
                     control = lme4::glmerControl(
                       optimizer = "bobyqa",
                       optCtrl   = list(maxfun = 4e5)))
  ss <- summary(fit)
  ct <- ss$coefficients
  vc <- lme4::VarCorr(fit)
  sigma2_u <- as.numeric(vc[[1]][1, 1])
  rho <- sigma2_u / (sigma2_u + (pi^2)/3)
  list(fit = fit, ct = ct,
       n = nobs(fit),
       events = sum(model.frame(fit)[[1]]),
       n_id = length(unique(d_cc$record_id)),
       sigma2_u = sigma2_u, rho = rho)
}

# Pull beta + p for a term (or return NA if missing).
get_bp <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(NA, NA))
  z <- ct[term, ]
  c(unname(z["Estimate"]),
    unname(z[grep("^Pr", names(z))]))
}

# Build the regression formula
make_formula <- function(outcome, with_re = FALSE) {
  rhs <- paste(c("wave_fe", PRED), collapse = " + ")
  if (with_re) rhs <- paste(rhs, "+ (1 | record_id)")
  as.formula(sprintf("%s ~ %s", outcome, rhs))
}

# Cohort handling: if a Q sample has only one cohort, drop cohort.
prep_data <- function(p, drop_cohort = FALSE) {
  d <- p
  d$cohort <- as.integer(d$cohort == "2025")  # 0=2024, 1=2025
  if (drop_cohort) d$cohort <- NULL
  d
}

run_one_Q <- function(Q) {
  cat(sprintf("\n========== Q = %d ==========\n", Q))
  files <- list(
    Adopters = sprintf("v4_panel_adopt_Q%d_full.rds", Q),
    A        = sprintf("v4_panel_A_Q%d_full.rds",     Q),
    B        = sprintf("v4_panel_B_Q%d_full.rds",     Q),
    C        = sprintf("v4_panel_C_Q%d_full.rds",     Q)
  )
  results <- list()
  drop_cohort <- (Q == 8)  # Q=8 has only schools 101-105 -> only cohort 2024
  for (col in names(files)) {
    p <- readRDS(file.path(INTERMEDIATE, files[[col]]))
    d <- prep_data(p, drop_cohort = drop_cohort)
    pred_used <- PRED
    if (drop_cohort) pred_used <- setdiff(pred_used, "cohort")
    rhs <- paste(c("wave_fe", pred_used), collapse = " + ")
    cat(sprintf("  Fitting %s : n=%d events=%d\n",
                col, nrow(d), sum(d$event)))
    if (col == "C") {
      f <- as.formula(sprintf("event ~ %s + (1 | record_id)", rhs))
      r <- tryCatch(fit_glmer_id(f, d), error = function(e) {
        cat("    GLMER error:", conditionMessage(e), "\n"); NULL })
    } else {
      f <- as.formula(sprintf("event ~ %s", rhs))
      r <- tryCatch(fit_glm(f, d), error = function(e) {
        cat("    GLM error:", conditionMessage(e), "\n"); NULL })
    }
    results[[col]] <- r
  }
  results
}

# ----------------------------------------------------------------
# Run all four Q levels
# ----------------------------------------------------------------
all_results <- list()
for (Q in c(5, 6, 7, 8)) {
  all_results[[as.character(Q)]] <- run_one_Q(Q)
}
saveRDS(all_results, file.path(INTERMEDIATE, "v4_results.rds"))

# ----------------------------------------------------------------
# Build the per-Q table: 17 rows x 4 cols (coef (p-value) per cell)
# Rows: 15 predictors + Rho + N students + N events
# ----------------------------------------------------------------
build_table <- function(res, Q) {
  cols <- c("Adopters", "A", "B", "C")
  # Predictor rows
  rows <- list()
  for (var in PRED) {
    cells <- character(4); names(cells) <- cols
    for (col in cols) {
      r <- res[[col]]
      if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var)
      cells[col] <- fmt_cell(bp[1], bp[2])
    }
    rows[[PRED_LABEL[var]]] <- cells
  }
  # Rho row
  rho_cells <- c("—", "—", "—", "—"); names(rho_cells) <- cols
  if (!is.null(res$C)) rho_cells["C"] <- sprintf("%.3f", res$C$rho)
  rows[["Rho (ICC)"]] <- rho_cells
  # N students
  n_cells <- character(4); names(n_cells) <- cols
  for (col in cols) {
    r <- res[[col]]
    if (is.null(r)) { n_cells[col] <- "—" } else {
      n_cells[col] <- as.character(r$n_id)
    }
  }
  rows[["N Students"]] <- n_cells
  # N events
  e_cells <- character(4); names(e_cells) <- cols
  for (col in cols) {
    r <- res[[col]]
    if (is.null(r)) { e_cells[col] <- "—" } else {
      e_cells[col] <- as.character(r$events)
    }
  }
  rows[["N Events"]] <- e_cells

  # Assemble into a data.frame
  tab <- do.call(rbind, lapply(rows, function(r) data.frame(
    Adopters = r["Adopters"], A = r["A"], B = r["B"], C = r["C"],
    stringsAsFactors = FALSE)))
  tab <- cbind(Variable = names(rows), tab)
  rownames(tab) <- NULL
  tab
}

for (Q in c(5, 6, 7, 8)) {
  tab <- build_table(all_results[[as.character(Q)]], Q)
  out_csv <- file.path(TABLES, sprintf("v4_regression_table_Q%d.csv", Q))
  write.csv(tab, out_csv, row.names = FALSE)
  cat(sprintf("\n=== Q = %d ===\n", Q))
  print(tab, row.names = FALSE)
  cat(sprintf("Saved: %s\n", out_csv))
}
