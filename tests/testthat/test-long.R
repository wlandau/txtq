test_that("txtq is thread safe", {
  f <- function(process, in_, out_) {
    q <- txtq::txtq(in_)
    if (identical(process, "A")) {
      while (nrow(q$log()) < 1000 || !q$empty()) {
        i <- 1
        p <- txtq::txtq(out_)
        msg <- q$pop()
        if (nrow(msg) > 0) {
          p$push(msg$title, msg$message)
        }
      }
    } else {
      for (i in seq_len(1000)) {
        q$push(title = as.character(i), message = as.character(i + 1))
      }
    }
  }
  cl <- parallel::makePSOCKcluster(2)
  in_ <- tempfile()
  out_ <- tempfile()
  parallel::parLapply(
    cl = cl, X = c("A", "B"), fun = f, in_ = in_, out_ = out_)
  parallel::stopCluster(cl)
  q <- txtq(in_)
  p <- txtq(out_)
  cols <- c("title", "message")
  expect_equal(nrow(q$list()), 0)
  expect_equal(nrow(q$log()), 1000)
  expect_equal(nrow(p$log()), 1000)
  expect_equal(p$list()[, cols], q$log()[, cols])
  expect_equal(p$list()[, cols], p$log()[, cols])
})


test_that("long message", {
  q <- txtq(tempfile())
  s <- paste(sample(LETTERS, 3000000, TRUE), collapse = "")
  q$push(title = "long", message = s)
  out <- q$pop(-1)
  expect_equal(s, out$message)
  q$destroy()
})
