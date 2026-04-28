# ================================================================
# 00-config.R
#
# Path configuration. Sourced by every other script in R/.
# Override any path via environment variables before sourcing.
# ================================================================

if (!requireNamespace("here", quietly = TRUE)) {
  install.packages("here", repos = "https://cloud.r-project.org")
}

ROOT         <- Sys.getenv("ND_ROOT", here::here())
DATA         <- file.path(ROOT, "data")
KFP_DATA     <- file.path(DATA, "kfp")     # public via netdiffuseR::kfamily
ADVANCE_DATA <- Sys.getenv("ND_ADVANCE_DATA",
                           file.path(DATA, "advance", "Cleaned-Data"))

OUTPUTS      <- file.path(ROOT, "outputs")
INTERMEDIATE <- file.path(OUTPUTS, "intermediate")
TABLES       <- file.path(OUTPUTS, "tables")
FIGURES      <- file.path(OUTPUTS, "figures")

dir.create(INTERMEDIATE, showWarnings = FALSE, recursive = TRUE)
dir.create(TABLES,       showWarnings = FALSE, recursive = TRUE)
dir.create(FIGURES,      showWarnings = FALSE, recursive = TRUE)
