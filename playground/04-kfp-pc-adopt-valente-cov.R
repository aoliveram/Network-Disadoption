# ================================================================
# playground/04-kfp-pc-adopt-valente-cov.R
#
# Focused refit: KFP PC adoption +cov using Valente's (children, media)
# covariate set. Runs only the spec ladder reported in v3 §3.2.2:
# F0, A1 (PC, modern), C1 (PC, modern), V1, V2, VAED.
# Bypasses the long-running disC glmer batch in R/03-models-kfp.R.
# ================================================================

suppressMessages({
  library(netdiffuseR)
  library(Matrix)
  library(sandwich)
  library(lmtest)
})
source(file.path(here::here(), "R", "00-config.R"))

# Pull only the helpers + panel-builders, skip the main loop.
src <- readLines(file.path(here::here(), "R", "03-models-kfp.R"))
end_idx <- grep("^# load both panels", src) - 1
eval(parse(text = paste(src[1:end_idx], collapse = "\n")), envir = globalenv())

odir <- INTERMEDIATE
canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
pp_can <- compute_panel_predictors(canonical)
ad_pc  <- build_adopt_PC(pp_can)
ad_pc$t <- factor(ad_pc$t); ad_pc$community_fe <- factor(ad_pc$village)
ad_pc_v <- merge(ad_pc, covar_valente, by = "i", all.x = TRUE)

cat(sprintf("PC adoption +cov(valente): n=%d ev=%d unique-i=%d\n",
            nrow(ad_pc_v), sum(ad_pc_v$event), length(unique(ad_pc_v$i))))

fmc <- function(x) as.formula(
  sprintf("event ~ t + community_fe + %s + children + media", x))

specs <- list(
  F0       = event ~ t + community_fe + children + media,
  A1_PC    = fmc("E_PC"),
  A1_mod   = fmc("E_mod"),
  C1_PC    = fmc("has_PC"),
  C1_mod   = fmc("has_mod"),
  V1_PC    = fmc("V_PC"),
  V2_PC    = fmc("V_PC + E_PC"),
  VAED_PC  = fmc("V_PC + E_PC + EDis_PC")
)
out <- lapply(specs, fit_logit, data = ad_pc_v)

tab <- rbind(
  row_of("PC+cov_v F0",            out$F0,      "(Intercept)"),
  row_of("PC+cov_v A1 E^PC",       out$A1_PC,   "E_PC"),
  row_of("PC+cov_v A1 E^mod",      out$A1_mod,  "E_mod"),
  row_of("PC+cov_v C1 has^PC",     out$C1_PC,   "has_PC"),
  row_of("PC+cov_v C1 has^mod",    out$C1_mod,  "has_mod"),
  row_of("PC+cov_v V1 V^PC",       out$V1_PC,   "V_PC"),
  row_of("PC+cov_v V2:V^PC",       out$V2_PC,   "V_PC"),
  row_of("PC+cov_v V2:E^PC",       out$V2_PC,   "E_PC"),
  row_of("PC+cov_v VAED:V",        out$VAED_PC, "V_PC"),
  row_of("PC+cov_v VAED:E",        out$VAED_PC, "E_PC"),
  row_of("PC+cov_v VAED:ED",       out$VAED_PC, "EDis_PC")
)

cat("\n==== KFP PC adoption +cov (children + media) ====\n")
print(tab, row.names = FALSE)

# Per-10pp helpers for V coefficients
cat("\n==== OR per 10pp V (Valente cov) ====\n")
for (v in c("V_PC")) {
  for (s in c("V1_PC", "V2_PC", "VAED_PC")) {
    if (v %in% rownames(out[[s]]$ct)) {
      beta <- out[[s]]$ct[v, "Estimate"]
      cat(sprintf("  %s : %s : OR/unit=%.3f, OR/10pp=%.3f\n",
                  s, v, exp(beta), exp(beta*0.10)))
    }
  }
}

saveRDS(tab, file.path(here::here(), "playground", "kfp_pc_adopt_cov_valente.rds"))
