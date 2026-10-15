test_that("saved output files are detected with any id format", {
  dir <- fs::path_abs(withr::local_tempdir())

  # unpadded (cmdstanr < 0.9.0.9002) and zero-padded ids
  expect_true(saved_output_files(
    fs::path(dir, paste0("model-", 1:2, ".csv")),
    dir,
    "model.rds"
  ))
  expect_true(saved_output_files(
    fs::path(dir, sprintf("model-%02d.csv", 1:4)),
    dir,
    "model.rds"
  ))

  # different directory, basename, or extra suffixes
  expect_false(saved_output_files(
    fs::path(dir, "other", "model-01.csv"),
    dir,
    "model.rds"
  ))
  expect_false(saved_output_files(
    fs::path(dir, "mod-01.csv"),
    dir,
    "model.rds"
  ))
  expect_false(saved_output_files(
    fs::path(dir, "model-202610151200-01-abc123.csv"),
    dir,
    "model.rds"
  ))
  expect_false(saved_output_files(character(0), dir, "model.rds"))
})
