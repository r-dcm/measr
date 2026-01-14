on_cran <- function() {
  env <- Sys.getenv("NOT_CRAN")
  if (identical(env, "")) {
    !interactive()
  } else {
    !isTRUE(as.logical(env))
  }
}

skip_on_cran_os <- function(os) {
  os <- rlang::arg_match(
    os,
    values = c("windows", "mac", "linux", "solaris", "emscripten"),
    multiple = TRUE
  )
  system_os <- tolower(Sys.info()[["sysname"]])

  if (system_os %in% os && on_cran()) {
    os_msg <- switch(
      system_os,
      windows = if ("windows" %in% os) "On Windows",
      darwin = if ("mac" %in% os) "On Mac",
      linux = if ("linux" %in% os) "On Linux",
      sunos = if ("solaris" %in% os) "On Solaris",
      emscripten = if ("emscripten" %in% os) "On Emscripten"
    )
    msg <- paste(os_msg, "on CRAN")
  } else {
    msg <- NULL
  }

  if (is.null(msg)) {
    invisible(TRUE)
  } else {
    skip(msg)
  }
}
