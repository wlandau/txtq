context("validate")

test_that("cannot create dir because a file is already there", {
  path <- tempfile()
  file.create(path)
  expect_error(txtq(path), regexp = "cannot create directory")
})

test_that("file is not a directory", {
  q <- txtq(tempfile())
  path <- q$path()
  unlink(path, recursive = TRUE)
  file.create(path)
  expect_error(q$validate(), regexp = "not a directory")
})

test_that("missing files", {
  for (file in c("db", "head", "total")) {
    q <- txtq(tempfile())
    unlink(file.path(q$path(), file))
    expect_error(q$validate(), regexp = "does not exist")
  }
})

test_that("missing counters", {
  for (file in c("head", "total")) {
    q <- txtq(tempfile())
    f <- file.path(q$path(), file)
    unlink(f)
    file.create(f)
    expect_error(q$validate(), regexp = "integer of length 1")
  }
})
