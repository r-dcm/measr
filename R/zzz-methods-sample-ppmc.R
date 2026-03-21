sample_ppmc <- S7::new_generic("sample_ppmc", "x", function(x, n, ...) {
  S7::S7_dispatch()
})

# methods-----------------------------------------------------------------------
S7::method(sample_ppmc, S7::new_S3_class("tbl_df")) <- function(x, n) {
  check_number_whole(n, min = 1, max = as.numeric(nrow(x)))
  dplyr::slice_sample(x, n = n)
}

S7::method(sample_ppmc, S7::new_S3_class("double")) <- function(x, n) {
  check_number_whole(n, min = 1, max = as.numeric(length(x)))
  sample(x, size = n)
}
