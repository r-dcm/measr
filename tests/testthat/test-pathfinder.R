if (!identical(Sys.getenv("NOT_CRAN"), "true")) {
  skip("No MCMC on CRAN")
} else {
  lcdm_spec <- dcm_specify(
    qmatrix = dcmdata::dtmr_qmatrix,
    identifier = "item",
    measurement_model = lcdm(),
    structural_model = hdcm(
      "appropriateness -> partitioning_iterating -> referent_units
      appropriateness -> multiplicative_comparison -> referent_units"
    )
  )
  dina_spec <- dcm_specify(
    qmatrix = dcmdata::dtmr_qmatrix,
    identifier = "item",
    measurement_model = dina(),
    structural_model = independent(),
    priors = c(
      prior(beta(5, 17), type = "slip"),
      prior(beta(5, 17), type = "guess")
    )
  )

  out <- capture.output(
    suppressWarnings(suppressMessages(
      cmds_dtmr_lcdm <- dcm_estimate(
        lcdm_spec,
        data = dcmdata::dtmr_data,
        identifier = "id",
        missing = NA,
        method = "pathfinder",
        seed = 63277,
        backend = "cmdstanr",
        draws = 1000
      )
    ))
  )
  out <- capture.output(
    suppressWarnings(suppressMessages(
      cmds_dtmr_dina <- dcm_estimate(
        dina_spec,
        data = dcmdata::dtmr_data,
        identifier = "id",
        missing = NA,
        method = "pathfinder",
        seed = 63277,
        backend = "cmdstanr"
      )
    ))
  )
}

# model validator --------------------------------------------------------------
test_that("measrfit validator errors correctly", {
  expect_error(
    {
      dcm_estimate(
        lcdm_spec,
        data = dcmdata::dtmr_data,
        identifier = "id",
        missing = NA,
        method = "pathfinder",
        seed = 63277,
        backend = "rstan",
        draws = 1000
      )
    },
    "`backend` must be cmdstanr"
  )

  expect_error(
    measrfit(backend = rstan(), method = pathfinder()),
    "@backend must be .*cmdstanr.* when @method is .*pathfinder.*"
  )
})

# draws ------------------------------------------------------------------------
test_that("as_draws works", {
  skip_on_cran()

  draws <- as_draws(cmds_dtmr_dina)
  expect_s3_class(draws, "draws_matrix")

  draws <- as_draws(cmds_dtmr_lcdm)
  expect_s3_class(draws, "draws_matrix")

  draws_a <- posterior::as_draws_array(cmds_dtmr_dina)
  expect_s3_class(draws_a, "draws_array")

  draws_d <- posterior::as_draws_df(cmds_dtmr_dina)
  expect_s3_class(draws_d, "draws_df")

  draws_l <- posterior::as_draws_list(cmds_dtmr_lcdm)
  expect_s3_class(draws_l, "draws_list")

  draws_m <- posterior::as_draws_matrix(cmds_dtmr_lcdm)
  expect_s3_class(draws_m, "draws_matrix")

  draws_r <- posterior::as_draws_rvars(cmds_dtmr_lcdm)
  expect_s3_class(draws_r, "draws_rvars")
})

test_that("get_draws works as expected", {
  skip_on_cran()

  test_draws <- get_draws(cmds_dtmr_lcdm)
  expect_equal(posterior::ndraws(test_draws), 1000)
  expect_equal(posterior::nvariables(test_draws), 241)
  expect_s3_class(test_draws, "draws_array")

  test_draws <- get_draws(
    cmds_dtmr_dina,
    vars = c("log_Vc", "pi"),
    ndraws = 750
  )
  expect_equal(posterior::ndraws(test_draws), 750)
  expect_equal(posterior::nvariables(test_draws), 448)
  expect_s3_class(test_draws, "draws_array")
})

# extracts ---------------------------------------------------------------------
test_that("extract pi matrix", {
  lcdm_pimat <- measr_extract(cmds_dtmr_lcdm, "pi_matrix")
  expect_equal(nrow(lcdm_pimat), 27)
  expect_equal(ncol(lcdm_pimat), 7)
  expect_equal(lcdm_pimat$item, dcmdata::dtmr_qmatrix$item)
  expect_equal(
    colnames(lcdm_pimat)[-1],
    dplyr::pull(profile_labels(lcdm_spec), "class")
  )
  expect_true(all(vapply(lcdm_pimat[, -1], posterior::is_rvar, logical(1))))
  expect_true(all(vapply(lcdm_pimat[, -1], \(x) !any(is.na(x)), logical(1))))
})

test_that("extract model p-values", {
  dina_pimat <- measr_extract(cmds_dtmr_dina, "exp_pvalues")
  expect_equal(nrow(dina_pimat), 27)
  expect_equal(ncol(dina_pimat), 18)
  expect_equal(dina_pimat$item, dcmdata::dtmr_qmatrix$item)
  expect_equal(
    colnames(dina_pimat)[-1],
    c(dplyr::pull(profile_labels(4), "class"), "overall")
  )
  expect_true(all(vapply(dina_pimat[, -1], posterior::is_rvar, logical(1))))
  expect_true(all(vapply(dina_pimat[, -1], \(x) !any(is.na(x)), logical(1))))
})

test_that("extract base rates", {
  lcdm_br <- measr_extract(cmds_dtmr_lcdm, "attribute_base_rate")
  expect_equal(nrow(lcdm_br), 1)
  expect_equal(ncol(lcdm_br), ncol(dcmdata::dtmr_qmatrix[, -1]))
  expect_equal(colnames(lcdm_br), names(dcmdata::dtmr_qmatrix[, -1]))
  expect_true(all(vapply(lcdm_br, posterior::is_rvar, logical(1))))
  expect_true(all(!is.na(lcdm_br[1, ])))
})

# loo/waic ---------------------------------------------------------------------
test_that("loo and waic work", {
  skip_on_cran()

  err <- rlang::catch_cnd(loo(rstn_dina))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "supports posterior distributions")

  err <- rlang::catch_cnd(waic(rstn_dino))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "supports posterior distributions")

  check_loo <- suppressWarnings(loo(cmds_dtmr_lcdm))
  expect_s3_class(check_loo, "psis_loo")

  check_waic <- suppressWarnings(waic(cmds_dtmr_dina))
  expect_s3_class(check_waic, "waic")
})

test_that("loo and waic can be added to model", {
  skip_on_cran()

  err <- rlang::catch_cnd(add_criterion(rstn_dino))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "supports posterior distributions")

  waic_model <- suppressWarnings(add_criterion(
    cmds_dtmr_lcdm,
    criterion = "waic"
  ))
  expect_equal(names(waic_model@criteria), "waic")
  expect_s3_class(waic_model@criteria$waic, "waic")
  expect_equal(
    measr_extract(cmds_dtmr_lcdm, "waic"),
    measr_extract(waic_model, "waic")
  )

  lw_model <- suppressWarnings(add_criterion(
    waic_model,
    criterion = c("loo", "waic"),
    overwrite = TRUE
  ))
  expect_equal(names(lw_model@criteria), c("waic", "loo"))
  expect_s3_class(lw_model@criteria$loo, "psis_loo")
  expect_s3_class(lw_model@criteria$waic, "waic")
  expect_identical(waic_model@criteria$waic, lw_model@criteria$waic)

  expect_identical(measr_extract(lw_model, "loo"), lw_model@criteria$loo)
  expect_identical(measr_extract(lw_model, "waic"), lw_model@criteria$waic)

  expect_identical(lw_model@criteria$loo, loo(lw_model))
  expect_identical(lw_model@criteria$waic, waic(lw_model))
})

test_that("model comparisons work", {
  skip_on_cran()

  no_save <- suppressWarnings(loo_compare(cmds_dtmr_lcdm, cmds_dtmr_dina))
  expect_s3_class(no_save, "compare.loo")
  expect_equal(rownames(no_save), c("cmds_dtmr_lcdm", "cmds_dtmr_dina"))
  expect_equal(
    colnames(no_save),
    c(
      "elpd_diff",
      "se_diff",
      "elpd_loo",
      "se_elpd_loo",
      "p_loo",
      "se_p_loo",
      "looic",
      "se_looic"
    )
  )

  lcdm_compare <- suppressWarnings(add_criterion(
    cmds_dtmr_lcdm,
    criterion = c("loo", "waic")
  ))
  lcdm_save <- suppressWarnings(loo_compare(lcdm_compare, cmds_dtmr_dina))
  expect_s3_class(lcdm_save, "compare.loo")
  expect_equal(rownames(lcdm_save), c("lcdm_compare", "cmds_dtmr_dina"))
  expect_equal(
    colnames(lcdm_save),
    c(
      "elpd_diff",
      "se_diff",
      "elpd_loo",
      "se_elpd_loo",
      "p_loo",
      "se_p_loo",
      "looic",
      "se_looic"
    )
  )

  dina_compare <- suppressWarnings(add_criterion(
    cmds_dtmr_dina,
    criterion = c("loo", "waic")
  ))
  dina_save <- suppressWarnings(loo_compare(
    cmds_dtmr_lcdm,
    dina_compare,
    criterion = "waic"
  ))
  expect_s3_class(dina_save, "compare.loo")
  expect_equal(rownames(dina_save), c("cmds_dtmr_lcdm", "dina_compare"))
  expect_equal(
    colnames(dina_save),
    c(
      "elpd_diff",
      "se_diff",
      "elpd_waic",
      "se_elpd_waic",
      "p_waic",
      "se_p_waic",
      "waic",
      "se_waic"
    )
  )

  all_save <- loo_compare(lcdm_compare, dina_compare, criterion = "loo")
  expect_s3_class(all_save, "compare.loo")
  expect_equal(rownames(all_save), c("lcdm_compare", "dina_compare"))
  expect_equal(
    colnames(all_save),
    c(
      "elpd_diff",
      "se_diff",
      "elpd_loo",
      "se_elpd_loo",
      "p_loo",
      "se_p_loo",
      "looic",
      "se_looic"
    )
  )

  err <- rlang::catch_cnd(loo_compare(
    lcdm_compare,
    dina_compare,
    model_names = c("m1", "m2", "m3")
  ))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "same as the number of models")

  err <- rlang::catch_cnd(loo_compare(lcdm_compare, no_save))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a .*measrdcm.* object")

  waic_comp <- loo_compare(
    lcdm_compare,
    dina_compare,
    criterion = "waic",
    model_names = c("first_model", "second_model")
  )
  expect_s3_class(waic_comp, "compare.loo")
  expect_equal(rownames(waic_comp), c("first_model", "second_model"))
  expect_equal(
    colnames(waic_comp),
    c(
      "elpd_diff",
      "se_diff",
      "elpd_waic",
      "se_elpd_waic",
      "p_waic",
      "se_p_waic",
      "waic",
      "se_waic"
    )
  )
})

# aic/bic ----------------------------------------------------------------------
test_that("aic and bic error", {
  err <- rlang::catch_cnd(aic(cmds_dtmr_lcdm))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with .*optim.*")

  err <- rlang::catch_cnd(aic(cmds_dtmr_dina))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with .*optim.*")

  err <- rlang::catch_cnd(bic(cmds_dtmr_lcdm))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with .*optim.*")

  err <- rlang::catch_cnd(bic(cmds_dtmr_dina))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with .*optim.*")
})

# bayes factors ----------------------------------------------------------------
test_that("log_mll works", {
  err <- rlang::catch_cnd(log_mll(rstn_dina))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with")

  err <- rlang::catch_cnd(log_mll(cmds_dtmr_lcdm))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with")

  err <- rlang::catch_cnd(log_mll(cmds_dtmr_dina))
  expect_s3_class(err, "rlang_error")
  expect_match(err$message, "must be a model estimated with")
})

# ppmc -------------------------------------------------------------------------
test_that("ppmc works", {
  skip_on_cran()

  test_ppmc <- fit_ppmc(cmds_dtmr_lcdm)
  expect_equal(test_ppmc, list())

  # test 1 -----
  test_ppmc <- fit_ppmc(
    cmds_dtmr_lcdm,
    ndraws = 500,
    return_draws = 100,
    model_fit = "raw_score",
    item_fit = "conditional_prob"
  )
  expect_equal(names(test_ppmc), c("ppmc_raw_score", "ppmc_conditional_prob"))

  expect_s3_class(test_ppmc$ppmc_raw_score, "tbl_df")
  expect_equal(nrow(test_ppmc$ppmc_raw_score), 1L)
  expect_equal(
    colnames(test_ppmc$ppmc_raw_score),
    c(
      "obs_chisq",
      "ppmc_mean",
      "2.5%",
      "97.5%",
      "rawscore_samples",
      "chisq_samples",
      "ppp"
    )
  )
  expect_equal(nrow(test_ppmc$ppmc_raw_score$rawscore_samples[[1]]), 100)
  expect_equal(length(test_ppmc$ppmc_raw_score$chisq_samples[[1]]), 100)

  expect_s3_class(test_ppmc$ppmc_conditional_prob, "tbl_df")
  expect_equal(nrow(test_ppmc$ppmc_conditional_prob), 162L)
  expect_equal(
    colnames(test_ppmc$ppmc_conditional_prob),
    c(
      "item",
      "class",
      "obs_cond_pval",
      "ppmc_mean",
      "2.5%",
      "97.5%",
      "samples",
      "ppp"
    )
  )
  expect_equal(
    as.character(test_ppmc$ppmc_conditional_prob$item),
    rep(dcmdata::dtmr_qmatrix$item, each = 6)
  )
  expect_equal(
    as.character(test_ppmc$ppmc_conditional_prob$class),
    rep(profile_labels(lcdm_spec)$class, 27)
  )
  expect_equal(
    vapply(test_ppmc$ppmc_conditional_prob$samples, length, integer(1)),
    rep(100, 162)
  )

  # test 2 -----
  test_ppmc <- fit_ppmc(
    cmds_dtmr_dina,
    ndraws = 200,
    return_draws = 180,
    probs = c(0.055, 0.945),
    item_fit = c("odds_ratio", "pvalue")
  )
  expect_equal(names(test_ppmc), c("ppmc_odds_ratio", "ppmc_pvalue"))
  expect_s3_class(test_ppmc$ppmc_odds_ratio, "tbl_df")
  expect_equal(nrow(test_ppmc$ppmc_odds_ratio), 351L)
  expect_equal(
    colnames(test_ppmc$ppmc_odds_ratio),
    c(
      "item_1",
      "item_2",
      "obs_or",
      "ppmc_mean",
      "5.5%",
      "94.5%",
      "samples",
      "ppp"
    )
  )

  item_combos <- tidyr::crossing(
    item1 = lcdm_spec@qmatrix_meta$item_names,
    item2 = lcdm_spec@qmatrix_meta$item_names
  ) |>
    dplyr::filter(.data$item1 < .data$item2)

  expect_equal(
    as.character(test_ppmc$ppmc_odds_ratio$item_1),
    names(lcdm_spec@qmatrix_meta$item_names[item_combos$item1])
  )
  expect_equal(
    as.character(test_ppmc$ppmc_odds_ratio$item_2),
    names(lcdm_spec@qmatrix_meta$item_names[item_combos$item2])
  )
  expect_equal(
    vapply(test_ppmc$ppmc_odds_ratio$samples, length, integer(1)),
    rep(180, 351)
  )

  expect_s3_class(test_ppmc$ppmc_pvalue, "tbl_df")
  expect_equal(nrow(test_ppmc$ppmc_pvalue), 27)
  expect_equal(
    colnames(test_ppmc$ppmc_pvalue),
    c("item", "obs_pvalue", "ppmc_mean", "5.5%", "94.5%", "samples", "ppp")
  )
  expect_equal(
    as.character(test_ppmc$ppmc_pvalue$item),
    dcmdata::dtmr_qmatrix$item
  )
  expect_equal(
    vapply(test_ppmc$ppmc_pvalue$samples, length, double(1)),
    rep(180, 27)
  )

  # test 3 -----
  test_ppmc <- fit_ppmc(
    cmds_dtmr_lcdm,
    ndraws = 1,
    return_draws = 0,
    model_fit = "raw_score",
    item_fit = c("conditional_prob", "odds_ratio", "pvalue")
  )
  expect_equal(
    names(test_ppmc),
    c(
      "ppmc_raw_score",
      "ppmc_conditional_prob",
      "ppmc_odds_ratio",
      "ppmc_pvalue"
    )
  )
  expect_equal(
    colnames(test_ppmc$ppmc_raw_score),
    c("obs_chisq", "ppmc_mean", "2.5%", "97.5%", "ppp")
  )
  expect_equal(
    colnames(test_ppmc$ppmc_conditional_prob),
    c("item", "class", "obs_cond_pval", "ppmc_mean", "2.5%", "97.5%", "ppp")
  )
  expect_equal(
    colnames(test_ppmc$ppmc_odds_ratio),
    c("item_1", "item_2", "obs_or", "ppmc_mean", "2.5%", "97.5%", "ppp")
  )
  expect_equal(
    colnames(test_ppmc$ppmc_pvalue),
    c("item", "obs_pvalue", "ppmc_mean", "2.5%", "97.5%", "ppp")
  )
})

# reliability ------------------------------------------------------------------
test_that("reliability works", {
  reli <- reliability(cmds_dtmr_lcdm, threshold = 0.5)

  expect_equal(
    names(reli),
    c("pattern_reliability", "map_reliability", "eap_reliability")
  )
  expect_equal(names(reli$pattern_reliability), c("p_a", "p_c"))
  expect_equal(names(reli$map_reliability), c("accuracy", "consistency"))

  # column names ---------------------------------------------------------------
  expect_equal(
    names(reli$map_reliability$accuracy),
    c(
      "attribute",
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
    names(reli$map_reliability$consistency),
    c(
      "attribute",
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
    names(reli$eap_reliability),
    c("attribute", "rho_pf", "rho_bs", "rho_i", "rho_tb")
  )

  # row names ------------------------------------------------------------------
  expect_equal(
    reli$map_reliability$accuracy$attribute,
    c(
      "referent_units",
      "partitioning_iterating",
      "appropriateness",
      "multiplicative_comparison"
    )
  )
  expect_equal(
    reli$map_reliability$consistency$attribute,
    c(
      "referent_units",
      "partitioning_iterating",
      "appropriateness",
      "multiplicative_comparison"
    )
  )
  expect_equal(
    reli$eap_reliability$attribute,
    c(
      "referent_units",
      "partitioning_iterating",
      "appropriateness",
      "multiplicative_comparison"
    )
  )
})

# respondent scores ------------------------------------------------------------
test_that("respondent probabilities are correct", {
  skip_on_cran()

  dtmr_preds <- score(
    cmds_dtmr_lcdm,
    newdata = dcmdata::dtmr_data,
    identifier = "id",
    summary = TRUE
  )
  dtmr_full_preds <- score(cmds_dtmr_lcdm, summary = FALSE)

  # dimensions are correct -----
  expect_equal(
    names(dtmr_preds),
    c("class_probabilities", "attribute_probabilities")
  )
  expect_equal(
    colnames(dtmr_preds$class_probabilities),
    c("id", "class", "probability", "2.5%", "97.5%")
  )
  expect_equal(
    colnames(dtmr_preds$attribute_probabilities),
    c("id", "attribute", "probability", "2.5%", "97.5%")
  )
  expect_equal(
    nrow(dtmr_preds$class_probabilities),
    nrow(dcmdata::dtmr_data) * nrow(create_profiles(lcdm_spec))
  )
  expect_equal(
    nrow(dtmr_preds$attribute_probabilities),
    nrow(dcmdata::dtmr_data) * 4
  )

  expect_equal(
    names(dtmr_full_preds),
    c("class_probabilities", "attribute_probabilities")
  )
  expect_equal(
    colnames(dtmr_full_preds$class_probabilities),
    c("id", profile_labels(lcdm_spec)$class)
  )
  expect_equal(
    colnames(dtmr_full_preds$attribute_probabilities),
    c(
      "id",
      "referent_units",
      "partitioning_iterating",
      "appropriateness",
      "multiplicative_comparison"
    )
  )
  expect_equal(
    nrow(dtmr_full_preds$class_probabilities),
    nrow(dcmdata::dtmr_data)
  )
  expect_equal(
    nrow(dtmr_full_preds$attribute_probabilities),
    nrow(dcmdata::dtmr_data)
  )

  # extract works -----
  expect_equal(cmds_dtmr_lcdm@respondent_estimates, list())

  cmds_dtmr_lcdm <- add_respondent_estimates(cmds_dtmr_lcdm)
  expect_equal(cmds_dtmr_lcdm@respondent_estimates, dtmr_preds)
  expect_equal(
    measr_extract(cmds_dtmr_lcdm, "class_prob"),
    dtmr_preds$class_probabilities |>
      dplyr::select("id", "class", "probability") |>
      tidyr::pivot_wider(names_from = "class", values_from = "probability")
  )
  expect_equal(
    measr_extract(cmds_dtmr_lcdm, "attribute_prob"),
    dtmr_preds$attribute_prob |>
      dplyr::select("id", "attribute", "probability") |>
      tidyr::pivot_wider(names_from = "attribute", values_from = "probability")
  )
})
