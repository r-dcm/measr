sample_ppmc <- S7::new_generic("sample_ppmc", "x", function(x, n, ...) {
  S7::S7_dispatch()
})

# methods-----------------------------------------------------------------------
S7::method(sample_ppmc, S7::new_S3_class("tbl_df")) <- function(x, n) {
  dplyr::slice_sample(x, n = n)
}

S7::method(sample_ppmc, S7::new_S3_class("double")) <- function(x, n) {
  sample(x, size = n)
}
