# loo 2.10.0 changed the output of `loo_compare()` from a matrix with model
# names as row names to a data frame with a `model` column and additional
# diagnostic columns. These helpers check the output with either structure.
loo_compare_models <- function(x) {
  if ("model" %in% colnames(x)) x$model else rownames(x)
}

expect_loo_compare <- function(object, models, criterion = c("loo", "waic")) {
  criterion <- rlang::arg_match(criterion)
  crit_cols <- switch(
    criterion,
    loo = c("elpd_loo", "se_elpd_loo", "p_loo", "se_p_loo", "looic"),
    waic = c("elpd_waic", "se_elpd_waic", "p_waic", "se_p_waic", "waic")
  )

  testthat::expect_s3_class(object, "compare.loo")
  # models are sorted by fit, which can vary across platforms
  testthat::expect_setequal(loo_compare_models(object), models)
  elpd_diff <- unname(object[, "elpd_diff"])
  testthat::expect_equal(elpd_diff[1], 0)
  testthat::expect_false(is.unsorted(rev(elpd_diff)))
  testthat::expect_contains(
    colnames(object),
    c("elpd_diff", "se_diff", crit_cols)
  )
}
