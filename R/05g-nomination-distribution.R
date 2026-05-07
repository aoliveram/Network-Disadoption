# ================================================================
# 05g-nomination-distribution.R  (v4b)
#
# §11.4 inputs: distribution of out-degree (number of friends an ego
# nominated) across all valid ego-waves, partitioned by the ego's
# current e-cig status.
#
# Three distributions:
#   - All ego-waves with valid out-degree
#   - Ego-waves where ecig = 1 at the same wave (current users)
#   - Ego-waves where ecig = 0 at the same wave (current non-users)
#
# Outputs:
#   outputs/tables/v4b_table_11_4_outdegree_distribution.csv
#   outputs/figures/sec11_outdegree_distribution.pdf
# ================================================================
suppressMessages({
  library(dplyr); library(ggplot2); library(tidyr)
})
source(file.path(here::here(), "R", "00-config.R"))

panel    <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))
out_deg  <- features$out_deg

# Long-form: one row per (record_id, wave) with out_degree at that wave
ids <- rownames(out_deg); waves <- 1:10
deg_long <- data.frame(
  record_id = rep(ids, times = length(waves)),
  wave      = rep(waves, each = length(ids)),
  out_deg   = as.vector(out_deg),
  stringsAsFactors = FALSE
)

# Attach ego's current ecig status from the panel
ec_lookup <- with(panel, setNames(ecig, paste(record_id, wave, sep = "_")))
deg_long$ecig <- as.integer(ec_lookup[paste(deg_long$record_id, deg_long$wave,
                                              sep = "_")])

# Subset to valid (ego-wave with at least one nominated friend in the panel)
deg_valid <- deg_long |> filter(out_deg > 0)

# Three subsets
all_set    <- deg_valid
user_set   <- deg_valid |> filter(!is.na(ecig), ecig == 1)
nonusr_set <- deg_valid |> filter(!is.na(ecig), ecig == 0)

# Per-degree count + share, for each subset
make_dist <- function(d, label) {
  d |>
    group_by(out_deg) |>
    summarise(n = n(), .groups = "drop") |>
    mutate(share = n / sum(n), subset = label)
}
dist_all <- make_dist(all_set, "All ego-waves")
dist_u   <- make_dist(user_set, "Current user (ecig=1)")
dist_n   <- make_dist(nonusr_set, "Current non-user (ecig=0)")

# Combined wide table for the report
tab <- dist_all |> select(out_deg, n_all = n) |>
  full_join(dist_u  |> select(out_deg, n_user    = n), by = "out_deg") |>
  full_join(dist_n  |> select(out_deg, n_nonuser = n), by = "out_deg") |>
  arrange(out_deg)
tab[is.na(tab)] <- 0L

cat("\n==== Out-degree distribution by ego status ====\n")
print(tab, n = 10)

# Summary stats
cat(sprintf("\nN ego-waves (with out_deg > 0)         : %d\n",   nrow(all_set)))
cat(sprintf("  ... where ecig observed AND = 1       : %d\n", nrow(user_set)))
cat(sprintf("  ... where ecig observed AND = 0       : %d\n", nrow(nonusr_set)))
cat(sprintf("Mean out-degree (all)        : %.2f\n", mean(all_set$out_deg)))
cat(sprintf("Mean out-degree (users)      : %.2f\n", mean(user_set$out_deg)))
cat(sprintf("Mean out-degree (non-users)  : %.2f\n", mean(nonusr_set$out_deg)))
cat(sprintf("Median out-degree (all)      : %.0f\n", median(all_set$out_deg)))
cat(sprintf("Median out-degree (users)    : %.0f\n", median(user_set$out_deg)))
cat(sprintf("Median out-degree (non-users): %.0f\n", median(nonusr_set$out_deg)))

write.csv(tab, file.path(TABLES, "v4b_table_11_4_outdegree_distribution.csv"),
          row.names = FALSE)

# Plot: three overlaid histograms (alpha = 0.5) on the SAME axes,
# normalised to relative frequency so the three subsets can be
# compared on the same scale.
plot_df <- bind_rows(dist_all, dist_u, dist_n)
plot_df$subset <- factor(plot_df$subset,
                          levels = c("All ego-waves",
                                     "Current non-user (ecig=0)",
                                     "Current user (ecig=1)"))

p <- ggplot(plot_df, aes(x = factor(out_deg), y = share, fill = subset)) +
  geom_col(alpha = 0.65, position = position_dodge(width = 0.8),
           width = 0.75) +
  geom_text(aes(label = sprintf("%d", n)),
            position = position_dodge(width = 0.8),
            vjust = -0.3, size = 2.6) +
  scale_fill_manual(values = c(
    "All ego-waves"             = "#7f7f7f",
    "Current non-user (ecig=0)" = "#1f77b4",
    "Current user (ecig=1)"     = "#d62728")) +
  scale_y_continuous(labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.12))) +
  labs(x = "Out-degree (number of nominated friends in the panel)",
       y = "Share of ego-waves at this degree",
       title = "Out-degree distribution by ego e-cigarette status",
       subtitle = "Pooled across W1-W10. Bars show share within each subset; numbers above bars are raw n.",
       fill = NULL) +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        plot.title = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec11_outdegree_distribution.pdf"), p,
       width = 10, height = 4.4, dpi = 220)
cat("\nWrote outputs/figures/sec11_outdegree_distribution.pdf\n")
