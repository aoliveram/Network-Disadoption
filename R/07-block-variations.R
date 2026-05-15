# ================================================================
# 07-block-variations.R  (v5)
#
# Block-buildup analysis for the headline spec (§6 alt E_D at Q=7,
# gs_fe + cohort), plus Block 5 variants that REPLACE E_D alt with
# alternative "peer cessation" predictors.
#
# Blocks (each fit for 4 outcomes: Adopters, A, B, C at Q=7):
#   1: gs_fe + cohort + 5 demographics
#   2: + MDD + GAD
#   3: + 4 network features (out/in-degree, PFU_lag, E_users)
#   4: + E_D alt   (= current §13 headline)
#
# Block 5 variants — replace E_D alt with one of:
#   5.1  anyQuit_w-1     binary indicator: any alter flipped 1->0 in (w-2, w-1)
#   5.3a delta_PFU       PFU_{w-1} - PFU_{w-2}
#   5.3b PFU_decrease    binary: PFU_{w-1} < PFU_{w-2}
#   5.4  delta_Eusers    E_users_{w-1} - E_users_{w-2}
#
# Outputs:
#   outputs/intermediate/v5_block_variations.rds
# ================================================================
suppressMessages({
  library(sandwich); library(lmtest); library(lme4)
})
source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

DEMOG    <- c("female", "sex_minority", "par_edu", "asian", "hispanic")
MENTAL   <- c("mdd", "gad")
NETWORK  <- c("out_degree", "in_degree", "friends_use_ecig_lag", "E_users")
HEADLINE <- "E_D_alt"

panel_long <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features   <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))

# Build a (record_id, wave) lookup for PFU at any wave
pfu_lookup <- with(panel_long,
                   setNames(friends_use_ecig,
                            paste(record_id, wave, sep = "_")))

# E_users_w2: matrix already in features$E_users (rows = record_id, cols = w1..w10)
Eu_mat <- features$E_users
Edis_mat <- features$E_dis
ids_all <- rownames(Eu_mat)

# Augment a panel with the new variables
augment_panel <- function(p) {
  p$cohort_dum <- as.integer(p$cohort == "2025")
  p <- attach_gs(p)
  rid <- as.character(p$record_id)
  w   <- p$wave
  wm1 <- w - 1L                  # prev wave (where E_users/PFU lag pulls from)
  wm2 <- w - 2L                  # prev-prev wave (for delta)
  # PFU at w-2 (perceived friend use two waves before)
  p$pfu_wm2 <- as.numeric(pfu_lookup[paste(rid, wm2, sep = "_")])
  # E_users at w-2
  p$E_users_wm2 <- NA_real_
  good <- wm2 >= 1 & wm2 <= 10 & rid %in% ids_all
  for (i in which(good)) {
    p$E_users_wm2[i] <- Eu_mat[rid[i], wm2[i]]
  }
  # delta variables (positive = increase from w-2 to w-1)
  p$delta_PFU    <- p$friends_use_ecig_lag - p$pfu_wm2
  p$delta_Eusers <- p$E_users               - p$E_users_wm2
  p$PFU_decrease <- as.integer(p$delta_PFU < 0)
  # anyQuit: indicator of E_dis_w-1 > 0 (i.e., at least one alter flipped
  # 1->0 in the previous wave). E_dis is already the share of flipped alters.
  p$anyQuit <- as.integer(!is.na(p$E_dis) & p$E_dis > 0)
  p
}

load_panel <- function(kind, Q = 7) {
  readRDS(file.path(INTERMEDIATE,
    sprintf("v4b_panel_%s_Q%d_main_full.rds", kind, Q)))
}

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

fit_block <- function(d, preds, outcome) {
  d$gs_fe  <- factor(d$gs)
  d$cohort <- d$cohort_dum
  # Use E_D_alt as the predictor mapped to E_D for compatibility
  if ("E_D_alt" %in% preds) {
    preds <- c(setdiff(preds, "E_D_alt"), "E_D_alt")
  }
  rhs <- paste(c("gs_fe", "cohort", preds), collapse = " + ")
  cc_vars <- c(preds, "gs", "cohort", "event")
  cc <- complete.cases(d[, intersect(cc_vars, names(d)), drop = FALSE])
  d_cc <- d[cc & !is.na(d$gs), ]
  if (nrow(d_cc) == 0) return(NULL)
  if (outcome == "C") {
    f <- as.formula(sprintf("event ~ %s + (1 | record_id)", rhs))
    fit <- tryCatch(
      glmer(f, data = d_cc, family = binomial("logit"),
            control = glmerControl(optimizer = "bobyqa",
                                    optCtrl = list(maxfun = 4e5))),
      error = function(e) NULL)
    if (is.null(fit)) return(NULL)
    ct <- summary(fit)$coefficients
    aic <- AIC(fit); bic <- BIC(fit); ll <- as.numeric(logLik(fit))
  } else {
    f <- as.formula(sprintf("event ~ %s", rhs))
    fit <- glm(f, data = d_cc, family = binomial("logit"))
    vc <- tryCatch(sandwich::vcovCL(fit, cluster = d_cc$record_id,
                                     type = "HC0"),
                   error = function(e) sandwich::vcovHC(fit, type = "HC0"))
    ct <- lmtest::coeftest(fit, vcov. = vc)
    aic <- AIC(fit); bic <- BIC(fit); ll <- as.numeric(logLik(fit))
  }
  list(fit = fit, ct = ct,
       n = nrow(d_cc),
       events = sum(d_cc$event),
       n_id = length(unique(d_cc$record_id)),
       aic = aic, bic = bic, ll = ll,
       preds = preds)
}

# Predictor sets per block
BLOCKS <- list(
  "B1_demog"     = c("cohort", DEMOG),
  "B2_mental"    = c("cohort", DEMOG, MENTAL),
  "B3_network"   = c("cohort", DEMOG, MENTAL, NETWORK),
  "B4_E_D_alt"   = c("cohort", DEMOG, MENTAL, NETWORK, "E_D_alt"),
  "B5_anyQuit"   = c("cohort", DEMOG, MENTAL, NETWORK, "anyQuit"),
  "B5_delta_PFU" = c("cohort", DEMOG, MENTAL, NETWORK, "delta_PFU"),
  "B5_PFU_dec"   = c("cohort", DEMOG, MENTAL, NETWORK, "PFU_decrease"),
  "B5_delta_Eu"  = c("cohort", DEMOG, MENTAL, NETWORK, "delta_Eusers")
)

# Run
results <- list()
for (outcome in c("Adopters", "A", "B", "C")) {
  kind <- if (outcome == "Adopters") "adopt" else outcome
  cat(sprintf("\n===================== %s =====================\n", outcome))
  p <- load_panel(kind, Q = 7)
  p <- augment_panel(p)
  cat(sprintf("  Augmented panel: %d rows, n_id=%d\n",
              nrow(p), length(unique(p$record_id))))
  out <- list()
  for (b in names(BLOCKS)) {
    preds <- setdiff(BLOCKS[[b]], "cohort")
    res <- fit_block(p, preds = preds, outcome = outcome)
    if (is.null(res)) {
      cat(sprintf("  %-15s [NULL]\n", b)); out[[b]] <- NULL; next
    }
    # Pull focal predictor OR/p
    focal_terms <- c("E_D_alt", "anyQuit", "delta_PFU",
                     "PFU_decrease", "delta_Eusers",
                     "friends_use_ecig_lag", "E_users", "mdd", "gad")
    foc <- lapply(focal_terms, function(t) get_bp(res$ct, t))
    names(foc) <- focal_terms
    cat(sprintf("  %-15s n=%4d ev=%3d  AIC=%6.1f  ll=%.1f\n",
                b, res$n, res$events, res$aic, res$ll))
    for (t in focal_terms) {
      bp <- foc[[t]]
      if (all(is.na(bp))) next
      cat(sprintf("    %-22s OR=%.3f  p=%.3f\n",
                  t, exp(bp[1]), bp[2]))
    }
    out[[b]] <- list(res = res, focal = foc)
  }
  results[[outcome]] <- out
}

saveRDS(results, file.path(INTERMEDIATE, "v5_block_variations.rds"))
cat("\nDone. Wrote v5_block_variations.rds\n")
