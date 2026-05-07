# ================================================================
# 05b-section4-figures.R  (v4b)
#
# Figures for §4 "Effective sample size by panel × Q":
#   - sec4_N_full.pdf : students/events overlay, full panels
#   - sec4_N_cc.pdf   : students/events overlay, complete-cases (CC)
#
# Within each PNG: 4 facets (one per outcome panel) and 4 bars per
# facet (one per Q ∈ {5,6,7,8}). Each bar is a single rectangle with
# students plotted at low alpha and events plotted at high alpha so
# the overlap is visible.
# ================================================================

suppressMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})
source(file.path(here::here(), "R", "00-config.R"))

# Numbers from the §4 N table (full / complete-cases).
df <- tibble::tribble(
  ~Q, ~panel,     ~full_n, ~full_e, ~cc_n, ~cc_e,
   8, "Adopters",  1029,    162,     925,   89,
   8, "A",          139,     96,      83,   52,
   8, "B",          158,    142,      91,   70,
   8, "C",          139,     17,      83,    7,
   7, "Adopters",  1930,    346,    1711,  193,
   7, "A",          299,    189,     161,   89,
   7, "B",          346,    293,     182,  129,
   7, "C",          299,     43,     161,   15,
   6, "Adopters",  2441,    449,    2077,  232,
   6, "A",          399,    244,     206,  108,
   6, "B",          461,    384,     233,  159,
   6, "C",          399,     66,     206,   21,
   5, "Adopters",  2919,    551,    2404,  267,
   5, "A",          493,    288,     237,  124,
   5, "B",          568,    467,     271,  185,
   5, "C",          493,     81,     237,   29
)

df$panel <- factor(df$panel, levels = c("Adopters","A","B","C"))
df$Q <- factor(df$Q, levels = c(5,6,7,8))

make_plot <- function(d_long, title) {
  ggplot(d_long, aes(x = Q, y = value, fill = panel)) +
    geom_col(data = subset(d_long, kind == "Students"),
             aes(alpha = "Students"), width = 0.7,
             position = "identity", colour = NA) +
    geom_col(data = subset(d_long, kind == "Events"),
             aes(alpha = "Events"), width = 0.7,
             position = "identity", colour = NA) +
    geom_text(data = subset(d_long, kind == "Students"),
              aes(label = value), vjust = -0.4, size = 2.7) +
    geom_text(data = subset(d_long, kind == "Events"),
              aes(label = value), vjust = 1.4, size = 2.7,
              fontface = "bold") +
    facet_wrap(~ panel, scales = "free_y", nrow = 1) +
    scale_alpha_manual(values = c("Students" = 0.35, "Events" = 0.85),
                       breaks = c("Students","Events"),
                       name = NULL,
                       guide = guide_legend(override.aes = list(fill = "grey30"))) +
    scale_fill_manual(values = c("Adopters" = "#1f77b4",
                                  "A" = "#2ca02c",
                                  "B" = "#ff7f0e",
                                  "C" = "#d62728"),
                       guide = "none") +
    labs(x = "Q (consecutive observed waves)", y = NULL, title = title) +
    theme_bw(base_size = 11) +
    theme(panel.grid.minor = element_blank(),
          legend.position = "bottom",
          plot.title = element_text(face = "bold"))
}

long_full <- df |>
  select(Q, panel, Students = full_n, Events = full_e) |>
  pivot_longer(c(Students, Events), names_to = "kind", values_to = "value")
long_cc <- df |>
  select(Q, panel, Students = cc_n,   Events = cc_e) |>
  pivot_longer(c(Students, Events), names_to = "kind", values_to = "value")

p_full <- make_plot(long_full, "Effective N — full at-risk panel")
p_cc   <- make_plot(long_cc,   "Effective N — after complete.cases on the 13 predictors (CC)")

ggsave(file.path(FIGURES, "sec4_N_full.pdf"), p_full,
       width = 9, height = 3.6, dpi = 220)
ggsave(file.path(FIGURES, "sec4_N_cc.pdf"),   p_cc,
       width = 9, height = 3.6, dpi = 220)

cat("Wrote:\n  ",
    file.path(FIGURES, "sec4_N_full.pdf"), "\n  ",
    file.path(FIGURES, "sec4_N_cc.pdf"), "\n")
