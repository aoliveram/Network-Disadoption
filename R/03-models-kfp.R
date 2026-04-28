# ================================================================
# 03-models-kfp.R
#
# Comprehensive KFP regression battery.
#
# Inputs:
#   outputs/intermediate/kfp_canonical.rds  (fpt + cfp episodes)
#   outputs/intermediate/kfp_fptonly.rds    (fpt episodes only)
#
# Outputs all coefficient tables to outputs/intermediate/kfp_all_results.rds
#
# Coverage:
#   - PC adoption (canonical):
#       basic battery + E^modern + prior_modern_nonPC + covariates
#   - modern6 adoption (canonical): basic battery
#   - PC disadoption A/B/C: canonical + fpt-only, with/without covariates
#   - modern6 disadoption A/B/C: canonical only (sanity)
#
# Specs in each battery:
#   F0, A1, C1, D1, H, ED, V1, V2, AED, VAED
#   (+cov versions add children + age + agemar)
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
covar <- data.frame(
  i        = seq_len(nrow(kfamily)),
  children = as.numeric(kfamily$sons) + as.numeric(kfamily$daughts),
  age      = as.numeric(kfamily$age),
  agemar   = as.numeric(kfamily$agemar)
)

# ---- helpers ----
fit_logit <- function(formula, data) {
  fit <- glm(formula, data = data, family = binomial())
  vc  <- tryCatch(sandwich::vcovCL(fit, cluster = ~village, type = "HC0"),
                  error = function(e) sandwich::vcovHC(fit, type = "HC0"))
  ct  <- lmtest::coeftest(fit, vcov. = vc)
  list(ct = ct, n = nrow(fit$model), events = sum(fit$model[[1]]),
       aic = AIC(fit))
}
row_of <- function(label, r, term) {
  if (!term %in% rownames(r$ct)) return(data.frame(model=label, term=term,
       OR=NA_real_, p=NA_real_, n=r$n, ev=r$events, aic=round(r$aic,1)))
  z <- r$ct[term,]
  data.frame(model=label, term=term,
             OR=round(exp(z["Estimate"]),3),
             p=signif(z["Pr(>|z|)"],3),
             n=r$n, ev=r$events, aic=round(r$aic,1))
}
TtN <- function() 10L

# ---- core compute on panel object ----
compute_panel_predictors <- function(po) {
  n <- nrow(po$state_PC); Tt <- po$Tt
  state_PC      <- po$state_PC
  state_modern  <- po$state_modern
  class_at_t    <- po$class_at_t
  village       <- po$village
  A             <- po$A

  # Treatment A (NA -> 0)
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
  has_PC  <- Nc_PC  >= 1
  has_mod <- Nc_mod >= 1

  make_em <- function(M) {
    Emax <- matrix(NA_real_, n, Tt)
    for (i in 1:n) {
      cm <- cummax(ifelse(is.na(M[i,]), -Inf, M[i,]))
      cm[is.infinite(cm)] <- NA
      Emax[i, ] <- cm
    }
    list(Emax = Emax, EDis = Emax - M)
  }
  pc_em  <- make_em(E_PC); mod_em <- make_em(E_mod)

  V_PC <- V_mod <- matrix(NA_real_, n, Tt)
  for (t in 2:Tt) for (v in sort(unique(village))) {
    idx <- which(village == v)
    V_PC[idx,  t] <- mean(state_PC[idx,     t-1], na.rm = TRUE)
    V_mod[idx, t] <- mean(state_modern[idx, t-1], na.rm = TRUE)
  }

  prior_mn <- matrix(0L, n, Tt)
  for (i in 1:n) {
    is_mn <- as.integer(!is.na(class_at_t[i, ]) & class_at_t[i, ] == "modern_nonPC")
    cm <- cummax(is_mn)
    prior_mn[i, ] <- c(0L, cm[-Tt])
  }

  list(state_PC=state_PC, state_modern=state_modern, class_at_t=class_at_t,
       village=village,
       E_PC=E_PC, E_mod=E_mod, Nc_PC=Nc_PC, Nc_mod=Nc_mod,
       has_PC=has_PC, has_mod=has_mod,
       Emax_PC=pc_em$Emax, EDis_PC=pc_em$EDis,
       Emax_mod=mod_em$Emax, EDis_mod=mod_em$EDis,
       V_PC=V_PC, V_mod=V_mod, prior_mn=prior_mn, Tt=Tt, n=n)
}

# ---- panel-builders for adoption / disA / disB / disC ----
build_adopt_PC <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  first_PC <- apply(pp$state_PC, 1, function(v) {
    ones <- which(v == 1L); if (!length(ones)) NA_integer_ else as.integer(min(ones))
  })
  rows <- list()
  for (i in 1:n) {
    end_t <- if (is.na(first_PC[i])) Tt else first_PC[i]
    if (end_t < 2) next
    for (t in 2:end_t) {
      rows[[length(rows)+1]] <- list(
        i=i, t=t,
        event = as.integer(!is.na(first_PC[i]) && t == first_PC[i]),
        E_PC = pp$E_PC[i,t], E_mod = pp$E_mod[i,t],
        Nc_PC = pp$Nc_PC[i,t], Nc_mod = pp$Nc_mod[i,t],
        has_PC = as.integer(pp$has_PC[i,t]), has_mod = as.integer(pp$has_mod[i,t]),
        Emax_PC = pp$Emax_PC[i,t], EDis_PC = pp$EDis_PC[i,t],
        V_PC = pp$V_PC[i,t], V_mod = pp$V_mod[i,t],
        prior_mn = pp$prior_mn[i,t], village = pp$village[i])
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_adopt_modern <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  first_mod <- apply(pp$state_modern, 1, function(v) {
    ones <- which(v == 1L); if (!length(ones)) NA_integer_ else as.integer(min(ones))
  })
  rows <- list()
  for (i in 1:n) {
    end_t <- if (is.na(first_mod[i])) Tt else first_mod[i]
    if (end_t < 2) next
    for (t in 2:end_t) {
      rows[[length(rows)+1]] <- list(
        i=i, t=t, event=as.integer(!is.na(first_mod[i]) && t == first_mod[i]),
        E=pp$E_mod[i,t], Nc=pp$Nc_mod[i,t],
        has=as.integer(pp$has_mod[i,t]),
        Emax=pp$Emax_mod[i,t], EDis=pp$EDis_mod[i,t],
        V=pp$V_mod[i,t], village=pp$village[i])
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_dis_PC <- function(pp, kind) {
  n <- pp$n; Tt <- pp$Tt
  state <- pp$state_PC; class_at <- pp$class_at_t
  rows <- list()
  for (i in 1:n) {
    if (kind == "B") {
      first_pc <- which(state[i,] == 1L)[1]
      if (is.na(first_pc) || first_pc == Tt) next
      for (t in (first_pc+1L):Tt) {
        if (is.na(state[i, t-1]) || state[i, t-1] != 1L) break
        if (is.na(state[i, t])) next
        cls <- class_at[i, t]
        if (!is.na(cls) && cls == "modern_nonPC") break  # censure
        ev <- as.integer(state[i, t] == 0L)
        rows[[length(rows)+1]] <- list(i=i, t=t, event=ev,
          E_PC=pp$E_PC[i,t], Nc_PC=pp$Nc_PC[i,t],
          has_PC=as.integer(pp$has_PC[i,t]),
          Emax_PC=pp$Emax_PC[i,t], EDis_PC=pp$EDis_PC[i,t],
          V_PC=pp$V_PC[i,t], village=pp$village[i])
        if (ev == 1L) break
      }
    } else {
      for (t in 2:Tt) {
        if (is.na(state[i, t-1]) || state[i, t-1] != 1L) next
        if (is.na(state[i, t])) next
        cls <- class_at[i, t]
        if (!is.na(cls) && cls == "modern_nonPC") next  # censure
        ev <- as.integer(state[i, t] == 0L)
        if (kind == "A" && ev == 1L && t < Tt &&
            !is.na(state[i, t+1]) && state[i, t+1] == 1L) next  # transient
        rows[[length(rows)+1]] <- list(i=i, t=t, event=ev,
          E_PC=pp$E_PC[i,t], Nc_PC=pp$Nc_PC[i,t],
          has_PC=as.integer(pp$has_PC[i,t]),
          Emax_PC=pp$Emax_PC[i,t], EDis_PC=pp$EDis_PC[i,t],
          V_PC=pp$V_PC[i,t], village=pp$village[i])
      }
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_dis_modern <- function(pp, kind) {
  n <- pp$n; Tt <- pp$Tt
  state <- pp$state_modern
  rows <- list()
  for (i in 1:n) {
    if (kind == "B") {
      first <- which(state[i,] == 1L)[1]
      if (is.na(first) || first == Tt) next
      for (t in (first+1L):Tt) {
        if (is.na(state[i, t-1]) || state[i, t-1] != 1L) break
        if (is.na(state[i, t])) next
        ev <- as.integer(state[i, t] == 0L)
        rows[[length(rows)+1]] <- list(i=i, t=t, event=ev,
          E=pp$E_mod[i,t], Nc=pp$Nc_mod[i,t], has=as.integer(pp$has_mod[i,t]),
          Emax=pp$Emax_mod[i,t], EDis=pp$EDis_mod[i,t],
          V=pp$V_mod[i,t], village=pp$village[i])
        if (ev == 1L) break
      }
    } else {
      for (t in 2:Tt) {
        if (is.na(state[i, t-1]) || state[i, t-1] != 1L) next
        if (is.na(state[i, t])) next
        ev <- as.integer(state[i, t] == 0L)
        if (kind == "A" && ev == 1L && t < Tt &&
            !is.na(state[i, t+1]) && state[i, t+1] == 1L) next
        rows[[length(rows)+1]] <- list(i=i, t=t, event=ev,
          E=pp$E_mod[i,t], Nc=pp$Nc_mod[i,t], has=as.integer(pp$has_mod[i,t]),
          Emax=pp$Emax_mod[i,t], EDis=pp$EDis_mod[i,t],
          V=pp$V_mod[i,t], village=pp$village[i])
      }
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}

# ---- battery runner: handles both PC (named E_PC etc) and modern (named E etc) ----
run_PC_disadopt_battery <- function(pan, label, with_cov = FALSE) {
  pan$t <- factor(pan$t); pan$village_fe <- factor(pan$village)
  if (with_cov) pan <- merge(pan, covar, by="i", all.x = TRUE)
  base <- if (with_cov) "+ children + age + agemar" else ""
  fmla <- function(x) as.formula(sprintf("event ~ t + village_fe + %s %s", x, base))
  out <- list(
    F0   = fit_logit(if (with_cov) event ~ t + village_fe + children + age + agemar
                     else event ~ t + village_fe, pan),
    A1   = fit_logit(fmla("E_PC"), pan),
    C1   = fit_logit(fmla("has_PC"), pan),
    D1   = fit_logit(fmla("Nc_PC"), pan),
    H    = fit_logit(fmla("Emax_PC"), pan),
    ED   = fit_logit(fmla("EDis_PC"), pan),
    V1   = fit_logit(fmla("V_PC"), pan),
    V2   = fit_logit(fmla("V_PC + E_PC"), pan),
    AED  = fit_logit(fmla("E_PC + EDis_PC"), pan),
    VAED = fit_logit(fmla("V_PC + E_PC + EDis_PC"), pan)
  )
  rbind(
    row_of(paste(label,"F0"),  out$F0,  "(Intercept)"),
    row_of(paste(label,"A1"),  out$A1,  "E_PC"),
    row_of(paste(label,"C1"),  out$C1,  "has_PC"),
    row_of(paste(label,"D1"),  out$D1,  "Nc_PC"),
    row_of(paste(label,"H"),   out$H,   "Emax_PC"),
    row_of(paste(label,"ED"),  out$ED,  "EDis_PC"),
    row_of(paste(label,"V1"),  out$V1,  "V_PC"),
    row_of(paste(label,"V2:V"),out$V2,  "V_PC"),
    row_of(paste(label,"V2:E"),out$V2,  "E_PC"),
    row_of(paste(label,"AED:E"), out$AED, "E_PC"),
    row_of(paste(label,"AED:ED"),out$AED, "EDis_PC"),
    row_of(paste(label,"VAED:V"),out$VAED, "V_PC"),
    row_of(paste(label,"VAED:E"),out$VAED, "E_PC"),
    row_of(paste(label,"VAED:ED"),out$VAED, "EDis_PC")
  )
}

run_mod_disadopt_battery <- function(pan, label, with_cov = FALSE) {
  pan$t <- factor(pan$t); pan$village_fe <- factor(pan$village)
  if (with_cov) pan <- merge(pan, covar, by="i", all.x = TRUE)
  base <- if (with_cov) "+ children + age + agemar" else ""
  fmla <- function(x) as.formula(sprintf("event ~ t + village_fe + %s %s", x, base))
  out <- list(
    F0   = fit_logit(if (with_cov) event ~ t + village_fe + children + age + agemar
                     else event ~ t + village_fe, pan),
    A1   = fit_logit(fmla("E"), pan),
    C1   = fit_logit(fmla("has"), pan),
    D1   = fit_logit(fmla("Nc"), pan),
    H    = fit_logit(fmla("Emax"), pan),
    ED   = fit_logit(fmla("EDis"), pan),
    V1   = fit_logit(fmla("V"), pan),
    V2   = fit_logit(fmla("V + E"), pan),
    AED  = fit_logit(fmla("E + EDis"), pan),
    VAED = fit_logit(fmla("V + E + EDis"), pan)
  )
  rbind(
    row_of(paste(label,"F0"),  out$F0,  "(Intercept)"),
    row_of(paste(label,"A1"),  out$A1,  "E"),
    row_of(paste(label,"C1"),  out$C1,  "has"),
    row_of(paste(label,"D1"),  out$D1,  "Nc"),
    row_of(paste(label,"H"),   out$H,   "Emax"),
    row_of(paste(label,"ED"),  out$ED,  "EDis"),
    row_of(paste(label,"V1"),  out$V1,  "V"),
    row_of(paste(label,"V2:V"),out$V2,  "V"),
    row_of(paste(label,"V2:E"),out$V2,  "E"),
    row_of(paste(label,"AED:E"), out$AED, "E"),
    row_of(paste(label,"AED:ED"),out$AED, "EDis"),
    row_of(paste(label,"VAED:V"),out$VAED, "V"),
    row_of(paste(label,"VAED:E"),out$VAED, "E"),
    row_of(paste(label,"VAED:ED"),out$VAED, "EDis")
  )
}

# ================================================================
# load both panels
# ================================================================
canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
fptonly   <- readRDS(file.path(odir, "kfp_fptonly.rds"))

pp_can <- compute_panel_predictors(canonical)
pp_fpt <- compute_panel_predictors(fptonly)

results <- list()

# ================================================================
# ADOPTION (canonical only)
# ================================================================
cat("\n==== KFP PC adoption (canonical) ====\n")
ad_pc <- build_adopt_PC(pp_can)
ad_pc$t <- factor(ad_pc$t); ad_pc$village_fe <- factor(ad_pc$village)
ad_pc_cov <- merge(ad_pc, covar, by="i", all.x = TRUE)
fm  <- function(x) as.formula(sprintf("event ~ t + village_fe + %s", x))
fmc <- function(x) as.formula(sprintf("event ~ t + village_fe + %s + children + age + agemar", x))

specs_pc <- list(
  F0       = event ~ t + village_fe,
  A1_PC    = fm("E_PC"),
  A1_mod   = fm("E_mod"),
  C1_PC    = fm("has_PC"),
  C1_mod   = fm("has_mod"),
  D1_PC    = fm("Nc_PC"),
  D1_mod   = fm("Nc_mod"),
  H_PC     = fm("Emax_PC"),
  ED_PC    = fm("EDis_PC"),
  V1_PC    = fm("V_PC"),
  V1_mod   = fm("V_mod"),
  V2_PC    = fm("V_PC + E_PC"),
  V2_mod   = fm("V_mod + E_mod"),
  AED_PC   = fm("E_PC + EDis_PC"),
  VAED_PC  = fm("V_PC + E_PC + EDis_PC"),
  prior    = fm("prior_mn"),
  A1pr_PC  = fm("E_PC + prior_mn"),
  A1pr_mod = fm("E_mod + prior_mn"),
  V1pr_PC  = fm("V_PC + prior_mn")
)
specs_pc_cov <- list(
  F0       = event ~ t + village_fe + children + age + agemar,
  A1_PC    = fmc("E_PC"),
  A1_mod   = fmc("E_mod"),
  C1_PC    = fmc("has_PC"),
  C1_mod   = fmc("has_mod"),
  D1_PC    = fmc("Nc_PC"),
  D1_mod   = fmc("Nc_mod"),
  H_PC     = fmc("Emax_PC"),
  ED_PC    = fmc("EDis_PC"),
  V1_PC    = fmc("V_PC"),
  V1_mod   = fmc("V_mod"),
  V2_PC    = fmc("V_PC + E_PC"),
  V2_mod   = fmc("V_mod + E_mod"),
  AED_PC   = fmc("E_PC + EDis_PC"),
  VAED_PC  = fmc("V_PC + E_PC + EDis_PC"),
  prior    = fmc("prior_mn"),
  A1pr_PC  = fmc("E_PC + prior_mn"),
  A1pr_mod = fmc("E_mod + prior_mn"),
  V1pr_PC  = fmc("V_PC + prior_mn")
)
out_a <- lapply(specs_pc,     fit_logit, data = ad_pc)
out_b <- lapply(specs_pc_cov, fit_logit, data = ad_pc_cov)

extract_pc_table <- function(out, label) {
  rbind(
    row_of(paste(label,"F0"),       out$F0,       "(Intercept)"),
    row_of(paste(label,"A1 E^PC"),  out$A1_PC,    "E_PC"),
    row_of(paste(label,"A1 E^mod"), out$A1_mod,   "E_mod"),
    row_of(paste(label,"C1 has^PC"),out$C1_PC,    "has_PC"),
    row_of(paste(label,"C1 has^mod"),out$C1_mod,  "has_mod"),
    row_of(paste(label,"D1 Nc^PC"), out$D1_PC,    "Nc_PC"),
    row_of(paste(label,"D1 Nc^mod"),out$D1_mod,   "Nc_mod"),
    row_of(paste(label,"H E^max"),  out$H_PC,     "Emax_PC"),
    row_of(paste(label,"ED"),       out$ED_PC,    "EDis_PC"),
    row_of(paste(label,"V1 V^PC"),  out$V1_PC,    "V_PC"),
    row_of(paste(label,"V1 V^mod"), out$V1_mod,   "V_mod"),
    row_of(paste(label,"V2:V^PC"),  out$V2_PC,    "V_PC"),
    row_of(paste(label,"V2:E^PC"),  out$V2_PC,    "E_PC"),
    row_of(paste(label,"V2:V^mod"), out$V2_mod,   "V_mod"),
    row_of(paste(label,"V2:E^mod"), out$V2_mod,   "E_mod"),
    row_of(paste(label,"AED:E"),    out$AED_PC,   "E_PC"),
    row_of(paste(label,"AED:ED"),   out$AED_PC,   "EDis_PC"),
    row_of(paste(label,"VAED:V"),   out$VAED_PC,  "V_PC"),
    row_of(paste(label,"VAED:E"),   out$VAED_PC,  "E_PC"),
    row_of(paste(label,"VAED:ED"),  out$VAED_PC,  "EDis_PC"),
    row_of(paste(label,"prior_mn"), out$prior,    "prior_mn"),
    row_of(paste(label,"A1+prior:E^PC"), out$A1pr_PC, "E_PC"),
    row_of(paste(label,"A1+prior:prior"),out$A1pr_PC, "prior_mn"),
    row_of(paste(label,"A1+prior:E^mod"),out$A1pr_mod, "E_mod"),
    row_of(paste(label,"V1+prior:V^PC"), out$V1pr_PC,  "V_PC")
  )
}
results$kfp_pc_adopt    <- extract_pc_table(out_a, "PC")
results$kfp_pc_adopt_cov<- extract_pc_table(out_b, "PC+cov")
print(results$kfp_pc_adopt, row.names=FALSE)
cat("\n--- + covariates ---\n")
print(results$kfp_pc_adopt_cov, row.names=FALSE)

cat("\n==== KFP modern6 adoption (canonical) ====\n")
ad_m <- build_adopt_modern(pp_can)
ad_m$t <- factor(ad_m$t); ad_m$village_fe <- factor(ad_m$village)
results$kfp_mod_adopt     <- run_mod_disadopt_battery(ad_m, "mod6 adopt", with_cov = FALSE)
results$kfp_mod_adopt_cov <- run_mod_disadopt_battery(ad_m, "mod6 adopt+cov", with_cov = TRUE)
print(results$kfp_mod_adopt, row.names=FALSE)
cat("\n--- + covariates ---\n")
print(results$kfp_mod_adopt_cov, row.names=FALSE)

# ================================================================
# DISADOPTION PC: canonical & fpt-only, with/without cov
# ================================================================
for (kind in c("A","B","C")) {
  for (panel_name in c("can","fpt")) {
    pp <- if (panel_name == "can") pp_can else pp_fpt
    pan <- build_dis_PC(pp, kind)
    if (is.null(pan) || nrow(pan) == 0) next
    label <- sprintf("PC dis%s [%s]", kind, panel_name)
    cat(sprintf("\n==== %s : n=%d events=%d ====\n", label, nrow(pan), sum(pan$event)))
    results[[sprintf("dis%s_PC_%s", kind, panel_name)]]    <- run_PC_disadopt_battery(pan, label, FALSE)
    results[[sprintf("dis%s_PC_%s_cov", kind, panel_name)]]<- run_PC_disadopt_battery(pan, paste(label,"+cov"), TRUE)
    print(results[[sprintf("dis%s_PC_%s", kind, panel_name)]], row.names=FALSE)
  }
}

# ================================================================
# DISADOPTION modern6: canonical only
# ================================================================
for (kind in c("A","B","C")) {
  pan <- build_dis_modern(pp_can, kind)
  label <- sprintf("mod6 dis%s [can]", kind)
  cat(sprintf("\n==== %s : n=%d events=%d ====\n", label, nrow(pan), sum(pan$event)))
  results[[sprintf("dis%s_mod_can", kind)]]    <- run_mod_disadopt_battery(pan, label, FALSE)
  results[[sprintf("dis%s_mod_can_cov", kind)]]<- run_mod_disadopt_battery(pan, paste(label,"+cov"), TRUE)
}

saveRDS(results, file.path(odir, "kfp_all_results.rds"))
cat(sprintf("\nSaved: %s\n", file.path(odir, "kfp_all_results.rds")))
