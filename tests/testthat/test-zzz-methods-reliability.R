test_that("dino reliability", {
  dino_reli <- reliability(rstn_dino, threshold = 0.5)

  # threshold errors
  err <- rlang::catch_cnd(reliability(
    rstn_dino,
    threshold = c(
      "att1" = 0.5,
      "asdf" = 0.8,
      "test" = 0.7,
      "att4" = 0.5
    )
  ))
  expect_match(err$message, "unknown attribute names")
  err <- rlang::catch_cnd(reliability(
    rstn_dino,
    threshold = c("att1" = 0.5, "asdf" = 0.8)
  ))
  expect_match(err$message, "must be length 1 or 4")

  # list naming
  expect_equal(
    names(dino_reli),
    c("pattern_reliability", "map_reliability", "eap_reliability")
  )
  expect_equal(names(dino_reli$pattern_reliability), c("p_a", "p_c"))
  expect_equal(names(dino_reli$map_reliability), c("accuracy", "consistency"))
  expect_equal(
    names(dino_reli$map_reliability$accuracy),
    c(
      "attribute",
      "threshold",
      "acc",
      "lambda_a",
      "kappa_a",
      "youden_a",
      "tetra_a",
      "tp_a",
      "tn_a"
    )
  )
  expect_equal(
    names(dino_reli$map_reliability$consistency),
    c(
      "attribute",
      "threshold",
      "consist",
      "lambda_c",
      "kappa_c",
      "youden_c",
      "tetra_c",
      "tp_c",
      "tn_c",
      "gammak",
      "pc_prime"
    )
  )
  expect_equal(
    names(dino_reli$eap_reliability),
    c("attribute", "rho_pf", "rho_bs", "rho_i", "rho_tb")
  )

  # list rows
  expect_equal(
    dino_reli$map_reliability$accuracy$attribute,
    colnames(q_matrix)[-1]
  )
  expect_equal(
    dino_reli$map_reliability$consistency$attribute,
    colnames(q_matrix)[-1]
  )
  expect_equal(dino_reli$eap_reliability$attribute, colnames(q_matrix)[-1])
})

test_that("reliability can be added to model object", {
  dina_mod <- rstn_dina
  expect_equal(dina_mod@reliability, list())

  dina_mod <- add_reliability(dina_mod, threshold = rep(0.5, 4))
  expect_equal(
    names(dina_mod@reliability),
    c("pattern_reliability", "map_reliability", "eap_reliability")
  )

  expect_equal(
    measr_extract(dina_mod, "pattern_reliability"),
    tibble(
      accuracy = dina_mod@reliability$pattern_reliability[["p_a"]],
      consistency = dina_mod@reliability$pattern_reliability[["p_c"]]
    )
  )
  expect_equal(
    measr_extract(rstn_dina, "pattern_reliability"),
    measr_extract(dina_mod, "pattern_reliability")
  )

  expect_equal(
    measr_extract(dina_mod, "classification_reliability"),
    dplyr::full_join(
      dplyr::select(
        dina_mod@reliability$map_reliability$accuracy,
        "attribute",
        accuracy = "acc"
      ),
      dplyr::select(
        dina_mod@reliability$map_reliability$consistency,
        "attribute",
        consistency = "consist"
      ),
      by = "attribute"
    )
  )
  expect_equal(
    measr_extract(rstn_dina, "classification_reliability"),
    measr_extract(dina_mod, "classification_reliability")
  )

  expect_equal(
    measr_extract(
      dina_mod,
      "classification_reliability",
      agreement = c("lambda", "tn")
    ),
    dplyr::full_join(
      dplyr::select(
        dina_mod@reliability$map_reliability$accuracy,
        "attribute",
        accuracy = "acc",
        lambda_accuracy = "lambda_a",
        tn_accuracy = "tn_a"
      ),
      dplyr::select(
        dina_mod@reliability$map_reliability$consistency,
        "attribute",
        consistency = "consist",
        lambda_consistency = "lambda_c",
        tn_consistency = "tn_c"
      ),
      by = "attribute"
    )
  )

  expect_equal(
    measr_extract(dina_mod, "probability_reliability"),
    dplyr::select(
      dina_mod@reliability$eap_reliability,
      "attribute",
      informational = "rho_i"
    )
  )
  expect_equal(
    measr_extract(rstn_dina, "probability_reliability"),
    measr_extract(dina_mod, "probability_reliability")
  )

  expect_equal(
    measr_extract(dina_mod, "probability_reliability", agreement = "bs"),
    dplyr::select(
      dina_mod@reliability$eap_reliability,
      "attribute",
      informational = "rho_i",
      point_biserial = "rho_bs"
    )
  )

  expect_identical(dina_mod@reliability, reliability(dina_mod))
})

test_that("reliability records the threshold used", {
  att_names <- colnames(q_matrix)[-1]

  reli <- reliability(rstn_dino, threshold = 0.7)
  expect_equal(reli$map_reliability$accuracy$attribute, att_names)
  expect_equal(reli$map_reliability$accuracy$threshold, rep(0.7, 4))
  expect_equal(reli$map_reliability$consistency$threshold, rep(0.7, 4))

  # named thresholds supplied out of order are matched to attributes
  thr <- rlang::set_names(c(0.4, 0.5, 0.6, 0.7), rev(att_names))
  reli <- reliability(rstn_dino, threshold = thr)
  expect_equal(
    rlang::set_names(
      reli$map_reliability$accuracy$threshold,
      reli$map_reliability$accuracy$attribute
    ),
    thr[att_names]
  )
  expect_equal(
    reli$map_reliability$consistency$threshold,
    reli$map_reliability$accuracy$threshold
  )

  # thresholds are applied to the matching attribute, regardless of order
  thr_ordered <- c(0.2, 0.9, 0.3, 0.8)
  thr_reversed <- rlang::set_names(rev(thr_ordered), rev(att_names))
  reli_ordered <- reliability(rstn_dino, threshold = thr_ordered)
  reli_reversed <- reliability(rstn_dino, threshold = thr_reversed)
  expect_equal(reli_reversed$map_reliability, reli_ordered$map_reliability)

  # sanity check: misapplied thresholds give different results, so the
  # comparison above can detect an ordering bug
  reli_misapplied <- reliability(rstn_dino, threshold = rev(thr_ordered))
  expect_false(isTRUE(all.equal(
    reli_misapplied$map_reliability$accuracy[, -(1:2)],
    reli_ordered$map_reliability$accuracy[, -(1:2)]
  )))

  # unnamed vectors are used in q-matrix order
  reli <- reliability(rstn_dino, threshold = c(0.4, 0.5, 0.6, 0.7))
  expect_equal(reli$map_reliability$accuracy$threshold, c(0.4, 0.5, 0.6, 0.7))
})

test_that("stored reliability warns when threshold differs", {
  dina_mod <- add_reliability(rstn_dina, threshold = 0.6)

  # same threshold: no warning, stored results returned
  expect_no_warning(reli <- reliability(dina_mod, threshold = 0.6))
  expect_identical(reli, dina_mod@reliability)
  expect_no_warning(
    measr_extract(dina_mod, "classification_reliability", threshold = 0.6)
  )

  # different threshold: warning, stored results still returned
  expect_warning(
    reli <- reliability(dina_mod, threshold = 0.5),
    "different `threshold`"
  )
  expect_identical(reli, dina_mod@reliability)
  expect_warning(
    measr_extract(dina_mod, "classification_reliability"),
    "different `threshold`"
  )

  # each function's warning points only to its own fix
  w <- rlang::catch_cnd(reliability(dina_mod), classes = "warning")
  expect_match(conditionMessage(w), "force = TRUE")
  expect_no_match(conditionMessage(w), "overwrite|add_reliability")

  w <- rlang::catch_cnd(add_reliability(dina_mod), classes = "warning")
  expect_match(conditionMessage(w), "different `threshold`")
  expect_match(conditionMessage(w), "overwrite = TRUE")
  expect_no_match(conditionMessage(w), "force")

  # add_reliability: mismatch leaves the model unchanged
  expect_identical(suppressWarnings(add_reliability(dina_mod)), dina_mod)
  expect_no_warning(same <- add_reliability(dina_mod, threshold = 0.6))
  expect_identical(same, dina_mod)

  # add_reliability: overwrite = TRUE recalculates without a warning
  expect_no_warning(
    updated <- add_reliability(dina_mod, threshold = 0.5, overwrite = TRUE)
  )
  expect_equal(
    updated@reliability$map_reliability$accuracy$threshold,
    rep(0.5, 4)
  )

  # extract warning points to the extract-level fix
  w <- rlang::catch_cnd(
    measr_extract(dina_mod, "classification_reliability"),
    classes = "warning"
  )
  expect_match(conditionMessage(w), "force = TRUE")
  expect_no_match(conditionMessage(w), "overwrite|add_reliability")

  # force = TRUE in measr_extract recalculates without touching the cache
  stored <- dina_mod@reliability
  expect_no_warning(
    forced <- measr_extract(
      dina_mod,
      "classification_reliability",
      threshold = 0.5,
      force = TRUE
    )
  )
  expect_identical(dina_mod@reliability, stored)
  expect_equal(
    forced,
    measr_extract(rstn_dina, "classification_reliability", threshold = 0.5)
  )
  expect_false(isTRUE(all.equal(
    forced,
    measr_extract(dina_mod, "classification_reliability", threshold = 0.6)
  )))

  err <- rlang::catch_cnd(measr_extract(
    dina_mod,
    "classification_reliability",
    force = "yes"
  ))
  expect_match(err$message, "force")

  # force = TRUE recalculates without a warning
  expect_no_warning(reli <- reliability(dina_mod, threshold = 0.5, force = TRUE))
  expect_equal(reli$map_reliability$accuracy$threshold, rep(0.5, 4))

  # eap and pattern reliability do not depend on the threshold
  expect_no_warning(measr_extract(dina_mod, "probability_reliability"))
  expect_equal(reli$eap_reliability, dina_mod@reliability$eap_reliability)
  expect_equal(
    reli$pattern_reliability,
    dina_mod@reliability$pattern_reliability
  )
})

test_that("consistency kappa follows Johnson & Sinharay (2018, Eq. 30)", {
  for (threshold in c(0.2, 0.5, 0.8)) {
    consistency <- reliability(
      rstn_dino,
      threshold = threshold
    )$map_reliability$consistency

    # the consistency table is symmetric, so it can be rebuilt from the observed
    # agreement and the TP and TN rates
    p1 <- (consistency$consist - consistency$tn_c) /
      (consistency$tp_c - consistency$tn_c)
    p_e <- p1^2 + (1 - p1)^2
    expect_equal(
      consistency$kappa_c,
      (consistency$consist - p_e) / (1 - p_e)
    )

    # for a symmetric 2x2 table, kappa is equal to Youden's statistic
    expect_equal(consistency$kappa_c, consistency$youden_c)
  }
})

test_that("accuracy kappa follows Johnson & Sinharay (2018, Eq. 30)", {
  for (threshold in c(0.2, 0.5, 0.8)) {
    accuracy <- reliability(
      rstn_dino,
      threshold = threshold
    )$map_reliability$accuracy

    # rebuild the margins of the accuracy table from the observed agreement and
    # the TP and TN rates
    p_true <- (accuracy$acc - accuracy$tn_a) / (accuracy$tp_a - accuracy$tn_a)
    p_est <- p_true * accuracy$tp_a + (1 - p_true) * (1 - accuracy$tn_a)
    p_e <- p_true * p_est + (1 - p_true) * (1 - p_est)
    expect_equal(accuracy$kappa_a, (accuracy$acc - p_e) / (1 - p_e))
  }
})

test_that("accuracy tetrachoric correlation is squared", {
  att_names <- colnames(q_matrix)[-1]
  obj <- reli_list(
    rstn_dino,
    threshold = rlang::set_names(rep(0.5, 4), att_names)
  )
  reli <- reliability(rstn_dino, threshold = 0.5)$map_reliability
  rho <- function(m) psych::tetrachoric(m)$rho

  expect_equal(reli$accuracy$tetra_a, unname(apply(obj$acc, 3, rho))^2)
  # consistency is not squared
  expect_equal(reli$consistency$tetra_c, unname(apply(obj$consist, 3, rho)))
})

test_that("pc_prime follows Johnson & Sinharay (2018, Eqs. 17-18)", {
  att_names <- colnames(q_matrix)[-1]
  obj <- reli_list(
    rstn_dino,
    threshold = rlang::set_names(rep(0.5, 4), att_names)
  )
  profiles <- as.matrix(create_profiles(rstn_dino@model_spec))

  # prevalence is the sum of the base rates for classes with the attribute
  prev <- vapply(
    att_names,
    \(att) sum(obj$strc[profiles[, att] == 1]),
    double(1)
  )
  expect_equal(obj$prev, unname(prev))
  expect_equal(unname(prev), colMeans(obj$eap), tolerance = 0.001)

  # probability of the same profile on two forms, given the true profile
  map_class <- apply(obj$posterior, 1, which.max)
  same <- vapply(
    seq_len(nrow(profiles)),
    \(a) {
      sum(vapply(
        seq_len(nrow(profiles)),
        \(l) (mean(obj$posterior[, a] * (map_class == l)) / obj$strc[a])^2,
        double(1)
      ))
    },
    double(1)
  )
  expected <- vapply(
    att_names,
    \(att) {
      has <- profiles[, att] == 1
      pck1 <- sum((same * obj$strc)[has]) / sum(obj$strc[has])
      pck0 <- sum((same * obj$strc)[!has]) / sum(obj$strc[!has])
      pck1^2 * prev[[att]] + pck0^2 * (1 - prev[[att]])
    },
    double(1)
  )

  # does not depend on the threshold
  for (threshold in c(0.2, 0.5, 0.8)) {
    reli <- reliability(rstn_dino, threshold = threshold)
    expect_equal(reli$map_reliability$consistency$pc_prime, unname(expected))
  }
})
