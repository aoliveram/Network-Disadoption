# ================================================================
# playground/03-modelC-glmer-batteries.R
#
# Runs the full Model C disadoption batteries with glmer + (1|i),
# in a FRESH R session, to populate the v3 report's §6 tables.
#
# Why this is here (and not just inside R/03-models-kfp.R): when run as
# a single Rscript invocation, the disC glmer batch was very slow on
# this hardware, presumably due to resident state / GC pressure from
# the earlier disA + disB GLM fits in the same session. Splitting the
# glmer disC batteries into their own session reliably finishes in a
# few minutes; the production R/03 script still produces these
# results, but the playground script here is a faster way to refresh
# the numbers when iterating.
#
# Outputs: playground/modelC_glmer_results.rds + .csv
# ================================================================

suppressMessages({
  library(netdiffuseR)
  library(Matrix)
  library(lme4)
})

source(file.path(here::here(), "R", "00-config.R"))

# Pull in shared helpers + panel-builders from R/03-models-kfp.R, but
# stop before its loop body executes.
src <- readLines(file.path(here::here(), "R", "03-models-kfp.R"))
end_idx <- grep("^# load both panels", src) - 1
eval(parse(text = paste(src[1:end_idx], collapse = "\n")), envir = globalenv())

odir <- INTERMEDIATE
canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
fptonly   <- readRDS(file.path(odir, "kfp_fptonly.rds"))

pp_can <- compute_panel_predictors(canonical)
pp_fpt <- compute_panel_predictors(fptonly)

results <- list()

# KFP PC disC: canonical (with/without cov)
pan <- build_dis_PC(pp_can, "C")
cat(sprintf("\n==== PC disC [can] glmer : n=%d ev=%d ====\n", nrow(pan), sum(pan$event)))
results$disC_PC_can     <- run_PC_disadopt_battery_glmer(pan, "PC disC [can]", FALSE)
print(results$disC_PC_can, row.names = FALSE)
cat(sprintf("\n==== PC disC [can] +cov ====\n"))
results$disC_PC_can_cov <- run_PC_disadopt_battery_glmer(pan, "PC disC [can] +cov", TRUE)
print(results$disC_PC_can_cov, row.names = FALSE)

# KFP PC disC: fpt-only (with/without cov)
pan <- build_dis_PC(pp_fpt, "C")
cat(sprintf("\n==== PC disC [fpt] glmer : n=%d ev=%d ====\n", nrow(pan), sum(pan$event)))
results$disC_PC_fpt     <- run_PC_disadopt_battery_glmer(pan, "PC disC [fpt]", FALSE)
print(results$disC_PC_fpt, row.names = FALSE)
cat(sprintf("\n==== PC disC [fpt] +cov ====\n"))
results$disC_PC_fpt_cov <- run_PC_disadopt_battery_glmer(pan, "PC disC [fpt] +cov", TRUE)
print(results$disC_PC_fpt_cov, row.names = FALSE)

# KFP modern6 disC (canonical, with/without cov)
pan <- build_dis_modern(pp_can, "C")
cat(sprintf("\n==== mod6 disC [can] glmer : n=%d ev=%d ====\n", nrow(pan), sum(pan$event)))
results$disC_mod_can     <- run_mod_disadopt_battery_glmer(pan, "mod6 disC [can]", FALSE)
print(results$disC_mod_can, row.names = FALSE)
cat(sprintf("\n==== mod6 disC [can] +cov ====\n"))
results$disC_mod_can_cov <- run_mod_disadopt_battery_glmer(pan, "mod6 disC [can] +cov", TRUE)
print(results$disC_mod_can_cov, row.names = FALSE)

saveRDS(results, file.path(here::here(), "playground", "modelC_glmer_results.rds"))
cat(sprintf("\nSaved: %s\n",
            file.path("playground", "modelC_glmer_results.rds")))
