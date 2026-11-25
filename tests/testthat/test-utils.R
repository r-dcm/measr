test_that("examples work", {
  expect_false(measr_examples())
})

test_that("eval_silent() retries after an error", {
  expect_equal(eval_silent("value"), "value")

  # don't print the error from the first attempt
  withr::local_options(show.error.messages = FALSE)

  # an expression that fails is evaluated a second time
  attempts <- 0
  out <- eval_silent({
    attempts <- attempts + 1
    if (attempts == 1) {
      stop("first attempt")
    }
    "second attempt"
  })
  expect_equal(attempts, 2)
  expect_equal(out, "second attempt")

  # and the error is surfaced if it fails again
  expect_error(eval_silent(stop("always fails")), "always fails")
})
