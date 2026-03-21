test_that("sampling tibble works", {
  expect_equal(nrow(sample_ppmc(dcmdata::ecpe_qmatrix, n = 10)), 10L)
  expect_equal(nrow(sample_ppmc(dcmdata::mdm_data, n = 100)), 100L)

  expect_error(
    sample_ppmc(dcmdata::dtmr_qmatrix, n = 30),
    "whole number between 1 and 27"
  )
})

test_that("sampling vector works", {
  expect_equal(length(sample_ppmc(rnorm(100), n = 10)), 10L)
  expect_equal(length(sample_ppmc(runif(1000), n = 100)), 100L)

  expect_error(
    sample_ppmc(rbeta(20, 5, 17), n = 30),
    "whole number between 1 and 20"
  )
})

test_that("unknown class errors", {
  expect_error(sample_ppmc(1:5, n = 2), "Can't find method")
  expect_error(sample_ppmc(letters, n = 10), "Can't find method")
  expect_error(
    sample_ppmc(vector(mode = "logical", length = 60), n = 15),
    "Can't find method"
  )
})
