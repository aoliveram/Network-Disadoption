# ================================================================
# 03-network-features.R  (v4b)
#
# Compute network features per (i, w) for W1..W10 and attach them to
# every event panel (4 outcomes × 4 Q × 5 modes = 80 panels).
#
# Features (all evaluated at w-1):
#   out_degree, in_degree
#   E_users      : peer share currently using ecig (§5/§6/§7/§8/§9)
#   E_dis        : peer share who flipped 1->0 between w-2 and w-1
#                   (§5/§7/§8/§9 main E_D)
#   E_users_max  : max over s <= w-1 of E_users[i, s]
#   E_D_alt      : E_users_max - E_users  (§6 alternative E_D)
#   friends_use_ecig_lag : panel value at w-1
#
# Reads edges from data/advance/Cleaned-Data-042326/ (NEW, v4b).
# ================================================================

source(file.path(here::here(), "R", "00-config.R"))

WAVES <- 1:10
EDGE_DIR <- file.path(ADVANCE_DATA, "..", "Cleaned-Data-042326")

# ----------------------------------------------------------------
# 1) Read edges per wave
# ----------------------------------------------------------------
read_edges <- function(w) {
  f <- file.path(EDGE_DIR, sprintf("w%dedges_clean.csv", w))
  if (!file.exists(f)) return(data.frame(ego=character(0), alter=character(0)))
  e <- read.csv(f, stringsAsFactors = FALSE)
  names(e) <- tolower(names(e))
  if (!"ego" %in% names(e) && "egoid" %in% names(e))
    names(e)[names(e)=="egoid"] <- "ego"
  e <- e[!is.na(e$ego) & !is.na(e$alter), c("ego","alter")]
  e$ego   <- as.character(e$ego)
  e$alter <- as.character(e$alter)
  e
}
edges <- lapply(WAVES, read_edges)
names(edges) <- paste0("w", WAVES)
cat("Edges per wave:\n"); print(sapply(edges, nrow))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

all_ids <- sort(unique(panel$record_id))
ecig_w <- matrix(NA_integer_, nrow = length(all_ids), ncol = length(WAVES),
                 dimnames = list(all_ids, paste0("w", WAVES)))
for (k in seq_len(nrow(panel))) {
  if (!is.na(panel$ecig[k])) {
    ecig_w[panel$record_id[k], panel$wave[k]] <- as.integer(panel$ecig[k])
  }
}

# ----------------------------------------------------------------
# 2) Per-wave degree
# ----------------------------------------------------------------
out_deg <- in_deg <- matrix(0L, nrow = length(all_ids), ncol = length(WAVES),
                            dimnames = list(all_ids, paste0("w", WAVES)))
for (w in WAVES) {
  e <- edges[[paste0("w", w)]]
  if (!nrow(e)) next
  od <- table(e$ego); id <- table(e$alter)
  egos <- intersect(names(od), all_ids); alts <- intersect(names(id), all_ids)
  out_deg[egos, w] <- as.integer(od[egos])
  in_deg[alts,  w] <- as.integer(id[alts])
}

# ----------------------------------------------------------------
# 3) Per-wave E_users + E_dis
# ----------------------------------------------------------------
E_users <- matrix(NA_real_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))
E_dis   <- matrix(NA_real_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))
for (w in WAVES) {
  e <- edges[[paste0("w", w)]]
  if (!nrow(e)) next
  e_keep <- e[e$ego %in% all_ids & e$alter %in% all_ids, ]
  ec_w   <- ecig_w[, w]
  ec_prv <- if (w > 1) ecig_w[, w-1] else rep(NA_integer_, length(all_ids))
  alter_user <- ec_w[e_keep$alter]
  alter_dis  <- as.integer(!is.na(ec_prv[e_keep$alter]) &
                           !is.na(ec_w[e_keep$alter]) &
                           ec_prv[e_keep$alter] == 1 &
                           ec_w[e_keep$alter] == 0)
  spl_u <- split(alter_user, e_keep$ego); spl_d <- split(alter_dis, e_keep$ego)
  for (rid in names(spl_u)) {
    vu <- spl_u[[rid]]; vd <- spl_d[[rid]]
    if (any(!is.na(vu))) E_users[rid, w] <- mean(vu, na.rm = TRUE)
    if (length(vd))      E_dis[rid, w]   <- mean(vd, na.rm = TRUE)
  }
}

# ----------------------------------------------------------------
# 4) E_users cumulative max + E_D_alt
# ----------------------------------------------------------------
E_users_max <- E_users
for (i in seq_len(nrow(E_users))) {
  v <- E_users[i, ]
  cm <- v
  last <- NA_real_
  for (j in seq_along(cm)) {
    if (!is.na(cm[j])) {
      last <- if (is.na(last)) cm[j] else max(last, cm[j], na.rm = TRUE)
      cm[j] <- last
    } else {
      cm[j] <- last
    }
  }
  E_users_max[i, ] <- cm
}
E_D_alt <- E_users_max - E_users  # >= 0 when both defined

# ----------------------------------------------------------------
# 5) Attach to a panel
# ----------------------------------------------------------------
attach_features <- function(p) {
  rid_chr <- as.character(p$record_id)
  prev_w  <- p$wave - 1L
  good    <- prev_w >= 1 & prev_w <= length(WAVES)
  out <- list(
    out_degree           = rep(NA_integer_, nrow(p)),
    in_degree            = rep(NA_integer_, nrow(p)),
    E_users              = rep(NA_real_,    nrow(p)),
    E_dis                = rep(NA_real_,    nrow(p)),
    E_users_max          = rep(NA_real_,    nrow(p)),
    E_D_alt              = rep(NA_real_,    nrow(p)),
    friends_use_ecig_lag = rep(NA_real_,    nrow(p))
  )
  for (i in which(good)) {
    rid <- rid_chr[i]; pw <- prev_w[i]
    if (rid %in% all_ids) {
      out$out_degree[i]   <- out_deg[rid,    pw]
      out$in_degree[i]    <- in_deg[rid,     pw]
      out$E_users[i]      <- E_users[rid,    pw]
      out$E_dis[i]        <- E_dis[rid,      pw]
      out$E_users_max[i]  <- E_users_max[rid,pw]
      out$E_D_alt[i]      <- E_D_alt[rid,    pw]
    }
  }
  fue <- with(panel, setNames(friends_use_ecig,
                              paste(record_id, wave, sep = "_")))
  key_lag <- paste(p$record_id, prev_w, sep = "_")
  out$friends_use_ecig_lag <- as.numeric(fue[key_lag])
  cbind(p, as.data.frame(out, stringsAsFactors = FALSE))
}

# ----------------------------------------------------------------
# 6) Loop over all panels
# ----------------------------------------------------------------
modes <- c("main", "Cw2", "Cw3", "A_with_indet", "obs_jumps")
n_files <- 0L
for (Q in c(5, 6, 7, 8)) {
  for (md in modes) {
    for (kind in c("adopt", "A", "B", "C")) {
      src  <- file.path(INTERMEDIATE,
                        sprintf("v4b_panel_%s_Q%d_%s.rds", kind, Q, md))
      dest <- file.path(INTERMEDIATE,
                        sprintf("v4b_panel_%s_Q%d_%s_full.rds", kind, Q, md))
      if (!file.exists(src)) next
      p <- readRDS(src)
      saveRDS(attach_features(p), dest)
      n_files <- n_files + 1L
    }
  }
}
cat(sprintf("\nAttached features to %d panels\n", n_files))
saveRDS(list(out_deg = out_deg, in_deg = in_deg,
             E_users = E_users, E_dis = E_dis,
             E_users_max = E_users_max, E_D_alt = E_D_alt),
        file.path(INTERMEDIATE, "v4b_network_features.rds"))
cat("Saved: v4b_network_features.rds\n")
