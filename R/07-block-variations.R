# ================================================================
# 07-block-variations.R
#
# Supplementary Table S4: alternative operationalisations of peer
# cessation. Each variant REPLACES E_D alt in the paper specification
# (04-regressions.R: Q=7, gs_fe + cohort, GLM with cluster-robust SE
# by record_id for all four outcomes).
#
# Variants:
#   E_D_count     share of alters who flipped 1->0 between w-2 and w-1
#                 (= E_dis from 03-network-features.R)
#   anyQuit       binary: any alter flipped 1->0 between w-2 and w-1
#   PFU_decrease  binary: PFU_{w-1} < PFU_{w-2}
#   PFU_D         perceptual analogue of E_D alt:
#                 max(PFU_1..PFU_{w-1}) - PFU_{w-1}
#
# Outputs:
#   outputs/tables/tableS4_peer_cessation.csv
#   INTERMEDIATE/v5_block_variations.rds
# ================================================================
suppressMessages({
  library(sandwich); library(lmtest)
})
source(file.path(here::here(), "R", "00-config.R"))
source(file.path(here::here(), "R", "helpers.R"))

DEMOG    <- c("female", "sex_minority", "par_edu", "asian", "hispanic")
MENTAL   <- c("mdd", "gad")
NETWORK  <- c("out_degree", "in_degree", "friends_use_ecig_lag", "E_users")
VARIANTS <- c("E_D_count", "anyQuit", "PFU_decrease", "PFU_D")

panel_long <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))

# Build a (record_id, wave) lookup for PFU at any wave
pfu_lookup <- with(panel_long,
                   setNames(friends_use_ecig,
                            paste(record_id, wave, sep = "_")))

# Augment a panel with the alternative peer-cessation variables
augment_panel <- function(p) {
  p$cohort_dum <- as.integer(p$cohort == "2025")
  p <- attach_gs(p)
  rid <- as.character(p$record_id)
  w   <- p$wave
  wm2 <- w - 2L                  # prev-prev wave (for PFU change)
  # PFU at w-2 and change to w-1
  p$pfu_wm2 <- as.numeric(pfu_lookup[paste(rid, wm2, sep = "_")])
  p$PFU_decrease <- as.integer(p$friends_use_ecig_lag - p$pfu_wm2 < 0)
  # Historical peak of PFU over waves 1..w-1, minus PFU at w-1
  pfu_peak <- vapply(seq_len(nrow(p)), function(i) {
    x <- pfu_lookup[paste(rid[i], seq_len(w[i] - 1L), sep = "_")]
    if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)
  }, numeric(1))
  p$PFU_D <- pfu_peak - p$friends_use_ecig_lag
  # E_D_count is the share of alters who flipped 1->0; anyQuit its indicator
  p$E_D_count <- p$E_dis
  p$anyQuit   <- as.integer(!is.na(p$E_dis) & p$E_dis > 0)
  p
}

load_panel <- function(kind, Q = 7) {
  readRDS(file.path(INTERMEDIATE,
    sprintf("v4b_panel_%s_Q%d_main_full.rds", kind, Q)))
}

get_bp <- function(ct, term) {
  if (!term %in% rownames(ct)) return(c(NA, NA))
  z <- ct[term, ]
  c(unname(z["Estimate"]),
    unname(z[grep("^Pr", names(z))]))
}

fmt_OR_p <- function(bp) {
  if (any(is.na(bp))) return("—")
  sprintf("%.3f (%.3f)", exp(bp[1]), bp[2])
}

fit_variant <- function(d, variant) {
  d$gs_fe  <- factor(d$gs)
  d$cohort <- d$cohort_dum
  preds <- c("cohort", DEMOG, MENTAL, NETWORK, variant)
  rhs <- paste(c("gs_fe", preds), collapse = " + ")
  cc <- complete.cases(d[, c(preds, "gs", "event"), drop = FALSE])
  d_cc <- d[cc & !is.na(d$gs), ]
  fit <- glm(as.formula(sprintf("event ~ %s", rhs)),
             data = d_cc, family = binomial("logit"))
  vc <- sandwich::vcovCL(fit, cluster = d_cc$record_id, type = "HC0")
  list(ct = lmtest::coeftest(fit, vcov. = vc),
       n = nrow(d_cc), events = sum(d_cc$event),
       n_id = length(unique(d_cc$record_id)),
       aic = AIC(fit))
}

# Run
results <- list()
for (outcome in c("Adopters", "A", "B", "C")) {
  kind <- if (outcome == "Adopters") "adopt" else outcome
  cat(sprintf("\n===================== %s =====================\n", outcome))
  p <- augment_panel(load_panel(kind, Q = 7))
  out <- list()
  for (v in VARIANTS) {
    res <- fit_variant(p, v)
    bp  <- get_bp(res$ct, v)
    cat(sprintf("  %-13s n=%4d ev=%3d  OR=%.3f  p=%.3f\n",
                v, res$n, res$events, exp(bp[1]), bp[2]))
    out[[v]] <- list(res = res, focal = bp)
  }
  results[[outcome]] <- out
}

tabS4 <- data.frame(
  `Peer-cessation measure` = VARIANTS,
  sapply(names(results), function(o)
    sapply(VARIANTS, function(v) fmt_OR_p(results[[o]][[v]]$focal))),
  check.names = FALSE, row.names = NULL)
names(tabS4)[-1] <- c("Adopters", "Stable Quitters", "Temporary Quitters",
                      "Unstable Quitters")
print(tabS4, right = FALSE)

write.csv(tabS4, file.path(TABLES, "tableS4_peer_cessation.csv"), row.names = FALSE)
saveRDS(results, file.path(INTERMEDIATE, "v5_block_variations.rds"))
cat("\nDone. Wrote tableS4_peer_cessation.csv and v5_block_variations.rds\n")
