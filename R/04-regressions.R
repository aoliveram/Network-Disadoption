# ================================================================
# 04-regressions.R
#
# Paper specification (Table 2 and Supplementary S2a-S2c): discrete-
# time event-history logistic regressions for the four outcomes,
# Q in {5, 6, 7, 8}.
#
#   Outcomes : Adopters, A (stable), B (temporary), C (unstable)
#   Predictors: grade-semester FE + cohort + demographics + MDD/GAD +
#               out/in-degree + perceived friend use (w-1) +
#               E_users (w-1) + E_D = E_D_alt (peak - current, w-1)
#   Estimator : GLM logistic, cluster-robust SE by record_id (all four)
#
# Supplementary: C refitted with a person-level random intercept
# (lme4::glmer) at Q = 7, to report the between-student variance
# (rho = 0, odds ratios identical to the GLM).
#
# Outputs:
#   outputs/tables/table2_Q<Q>.csv          (Q = 7 -> Table 2; 8/6/5 -> S2a-c)
#   outputs/tables/tableS_glmer_C_Q7.csv
#   INTERMEDIATE/paper_results.rds          (fits + complete-case data)
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
})

source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

PRED <- c("cohort", "female", "sex_minority", "par_edu",
          "asian", "hispanic",
          "mdd", "gad",
          "out_degree", "in_degree",
          "friends_use_ecig_lag",
          "E_users", "E_D")
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
OUTCOMES <- c(Adopters = "adopt", A = "A", B = "B", C = "C")

# ----------------------------------------------------------------
# Data
# ----------------------------------------------------------------
load_panel <- function(kind, Q) {
  readRDS(file.path(INTERMEDIATE,
                    sprintf("v4b_panel_%s_Q%d_main_full.rds", kind, Q)))
}

prep_data <- function(p) {
  d <- attach_gs(p)                           # add gs from (cohort, wave) FIRST
  d$cohort <- as.integer(d$cohort == "2025")  # then encode 0/1
  d$E_D    <- d$E_D_alt
  d$gs_fe  <- factor(d$gs)
  d <- d[!is.na(d$gs), ]
  d[complete.cases(d[, c("event", PRED)]), ]
}

# ----------------------------------------------------------------
# Fitters
# ----------------------------------------------------------------
fit_glm <- function(d) {
  f <- as.formula(paste("event ~", paste(c("gs_fe", PRED), collapse = " + ")))
  fit <- glm(f, data = d, family = binomial("logit"))
  vc  <- sandwich::vcovCL(fit, cluster = d$record_id, type = "HC0")
  list(fit = fit, ct = lmtest::coeftest(fit, vcov. = vc), data = d,
       n = nrow(d), events = sum(d$event),
       n_id = length(unique(d$record_id)))
}

fit_glmer_id <- function(d) {
  f <- as.formula(paste("event ~", paste(c("gs_fe", PRED), collapse = " + "),
                        "+ (1 | record_id)"))
  fit <- lme4::glmer(f, data = d, family = binomial("logit"),
                     control = lme4::glmerControl(
                       optimizer = "bobyqa",
                       optCtrl   = list(maxfun = 4e5)))
  sigma2_u <- as.numeric(lme4::VarCorr(fit)[[1]][1, 1])
  list(fit = fit, ct = summary(fit)$coefficients,
       n = nobs(fit), events = sum(d$event),
       n_id = length(unique(d$record_id)),
       sigma2_u = sigma2_u, rho = sigma2_u / (sigma2_u + (pi^2) / 3))
}

# ----------------------------------------------------------------
# Tables: OR [95% CI] with p-value; * = p < 0.05
# ----------------------------------------------------------------
or_ci <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(OR = NA, lo = NA, hi = NA, p = NA))
  b <- ct[term, 1]; se <- ct[term, 2]; p <- ct[term, ncol(ct)]
  c(OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se), p = p)
}

fmt_cell <- function(x) {
  if (is.na(x["OR"])) return("—")
  sprintf("%.2f [%.2f–%.2f]%s (p=%.3f)", x["OR"], x["lo"], x["hi"],
          ifelse(x["p"] < 0.05, "*", ""), x["p"])
}

build_table <- function(results) {
  rows <- lapply(PRED, function(v)
    sapply(results, function(r) fmt_cell(or_ci(r$ct, v))))
  tab <- data.frame(Variable = PRED_LABEL[PRED], do.call(rbind, rows),
                    check.names = FALSE, row.names = NULL)
  rbind(tab,
        data.frame(Variable = "N Students",
                   t(sapply(results, `[[`, "n_id")), check.names = FALSE),
        data.frame(Variable = "N Events",
                   t(sapply(results, `[[`, "events")), check.names = FALSE))
}

# ----------------------------------------------------------------
# Main loop
# ----------------------------------------------------------------
all_results <- list()
for (Q in c(5, 6, 7, 8)) {
  cat(sprintf("\n========== Q = %d ==========\n", Q))
  res <- lapply(OUTCOMES, function(k) fit_glm(prep_data(load_panel(k, Q))))
  tab <- build_table(res)
  write.csv(tab, file.path(TABLES, sprintf("table2_Q%d.csv", Q)), row.names = FALSE)
  print(tab, right = FALSE)
  all_results[[as.character(Q)]] <- res
}

# Supplementary: random-intercept version of C at Q = 7
gC <- fit_glmer_id(all_results[["7"]]$C$data)
cC <- all_results[["7"]]$C
tabC <- data.frame(Variable = PRED_LABEL[PRED],
                   `C (GLM, cluster-robust)` = sapply(PRED, function(v) fmt_cell(or_ci(cC$ct, v))),
                   `C (random intercept)`    = sapply(PRED, function(v) fmt_cell(or_ci(gC$ct, v))),
                   check.names = FALSE, row.names = NULL)
tabC <- rbind(tabC,
              data.frame(Variable = c("Between-student variance", "Rho (ICC)",
                                      "N Students", "N Events"),
                         `C (GLM, cluster-robust)` = c("—", "—", cC$n_id, cC$events),
                         `C (random intercept)`    = c(sprintf("%.2e", gC$sigma2_u),
                                                       sprintf("%.3f", gC$rho),
                                                       gC$n_id, gC$events),
                         check.names = FALSE))
write.csv(tabC, file.path(TABLES, "tableS_glmer_C_Q7.csv"), row.names = FALSE)
cat(sprintf("\nC with random intercept (Q = 7): sigma2_u = %.3e, rho = %.3f\n",
            gC$sigma2_u, gC$rho))

all_results$glmer_C_Q7 <- gC
saveRDS(all_results, file.path(INTERMEDIATE, "paper_results.rds"))
cat("\nDone. Saved paper_results.rds, table2_Q{5,6,7,8}.csv and tableS_glmer_C_Q7.csv.\n")
