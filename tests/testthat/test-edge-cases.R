context("edge cases")

test_that("subdirectories (#13)", {
  f <- file.path(tempfile(), "x", "y", "z")
  q <- txtq(f)
  q$push("x", "y")
  expect_equal(q$pop()$title, "x")
})

test_that("do not push messages of length 0 (#15)", {
  q <- txtq(tempfile())
  q$push(title = character(0), message = character(0))
  for (i in 1:3) {
    q$push(title = as.character(i), message = letters[i])
  }
  q$push(title = character(0), message = character(0))
  for (i in 4:6) {
    q$push(title = as.character(i), message = letters[i])
  }
  for (i in 1:6) {
    msg <- q$pop(1)
    expect_equal(msg$title, as.character(i))
    expect_equal(msg$message, letters[i])
  }
  q$clean()
  for (i in 1:3) {
    q$push(title = as.character(i), message = letters[i])
  }
  for (i in 1:3) {
    msg <- q$pop(1)
    expect_equal(msg$title, as.character(i))
    expect_equal(msg$message, letters[i])
  }
})
