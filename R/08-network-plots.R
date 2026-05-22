# ================================================================
# 08-network-plots.R
#
# Per-wave friendship-network plots for one focal school, with
# nodes colored by ecig status (never-user / current user /
# past-user a.k.a. dis-adopter).
#
# Selection rule for the focal school: highest combined rank of
# total adoption events (0->1) and total dis-adoption events
# (1->0) across the panel.  Top school = 114 (cohort 2024,
# 115 adoptions, 81 dis-adoptions, 375 students).
#
# Layout: Fruchterman-Reingold (FR), computed ONCE from the union
# of all edges across waves (isolates dropped) and held FIXED
# across timesteps so node positions are comparable.
#
# Outputs:
#   outputs/figures/network_panel_school<id>_allwaves.pdf  (4x2 grid, all waves)
#   outputs/figures/network_panel_school<id>_2x2.pdf        (W2/W4/W6/W8, paper-ready)
#   outputs/figures/network_panel_school<id>_w<W>.pdf       (one per wave)
# ================================================================

suppressMessages({
  library(igraph)
  library(dplyr)
})
source(file.path(here::here(), "R", "00-config.R"))

EDGE_DIR  <- file.path(ADVANCE_DATA, "..", "Cleaned-Data-042326")
FOCAL_SCHOOL <- 114                       # see ranking in script log
WAVES_BY_COHORT <- list("2024" = 1:8, "2025" = 3:10)

# Plot-size knobs (tune here if needed)
GRID_VSIZE <- 2.8   # vertex size for the 4x2 all-waves grid
GRID_ESIZE <- 0.45  # edge width for the grid
TWO_VSIZE  <- 3.2   # vertex size for the 2x2 paper-ready figure
TWO_ESIZE  <- 0.55  # edge width for the 2x2
INDV_VSIZE <- 4.0   # vertex size for the per-wave standalone PDFs
INDV_ESIZE <- 0.65  # edge width for the standalone PDFs

# ----------------------------------------------------------------
# 1) Load panel, infer roster + per-wave ecig status for school
# ----------------------------------------------------------------
panel <- readRDS(file.path(INTERMEDIATE, "advance_panel_v4b.rds"))
panel <- panel[order(panel$record_id, panel$wave), ]

# Identify cohort of focal school (use any row tagged with that school)
sch_rows <- panel[!is.na(panel$schoolid) & panel$schoolid == FOCAL_SCHOOL, ]
COHORT   <- as.character(unique(sch_rows$cohort))
stopifnot(length(COHORT) == 1)
WAVES    <- WAVES_BY_COHORT[[COHORT]]
cat(sprintf("Focal school %d (cohort %s); plotting waves %s\n",
            FOCAL_SCHOOL, COHORT, paste(WAVES, collapse = ",")))

# Roster: any student that appears with this schoolid in any wave
roster <- unique(as.character(sch_rows$record_id))
cat(sprintf("Roster: %d students\n", length(roster)))

# Wide per-wave ecig matrix (n x nW) for the roster
ecig_mat <- matrix(NA_integer_, nrow = length(roster), ncol = length(WAVES),
                   dimnames = list(roster, paste0("w", WAVES)))
for (k in seq_along(WAVES)) {
  w   <- WAVES[k]
  sub <- panel[panel$record_id %in% roster & panel$wave == w, ]
  if (!nrow(sub)) next
  ix  <- match(sub$record_id, roster)
  ecig_mat[ix, k] <- as.integer(sub$ecig)
}

# Per-wave node status:
#   "never"   : ecig=0 at this wave AND never been ecig=1 in any prior wave
#   "current" : ecig=1 at this wave
#   "past"    : ecig=0 at this wave but ecig=1 at some prior wave (dis-adopter)
#   "na"      : ecig is NA at this wave
node_status <- function(k) {
  cur  <- ecig_mat[, k]
  if (k == 1) {
    prior_user <- rep(FALSE, nrow(ecig_mat))
  } else {
    prior_user <- apply(ecig_mat[, 1:(k - 1), drop = FALSE], 1,
                        function(x) any(!is.na(x) & x == 1))
  }
  out <- rep("na", length(cur))
  out[!is.na(cur) & cur == 1L]                   <- "current"
  out[!is.na(cur) & cur == 0L & !prior_user]     <- "never"
  out[!is.na(cur) & cur == 0L &  prior_user]     <- "past"
  out
}

status_mat <- vapply(seq_along(WAVES), node_status, character(length(roster)))
colnames(status_mat) <- paste0("w", WAVES)
rownames(status_mat) <- roster

# ----------------------------------------------------------------
# 2) Load edges and build per-wave igraphs (fixed node set = roster)
# ----------------------------------------------------------------
load_edges <- function(w) {
  f <- file.path(EDGE_DIR, sprintf("w%dedges_clean.csv", w))
  if (!file.exists(f)) return(NULL)
  e <- read.csv(f, stringsAsFactors = FALSE)
  names(e) <- tolower(names(e))
  if (!"ego" %in% names(e) && "egoid" %in% names(e))
    names(e)[names(e) == "egoid"] <- "ego"
  e$ego   <- as.character(e$ego)
  e$alter <- as.character(e$alter)
  e[e$ego %in% roster & e$alter %in% roster, c("ego", "alter")]
}

edges_by_wave <- lapply(WAVES, load_edges)
names(edges_by_wave) <- paste0("w", WAVES)

# Union of edges → backbone for FR layout
union_edges <- do.call(rbind, edges_by_wave)
union_edges <- unique(union_edges)
g_union_full <- graph_from_data_frame(union_edges, directed = TRUE,
                                       vertices = data.frame(name = roster))
deg_union <- igraph::degree(g_union_full, mode = "all")
connected <- V(g_union_full)$name[deg_union > 0]
cat(sprintf("Union graph: |V|=%d (connected = %d, dropping %d isolates), |E|=%d\n",
            vcount(g_union_full), length(connected),
            vcount(g_union_full) - length(connected), ecount(g_union_full)))

# Trim roster + status_mat + ecig_mat to connected nodes only
roster     <- connected
ecig_mat   <- ecig_mat[roster, , drop = FALSE]
status_mat <- status_mat[roster, , drop = FALSE]

g_union <- induced_subgraph(g_union_full, roster)

# ----------------------------------------------------------------
# 3) Fixed FR layout on connected union (computed once)
# ----------------------------------------------------------------
set.seed(42)
und <- as_undirected(g_union, mode = "collapse")
layout_xy <- layout_with_fr(und, niter = 800, grid = "nogrid")
rownames(layout_xy) <- V(g_union)$name

# Community-ordered circular layout: Louvain communities on the
# undirected union; nodes ordered around the circle by community
# (largest first), and within community by degree (high → low).
set.seed(42)
comms     <- cluster_louvain(und)
mem       <- as.integer(membership(comms))
deg_u     <- igraph::degree(und)
names(mem) <- V(und)$name
ord_comm  <- as.integer(names(sort(table(mem), decreasing = TRUE)))
node_order <- unlist(lapply(ord_comm, function(c) {
  ids <- names(mem)[mem == c]
  ids[order(-deg_u[ids])]
}), use.names = FALSE)
n_nodes  <- length(node_order)
angles   <- 2 * pi * (seq_len(n_nodes) - 1) / n_nodes - pi / 2
layout_circ <- cbind(cos(angles), sin(angles))
rownames(layout_circ) <- node_order
cat(sprintf("Louvain: %d communities, sizes = %s\n",
            length(ord_comm),
            paste(as.integer(sort(table(mem), decreasing = TRUE)),
                  collapse = ",")))

# ----------------------------------------------------------------
# 4) Plotting helpers
# ----------------------------------------------------------------
COLORS <- c(never   = "grey85",
            current = "#1565C0",   # blue
            past    = "#C62828",   # red
            na      = "white")
BORDERS <- c(never  = "grey55",
             current= "#0B3D91",
             past   = "#7F0000",
             na     = "grey75")

build_wave_graph <- function(k) {
  edges <- edges_by_wave[[k]]
  # restrict edges to current (connected) roster
  if (!is.null(edges) && nrow(edges)) {
    edges <- edges[edges$ego %in% roster & edges$alter %in% roster, ]
  } else {
    edges <- data.frame(ego = character(), alter = character())
  }
  g <- graph_from_data_frame(edges, directed = TRUE,
                             vertices = data.frame(name = roster))
  st <- status_mat[, k]
  V(g)$color       <- unname(COLORS[st])
  V(g)$frame.color <- unname(BORDERS[st])
  g
}

plot_wave <- function(k, main_size = 1.1, vsize = GRID_VSIZE, esize = GRID_ESIZE,
                     show_counts = TRUE, layout = layout_xy) {
  w  <- WAVES[k]
  g  <- build_wave_graph(k)
  V(g)$size <- vsize
  st <- status_mat[, k]
  ttl <- if (show_counts) {
    sprintf("W%d  (current=%d, past=%d, never=%d, NA=%d)",
            w, sum(st == "current"), sum(st == "past"),
            sum(st == "never"),   sum(st == "na"))
  } else {
    sprintf("W%d", w)
  }
  plot(g,
       layout          = layout[V(g)$name, ],
       vertex.label    = NA,
       edge.arrow.size = 0.15,
       edge.color      = adjustcolor("grey55", alpha.f = 0.40),
       edge.width      = esize,
       main            = ttl,
       cex.main        = main_size)
}

legend_panel <- function(cex = 0.95, horiz = TRUE) {
  plot.new()
  legend(if (horiz) "center" else "left",
         legend = c("Current user (ecig=1)",
                    "Disadopter (was 1, now 0)",
                    "Never-user",
                    "Missing (NA)"),
         pch    = 21,
         pt.bg  = c(COLORS["current"], COLORS["past"],
                    COLORS["never"],   COLORS["na"]),
         col    = c(BORDERS["current"], BORDERS["past"],
                    BORDERS["never"],   BORDERS["na"]),
         pt.cex = 1.8, cex = cex, horiz = horiz, bty = "n",
         x.intersp = 1.1, y.intersp = 1.4)
}

# ----------------------------------------------------------------
# 5a) Multi-panel PDF (all waves, 4x2 grid)
# ----------------------------------------------------------------
out_all <- file.path(FIGURES,
                     sprintf("network_panel_school%d_allwaves.pdf", FOCAL_SCHOOL))
nW <- length(WAVES)
ncol <- 4L; nrow <- ceiling(nW / ncol)
pdf(out_all, width = 4 * ncol, height = 4 * nrow + 0.4)
op <- par(mfrow = c(nrow, ncol), mar = c(0.5, 0.5, 2.2, 0.5),
          oma  = c(2.5, 0.5, 1.5, 0.5))
for (k in seq_along(WAVES)) plot_wave(k)
mtext(sprintf("School %d  (cohort %s) - friendship network across waves; FR layout fixed across all panels",
              FOCAL_SCHOOL, COHORT),
      side = 3, line = -1, outer = TRUE, cex = 1.0, font = 2)
mtext("blue = current e-cig user   |   red = past user (dis-adopter)   |   grey = never-user   |   white = NA",
      side = 1, line = 0.5, outer = TRUE, cex = 0.9)
par(op); dev.off()
cat(sprintf("Wrote %s\n", out_all))

# ----------------------------------------------------------------
# 5b) Paper-ready 2x2 figure (W2, W4, W6, W8) with single legend
# ----------------------------------------------------------------
PAPER_WAVES <- c(2, 4, 6, 8)
paper_idx   <- match(PAPER_WAVES, WAVES)
stopifnot(all(!is.na(paper_idx)))

render_2x2 <- function(out_path, layout_to_use) {
  pdf(out_path, width = 11.5, height = 8.4)
  op <- par(oma = c(0.5, 0.5, 0.5, 0.5))
  layout(rbind(c(1, 2, 5),
               c(3, 4, 5)),
         widths = c(1, 1, 0.55))
  par(mar = c(0.5, 0.5, 2.0, 0.5))
  for (k in paper_idx) plot_wave(k, main_size = 1.4,
                                  vsize = TWO_VSIZE, esize = TWO_ESIZE,
                                  show_counts = FALSE,
                                  layout = layout_to_use)
  par(mar = c(0.5, 0.5, 0.5, 0.5))
  legend_panel(cex = 1.0, horiz = FALSE)
  par(op); dev.off()
}

out_2x2      <- file.path(FIGURES,
                          sprintf("network_panel_school%d_2x2.pdf", FOCAL_SCHOOL))
out_2x2_circ <- file.path(FIGURES,
                          sprintf("network_panel_school%d_2x2_circular.pdf",
                                  FOCAL_SCHOOL))
render_2x2(out_2x2,      layout_xy)
cat(sprintf("Wrote %s\n", out_2x2))

# ----------------------------------------------------------------
# 5c) Paper-ready 2x2 figure on CIRCULAR community-ordered layout
#     (uses the same trimmed roster — isolates already excluded)
# ----------------------------------------------------------------
render_2x2(out_2x2_circ, layout_circ)
cat(sprintf("Wrote %s\n", out_2x2_circ))

# ----------------------------------------------------------------
# 6) One PDF per wave (closer inspection)
# ----------------------------------------------------------------
for (k in seq_along(WAVES)) {
  w <- WAVES[k]
  out_w <- file.path(FIGURES,
                     sprintf("network_panel_school%d_w%d.pdf", FOCAL_SCHOOL, w))
  pdf(out_w, width = 7, height = 7)
  op <- par(mar = c(2.5, 0.5, 2.5, 0.5))
  plot_wave(k, vsize = INDV_VSIZE, esize = INDV_ESIZE, main_size = 1.2)
  mtext("blue = current  |  red = past (dis-adopter)  |  grey = never  |  white = NA",
        side = 1, line = 1, cex = 0.85)
  par(op); dev.off()
}
cat(sprintf("Wrote %d per-wave PDFs in %s\n", length(WAVES), FIGURES))

# ----------------------------------------------------------------
# 7) Per-wave status table (saved alongside the PDFs)
# ----------------------------------------------------------------
status_summary <- data.frame(
  wave    = WAVES,
  never   = colSums(status_mat == "never"),
  current = colSums(status_mat == "current"),
  past    = colSums(status_mat == "past"),
  na      = colSums(status_mat == "na"),
  edges   = vapply(edges_by_wave,
                   function(e) if (is.null(e)) 0L else nrow(e), integer(1)))
status_summary$pct_current <- round(100 *
  status_summary$current /
  (status_summary$never + status_summary$current + status_summary$past), 1)
status_summary$pct_past <- round(100 *
  status_summary$past /
  (status_summary$never + status_summary$current + status_summary$past), 1)
out_csv <- file.path(FIGURES,
                     sprintf("network_panel_school%d_status.csv", FOCAL_SCHOOL))
write.csv(status_summary, out_csv, row.names = FALSE)
cat(sprintf("Wrote %s\n", out_csv))
cat("\nPer-wave status summary:\n")
print(status_summary, row.names = FALSE)
