# ================================================================
# 11-revision-analyses.R
#
# Attrition analyses for the PLOS ONE revision (PONE-D-26-32768),
# reviewer points R2.4, R3.1 and R3.2. Uses the paper specification
# fitted in 04-regressions.R (run it first).
#
#   (1) Included vs. excluded comparison: characteristics at each
#       student's first observed wave, Q >= 7 vs. the rest, with the
#       overall and the within-school-cohort SMD. Repeated for
#       Q >= 6 and Q >= 5, for baseline non-users, and for ever-users
#       (measured at their first wave of reported use).
#   (2) IPW sensitivity: stabilised inverse probability of inclusion
#       weights; refit of the four Table 2 models.
#
# Outputs:
#   outputs/tables/rev_included_vs_excluded.csv          (Q >= 7, all)
#   outputs/tables/rev_included_vs_excluded_Q6.csv
#   outputs/tables/rev_included_vs_excluded_Q5.csv
#   outputs/tables/rev_included_vs_excluded_nonusers.csv (Q >= 7)
#   outputs/tables/rev_included_vs_excluded_everusers.csv (Q >= 7)
#   outputs/tables/rev_ipw_table2.csv
#   outputs/tables/rev_ipw_weights_summary.csv
# ================================================================
suppressMessages({
  library(sandwich)
  library(lmtest)
})
source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

PRED <- c("cohort", "female", "sex_minority", "par_edu", "asian", "hispanic",
          "mdd", "gad", "out_degree", "in_degree",
          "friends_use_ecig_lag", "E_users", "E_D")
PRED_LABEL <- c(
  cohort = "Cohort (2025 vs 2024)", female = "Female",
  sex_minority = "Sexual Minority", par_edu = "Parent Ed.",
  asian = "Asian", hispanic = "Hispanic/Latine",
  mdd = "MDD (RCADS Mean)", gad = "GAD (RCADS Mean)",
  out_degree = "Out-degree", in_degree = "In-degree",
  friends_use_ecig_lag = "Perceived Friend Use",
  E_users = "Network Exposure Users",
  E_D = "Network Exposure Dis-adopters")
OUTCOMES <- c(Adopters = "adopt", A = "A", B = "B", C = "C")

# Paper specification at Q = 7 (fits and complete-case data from 04)
res_main <- readRDS(file.path(INTERMEDIATE, "paper_results.rds"))[["7"]]

fit_glm_cl <- function(d, weights = NULL) {
  f <- as.formula(paste("event ~", paste(c("gs_fe", PRED), collapse = " + ")))
  d$.w <- if (is.null(weights)) 1 else weights
  fit <- suppressWarnings(glm(f, data = d, family = binomial("logit"), weights = .w))
  vc <- sandwich::vcovCL(fit, cluster = d$record_id, type = "HC0")
  list(fit = fit, ct = lmtest::coeftest(fit, vcov. = vc),
       n_id = length(unique(d$record_id)), events = sum(d$event))
}

or_ci <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(OR = NA, lo = NA, hi = NA, p = NA))
  b <- ct[term, 1]; se <- ct[term, 2]; p <- ct[term, ncol(ct)]
  c(OR = exp(b), lo = exp(b - 1.96 * se), hi = exp(b + 1.96 * se), p = p)
}

fmt_or <- function(x) {
  if (is.na(x["OR"])) return("—")
  sprintf("%.2f [%.2f–%.2f]%s", x["OR"], x["lo"], x["hi"], ifelse(x["p"] < 0.05, "*", ""))
}

# ----------------------------------------------------------------
# (1) Included vs. excluded
# ----------------------------------------------------------------
panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
nf    <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]
panel$out_degree <- nf$out_deg[cbind(panel$record_id, paste0("w", panel$wave))]
panel$in_degree  <- nf$in_deg[cbind(panel$record_id, paste0("w", panel$wave))]
panel$E_users    <- nf$E_users[cbind(panel$record_id, paste0("w", panel$wave))]
panel <- attach_gs(panel)

longest_consec <- function(s) {
  s <- sort(unique(s[!is.na(s)]))
  if (!length(s)) return(0L); if (length(s) == 1) return(1L)
  best <- cur <- 1L
  for (i in 2:length(s)) {
    if (s[i] == s[i - 1] + 1L) cur <- cur + 1L else cur <- 1L
    if (cur > best) best <- cur
  }
  best
}
obs <- panel[!is.na(panel$ecig), ]
max_consec <- vapply(split(obs$wave, obs$record_id), longest_consec, integer(1))
n_waves    <- vapply(split(obs$wave, obs$record_id), length, integer(1))

# One row per student, taken at the first observed wave (or, for
# ever-users, at the first wave with reported use)
student_rows <- function(rows) {
  b <- rows[!duplicated(rows$record_id), ]
  # Time-invariant demographics: fall back to the first non-missing report
  for (v in c("female", "sex_minority", "asian", "hispanic", "par_edu", "cohort")) {
    first_nm <- tapply(panel[[v]], panel$record_id, function(x) x[!is.na(x)][1])
    miss <- is.na(b[[v]])
    b[[v]][miss] <- first_nm[b$record_id[miss]]
  }
  first_obs <- obs[!duplicated(obs$record_id), ]
  b$max_consec <- max_consec[b$record_id]
  b$n_waves    <- n_waves[b$record_id]
  b$cohort25   <- as.integer(b$cohort == "2025")
  # Students first observed after spring 9th cannot reach 7 consecutive
  # waves within the 8 high-school semesters (excluded by design).
  b$could_reach7 <- as.integer(first_obs$gs[match(b$record_id, first_obs$record_id)] <= 2)
  b$could_reach7[is.na(b$could_reach7)] <- 0L
  first_school <- tapply(panel$schoolid, panel$record_id, function(x) x[!is.na(x)][1])
  b$schoolid[is.na(b$schoolid)] <- first_school[b$record_id[is.na(b$schoolid)]]
  # School cohort = record_id prefix: first digit = cohort (1 = class of
  # 2024, 2 = class of 2025), last two digits = school (112 and 212 are
  # the same high school).
  b$school <- substr(b$record_id, 1, 3)
  b
}
base <- student_rows(obs)
base$included <- as.integer(base$max_consec >= 7)
stopifnot(sum(base$included) == 1961)   # v4b pipeline count (paper text: 1,962)

CMP <- list(
  "Waves with e-cigarette data"         = list(v = "n_waves",          type = "cont"),
  "Entry grade-semester (1 = fall 9th)" = list(v = "gs",               type = "cont"),
  "% Entered by spring 9th"             = list(v = "could_reach7",     type = "bin"),
  "% Cohort 2"                          = list(v = "cohort25",         type = "bin"),
  "% Female"                            = list(v = "female",           type = "bin"),
  "% Sexual minority"                   = list(v = "sex_minority",     type = "bin"),
  "Parent education"                    = list(v = "par_edu",          type = "cont"),
  "% Asian"                             = list(v = "asian",            type = "bin"),
  "% Hispanic/Latine"                   = list(v = "hispanic",         type = "bin"),
  "% E-cigarette use (past 6 months)"   = list(v = "ecig",             type = "bin"),
  "% Cigarette use (past 6 months)"     = list(v = "cig",              type = "bin"),
  "Perceived friend use"                = list(v = "friends_use_ecig", type = "cont"),
  "MDD (RCADS mean)"                    = list(v = "mdd",              type = "cont"),
  "GAD (RCADS mean)"                    = list(v = "gad",              type = "cont"),
  "Out-degree"                          = list(v = "out_degree",       type = "cont"),
  "In-degree"                           = list(v = "in_degree",        type = "cont"),
  "Network exposure users"              = list(v = "E_users",          type = "cont"))

cmp_row <- function(lab, spec, base) {
  x <- base[[spec$v]]; g <- base$included
  x1 <- x[g == 1]; x0 <- x[g == 0]
  m1 <- mean(x1, na.rm = TRUE); m0 <- mean(x0, na.rm = TRUE)
  s1 <- sd(x1, na.rm = TRUE);   s0 <- sd(x0, na.rm = TRUE)
  sp <- sqrt((s1^2 + s0^2) / 2)
  smd <- if (sp > 0) (m1 - m0) / sp else NA
  if (spec$type == "bin") {
    p <- tryCatch(suppressWarnings(chisq.test(table(g, x))$p.value), error = function(e) NA)
    f1 <- sprintf("%.1f", 100 * m1); f0 <- sprintf("%.1f", 100 * m0)
  } else {
    p <- tryCatch(t.test(x1, x0)$p.value, error = function(e) NA)
    f1 <- sprintf("%.2f (%.2f)", m1, s1); f0 <- sprintf("%.2f (%.2f)", m0, s0)
  }
  # Within-school-cohort SMD: included-vs-excluded difference net of
  # school cohort (fixed effects), scaled by the same pooled SD.
  ok <- !is.na(x)
  b_w <- if (sp > 0 && length(unique(x[ok])) > 1)
    coef(lm(x[ok] ~ g[ok] + factor(base$school[ok])))[2] else NA
  smd_w <- unname(b_w) / sp
  data.frame(Characteristic = lab, Included = f1, Excluded = f0,
             SMD = ifelse(is.na(smd), "—", sprintf("%.2f", smd)),
             `SMD within school cohort` = ifelse(is.na(smd_w) | abs(smd_w) < 1e-8, "—",
                                                 sprintf("%.2f", smd_w)),
             SMD_raw = round(smd, 4), SMD_within_raw = round(smd_w, 4),
             p = ifelse(is.na(p), "—", ifelse(p < 0.001, "<0.001", sprintf("%.3f", p))),
             `% missing (incl / excl)` = sprintf("%.0f / %.0f",
                                                 100 * mean(is.na(x1)), 100 * mean(is.na(x0))),
             check.names = FALSE)
}
cmp_table <- function(base) {
  cmp <- do.call(rbind, Map(cmp_row, names(CMP), CMP, MoreArgs = list(base = base)))
  rbind(data.frame(Characteristic = "N students",
                   Included = format(sum(base$included), big.mark = ","),
                   Excluded = format(sum(1 - base$included), big.mark = ","),
                   SMD = "", `SMD within school cohort` = "", SMD_raw = NA, SMD_within_raw = NA,
                   p = "", `% missing (incl / excl)` = "", check.names = FALSE),
        cmp)
}
write_cmp <- function(b, file, label) {
  cmp <- cmp_table(b)
  write.csv(cmp, file.path(TABLES, file), row.names = FALSE)
  cat(sprintf("\nIncluded vs. excluded: %s\n", label))
  print(cmp[, c(1:5, 8)], right = FALSE, row.names = FALSE)
}

write_cmp(base, "rev_included_vs_excluded.csv", "Q >= 7, all students")
for (Q in c(6, 5)) {
  bq <- base; bq$included <- as.integer(bq$max_consec >= Q)
  write_cmp(bq, sprintf("rev_included_vs_excluded_Q%d.csv", Q),
            sprintf("Q >= %d, all students", Q))
}
write_cmp(base[base$ecig == 0, ], "rev_included_vs_excluded_nonusers.csv",
          "Q >= 7, baseline non-users")
ever <- student_rows(obs[obs$ecig == 1, ])
ever$included <- as.integer(ever$max_consec >= 7)
write_cmp(ever, "rev_included_vs_excluded_everusers.csv",
          "Q >= 7, ever-users at their first wave of reported use")

# ----------------------------------------------------------------
# (2) IPW: P(included | first-wave characteristics)
# ----------------------------------------------------------------
IPW_X <- c("cohort25", "female", "sex_minority", "par_edu", "asian", "hispanic",
           "ecig", "friends_use_ecig", "mdd", "gad", "out_degree", "in_degree")
# Positivity: only students who could have reached 7 waves enter the model.
dw <- base[base$could_reach7 == 1 & !is.na(base$schoolid), ]
cat(sprintf("\nIPW universe: %d students (%d included, %d excluded); %d late entrants left out\n",
            nrow(dw), sum(dw$included), sum(1 - dw$included), sum(base$could_reach7 == 0)))
for (v in IPW_X) {                                   # missing-indicator method
  dw[[paste0(v, "_na")]] <- as.integer(is.na(dw[[v]]))
  dw[[v]][is.na(dw[[v]])] <- median(dw[[v]], na.rm = TRUE)
}
dw$school_fe <- factor(dw$schoolid)
dw$gs_entry  <- factor(dw$gs)                      # fall vs. spring 9th
na_terms <- paste0(IPW_X, "_na")[sapply(paste0(IPW_X, "_na"), function(v) any(dw[[v]] == 1))]
f_ipw <- as.formula(paste("included ~", paste(c(IPW_X, na_terms, "school_fe", "gs_entry"),
                                              collapse = " + ")))
m_ipw <- suppressWarnings(glm(f_ipw, data = dw, family = binomial("logit")))
dw$p_incl <- predict(m_ipw, type = "response")
dw$w <- mean(dw$included) / dw$p_incl
lim <- quantile(dw$w[dw$included == 1], c(0.01, 0.99))
dw$w <- pmin(pmax(dw$w, lim[1]), lim[2])
w_inc <- dw$w[dw$included == 1]
auc <- with(dw, {r <- rank(p_incl); n1 <- sum(included); n0 <- sum(1 - included)
  (sum(r[included == 1]) - n1 * (n1 + 1) / 2) / (n1 * n0)})
ws <- data.frame(stat = c("AUC of inclusion model", "min", "p25", "median", "p75", "max",
                          "Effective N (Kish)"),
                 value = c(auc, quantile(w_inc, c(0, .25, .5, .75, 1)),
                           sum(w_inc)^2 / sum(w_inc^2)))
write.csv(ws, file.path(TABLES, "rev_ipw_weights_summary.csv"), row.names = FALSE)
cat("\nIPW weights (included students):\n"); print(ws)

wmap <- setNames(dw$w, dw$record_id)
res_ipw <- lapply(res_main[names(OUTCOMES)], function(r)
  fit_glm_cl(r$data, weights = unname(wmap[r$data$record_id])))
ipw_tab <- data.frame(Variable = PRED_LABEL[PRED], check.names = FALSE, row.names = NULL)
for (k in names(OUTCOMES)) {
  ipw_tab[[paste(k, "unweighted")]] <- sapply(PRED, function(v) fmt_or(or_ci(res_main[[k]]$ct, v)))
  ipw_tab[[paste(k, "IPW")]]        <- sapply(PRED, function(v) fmt_or(or_ci(res_ipw[[k]]$ct, v)))
}
write.csv(ipw_tab, file.path(TABLES, "rev_ipw_table2.csv"), row.names = FALSE)
cat("\nTable 2 unweighted vs. IPW:\n"); print(ipw_tab, right = FALSE)
