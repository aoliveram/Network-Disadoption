# ================================================================
# 10-figure1-plos.R
#
# Figure 1 for the PLOS ONE revision (Reviewer 2, point 7).
# Replaces the dual-axis line graph of 05e-grade-rate-table.R with two
# stacked panels, each on its own labelled y-axis, with 95% Wilson
# confidence intervals and the number at risk per grade-semester.
# Rates are computed exactly as in 05e (any 0->1 / any 1->0 between
# consecutive calendar waves, pooled across students).
#
# Outputs:
#   outputs/figures/sec11_grade_rates_line.pdf
#   outputs/figures/sec11_grade_rates_line.tif  (PLOS submission, 600 dpi, LZW)
# ================================================================
suppressMessages({
  library(dplyr)
  library(ggplot2)
})
source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

gs_2024 <- c(`1`=1, `2`=2, `3`=3, `4`=4, `5`=5, `6`=6, `7`=7, `8`=8,
             `9`=NA_integer_, `10`=NA_integer_)
gs_2025 <- c(`3`=1, `4`=2, `5`=3, `6`=4, `7`=5, `8`=6, `9`=7, `10`=8)
panel$gs <- NA_integer_
i24 <- !is.na(panel$cohort) & panel$cohort == "2024"
i25 <- !is.na(panel$cohort) & panel$cohort == "2025"
panel$gs[i24] <- as.integer(gs_2024[as.character(panel$wave[i24])])
panel$gs[i25] <- as.integer(gs_2025[as.character(panel$wave[i25])])

panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig)) |>
  ungroup()

wilson <- function(x, n, z = qnorm(0.975)) {
  p <- x / n
  centre <- (p + z^2 / (2 * n)) / (1 + z^2 / n)
  half   <- z * sqrt(p * (1 - p) / n + z^2 / (4 * n^2)) / (1 + z^2 / n)
  cbind(lo = centre - half, hi = centre + half)
}

rates <- function(prev, event_val, label) {
  panel |>
    filter(!is.na(prev_ecig), prev_ecig == prev, !is.na(ecig), !is.na(gs)) |>
    group_by(gs) |>
    summarise(n = n(), x = sum(ecig == event_val), .groups = "drop") |>
    mutate(rate = x / n, kind = label) |>
    (\(d) cbind(d, wilson(d$x, d$n)))()
}
plot_df <- bind_rows(
  rates(0, 1, "A. Adoption (non-user to user)"),
  rates(1, 0, "B. Disadoption (user to non-user)")
)
print(plot_df)

# Per-point vertical offset of the % labels (in percentage points), chosen
# so each label sits on the side of the point away from the outgoing line
# segment. Order: gs = 2..8.
label_dy <- list(
  "A. Adoption (non-user to user)"    = c(-0.55, -0.55, 0.55, -0.55, 0.55, 0.55, 0.55),
  "B. Disadoption (user to non-user)" = c(4.5, -4.5, -4.5, 4.5, -4.5, 4.5, 4.5)
)
plot_df$label_y <- 100 * plot_df$rate +
  unlist(lapply(split(plot_df, plot_df$kind), function(d) label_dy[[d$kind[1]]][d$gs - 1]))

gs_label <- c("Fall\n9th", "Spring\n9th", "Fall\n10th", "Spring\n10th",
              "Fall\n11th", "Spring\n11th", "Fall\n12th", "Spring\n12th")

kind_col <- c("A. Adoption (non-user to user)"    = "#1f77b4",
              "B. Disadoption (user to non-user)" = "#2ca02c")

p <- ggplot(plot_df, aes(x = gs, y = 100 * rate, colour = kind)) +
  geom_errorbar(aes(ymin = 100 * lo, ymax = 100 * hi),
                width = 0.15, alpha = 0.6) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.4) +
  geom_text(aes(y = label_y, label = sprintf("%.1f%%", 100 * rate)),
            nudge_x = 0.12, hjust = 0, size = 3) +
  geom_text(aes(y = -Inf, label = sprintf("n = %s", formatC(n, big.mark = ",", format = "d"))),
            vjust = -0.6, size = 2.7, colour = "grey35") +
  scale_colour_manual(values = kind_col, guide = "none") +
  facet_wrap(~ kind, ncol = 1, scales = "free_y") +
  scale_x_continuous(breaks = 2:8, labels = gs_label[2:8],
                     expand = expansion(add = c(0.4, 0.6))) +
  scale_y_continuous(limits = c(0, NA),
                     expand = expansion(mult = c(0.12, 0.12))) +
  labs(x = "High-school grade-semester",
       y = "Rate among students at risk (%)") +
  theme_bw(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.background = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0, size = 10))

ggsave(file.path(FIGURES, "sec11_grade_rates_line.pdf"), p, width = 5.2, height = 5.2)
ggsave(file.path(FIGURES, "sec11_grade_rates_line.tif"), p, width = 5.2, height = 5.2,
       dpi = 600, compression = "lzw")
cat("Wrote outputs/figures/sec11_grade_rates_line.{pdf,tif}\n")
