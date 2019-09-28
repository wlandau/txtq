test_that("import (#17)", {
  grid <- expand.grid(
    ext_popped = c(0, 13),
    ext_unpopped = c(0, 4),
    this_popped = c(0, 23),
    this_unpopped = c(0, 14)
  )
  purrr::pwalk(grid, test_import)
})
