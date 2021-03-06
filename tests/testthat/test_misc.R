context("Misc. utility functions")

test_that("We can concatenate units if they have the same unit", {
  x <- 1:4 * make_unit("m")
  y <- 5:8 * make_unit("m")
  z <- c(x, y)
  
  expect_equal(length(z), length(x) + length(y))
  expect_equal(x, z[1:4])
  expect_equal(y, z[1:4 + 4])
})

test_that("We can't concatenate units if they have different units", {
  x <- 1:4 * make_unit("m")
  y <- 5:8 * make_unit("s")
  expect_error(c(x, y))
})

test_that("We can concatenate units if their units can be converted", {
  x <- 1:4 * make_unit("m")
  y <- 5:8 * make_unit("km")
  z <- c(x, y)
  
  expect_equal(length(z), length(x) + length(y))
  expect_equal(as.character(units(z)), "m")
  expect_equal(x, z[1:4])
  expect_equal(as.units(y, units(make_unit("m"))), z[1:4 + 4])
})

test_that("We can use diff on a units object", {
  x = 1:10 * make_unit("m")
  y = rep(1,9) * make_unit("m")
  expect_equal(diff(x), y)
})

test_that("type_sum is available for units objects", {
  library(tibble)
  expect_equal(type_sum(make_unit("m")), "units")
})

test_that("parse_unit works", {
  kg = make_unit("kg")
  m = make_unit("m")
  s = make_unit("s")
  u0 = kg/m/m/s
  u = parse_unit("kg m-2 s-1")
  expect_equal(u, u0)
  J = make_unit("J")
  u0 = with(ud_units, kg*kg*kg*m*m*J/s/s/s/s/s)
  u = parse_unit("kg3 m2 s-5 J")
  expect_equal(u, u0)
})

test_that("as_cf works", {
  str = "kg m-2 s-1"
  u = parse_unit(str)
  str0 = as_cf(u)
  expect_equal(str, str0)
})
