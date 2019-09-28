test_import <- function(
  ext_popped,
  ext_unpopped,
  this_popped,
  this_unpopped
) {
  q_ext <- txtq(tempfile())
  q_this <- txtq(tempfile())
  for (i in seq_len(ext_popped)) {
    q_ext$push(title = "ext", message = "popped")
  }
  for (i in seq_len(ext_unpopped)) {
    q_ext$push(title = "ext", message = "unpopped")
  }
  for (i in seq_len(this_popped)) {
    q_this$push(title = "this", message = "popped")
  }
  for (i in seq_len(this_unpopped)) {
    q_this$push(title = "this", message = "unpopped")
  }
  o <- q_ext$pop(ext_popped)
  expect_equal(nrow(o), ext_popped)
  expect_true(all(o$title == "ext"))
  expect_true(all(o$message == "popped"))
  l <- q_ext$list()
  expect_equal(nrow(l), ext_unpopped)
  expect_true(all(l$title == "ext"))
  expect_true(all(l$message == "unpopped"))
  o <- q_this$pop(this_popped)
  expect_equal(nrow(o), this_popped)
  expect_true(all(o$title == "this"))
  expect_true(all(o$message == "popped"))
  l <- q_this$list()
  expect_equal(nrow(l), this_unpopped)
  expect_true(all(l$title == "this"))
  expect_true(all(l$message == "unpopped"))
  q_this$import(q_ext)
  o <- q_this$list()
  expect_equal(nrow(o), ext_unpopped + this_unpopped)
  expect_equal(sum(o$title == "ext"), ext_unpopped)
  expect_equal(sum(o$title == "this"), this_unpopped)
  expect_true(all(o$message == "unpopped"))
  expect_true(all(sort(o$time) == o$time))
  o <- q_this$log()
  expect_equal(
    nrow(o),
    ext_popped + ext_unpopped + this_popped + this_unpopped
  )
  expect_equal(sum(o$title == "ext"), ext_popped + ext_unpopped)
  expect_equal(sum(o$title == "this"), this_popped + this_unpopped)
  expect_equal(
    o$message,
    c(
      rep("popped", ext_popped + this_popped),
      rep("unpopped", ext_unpopped + this_unpopped)
    )
  )
  p <- o[o$message == "popped",, drop = FALSE] # nolint
  expect_true(all(sort(p$time) == p$time))
  p <- o[o$message == "unpopped",, drop = FALSE] # nolint
  expect_true(all(sort(p$time) == p$time))
}
