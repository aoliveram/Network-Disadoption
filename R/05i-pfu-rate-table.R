# ================================================================
# 05i-pfu-rate-table.R
#
# Paper Table 3: adoption and quit rates by perceived friend use
# (PFU = "How many of your five closest friends use any e-cigarette",
# 0..5, "Not sure" -> NA) at w-1. Same shape as the k_users table of
# 05f (paper Table 4), plus a Cochran-Armitage trend test on the quit
# proportions.
#
# Bins: 0, 1, 2, 3, 4, 5.
# Includes BOTH the at-risk denominators AND the event counts so
# the rate (= events / at-risk) is auditable per cell.
#
# Output: outputs/tables/table3_pfu_rates.csv
# ================================================================
suppressMessages({ library(dplyr) })
source(file.path(here::here(), "R", "00-config.R"))

panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]
panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig),
         pfu_lag   = lag(friends_use_ecig)) |>
  ungroup()
panel$pfu_bin <- factor(panel$pfu_lag, levels = 0:5)

# Adoption: at risk = prev_ecig == 0; event = ecig == 1
adopt_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(pfu_bin)) |>
  group_by(pfu_bin) |>
  summarise(n_adopt   = n(),
            n_event_a = sum(ecig == 1),
            rate_adopt = mean(ecig == 1),
            .groups   = "drop")

# Disadoption: at risk = prev_ecig == 1; event = ecig == 0  (any 1->0)
disad_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(pfu_bin)) |>
  group_by(pfu_bin) |>
  summarise(n_disad   = n(),
            n_event_d = sum(ecig == 0),
            rate_disad_pct = 100 * mean(ecig == 0),
            .groups   = "drop")

tab <- full_join(adopt_tab, disad_tab, by = "pfu_bin") |> arrange(pfu_bin)

# Cochran-Armitage trend test on the quit proportions across PFU bins
ca <- prop.trend.test(tab$n_event_d, tab$n_disad, score = 0:5)

cat("\n==== Rate table (perceived friend use at w-1) ====\n")
print(tab, n = 10)
cat(sprintf("\nCochran-Armitage trend test (quit rate): X-squared = %.1f, df = %d, p = %.2g\n",
            ca$statistic, ca$parameter, ca$p.value))

write.csv(tab, file.path(TABLES, "table3_pfu_rates.csv"), row.names = FALSE)
cat("\nWrote outputs/tables/table3_pfu_rates.csv\n")
