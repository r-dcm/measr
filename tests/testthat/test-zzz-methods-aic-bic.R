test_that("aic and bic work", {
  num_params <- 55
  n <- 750
  dina_log_lik <- -8642.807
  dino_log_lik <- -8361.498

  expect_equal(
    (-2 * dina_log_lik) + (2 * num_params),
    aic(rstn_dina),
    tolerance = 0.01
  )
  expect_equal(
    (-2 * dina_log_lik) + (log(n) * num_params),
    bic(rstn_dina),
    tolerance = 0.01
  )
  expect_equal(
    (-2 * dino_log_lik) + (2 * num_params),
    aic(rstn_dino),
    tolerance = 0.01
  )
  expect_equal(
    (-2 * dino_log_lik) + (log(n) * num_params),
    bic(rstn_dino),
    tolerance = 0.01
  )

  expect_equal(aic(rstn_dina), 17395.61, tolerance = 0.01)
  expect_equal(bic(rstn_dina), 17649.72, tolerance = 0.01)
  expect_equal(aic(rstn_dino), 16833.00, tolerance = 0.01)
  expect_equal(bic(rstn_dino), 17087.10, tolerance = 0.01)
})

test_that("store aic and bic", {
  # dina aic -------------------------------------------------------------------
  expect_true(rlang::is_empty(rstn_dina@criteria$aic))
  expect_true(rlang::is_empty(rstn_dina@criteria$bic))

  dina_aic <- add_criterion(rstn_dina, "aic")
  expect_false(rlang::is_empty(dina_aic@criteria$aic))
  expect_true(rlang::is_empty(dina_aic@criteria$bic))
  expect_identical(aic(rstn_dina), dina_aic@criteria$aic)
  expect_identical(aic(dina_aic), dina_aic@criteria$aic)
  expect_identical(measr_extract(dina_aic, "aic"), aic(rstn_dina))
  expect_identical(
    measr_extract(rstn_dina, "aic"),
    measr_extract(dina_aic, "aic")
  )

  # dino bic -------------------------------------------------------------------
  expect_true(rlang::is_empty(rstn_dino@criteria$aic))
  expect_true(rlang::is_empty(rstn_dino@criteria$bic))

  dino_bic <- add_criterion(rstn_dino, "bic")
  expect_false(rlang::is_empty(dino_bic@criteria$bic))
  expect_true(rlang::is_empty(dino_bic@criteria$aic))
  expect_identical(bic(rstn_dino), dino_bic@criteria$bic)
  expect_identical(bic(dino_bic), dino_bic@criteria$bic)
  expect_identical(measr_extract(dino_bic, "bic"), bic(rstn_dino))
  expect_identical(
    measr_extract(rstn_dino, "bic"),
    measr_extract(dino_bic, "bic")
  )

  dino_bic <- add_criterion(dino_bic, c("aic", "bic"), overwrite = TRUE)
  expect_false(rlang::is_empty(dino_bic@criteria$bic))
  expect_false(rlang::is_empty(dino_bic@criteria$aic))
  expect_identical(bic(rstn_dino), dino_bic@criteria$bic)
  expect_identical(bic(dino_bic), dino_bic@criteria$bic)
  expect_identical(aic(rstn_dino), dino_bic@criteria$aic)
  expect_identical(aic(dino_bic), dino_bic@criteria$aic)

  expect_equal(measr_extract(dino_bic, "aic"), 16833.00, tolerance = .0001)
  expect_equal(measr_extract(dino_bic, "bic"), 17087.10, tolerance = .0001)
})
