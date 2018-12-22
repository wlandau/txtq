context("txtq")

test_that("core txtq utilities work", {
  q <- txtq(tempfile())
  expect_true(file.exists(q$path()))
  expect_true(q$empty())
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 0)
  null_df <- data.frame(
    title = character(0),
    message = character(0),
    time = as.POSIXct(character(0)),
    stringsAsFactors = FALSE
  )
  expect_equal(q$pop(), null_df)
  expect_equal(q$pop(), null_df)
  expect_equal(q$list(), null_df)
  expect_equal(q$log(), null_df)
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 0)
  q$push(title = 1:2, message = 2:3)
  q$push(title = "74", message = "\"128\"")
  q$push(title = "71234", message = "My sentence is not long.")
  db <- file.path(q$path(), "db")
  expect_false(q$empty())
  expect_equal(q$count(), 4)
  expect_equal(q$total(), 4)
  full_df <- data.frame(
    title = c(1, 2, "74", "71234"),
    message = c(2, 3, "\"128\"", "My sentence is not long."),
    stringsAsFactors = FALSE
  )
  cols <- c("title", "message")
  expect_equal(q$list()[, cols], full_df)
  expect_equal(q$log()[, cols], full_df)
  o <- q$pop(1)
  expect_false(q$empty())
  expect_equal(q$count(), 3)
  expect_equal(q$total(), 4)
  expect_equal(q$list()$title, full_df[-1, "title"])
  expect_equal(q$list()$message, full_df[-1, "message"])
  expect_equal(q$log()[, cols], full_df)
  out <- q$pop(-1)
  expect_equal(out$title, full_df[-1, "title"])
  expect_equal(out$message, full_df[-1, "message"])
  expect_true(q$empty())
  expect_equal(q$count(), 0)
  expect_equal(q$list(), null_df)
  expect_equal(q$log()[, cols], full_df)
  q$push(title = "new", message = "message")
  expect_false(q$empty())
  expect_equal(q$count(), 1)
  one_df <- data.frame(
    title = "new",
    message = "message",
    stringsAsFactors = FALSE
  )
  expect_equal(q$list()[, cols], one_df)
  expect_equal(q$log()[, cols], rbind(full_df, one_df))
  expect_true(file.exists(q$path()))
  q$destroy()
  expect_false(file.exists(q$path()))
})

test_that("$reset()", {
  q <- txtq(tempfile())
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 0)
  expect_equal(nrow(q$log()), 0)
  q$push(title = 1:5, message = letters[1:5])
  expect_equal(q$count(), 5)
  expect_equal(q$total(), 5)
  expect_equal(nrow(q$log()), 5)
  q$reset()
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 0)
  expect_equal(nrow(q$log()), 0)
  q$push(title = 1:5, message = letters[1:5])
  q$pop(n = 5)
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 5)
  expect_equal(nrow(q$log()), 5)
  q$reset()
  expect_equal(q$count(), 0)
  expect_equal(q$total(), 0)
  expect_equal(nrow(q$log()), 0)
})

test_that("$clean()", {
  df <- function(index){
    data.frame(
      title = as.character(index),
      message = as.character(letters[index]),
      stringsAsFactors = FALSE
    )
  }
  cols <- c("title", "message")
  q <- txtq(tempfile())
  q$push(title = as.character(1:5), message = letters[1:5])
  expect_equal(q$pop(n = 2)[, cols], df(index = 1:2))
  expect_equal(q$list()[, cols], df(index = 3:5))
  expect_equal(q$log()[, cols], df(index = 1:5))
  expect_equal(q$count(), 3)
  expect_equal(q$total(), 5)
  for (i in 1:2){
    q$clean()
    expect_equal(q$list()[, cols], df(index = 3:5))
    expect_equal(q$log()[, cols], df(index = 3:5))
    expect_equal(q$count(), 3)
    expect_equal(q$total(), 3)
  }
})

test_that("txtq is thread safe", {
  f <- function(process, in_, out_){
    q <- txtq::txtq(in_)
    if (identical(process, "A")){
      while (nrow(q$log()) < 1000 || !q$empty()){
        i <- 1
        p <- txtq::txtq(out_)
        msg <- q$pop()
        if (nrow(msg) > 0){
          p$push(msg$title, msg$message)
        }
      }
    } else {
      for (i in seq_len(1000)){
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
