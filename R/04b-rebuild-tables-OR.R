# ================================================================
# 04b-rebuild-tables-OR.R  (v4b)
#
# Post-process the saved v4b regression fits and emit the 20 tables
# again, this time with **odds ratios** (OR = exp(beta)) instead of
# raw logit coefficients. P-values are unchanged. Rho (ICC) for C
# remains on its native scale.
#
# Reads: outputs/intermediate/v4b_results.rds
# Writes: outputs/tables/v4b_table_<sec>_Q<Q>.csv (overwrites)
# ================================================================

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
  mdd                  = "MDD (RCADS Mean)",
  gad                  = "GAD (RCADS Mean)",
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

build_table_4 <- function(results, Q) {
  cols <- c("Adopters", "A", "B", "C"); rows <- list()
  for (var in PRED) {
    cells <- character(4); names(cells) <- cols
    for (col in cols) {
      r <- results[[col]]
      if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var)
      cells[col] <- fmt_OR_p(bp[1], bp[2])
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

build_table_7 <- function(C_W1, C_W2, C_W3) {
  cols <- c("C_W1", "C_W2", "C_W3"); rows <- list()
  fits <- list(C_W1 = C_W1, C_W2 = C_W2, C_W3 = C_W3)
  for (var in PRED) {
    cells <- character(3); names(cells) <- cols
    for (col in cols) {
      r <- fits[[col]]; if (is.null(r)) { cells[col] <- "—"; next }
      bp <- get_bp(r$ct, var); cells[col] <- fmt_OR_p(bp[1], bp[2])
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

all_results <- readRDS(file.path(INTERMEDIATE, "v4b_results.rds"))

for (Q in c(5, 6, 7, 8)) {
  Q_results <- all_results[[as.character(Q)]]
  for (sec in c(5, 6, 8, 9)) {
    res <- Q_results[[sprintf("s%d", sec)]]
    tab <- build_table_4(res, Q)
    out <- file.path(TABLES, sprintf("v4b_table_%d_Q%d.csv", sec, Q))
    write.csv(tab, out, row.names = FALSE)
  }
  s7 <- Q_results$s7
  tab7 <- build_table_7(s7$C_W1, s7$C_W2, s7$C_W3)
  out  <- file.path(TABLES, sprintf("v4b_table_7_Q%d.csv", Q))
  write.csv(tab7, out, row.names = FALSE)
}
cat("Rewrote 20 tables with OR formatting.\n")
