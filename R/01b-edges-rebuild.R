# ================================================================
# 01b-edges-rebuild.R  (v4b)
#
# Reconstruct the friendship edge files for W1..W10 from the 042326
# XLSX releases. Output: data/advance/Cleaned-Data-042326/wNedges_clean.csv.
#
# Construction rule (uniform across all 10 waves):
#
#   For each student i with w#_schoolid non-NA, find their school s.
#   Read the 7 friend columns:
#     - W1     : w1_friend_1 .. w1_friend_7  (no school suffix)
#     - W2..W10: w#_friend1_<s> .. w#_friend7_<s>  (per-school slot)
#   For each non-NA cell value (= alter j's record_id), keep edge (i, j)
#   iff:
#     (a) j != i                             (no self-loops)
#     (b) j has a record_id in the panel      (W1-W8 panel; W9-W10 ⊂ W1-W8)
#     (c) j responded to wave w (w#_schoolid non-NA for j at this wave;
#         schoolid==999 treated as NA).
#   Deduplicate (ego, alter) pairs.
#
# Output schema: ego, alter, schoolid (integer school id of the ego at
# wave w).
# ================================================================

suppressMessages({
  library(readxl)
})

source(file.path(here::here(), "R", "00-config.R"))

XL_W1W8  <- file.path(ADVANCE_DATA, "..", "Data",
                       "ADVANCE_W1-W8_Data_Complete_042326.xlsx")
XL_W9W10 <- file.path(ADVANCE_DATA, "..", "Data",
                       "ADVANCE_W9-W10_HS_Data_Complete_042326.xlsx")
stopifnot(file.exists(XL_W1W8), file.exists(XL_W9W10))

OUT_DIR <- file.path(ADVANCE_DATA, "..", "Cleaned-Data-042326")
dir.create(OUT_DIR, recursive = TRUE, showWarnings = FALSE)

# Schools we keep (matches v4 panel).
SCHOOLS <- c(101:108, 112:114, 201, 212:214)

# ----------------------------------------------------------------
# 1) Read the master panel for the universe of record_ids
# ----------------------------------------------------------------
hdr1 <- read_excel(XL_W1W8, n_max = 1, .name_repair = "minimal")
nm1  <- tolower(names(hdr1))
ix1_id <- which(nm1 == "record_id")
ct1 <- rep("skip", length(nm1)); ct1[ix1_id] <- "text"
panel_ids <- read_excel(XL_W1W8, col_types = ct1, .name_repair = "minimal")
ALL_IDS <- as.character(panel_ids$record_id)

# ----------------------------------------------------------------
# 2) Per-wave readers
# ----------------------------------------------------------------
read_wave_w1w8 <- function(w) {
  hdr <- read_excel(XL_W1W8, n_max = 1, .name_repair = "minimal")
  nm  <- tolower(names(hdr))
  if (w == 1) {
    friend_cols <- sprintf("w1_friend_%d", 1:7)
  } else {
    friend_cols <- unlist(lapply(SCHOOLS, function(s)
      sprintf("w%d_friend%d_%d", w, 1:7, s)))
  }
  need <- c("record_id", sprintf("w%d_schoolid", w), friend_cols)
  ix <- match(need, nm); ix <- ix[!is.na(ix)]
  ct <- rep("skip", length(nm)); ct[ix] <- "text"
  d <- read_excel(XL_W1W8, col_types = ct, na = c("","NA","."),
                  .name_repair = "minimal")
  names(d) <- tolower(names(d))
  d
}

read_wave_w9w10 <- function(w) {
  hdr <- read_excel(XL_W9W10, n_max = 1, .name_repair = "minimal")
  nm  <- tolower(names(hdr))
  friend_cols <- unlist(lapply(SCHOOLS, function(s)
    sprintf("w%d_friend%d_%d", w, 1:7, s)))
  need <- c("record_id", sprintf("w%d_schoolid", w), friend_cols)
  ix <- match(need, nm); ix <- ix[!is.na(ix)]
  ct <- rep("skip", length(nm)); ct[ix] <- "text"
  d <- read_excel(XL_W9W10, col_types = ct, na = c("","NA","."),
                  .name_repair = "minimal")
  names(d) <- tolower(names(d))
  d
}

# ----------------------------------------------------------------
# 3) Patch W1 schoolid encoding: codes 1..5 -> 101..105 mapping
#    (verified empirically against W2 in v4 phase 2)
# ----------------------------------------------------------------
patch_w1_schoolid <- function(x) {
  m <- c(`1`=101L, `2`=104L, `3`=102L, `4`=103L, `5`=105L)
  out <- as.integer(x)
  for (k in names(m)) out[!is.na(out) & out == as.integer(k)] <- m[[k]]
  out
}

# ----------------------------------------------------------------
# 4) Build edges for one wave
# ----------------------------------------------------------------
build_edges <- function(d, w) {
  schoolid_col <- sprintf("w%d_schoolid", w)
  if (!schoolid_col %in% names(d)) {
    stop("Missing schoolid column for wave ", w)
  }
  s <- as.integer(d[[schoolid_col]])
  # Treat 999 as NA (transferred-out / unknown).
  s[!is.na(s) & s == 999L] <- NA_integer_
  if (w == 1) s <- patch_w1_schoolid(s)
  d[[schoolid_col]] <- s

  # Set of respondents in this wave (alter inclusion criterion (c))
  respondents <- as.character(d$record_id[!is.na(s)])

  edges <- list()
  for (i in seq_len(nrow(d))) {
    ego <- d$record_id[i]
    if (is.na(ego)) next
    sch <- s[i]
    if (is.na(sch)) next
    if (w == 1) {
      cols <- sprintf("w1_friend_%d", 1:7)
    } else {
      cols <- sprintf("w%d_friend%d_%d", w, 1:7, sch)
    }
    for (k in seq_along(cols)) {
      v <- cols[k]
      if (!v %in% names(d)) next
      a <- d[[v]][i]
      if (is.na(a) || a == "" ) next
      a <- as.character(a)
      if (a == ego) next                    # (a) drop self-loops
      if (!(a %in% ALL_IDS)) next            # (b) alter in panel
      if (!(a %in% respondents)) next        # (c) alter responded W
      edges[[length(edges) + 1]] <- c(ego, a, sch)
    }
  }
  if (!length(edges)) {
    return(data.frame(ego = character(0), alter = character(0),
                       schoolid = integer(0), stringsAsFactors = FALSE))
  }
  M <- do.call(rbind, edges)
  out <- data.frame(ego = M[, 1], alter = M[, 2],
                    schoolid = as.integer(M[, 3]),
                    stringsAsFactors = FALSE)
  unique(out)
}

# ----------------------------------------------------------------
# 4b) Special case for W1: the 042326 XLSX stores W1 friend cells as
# REDCap-internal sequential codes (range ~ 1..2676) with no
# embedded mapping back to record_ids. The legacy
# `Cleaned-Data/w1edges_clean.csv` has the resolved edges (1,474
# entries; 2 self-loops, 3 with alters out-of-panel). For W1 we
# adopt the legacy file as canonical and apply the same hygiene
# rules used in our W2..W10 reconstruction.
# ----------------------------------------------------------------
load_w1_legacy <- function() {
  legacy <- file.path(ADVANCE_DATA, "..", "Cleaned-Data",
                      "w1edges_clean.csv")
  e <- read.csv(legacy, stringsAsFactors = FALSE)
  names(e) <- tolower(names(e))
  e$ego   <- as.character(e$ego)
  e$alter <- as.character(e$alter)
  # Apply the same hygiene rules as W2..W10
  e <- e[e$ego != e$alter, ]                  # (a) no self-loops
  e <- e[e$alter %in% ALL_IDS, ]               # (b) alter in panel
  e <- e[e$ego   %in% ALL_IDS, ]               # ego must also be in panel
  # Note: rule (c) — "alter responded W1" — is implicitly applied
  # because the legacy cleaner already restricted to W1 respondents.
  # Keep only ego, alter, schoolid columns.
  e <- e[, c("ego", "alter", "schoolid")]
  e$schoolid <- as.integer(e$schoolid)
  unique(e)
}

# ----------------------------------------------------------------
# 5) Run for W1..W10
# ----------------------------------------------------------------
summary_rows <- list()
for (w in 1:10) {
  cat(sprintf("\n=== Wave %d ===\n", w))
  if (w == 1) {
    e <- load_w1_legacy()
  } else if (w <= 8) {
    d <- read_wave_w1w8(w); e <- build_edges(d, w)
  } else {
    d <- read_wave_w9w10(w); e <- build_edges(d, w)
  }
  out_csv <- file.path(OUT_DIR, sprintf("w%dedges_clean.csv", w))
  write.csv(e, out_csv, row.names = FALSE)
  od <- if (nrow(e)) table(e$ego)   else integer(0)
  ind <- if (nrow(e)) table(e$alter) else integer(0)
  fwd <- paste(e$ego, e$alter, sep = "_")
  rev <- paste(e$alter, e$ego, sep = "_")
  recip <- if (nrow(e)) sum(rev %in% fwd) / nrow(e) else NA
  cat(sprintf("  n_edges=%d  n_egos=%d  out_max=%d  in_max=%d  recip=%.1f%%  self_loops=%d\n",
              nrow(e),
              if (nrow(e)) length(unique(e$ego)) else 0,
              if (length(od)) max(od) else 0,
              if (length(ind)) max(ind) else 0,
              100 * recip,
              if (nrow(e)) sum(e$ego == e$alter) else 0))
  summary_rows[[length(summary_rows) + 1]] <- data.frame(
    wave = w, n_edges = nrow(e),
    n_egos = if (nrow(e)) length(unique(e$ego)) else 0L,
    out_max = if (length(od)) as.integer(max(od)) else 0L,
    in_max  = if (length(ind)) as.integer(max(ind)) else 0L,
    recip = round(100 * recip, 1),
    self_loops = if (nrow(e)) sum(e$ego == e$alter) else 0L,
    stringsAsFactors = FALSE)
}
summary_df <- do.call(rbind, summary_rows)
cat("\n=== Summary ===\n")
print(summary_df, row.names = FALSE)

cat(sprintf("\nEdge files written to: %s\n", OUT_DIR))
