# ================================================================
# helpers.R
#
# Common utilities used across the modelling scripts.
# ================================================================

suppressMessages({
  library(sandwich)
  library(lmtest)
  library(Matrix)
})

# ---- year decoding for KFP cyclic encoding ('4'..'3' -> 1964..1973) ----
YEAR_MAP <- c("4"=1964,"5"=1965,"6"=1966,"7"=1967,"8"=1968,
              "9"=1969,"0"=1970,"1"=1971,"2"=1972,"3"=1973)

decode_year <- function(x) {
  out <- rep(NA_integer_, length(x))
  ok  <- !is.na(x) & as.character(x) %in% names(YEAR_MAP)
  out[ok] <- as.integer(YEAR_MAP[as.character(x[ok])])
  out
}

# ---- cluster-robust logistic ----
fit_logit <- function(formula, data, cluster_var = "village") {
  fit <- glm(formula, data = data, family = binomial())
  cluster <- if (cluster_var %in% names(data)) data[[cluster_var]] else NULL
  vc <- tryCatch(
    sandwich::vcovCL(fit, cluster = cluster, type = "HC0"),
    error = function(e) sandwich::vcovHC(fit, type = "HC0")
  )
  ct <- lmtest::coeftest(fit, vcov. = vc)
  list(fit = fit, ct = ct, vcov = vc,
       n = nrow(fit$model), events = sum(fit$model[[1]]),
       aic = AIC(fit))
}

row_of <- function(label, r, term) {
  if (!term %in% rownames(r$ct)) {
    return(data.frame(model = label, term = term,
                      OR = NA_real_, p = NA_real_,
                      n = r$n, ev = r$events, aic = round(r$aic, 1),
                      stringsAsFactors = FALSE))
  }
  z <- r$ct[term, ]
  data.frame(model = label, term = term,
             OR = round(exp(unname(z["Estimate"])), 3),
             p  = signif(unname(z["Pr(>|z|)"]), 3),
             n  = r$n, ev = r$events, aic = round(r$aic, 1),
             stringsAsFactors = FALSE)
}

# ---- E^max and E^Dis from a (n x T) exposure matrix ----
make_emax_edis <- function(M) {
  n <- nrow(M); Tt <- ncol(M)
  Emax <- matrix(NA_real_, n, Tt)
  for (i in seq_len(n)) {
    cm <- cummax(ifelse(is.na(M[i,]), -Inf, M[i,]))
    cm[is.infinite(cm)] <- NA
    Emax[i, ] <- cm
  }
  list(Emax = Emax, EDis = Emax - M)
}

# ---- ADVANCE grade-semester from (cohort, wave) ----
# Class of 2024 (schools 101..114): W1..W8 -> gs 1..8 (fall 9th .. spring 12th).
# W9, W10 are post-HS for cohort 2024, encoded as NA (excluded from gs_fe).
# Class of 2025 (schools 201..214): W3..W10 -> gs 1..8.
attach_gs <- function(d) {
  gs_2024 <- c(`1`=1L,`2`=2L,`3`=3L,`4`=4L,`5`=5L,`6`=6L,`7`=7L,`8`=8L,
               `9`=NA_integer_,`10`=NA_integer_)
  gs_2025 <- c(`3`=1L,`4`=2L,`5`=3L,`6`=4L,`7`=5L,`8`=6L,`9`=7L,`10`=8L)
  d$gs <- NA_integer_
  i24 <- !is.na(d$cohort) & d$cohort == "2024"
  i25 <- !is.na(d$cohort) & d$cohort == "2025"
  d$gs[i24] <- as.integer(gs_2024[as.character(d$wave[i24])])
  d$gs[i25] <- as.integer(gs_2025[as.character(d$wave[i25])])
  d
}

# ---- row-normalised adjacency W = D^{-1} A ----
build_W <- function(A) {
  n <- nrow(A)
  rs <- as.numeric(Matrix::rowSums(A))
  D  <- Matrix::Diagonal(n, ifelse(rs > 0, 1/rs, 0))
  as(D %*% A, "CsparseMatrix")
}
