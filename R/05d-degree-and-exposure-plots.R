# ================================================================
# 05d-degree-and-exposure-plots.R  (v4b)
#
# Two figures:
#
#   (1) sec2_degree_distribution.pdf — overall in/out-degree
#       distributions across all (record_id, wave) cells (one
#       observation per ego-wave). Goes in §2 Data.
#
#   (2) sec3_per_wave_degree_exposure.pdf — 10 subplots, one per
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

ggsave(file.path(FIGURES, "sec2_degree_distribution.pdf"), p1,
       width = 9, height = 4.0, dpi = 220)
cat("Wrote outputs/figures/sec2_degree_distribution.pdf\n")

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

# Two parallel distributions: out-degree and k_users (count of using
# friends). Both at integer support 0..max_degree.
per_wave_long <- bind_rows(
  per_wave |> select(wave, value = out_deg) |>
    mutate(metric = "Out-degree"),
  per_wave |> select(wave, value = k_users) |>
    mutate(metric = "Adopting friends (k_users)")
)
per_wave_long$metric <- factor(per_wave_long$metric,
                                levels = c("Out-degree",
                                           "Adopting friends (k_users)"))

agg <- per_wave_long |>
  group_by(wave, metric, value) |>
  summarise(n = n(), .groups = "drop")

p2 <- ggplot(agg, aes(x = factor(value), y = n, fill = metric)) +
  geom_col(alpha = 0.55, position = "identity", width = 0.85) +
  facet_wrap(~ wave, ncol = 5,
             labeller = labeller(wave = function(x) sprintf("W%s", x))) +
  scale_fill_manual(name = NULL,
                    values = c("Out-degree" = "#1f77b4",
                                "Adopting friends (k_users)" = "#d62728")) +
  labs(x = "Count (out-degree, or number of friends who currently use ecig)",
       y = "Number of ego-waves",
       title = "Per-wave: out-degree distribution vs distribution of using-friend count",
       subtitle = "Blue: how many ego-waves have each out-degree. Red: how many ego-waves have each count of using friends.") +
  theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec3_per_wave_degree_exposure.pdf"), p2,
       width = 12, height = 5.5, dpi = 200)
cat("Wrote outputs/figures/sec3_per_wave_degree_exposure.pdf\n")
