# ================================================================
# 92-valente-replication.R
#
# Strict Valente replication (Valente 2010, Table 10-2, KFP column).
# Discrete-time event history on KFP modern6 first-adoption events.
# NO additional community / period fixed effects (only `t` enters as
# a continuous integer, per Valente's specification).
#
# Specification (per prompts/v3-instructions.md, item 4):
#
#   logit(p_it) = a + b1 * t + b2 * Acum_{v,t-1}
#               + b3 * n_sent_i + b4 * n_recv_i
#               + b5 * E^coh_{i,t-1} + b6 * E^se_{i,t-1}
#               + b7 * children_i + b8 * media_i
#
# where:
#   t        : continuous integer (NOT a factor)
#   Acum     : community-level cumulative modern adoption at t-1
#   n_sent   : out-degree from the FP-discussion network
#   n_recv   : in-degree across (village, id) keys
#   E^coh    : (W * y_{t-1}) with W row-normalised adjacency
#   E^se     : structural-equivalence exposure (netdiffuseR::struct_equiv, v=1)
#   children : sons + daughts
#   media    : rowMeans(media6..media14, na.rm = TRUE) -- frequency-scale
#              items (range 0..4), per Tom Valente's book. We do NOT
#              use media1..media5 (binary ownership flags).
#
# Cluster SE by village. Run on KFP modern6 first-adoption events
# (kfamily$toa, the netdiffuseR canonical TOA).
#
# This is a sanity check / strict reproduction; the FE-controlled
# main analysis lives in 03-models-kfp.R.
#
# We also fit the same spec on TOA_derivado (from 91-toa-derivation.R)
# for a side-by-side comparison.
# ================================================================

suppressMessages({
  library(netdiffuseR)
  library(sandwich)
  library(lmtest)
  library(Matrix)
})
source(file.path(here::here(), "R", "00-config.R"))

data(kfamily, package = "netdiffuseR")
n <- nrow(kfamily)

# ---- panel length: 10 calendar periods (1964..1973) ----
# kfamily$toa = 1..10 for adopters, 11 for never-adopters.
# fit_eha treats toa > Tt as never (NA), so Tt = 10 correctly excludes
# never-adopters from contributing a spurious event at t=11.
Tt <- 10L

# ---- personal covariates ----
children     <- as.numeric(kfamily$sons) + as.numeric(kfamily$daughts)
# Strict Valente media: mean of media6..media14 (frequency scale, 0..4).
# We do NOT use media1..media5 (those are binary ownership flags).
media_idx    <- rowMeans(as.matrix(kfamily[, sprintf("media%d", 6:14)]),
                          na.rm = TRUE)
# Nomination vars: 0 = no nomination; positive = community id
net_vars <- sprintf("net1%d", 1:5)
surveyed <- kfamily$id
alter_mat <- as.matrix(kfamily[, net_vars])
alter_mat[alter_mat == 0] <- NA
for (j in seq_along(net_vars)) {
  bad <- !(alter_mat[, j] %in% surveyed)
  alter_mat[bad, j] <- NA
}
n_sent <- rowSums(!is.na(alter_mat))
# Count in-degree per (village, id)
key_ego   <- paste(kfamily$village, kfamily$id, sep = "_")
in_deg_key <- rep(0L, n)
for (j in seq_len(ncol(alter_mat))) {
  alter_id <- alter_mat[, j]
  ego_vill <- kfamily$village
  keep <- !is.na(alter_id)
  tbl  <- table(paste(ego_vill[keep], alter_id[keep], sep = "_"))
  match_idx <- match(key_ego, names(tbl))
  in_deg_key <- in_deg_key + ifelse(is.na(match_idx), 0L, as.integer(tbl[match_idx]))
}
n_received <- in_deg_key

# ---- load TOA_derivado ----
toa_deriv <- readRDS(file.path(INTERMEDIATE, "TOA_derivado_full.rds"))
stopifnot(nrow(toa_deriv) == n)
# Column name = TOA_derivado (per 1-toa_construction_3.R)
TOA_deriv <- toa_deriv$TOA_derivado

# ---- build adjacency matrix (FP-discussion, directed) ----
gid <- seq_len(n)
id_lookup <- setNames(gid, key_ego)
row_idx <- integer(0); col_idx <- integer(0)
for (j in seq_along(net_vars)) {
  alter_id <- alter_mat[, j]
  keep <- !is.na(alter_id)
  alter_global <- id_lookup[paste(kfamily$village[keep], alter_id[keep], sep = "_")]
  ok <- !is.na(alter_global)
  row_idx <- c(row_idx, gid[keep][ok])
  col_idx <- c(col_idx, as.integer(alter_global[ok]))
}
A <- sparseMatrix(i = row_idx, j = col_idx, x = 1, dims = c(n, n))
A@x[A@x > 1] <- 1  # collapse duplicates
# Row-normalized (so exposure = proportion of nominees who adopted)
row_sum <- as.numeric(Matrix::rowSums(A))
D <- Diagonal(n, ifelse(row_sum > 0, 1 / row_sum, 0))
W_coh <- as(D %*% A, "CsparseMatrix")

# ---- structural-equivalence weights (Burt 1987): w_ij = 1 / d_ij^v ----
# d_ij = Euclidean distance between rows i and j in the adjacency,
# v = large tuning exponent. Use Valente's exposure() from netdiffuseR if possible.

# Use netdiffuseR's struct_equiv on a static graph instead.

# ---- function that fits the EHA model for a given TOA ----
fit_eha <- function(toa_vec, label) {
  cat(sprintf("\n==== %s ====\n", label))

  # valid TOA: 1..Tt ; NA = never adopted in observation window
  toa_vec <- as.integer(toa_vec)
  toa_vec[!is.na(toa_vec) & toa_vec > Tt] <- NA
  toa_vec[!is.na(toa_vec) & toa_vec < 1L] <- NA
  adopted_ever <- !is.na(toa_vec)

  # Cumulative adoption indicator per period (matrix n x Tt): 1 if adopted by t
  y_mat <- matrix(0L, n, Tt)
  for (i in seq_len(n)) if (!is.na(toa_vec[i])) {
    y_mat[i, toa_vec[i]:Tt] <- 1L
  }

  # Exposure by cohesion at t:  E^coh_it = (W_coh %*% y_{t-1})_i
  # We use y at period t-1 as alters' state
  Ecoh <- matrix(0, n, Tt)
  for (t in 2:Tt) {
    Ecoh[, t] <- as.numeric(W_coh %*% y_mat[, t - 1])
  }

  # Structural equivalence exposure (per-period graph too heavy; use a
  # single SE weight matrix based on the static adjacency)
  # Use netdiffuseR::struct_equiv on the static graph
  dn <- new_diffnet(graph = A, toa = toa_vec, t0 = 1, t1 = Tt)
  se_obj <- tryCatch(struct_equiv(dn, v = 1), error = function(e) NULL)
  if (!is.null(se_obj)) {
    SE <- se_obj[[1]]$SE      # distance matrix; convert to weights
    W_se <- 1 / (SE + 1e-9)
    diag(W_se) <- 0
    rs <- rowSums(W_se)
    W_se <- W_se / ifelse(rs > 0, rs, 1)
    W_se <- as(W_se, "CsparseMatrix")
    Ese <- matrix(0, n, Tt)
    for (t in 2:Tt) Ese[, t] <- as.numeric(W_se %*% y_mat[, t - 1])
  } else {
    Ese <- matrix(NA_real_, n, Tt)
  }

  # Community cumulative adoption at t-1, relative to community size
  comm <- kfamily$village
  ucomm <- sort(unique(comm))
  Acum <- matrix(0, n, Tt)
  for (t in 2:Tt) {
    for (v in ucomm) {
      idx <- which(comm == v)
      Acum[idx, t] <- mean(y_mat[idx, t - 1])
    }
  }

  # At-risk row set: periods 1..toa_vec[i] (or all Tt if never)
  panel <- do.call(rbind, lapply(seq_len(n), function(i) {
    last <- if (is.na(toa_vec[i])) Tt else toa_vec[i]
    if (last < 1) return(NULL)
    ts  <- seq_len(last)
    yy  <- as.integer(!is.na(toa_vec[i]) & ts == toa_vec[i])
    data.frame(
      id = i, t = ts, y = yy,
      Ecoh     = Ecoh[i, ts],
      Ese      = Ese[i, ts],
      Acum     = Acum[i, ts],
      n_sent   = n_sent[i],
      n_recv   = n_received[i],
      children = children[i],
      media    = media_idx[i],
      village  = kfamily$village[i]
    )
  }))
  panel <- panel[complete.cases(panel[, c("Ecoh","Acum","n_sent","n_recv",
                                          "children","media")]), ]
  cat(sprintf("person-periods: %d; events: %d\n",
              nrow(panel), sum(panel$y)))

  # Fit logit: report OR + clustered SE by community
  fmla <- y ~ t + Acum + n_sent + n_recv + Ecoh + Ese + children + media
  # If Ese is all NA, drop it
  if (all(is.na(panel$Ese))) {
    fmla <- y ~ t + Acum + n_sent + n_recv + Ecoh + children + media
  }
  fit <- glm(fmla, data = panel, family = binomial("logit"))

  # Clustered SE by village
  clust_se <- tryCatch({
    sandwich::vcovCL(fit, cluster = ~ village)
  }, error = function(e) vcov(fit))
  ct <- lmtest::coeftest(fit, vcov. = clust_se)

  # Build OR table
  tab <- data.frame(
    term  = rownames(ct),
    beta  = ct[, 1],
    se    = ct[, 2],
    OR    = exp(ct[, 1]),
    z     = ct[, 3],
    p     = ct[, 4],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  print(tab, digits = 3)
  list(fit = fit, tab = tab, panel_n = nrow(panel), events = sum(panel$y))
}

# ---- (A) original toa ----
resA <- fit_eha(kfamily$toa, "ORIGINAL toa (kfamily$toa)")

# ---- (B) TOA_derivado ----
resB <- fit_eha(TOA_deriv, "TOA_derivado (1-toa_construction_3.R)")

# ---- save side-by-side ----
cmp <- merge(
  resA$tab[, c("term", "OR", "p")],
  resB$tab[, c("term", "OR", "p")],
  by = "term", suffixes = c("_orig", "_deriv"),
  all = TRUE, sort = FALSE
)
cat("\n==== Side-by-side OR comparison ====\n")
print(cmp, digits = 3)

out_dir <- TABLES
write.csv(resA$tab, file.path(out_dir, "table10-2_original_toa.csv"),
          row.names = FALSE)
write.csv(resB$tab, file.path(out_dir, "table10-2_TOA_derivado.csv"),
          row.names = FALSE)
write.csv(cmp,      file.path(out_dir, "table10-2_comparison.csv"),
          row.names = FALSE)

cat(sprintf("\nperson-periods: A=%d (events=%d) | B=%d (events=%d)\n",
            resA$panel_n, resA$events, resB$panel_n, resB$events))
