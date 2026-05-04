# ================================================================
# 04c-section8-tables.R  (v4b refinement)
#
# Build the two §8 tables (one per E_D variant) showing the A column
# only, with 8 result columns per table = 4 Q levels × {original
# (§5/§6), (a) indeterminates-as-A}.
#
# Requires: v4b_results.rds (already has §5 and §6 A fits per Q;
# already has §8 A fits with E_dis). We additionally fit the §8 A
# panel with E_D_alt as the predictor and store those fits.
#
# Outputs:
#   outputs/tables/v4b_table_8a_E_dis.csv     (E_D = peer-flipped)
#   outputs/tables/v4b_table_8a_E_alt.csv     (E_D = alt = max - cur)
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
})
source(file.path(here::here(), "R", "00-config.R"))

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
prep_data <- function(p, E_D_var, drop_cohort = FALSE) {
  d <- p
  d$cohort <- as.integer(d$cohort == "2025")
  if (drop_cohort) d$cohort <- NULL
  d$E_D <- if (E_D_var == "E_dis") d$E_dis else d$E_D_alt
  d
}

# ----------------------------------------------------------------
# 1) Run A_with_indet × E_D_alt regressions for each Q (new)
# ----------------------------------------------------------------
fits_indet_alt <- list()
for (Q in c(5, 6, 7, 8)) {
  p <- readRDS(file.path(INTERMEDIATE,
                         sprintf("v4b_panel_A_Q%d_A_with_indet_full.rds", Q)))
  d <- prep_data(p, E_D_var = "E_D_alt", drop_cohort = (Q == 8))
  pred <- if (Q == 8) setdiff(PRED, "cohort") else PRED
  rhs <- paste(c("wave_fe", pred), collapse = " + ")
  f <- as.formula(sprintf("event ~ %s", rhs))
  fits_indet_alt[[as.character(Q)]] <- fit_glm(f, d)
  cat(sprintf("Q=%d  A indet × E_alt :  n=%d  ev=%d  n_id=%d\n",
              Q, fits_indet_alt[[as.character(Q)]]$n,
              fits_indet_alt[[as.character(Q)]]$events,
              fits_indet_alt[[as.character(Q)]]$n_id))
}

# ----------------------------------------------------------------
# 2) Pull the existing fits from v4b_results.rds:
#    - §5 A (main mode, E_dis)            -> "orig" col with E_dis
#    - §6 A (main mode, E_D_alt)          -> "orig" col with E_alt
#    - §8 A (A_with_indet, E_dis)         -> "(a)" col with E_dis
#    - new fits (A_with_indet, E_D_alt)   -> "(a)" col with E_alt
# ----------------------------------------------------------------
all_results <- readRDS(file.path(INTERMEDIATE, "v4b_results.rds"))

# Helper: build one big 8-col table (A only)
build_section8_A <- function(fits_orig_per_Q, fits_indet_per_Q) {
  Qs <- c(8, 7, 6, 5)
  cols <- character(0)
  cell_data <- list()
  for (Q in Qs) {
    for (mode_lab in c("orig", "(a)")) {
      cols <- c(cols, sprintf("Q=%d %s", Q, mode_lab))
    }
  }
  rows <- list()
  for (var in PRED) {
    cells <- character(length(cols))
    j <- 1
    for (Q in Qs) {
      for (md in c("orig", "indet")) {
        r <- if (md == "orig") fits_orig_per_Q[[as.character(Q)]] else fits_indet_per_Q[[as.character(Q)]]
        if (is.null(r)) { cells[j] <- "—" } else {
          bp <- get_bp(r$ct, var); cells[j] <- fmt_OR_p(bp[1], bp[2])
        }
        j <- j + 1
      }
    }
    rows[[PRED_LABEL[var]]] <- cells
  }
  # N students + N events rows
  n_cells <- e_cells <- character(length(cols))
  j <- 1
  for (Q in Qs) {
    for (md in c("orig", "indet")) {
      r <- if (md == "orig") fits_orig_per_Q[[as.character(Q)]] else fits_indet_per_Q[[as.character(Q)]]
      if (is.null(r)) { n_cells[j] <- "—"; e_cells[j] <- "—" } else {
        n_cells[j] <- as.character(r$n_id)
        e_cells[j] <- as.character(r$events)
      }
      j <- j + 1
    }
  }
  rows[["N Students"]] <- n_cells
  rows[["N Events"]]   <- e_cells

  # Assemble
  out <- do.call(rbind, lapply(rows, function(r) {
    as.data.frame(setNames(as.list(r), cols), stringsAsFactors = FALSE)
  }))
  out <- cbind(Variable = names(rows), out, stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

# §5 A and §8 A fits (with E_dis)
fits5_A <- list(); fits8_A_dis <- list()
for (Q in c(5, 6, 7, 8)) {
  fits5_A[[as.character(Q)]]     <- all_results[[as.character(Q)]]$s5$A
  fits8_A_dis[[as.character(Q)]] <- all_results[[as.character(Q)]]$s8$A
}
# §6 A (with E_D_alt)
fits6_A <- list()
for (Q in c(5, 6, 7, 8)) fits6_A[[as.character(Q)]] <- all_results[[as.character(Q)]]$s6$A

# Build the two tables
tab1 <- build_section8_A(fits5_A, fits8_A_dis)
tab2 <- build_section8_A(fits6_A, fits_indet_alt)

write.csv(tab1, file.path(TABLES, "v4b_table_8a_E_dis.csv"), row.names = FALSE)
write.csv(tab2, file.path(TABLES, "v4b_table_8a_E_alt.csv"), row.names = FALSE)
cat("\nWrote:\n")
cat("  ", file.path(TABLES, "v4b_table_8a_E_dis.csv"), "\n")
cat("  ", file.path(TABLES, "v4b_table_8a_E_alt.csv"), "\n")
cat("\n=== Table 1 (E_D peer-flipped) ===\n"); print(tab1, row.names = FALSE)
cat("\n=== Table 2 (E_D alt) ===\n");          print(tab2, row.names = FALSE)
