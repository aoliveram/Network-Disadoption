# ================================================================
# 03-network-features.R  (v4)
#
# For each event panel (adopt / A / B / C, per Q in {5,6,7,8}),
# attach the network-derived predictors at wave w-1:
#
#   out_degree[i, w-1]       : # of distinct alters i nominates at w-1
#   in_degree[i, w-1]        : # of distinct nominations of i at w-1
#   E_users[i, w-1]          : peer share of current users at w-1
#   E_dis[i, w-1]            : peer share of alters who flipped 1->0
#                               between w-2 and w-1
#
# Reads: outputs/intermediate/v4_panel_{adopt,A,B,C}_Q{5,6,7,8}.rds
# Writes: same panels with `_full` suffix, plus network-features RDS.
# ================================================================

source(file.path(here::here(), "R", "00-config.R"))

WAVES <- 1:8
EDGE_DIR <- file.path(ADVANCE_DATA)  # legacy CSV folder; edges are unchanged.

# ----------------------------------------------------------------
# 1) Read edges per wave + ecig state (from advance_panel_v4)
# ----------------------------------------------------------------
read_edges <- function(w) {
  f <- file.path(EDGE_DIR, sprintf("w%dedges_clean.csv", w))
  e <- read.csv(f, stringsAsFactors = FALSE)
  names(e) <- tolower(names(e))
  if (!"ego" %in% names(e) && "egoid" %in% names(e)) {
    names(e)[names(e) == "egoid"] <- "ego"
  }
  if (!all(c("ego", "alter") %in% names(e))) {
    stop("read_edges: missing ego/alter columns in ", f)
  }
  e <- e[!is.na(e$ego) & !is.na(e$alter), c("ego", "alter")]
  e$ego   <- as.character(e$ego)
  e$alter <- as.character(e$alter)
  e
}
edges <- lapply(WAVES, read_edges)
names(edges) <- paste0("w", WAVES)
cat("Edges per wave:\n"); print(sapply(edges, nrow))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

# Wide ecig matrix [student x wave]
all_ids <- sort(unique(panel$record_id))
ecig_w <- matrix(NA_integer_, nrow = length(all_ids), ncol = length(WAVES),
                 dimnames = list(all_ids, paste0("w", WAVES)))
for (k in seq_len(nrow(panel))) {
  if (!is.na(panel$ecig[k])) {
    ecig_w[panel$record_id[k], panel$wave[k]] <- as.integer(panel$ecig[k])
  }
}

# ----------------------------------------------------------------
# 2) Per-wave degree: out_deg[wave](i) = # distinct alters nominated
#    by i at wave; in_deg[wave](i)  = # of distinct nominations of i.
# ----------------------------------------------------------------
out_deg <- in_deg <- matrix(0L, nrow = length(all_ids), ncol = length(WAVES),
                            dimnames = list(all_ids, paste0("w", WAVES)))
for (w in WAVES) {
  e <- edges[[paste0("w", w)]]
  if (!nrow(e)) next
  od <- table(e$ego)
  id <- table(e$alter)
  egos <- names(od); alts <- names(id)
  out_deg[egos[egos %in% all_ids], w] <- as.integer(od[egos[egos %in% all_ids]])
  in_deg[alts[alts %in% all_ids],  w] <- as.integer(id[alts[alts %in% all_ids]])
}

# ----------------------------------------------------------------
# 3) Per-wave network exposures
#    E_users[i, w]  = mean( ecig_w[alters, w] ) over i's alters at w.
#    E_dis[i, w]    = mean( ecig_w[alters, w-1] == 1 & ecig_w[alters, w] == 0 )
# ----------------------------------------------------------------
E_users <- matrix(NA_real_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))
E_dis   <- matrix(NA_real_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))

for (w in WAVES) {
  e <- edges[[paste0("w", w)]]
  if (!nrow(e)) next
  egos <- e$ego; alts <- e$alter
  egos <- egos[egos %in% all_ids]
  alts <- alts[seq_along(egos)]
  alts <- alts[alts %in% all_ids]
  # Re-index keep
  keep <- e$ego %in% all_ids & e$alter %in% all_ids
  e_keep <- e[keep, ]
  # Vectorised mean per ego
  ec_w   <- ecig_w[, w]
  ec_prev <- if (w > 1) ecig_w[, w-1] else rep(NA_integer_, nrow(ecig_w))
  alter_user <- ec_w[e_keep$alter]
  alter_dis  <- as.integer(!is.na(ec_prev[e_keep$alter]) &
                           !is.na(ec_w[e_keep$alter]) &
                           ec_prev[e_keep$alter] == 1 &
                           ec_w[e_keep$alter] == 0)
  spl_user <- split(alter_user, e_keep$ego)
  spl_dis  <- split(alter_dis,  e_keep$ego)
  for (rid in names(spl_user)) {
    vu <- spl_user[[rid]]; vd <- spl_dis[[rid]]
    if (any(!is.na(vu)))   E_users[rid, w] <- mean(vu, na.rm = TRUE)
    if (length(vd))        E_dis[rid, w]   <- mean(vd, na.rm = TRUE)
  }
}

# ----------------------------------------------------------------
# 4) For each event panel, attach network features at w-1
# ----------------------------------------------------------------
attach_features <- function(p) {
  rid_chr <- as.character(p$record_id)
  w       <- p$wave
  prev_w  <- w - 1L
  good    <- prev_w >= 1 & prev_w <= length(WAVES)
  out <- list()
  out$out_degree         <- rep(NA_integer_, nrow(p))
  out$in_degree          <- rep(NA_integer_, nrow(p))
  out$E_users            <- rep(NA_real_, nrow(p))
  out$E_dis              <- rep(NA_real_, nrow(p))
  out$friends_use_ecig_l <- rep(NA_real_, nrow(p))  # already in panel? at w; we need at w-1
  for (i in which(good)) {
    rid <- rid_chr[i]; pw <- prev_w[i]
    out$out_degree[i] <- out_deg[rid, pw]
    out$in_degree[i]  <- in_deg[rid, pw]
    out$E_users[i]    <- E_users[rid, pw]
    out$E_dis[i]      <- E_dis[rid, pw]
  }
  # friends_use_ecig at w-1 (lookup in the long panel)
  fue <- with(panel, setNames(friends_use_ecig, paste(record_id, wave, sep = "_")))
  key_lag <- paste(p$record_id, prev_w, sep = "_")
  out$friends_use_ecig_lag <- as.numeric(fue[key_lag])
  cbind(p, as.data.frame(out, stringsAsFactors = FALSE))
}

# ----------------------------------------------------------------
# 5) Loop over Q and over outcomes
# ----------------------------------------------------------------
out_files <- list()
for (Q in c(5, 6, 7, 8)) {
  for (kind in c("adopt", "A", "B", "C")) {
    src  <- file.path(INTERMEDIATE, sprintf("v4_panel_%s_Q%d.rds", kind, Q))
    dest <- file.path(INTERMEDIATE, sprintf("v4_panel_%s_Q%d_full.rds", kind, Q))
    if (!file.exists(src)) next
    p <- readRDS(src)
    p <- attach_features(p)
    saveRDS(p, dest)
    out_files[[length(out_files)+1]] <- dest
  }
}
cat("\n=== Augmented panels saved ===\n")
for (f in out_files) cat("  ", basename(f), "\n")

saveRDS(list(out_deg = out_deg, in_deg = in_deg,
             E_users = E_users, E_dis = E_dis),
        file.path(INTERMEDIATE, "v4_network_features.rds"))
cat("\nSaved: v4_network_features.rds\n")
