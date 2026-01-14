test_that("m2 works", {
  m2 <- fit_m2(rstn_dina, ci = 0.8)
  expect_equal(m2$m2, 145.1535, tolerance = 0.1)
  expect_equal(m2$df, 155)
  expect_equal(m2$pval, 0.7031, tolerance = 0.1)
  expect_equal(m2$rmsea, 0, tolerance = 0.1)
  expect_equal(m2$ci_lower, 0, tolerance = 0.1)
  expect_equal(m2$ci_upper, 0.011, tolerance = 0.1)
  expect_equal(m2$srmsr, 0.0309, tolerance = 0.1)

  m2_mod <- add_fit(rstn_dina, method = "m2", ci = 0.8)
  expect_equal(m2_mod@fit$m2, m2)
  expect_equal(
    measr_extract(m2_mod, "m2"),
    dplyr::select(m2, "m2", "df", "pval")
  )
  expect_equal(
    measr_extract(m2_mod, "rmsea"),
    dplyr::select(m2, "rmsea", "80% CI")
  )
  expect_equal(measr_extract(m2_mod, "srmsr"), dplyr::select(m2, "srmsr"))

  # now with DINO -----
  m2 <- fit_m2(rstn_dino, ci = 0.90)
  expect_equal(m2$m2, 173.7192, tolerance = 0.1)
  expect_equal(m2$df, 155)
  expect_equal(m2$pval, 0.1444, tolerance = 0.1)
  expect_equal(m2$rmsea, 0.0127, tolerance = 0.01)
  expect_equal(m2$ci_lower, 0, tolerance = 0.01)
  expect_equal(m2$ci_upper, 0.0218, tolerance = 0.01)
  expect_equal(m2$srmsr, 0.0329, tolerance = 0.1)

  expect_equal(
    measr_extract(rstn_dino, "m2"),
    dplyr::select(m2, "m2", "df", "pval")
  )
  expect_equal(
    measr_extract(rstn_dino, "rmsea"),
    dplyr::select(m2, "rmsea", "90% CI")
  )
  expect_equal(
    measr_extract(rstn_dino, "srmsr"),
    dplyr::select(m2, "srmsr")
  )

  m2_mod <- add_fit(rstn_dino, method = "m2", ci = 0.90)
  expect_equal(m2_mod@fit$m2, m2)
  expect_equal(
    measr_extract(m2_mod, "m2"),
    dplyr::select(m2, "m2", "df", "pval")
  )
  expect_equal(
    measr_extract(m2_mod, "rmsea"),
    dplyr::select(m2, "rmsea", "90% CI")
  )
  expect_equal(measr_extract(m2_mod, "srmsr"), dplyr::select(m2, "srmsr"))

  # recalculating returns same object
  m2_recalc <- fit_m2(m2_mod)
  expect_identical(m2_recalc, m2_mod@fit$m2)
})
