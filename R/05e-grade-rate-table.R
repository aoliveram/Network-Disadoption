# ================================================================
# 05e-grade-rate-table.R  (v4b)
#
# Parallel to §11.1 PFU and E_users tables, but with HIGH-SCHOOL
# GRADE-SEMESTER on the x-axis (8 bins per Tom's request: "histograms
# of quit rates ... should have 8 categories not 4").
#
# Mapping (cohort, wave) -> grade-semester:
#   class of 2024 (schools 101..114):
#     W1=1 fall9   W2=2 spr9   W3=3 fall10 W4=4 spr10
#     W5=5 fall11  W6=6 spr11  W7=7 fall12 W8=8 spr12
#     W9, W10 = post-HS
#   class of 2025 (schools 201..214):
#     W3=1 fall9   W4=2 spr9   W5=3 fall10 W6=4 spr10
#     W7=5 fall11  W8=6 spr11  W9=7 fall12 W10=8 spr12
#
# Outputs:
#   outputs/tables/v4b_table_11_3_grade.csv
#   outputs/figures/sec11_grade_rates.pdf    (8-bin bar version)
#   outputs/figures/sec11_grade_rates_line.pdf (line-graph version)
# ================================================================
suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(tidyr)
})
source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

# (cohort, wave) -> grade-semester index
gs_2024 <- c(`1`=1, `2`=2, `3`=3, `4`=4, `5`=5, `6`=6, `7`=7, `8`=8,
             `9`=NA_integer_, `10`=NA_integer_)
gs_2025 <- c(`3`=1, `4`=2, `5`=3, `6`=4, `7`=5, `8`=6, `9`=7, `10`=8)

panel$gs <- NA_integer_
i24 <- !is.na(panel$cohort) & panel$cohort == "2024"
i25 <- !is.na(panel$cohort) & panel$cohort == "2025"
panel$gs[i24] <- as.integer(gs_2024[as.character(panel$wave[i24])])
panel$gs[i25] <- as.integer(gs_2025[as.character(panel$wave[i25])])

# Human-readable labels for the 8 semesters
gs_label <- c("1\nfall 9", "2\nspr 9", "3\nfall 10", "4\nspr 10",
              "5\nfall 11", "6\nspr 11", "7\nfall 12", "8\nspr 12")
panel$gs_lab <- factor(panel$gs, levels = 1:8, labels = gs_label)

# Lag of ecig
panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig)) |>
  ungroup()

# Adoption / disadoption per gs
adopt_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(gs)) |>
  group_by(gs, gs_lab) |>
  summarise(n_adopt   = n(),
            n_event_a = sum(ecig == 1),
            rate_adopt_pct = 100 * mean(ecig == 1),
            .groups = "drop")
disad_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(gs)) |>
  group_by(gs, gs_lab) |>
  summarise(n_disad   = n(),
            n_event_d = sum(ecig == 0),
            rate_disad_pct = 100 * mean(ecig == 0),
            .groups = "drop")

tab <- full_join(adopt_tab, disad_tab, by = c("gs","gs_lab")) |>
  arrange(gs)

cat("\n==== Rate table by HS grade-semester (any 1->0) ====\n")
print(tab, n = 10)

# Continuous correlations on integer gs scale
adopt_set <- panel |> filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(gs))
disad_set <- panel |> filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(gs))
r_adopt <- cor(adopt_set$gs, as.integer(adopt_set$ecig == 1))
r_disad <- cor(disad_set$gs, as.integer(disad_set$ecig == 0))
cat(sprintf("\nAdoption (any 0->1) vs gs : r = %.3f  (n = %d)\n", r_adopt, nrow(adopt_set)))
cat(sprintf("Any 1->0           vs gs : r = %.3f  (n = %d)\n", r_disad, nrow(disad_set)))

write.csv(tab, file.path(TABLES, "v4b_table_11_3_grade.csv"), row.names = FALSE)
saveRDS(list(tab = tab,
             r_adopt = r_adopt, n_adopt = nrow(adopt_set),
             r_disad = r_disad, n_disad = nrow(disad_set)),
        file.path(INTERMEDIATE, "v4b_grade_rate.rds"))

# ---------------------------------------------------------------
# (a) Bar plot — 8 grade-semester bins, faceted by outcome
# ---------------------------------------------------------------
plot_df <- bind_rows(
  tab |> select(gs, gs_lab, n = n_adopt, rate = rate_adopt_pct) |>
    mutate(kind = "Adoption (0→1)"),
  tab |> select(gs, gs_lab, n = n_disad, rate = rate_disad_pct) |>
    mutate(kind = "Disadoption (any 1→0)")
)

p_bar <- ggplot(plot_df, aes(x = gs_lab, y = rate, fill = kind)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%\n(n=%d)", rate, n)),
            vjust = -0.2, size = 2.7) +
  facet_wrap(~ kind, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c("Adoption (0→1)" = "#1f77b4",
                                "Disadoption (any 1→0)" = "#2ca02c"),
                    guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = "HS grade-semester (1 = fall 9th, 8 = spring 12th)",
       y = "Rate (%)",
       title = "Adoption and disadoption rates by HS grade-semester",
       subtitle = "Pooled across all valid (record_id, wave) at-risk rows. Disadoption = any 1→0.") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        axis.text.x = element_text(size = 8))

ggsave(file.path(FIGURES, "sec11_grade_rates.pdf"), p_bar,
       width = 10, height = 4.0, dpi = 220)
cat("\nWrote outputs/figures/sec11_grade_rates.pdf\n")

# ---------------------------------------------------------------
# (b) Line graph — both rates on the same plot, dual y-axes
# ---------------------------------------------------------------
# Use a scaling trick so adoption (small %) and disadoption (large %)
# share the x-axis with two y-axes that line up cleanly.
max_a <- max(tab$rate_adopt_pct)
max_d <- max(tab$rate_disad_pct)
scale_factor <- max_d / max_a

p_line <- ggplot(tab, aes(x = gs)) +
  geom_line(aes(y = rate_adopt_pct * scale_factor,
                colour = "Adoption (0→1)"),
            linewidth = 1.1) +
  geom_point(aes(y = rate_adopt_pct * scale_factor,
                 colour = "Adoption (0→1)"), size = 2.6) +
  geom_text(aes(y = rate_adopt_pct * scale_factor,
                label = sprintf("%.1f%%", rate_adopt_pct)),
            colour = "#1f77b4", vjust = -1.0, size = 3) +
  geom_line(aes(y = rate_disad_pct,
                colour = "Disadoption (any 1→0)"),
            linewidth = 1.1) +
  geom_point(aes(y = rate_disad_pct,
                 colour = "Disadoption (any 1→0)"), size = 2.6) +
  geom_text(aes(y = rate_disad_pct,
                label = sprintf("%.1f%%", rate_disad_pct)),
            colour = "#2ca02c", vjust = 1.7, size = 3) +
  scale_x_continuous(breaks = 1:8, labels = gs_label) +
  scale_y_continuous(
    name = "Disadoption rate (%)",
    sec.axis = sec_axis(~ . / scale_factor, name = "Adoption rate (%)"),
    expand = expansion(mult = c(0.08, 0.10))
  ) +
  scale_colour_manual(name = NULL,
                      values = c("Adoption (0→1)" = "#1f77b4",
                                  "Disadoption (any 1→0)" = "#2ca02c")) +
  labs(x = "HS grade-semester (1 = fall 9th, 8 = spring 12th)",
       title = "Adoption and disadoption trajectories across the high-school years",
       subtitle = "Adoption (blue) follows an inverted-U with the peak around fall 11th. Disadoption (green) drifts up from 9th to 12th.") +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom",
        axis.title.y.left  = element_text(colour = "#2ca02c"),
        axis.text.y.left   = element_text(colour = "#2ca02c"),
        axis.title.y.right = element_text(colour = "#1f77b4"),
        axis.text.y.right  = element_text(colour = "#1f77b4"),
        plot.title = element_text(face = "bold"),
        axis.text.x = element_text(size = 8))

ggsave(file.path(FIGURES, "sec11_grade_rates_line.pdf"), p_line,
       width = 10, height = 4.6, dpi = 220)
cat("Wrote outputs/figures/sec11_grade_rates_line.pdf\n")
