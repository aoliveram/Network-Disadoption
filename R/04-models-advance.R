# ================================================================
# 04-models-advance.R
#
# ADVANCE e-cig adoption + disadoption (A/B/C) battery
# (10 specs: F0, A1, C1, D1, H, ED, V1, V2, AED, VAED).
# Plus positive control (cigarette adoption) and placebo
# (cigarette peers -> e-cig adoption).
# ================================================================

suppressMessages({ library(sandwich); library(lmtest) })
source(file.path(here::here(), "R", "00-config.R"))

adv <- readRDS(file.path(INTERMEDIATE, "advance_panel.rds"))
adv <- adv[order(adv$record_id, adv$wave), ]

lag1 <- function(df, var) {
  out <- rep(NA, nrow(df))
  same <- c(FALSE, df$record_id[-1] == df$record_id[-nrow(df)] &
                   df$wave[-1]      == df$wave[-nrow(df)] + 1L)
  out[same] <- df[[var]][which(same) - 1L]; out
}
lag_next <- function(df, var) {
  out <- rep(NA, nrow(df))
  same <- c(df$record_id[-nrow(df)] == df$record_id[-1] &
            df$wave[-nrow(df)]     == df$wave[-1] - 1L, FALSE)
  out[same] <- df[[var]][which(same) + 1L]; out
}
adv$ecig_prev <- lag1(adv,"ecig"); adv$ecig_next <- lag_next(adv,"ecig")
adv$E_prev    <- lag1(adv,"E_ecig"); adv$Nc_prev <- lag1(adv,"Nc_ecig")
adv$has_prev  <- lag1(adv,"has_ecig"); adv$V_prev <- lag1(adv,"V_ecig")
adv$cig_prev   <- lag1(adv, "cig")
adv$E_cig_prev <- lag1(adv, "E_cig")
adv$has_cig_prev <- lag1(adv, "has_cig")
adv$V_cig_prev <- lag1(adv, "V_cig")
adv$Emax_prev <- NA_real_
for (rr in split(seq_len(nrow(adv)), adv$record_id)) {
  if (length(rr) < 2) next
  e <- adv$E_ecig[rr]; cm <- cummax(ifelse(is.na(e), -Inf, e))
  cm[is.infinite(cm)] <- NA
  adv$Emax_prev[rr][-1] <- cm[-length(cm)]
}
adv$EDis_prev <- adv$Emax_prev - adv$E_prev

fit_logit <- function(formula, data) {
  fit <- glm(formula, data = data, family = binomial())
  vc  <- tryCatch(sandwich::vcovCL(fit, cluster = data$schoolid, type = "HC0"),
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

run_battery <- function(pan, label) {
  pan$wave <- factor(pan$wave); pan$schoolid <- factor(pan$schoolid)
  out <- list(
    F0   = fit_logit(event ~ wave + schoolid, pan),
    A1   = fit_logit(event ~ wave + schoolid + E, pan),
    C1   = fit_logit(event ~ wave + schoolid + has, pan),
    D1   = fit_logit(event ~ wave + schoolid + Nc, pan),
    H    = fit_logit(event ~ wave + schoolid + Emax, pan),
    ED   = fit_logit(event ~ wave + schoolid + EDis, pan),
    V1   = fit_logit(event ~ wave + schoolid + V, pan),
    V2   = fit_logit(event ~ wave + schoolid + V + E, pan),
    AED  = fit_logit(event ~ wave + schoolid + E + EDis, pan),
    VAED = fit_logit(event ~ wave + schoolid + V + E + EDis, pan)
  )
  rbind(
    row_of(paste(label,"F0"),   out$F0,  "(Intercept)"),
    row_of(paste(label,"A1"),   out$A1,  "E"),
    row_of(paste(label,"C1"),   out$C1,  "has"),
    row_of(paste(label,"D1"),   out$D1,  "Nc"),
    row_of(paste(label,"H"),    out$H,   "Emax"),
    row_of(paste(label,"ED"),   out$ED,  "EDis"),
    row_of(paste(label,"V1"),   out$V1,  "V"),
    row_of(paste(label,"V2:V"), out$V2,  "V"),
    row_of(paste(label,"V2:E"), out$V2,  "E"),
    row_of(paste(label,"AED:E"), out$AED, "E"),
    row_of(paste(label,"AED:ED"),out$AED, "EDis"),
    row_of(paste(label,"VAED:V"), out$VAED, "V"),
    row_of(paste(label,"VAED:E"), out$VAED, "E"),
    row_of(paste(label,"VAED:ED"),out$VAED, "EDis")
  )
}

# Adoption
ever_before <- ave(adv$ecig, adv$record_id, FUN = function(x) cummax(replace(x, is.na(x), 0)))
adv$ever_before_t <- c(0, ever_before[-length(ever_before)])
adv$ever_before_t[c(TRUE, adv$record_id[-1] != adv$record_id[-nrow(adv)])] <- 0
ad <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 0 & adv$ever_before_t == 0 & !is.na(adv$ecig), ]
ad_pan <- data.frame(event=as.integer(ad$ecig==1), wave=ad$wave, schoolid=ad$schoolid,
                     E=ad$E_prev, has=ad$has_prev, Nc=ad$Nc_prev,
                     Emax=ad$Emax_prev, EDis=ad$EDis_prev, V=ad$V_prev)

# Disadoption A (stable)
disA <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 1 & !is.na(adv$ecig), ]
disA <- disA[!(disA$ecig == 0 & !is.na(disA$ecig_next) & disA$ecig_next == 1), ]
panA <- data.frame(event=as.integer(disA$ecig==0), wave=disA$wave, schoolid=disA$schoolid,
                   E=disA$E_prev, has=disA$has_prev, Nc=disA$Nc_prev,
                   Emax=disA$Emax_prev, EDis=disA$EDis_prev, V=disA$V_prev)

# Disadoption B (unstable)
disB_rows <- integer(0)
for (sp in split(seq_len(nrow(adv)), adv$record_id)) {
  if (length(sp) < 2) next
  ec <- adv$ecig[sp]; first_adopt <- which(ec == 1)[1]
  if (is.na(first_adopt) || first_adopt == length(sp)) next
  for (k in seq(first_adopt + 1L, length(sp))) {
    if (!is.na(adv$ecig[sp[k-1]]) && adv$ecig[sp[k-1]] == 1 && !is.na(adv$ecig[sp[k]])) {
      disB_rows <- c(disB_rows, sp[k])
      if (adv$ecig[sp[k]] == 0) break
    } else break
  }
}
disB <- adv[disB_rows, ]
panB <- data.frame(event=as.integer(disB$ecig==0), wave=disB$wave, schoolid=disB$schoolid,
                   E=disB$E_prev, has=disB$has_prev, Nc=disB$Nc_prev,
                   Emax=disB$Emax_prev, EDis=disB$EDis_prev, V=disB$V_prev)

# Disadoption C (recurrent)
disC <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 1 & !is.na(adv$ecig), ]
panC <- data.frame(event=as.integer(disC$ecig==0), wave=disC$wave, schoolid=disC$schoolid,
                   E=disC$E_prev, has=disC$has_prev, Nc=disC$Nc_prev,
                   Emax=disC$Emax_prev, EDis=disC$EDis_prev, V=disC$V_prev)

results <- list(
  adv_adopt = run_battery(ad_pan, "ADV-adopt"),
  adv_disA  = run_battery(panA, "ADV-disA"),
  adv_disB  = run_battery(panB, "ADV-disB"),
  adv_disC  = run_battery(panC, "ADV-disC")
)

# Positive control: cigarettes
ever_before_cig <- ave(adv$cig, adv$record_id, FUN = function(x) cummax(replace(x, is.na(x), 0)))
adv$ever_before_cig_t <- c(0, ever_before_cig[-length(ever_before_cig)])
adv$ever_before_cig_t[c(TRUE, adv$record_id[-1] != adv$record_id[-nrow(adv)])] <- 0
adc <- adv[!is.na(adv$cig_prev) & adv$cig_prev == 0 & adv$ever_before_cig_t == 0 & !is.na(adv$cig), ]

specs_pc <- list(
  A1 = fit_logit(as.integer(adc$cig==1) ~ factor(adc$wave) + factor(adc$schoolid) + adc$E_cig_prev,
                 data.frame(event=as.integer(adc$cig==1), wave=factor(adc$wave),
                            schoolid=factor(adc$schoolid), x=adc$E_cig_prev)),
  C1 = fit_logit(as.integer(adc$cig==1) ~ factor(adc$wave) + factor(adc$schoolid) + adc$has_cig_prev,
                 data.frame(event=as.integer(adc$cig==1), wave=factor(adc$wave),
                            schoolid=factor(adc$schoolid), x=adc$has_cig_prev))
)

# Cleaner positive control
posc_pan <- data.frame(event=as.integer(adc$cig==1), wave=adc$wave, schoolid=adc$schoolid,
                       E_cig=adc$E_cig_prev, has_cig=adc$has_cig_prev, V_cig=adc$V_cig_prev)
posc_pan$wave <- factor(posc_pan$wave); posc_pan$schoolid <- factor(posc_pan$schoolid)
posc <- list(
  A1 = fit_logit(event ~ wave + schoolid + E_cig, posc_pan),
  C1 = fit_logit(event ~ wave + schoolid + has_cig, posc_pan),
  V1 = fit_logit(event ~ wave + schoolid + V_cig, posc_pan)
)
results$adv_poscontrol <- rbind(
  row_of("Pos cig adopt A1", posc$A1, "E_cig"),
  row_of("Pos cig adopt C1", posc$C1, "has_cig"),
  row_of("Pos cig adopt V1", posc$V1, "V_cig")
)

# Placebo: peer-cig predicting e-cig adoption
plac_pan <- data.frame(event=ad_pan$event, wave=ad_pan$wave, schoolid=ad_pan$schoolid,
                       E_cig=ad$E_cig_prev, has_cig=ad$has_cig_prev)
plac_pan$wave <- factor(plac_pan$wave); plac_pan$schoolid <- factor(plac_pan$schoolid)
plac_pan <- plac_pan[complete.cases(plac_pan), ]
plac <- list(
  A1 = fit_logit(event ~ wave + schoolid + E_cig, plac_pan),
  C1 = fit_logit(event ~ wave + schoolid + has_cig, plac_pan)
)
results$adv_placebo <- rbind(
  row_of("Plac cig->ecig A1", plac$A1, "E_cig"),
  row_of("Plac cig->ecig C1", plac$C1, "has_cig")
)

saveRDS(results, file.path(INTERMEDIATE, "advance_all_results.rds"))
cat(sprintf("Saved: %s\n", file.path(INTERMEDIATE, "advance_all_results.rds")))
for (nm in names(results)) {
  cat(sprintf("\n=== %s ===\n", nm))
  print(results[[nm]], row.names = FALSE)
}
