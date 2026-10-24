# ================================================================
# 11-revision-analyses.R
#
# Analyses for the PLOS ONE revision (PONE-D-26-32768).
# Scope: only what the reviewers ask for. Original par_edu coding.
#
#   (1) Main models (R2.6): all four outcomes as GLM logistic with
#       cluster-robust SE by student. Unstable (C) moves from glmer to
#       GLM; the random-intercept fit is kept for the supplement and
#       reports rho. Headline spec = Table 2 (E_D = E_D_alt, Q = 7).
#   (2) Included vs. excluded comparison (R3.1): characteristics at
#       each student's first observed wave, Q >= 7 vs. the rest.
#   (3) IPW sensitivity (R2.4, R3.2): stabilised inverse probability
#       of inclusion weights; refit of the four Table 2 models.
#   (4) Scenarios for discussion (not requested by reviewers):
#       (a) par_edu rebuilt as documented in the SM codebook (six-level
#           item, 1..6 valid, anything else -> NA, LOCF within student);
#       (b) (a) + students from school 108 removed (no network items
#           after W2). Plus the (2) comparison table without school 108.
#
# Outputs:
#   outputs/tables/rev_table2_ci_Q<Q>.csv      (Q = 5..8, GLM for C)
#   outputs/tables/rev_tableS_glmer_C.csv      (C with random intercept)
#   outputs/tables/rev_included_vs_excluded.csv
#   outputs/tables/rev_ipw_table2.csv
#   outputs/tables/rev_ipw_weights_summary.csv
#   outputs/tables/rev_scenarios_table2.csv
#   outputs/tables/rev_included_vs_excluded_no108.csv
# ================================================================
suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
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

load_panel <- function(kind, Q) {
  d <- readRDS(file.path(INTERMEDIATE, sprintf("v4b_panel_%s_Q%d_main_full.rds", kind, Q)))
  d <- attach_gs(d)
  d$cohort <- as.integer(d$cohort == "2025")
  d$E_D <- d$E_D_alt
  d$gs_fe <- factor(d$gs)
  d <- d[!is.na(d$gs), ]
  d[complete.cases(d[, c("event", PRED)]), ]
}

fit_glm_cl <- function(d, weights = NULL) {
  f <- as.formula(paste("event ~", paste(c("gs_fe", PRED), collapse = " + ")))
  d$.w <- if (is.null(weights)) 1 else weights
  fit <- suppressWarnings(glm(f, data = d, family = binomial("logit"), weights = .w))
  vc <- sandwich::vcovCL(fit, cluster = d$record_id, type = "HC0")
  list(fit = fit, ct = lmtest::coeftest(fit, vcov. = vc),
       n_id = length(unique(d$record_id)), events = sum(d$event))
}

fit_glmer_C <- function(d) {
  f <- as.formula(paste("event ~", paste(c("gs_fe", PRED), collapse = " + "),
                        "+ (1 | record_id)"))
  fit <- lme4::glmer(f, data = d, family = binomial("logit"),
                     control = lme4::glmerControl(optimizer = "bobyqa",
                                                  optCtrl = list(maxfun = 4e5)))
  s2 <- as.numeric(lme4::VarCorr(fit)[[1]][1, 1])
  list(fit = fit, ct = summary(fit)$coefficients,
       n_id = length(unique(d$record_id)), events = sum(d$event),
       sigma2_u = s2, rho = s2 / (s2 + pi^2 / 3), singular = lme4::isSingular(fit))
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

table_ci <- function(res) {
  rows <- lapply(PRED, function(v) sapply(res, function(r) fmt_or(or_ci(r$ct, v))))
  tab <- data.frame(Variable = PRED_LABEL[PRED], do.call(rbind, rows),
                    check.names = FALSE, row.names = NULL)
  rbind(tab,
        data.frame(Variable = "N Students", t(sapply(res, `[[`, "n_id")), check.names = FALSE),
        data.frame(Variable = "N Events",   t(sapply(res, `[[`, "events")), check.names = FALSE))
}

# ----------------------------------------------------------------
# (1) Main models, Q = 5..8, GLM for all four outcomes
# ----------------------------------------------------------------
panels <- list()
for (Q in 5:8) {
  panels[[as.character(Q)]] <- lapply(OUTCOMES, load_panel, Q = Q)
  res <- lapply(panels[[as.character(Q)]], fit_glm_cl)
  write.csv(table_ci(res), file.path(TABLES, sprintf("rev_table2_ci_Q%d.csv", Q)),
            row.names = FALSE)
  if (Q == 7) res_main <- res
}
cat("\nTable 2 (Q = 7), GLM for all outcomes:\n")
print(table_ci(res_main), right = FALSE)

# Random-intercept version of C (supplement)
gC <- fit_glmer_C(panels[["7"]]$C)
tabC <- data.frame(Variable = PRED_LABEL[PRED],
                   `C (GLM, cluster-robust)` = sapply(PRED, function(v) fmt_or(or_ci(res_main$C$ct, v))),
                   `C (random intercept)`    = sapply(PRED, function(v) fmt_or(or_ci(gC$ct, v))),
                   check.names = FALSE, row.names = NULL)
tabC <- rbind(tabC, data.frame(Variable = c("Between-student variance", "Rho (ICC)", "N Students", "N Events"),
                               `C (GLM, cluster-robust)` = c("—", "—", res_main$C$n_id, res_main$C$events),
                               `C (random intercept)` = c(sprintf("%.2e", gC$sigma2_u), sprintf("%.3f", gC$rho),
                                                          gC$n_id, gC$events),
                               check.names = FALSE))
write.csv(tabC, file.path(TABLES, "rev_tableS_glmer_C.csv"), row.names = FALSE)
cat(sprintf("\nglmer C: sigma2_u = %.3e, rho = %.4f, singular = %s\n",
            gC$sigma2_u, gC$rho, gC$singular))

# ----------------------------------------------------------------
# (2) Included vs. excluded, at each student's first observed wave
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

base <- obs[!duplicated(obs$record_id), ]          # first observed wave
# Time-invariant demographics: fall back to the first non-missing report
for (v in c("female", "sex_minority", "asian", "hispanic", "par_edu", "cohort")) {
  first_nm <- tapply(panel[[v]], panel$record_id, function(x) x[!is.na(x)][1])
  miss <- is.na(base[[v]])
  base[[v]][miss] <- first_nm[base$record_id[miss]]
}
base$included <- as.integer(max_consec[base$record_id] >= 7)
base$n_waves  <- n_waves[base$record_id]
base$cohort25 <- as.integer(base$cohort == "2025")
# Students whose first observation comes after spring 9th cannot reach 7
# consecutive waves within the 8 high-school semesters (excluded by design).
base$could_reach7 <- as.integer(!is.na(base$gs) & base$gs <= 2)
first_school <- tapply(panel$schoolid, panel$record_id, function(x) x[!is.na(x)][1])
base$schoolid[is.na(base$schoolid)] <- first_school[base$record_id[is.na(base$schoolid)]]
base$school <- substr(base$record_id, 1, 3)
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
  smd <- (m1 - m0) / sqrt((s1^2 + s0^2) / 2)
  if (spec$type == "bin") {
    p <- suppressWarnings(chisq.test(table(g, x))$p.value)
    f1 <- sprintf("%.1f", 100 * m1); f0 <- sprintf("%.1f", 100 * m0)
  } else {
    p <- t.test(x1, x0)$p.value
    f1 <- sprintf("%.2f (%.2f)", m1, s1); f0 <- sprintf("%.2f (%.2f)", m0, s0)
  }
  # Within-school SMD: included-vs-excluded difference net of school (school
  # fixed effects), scaled by the same pooled SD. Schools are identified by
  # the record_id prefix (school of enrolment).
  ok <- !is.na(x)
  b_w <- if (length(unique(x[ok])) > 1)
    coef(lm(x[ok] ~ g[ok] + factor(base$school[ok])))[2] else NA
  smd_w <- unname(b_w) / sqrt((s1^2 + s0^2) / 2)
  data.frame(Characteristic = lab, Included = f1, Excluded = f0,
             SMD = sprintf("%.2f", smd),
             `SMD within school` = ifelse(is.na(smd_w) | abs(smd_w) < 1e-8, "—",
                                          sprintf("%.2f", smd_w)),
             SMD_raw = round(smd, 4), SMD_within_raw = round(smd_w, 4),
             p = ifelse(p < 0.001, "<0.001", sprintf("%.3f", p)),
             `% missing (incl / excl)` = sprintf("%.0f / %.0f",
                                                 100 * mean(is.na(x1)), 100 * mean(is.na(x0))),
             check.names = FALSE)
}
cmp_table <- function(base) {
  cmp <- do.call(rbind, Map(cmp_row, names(CMP), CMP, MoreArgs = list(base = base)))
  rbind(data.frame(Characteristic = "N students",
                   Included = format(sum(base$included), big.mark = ","),
                   Excluded = format(sum(1 - base$included), big.mark = ","),
                   SMD = "", `SMD within school` = "", SMD_raw = NA, SMD_within_raw = NA,
                   p = "", `% missing (incl / excl)` = "", check.names = FALSE),
        cmp)
}
cmp <- cmp_table(base)
write.csv(cmp, file.path(TABLES, "rev_included_vs_excluded.csv"), row.names = FALSE)
cat("\nIncluded vs. excluded (first observed wave):\n")
print(cmp[, 1:7], right = FALSE, row.names = FALSE)

# ----------------------------------------------------------------
# (3) IPW: P(included | first-wave characteristics)
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
m_ipw <- glm(f_ipw, data = dw, family = binomial("logit"))
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
res_ipw <- lapply(panels[["7"]], function(d) fit_glm_cl(d, weights = unname(wmap[d$record_id])))
ipw_tab <- data.frame(Variable = PRED_LABEL[PRED], check.names = FALSE, row.names = NULL)
for (k in names(OUTCOMES)) {
  ipw_tab[[paste(k, "unweighted")]] <- sapply(PRED, function(v) fmt_or(or_ci(res_main[[k]]$ct, v)))
  ipw_tab[[paste(k, "IPW")]]        <- sapply(PRED, function(v) fmt_or(or_ci(res_ipw[[k]]$ct, v)))
}
write.csv(ipw_tab, file.path(TABLES, "rev_ipw_table2.csv"), row.names = FALSE)
cat("\nTable 2 unweighted vs. IPW:\n"); print(ipw_tab, right = FALSE)

# Exact p-values for the focal terms (main vs. IPW)
focal <- c("sex_minority", "asian", "in_degree", "mdd", "friends_use_ecig_lag", "E_users", "E_D")
pv <- do.call(rbind, lapply(names(OUTCOMES), function(k) data.frame(
  outcome = k, term = focal,
  p_main = sapply(focal, function(v) or_ci(res_main[[k]]$ct, v)["p"]),
  p_ipw  = sapply(focal, function(v) or_ci(res_ipw[[k]]$ct, v)["p"]), row.names = NULL)))
cat("\nFocal p-values:\n"); print(pv, digits = 3)
cat("\nInclusion-model fitted range:", range(dw$p_incl), "\n")

# ----------------------------------------------------------------
# (4) Scenarios: par_edu as documented; + without school 108
# ----------------------------------------------------------------
suppressMessages(library(readxl))
read_par <- function(f, waves) {
  h  <- tolower(names(read_excel(f, n_max = 0, .name_repair = "minimal")))
  ct <- rep("skip", length(h))
  ct[h %in% sprintf("w%d_dem_high_par_edu", waves)] <- "numeric"
  ct[h == "record_id"] <- "text"
  x <- suppressWarnings(read_excel(f, col_types = ct, .name_repair = "minimal"))
  names(x) <- tolower(names(x)); x
}
DATA_DIR <- file.path(ADVANCE_DATA, "..", "Data")
raw_par <- merge(read_par(file.path(DATA_DIR, "ADVANCE_W1-W8_Data_Complete_042326.xlsx"), 1:8),
                 read_par(file.path(DATA_DIR, "ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx"), 9:10),
                 by = "record_id", all.x = TRUE)
par_long <- do.call(rbind, lapply(1:10, function(w) data.frame(
  record_id = as.character(raw_par$record_id), wave = w,
  pe = raw_par[[sprintf("w%d_dem_high_par_edu", w)]])))
par_long$pe[!par_long$pe %in% 1:6] <- NA          # 9 = don't know, out-of-range -> NA
par_long <- par_long[order(par_long$record_id, par_long$wave), ]
locf <- function(x) { last <- NA; for (i in seq_along(x)) if (!is.na(x[i])) last <- x[i] else x[i] <- last; x }
par_long$par_fix <- ave(par_long$pe, par_long$record_id, FUN = locf)
par_key <- setNames(par_long$par_fix, paste(par_long$record_id, par_long$wave))

ids_108 <- unique(c(panel$record_id[!is.na(panel$schoolid) & panel$schoolid == 108],
                    panel$record_id[substr(panel$record_id, 1, 3) == "108"]))

scen_panels <- function(fix_par, drop108) {
  lapply(OUTCOMES, function(k) {
    d <- readRDS(file.path(INTERMEDIATE, sprintf("v4b_panel_%s_Q7_main_full.rds", k)))
    d <- attach_gs(d); d$cohort <- as.integer(d$cohort == "2025"); d$E_D <- d$E_D_alt
    if (fix_par) d$par_edu <- unname(par_key[paste(d$record_id, d$wave)])
    if (drop108) d <- d[!d$record_id %in% ids_108, ]
    d$gs_fe <- factor(d$gs); d <- d[!is.na(d$gs), ]
    d[complete.cases(d[, c("event", PRED)]), ]
  })
}
scen <- list(main  = res_main,
             par   = lapply(scen_panels(TRUE, FALSE), fit_glm_cl),
             par108 = lapply(scen_panels(TRUE, TRUE), fit_glm_cl))
sc_tab <- data.frame(Variable = PRED_LABEL[PRED], check.names = FALSE, row.names = NULL)
for (k in names(OUTCOMES)) for (s_ in names(scen))
  sc_tab[[paste(k, s_)]] <- sapply(PRED, function(v) {
    x <- or_ci(scen[[s_]][[k]]$ct, v); sprintf("%.2f%s (p=%.3f)", x["OR"], ifelse(x["p"] < .05, "*", ""), x["p"]) })
nrow_add <- function(lab, f) { r <- data.frame(Variable = lab, check.names = FALSE)
  for (k in names(OUTCOMES)) for (s_ in names(scen)) r[[paste(k, s_)]] <- f(scen[[s_]][[k]]); r }
sc_tab <- rbind(sc_tab, nrow_add("N Students", function(r) as.character(r$n_id)),
                nrow_add("N Events", function(r) as.character(r$events)))
write.csv(sc_tab, file.path(TABLES, "rev_scenarios_table2.csv"), row.names = FALSE)
cat("\nScenarios (main / par_edu fixed / + no school 108):\n"); print(sc_tab, right = FALSE)

base_fix <- base
base_fix$par_edu <- unname(par_key[paste(base_fix$record_id, base_fix$wave)])
first_fix <- tapply(par_long$par_fix, par_long$record_id, function(x) x[!is.na(x)][1])
miss <- is.na(base_fix$par_edu)
base_fix$par_edu[miss] <- first_fix[base_fix$record_id[miss]]
cmp108 <- cmp_table(base_fix[!base_fix$record_id %in% ids_108, ])
write.csv(cmp108, file.path(TABLES, "rev_included_vs_excluded_no108.csv"), row.names = FALSE)
cat("\nIncluded vs. excluded without school 108 (par_edu fixed):\n"); print(cmp108[, 1:7], right = FALSE, row.names = FALSE)
cat("School 108 students:", length(ids_108), " included among them:", sum(base$included[base$record_id %in% ids_108]), "\n")
