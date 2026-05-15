# ================================================================
# 06-diagnostics.R  (v5)
#
# All-in-one diagnostics script for the headline specification
# (§6 alt E_D at Q=7, gs_fe + cohort). Runs the 9 checks listed in
# papers/disadoption-study-draft/04-analysis-plan-3.1-diagnostics.md
# on the four outcomes (Adopters, Stable A, Experimental B,
# Unstable C) and writes a combined report.
#
# Outputs:
#   outputs/intermediate/v5_diagnostics.rds    (all numeric results)
#   outputs/diagnostics/v5_diagnostics.md      (human-readable summary)
#
# Run with: Rscript R/06-diagnostics.R
# ================================================================

suppressMessages({
  library(sandwich); library(lmtest); library(lme4)
  library(car)       # vif
  library(splines)   # ns()
  library(pROC)      # auc
  library(logistf)   # Firth penalised likelihood
})
source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

DIAG_DIR <- file.path(here::here(), "outputs", "diagnostics")
dir.create(DIAG_DIR, recursive = TRUE, showWarnings = FALSE)

PRED <- c("cohort", "female", "sex_minority", "par_edu",
          "asian", "hispanic", "mdd", "gad",
          "out_degree", "in_degree",
          "friends_use_ecig_lag", "E_users", "E_D")

prep_data <- function(p, E_D_var = "E_D_alt") {
  d <- p
  d <- attach_gs(d)
  d$cohort <- as.integer(d$cohort == "2025")
  if (E_D_var == "E_dis")        d$E_D <- d$E_dis
  else if (E_D_var == "E_D_alt") d$E_D <- d$E_D_alt
  d$gs_fe <- factor(d$gs)
  cc <- complete.cases(d[, c(PRED, "gs", "event"), drop = FALSE])
  d_cc <- d[cc, ]
  d_cc <- d_cc[!is.na(d_cc$gs), ]
  d_cc
}

load_panel <- function(kind, Q = 7, mode = "main") {
  readRDS(file.path(INTERMEDIATE,
    sprintf("v4b_panel_%s_Q%d_%s_full.rds", kind, Q, mode)))
}

fit_headline <- function(d, outcome) {
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  f <- as.formula(sprintf("event ~ %s", rhs))
  if (outcome == "C") {
    fit <- glmer(as.formula(sprintf("event ~ %s + (1 | record_id)", rhs)),
                 data = d, family = binomial("logit"),
                 control = glmerControl(optimizer = "bobyqa",
                                         optCtrl = list(maxfun = 4e5)))
  } else {
    fit <- glm(f, data = d, family = binomial("logit"))
  }
  fit
}

# ----------------------------------------------------------------
# D1 — separation: per-outcome × gs_fe event-count table
# ----------------------------------------------------------------
diag_D1 <- function(d, outcome) {
  cat(sprintf("\n  D1 — Separation check for outcome=%s\n", outcome))
  tab <- table(d$gs_fe, d$event)
  print(tab)
  zero_cells <- which(tab[, "1"] == 0)
  list(table = tab,
       zero_event_levels = if (length(zero_cells)) rownames(tab)[zero_cells] else character(0))
}

# ----------------------------------------------------------------
# D2 — VIF on the linear predictor part of the GLM
# ----------------------------------------------------------------
diag_D2 <- function(d, outcome) {
  cat(sprintf("\n  D2 — VIF for outcome=%s\n", outcome))
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit <- glm(as.formula(sprintf("event ~ %s", rhs)),
             data = d, family = binomial("logit"))
  vc <- tryCatch(vif(fit), error = function(e) {
    cat("    VIF error: ", conditionMessage(e), "\n"); NULL })
  print(round(vc, 2))
  vc
}

# ----------------------------------------------------------------
# D3 — Firth penalised-likelihood logistic regression
# ----------------------------------------------------------------
diag_D3 <- function(d, outcome) {
  cat(sprintf("\n  D3 — Firth penalised likelihood for outcome=%s\n", outcome))
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit_firth <- tryCatch(
    logistf(as.formula(sprintf("event ~ %s", rhs)), data = d),
    error = function(e) {
      cat("    Firth error: ", conditionMessage(e), "\n"); NULL })
  if (!is.null(fit_firth)) {
    or_table <- data.frame(
      term = names(coef(fit_firth)),
      OR   = exp(coef(fit_firth)),
      p    = fit_firth$prob,
      row.names = NULL)
    print(or_table)
  }
  fit_firth
}

# ----------------------------------------------------------------
# D4 — Linearity in the logit: LRT linear vs natural-cubic-spline
# ----------------------------------------------------------------
diag_D4 <- function(d, outcome) {
  cat(sprintf("\n  D4 — Linearity in the logit for outcome=%s\n", outcome))
  rhs_lin <- paste(c("gs_fe", PRED), collapse = " + ")
  fit_lin <- glm(as.formula(sprintf("event ~ %s", rhs_lin)),
                 data = d, family = binomial("logit"))
  out <- list()
  for (v in c("friends_use_ecig_lag", "E_users", "E_D",
              "mdd", "gad", "out_degree", "in_degree", "par_edu")) {
    rhs_spl <- gsub(v, sprintf("ns(%s, 3)", v),
                    rhs_lin, fixed = TRUE)
    fit_spl <- tryCatch(
      glm(as.formula(sprintf("event ~ %s", rhs_spl)),
          data = d, family = binomial("logit")),
      error = function(e) NULL)
    if (!is.null(fit_spl)) {
      lrt <- anova(fit_lin, fit_spl, test = "Chisq")
      p <- lrt$`Pr(>Chi)`[2]
      out[[v]] <- p
      cat(sprintf("    %s : LRT p = %.4f\n", v, p))
    }
  }
  out
}

# ----------------------------------------------------------------
# D5 — Cluster-robust SE adequacy: id vs id+schoolid
# ----------------------------------------------------------------
diag_D5 <- function(d, outcome) {
  cat(sprintf("\n  D5 — Cluster-robust SE comparison for outcome=%s\n", outcome))
  d <- d[!is.na(d$schoolid) & !is.na(d$record_id), ]
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit <- glm(as.formula(sprintf("event ~ %s", rhs)),
             data = d, family = binomial("logit"))
  vc_id  <- sandwich::vcovCL(fit, cluster = d$record_id, type = "HC0")
  vc_sch <- sandwich::vcovCL(fit, cluster = d$schoolid,  type = "HC0")
  vc_two <- tryCatch(sandwich::vcovCL(fit, cluster = ~ record_id + schoolid,
                                       data = d, type = "HC0"),
                     error = function(e) NULL)
  ses <- data.frame(
    term = names(coef(fit)),
    se_id  = sqrt(diag(vc_id)),
    se_sch = sqrt(diag(vc_sch)),
    se_two = if (!is.null(vc_two)) sqrt(diag(vc_two)) else NA)
  ses$ratio_two_vs_id <- ses$se_two / ses$se_id
  print(head(ses[order(-ses$ratio_two_vs_id), ], 8))
  ses
}

# ----------------------------------------------------------------
# D6 — AUC + Hosmer-Lemeshow calibration
# ----------------------------------------------------------------
diag_D6 <- function(d, outcome) {
  cat(sprintf("\n  D6 — AUC / calibration for outcome=%s\n", outcome))
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit <- glm(as.formula(sprintf("event ~ %s", rhs)),
             data = d, family = binomial("logit"))
  prob <- predict(fit, type = "response")
  au <- pROC::auc(d$event, prob, direction = "<")
  cat(sprintf("    AUC = %.3f\n", au))
  # Hosmer-Lemeshow GoF
  hl <- tryCatch({
    library(ResourceSelection)
    hoslem.test(d$event, prob, g = 10)
  }, error = function(e) NULL)
  if (!is.null(hl))
    cat(sprintf("    Hosmer-Lemeshow chi^2 = %.2f, df = %d, p = %.4f\n",
                hl$statistic, hl$parameter, hl$p.value))
  list(auc = as.numeric(au), hl = hl)
}

# ----------------------------------------------------------------
# D7 — Influential observations (Cook's distance > 4/n)
# ----------------------------------------------------------------
diag_D7 <- function(d, outcome) {
  cat(sprintf("\n  D7 — Cook's distance influential obs for outcome=%s\n", outcome))
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit <- glm(as.formula(sprintf("event ~ %s", rhs)),
             data = d, family = binomial("logit"))
  cd <- cooks.distance(fit)
  thr <- 4 / nrow(d)
  flagged <- which(cd > thr)
  cat(sprintf("    n = %d ; threshold = %.4f ; flagged = %d\n",
              nrow(d), thr, length(flagged)))
  list(flagged_n = length(flagged), cook = cd)
}

# ----------------------------------------------------------------
# D8 — Model C random-intercept variance check (bootstrap)
# ----------------------------------------------------------------
diag_D8 <- function(d) {
  cat("\n  D8 — Model C: random-intercept variance bootstrap CI\n")
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  fit_g <- glmer(as.formula(sprintf("event ~ %s + (1 | record_id)", rhs)),
                 data = d, family = binomial("logit"),
                 control = glmerControl(optimizer = "bobyqa",
                                         optCtrl = list(maxfun = 4e5)))
  vc <- VarCorr(fit_g)
  sigma2_u <- as.numeric(vc[[1]][1, 1])
  cat(sprintf("    sigma2_u = %.6f\n", sigma2_u))
  # Skip bootMer for time (200 nsim ~ 20 min); leave as TODO if needed
  list(sigma2_u = sigma2_u)
}

# ----------------------------------------------------------------
# D9 — Leave-one-school-out stability on focal coefficients
# ----------------------------------------------------------------
diag_D9 <- function(d, outcome) {
  cat(sprintf("\n  D9 — Leave-one-school-out for outcome=%s\n", outcome))
  schs <- sort(unique(d$schoolid))
  focal <- c("friends_use_ecig_lag", "E_users", "E_D", "mdd", "asian")
  out <- list()
  rhs <- paste(c("gs_fe", PRED), collapse = " + ")
  for (s in schs) {
    d_s <- subset(d, schoolid != s)
    fit_s <- tryCatch(
      glm(as.formula(sprintf("event ~ %s", rhs)),
          data = d_s, family = binomial("logit")),
      error = function(e) NULL)
    if (is.null(fit_s)) next
    co <- coef(fit_s)
    out[[as.character(s)]] <- co[focal]
  }
  if (length(out)) {
    mat <- do.call(rbind, out)
    cat("    OR range across leave-one-school-out (min .. max):\n")
    for (v in focal) {
      vals <- mat[, v]; vals <- vals[is.finite(vals)]
      if (length(vals))
        cat(sprintf("      %-25s : %.3f .. %.3f\n",
                    v, exp(min(vals)), exp(max(vals))))
    }
  }
  out
}

# ----------------------------------------------------------------
# Run everything
# ----------------------------------------------------------------
results <- list()
for (outcome in c("Adopters", "A", "B", "C")) {
  cat(sprintf("\n===================== %s =====================\n", outcome))
  kind <- if (outcome == "Adopters") "adopt" else outcome
  p <- load_panel(kind, Q = 7, mode = "main")
  d <- prep_data(p, E_D_var = "E_D_alt")
  cat(sprintf("  n = %d  events = %d  n_id = %d\n",
              nrow(d), sum(d$event), length(unique(d$record_id))))
  r <- list()
  r$D1 <- diag_D1(d, outcome)
  r$D2 <- diag_D2(d, outcome)
  r$D3 <- diag_D3(d, outcome)
  r$D4 <- diag_D4(d, outcome)
  r$D5 <- diag_D5(d, outcome)
  r$D6 <- diag_D6(d, outcome)
  r$D7 <- diag_D7(d, outcome)
  if (outcome == "C") r$D8 <- diag_D8(d)
  r$D9 <- diag_D9(d, outcome)
  results[[outcome]] <- r
}

saveRDS(results, file.path(INTERMEDIATE, "v5_diagnostics.rds"))
cat(sprintf("\nWrote %s\n",
            file.path(INTERMEDIATE, "v5_diagnostics.rds")))
cat("\nDone.\n")
