# ================================================================
# 90-sanity-checks.R
#
# Generates:
#   - village subset robustness (KFP PC adopt + disA, threshold V_max >= 0.10)
#   - byrt verification statistics for the annex
#   - FN_A/B/C/D/F examples for the annex
#   - substitution counts & disadoption breakdown for the annex
# ================================================================

suppressMessages({
  library(netdiffuseR)
  library(sandwich)
  library(lmtest)
  library(Matrix)
})

source(file.path(here::here(), "R", "00-config.R"))
odir <- INTERMEDIATE
data(kfamily)

canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
n  <- nrow(canonical$state_PC); Tt <- canonical$Tt
state_PC <- canonical$state_PC
state_modern <- canonical$state_modern
class_at_t <- canonical$class_at_t
village <- canonical$village

# Vmax_v per village
Vmax_v <- tapply(seq_along(village), village, function(idx) {
  max(sapply(2:Tt, function(t) mean(state_PC[idx, t-1], na.rm = TRUE)), na.rm=TRUE)
})

cat("==== Village V_max distribution (PC) ====\n")
print(round(sort(Vmax_v), 3))
cat(sprintf("\nVillages with V_max >= 0.10: %d / %d\n",
            sum(Vmax_v >= 0.10), length(Vmax_v)))

keep_villages <- as.integer(names(Vmax_v)[Vmax_v >= 0.10])

# ---- village subset for KFP PC adoption (canonical) ----
# Re-use predictors via a quick rebuild
A <- canonical$A
state_PC_A     <- ifelse(is.na(state_PC),     0L, state_PC)
state_modern_A <- ifelse(is.na(state_modern), 0L, state_modern)
W <- {
  rs <- as.numeric(Matrix::rowSums(A))
  Diagonal(n, ifelse(rs > 0, 1/rs, 0)) %*% A
}
W <- as(W, "CsparseMatrix")
E_PC <- E_mod <- Nc_PC <- Nc_mod <- matrix(NA_real_, n, Tt)
for (t in 2:Tt) {
  E_PC[, t]   <- as.numeric(W %*% state_PC_A[, t-1])
  E_mod[, t]  <- as.numeric(W %*% state_modern_A[, t-1])
  Nc_PC[, t]  <- as.numeric(A %*% state_PC_A[, t-1])
  Nc_mod[, t] <- as.numeric(A %*% state_modern_A[, t-1])
}
has_PC <- Nc_PC >= 1; has_mod <- Nc_mod >= 1
make_em <- function(M) {
  Emax <- matrix(NA_real_, n, Tt)
  for (i in 1:n) {
    cm <- cummax(ifelse(is.na(M[i,]), -Inf, M[i,]))
    cm[is.infinite(cm)] <- NA
    Emax[i, ] <- cm
  }
  list(Emax = Emax, EDis = Emax - M)
}
em_PC <- make_em(E_PC); Emax_PC <- em_PC$Emax; EDis_PC <- em_PC$EDis
V_PC <- matrix(NA_real_, n, Tt)
for (t in 2:Tt) for (v in sort(unique(village))) {
  idx <- which(village == v)
  V_PC[idx, t] <- mean(state_PC[idx, t-1], na.rm = TRUE)
}

fit_logit <- function(formula, data) {
  fit <- glm(formula, data = data, family = binomial())
  vc  <- tryCatch(sandwich::vcovCL(fit, cluster = ~village, type = "HC0"),
                  error = function(e) sandwich::vcovHC(fit, type = "HC0"))
  ct  <- lmtest::coeftest(fit, vcov. = vc)
  list(ct = ct, n = nrow(fit$model), events = sum(fit$model[[1]]),
       aic = AIC(fit))
}
row_of <- function(label, r, term) {
  if (!term %in% rownames(r$ct)) return(data.frame(model=label, term=term, OR=NA, p=NA, n=r$n, ev=r$events, aic=round(r$aic,1)))
  z <- r$ct[term,]
  data.frame(model=label, term=term, OR=round(exp(z["Estimate"]),3),
             p=signif(z["Pr(>|z|)"],3), n=r$n, ev=r$events, aic=round(r$aic,1))
}

# --- adoption panel ---
first_PC <- apply(state_PC, 1, function(v) {
  o <- which(v == 1L); if (!length(o)) NA_integer_ else as.integer(min(o))
})
build_adopt <- function(keep_v) {
  rows <- list()
  for (i in 1:n) {
    if (!(village[i] %in% keep_v)) next
    end_t <- if (is.na(first_PC[i])) Tt else first_PC[i]
    if (end_t < 2) next
    for (t in 2:end_t) {
      rows[[length(rows)+1]] <- list(i=i, t=t,
        event=as.integer(!is.na(first_PC[i]) && t == first_PC[i]),
        E=E_PC[i,t], has=as.integer(has_PC[i,t]), Nc=Nc_PC[i,t],
        Emax=Emax_PC[i,t], EDis=EDis_PC[i,t], V=V_PC[i,t], village=village[i])
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_disA <- function(keep_v) {
  rows <- list()
  for (i in 1:n) {
    if (!(village[i] %in% keep_v)) next
    for (t in 2:Tt) {
      if (is.na(state_PC[i, t-1]) || state_PC[i, t-1] != 1L) next
      if (is.na(state_PC[i, t])) next
      cls <- class_at_t[i, t]
      if (!is.na(cls) && cls == "modern_nonPC") next
      ev <- as.integer(state_PC[i, t] == 0L)
      if (ev == 1 && t < Tt && !is.na(state_PC[i, t+1]) && state_PC[i, t+1] == 1L) next
      rows[[length(rows)+1]] <- list(i=i, t=t, event=ev,
        E=E_PC[i,t], has=as.integer(has_PC[i,t]), Nc=Nc_PC[i,t],
        Emax=Emax_PC[i,t], EDis=EDis_PC[i,t], V=V_PC[i,t], village=village[i])
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}

run_battery <- function(pan, label) {
  pan$t <- factor(pan$t); pan$village_fe <- factor(pan$village)
  out <- list(
    A1   = fit_logit(event ~ t + village_fe + E, pan),
    C1   = fit_logit(event ~ t + village_fe + has, pan),
    H    = fit_logit(event ~ t + village_fe + Emax, pan),
    V1   = fit_logit(event ~ t + village_fe + V, pan),
    V2   = fit_logit(event ~ t + village_fe + V + E, pan)
  )
  rbind(
    row_of(paste(label,"A1"), out$A1, "E"),
    row_of(paste(label,"C1"), out$C1, "has"),
    row_of(paste(label,"H"),  out$H,  "Emax"),
    row_of(paste(label,"V1"), out$V1, "V"),
    row_of(paste(label,"V2:V"),out$V2, "V"),
    row_of(paste(label,"V2:E"),out$V2, "E")
  )
}

ad_full <- build_adopt(unique(village))
ad_sub  <- build_adopt(keep_villages)
disA_full <- build_disA(unique(village))
disA_sub  <- build_disA(keep_villages)

cat(sprintf("\nAdoption full: n=%d ev=%d   |   subset(V>=0.10): n=%d ev=%d\n",
            nrow(ad_full), sum(ad_full$event), nrow(ad_sub), sum(ad_sub$event)))
cat("\n--- Adoption subset (V_max >= 0.10) ---\n")
print(run_battery(ad_sub, "PC adopt sub"), row.names = FALSE)
cat(sprintf("\nDisA full: n=%d ev=%d  |  subset: n=%d ev=%d\n",
            nrow(disA_full), sum(disA_full$event), nrow(disA_sub), sum(disA_sub$event)))
cat("\n--- DisA subset (V_max >= 0.10) ---\n")
print(run_battery(disA_sub, "PC disA sub"), row.names = FALSE)

# Save
sanity <- list(
  Vmax_v = Vmax_v,
  PC_adopt_sub  = run_battery(ad_sub, "PC adopt sub"),
  PC_disA_sub   = run_battery(disA_sub, "PC disA sub")
)

# ---- byrt verification stats (already computed in 00, replicate) ----
fpt_cols  <- grep("^fpt[0-9]+$",  names(kfamily), value = TRUE)
byrt_cols <- grep("^byrt[0-9]+$", names(kfamily), value = TRUE)
fpt_cols  <- fpt_cols[ order(as.integer(sub("fpt","",  fpt_cols)))]
byrt_cols <- byrt_cols[order(as.integer(sub("byrt","", byrt_cols)))]
fpt_mat   <- as.matrix(kfamily[, fpt_cols])
byrt_mat  <- as.matrix(kfamily[, byrt_cols])
year_map  <- c("4"=1964,"5"=1965,"6"=1966,"7"=1967,"8"=1968,
               "9"=1969,"0"=1970,"1"=1971,"2"=1972,"3"=1973)
decode <- function(x) { o <- rep(NA_integer_, length(x))
  ok <- !is.na(x) & as.character(x) %in% names(year_map)
  o[ok] <- as.integer(year_map[as.character(x[ok])]); o }
byrt_year <- matrix(decode(byrt_mat), nrow = nrow(byrt_mat))

n_with_ge2 <- 0; n_mono <- 0
for (i in 1:nrow(byrt_year)) {
  bv <- byrt_year[i, ]; bv <- bv[!is.na(bv)]
  if (length(bv) < 2) next
  n_with_ge2 <- n_with_ge2 + 1
  if (all(diff(bv) >= 0)) n_mono <- n_mono + 1
}
n_byrt_after_p <- 0; total_pairs <- 0
for (i in 1:nrow(byrt_year)) for (p in 1:ncol(byrt_year)) {
  if (is.na(fpt_mat[i,p]) || is.na(byrt_year[i,p])) next
  total_pairs <- total_pairs + 1
  if (byrt_year[i,p] > 1963 + p) n_byrt_after_p <- n_byrt_after_p + 1
}
sanity$byrt_stats <- list(
  women_ge2 = n_with_ge2, women_monotone = n_mono,
  pct_monotone = round(100 * n_mono / n_with_ge2, 1),
  total_pairs = total_pairs, byrt_after_p = n_byrt_after_p,
  pct_byrt_after_p = round(100 * n_byrt_after_p / total_pairs, 1)
)
cat(sprintf("\n==== byrt verification stats ====\n"))
cat(sprintf("  Women with >=2 byrt obs:        %d\n", n_with_ge2))
cat(sprintf("  ... and byrt monotone:          %d (%.1f%%)\n", n_mono, 100*n_mono/n_with_ge2))
cat(sprintf("  Total (i,p) pairs:              %d\n", total_pairs))
cat(sprintf("  Pairs with byrt_year > 1963+p:  %d (%.1f%%)\n",
            n_byrt_after_p, 100*n_byrt_after_p/total_pairs))

# ---- substitution counts under Option II ----
n_sub <- 0; n_dis_trad <- 0; n_dis_noFP <- 0; n_within_PC <- 0
for (i in 1:n) for (t in 2:Tt) {
  if (is.na(state_PC[i, t-1]) || state_PC[i, t-1] != 1L) next
  if (is.na(state_PC[i, t])) next
  cls <- class_at_t[i, t]
  if (state_PC[i, t] == 1L) n_within_PC <- n_within_PC + 1
  else if (!is.na(cls) && cls == "modern_nonPC") n_sub <- n_sub + 1
  else if (!is.na(cls) && cls == "trad")         n_dis_trad <- n_dis_trad + 1
  else if (!is.na(cls) && cls == "noFP")         n_dis_noFP <- n_dis_noFP + 1
}
sanity$option_II_counts <- list(
  within_PC = n_within_PC, sub_to_modern_nonPC = n_sub,
  dis_to_trad = n_dis_trad, dis_to_noFP = n_dis_noFP)
cat(sprintf("\n==== Option II refined breakdown (PC at t-1, observed at t) ====\n"))
cat(sprintf("  Stay in PC                       : %d\n", n_within_PC))
cat(sprintf("  Substitution to modern_nonPC     : %d   (RIGHT-CENSURED)\n", n_sub))
cat(sprintf("  Disadopt to trad                 : %d\n", n_dis_trad))
cat(sprintf("  Disadopt to noFP                 : %d\n", n_dis_noFP))
cat(sprintf("  Total disadoption events (raw)   : %d\n", n_dis_trad + n_dis_noFP))

# ---- FN counts and examples ----
PC_codes <- canonical$PC_codes
modern_nonPC <- canonical$modern_nonPC
trad_codes <- canonical$trad_codes
noFP_codes <- canonical$noFP_codes

cfp <- kfamily$cfp; cby <- sapply(kfamily$cbyr, decode)

# Old-style FN definitions (referencing original fpt episodes only)
# This requires the 'fpt-only' version
fptonly <- readRDS(file.path(odir, "kfp_fptonly.rds"))
state_PC_fpt <- fptonly$state_PC
class_at_fpt <- fptonly$class_at_t

# trajectory diagnostics on fpt-only panel
last_PC_fpt <- apply(state_PC_fpt, 1, function(v) {
  o <- which(v == 1L); if (!length(o)) NA_integer_ else as.integer(max(o))
})
first_PC_fpt <- apply(state_PC_fpt, 1, function(v) {
  o <- which(v == 1L); if (!length(o)) NA_integer_ else as.integer(min(o))
})

# is_obs at calendar t in fpt panel = state_PC_fpt is non-NA
# end-censored on PC: last_PC_fpt == Tt
# stable PC exit: last_PC_fpt < Tt and subsequent state observed and not PC, no later PC
# ambig: last_PC_fpt < Tt and no observation after last_PC_fpt
classify_traj <- function(i) {
  s <- state_PC_fpt[i, ]
  obs <- !is.na(s)
  ones <- which(s == 1L)
  if (!length(ones)) return("never_PC")
  lm <- max(ones)
  if (lm == Tt) return("end_cens")
  after_obs <- which(obs[(lm+1L):Tt]) + lm
  if (!length(after_obs)) return("ambig")
  if (any(s[after_obs] == 1L, na.rm = TRUE)) return("transient")
  "stable_exit"
}
traj <- sapply(1:n, classify_traj)
cfp_in_PC <- !is.na(cfp) & cfp %in% PC_codes

FN_A <- which(traj == "end_cens"   & !cfp_in_PC & !is.na(cfp))
FN_B <- which(traj == "ambig"      & !cfp_in_PC & !is.na(cfp))
FN_C <- which(traj == "ambig"      & cfp_in_PC)
FN_D <- which(traj == "stable_exit"& cfp_in_PC)
FN_F <- which(traj == "never_PC"   & cfp_in_PC)
sanity$FN_counts <- list(
  FN_A_endcens_cfp_nonPC = length(FN_A),
  FN_B_ambig_cfp_nonPC   = length(FN_B),
  FN_C_ambig_cfp_PC      = length(FN_C),
  FN_D_stable_cfp_PC     = length(FN_D),
  FN_F_neverPC_cfp_PC    = length(FN_F)
)
cat(sprintf("\n==== FN counts (using fpt-only panel as basis) ====\n"))
cat(sprintf("  FN_A end_cens + cfp non-PC: %d\n", length(FN_A)))
cat(sprintf("  FN_B ambig + cfp non-PC:    %d\n", length(FN_B)))
cat(sprintf("  FN_C ambig + cfp PC:        %d\n", length(FN_C)))
cat(sprintf("  FN_D stable + cfp PC:       %d\n", length(FN_D)))
cat(sprintf("  FN_F never PC + cfp PC:     %d\n", length(FN_F)))

# 3 examples per FN
lt <- attr(kfamily, "label.table")$fpstatus
inv_lt <- setNames(names(lt), as.numeric(lt))
fmt_traj <- function(i) {
  fp <- as.character(fpt_mat[i, ]); fp[is.na(fp)] <- "."
  fp_lab <- ifelse(fp == ".", ".", inv_lt[fp])
  by <- as.character(byrt_mat[i, ]); by[is.na(by)] <- "."
  cfp_v <- cfp[i]; cby_v <- kfamily$cbyr[i]
  list(fpt = fp_lab, byrt = by,
       cfp = ifelse(is.na(cfp_v), ".", inv_lt[as.character(cfp_v)]),
       cbyr = ifelse(is.na(cby_v), ".", as.character(cby_v)))
}
examples <- list()
for (nm in c("FN_A","FN_B","FN_C","FN_D","FN_F")) {
  idx <- get(nm)
  examples[[nm]] <- lapply(head(idx, 3), function(i) c(list(row=i, id=kfamily$id[i], village=kfamily$village[i]), fmt_traj(i)))
}
sanity$FN_examples <- examples

saveRDS(sanity, file.path(odir, "sanity_and_annex.rds"))
cat(sprintf("\nSaved: %s\n", file.path(odir, "sanity_and_annex.rds")))
