# ================================================================
# 01-kfp-panel.R
#
# Build the KFP panel using the corrected episode -> calendar
# reconstruction. For each woman:
#   - Collect all (byrt_p, fpt_p) episodes plus the (cbyr, cfp)
#     survey-time anchor.
#   - Sort by byrt_year ascending (ties: FP-active wins, cfp wins
#     within ties).
#   - For each calendar year t = 1..10 (= 1964..1973), the active
#     method is the LATEST episode whose byrt_year <= 1963 + t.
#
# Outputs (in outputs/intermediate/):
#   - kfp_full_status_panel.txt  : 1047 x (id, village, t1..t10) full method labels
#   - kfp_pc_status_panel.txt    : 1047 x (id, village, t1..t10) 0/1 PC indicator
#   - kfp_canonical.rds          : panel with fpt + cfp anchor (canonical)
#   - kfp_fptonly.rds            : panel from fpt episodes only (no cfp)
#   - kfp_objects.rds            : alias for kfp_canonical.rds (legacy)
# ================================================================

suppressMessages({
  library(netdiffuseR)
  library(Matrix)
})

source(file.path(here::here(), "R", "00-config.R"))
odir <- INTERMEDIATE
dir.create(odir, showWarnings = FALSE, recursive = TRUE)

data(kfamily)
n  <- nrow(kfamily)
Tt <- 10L  # calendar years 1964..1973

# ---- method classification ----
PC_codes        <- c(4L, 5L)                  # Condom, Pill
modern_nonPC    <- c(3L, 6L, 15L, 18L)        # Loop, Vasectomy, TL, Injection
trad_codes      <- c(14L, 16L, 17L, 19L, 20L) # Rhythm, Withdrawal, Pessary, Jelly, Foam
noFP_codes      <- c(1L, 2L, 7L, 8L, 9L, 10L, 11L, 12L, 13L, 21L)

classify <- function(method) {
  if (is.na(method)) return(NA_character_)
  if (method %in% PC_codes)     return("PC")
  if (method %in% modern_nonPC) return("modern_nonPC")
  if (method %in% trad_codes)   return("trad")
  if (method %in% noFP_codes)   return("noFP")
  return("unknown")
}

lt <- attr(kfamily, "label.table")$fpstatus
inv_lt <- setNames(names(lt), as.numeric(lt))
label_method <- function(m) ifelse(is.na(m), "NA", inv_lt[as.character(m)])

# ---- year decoding ----
year_map <- c("4"=1964,"5"=1965,"6"=1966,"7"=1967,"8"=1968,
              "9"=1969,"0"=1970,"1"=1971,"2"=1972,"3"=1973)
decode_year <- function(x) {
  if (is.na(x)) return(NA_integer_)
  yr <- year_map[as.character(x)]
  if (length(yr) == 0 || is.na(yr)) return(NA_integer_)
  as.integer(yr)
}

# ---- gather columns ----
fpt_cols  <- grep("^fpt[0-9]+$",  names(kfamily), value = TRUE)
byrt_cols <- grep("^byrt[0-9]+$", names(kfamily), value = TRUE)
fpt_cols  <- fpt_cols[ order(as.integer(sub("fpt","",  fpt_cols)))]
byrt_cols <- byrt_cols[order(as.integer(sub("byrt","", byrt_cols)))]

fpt_mat  <- as.matrix(kfamily[, fpt_cols])
byrt_mat <- as.matrix(kfamily[, byrt_cols])

# ---- build episode list per woman ----
# Sort key encodes: byrt_year > FP_active priority > p (within year+class).
# FP-active (PC, modern_nonPC, trad) overrides noFP within same year, because
# a birth event (NormalB) does not preclude active FP use; cfp anchor wins
# ties by virtue of receiving a large p slot (99 > all fpt p in 1..12).
class_priority <- function(method) {
  if (is.na(method)) return(0L)
  if (method %in% c(PC_codes, modern_nonPC, trad_codes)) return(1L)  # FP-active
  return(0L)  # noFP / unknown
}
build_episodes <- function(i, use_cfp = TRUE) {
  ep <- list()
  for (p in seq_along(fpt_cols)) {
    fp <- fpt_mat[i, p]
    by <- byrt_mat[i, p]
    if (is.na(fp) || is.na(by)) next
    yr <- decode_year(by)
    if (is.na(yr)) next
    ep[[length(ep)+1]] <- list(byrt_year = yr, method = as.integer(fp),
                                source = paste0("fpt", p),
                                sort_key = yr * 10000L + class_priority(fp) * 100L + p)
  }
  if (use_cfp) {
    cfp_v <- kfamily$cfp[i]; cby_v <- kfamily$cbyr[i]
    if (!is.na(cfp_v) && !is.na(cby_v)) {
      yr <- decode_year(cby_v)
      if (!is.na(yr)) {
        ep[[length(ep)+1]] <- list(byrt_year = yr, method = as.integer(cfp_v),
                                    source = "cfp",
                                    sort_key = yr * 10000L + class_priority(cfp_v) * 100L + 99L)
      }
    }
  }
  if (length(ep) > 0) {
    ep <- ep[order(sapply(ep, function(x) x$sort_key))]
  }
  ep
}

# ---- compute calendar-year state matrices for both panel variants ----
build_panel <- function(use_cfp) {
  state_PC      <- matrix(NA_integer_, n, Tt)
  state_modern  <- matrix(NA_integer_, n, Tt)
  method_at_t   <- matrix(NA_integer_, n, Tt)
  class_at_t    <- matrix(NA_character_, n, Tt)
  n_eps         <- integer(n)
  eps_list      <- vector("list", n)
  for (i in seq_len(n)) {
    ep <- build_episodes(i, use_cfp = use_cfp)
    eps_list[[i]] <- ep
    n_eps[i] <- length(ep)
    if (length(ep) == 0) next
    yrs <- sapply(ep, function(x) x$byrt_year)
    for (t in seq_len(Tt)) {
      cal <- 1963 + t
      cands <- which(yrs <= cal)
      if (length(cands) == 0) next
      active <- ep[[max(cands)]]
      method_at_t[i, t] <- active$method
      cls <- classify(active$method)
      class_at_t[i, t]  <- cls
      state_PC[i, t]    <- as.integer(cls == "PC")
      state_modern[i, t]<- as.integer(cls %in% c("PC", "modern_nonPC"))
    }
  }
  list(state_PC=state_PC, state_modern=state_modern,
       method_at_t=method_at_t, class_at_t=class_at_t,
       n_episodes=n_eps, episodes_list=eps_list)
}

panel_canonical <- build_panel(use_cfp = TRUE)
panel_fptonly   <- build_panel(use_cfp = FALSE)
state_PC      <- panel_canonical$state_PC
state_modern  <- panel_canonical$state_modern
method_at_t   <- panel_canonical$method_at_t
class_at_t    <- panel_canonical$class_at_t
n_episodes    <- panel_canonical$n_episodes
episodes_list <- panel_canonical$episodes_list

# ---- diagnostics ----
cat(sprintf("Episodes per woman (incl cfp anchor):\n"))
print(quantile(n_episodes, c(0,.25,.5,.75,.9,1)))
cat(sprintf("\nPC prevalence by calendar period (state_PC = 1):\n"))
prev_PC <- round(colMeans(state_PC == 1, na.rm = TRUE), 3)
print(setNames(prev_PC, paste0("t", 1:Tt)))
cat(sprintf("\nFraction NA in state_PC by period (no episode yet):\n"))
print(setNames(round(colMeans(is.na(state_PC)), 3), paste0("t", 1:Tt)))

# Class breakdown across all (i, t)
cat("\nClass at (i,t) breakdown:\n")
print(table(class_at_t, useNA = "ifany"))

# ---- compare new TOA-of-PC and TOA-of-modern against original toa ----
# TOA of PC = first calendar year where state_PC == 1
toa_PC_new <- apply(state_PC, 1, function(v) {
  ones <- which(v == 1)
  if (!length(ones)) NA_integer_ else as.integer(min(ones))
})
# TOA of modern = first calendar year where state_modern == 1
toa_mod_new <- apply(state_modern, 1, function(v) {
  ones <- which(v == 1)
  if (!length(ones)) NA_integer_ else as.integer(min(ones))
})
cat(sprintf("\nEver PC (new episode-based) : %d\n", sum(!is.na(toa_PC_new))))
cat(sprintf("Ever PC (old fpt-direct)    : %d (was 292)\n",
            sum(apply(fpt_mat, 1, function(v) any(v %in% PC_codes, na.rm = TRUE)))))
cat(sprintf("Ever modern (new)           : %d\n", sum(!is.na(toa_mod_new))))
adopters <- which(!is.na(kfamily$toa) & kfamily$toa <= 10)
match_mod <- sum(kfamily$toa[adopters] == toa_mod_new[adopters], na.rm = TRUE)
cat(sprintf("New TOA-of-modern matches kfamily$toa: %d/%d (%.1f%%)\n",
            match_mod, length(adopters), 100*match_mod/length(adopters)))

# ---- write tables ----
ids        <- kfamily$id
villages   <- kfamily$village
header_t   <- paste0("t", 1:Tt)

# Table 1.1: full method status (string label) per (i, t)
full_tab <- data.frame(
  global_id = seq_len(n),
  id        = ids,
  village   = villages,
  matrix(NA_character_, n, Tt, dimnames = list(NULL, header_t)),
  stringsAsFactors = FALSE
)
for (t in seq_len(Tt)) {
  full_tab[, paste0("t", t)] <- ifelse(is.na(method_at_t[, t]), "NA", inv_lt[as.character(method_at_t[, t])])
}
write.table(full_tab, file.path(odir, "kfp_full_status_panel.txt"),
            sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("\nWrote: %s\n", file.path(odir, "kfp_full_status_panel.txt")))

# Table 1.2: PC indicator per (i, t)
pc_tab <- data.frame(
  global_id = seq_len(n), id = ids, village = villages,
  matrix(NA_character_, n, Tt, dimnames = list(NULL, header_t)),
  stringsAsFactors = FALSE
)
for (t in seq_len(Tt)) {
  v <- state_PC[, t]
  pc_tab[, paste0("t", t)] <- ifelse(is.na(v), "NA", as.character(v))
}
write.table(pc_tab, file.path(odir, "kfp_pc_status_panel.txt"),
            sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("Wrote: %s\n", file.path(odir, "kfp_pc_status_panel.txt")))

# ---- adjacency (FP-discussion network, static) ----
alter_mat <- as.matrix(kfamily[, sprintf("net1%d", 1:5)])
alter_mat[alter_mat == 0] <- NA
surveyed <- kfamily$id
for (j in 1:5) {
  bad <- !(alter_mat[, j] %in% surveyed)
  alter_mat[bad, j] <- NA
}
key_ego   <- paste(kfamily$village, kfamily$id, sep = "_")
id_lookup <- setNames(seq_len(n), key_ego)
row_idx <- integer(0); col_idx <- integer(0)
for (j in 1:5) {
  alt <- alter_mat[, j]; keep <- !is.na(alt)
  alt_g <- id_lookup[paste(kfamily$village[keep], alt[keep], sep = "_")]
  ok <- !is.na(alt_g)
  row_idx <- c(row_idx, which(keep)[ok])
  col_idx <- c(col_idx, as.integer(alt_g[ok]))
}
A <- sparseMatrix(i = row_idx, j = col_idx, x = 1, dims = c(n, n))
A@x[A@x > 1] <- 1
deg <- as.numeric(Matrix::rowSums(A))

# ---- substitution / disadoption counts under Option II refined ----
count_sub <- 0; count_disadopt_trad <- 0; count_disadopt_noFP <- 0
for (i in 1:n) for (t in 2:Tt) {
  if (is.na(state_PC[i, t-1]) || state_PC[i, t-1] != 1L) next
  if (is.na(state_PC[i, t])) next
  if (state_PC[i, t] == 1L) next
  cls <- class_at_t[i, t]
  if (is.na(cls)) next
  if (cls == "modern_nonPC") count_sub <- count_sub + 1
  else if (cls == "trad")    count_disadopt_trad <- count_disadopt_trad + 1
  else if (cls == "noFP")    count_disadopt_noFP <- count_disadopt_noFP + 1
}
cat(sprintf("\nOption II refined breakdown (canonical panel, all 1->0 transitions):\n"))
cat(sprintf("  Substitution to modern_nonPC (censored): %d\n", count_sub))
cat(sprintf("  Disadoption to trad                    : %d\n", count_disadopt_trad))
cat(sprintf("  Disadoption to noFP                    : %d\n", count_disadopt_noFP))

# ---- save objects (canonical + fpt-only) ----
common <- list(
  Tt = Tt, village = kfamily$village, id = kfamily$id,
  cfp = kfamily$cfp,
  cbyr_year = sapply(kfamily$cbyr, decode_year),
  A = A, deg_out = deg,
  PC_codes = PC_codes, modern_nonPC = modern_nonPC,
  trad_codes = trad_codes, noFP_codes = noFP_codes,
  fpt_mat = fpt_mat, byrt_mat = byrt_mat
)
saveRDS(c(panel_canonical, common), file.path(odir, "kfp_canonical.rds"))
saveRDS(c(panel_fptonly,   common), file.path(odir, "kfp_fptonly.rds"))
saveRDS(c(panel_canonical, common), file.path(odir, "kfp_objects.rds"))  # legacy alias
cat(sprintf("\nSaved: %s\n", file.path(odir, "kfp_canonical.rds")))
cat(sprintf("Saved: %s\n", file.path(odir, "kfp_fptonly.rds")))
