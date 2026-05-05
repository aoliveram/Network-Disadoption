# ================================================================
# 05c-eusers-rate-table.R  (v4b)
#
# Build the parallel of §11.1's PFU rate table, but using
# E_users(w-1) (network-derived: peer share who are current users)
# in place of perceived friend use (PFU).
#
# Bins E_users into 6 categories matching the 6 PFU levels:
#   {0, (0,0.2], (0.2,0.4], (0.4,0.6], (0.6,0.8], (0.8,1.0]}
#
# For each bin, computes:
#   - n at risk for adoption  (state at w-1 = 0, valid lag, valid outcome)
#   - adoption rate            (P(state_w = 1 | state_{w-1} = 0))
#   - n at risk for disadoption (state_{w-1} = 1, valid lag/outcome)
#   - disadoption rate (any 1->0)
#
# Plus point-biserial correlations (E_users vs adoption / any 1->0).
# Output: outputs/tables/v4b_table_11_1_E_users.csv
# ================================================================
suppressMessages({ library(dplyr) })
source(file.path(here::here(), "R", "00-config.R"))

panel    <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
features <- readRDS(file.path(INTERMEDIATE, "v4b_network_features.rds"))
E_users  <- features$E_users   # rows = record_id, cols = waves

# Build long table with state_w, state_{w-1}, E_users at w-1
panel <- panel[order(panel$record_id, panel$wave), ]
panel <- panel |>
  group_by(record_id) |>
  mutate(prev_ecig = lag(ecig)) |>
  ungroup()

# Attach E_users at w-1
prev_w <- panel$wave - 1L
key_lag <- paste(panel$record_id, prev_w, sep = "_")
E_users_long <- as.data.frame(as.table(E_users), stringsAsFactors = FALSE)
names(E_users_long) <- c("record_id", "wave_lab", "E_users_w")
E_users_long$wave <- as.integer(sub("^w", "", E_users_long$wave_lab))
E_users_lookup <- with(E_users_long,
                       setNames(E_users_w, paste(record_id, wave, sep = "_")))
panel$E_users_lag <- as.numeric(E_users_lookup[key_lag])

# Bin E_users_lag
bin_eu <- function(x) {
  out <- rep(NA_character_, length(x))
  out[!is.na(x) & x == 0]                  <- "0 (None)"
  out[!is.na(x) & x >  0   & x <= 0.2]     <- "(0, 0.2]"
  out[!is.na(x) & x >  0.2 & x <= 0.4]     <- "(0.2, 0.4]"
  out[!is.na(x) & x >  0.4 & x <= 0.6]     <- "(0.4, 0.6]"
  out[!is.na(x) & x >  0.6 & x <= 0.8]     <- "(0.6, 0.8]"
  out[!is.na(x) & x >  0.8 & x <= 1.0]     <- "(0.8, 1.0]"
  factor(out, levels = c("0 (None)","(0, 0.2]","(0.2, 0.4]",
                         "(0.4, 0.6]","(0.6, 0.8]","(0.8, 1.0]"))
}
panel$E_bin <- bin_eu(panel$E_users_lag)

# Adoption: at risk = prev_ecig == 0; event = ecig == 1
adopt_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(E_bin)) |>
  group_by(E_bin) |>
  summarise(n_adopt = n(),
            rate_adopt_pct = 100 * mean(ecig == 1),
            .groups = "drop")

# Disadoption: at risk = prev_ecig == 1; event = ecig == 0  (any 1->0)
disad_tab <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(E_bin)) |>
  group_by(E_bin) |>
  summarise(n_disad = n(),
            rate_disad_pct = 100 * mean(ecig == 0),
            .groups = "drop")

tab <- full_join(adopt_tab, disad_tab, by = "E_bin")
tab <- tab |> arrange(E_bin)

# Point-biserial correlations
adopt_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 0, !is.na(ecig), !is.na(E_users_lag))
disad_set <- panel |>
  filter(!is.na(prev_ecig), prev_ecig == 1, !is.na(ecig), !is.na(E_users_lag))
r_adopt <- cor(adopt_set$E_users_lag, as.integer(adopt_set$ecig == 1))
n_adopt <- nrow(adopt_set)
r_disad <- cor(disad_set$E_users_lag, as.integer(disad_set$ecig == 0))
n_disad <- nrow(disad_set)

cat("\n==== Rate table (E_users at w-1) ====\n")
print(tab, n = 10)
cat(sprintf("\nAdoption (any 0->1) vs E_users : r = %.3f  (n = %d)\n",
            r_adopt, n_adopt))
cat(sprintf("Any 1->0       vs E_users : r = %.3f  (n = %d)\n",
            r_disad, n_disad))

write.csv(tab, file.path(TABLES, "v4b_table_11_1_E_users.csv"),
          row.names = FALSE)
saveRDS(list(tab = tab,
             r_adopt = r_adopt, n_adopt = n_adopt,
             r_disad = r_disad, n_disad = n_disad),
        file.path(INTERMEDIATE, "v4b_eusers_rate.rds"))
cat("\nWrote outputs/tables/v4b_table_11_1_E_users.csv\n")
