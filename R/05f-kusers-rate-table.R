# ================================================================
# 05f-kusers-rate-table.R  (v4b)
#
# Same shape as §11.1's PFU and E_users rate tables, but binned by
# the COUNT of using friends k_users = round(E_users * out_degree)
# at w-1 (Tom's request: "break it down by a count of the number of
# alters rather than the proportion").
#
# Bins: 0, 1, 2, 3, 4, 5+  (matches the 0-5 range of PFU).
# Includes BOTH the at-risk denominators AND the event counts so
# the rate (= events / at-risk) is auditable per cell.
#
# Output: outputs/tables/v4b_table_11_1_kusers.csv
# ================================================================
suppressMessages({ library(dplyr) })
source(file.path(here::here(), "R", "00-config.R"))

panel    <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))
out_deg  <- features$out_deg
E_users  <- features$E_users

# Build a long table linking each (record_id, wave) to k_users at w-1
n_users_mat <- round(E_users * out_deg)
panel <- panel[order(panel$record_id, panel$wave), ]
panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig)) |>
  ungroup()

# Attach k_users at (record_id, wave-1)
prev_w  <- panel$wave - 1L
key_lag <- paste(panel$record_id, prev_w, sep = "_")
ku_long <- as.data.frame(as.table(n_users_mat), stringsAsFactors = FALSE)
names(ku_long) <- c("record_id", "wave_lab", "k_users_w")
ku_long$wave <- as.integer(sub("^w", "", ku_long$wave_lab))
ku_lookup <- with(ku_long,
                  setNames(k_users_w, paste(record_id, wave, sep = "_")))
panel$k_users_lag <- as.numeric(ku_lookup[key_lag])

# Bin k_users_lag into 0, 1, 2, 3, 4, 5+
bin_ku <- function(x) {
  out <- rep(NA_character_, length(x))
  out[!is.na(x) & x == 0] <- "0"
  out[!is.na(x) & x == 1] <- "1"
  out[!is.na(x) & x == 2] <- "2"
  out[!is.na(x) & x == 3] <- "3"
  out[!is.na(x) & x == 4] <- "4"
  out[!is.na(x) & x >= 5] <- "5+"
  factor(out, levels = c("0","1","2","3","4","5+"))
}
panel$k_bin <- bin_ku(panel$k_users_lag)

# Adoption: at risk = prev_ecig == 0; event = ecig == 1
adopt_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(k_bin)) |>
  group_by(k_bin) |>
  summarise(n_adopt   = n(),
            n_event_a = sum(ecig == 1),
            rate_adopt_pct = 100 * mean(ecig == 1),
            .groups   = "drop")

# Disadoption: at risk = prev_ecig == 1; event = ecig == 0  (any 1->0)
disad_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(k_bin)) |>
  group_by(k_bin) |>
  summarise(n_disad   = n(),
            n_event_d = sum(ecig == 0),
            rate_disad_pct = 100 * mean(ecig == 0),
            .groups   = "drop")

tab <- full_join(adopt_tab, disad_tab, by = "k_bin") |> arrange(k_bin)

# Point-biserial / continuous correlations on the integer scale
adopt_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(k_users_lag))
disad_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(k_users_lag))
r_adopt <- cor(adopt_set$k_users_lag, as.integer(adopt_set$ecig == 1))
n_adopt <- nrow(adopt_set)
r_disad <- cor(disad_set$k_users_lag, as.integer(disad_set$ecig == 0))
n_disad <- nrow(disad_set)

cat("\n==== Rate table (count of using friends, k_users at w-1) ====\n")
print(tab, n = 10)
cat(sprintf("\nAdoption (any 0->1)  vs k_users : r = %.3f  (n = %d)\n",
            r_adopt, n_adopt))
cat(sprintf("Any 1->0           vs k_users : r = %.3f  (n = %d)\n",
            r_disad, n_disad))

write.csv(tab, file.path(TABLES, "v4b_table_11_1_kusers.csv"),
          row.names = FALSE)
saveRDS(list(tab = tab,
             r_adopt = r_adopt, n_adopt = n_adopt,
             r_disad = r_disad, n_disad = n_disad),
        file.path(INTERMEDIATE, "v4b_kusers_rate.rds"))
cat("\nWrote outputs/tables/v4b_table_11_1_kusers.csv\n")
