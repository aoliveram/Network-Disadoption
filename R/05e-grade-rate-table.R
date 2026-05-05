# ================================================================
# 05e-grade-rate-table.R  (v4b)
#
# Parallel to §11.1 PFU and §11 E_users tables, but with HIGH-SCHOOL
# GRADE LEVEL on the x-axis. Grade is derived from (cohort, wave):
#
#   class of 2024 (schools 101..114):
#     W1=9  W2=9  W3=10 W4=10 W5=11 W6=11 W7=12 W8=12 W9=postHS W10=postHS
#   class of 2025 (schools 201..214):
#     W3=9  W4=9  W5=10 W6=10 W7=11 W8=11 W9=12 W10=12
#
# Outputs:
#   outputs/tables/v4b_table_11_3_grade.csv
#   outputs/figures/sec11_grade_rates.png
# ================================================================
suppressMessages({
  library(dplyr)
  library(ggplot2)
})
source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

# Map (cohort, wave) -> grade
grade_2024 <- c(`1`="9th",`2`="9th",`3`="10th",`4`="10th",
                `5`="11th",`6`="11th",`7`="12th",`8`="12th",
                `9`="post-HS",`10`="post-HS")
grade_2025 <- c(`3`="9th",`4`="9th",`5`="10th",`6`="10th",
                `7`="11th",`8`="11th",`9`="12th",`10`="12th")

panel$grade <- NA_character_
panel$grade[!is.na(panel$cohort) & panel$cohort == "2024"] <-
  grade_2024[as.character(panel$wave[!is.na(panel$cohort) & panel$cohort == "2024"])]
panel$grade[!is.na(panel$cohort) & panel$cohort == "2025"] <-
  grade_2025[as.character(panel$wave[!is.na(panel$cohort) & panel$cohort == "2025"])]
panel$grade <- factor(panel$grade, levels = c("9th","10th","11th","12th","post-HS"))

# Lag of ecig
panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig)) |>
  ungroup()

# Adoption: at risk = prev_ecig == 0; event = ecig == 1
adopt_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(grade)) |>
  group_by(grade) |>
  summarise(n_adopt = n(),
            rate_adopt_pct = 100 * mean(ecig == 1),
            .groups = "drop")

# Disadoption: at risk = prev_ecig == 1; event = ecig == 0  (any 1->0)
disad_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(grade)) |>
  group_by(grade) |>
  summarise(n_disad = n(),
            rate_disad_pct = 100 * mean(ecig == 0),
            .groups = "drop")

tab <- full_join(adopt_tab, disad_tab, by = "grade") |>
  arrange(grade)

cat("\n==== Rate table by HS grade (any 1->0) ====\n")
print(tab, n = 10)

# Point-biserial / ordered-correlation: encode grade as integer 1..5
grade_to_int <- c("9th"=1, "10th"=2, "11th"=3, "12th"=4, "post-HS"=5)
adopt_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(grade))
adopt_set$grade_int <- grade_to_int[as.character(adopt_set$grade)]
disad_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(grade))
disad_set$grade_int <- grade_to_int[as.character(disad_set$grade)]

r_adopt <- cor(adopt_set$grade_int, as.integer(adopt_set$ecig == 1))
n_adopt <- nrow(adopt_set)
r_disad <- cor(disad_set$grade_int, as.integer(disad_set$ecig == 0))
n_disad <- nrow(disad_set)
cat(sprintf("\nAdoption (any 0->1) vs grade : r = %.3f  (n = %d)\n", r_adopt, n_adopt))
cat(sprintf("Any 1->0           vs grade : r = %.3f  (n = %d)\n", r_disad, n_disad))

write.csv(tab, file.path(TABLES, "v4b_table_11_3_grade.csv"), row.names = FALSE)
saveRDS(list(tab = tab,
             r_adopt = r_adopt, n_adopt = n_adopt,
             r_disad = r_disad, n_disad = n_disad),
        file.path(INTERMEDIATE, "v4b_grade_rate.rds"))

# ----------------------------------------------------------------
# Plot: dual panels — adoption rate (left) and disadoption rate (right)
# ----------------------------------------------------------------
plot_df <- bind_rows(
  tab |> select(grade, n = n_adopt, rate = rate_adopt_pct) |>
    mutate(kind = "Adoption (0→1)"),
  tab |> select(grade, n = n_disad, rate = rate_disad_pct) |>
    mutate(kind = "Disadoption (any 1→0)")
)

p <- ggplot(plot_df, aes(x = grade, y = rate, fill = kind)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%\n(n=%d)", rate, n)),
            vjust = -0.2, size = 3) +
  facet_wrap(~ kind, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = c("Adoption (0→1)" = "#1f77b4",
                                "Disadoption (any 1→0)" = "#2ca02c"),
                    guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
  labs(x = "High-school grade (derived from cohort × wave)", y = "Rate (%)",
       title = "Adoption and disadoption rates by HS grade",
       subtitle = sprintf("Pooled across all valid (record_id, wave) at-risk rows. Disadoption = any 1→0.")) +
  theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave(file.path(FIGURES, "sec11_grade_rates.png"), p,
       width = 9, height = 4.0, dpi = 220)
cat("\nWrote outputs/figures/sec11_grade_rates.png\n")
