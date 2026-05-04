# ================================================================
# 02-event-builder.R  (v4b)
#
# Build per-outcome panels for the v4b regression families:
#   §5 Main:           main mode + window=1 for C
#   §6 Alt E_D:        same panels as §5 (E_D variant lives in features)
#   §7 Window:         main mode + C panels at window=1, 2, 3
#   §8 (a) sensitivity:A panel with indeterminates included
#   §9 (b) sensitivity:observed-wave-jumps mode (all panels)
#
# All panels stratified by Q in {5, 6, 7, 8} (longest run of consecutive
# valid `ecig` waves over W1-W10).
#
# Saves panels with names:
#   v4b_panel_<outcome>_Q<Q>_<mode>.rds
#   where outcome ∈ {adopt, A, B, C}, mode encodes the variant:
#     "main"           — §5/§6/§7/§8 baseline
#     "Cw2"            — main but with window=2 for C events
#     "Cw3"            — main but with window=3 for C events
#     "A_with_indet"   — main but indeterminates count as A
#     "obs_jumps"      — observed-wave-jumps mode
# ================================================================

source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]
WAVES <- 1:10

# ----------------------------------------------------------------
# Build wide ecig matrix [student x wave]
# ----------------------------------------------------------------
all_ids <- sort(unique(panel$record_id))
ecig_w  <- matrix(NA_integer_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))
for (k in seq_len(nrow(panel))) {
  if (!is.na(panel$ecig[k])) {
    ecig_w[panel$record_id[k], panel$wave[k]] <- as.integer(panel$ecig[k])
  }
}

# ----------------------------------------------------------------
# Helper: longest run of consecutive observed waves
# ----------------------------------------------------------------
longest_consec <- function(s) {
  s <- sort(unique(s[!is.na(s)]))
  if (!length(s)) return(0L); if (length(s) == 1) return(1L)
  best <- cur <- 1L
  for (i in 2:length(s)) {
    if (s[i] == s[i-1] + 1L) cur <- cur + 1L else cur <- 1L
    if (cur > best) best <- cur
  }
  best
}

# Per-student longest run
ecig_obs <- split(panel$wave[!is.na(panel$ecig)],
                  panel$record_id[!is.na(panel$ecig)])
max_consec <- vapply(ecig_obs, longest_consec, integer(1))
cat("Longest consecutive run distribution:\n")
print(table(max_consec))

eligible_under_Q <- function(Q) names(max_consec)[max_consec >= Q]

# ----------------------------------------------------------------
# Lag helpers
# ----------------------------------------------------------------
add_calendar_lags <- function(p) {
  p <- p[order(p$record_id, p$wave), ]
  p$ecig_prev <- ave(p$ecig, p$record_id,
                     FUN = function(x) c(NA, x[-length(x)]))
  p$ecig_next <- ave(p$ecig, p$record_id,
                     FUN = function(x) c(x[-1], NA))
  p
}
panel <- add_calendar_lags(panel)

# ----------------------------------------------------------------
# Event identification per student.
#   mode in {"main", "Cw2", "Cw3", "A_with_indet", "obs_jumps"}
# Returns a list of 4 panels (adopt, A, B, C) with `event` column.
# ----------------------------------------------------------------
build_panels <- function(panel_subset, mode) {
  ids <- sort(unique(panel_subset$record_id))
  ecig_sub <- ecig_w[ids, , drop = FALSE]
  Tt <- ncol(ecig_sub)
  # Window for C
  C_window <- switch(mode, main = 1L, Cw2 = 2L, Cw3 = 3L,
                     A_with_indet = 1L, obs_jumps = 1L, 1L)

  # Storage for per-event keys
  ev_adopt <- ev_A <- ev_B <- ev_C <- character(0)

  for (i in seq_len(nrow(ecig_sub))) {
    rid <- rownames(ecig_sub)[i]; v <- ecig_sub[i, ]
    obs <- which(!is.na(v))
    if (length(obs) < 2) next
    if (mode == "obs_jumps") {
      # Use observed-wave jumps: pairs are consecutive observations
      pairs <- mapply(function(a, b) c(a, b), obs[-length(obs)], obs[-1],
                       SIMPLIFY = FALSE)
    } else {
      # Calendar consecutive pairs only
      pairs <- list()
      for (k in 2:Tt) if (!is.na(v[k]) && !is.na(v[k-1])) {
        pairs[[length(pairs)+1]] <- c(k-1, k)
      }
    }
    fa <- f10 <- FALSE
    for (kk in seq_along(pairs)) {
      a <- pairs[[kk]][1]; b <- pairs[[kk]][2]
      sp <- v[a]; sc <- v[b]
      if (is.na(sp) || is.na(sc)) next
      key <- paste(rid, b, sep = "_")
      if (sp == 0 && sc == 1 && !fa) {
        ev_adopt <- c(ev_adopt, key); fa <- TRUE
      }
      if (sp == 1 && sc == 0) {
        if (!f10) { ev_B <- c(ev_B, key); f10 <- TRUE }
        # C: cycle within `C_window` next observed waves
        future_obs <- obs[obs > b]
        nw <- min(C_window, length(future_obs))
        if (nw > 0 && any(v[future_obs[seq_len(nw)]] == 1, na.rm = TRUE)) {
          ev_C <- c(ev_C, key)
        }
        # A: never returns ; in A_with_indet, also include indeterminates
        if (length(future_obs) == 0) {
          if (mode == "A_with_indet") ev_A <- c(ev_A, key)
        } else if (!any(v[future_obs] == 1, na.rm = TRUE)) {
          ev_A <- c(ev_A, key)
        }
      }
    }
  }

  # Build risk-set panels
  pan_q <- panel[panel$record_id %in% ids, ]

  # Adopters: standard at-risk = never adopted yet & ecig observed
  ever_before <- ave(pan_q$ecig, pan_q$record_id,
                     FUN = function(x) cummax(replace(x, is.na(x), 0)))
  pan_q$ever_before <- c(0, ever_before[-length(ever_before)])
  pan_q$ever_before[c(TRUE,
                       pan_q$record_id[-1] != pan_q$record_id[-nrow(pan_q)])] <- 0
  pa <- pan_q[!is.na(pan_q$ecig_prev) & pan_q$ecig_prev == 0 &
              pan_q$ever_before == 0 & !is.na(pan_q$ecig), ]
  pa$event <- as.integer(paste(pa$record_id, pa$wave, sep="_") %in% ev_adopt)

  # A risk-set: 1->0 person-waves with future obs (or indeterminate, in A_with_indet)
  rs10 <- pan_q[!is.na(pan_q$ecig_prev) & pan_q$ecig_prev == 1 &
                !is.na(pan_q$ecig), ]
  # For A: drop person-waves where the student has no future obs (indeterminate)
  obs_per_id <- split(pan_q$wave[!is.na(pan_q$ecig)],
                       pan_q$record_id[!is.na(pan_q$ecig)])
  has_future <- vapply(seq_len(nrow(rs10)), function(i) {
    any(obs_per_id[[as.character(rs10$record_id[i])]] > rs10$wave[i])
  }, logical(1))
  if (mode == "A_with_indet") {
    # Keep ALL rows (even those with no future) — indet count as 0-event
    pA <- rs10
  } else {
    pA <- rs10[has_future, ]
  }
  pA$event <- as.integer(paste(pA$record_id, pA$wave, sep="_") %in% ev_A)

  # B risk-set: walk forward from first 1->0; keep up to and including event row
  pB_rows <- list()
  for (rid in unique(rs10$record_id)) {
    sub <- rs10[rs10$record_id == rid, ]
    sub <- sub[order(sub$wave), ]
    sub$event <- as.integer(paste(sub$record_id, sub$wave, sep="_") %in% ev_B)
    ev_idx <- which(sub$event == 1)
    end_at <- if (length(ev_idx)) ev_idx[1] else nrow(sub)
    pB_rows[[length(pB_rows)+1]] <- sub[seq_len(end_at), ]
  }
  pB <- if (length(pB_rows)) do.call(rbind, pB_rows) else rs10[FALSE, ]

  # C risk-set: 1->0 person-waves with at least one future observed wave
  pC <- rs10[has_future, ]
  pC$event <- as.integer(paste(pC$record_id, pC$wave, sep="_") %in% ev_C)

  list(adopt = pa, A = pA, B = pB, C = pC,
       n_ev = c(adopt = length(ev_adopt), A = length(ev_A),
                B = length(ev_B),     C = length(ev_C)))
}

# ----------------------------------------------------------------
# Run all combinations: 4 Q × 5 modes
# ----------------------------------------------------------------
modes <- c("main", "Cw2", "Cw3", "A_with_indet", "obs_jumps")
summary_rows <- list()

for (Q in c(5, 6, 7, 8)) {
  cat(sprintf("\n========== Q = %d ==========\n", Q))
  eligible <- eligible_under_Q(Q)
  panel_q <- panel[panel$record_id %in% eligible, ]
  cat(sprintf("Eligible: %d students, %d person-waves\n",
              length(eligible), nrow(panel_q)))
  for (md in modes) {
    cat(sprintf("\n  mode = %s\n", md))
    res <- build_panels(panel_q, md)
    for (kind in c("adopt", "A", "B", "C")) {
      saveRDS(res[[kind]],
              file.path(INTERMEDIATE,
                        sprintf("v4b_panel_%s_Q%d_%s.rds", kind, Q, md)))
    }
    summary_rows[[length(summary_rows)+1]] <- data.frame(
      Q = Q, mode = md,
      n_eligible = length(eligible),
      adopt_n = nrow(res$adopt), adopt_ev = sum(res$adopt$event),
      A_n     = nrow(res$A),     A_ev     = sum(res$A$event),
      B_n     = nrow(res$B),     B_ev     = sum(res$B$event),
      C_n     = nrow(res$C),     C_ev     = sum(res$C$event),
      stringsAsFactors = FALSE)
  }
}
out_summary <- do.call(rbind, summary_rows)
saveRDS(out_summary, file.path(INTERMEDIATE, "v4b_event_summary.rds"))
cat("\n=== Summary across (Q, mode) ===\n")
print(out_summary, row.names = FALSE)
