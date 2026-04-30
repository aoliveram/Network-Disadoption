# ================================================================
# playground/02-glmer-modelC.R
#
# Sanity check (C): random-effects logit on Model C (recurrent
# disadoption), where individuals can contribute multiple events,
# so (1 | id) is well-identified.
#
# For each spec we report:
#   GLM    = current v3: glm + cluster-robust SE by community
#   GLMER  = lme4::glmer with (1 | id), wave_fe + community_fe FE
#
# Reports per coefficient: OR_glm, p_glm, OR_glmer, p_glmer, ratio.
# Plus per-model: sigma2_u, ICC, convergence flags.
#
# Notes:
#   - GLMER OR are subject-specific (conditional on u_i), so they are
#     systematically more extreme than population-averaged GLM OR.
#     Direction and (rough) significance are what we compare.
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(lme4)
  library(Matrix)
})

source(file.path(here::here(), "R", "00-config.R"))

odir <- INTERMEDIATE
canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
advance   <- readRDS(file.path(odir, "advance_panel.rds"))

# Pull in the same panel-builders as 01-twoway-clustering.R
# (kept brief: only Model C panels for ADVANCE, KFP PC canon, KFP modern6)
compute_pp <- function(po) {
  n <- nrow(po$state_PC); Tt <- po$Tt
  state_PC <- po$state_PC; state_modern <- po$state_modern
  class_at_t <- po$class_at_t; village <- po$village; A <- po$A
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
  has_PC  <- Nc_PC  >= 1; has_mod <- Nc_mod >= 1
  make_em <- function(M) {
    Emax <- matrix(NA_real_, n, Tt)
    for (i in 1:n) {
      cm <- cummax(ifelse(is.na(M[i,]), -Inf, M[i,]))
      cm[is.infinite(cm)] <- NA
      Emax[i, ] <- cm
    }
    list(Emax = Emax, EDis = Emax - M)
  }
  pc_em <- make_em(E_PC); mod_em <- make_em(E_mod)
  V_PC <- V_mod <- matrix(NA_real_, n, Tt)
  for (t in 2:Tt) for (v in sort(unique(village))) {
    idx <- which(village == v)
    V_PC[idx,  t] <- mean(state_PC[idx,     t-1], na.rm = TRUE)
    V_mod[idx, t] <- mean(state_modern[idx, t-1], na.rm = TRUE)
  }
  list(state_PC=state_PC, state_modern=state_modern, class_at_t=class_at_t,
       village=village, E_PC=E_PC, E_mod=E_mod, has_PC=has_PC, has_mod=has_mod,
       Emax_PC=pc_em$Emax, EDis_PC=pc_em$EDis,
       Emax_mod=mod_em$Emax, EDis_mod=mod_em$EDis,
       V_PC=V_PC, V_mod=V_mod, Tt=Tt, n=n)
}

build_dis_PC_C <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  state <- pp$state_PC; class_at <- pp$class_at_t
  rows <- list()
  for (i in 1:n) for (t in 2:Tt) {
    if (is.na(state[i, t-1]) || state[i, t-1] != 1L) next
    if (is.na(state[i, t])) next
    cls <- class_at[i, t]
    if (!is.na(cls) && cls == "modern_nonPC") next
    ev <- as.integer(state[i, t] == 0L)
    rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
      E_PC=pp$E_PC[i,t], V_PC=pp$V_PC[i,t],
      EDis_PC=pp$EDis_PC[i,t], village=pp$village[i])
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_dis_mod_C <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  state <- pp$state_modern
  rows <- list()
  for (i in 1:n) for (t in 2:Tt) {
    if (is.na(state[i, t-1]) || state[i, t-1] != 1L) next
    if (is.na(state[i, t])) next
    ev <- as.integer(state[i, t] == 0L)
    rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
      E=pp$E_mod[i,t], V=pp$V_mod[i,t], EDis=pp$EDis_mod[i,t],
      village=pp$village[i])
  }
  do.call(rbind, lapply(rows, as.data.frame))
}

pp_can <- compute_pp(canonical)
kfp_pc_disC <- build_dis_PC_C(pp_can)
names(kfp_pc_disC)[names(kfp_pc_disC)=="village"] <- "community"
kfp_pc_disC$wave <- kfp_pc_disC$t

kfp_mod_disC <- build_dis_mod_C(pp_can)
names(kfp_mod_disC)[names(kfp_mod_disC)=="village"] <- "community"
kfp_mod_disC$wave <- kfp_mod_disC$t

# ADVANCE disC
adv <- advance[order(advance$record_id, advance$wave), ]
lag1 <- function(df, var) {
  out <- rep(NA, nrow(df))
  same <- c(FALSE, df$record_id[-1] == df$record_id[-nrow(df)] &
                   df$wave[-1]      == df$wave[-nrow(df)] + 1L)
  out[same] <- df[[var]][which(same) - 1L]; out
}
adv$ecig_prev <- lag1(adv,"ecig")
adv$E_prev    <- lag1(adv,"E_ecig")
adv$V_prev    <- lag1(adv,"V_ecig")
adv$Emax_prev <- NA_real_
for (rr in split(seq_len(nrow(adv)), adv$record_id)) {
  if (length(rr) < 2) next
  e <- adv$E_ecig[rr]; cm <- cummax(ifelse(is.na(e), -Inf, e))
  cm[is.infinite(cm)] <- NA
  adv$Emax_prev[rr][-1] <- cm[-length(cm)]
}
adv$EDis_prev <- adv$Emax_prev - adv$E_prev

disC_raw <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 1 & !is.na(adv$ecig), ]
adv_disC <- data.frame(event=as.integer(disC_raw$ecig==0), id=disC_raw$record_id,
                       community=disC_raw$schoolid, wave=disC_raw$wave,
                       E=disC_raw$E_prev, V=disC_raw$V_prev,
                       EDis=disC_raw$EDis_prev)

prep <- function(d) {
  d$wave_fe <- factor(d$wave); d$community_fe <- factor(d$community); d
}
adv_disC      <- prep(adv_disC)
kfp_pc_disC   <- prep(kfp_pc_disC)
kfp_mod_disC  <- prep(kfp_mod_disC)

# ----------------------------------------------------------------
# fitter that returns GLM and GLMER side-by-side per coefficient
# ----------------------------------------------------------------
fit_pair <- function(formula_glm, formula_glmer, data, panel_label, spec_label,
                      key_terms) {
  vars <- unique(c(all.vars(formula_glm), "id", "community", "wave"))
  d <- data[, vars[vars %in% names(data)], drop = FALSE]
  d <- d[complete.cases(d), , drop = FALSE]
  n_id <- length(unique(d$id))
  n_comm <- length(unique(d$community))
  n <- nrow(d); ev <- sum(d$event)

  cat(sprintf("\n--- %s : %s : n=%d ev=%d n_id=%d ---\n",
              panel_label, spec_label, n, ev, n_id))

  # GLM
  fit_glm <- glm(formula_glm, data = d, family = binomial())
  vc_comm <- tryCatch(vcovCL(fit_glm, cluster = d$community, type = "HC0"),
                      error = function(e) vcovHC(fit_glm, type = "HC0"))
  ct_glm  <- coeftest(fit_glm, vcov. = vc_comm)

  # GLMER
  glmer_t0 <- Sys.time()
  fit_glmer <- tryCatch(
    glmer(formula_glmer, data = d, family = binomial(),
          control = glmerControl(optimizer = "bobyqa",
                                  optCtrl  = list(maxfun = 4e5))),
    error = function(e) {cat("    GLMER ERROR:", conditionMessage(e), "\n"); NULL},
    warning = function(w) {cat("    GLMER WARN:", conditionMessage(w), "\n"); NULL}
  )
  glmer_dt <- as.numeric(difftime(Sys.time(), glmer_t0, units = "secs"))
  cat(sprintf("    glmer wall-time: %.1fs\n", glmer_dt))

  rows <- list()
  if (is.null(fit_glmer)) {
    sigma2_u <- NA; icc <- NA; conv_msg <- "FAIL"
    for (term in key_terms) {
      rows[[length(rows)+1]] <- data.frame(
        panel = panel_label, spec = spec_label, term = term,
        OR_glm   = round(exp(ct_glm[term, "Estimate"]), 3),
        p_glm    = signif(ct_glm[term, "Pr(>|z|)"], 3),
        OR_glmer = NA_real_, p_glmer = NA_real_,
        sigma2_u = NA_real_, ICC = NA_real_,
        conv_msg = conv_msg, n = n, ev = ev, n_id = n_id, n_comm = n_comm,
        stringsAsFactors = FALSE)
    }
  } else {
    sigma2_u <- as.numeric(VarCorr(fit_glmer)$id[1, 1])
    icc      <- sigma2_u / (sigma2_u + (pi^2)/3)
    conv_msg <- ifelse(length(fit_glmer@optinfo$conv$lme4$messages) == 0,
                       "OK",
                       paste(fit_glmer@optinfo$conv$lme4$messages, collapse=";"))
    se_glmer <- summary(fit_glmer)$coefficients
    for (term in key_terms) {
      if (term %in% rownames(se_glmer)) {
        rows[[length(rows)+1]] <- data.frame(
          panel = panel_label, spec = spec_label, term = term,
          OR_glm   = round(exp(ct_glm[term, "Estimate"]), 3),
          p_glm    = signif(ct_glm[term, "Pr(>|z|)"], 3),
          OR_glmer = round(exp(se_glmer[term, "Estimate"]), 3),
          p_glmer  = signif(se_glmer[term, "Pr(>|z|)"], 3),
          sigma2_u = round(sigma2_u, 3),
          ICC      = round(icc, 3),
          conv_msg = conv_msg, n = n, ev = ev, n_id = n_id, n_comm = n_comm,
          stringsAsFactors = FALSE)
      }
    }
  }
  do.call(rbind, rows)
}

out <- list()

# ADVANCE disC
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + E,
  event ~ wave_fe + community_fe + E + (1 | id),
  adv_disC, "ADV disC", "A1", "E")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V,
  event ~ wave_fe + community_fe + V + (1 | id),
  adv_disC, "ADV disC", "V1", "V")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V + E + EDis,
  event ~ wave_fe + community_fe + V + E + EDis + (1 | id),
  adv_disC, "ADV disC", "VAED", c("V","E","EDis"))

# KFP PC disC canonical
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + E_PC,
  event ~ wave_fe + community_fe + E_PC + (1 | id),
  kfp_pc_disC, "KFP PC disC", "A1", "E_PC")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V_PC,
  event ~ wave_fe + community_fe + V_PC + (1 | id),
  kfp_pc_disC, "KFP PC disC", "V1", "V_PC")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V_PC + E_PC + EDis_PC,
  event ~ wave_fe + community_fe + V_PC + E_PC + EDis_PC + (1 | id),
  kfp_pc_disC, "KFP PC disC", "VAED", c("V_PC","E_PC","EDis_PC"))

# KFP modern6 disC
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + E,
  event ~ wave_fe + community_fe + E + (1 | id),
  kfp_mod_disC, "KFP mod6 disC", "A1", "E")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V,
  event ~ wave_fe + community_fe + V + (1 | id),
  kfp_mod_disC, "KFP mod6 disC", "V1", "V")
out[[length(out)+1]] <- fit_pair(
  event ~ wave_fe + community_fe + V + E + EDis,
  event ~ wave_fe + community_fe + V + E + EDis + (1 | id),
  kfp_mod_disC, "KFP mod6 disC", "VAED", c("V","E","EDis"))

res <- do.call(rbind, out)
cat("\n==== GLMER (1|id) vs GLM cluster-robust on Model C ====\n")
print(res, row.names = FALSE)

saveRDS(res, file.path(here::here(), "playground", "glmer_modelC_results.rds"))
write.csv(res, file.path(here::here(), "playground", "glmer_modelC_results.csv"),
          row.names = FALSE)
cat(sprintf("\nSaved: %s\n", file.path("playground", "glmer_modelC_results.csv")))

cat("\n==== ICC summary by panel ====\n")
icc_summ <- aggregate(ICC ~ panel, data = res[!is.na(res$ICC), ], FUN = function(x) round(mean(x), 3))
print(icc_summ, row.names = FALSE)

# Significance flips
flips <- with(res, !is.na(p_glm) & !is.na(p_glmer) &
                     ((p_glm < 0.05) != (p_glmer < 0.05)))
cat(sprintf("\nSignificance flips at alpha=0.05 (GLM vs GLMER): %d / %d\n",
            sum(flips), nrow(res)))
if (any(flips)) print(res[flips, c("panel","spec","term","OR_glm","p_glm","OR_glmer","p_glmer")], row.names = FALSE)
