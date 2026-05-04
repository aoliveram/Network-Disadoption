# ================================================================
# 04-regressions.R  (v4b)
#
# Five regression families per Q ∈ {5,6,7,8} = 20 tables total.
#
# §5 Main         : panels=main      , E_D=E_dis,    C window=1, 4 outcomes
# §6 Alt E_D      : panels=main      , E_D=E_D_alt,  C window=1, 4 outcomes
# §7 Window sens. : panels=main+Cw2+Cw3, E_D=E_dis, C only (3 W cols)
# §8 (a) sensit.  : panels=A_with_indet for A; main for the rest
# §9 (b) sensit.  : panels=obs_jumps , E_D=E_dis, C window=1, 4 outcomes
#
# Estimator:
#   adopt / A / B  : GLM logistic, wave FE, cluster-robust SE by record_id
#   C              : lme4::glmer((1 | record_id)), wave FE, report ICC
#
# Outputs (per Q):
#   outputs/tables/v4b_table_5_Q<Q>.csv
#   outputs/tables/v4b_table_6_Q<Q>.csv
#   outputs/tables/v4b_table_7_Q<Q>.csv  (3 cols: C_W1, C_W2, C_W3)
#   outputs/tables/v4b_table_8_Q<Q>.csv
#   outputs/tables/v4b_table_9_Q<Q>.csv
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
})

source(file.path(here::here(), "R", "00-config.R"))

PRED <- c("cohort", "female", "sex_minority", "par_edu",
          "asian", "hispanic",
          "mdd", "gad",
          "out_degree", "in_degree",
          "friends_use_ecig_lag",
          "E_users", "E_D")  # E_D is mapped to E_dis or E_D_alt later
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
  E_D                  = "Network Exposure Dis-adopters"
)

fmt_cell <- function(beta, p) {
  if (is.na(beta) || is.na(p)) return("—")
  sprintf("%.3f (%.3f)", beta, p)
}

# ----------------------------------------------------------------
# Fitters
# ----------------------------------------------------------------
fit_glm <- function(formula, data) {
  d <- data; d$wave_fe <- factor(d$wave)
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
fit_glmer_id <- function(formula, data) {
  d <- data; d$wave_fe <- factor(d$wave)
  vars <- all.vars(formula)
  d_cc <- d[complete.cases(d[, intersect(vars, names(d)), drop = FALSE]), ]
  fit <- lme4::glmer(formula, data = d_cc, family = binomial("logit"),
                     control = lme4::glmerControl(
                       optimizer = "bobyqa",
                       optCtrl   = list(maxfun = 4e5)))
  ct <- summary(fit)$coefficients
  vc <- lme4::VarCorr(fit)
  sigma2_u <- as.numeric(vc[[1]][1, 1])
  rho <- sigma2_u / (sigma2_u + (pi^2)/3)
  list(fit = fit, ct = ct,
       n = nobs(fit),
       events = sum(model.frame(fit)[[1]]),
       n_id = length(unique(d_cc$record_id)),
       sigma2_u = sigma2_u, rho = rho)
}
get_bp <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(NA, NA))
  z <- ct[term, ]
  c(unname(z["Estimate"]),
    unname(z[grep("^Pr", names(z))]))
}

# ----------------------------------------------------------------
# Helper to build a regression on a panel given E_D variant
# ----------------------------------------------------------------
prep_data <- function(p, E_D_var, drop_cohort = FALSE) {
  d <- p
  d$cohort <- as.integer(d$cohort == "2025")  # 0=2024, 1=2025
  if (drop_cohort) d$cohort <- NULL
  # Map E_D variant to a unified column "E_D"
  if (E_D_var == "E_dis") {
    d$E_D <- d$E_dis
  } else if (E_D_var == "E_D_alt") {
    d$E_D <- d$E_D_alt
  } else stop("Unknown E_D_var: ", E_D_var)
  d
}

run_one <- function(panel_obj, outcome, E_D_var, Q) {
  d <- prep_data(panel_obj, E_D_var = E_D_var, drop_cohort = (Q == 8))
  pred_used <- if (Q == 8) setdiff(PRED, "cohort") else PRED
  rhs <- paste(c("wave_fe", pred_used), collapse = " + ")
  if (outcome == "C") {
    f <- as.formula(sprintf("event ~ %s + (1 | record_id)", rhs))
    r <- tryCatch(fit_glmer_id(f, d), error = function(e) {
      cat(sprintf("    GLMER error: %s\n", conditionMessage(e))); NULL })
  } else {
    f <- as.formula(sprintf("event ~ %s", rhs))
    r <- tryCatch(fit_glm(f, d), error = function(e) {
      cat(sprintf("    GLM error: %s\n", conditionMessage(e))); NULL })
  }
  r
}

# ----------------------------------------------------------------
# Build a 4-outcome table (cols: Adopt, A, B, C)
# ----------------------------------------------------------------
build_table_4 <- function(results, Q) {
  cols <- c("Adopters", "A", "B", "C"); rows <- list()
  for (var in PRED) {
    cells <- character(4); names(cells) <- cols
    for (col in cols) {
      r <- results[[col]]; if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var); cells[col] <- fmt_cell(bp[1], bp[2])
    }
    rows[[PRED_LABEL[var]]] <- cells
  }
  rho_cells <- c("—","—","—","—"); names(rho_cells) <- cols
  if (!is.null(results$C)) rho_cells["C"] <- sprintf("%.3f", results$C$rho)
  rows[["Rho (ICC)"]] <- rho_cells
  n_cells <- e_cells <- character(4); names(n_cells) <- names(e_cells) <- cols
  for (col in cols) {
    r <- results[[col]]
    n_cells[col] <- if (is.null(r)) "—" else as.character(r$n_id)
    e_cells[col] <- if (is.null(r)) "—" else as.character(r$events)
  }
  rows[["N Students"]] <- n_cells
  rows[["N Events"]]   <- e_cells
  tab <- do.call(rbind, lapply(rows, function(r) data.frame(
    Adopters = r["Adopters"], A = r["A"], B = r["B"], C = r["C"],
    stringsAsFactors = FALSE)))
  tab <- cbind(Variable = names(rows), tab); rownames(tab) <- NULL
  tab
}

# ----------------------------------------------------------------
# §7 — only-C window-sensitivity table (3 cols: C_W1, C_W2, C_W3)
# ----------------------------------------------------------------
build_table_7 <- function(C_W1, C_W2, C_W3) {
  cols <- c("C_W1", "C_W2", "C_W3"); rows <- list()
  fits <- list(C_W1 = C_W1, C_W2 = C_W2, C_W3 = C_W3)
  for (var in PRED) {
    cells <- character(3); names(cells) <- cols
    for (col in cols) {
      r <- fits[[col]]; if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var); cells[col] <- fmt_cell(bp[1], bp[2])
    }
    rows[[PRED_LABEL[var]]] <- cells
  }
  rho_cells <- character(3); names(rho_cells) <- cols
  for (col in cols) {
    r <- fits[[col]]; rho_cells[col] <- if (is.null(r)) "—" else sprintf("%.3f", r$rho)
  }
  rows[["Rho (ICC)"]] <- rho_cells
  n_cells <- e_cells <- character(3); names(n_cells) <- names(e_cells) <- cols
  for (col in cols) {
    r <- fits[[col]]
    n_cells[col] <- if (is.null(r)) "—" else as.character(r$n_id)
    e_cells[col] <- if (is.null(r)) "—" else as.character(r$events)
  }
  rows[["N Students"]] <- n_cells
  rows[["N Events"]]   <- e_cells
  tab <- do.call(rbind, lapply(rows, function(r) data.frame(
    C_W1 = r["C_W1"], C_W2 = r["C_W2"], C_W3 = r["C_W3"],
    stringsAsFactors = FALSE)))
  tab <- cbind(Variable = names(rows), tab); rownames(tab) <- NULL
  tab
}

# ----------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------
load_panel <- function(kind, Q, mode) {
  f <- file.path(INTERMEDIATE,
                 sprintf("v4b_panel_%s_Q%d_%s_full.rds", kind, Q, mode))
  readRDS(f)
}

all_results <- list()
for (Q in c(5, 6, 7, 8)) {
  cat(sprintf("\n========== Q = %d ==========\n", Q))
  Q_results <- list()

  # §5 Main (mode=main, E_D=E_dis)
  cat("  §5 main...\n")
  s5 <- list(
    Adopters = run_one(load_panel("adopt", Q, "main"), "adopt", "E_dis", Q),
    A        = run_one(load_panel("A",     Q, "main"), "A",     "E_dis", Q),
    B        = run_one(load_panel("B",     Q, "main"), "B",     "E_dis", Q),
    C        = run_one(load_panel("C",     Q, "main"), "C",     "E_dis", Q))
  Q_results[["s5"]] <- s5

  # §6 Alt E_D (mode=main, E_D=E_D_alt)
  cat("  §6 alt E_D...\n")
  s6 <- list(
    Adopters = run_one(load_panel("adopt", Q, "main"), "adopt", "E_D_alt", Q),
    A        = run_one(load_panel("A",     Q, "main"), "A",     "E_D_alt", Q),
    B        = run_one(load_panel("B",     Q, "main"), "B",     "E_D_alt", Q),
    C        = run_one(load_panel("C",     Q, "main"), "C",     "E_D_alt", Q))
  Q_results[["s6"]] <- s6

  # §7 Window sensitivity (only C, 3 windows)
  cat("  §7 window sensitivity...\n")
  s7 <- list(
    C_W1 = run_one(load_panel("C", Q, "main"), "C", "E_dis", Q),
    C_W2 = run_one(load_panel("C", Q, "Cw2"),  "C", "E_dis", Q),
    C_W3 = run_one(load_panel("C", Q, "Cw3"),  "C", "E_dis", Q))
  Q_results[["s7"]] <- s7

  # §8 (a) sensitivity: only A panel changes (uses A_with_indet); rest = §5
  cat("  §8 (a) indet -> A...\n")
  s8 <- list(
    Adopters = s5$Adopters,
    A        = run_one(load_panel("A", Q, "A_with_indet"), "A", "E_dis", Q),
    B        = s5$B,
    C        = s5$C)
  Q_results[["s8"]] <- s8

  # §9 (b) sensitivity: observed-jumps mode for all four
  cat("  §9 (b) observed jumps...\n")
  s9 <- list(
    Adopters = run_one(load_panel("adopt", Q, "obs_jumps"), "adopt", "E_dis", Q),
    A        = run_one(load_panel("A",     Q, "obs_jumps"), "A",     "E_dis", Q),
    B        = run_one(load_panel("B",     Q, "obs_jumps"), "B",     "E_dis", Q),
    C        = run_one(load_panel("C",     Q, "obs_jumps"), "C",     "E_dis", Q))
  Q_results[["s9"]] <- s9

  all_results[[as.character(Q)]] <- Q_results

  # Build + save tables
  tab5 <- build_table_4(s5, Q)
  tab6 <- build_table_4(s6, Q)
  tab7 <- build_table_7(s7$C_W1, s7$C_W2, s7$C_W3)
  tab8 <- build_table_4(s8, Q)
  tab9 <- build_table_4(s9, Q)
  for (sec in 5:9) {
    tab <- get(sprintf("tab%d", sec))
    out_csv <- file.path(TABLES, sprintf("v4b_table_%d_Q%d.csv", sec, Q))
    write.csv(tab, out_csv, row.names = FALSE)
  }
  cat(sprintf("\nQ=%d: 5 tables saved (sec 5..9)\n", Q))
}

saveRDS(all_results, file.path(INTERMEDIATE, "v4b_results.rds"))
cat("\nDone. Saved v4b_results.rds and 20 CSVs.\n")
