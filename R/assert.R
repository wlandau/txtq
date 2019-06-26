assert_file <- function(x) {
  if (!file.exists(x)) {
    stop("invalid txtq: file ", shQuote(x), " does not exist", call. = FALSE)
  }
  invisible()
}

assert_dir <- function(x) {
  assert_file(x)
  if (!dir.exists(x)) {
    stop(
      "invalid txtq: file ",
      shQuote(x),
      " is not a directory",
      call. = FALSE
    )
  }
  invisible()
}

assert_file_scalar <- function(x) {
  assert_file(x)
  tryCatch({
    y <- scan(x, quiet = TRUE, what = integer())
    stopifnot(length(y) == 1L)
  },
  error = function(e) {
    stop(
      "invalid txtq: file ",
      shQuote(x),
      " must contain an integer of length 1.",
      call. = FALSE
    )
  })
}
