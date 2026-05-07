# ================================================================
# 05h-Q-sensitivity.R  (v4b)
#
# §11.5 inputs: how do N students and N events change as we
# tighten Q from 5 to 10? Helps us pick the Q that balances
# complete-case restriction and event count.
#
# For Q in 5..10, for each disadoption outcome A / B / C (with
# C window=1), compute:
#   - N students at risk        (FULL panel)
#   - N events                  (FULL panel)
#   - N students after CC       (regression-ready panel)
#   - N events after CC         (regression-ready panel)
#
# Predictor set = the 13-variable v4b PRED list.
#
# Outputs:
#   outputs/tables/v4b_table_11_5_Q_sensitivity.csv
#   outputs/figures/sec11_Q_sensitivity.pdf
# ================================================================
suppressMessages({
  library(dplyr); library(ggplot2); library(tidyr)
})
source(file.path(here::here(), "R", "00-config.R"))

panel    <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))
panel    <- panel[order(panel$record_id, panel$wave), ]
WAVES    <- 1:10

# Build wide ecig matrix
all_ids <- sort(unique(panel$record_id))
ecig_w  <- matrix(NA_integer_, nrow = length(all_ids), ncol = length(WAVES),
                  dimnames = list(all_ids, paste0("w", WAVES)))
for (k in seq_len(nrow(panel))) {
  if (!is.na(panel$ecig[k]))
    ecig_w[panel$record_id[k], panel$wave[k]] <- as.integer(panel$ecig[k])
}

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
ecig_obs   <- split(panel$wave[!is.na(panel$ecig)],
                    panel$record_id[!is.na(panel$ecig)])
max_consec <- vapply(ecig_obs, longest_consec, integer(1))

# Lag/lead within record_id
panel$ecig_prev <- ave(panel$ecig, panel$record_id,
                       FUN = function(x) c(NA, x[-length(x)]))

# Network features per (record_id, wave-1) — same logic as
# 03-network-features.R::attach_features
attach_lagged_feats <- function(p) {
  rid_chr <- as.character(p$record_id); pw <- p$wave - 1L
  good <- pw >= 1 & pw <= length(WAVES)
  out <- list(
    out_degree = rep(NA_integer_, nrow(p)),
    in_degree  = rep(NA_integer_, nrow(p)),
    E_users    = rep(NA_real_, nrow(p)),
    E_dis      = rep(NA_real_, nrow(p)),
    E_D_alt    = rep(NA_real_, nrow(p))
  )
  for (i in which(good)) {
    rid <- rid_chr[i]; w <- pw[i]
    if (rid %in% rownames(features$out_deg)) {
      out$out_degree[i] <- features$out_deg[rid, w]
      out$in_degree[i]  <- features$in_deg[rid, w]
      out$E_users[i]    <- features$E_users[rid, w]
      out$E_dis[i]      <- features$E_dis[rid, w]
      out$E_D_alt[i]    <- features$E_D_alt[rid, w]
    }
  }
  fue <- with(panel, setNames(friends_use_ecig,
                              paste(record_id, wave, sep = "_")))
  out$friends_use_ecig_lag <- as.numeric(
    fue[paste(p$record_id, pw, sep = "_")])
  cbind(p, as.data.frame(out, stringsAsFactors = FALSE))
}

# Predictor set (mirrors PRED in R/04-regressions.R)
PRED <- c("cohort", "female", "sex_minority", "par_edu",
          "asian", "hispanic", "mdd", "gad",
          "out_degree", "in_degree",
          "friends_use_ecig_lag", "E_users", "E_dis")  # using E_dis as the §5 default

# Build A / B / C panels for one Q (FULL + CC student/event counts)
build_counts_for_Q <- function(Q) {
  ids <- names(max_consec)[max_consec >= Q]
  pq  <- panel[panel$record_id %in% ids, ]
  rs10 <- pq[!is.na(pq$ecig_prev) & pq$ecig_prev == 1 & !is.na(pq$ecig), ]

  obs_per_id <- split(pq$wave[!is.na(pq$ecig)],
                      pq$record_id[!is.na(pq$ecig)])
  has_future <- vapply(seq_len(nrow(rs10)), function(i)
    any(obs_per_id[[as.character(rs10$record_id[i])]] > rs10$wave[i]),
    logical(1))

  # Future observations matrix per ego, used for A / C definitions
  ecig_sub <- ecig_w[ids, , drop = FALSE]
  ev_A <- ev_B <- ev_C <- character(0)
  for (i in seq_len(nrow(ecig_sub))) {
    rid <- rownames(ecig_sub)[i]; v <- ecig_sub[i, ]
    f10 <- FALSE
    for (k in 2:length(v)) {
      if (is.na(v[k]) || is.na(v[k-1])) next
      if (v[k-1] == 1 && v[k] == 0) {
        key <- paste(rid, k, sep = "_")
        if (!f10) { ev_B <- c(ev_B, key); f10 <- TRUE }
        future_obs <- which(!is.na(v))
        future_obs <- future_obs[future_obs > k]
        if (length(future_obs) > 0 && v[future_obs[1]] == 1)
          ev_C <- c(ev_C, key)
        if (length(future_obs) > 0 && !any(v[future_obs] == 1, na.rm = TRUE))
          ev_A <- c(ev_A, key)
      }
    }
  }

  pA <- rs10[has_future, ]
  pA$event <- as.integer(paste(pA$record_id, pA$wave, sep="_") %in% ev_A)

  # B: walk forward per student until first 1->0 (incl event row)
  pB_rows <- list()
  for (rid in unique(rs10$record_id)) {
    sub <- rs10[rs10$record_id == rid, ]
    sub <- sub[order(sub$wave), ]
    sub$event <- as.integer(paste(sub$record_id, sub$wave, sep = "_") %in% ev_B)
    ev_idx <- which(sub$event == 1)
    end_at <- if (length(ev_idx)) ev_idx[1] else nrow(sub)
    pB_rows[[length(pB_rows)+1]] <- sub[seq_len(end_at), ]
  }
  pB <- if (length(pB_rows)) do.call(rbind, pB_rows) else rs10[FALSE, ]

  pC <- rs10[has_future, ]
  pC$event <- as.integer(paste(pC$record_id, pC$wave, sep="_") %in% ev_C)

  out <- list()
  for (kind in c("A","B","C")) {
    p <- get(paste0("p", kind))
    if (nrow(p) == 0) {
      out[[kind]] <- data.frame(Q = Q, outcome = kind,
        full_n = 0, full_ev = 0, cc_n = 0, cc_ev = 0)
      next
    }
    # FULL counts
    full_n  <- length(unique(p$record_id))
    full_ev <- sum(p$event, na.rm = TRUE)
    # Attach features and complete-case
    p2 <- attach_lagged_feats(p)
    p2$cohort <- as.integer(p2$cohort == "2025")
    cc <- complete.cases(p2[, PRED, drop = FALSE])
    cc_p <- p2[cc, ]
    cc_n  <- length(unique(cc_p$record_id))
    cc_ev <- sum(cc_p$event, na.rm = TRUE)
    out[[kind]] <- data.frame(Q = Q, outcome = kind,
      full_n = full_n, full_ev = full_ev, cc_n = cc_n, cc_ev = cc_ev)
  }
  do.call(rbind, out)
}

cat("Computing Q-sensitivity table (Q = 4..8)...\n")
all_rows <- list()
for (Q in 4:8) {
  cat(sprintf("  Q = %d\n", Q))
  all_rows[[length(all_rows) + 1]] <- build_counts_for_Q(Q)
}
tab <- do.call(rbind, all_rows)
cat("\n=== Q-sensitivity (FULL and CC) ===\n")
print(tab, row.names = FALSE)
write.csv(tab, file.path(TABLES, "v4b_table_11_5_Q_sensitivity.csv"),
          row.names = FALSE)

# ----------------------------------------------------------------
# Plot: 3 stacked subplots (one per outcome A/B/C). Each subplot has
# two lines: students (CC) and events (CC). x-axis runs Q = 8..4
# (descending). Annotate % change between consecutive Q steps and
# bold the steepest single-step drop per metric.
# ----------------------------------------------------------------
plot_df <- tab |>
  select(Q, outcome, Students = cc_n, Events = cc_ev) |>
  pivot_longer(c(Students, Events), names_to = "metric", values_to = "value")
plot_df$outcome <- factor(plot_df$outcome, levels = c("A","B","C"),
                          labels = c("A — Stable disadoption",
                                     "B — Experimental",
                                     "C — Unstable / cyclic"))

# Per-step % gain when relaxing one Q step (going from Q+1 down to Q,
# i.e., comparing each Q to the immediately stricter previous Q).
# At Q = 8 there is no previous (stricter) Q to compare, so the label
# is empty there. Q = 7 is highlighted as the recommended sweet spot.
gain_df <- plot_df |>
  arrange(outcome, metric, desc(Q)) |>
  group_by(outcome, metric) |>
  mutate(prev_value = dplyr::lag(value),
         gain_pct   = ifelse(is.na(prev_value) | prev_value == 0, NA_real_,
                             100 * (value - prev_value) / prev_value),
         is_q7      = Q == 7) |>
  ungroup()
gain_df$gain_lbl <- ifelse(is.na(gain_df$gain_pct), "",
                           sprintf("%+.0f%%", gain_df$gain_pct))

p <- ggplot(plot_df, aes(x = Q, y = value, colour = metric, group = metric)) +
  geom_line(linewidth = 1.0) +
  geom_point(size = 2.4) +
  geom_text(aes(label = value), vjust = -0.9, size = 3, show.legend = FALSE) +
  geom_text(data = subset(gain_df, !is_q7 & gain_lbl != ""),
            aes(label = gain_lbl),
            vjust = 1.9, size = 2.7, show.legend = FALSE) +
  geom_text(data = subset(gain_df, is_q7 & gain_lbl != ""),
            aes(label = gain_lbl),
            vjust = 1.9, size = 3.4, fontface = "bold", show.legend = FALSE) +
  facet_wrap(~ outcome, ncol = 1, scales = "free_y") +
  scale_x_reverse(breaks = 4:8) +
  scale_y_continuous(expand = expansion(mult = c(0.18, 0.18))) +
  scale_colour_manual(values = c("Students" = "#1f77b4",
                                  "Events"   = "#d62728"),
                      name = NULL) +
  labs(x = "Q (minimum consecutive observed waves of past_6mo_use_3) — strict ← → relaxed",
       y = "Count after complete.cases (CC)",
       title = "Q sensitivity: how N students and N events shrink as Q tightens",
       subtitle = "After complete-case filter on the 13 predictors. Numbers below each point = % gain vs the immediately stricter Q. The bold highlight is Q=7, our recommended sweet spot.") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(face = "bold"),
        strip.text = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec11_Q_sensitivity.pdf"), p,
       width = 6.5, height = 8.0, dpi = 220)
cat("\nWrote outputs/figures/sec11_Q_sensitivity.pdf\n")
