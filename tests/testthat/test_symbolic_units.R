context("Symbolic unit manipulation")

test_that("we can make symbolic units", {
  m <- units:::.make_symbolic_units("m")
  expect_true(inherits(m, "symbolic_units"))
  expect_equal(as.character(m), "m")
})

test_that("we can multiply and divide symbolic units", {
  m <- units:::.make_symbolic_units("m")
  s <- units:::.make_symbolic_units("s")
  expect_equal(as.character(units(m*m)), "m^2")
  expect_equal(as.character(units(m/s)), "m/s")
  expect_equal(as.character(units(units(m/s)/s)), "m/s^2")
})

test_that("we can simplify basic units", {
  m <- units:::.make_symbolic_units("m")
  s <- units:::.make_symbolic_units("s")
  expect_equal(as.character(units(m/m)), "1")
  expect_equal(as.character(units(units(m/s)/m)), "1/s")
  expect_equal(as.character(units(units(m*m)/m)), "m")
  expect_equal(as.character(units(units(s/m)/s)), "1/m")
})

test_that("we can simplify basic units", {
  m <- units:::.make_symbolic_units("m")
  s <- units:::.make_symbolic_units("s")
  expect_equal(as.character(units(m/m)), "1")
  expect_equal(as.character(units(units(m/s)/m)), "1/s")
  expect_equal(as.character(units(units(m*m)/m)), "m")
  expect_equal(as.character(units(units(s/m)/s)), "1/m")
})

test_that("we can simplify basic units with conversion", {
  m <- units:::.make_symbolic_units("m")
  s <- units:::.make_symbolic_units("s")
  km <- units:::.make_symbolic_units("km")
  expect_equal(as.character(units(m/m)), "1")
  expect_equal(as.character(units(m/km)), "1")
  expect_equal(as.character(units(units(m/s)/km)), "1/s")
  expect_equal(as.character(units(units(m*m)/km)), "m")
})

test_that("we can compare units", {
  g <- make_unit("g")
  m <- make_unit("m")
  s <- make_unit("s")
  q <- make_unit("q")
  e1 <- 1:10 * g * m / s / q
  e2 <- 1:10 * m / s
  expect_equal(units:::.same_units(units(e1),units(e1)), TRUE)
  expect_equal(units:::.same_units(units(e1),units(e2)), FALSE)
  expect_equal(units(e1) == units(e1), TRUE)
  expect_equal(units(e1) != units(e1), FALSE)
  expect_equal(units(e1) == units(e2), FALSE)
  expect_equal(units(e1) != units(e2), TRUE)
})
