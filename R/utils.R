dir_create <- function(x) {
  if (!file.exists(x)) {
    dir.create(x)
  }
  if (!dir.exists(x)) {
    stop("txtq cannot create directory at ", shQuote(x), call. = FALSE)
  }
  invisible()
}

# Avoid truncation in base::file.create() # nolint
file_create <- function(x) {
  if (!file.exists(x)) {
    file.create(x)
  }
  invisible()
}

microtime <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%OS9 %z GMT")
}

null_log <- data.frame(
  title = character(0),
  message = character(0),
  time = character(0),
  stringsAsFactors = FALSE
)

parse_db <- function(x) {
  colnames(x) <- c("title", "message", "time")
  x$title <- base64url::base64_urldecode(x$title)
  x$message <- base64url::base64_urldecode(x$message)
  x$time <- base64url::base64_urldecode(x$time)
  x
}

read_db_table <- function(dbfile, skip, n) {
  t <- scan(
    dbfile,
    what = character(),
    sep = "|",
    skip = skip,
    nmax = 3 * n,
    quote = "",
    na.strings = NULL,
    quiet = TRUE)
  out <- as.data.frame(
    matrix(t, byrow = TRUE, ncol = 3),
    stringsAsFactors = FALSE
  )
  parse_db(out)
}
