# ================================================================
# 04d-no-eD-regressions.R  (v4b)
#
# Refit §5 outcomes (Adopters, A, B, C) for each Q ∈ {5,6,7,8}
# WITHOUT the E_D predictor in the model, to assess whether dropping
# the contested disadoption-specific peer-pressure term sharpens
# inference on the remaining 12 predictors.
#
# Outputs (OR-formatted, in line with §5/§6 tables):
#   outputs/tables/v4b_table_no_eD_Q<Q>.csv
#
# Persists the fits in:
#   outputs/intermediate/v4b_results_no_eD.rds
# ================================================================
suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
})
source(file.path(here::here(), "R", "00-config.R"))

PRED_NO_ED <- c("cohort", "female", "sex_minority", "par_edu",
                "asian", "hispanic", "mdd", "gad",
                "out_degree", "in_degree",
                "friends_use_ecig_lag", "E_users")
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
  E_users              = "Network Exposure Users"
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
                     control = lme4::glmerControl(optimizer = "bobyqa",
                                                   optCtrl = list(maxfun = 4e5)))
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

prep_data <- function(p, drop_cohort = FALSE) {
  d <- p
  d$cohort <- as.integer(d$cohort == "2025")
  if (drop_cohort) d$cohort <- NULL
  d
}
run_one <- function(panel_obj, outcome, Q) {
  d <- prep_data(panel_obj, drop_cohort = (Q == 8))
  pred_used <- if (Q == 8) setdiff(PRED_NO_ED, "cohort") else PRED_NO_ED
  rhs <- paste(c("wave_fe", pred_used), collapse = " + ")
  if (outcome == "C") {
    f <- as.formula(sprintf("event ~ %s + (1 | record_id)", rhs))
    tryCatch(fit_glmer_id(f, d), error = function(e) {
      cat("    GLMER error: ", conditionMessage(e), "\n"); NULL })
  } else {
    f <- as.formula(sprintf("event ~ %s", rhs))
    tryCatch(fit_glm(f, d), error = function(e) {
      cat("    GLM error: ", conditionMessage(e), "\n"); NULL })
  }
}

build_table_4 <- function(results, Q) {
  cols <- c("Adopters", "A", "B", "C"); rows <- list()
  for (var in PRED_NO_ED) {
    cells <- character(4); names(cells) <- cols
    for (col in cols) {
      r <- results[[col]]; if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var); cells[col] <- fmt_OR_p(bp[1], bp[2])
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

load_panel <- function(kind, Q, mode = "main") {
  readRDS(file.path(INTERMEDIATE,
    sprintf("v4b_panel_%s_Q%d_%s_full.rds", kind, Q, mode)))
}

all_results <- list()
for (Q in c(5, 6, 7, 8)) {
  cat(sprintf("\n========== Q = %d (no E_D) ==========\n", Q))
  s <- list(
    Adopters = run_one(load_panel("adopt", Q), "adopt", Q),
    A        = run_one(load_panel("A",     Q), "A",     Q),
    B        = run_one(load_panel("B",     Q), "B",     Q),
    C        = run_one(load_panel("C",     Q), "C",     Q))
  for (col in names(s)) {
    r <- s[[col]]
    if (!is.null(r))
      cat(sprintf("  %-9s n=%5d  ev=%4d  n_id=%5d\n",
                  col, r$n, r$events, r$n_id))
  }
  all_results[[as.character(Q)]] <- s
  tab <- build_table_4(s, Q)
  out_csv <- file.path(TABLES, sprintf("v4b_table_no_eD_Q%d.csv", Q))
  write.csv(tab, out_csv, row.names = FALSE)
  cat(sprintf("  wrote %s\n", out_csv))
}
saveRDS(all_results, file.path(INTERMEDIATE, "v4b_results_no_eD.rds"))
cat("\nDone.\n")
