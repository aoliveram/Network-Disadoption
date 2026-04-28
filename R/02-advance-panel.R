# ================================================================
# 02-advance-panel.R
#
# Builds the ADVANCE long panel (person x wave) and computes
# per-wave peer-exposure metrics. Combines what used to be
# two separate scripts (build-panel, compute-exposure).
#
# Outcomes (past-6-month indicator at each wave):
#   ecig    = past_6mo_use_3
#   cig     = past_6mo_use_2
#   alcohol = past_6mo_use_11
#
# For each wave, builds:
#   E_y[i,w]    = mean of alter y at w-1 (row-norm)
#   Nc_y[i,w]   = count of alter y=1 at w-1
#   has_y[i,w]  = 1 if Nc >= 1
#   V_y[v,w]    = school-level prevalence at w
#
# Outputs (in outputs/intermediate/):
#   advance_panel.rds            -- long panel + exposures
#   advance_edges_list.rds       -- list of 8 edge data frames
# ================================================================

suppressMessages({
  library(dplyr)
})
source(file.path(here::here(), "R", "00-config.R"))

cdir  <- ADVANCE_DATA
odir  <- INTERMEDIATE
waves <- 1:8
outcomes <- c("ecig" = 3, "cig" = 2, "alcohol" = 11)

read_wave <- function(w) {
  f <- file.path(cdir, sprintf("w%d_adv_data.csv", w))
  if (w == 1) f <- file.path(cdir, "w1_adv_data.csv")
  d <- read.csv(f, stringsAsFactors = FALSE, check.names = TRUE)
  names(d) <- tolower(names(d))
  id_col  <- if ("record_id" %in% names(d)) "record_id" else "w1_record_id"
  sch_col <- if ("schoolid" %in% names(d)) "schoolid" else sprintf("w%d_schoolid", w)
  out <- data.frame(record_id = d[[id_col]], schoolid = d[[sch_col]], wave = w)
  for (nm in names(outcomes)) {
    sub <- outcomes[[nm]]
    v6  <- sprintf("w%d_past_6mo_use_%d", w, sub)
    out[[nm]] <- if (v6 %in% names(d)) suppressWarnings(as.integer(d[[v6]])) else NA_integer_
  }
  for (dem in c("dem_gender", "race", "eth")) {
    v <- sprintf("w%d_%s", w, dem)
    if (v %in% names(d)) out[[dem]] <- suppressWarnings(as.integer(d[[v]]))
  }
  out
}

panels <- lapply(waves, read_wave)
panel  <- do.call(rbind, lapply(panels, function(x) {
  need <- c("record_id","schoolid","wave","ecig","cig","alcohol","dem_gender","race","eth")
  for (n in need) if (!n %in% names(x)) x[[n]] <- NA
  x[, need]
}))

schools_keep <- c(101,102,103,104,105,106,107,108,112,113,114,201,212,213,214)
panel <- panel[panel$schoolid %in% schools_keep, ]

bad <- function(x) { x[!x %in% c(0L,1L)] <- NA_integer_; x }
panel$ecig    <- bad(panel$ecig)
panel$cig     <- bad(panel$cig)
panel$alcohol <- bad(panel$alcohol)

cat("Panel rows per wave:\n"); print(table(panel$wave))
cat("\nE-cig (past 6mo) prevalence by wave:\n")
print(round(tapply(panel$ecig, panel$wave, mean, na.rm = TRUE), 3))

read_edges <- function(w) {
  f <- file.path(cdir, sprintf("w%dedges_clean.csv", w))
  e <- read.csv(f, stringsAsFactors = FALSE)
  names(e) <- tolower(names(e))
  e
}
edges_list <- lapply(waves, read_edges)
names(edges_list) <- paste0("w", waves)
cat("\nEdges per wave:\n"); print(sapply(edges_list, nrow))

# ---- compute exposures ----
for (y in c("ecig","cig","alcohol")) {
  panel[[paste0("E_",  y)]]   <- NA_real_
  panel[[paste0("Nc_", y)]]   <- NA_integer_
  panel[[paste0("has_",y)]]   <- NA_integer_
  panel[[paste0("Nobs_",y)]]  <- NA_integer_
  panel[[paste0("V_",  y)]]   <- NA_real_
}
panel$out_deg <- NA_integer_

for (w in waves) {
  cat(sprintf("Wave %d... ", w))
  e <- edges_list[[paste0("w", w)]]
  pw <- panel[panel$wave == w, ]
  lut <- list()
  for (y in c("ecig","cig","alcohol")) lut[[y]] <- setNames(pw[[y]], pw$record_id)
  od <- table(e$ego)
  idx_in_panel <- which(panel$wave == w)
  ids <- panel$record_id[idx_in_panel]
  e_split <- split(e$alter, e$ego)
  V_tab <- lapply(c("ecig","cig","alcohol"), function(y) tapply(pw[[y]], pw$schoolid, mean, na.rm = TRUE))
  names(V_tab) <- c("ecig","cig","alcohol")

  for (k in seq_along(idx_in_panel)) {
    id <- ids[k]; row <- idx_in_panel[k]
    panel$out_deg[row] <- if (as.character(id) %in% names(od)) as.integer(od[as.character(id)]) else 0L
    alters <- e_split[[as.character(id)]]
    if (is.null(alters)) {
      for (y in c("ecig","cig","alcohol")) {
        panel[[paste0("Nc_",y)]][row]   <- 0L
        panel[[paste0("has_",y)]][row]  <- 0L
        panel[[paste0("Nobs_",y)]][row] <- 0L
      }
    } else {
      for (y in c("ecig","cig","alcohol")) {
        vals <- lut[[y]][as.character(alters)]
        ok <- !is.na(vals); nobs <- sum(ok)
        if (nobs == 0) {
          panel[[paste0("Nc_",y)]][row]   <- 0L
          panel[[paste0("has_",y)]][row]  <- 0L
          panel[[paste0("Nobs_",y)]][row] <- 0L
        } else {
          nc <- sum(vals[ok] == 1L)
          panel[[paste0("E_",y)]][row]    <- nc / nobs
          panel[[paste0("Nc_",y)]][row]   <- as.integer(nc)
          panel[[paste0("has_",y)]][row]  <- as.integer(nc >= 1)
          panel[[paste0("Nobs_",y)]][row] <- as.integer(nobs)
        }
      }
    }
    sid <- as.character(panel$schoolid[row])
    for (y in c("ecig","cig","alcohol")) {
      v <- V_tab[[y]][sid]
      panel[[paste0("V_",y)]][row] <- if (length(v)) as.numeric(v) else NA_real_
    }
  }
}
cat("done\n")

saveRDS(panel,      file.path(odir, "advance_panel.rds"))
saveRDS(edges_list, file.path(odir, "advance_edges_list.rds"))
cat(sprintf("Saved: %s\n", file.path(odir, "advance_panel.rds")))
cat(sprintf("Saved: %s\n", file.path(odir, "advance_edges_list.rds")))
