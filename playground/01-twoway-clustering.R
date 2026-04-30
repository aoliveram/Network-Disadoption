# ================================================================
# playground/01-twoway-clustering.R
#
# Bake-off: how do the v3 OR + p change when we cluster the SE by:
#   (a) community  (= village/schoolid; the v3 default)
#   (b) individual (= record_id / kfamily i)
#   (c) community + individual  (Cameron-Gelbach-Miller two-way)
#
# Reads the saved panels (canonical KFP, fpt-only KFP, ADVANCE) and
# refits a representative slice of the v3 batteries, then prints a
# side-by-side OR / SE / p comparison for each spec.
#
# Goal: decide whether (B) two-way SE should become the new v3 standard.
# This script does NOT modify any v3 result; it only reports.
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(Matrix)
})

source(file.path(here::here(), "R", "00-config.R"))

odir <- INTERMEDIATE
canonical <- readRDS(file.path(odir, "kfp_canonical.rds"))
fptonly   <- readRDS(file.path(odir, "kfp_fptonly.rds"))
advance   <- readRDS(file.path(odir, "advance_panel.rds"))

# ----------------------------------------------------------------
# 1. KFP panel-builders (lifted from R/03-models-kfp.R, slimmed)
# ----------------------------------------------------------------
compute_pp <- function(po) {
  n <- nrow(po$state_PC); Tt <- po$Tt
  state_PC      <- po$state_PC
  state_modern  <- po$state_modern
  class_at_t    <- po$class_at_t
  village       <- po$village
  A             <- po$A
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
  list(state_PC=state_PC, state_modern=state_modern, class_at_t=class_at_t,
       village=village,
       E_PC=E_PC, E_mod=E_mod, has_PC=has_PC, has_mod=has_mod,
       Emax_PC=pc_em$Emax, EDis_PC=pc_em$EDis,
       Emax_mod=mod_em$Emax, EDis_mod=mod_em$EDis,
       V_PC=V_PC, V_mod=V_mod, Tt=Tt, n=n)
}

build_adopt_PC <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  first_PC <- apply(pp$state_PC, 1, function(v) {
    o <- which(v == 1L); if (!length(o)) NA_integer_ else as.integer(min(o))
  })
  rows <- list()
  for (i in 1:n) {
    end_t <- if (is.na(first_PC[i])) Tt else first_PC[i]
    if (end_t < 2) next
    for (t in 2:end_t) {
      rows[[length(rows)+1]] <- list(
        id=i, t=t,
        event=as.integer(!is.na(first_PC[i]) && t == first_PC[i]),
        E_PC=pp$E_PC[i,t], has_PC=as.integer(pp$has_PC[i,t]),
        Emax_PC=pp$Emax_PC[i,t], EDis_PC=pp$EDis_PC[i,t],
        V_PC=pp$V_PC[i,t], village=pp$village[i])
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_adopt_mod <- function(pp) {
  n <- pp$n; Tt <- pp$Tt
  first <- apply(pp$state_modern, 1, function(v) {
    o <- which(v == 1L); if (!length(o)) NA_integer_ else as.integer(min(o))
  })
  rows <- list()
  for (i in 1:n) {
    end_t <- if (is.na(first[i])) Tt else first[i]
    if (end_t < 2) next
    for (t in 2:end_t) {
      rows[[length(rows)+1]] <- list(id=i, t=t,
        event=as.integer(!is.na(first[i]) && t == first[i]),
        E=pp$E_mod[i,t], has=as.integer(pp$has_mod[i,t]),
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
        if (!is.na(cls) && cls == "modern_nonPC") break
        ev <- as.integer(state[i, t] == 0L)
        rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
          E_PC=pp$E_PC[i,t], has_PC=as.integer(pp$has_PC[i,t]),
          Emax_PC=pp$Emax_PC[i,t], EDis_PC=pp$EDis_PC[i,t],
          V_PC=pp$V_PC[i,t], village=pp$village[i])
        if (ev == 1L) break
      }
    } else {
      for (t in 2:Tt) {
        if (is.na(state[i, t-1]) || state[i, t-1] != 1L) next
        if (is.na(state[i, t])) next
        cls <- class_at[i, t]
        if (!is.na(cls) && cls == "modern_nonPC") next
        ev <- as.integer(state[i, t] == 0L)
        if (kind == "A" && ev == 1L && t < Tt &&
            !is.na(state[i, t+1]) && state[i, t+1] == 1L) next
        rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
          E_PC=pp$E_PC[i,t], has_PC=as.integer(pp$has_PC[i,t]),
          Emax_PC=pp$Emax_PC[i,t], EDis_PC=pp$EDis_PC[i,t],
          V_PC=pp$V_PC[i,t], village=pp$village[i])
      }
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}
build_dis_mod <- function(pp, kind) {
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
        rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
          E=pp$E_mod[i,t], has=as.integer(pp$has_mod[i,t]),
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
        rows[[length(rows)+1]] <- list(id=i, t=t, event=ev,
          E=pp$E_mod[i,t], has=as.integer(pp$has_mod[i,t]),
          Emax=pp$Emax_mod[i,t], EDis=pp$EDis_mod[i,t],
          V=pp$V_mod[i,t], village=pp$village[i])
      }
    }
  }
  do.call(rbind, lapply(rows, as.data.frame))
}

# ----------------------------------------------------------------
# 2. ADVANCE panel-builder (lifted from R/04-models-advance.R)
# ----------------------------------------------------------------
adv <- advance[order(advance$record_id, advance$wave), ]
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
adv$E_prev    <- lag1(adv,"E_ecig"); adv$has_prev  <- lag1(adv,"has_ecig")
adv$Nc_prev   <- lag1(adv,"Nc_ecig"); adv$V_prev   <- lag1(adv,"V_ecig")
adv$Emax_prev <- NA_real_
for (rr in split(seq_len(nrow(adv)), adv$record_id)) {
  if (length(rr) < 2) next
  e <- adv$E_ecig[rr]; cm <- cummax(ifelse(is.na(e), -Inf, e))
  cm[is.infinite(cm)] <- NA
  adv$Emax_prev[rr][-1] <- cm[-length(cm)]
}
adv$EDis_prev <- adv$Emax_prev - adv$E_prev

ever_before <- ave(adv$ecig, adv$record_id, FUN = function(x) cummax(replace(x, is.na(x), 0)))
adv$ever_before_t <- c(0, ever_before[-length(ever_before)])
adv$ever_before_t[c(TRUE, adv$record_id[-1] != adv$record_id[-nrow(adv)])] <- 0

adv_adopt <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 0 & adv$ever_before_t == 0 & !is.na(adv$ecig), ]
adv_adopt <- data.frame(event=as.integer(adv_adopt$ecig==1), id=adv_adopt$record_id,
                         community=adv_adopt$schoolid, wave=adv_adopt$wave,
                         E=adv_adopt$E_prev, has=adv_adopt$has_prev,
                         Emax=adv_adopt$Emax_prev, EDis=adv_adopt$EDis_prev, V=adv_adopt$V_prev)

# disA, disB, disC for ADVANCE
disA_raw <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 1 & !is.na(adv$ecig), ]
disA_raw <- disA_raw[!(disA_raw$ecig == 0 & !is.na(disA_raw$ecig_next) & disA_raw$ecig_next == 1), ]
adv_disA <- data.frame(event=as.integer(disA_raw$ecig==0), id=disA_raw$record_id,
                       community=disA_raw$schoolid, wave=disA_raw$wave,
                       E=disA_raw$E_prev, has=disA_raw$has_prev,
                       Emax=disA_raw$Emax_prev, EDis=disA_raw$EDis_prev, V=disA_raw$V_prev)

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
disB_raw <- adv[disB_rows, ]
adv_disB <- data.frame(event=as.integer(disB_raw$ecig==0), id=disB_raw$record_id,
                       community=disB_raw$schoolid, wave=disB_raw$wave,
                       E=disB_raw$E_prev, has=disB_raw$has_prev,
                       Emax=disB_raw$Emax_prev, EDis=disB_raw$EDis_prev, V=disB_raw$V_prev)

disC_raw <- adv[!is.na(adv$ecig_prev) & adv$ecig_prev == 1 & !is.na(adv$ecig), ]
adv_disC <- data.frame(event=as.integer(disC_raw$ecig==0), id=disC_raw$record_id,
                       community=disC_raw$schoolid, wave=disC_raw$wave,
                       E=disC_raw$E_prev, has=disC_raw$has_prev,
                       Emax=disC_raw$Emax_prev, EDis=disC_raw$EDis_prev, V=disC_raw$V_prev)

# ----------------------------------------------------------------
# 3. KFP panels
# ----------------------------------------------------------------
pp_can <- compute_pp(canonical)
pp_fpt <- compute_pp(fptonly)

kfp_pc_adopt <- build_adopt_PC(pp_can)
names(kfp_pc_adopt)[names(kfp_pc_adopt)=="village"] <- "community"
kfp_pc_adopt$wave <- kfp_pc_adopt$t   # uniform name

kfp_mod_adopt <- build_adopt_mod(pp_can)
names(kfp_mod_adopt)[names(kfp_mod_adopt)=="village"] <- "community"
kfp_mod_adopt$wave <- kfp_mod_adopt$t

kfp_pc_disA_can <- build_dis_PC(pp_can, "A")
names(kfp_pc_disA_can)[names(kfp_pc_disA_can)=="village"] <- "community"
kfp_pc_disA_can$wave <- kfp_pc_disA_can$t

kfp_pc_disA_fpt <- build_dis_PC(pp_fpt, "A")
names(kfp_pc_disA_fpt)[names(kfp_pc_disA_fpt)=="village"] <- "community"
kfp_pc_disA_fpt$wave <- kfp_pc_disA_fpt$t

kfp_mod_disA <- build_dis_mod(pp_can, "A")
names(kfp_mod_disA)[names(kfp_mod_disA)=="village"] <- "community"
kfp_mod_disA$wave <- kfp_mod_disA$t

# ----------------------------------------------------------------
# 4. fit_three: GLM + three SE schemes
# ----------------------------------------------------------------
fit_three <- function(formula, data, panel_label, spec_label) {
  vars <- all.vars(formula)
  need <- unique(c(vars, "id", "community", "wave"))
  d <- data[, need[need %in% names(data)], drop = FALSE]
  d <- d[complete.cases(d), , drop = FALSE]
  if (nrow(d) == 0) return(NULL)
  fit <- glm(formula, data = d, family = binomial())
  vc_comm <- tryCatch(vcovCL(fit, cluster = d$community, type = "HC0"),
                      error = function(e) vcovHC(fit, type = "HC0"))
  vc_id   <- tryCatch(vcovCL(fit, cluster = d$id, type = "HC0"),
                      error = function(e) vcovHC(fit, type = "HC0"))
  vc_2way <- tryCatch(vcovCL(fit, cluster = list(community=d$community, id=d$id), type = "HC0"),
                      error = function(e) vcovHC(fit, type = "HC0"))
  ct_comm <- coeftest(fit, vcov. = vc_comm)
  ct_id   <- coeftest(fit, vcov. = vc_id)
  ct_2way <- coeftest(fit, vcov. = vc_2way)
  list(panel=panel_label, spec=spec_label, fit=fit,
       comm=ct_comm, idr=ct_id, two=ct_2way,
       n=nrow(d), events=sum(d$event),
       n_unique_id=length(unique(d$id)),
       n_unique_comm=length(unique(d$community)))
}

row_three <- function(three, term, label = NULL) {
  if (is.null(three) || !term %in% rownames(three$comm)) return(NULL)
  est <- three$comm[term, "Estimate"]
  data.frame(
    panel = three$panel,
    spec  = if (is.null(label)) three$spec else label,
    term  = term,
    OR    = round(exp(est), 3),
    SE_comm = round(three$comm[term, "Std. Error"], 4),
    p_comm  = signif(three$comm[term, "Pr(>|z|)"], 3),
    SE_id   = round(three$idr[term, "Std. Error"], 4),
    p_id    = signif(three$idr[term, "Pr(>|z|)"], 3),
    SE_2way = round(three$two[term, "Std. Error"], 4),
    p_2way  = signif(three$two[term, "Pr(>|z|)"], 3),
    ratio_2w_over_comm = round(three$two[term,"Std. Error"] / three$comm[term,"Std. Error"], 3),
    n  = three$n, ev = three$events,
    n_id = three$n_unique_id, n_comm = three$n_unique_comm,
    stringsAsFactors = FALSE
  )
}

# helper: factor up FE columns once per panel
prep <- function(d) {
  d$wave_fe <- factor(d$wave)
  d$community_fe <- factor(d$community)
  d
}

adv_adopt <- prep(adv_adopt)
adv_disA  <- prep(adv_disA)
adv_disB  <- prep(adv_disB)
adv_disC  <- prep(adv_disC)
kfp_pc_adopt    <- prep(kfp_pc_adopt)
kfp_mod_adopt   <- prep(kfp_mod_adopt)
kfp_pc_disA_can <- prep(kfp_pc_disA_can)
kfp_pc_disA_fpt <- prep(kfp_pc_disA_fpt)
kfp_mod_disA    <- prep(kfp_mod_disA)

# ----------------------------------------------------------------
# 5. run the bake-off
# ----------------------------------------------------------------
out <- list()

# ADVANCE adoption
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + E,         adv_adopt, "ADV adopt", "A1"), "E", "A1 E")
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V,         adv_adopt, "ADV adopt", "V1"), "V", "V1 V")
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, adv_adopt, "ADV adopt", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V")
out[[length(out)+1]] <- row_three(o, "E", "VAED E")
out[[length(out)+1]] <- row_three(o, "EDis", "VAED EDis")

# ADVANCE disA
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + E, adv_disA, "ADV disA", "A1"), "E", "A1 E")
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V, adv_disA, "ADV disA", "V1"), "V", "V1 V")
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, adv_disA, "ADV disA", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V")
out[[length(out)+1]] <- row_three(o, "E", "VAED E")
out[[length(out)+1]] <- row_three(o, "EDis", "VAED EDis")

# ADVANCE disB VAED + disC VAED
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, adv_disB, "ADV disB", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V"); out[[length(out)+1]] <- row_three(o, "E", "VAED E"); out[[length(out)+1]] <- row_three(o, "EDis", "VAED EDis")
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, adv_disC, "ADV disC", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V"); out[[length(out)+1]] <- row_three(o, "E", "VAED E"); out[[length(out)+1]] <- row_three(o, "EDis", "VAED EDis")

# KFP PC adoption (canonical)
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + E_PC, kfp_pc_adopt, "KFP PC adopt can", "A1"), "E_PC", "A1 E_PC")
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V_PC, kfp_pc_adopt, "KFP PC adopt can", "V1"), "V_PC", "V1 V_PC")
o <- fit_three(event ~ wave_fe + community_fe + V_PC + E_PC + EDis_PC, kfp_pc_adopt, "KFP PC adopt can", "VAED")
out[[length(out)+1]] <- row_three(o, "V_PC", "VAED V_PC")
out[[length(out)+1]] <- row_three(o, "E_PC", "VAED E_PC")

# KFP modern6 adoption
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + E,    kfp_mod_adopt, "KFP mod6 adopt", "A1"), "E", "A1 E")
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V,    kfp_mod_adopt, "KFP mod6 adopt", "V1"), "V", "V1 V")
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, kfp_mod_adopt, "KFP mod6 adopt", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V")
out[[length(out)+1]] <- row_three(o, "E", "VAED E")

# KFP PC disA (canonical)
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + E_PC, kfp_pc_disA_can, "KFP PC disA can", "A1"), "E_PC", "A1 E_PC")
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V_PC, kfp_pc_disA_can, "KFP PC disA can", "V1"), "V_PC", "V1 V_PC")
o <- fit_three(event ~ wave_fe + community_fe + V_PC + E_PC + EDis_PC, kfp_pc_disA_can, "KFP PC disA can", "VAED")
out[[length(out)+1]] <- row_three(o, "V_PC", "VAED V_PC")
out[[length(out)+1]] <- row_three(o, "E_PC", "VAED E_PC")

# KFP PC disA (fpt-only)
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V_PC, kfp_pc_disA_fpt, "KFP PC disA fpt", "V1"), "V_PC", "V1 V_PC")
o <- fit_three(event ~ wave_fe + community_fe + V_PC + E_PC + EDis_PC, kfp_pc_disA_fpt, "KFP PC disA fpt", "VAED")
out[[length(out)+1]] <- row_three(o, "V_PC", "VAED V_PC")
out[[length(out)+1]] <- row_three(o, "E_PC", "VAED E_PC")

# KFP modern6 disA
out[[length(out)+1]] <- row_three(fit_three(event ~ wave_fe + community_fe + V, kfp_mod_disA, "KFP mod6 disA", "V1"), "V", "V1 V")
o <- fit_three(event ~ wave_fe + community_fe + V + E + EDis, kfp_mod_disA, "KFP mod6 disA", "VAED")
out[[length(out)+1]] <- row_three(o, "V", "VAED V")
out[[length(out)+1]] <- row_three(o, "E", "VAED E")

# ----------------------------------------------------------------
# 6. assemble + print
# ----------------------------------------------------------------
res <- do.call(rbind, out[!sapply(out, is.null)])

cat("\n==== TWO-WAY CLUSTERING BAKE-OFF ====\n")
cat("Columns: SE_comm = v3 default (cluster by community);\n")
cat("         SE_id   = cluster by individual;\n")
cat("         SE_2way = Cameron-Gelbach-Miller two-way (community + id).\n")
cat("ratio_2w_over_comm: how much SE inflates / deflates moving to two-way.\n\n")

print(res, row.names = FALSE)

# Save for downstream summary
saveRDS(res, file.path(here::here(), "playground", "twoway_results.rds"))
write.csv(res, file.path(here::here(), "playground", "twoway_results.csv"),
          row.names = FALSE)
cat(sprintf("\nSaved: %s\n", file.path("playground", "twoway_results.csv")))

# Summary stats
cat("\n==== Summary: distribution of SE_2way / SE_comm ratios ====\n")
print(summary(res$ratio_2w_over_comm))

# Significance flips at alpha = 0.05
flips <- with(res, sign(p_comm < 0.05) != sign(p_2way < 0.05))
cat(sprintf("\nSignificance flips at alpha=0.05 (community vs two-way): %d / %d rows\n",
            sum(flips), nrow(res)))
if (any(flips)) print(res[flips, c("panel","spec","term","OR","p_comm","p_2way")], row.names = FALSE)
