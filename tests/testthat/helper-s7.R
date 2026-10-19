# Comparing S7 objects with `expect_equal()` also compares their class objects.
# Classes that inherit from `S7::S7_object` embed S7's own source references,
# which can hold lazy-load promises tied to the library S7 was loaded from when
# measr was installed.
# Under R CMD check that library is temporary and removed before tests run, so
# forcing those promises errors.
# This helper reduces S7 objects to their class names and property values for
# comparison.
s7_contents <- function(x) {
  if (S7::S7_inherits(x)) {
    c(list(.class = class(x)), lapply(S7::props(x), s7_contents))
  } else {
    x
  }
}
