# ================================================================
# 02-event-builder.R  (v4)
#
# Build per-outcome panels for the four ADVANCE regressions
# (Adopters, A-Stable, B-Experimental, C-Unstable) under each
# Q-restriction (Q in {5, 6, 7, 8}).
#
# Definitions (per prompts/v4-instructions.md):
#   Adopters     = first 0->1 transition (one event per person).
#   A (Stable)   = 1->0 with no future return to 1 in any later
#                   observed wave.
#   B (Experim.) = first 1->0 (any).
#   C (Unstable) = 1->0 followed by 1 in the immediately next observed
#                   wave (window=1). Multiple events per person allowed.
#
# Q-restriction:
#   Eligible students have at least Q **consecutive calendar waves**
#   with non-NA `ecig`. The Q filter is applied to all four outcomes
#   for consistency.
#
# Outputs (per Q):
#   panel_adopt_Q.rds, panel_A_Q.rds, panel_B_Q.rds, panel_C_Q.rds
# All saved to outputs/intermediate/.
# ================================================================

source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

# ----------------------------------------------------------------
# Helper: longest run of consecutive observed waves per student
# ----------------------------------------------------------------
longest_consec <- function(waves_obs) {
  s <- sort(unique(waves_obs[!is.na(waves_obs)]))
  if (length(s) == 0) return(0L)
  if (length(s) == 1) return(1L)
  best <- cur <- 1L
  for (i in 2:length(s)) {
    if (s[i] == s[i-1] + 1L) cur <- cur + 1L else cur <- 1L
    if (cur > best) best <- cur
  }
  best
}

# Per-student summary: how many consecutive waves of valid e-cig
ecig_obs_per_student <- split(panel$wave[!is.na(panel$ecig)],
                              panel$record_id[!is.na(panel$ecig)])
max_consec <- vapply(ecig_obs_per_student, longest_consec, integer(1))
cat("=== Distribution of longest consecutive runs of valid ecig ===\n")
print(table(max_consec))

# ----------------------------------------------------------------
# Helper: build a wide ecig matrix [student x wave] from the long panel
# ----------------------------------------------------------------
all_ids <- sort(unique(panel$record_id))
wide_ecig <- matrix(NA_integer_, nrow = length(all_ids), ncol = 8,
                    dimnames = list(all_ids, paste0("w", 1:8)))
for (k in seq_len(nrow(panel))) {
  w <- panel$wave[k]
  if (!is.na(panel$ecig[k])) {
    wide_ecig[panel$record_id[k], w] <- as.integer(panel$ecig[k])
  }
}

# ----------------------------------------------------------------
# Event identification per student.
# Returns a data.frame with one row per (record_id, wave-of-event):
#   event_type in {"adopt", "A", "B", "C"}, all four flags Boolean.
# ----------------------------------------------------------------
events_per_student <- function(rid) {
  v <- wide_ecig[rid, ]
  obs <- which(!is.na(v))
  if (length(obs) < 2) return(NULL)
  out <- list()
  # Walk consecutive observed pairs.
  pairs <- mapply(function(a, b) c(a, b), obs[-length(obs)], obs[-1],
                   SIMPLIFY = FALSE)
  first_adopt_done <- FALSE
  first_10_done    <- FALSE
  for (k in seq_along(pairs)) {
    a <- pairs[[k]][1]; b <- pairs[[k]][2]
    s_prev <- v[a]; s_curr <- v[b]
    is_pair_adoption <- (s_prev == 0 && s_curr == 1)
    is_pair_disadopt <- (s_prev == 1 && s_curr == 0)
    # Adopters: first 0->1
    if (is_pair_adoption && !first_adopt_done) {
      out[[length(out)+1]] <- data.frame(
        record_id = rid, wave = b, event_type = "adopt",
        stringsAsFactors = FALSE)
      first_adopt_done <- TRUE
    }
    # B: first 1->0
    if (is_pair_disadopt && !first_10_done) {
      out[[length(out)+1]] <- data.frame(
        record_id = rid, wave = b, event_type = "B",
        stringsAsFactors = FALSE)
      first_10_done <- TRUE
    }
    # C (unstable, window=1): 1->0 with next observed wave = 1
    if (is_pair_disadopt) {
      next_obs_wave <- if (k < length(pairs)) pairs[[k+1]][2] else NA
      if (!is.na(next_obs_wave) && v[next_obs_wave] == 1) {
        out[[length(out)+1]] <- data.frame(
          record_id = rid, wave = b, event_type = "C",
          stringsAsFactors = FALSE)
      }
    }
    # A (stable): 1->0 with no future return to 1
    if (is_pair_disadopt) {
      future_obs <- obs[obs > b]
      ever_returns <- length(future_obs) > 0 &&
                       any(v[future_obs] == 1, na.rm = TRUE)
      indeterminate <- length(future_obs) == 0  # no future obs at all
      if (!ever_returns && !indeterminate) {
        out[[length(out)+1]] <- data.frame(
          record_id = rid, wave = b, event_type = "A",
          stringsAsFactors = FALSE)
      }
    }
  }
  if (length(out)) do.call(rbind, out) else NULL
}

cat("\nIdentifying events per student...\n")
all_events <- do.call(rbind, lapply(all_ids, events_per_student))
cat(sprintf("Total event rows: %d\n", nrow(all_events)))
cat("By event_type:\n"); print(table(all_events$event_type))

# Number of unique students per event_type
cat("\nUnique students per event_type:\n")
print(tapply(all_events$record_id, all_events$event_type,
             function(x) length(unique(x))))

# ----------------------------------------------------------------
# Build risk-set panels for each outcome at the panel level.
# Each row = (record_id, wave) at risk. event = 0/1 outcome.
# ----------------------------------------------------------------

# Lag and next helpers per student
add_lags <- function(df) {
  df <- df[order(df$record_id, df$wave), ]
  df$ecig_prev <- ave(df$ecig, df$record_id, FUN = function(x) c(NA, x[-length(x)]))
  df$ecig_next <- ave(df$ecig, df$record_id, FUN = function(x) c(x[-1], NA))
  df
}

panel <- add_lags(panel)

# Risk-set helpers
build_panel_adopt <- function(panel) {
  ever_before <- ave(panel$ecig, panel$record_id,
                     FUN = function(x) cummax(replace(x, is.na(x), 0)))
  panel$ever_before <- c(0, ever_before[-length(ever_before)])
  panel$ever_before[c(TRUE,
                       panel$record_id[-1] != panel$record_id[-nrow(panel)])] <- 0
  rs <- panel[!is.na(panel$ecig_prev) & panel$ecig_prev == 0 &
              panel$ever_before == 0 & !is.na(panel$ecig), ]
  rs$event <- as.integer(rs$ecig == 1)
  rs
}

build_panel_A <- function(panel, all_events) {
  # A's risk-set: 1->0 transitions where the student has FUTURE
  # observations to verify "no return". Each student contributes to
  # A only at the wave of their stable disadoption (one row).
  A_keys <- with(all_events[all_events$event_type == "A", ],
                  paste(record_id, wave, sep = "_"))
  rs <- panel[!is.na(panel$ecig_prev) & panel$ecig_prev == 1 &
              !is.na(panel$ecig), ]
  panel_keys <- paste(rs$record_id, rs$wave, sep = "_")
  rs$event <- as.integer(panel_keys %in% A_keys)
  # Indeterminate filter: drop rows where the student has no FUTURE
  # observed wave at all after this one (no way to verify "no return").
  drop_indet <- function(df) {
    n <- nrow(df)
    keep <- logical(n)
    obs_per_id <- split(seq_len(nrow(panel)), panel$record_id)
    for (i in seq_len(n)) {
      rid <- df$record_id[i]; w <- df$wave[i]
      future <- panel$wave[obs_per_id[[as.character(rid)]]]
      future <- future[future > w & !is.na(panel$ecig[obs_per_id[[as.character(rid)]]][future > w])]
      keep[i] <- length(future) > 0
    }
    df[keep, ]
  }
  rs <- drop_indet(rs)
  rs
}

build_panel_B <- function(panel, all_events) {
  # B's risk-set: walk forward from first 1 (first adoption); event = 1
  # at first 1->0; person leaves the risk-set after event.
  B_keys <- with(all_events[all_events$event_type == "B", ],
                  paste(record_id, wave, sep = "_"))
  rs <- panel[!is.na(panel$ecig_prev) & panel$ecig_prev == 1 &
              !is.na(panel$ecig), ]
  panel_keys <- paste(rs$record_id, rs$wave, sep = "_")
  rs$event <- as.integer(panel_keys %in% B_keys)
  # Trim: only keep rows up to and including the first event for each
  # student. After the first event, the person leaves the risk-set.
  trim_rows <- list()
  for (rid in unique(rs$record_id)) {
    sub <- rs[rs$record_id == rid, ]
    sub <- sub[order(sub$wave), ]
    ev_idx <- which(sub$event == 1)
    end_at <- if (length(ev_idx)) ev_idx[1] else nrow(sub)
    trim_rows[[length(trim_rows) + 1]] <- sub[seq_len(end_at), ]
  }
  do.call(rbind, trim_rows)
}

build_panel_C <- function(panel, all_events) {
  # C's risk-set: every person-wave with ecig_prev=1 AND a next observed
  # wave (so we can verify the cycle). Event = 1 if the next observed
  # ecig is 1. Multiple events per person.
  C_keys <- with(all_events[all_events$event_type == "C", ],
                  paste(record_id, wave, sep = "_"))
  rs <- panel[!is.na(panel$ecig_prev) & panel$ecig_prev == 1 &
              !is.na(panel$ecig), ]
  # For C we also need ecig_next observed (the post-disadopt wave).
  # We use the NEXT OBSERVED wave for the student, not just ecig_next.
  # Easier: drop rows where there's no future observation of ecig.
  obs_per_id <- split(panel$wave[!is.na(panel$ecig)],
                       panel$record_id[!is.na(panel$ecig)])
  has_future <- vapply(seq_len(nrow(rs)), function(i) {
    rid <- as.character(rs$record_id[i])
    any(obs_per_id[[rid]] > rs$wave[i])
  }, logical(1))
  rs <- rs[has_future, ]
  panel_keys <- paste(rs$record_id, rs$wave, sep = "_")
  rs$event <- as.integer(panel_keys %in% C_keys)
  rs
}

# ----------------------------------------------------------------
# Q-restriction per student
# ----------------------------------------------------------------
eligible_under_Q <- function(panel, Q) {
  obs_per_student <- split(panel$wave[!is.na(panel$ecig)],
                            panel$record_id[!is.na(panel$ecig)])
  max_consec <- vapply(obs_per_student, longest_consec, integer(1))
  names(max_consec)[max_consec >= Q]
}

# ----------------------------------------------------------------
# Build all four panels per Q
# ----------------------------------------------------------------
out_summary <- data.frame()
for (Q in c(5, 6, 7, 8)) {
  cat(sprintf("\n========== Q = %d ==========\n", Q))
  eligible <- eligible_under_Q(panel, Q)
  cat(sprintf("  Eligible students (>= %d consecutive valid waves): %d\n",
              Q, length(eligible)))
  panel_q <- panel[panel$record_id %in% eligible, ]

  pa <- build_panel_adopt(panel_q)
  pA <- build_panel_A(panel_q, all_events)
  pB <- build_panel_B(panel_q, all_events)
  pC <- build_panel_C(panel_q, all_events)

  out_summary <- rbind(out_summary, data.frame(
    Q = Q,
    n_eligible_students = length(eligible),
    n_pw_adopt = nrow(pa), n_ev_adopt = sum(pa$event),
    n_pw_A = nrow(pA), n_ev_A = sum(pA$event),
    n_pw_B = nrow(pB), n_ev_B = sum(pB$event),
    n_pw_C = nrow(pC), n_ev_C = sum(pC$event)
  ))
  saveRDS(pa, file.path(INTERMEDIATE, sprintf("v4_panel_adopt_Q%d.rds", Q)))
  saveRDS(pA, file.path(INTERMEDIATE, sprintf("v4_panel_A_Q%d.rds",     Q)))
  saveRDS(pB, file.path(INTERMEDIATE, sprintf("v4_panel_B_Q%d.rds",     Q)))
  saveRDS(pC, file.path(INTERMEDIATE, sprintf("v4_panel_C_Q%d.rds",     Q)))
}

cat("\n=== Summary across Q ===\n")
print(out_summary, row.names = FALSE)
saveRDS(out_summary, file.path(INTERMEDIATE, "v4_event_summary.rds"))
saveRDS(all_events,  file.path(INTERMEDIATE, "v4_all_events.rds"))
cat("\nDone.\n")
