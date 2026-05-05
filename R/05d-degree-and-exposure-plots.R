# ================================================================
# 05d-degree-and-exposure-plots.R  (v4b)
#
# Two figures:
#
#   (1) sec2_degree_distribution.png — overall in/out-degree
#       distributions across all (record_id, wave) cells (one
#       observation per ego-wave). Goes in §2 Data.
#
#   (2) sec3_per_wave_degree_exposure.png — 10 subplots, one per
#       wave. Each subplot shows:
#         - histogram of out-degree at that wave
#         - overlaid scatter (or 2nd-axis) of "k_users" =
#           E_users * out_degree (count of using friends) at that
#           wave, faceted by degree.
#       Goes in §3 Event Definitions.
# ================================================================

suppressMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})
source(file.path(here::here(), "R", "00-config.R"))

panel    <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))

out_deg <- features$out_deg
in_deg  <- features$in_deg
E_users <- features$E_users

waves <- 1:10
ids   <- rownames(out_deg)

# ----------------------------------------------------------------
# Figure 1: Overall in/out degree distributions (pooled across waves)
# ----------------------------------------------------------------
deg_df <- bind_rows(
  data.frame(record_id = rep(ids, times = length(waves)),
             wave      = rep(waves, each = length(ids)),
             value     = as.vector(out_deg),
             kind      = "Out-degree"),
  data.frame(record_id = rep(ids, times = length(waves)),
             wave      = rep(waves, each = length(ids)),
             value     = as.vector(in_deg),
             kind      = "In-degree")
) |>
  filter(value > 0)   # drop person-waves with no edges (alter not in panel)

p1 <- ggplot(deg_df, aes(x = value, fill = kind)) +
  geom_histogram(binwidth = 1, alpha = 0.65, position = "identity",
                 colour = "white", linewidth = 0.1) +
  facet_wrap(~ kind, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c("Out-degree" = "#1f77b4",
                                "In-degree"  = "#d62728"),
                    guide = "none") +
  scale_x_continuous(breaks = seq(0, 25, by = 2)) +
  labs(x = "Degree (per ego-wave, edges with valid alter only)",
       y = "Count of ego-wave observations",
       title = "Friendship-nomination degree distribution",
       subtitle = sprintf("Pooled across W1-W10. n = %d ego-waves with non-zero degree.",
                          nrow(deg_df))) +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec2_degree_distribution.png"), p1,
       width = 9, height = 4.0, dpi = 220)
cat("Wrote outputs/figures/sec2_degree_distribution.png\n")

# Also print summary statistics
out_deg_v <- as.vector(out_deg); out_deg_v <- out_deg_v[out_deg_v > 0]
in_deg_v  <- as.vector(in_deg);  in_deg_v  <- in_deg_v[in_deg_v > 0]
cat(sprintf("  Out-degree: median=%g, mean=%.2f, max=%d, n=%d\n",
            median(out_deg_v), mean(out_deg_v), max(out_deg_v), length(out_deg_v)))
cat(sprintf("  In-degree:  median=%g, mean=%.2f, max=%d, n=%d\n",
            median(in_deg_v),  mean(in_deg_v),  max(in_deg_v),  length(in_deg_v)))

# ----------------------------------------------------------------
# Figure 2: Per-wave degree distribution + count of using friends
# ----------------------------------------------------------------
# k_users = E_users * out_degree = number of alters who use ecig at wave w
# We round to nearest integer because the count is what we want.
n_users_mat <- round(E_users * out_deg)
n_users_mat[is.na(E_users)] <- NA_integer_

per_wave <- bind_rows(lapply(waves, function(w) {
  od <- out_deg[, w]
  ku <- n_users_mat[, w]
  data.frame(wave      = w,
             out_deg   = as.integer(od),
             k_users   = as.integer(ku))
})) |>
  filter(out_deg > 0) |>          # only egos with at least one alter
  filter(!is.na(k_users))         # only ego-waves with E_users defined

# Cap degree at 12 for visualisation (very few above)
per_wave$out_deg_cap <- pmin(per_wave$out_deg, 12L)

# We compute degree counts and average k_users per (wave, degree) cell.
agg <- per_wave |>
  group_by(wave, out_deg_cap) |>
  summarise(n         = n(),
            mean_k_u  = mean(k_users),
            .groups   = "drop")

# Build double-axis: bars for degree count (left axis), points/line for
# mean k_users (right axis, scaled).
max_n   <- max(agg$n)
max_kmu <- max(agg$mean_k_u, na.rm = TRUE)
scale_k <- max_n / max_kmu

p2 <- ggplot(agg, aes(x = factor(out_deg_cap))) +
  geom_col(aes(y = n, fill = "Out-degree count"),
           alpha = 0.5, width = 0.8) +
  geom_point(aes(y = mean_k_u * scale_k, colour = "Mean # using friends"),
             size = 1.8) +
  geom_line(aes(y = mean_k_u * scale_k,
                colour = "Mean # using friends",
                group  = wave),
            linewidth = 0.5) +
  facet_wrap(~ wave, ncol = 5,
             labeller = labeller(wave = function(x) sprintf("W%s", x))) +
  scale_y_continuous(
    name = "Number of ego-waves",
    sec.axis = sec_axis(~ . / scale_k,
                        name = "Mean # of using friends (k_users)")
  ) +
  scale_fill_manual(name = NULL, values = c("Out-degree count" = "#1f77b4")) +
  scale_colour_manual(name = NULL, values = c("Mean # using friends" = "#d62728")) +
  labs(x = "Out-degree (capped at 12)",
       title = "Per-wave degree distribution and average peer-user count",
       subtitle = "Bars: count of ego-waves at each out-degree. Red line: mean number of alters who currently use ecig.") +
  theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        axis.title.y.right = element_text(colour = "#d62728"),
        axis.text.y.right  = element_text(colour = "#d62728"),
        axis.title.y.left  = element_text(colour = "#1f77b4"),
        axis.text.y.left   = element_text(colour = "#1f77b4"),
        plot.title = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec3_per_wave_degree_exposure.png"), p2,
       width = 12, height = 5.5, dpi = 200)
cat("Wrote outputs/figures/sec3_per_wave_degree_exposure.png\n")
