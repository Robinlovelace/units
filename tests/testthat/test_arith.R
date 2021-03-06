context("Arithmetic")

test_that("we can compare vectors with equal units", {
  x <- 1:4 * make_unit("m")
  y <- 1:4 * make_unit("m")
  z <- 2 * y
  
  expect_true(all(x == y))
  expect_true(all(x <= y))
  expect_true(all(x >= y))
  
  expect_true(all(x < z))
  expect_true(all(x <= z))
  expect_true(all(z > x))
  expect_true(all(z >= x))
  
  expect_false(any(x > y))
  expect_false(any(x != y))
  expect_true(all(x != z))
})

test_that("we can scale units with scalars", {
  x <- 1:4
  ux <- x * make_unit("m")
  
  expect_equal(as.numeric(10 * ux), 10 * x)
  expect_equal(as.numeric(ux / 10), x / 10)
})

test_that("we can multiply and divide units", {
  x <- 1:4 ; y <- 5:8
  m <- x * make_unit("m")
  s <- y * make_unit("s")
  
  expect_equal(as.numeric(m * s), x * y)
  expect_equal(as.numeric(m / s), x / y)
  
  # FIXME: There ought to be a test that the expressions get the right units
  # but I am not entirely sure how that should be wrapped. Just checking string
  # equality would give problems if units are equivalent but needs to be converted
  # first...
})

test_that("we can take powers of units", {
  x <- 1:4
  ux <- x * make_unit("m")
  
  expect_equal(as.numeric(ux ** 2), x ** 2)
  expect_equal(as.numeric(ux ^ 2), x ^ 2)
  expect_equal(as.character(units(ux ** 2)), "m^2")
  expect_equal(as.character(units(ux ^ 2)), "m^2")
  
  expect_error(ux ^ 1.3)
  expect_error(ux ^ 0.3)
  expect_error(ux ^ ux)
  expect_error(ux ^ x)
  
  expect_equal(as.numeric(ux ** -2), x ** -2)
  expect_equal(as.numeric(ux ^ -2), x ^ -2)
  expect_equal(as.character(units(ux ** -2)), "1/m^2")
  expect_equal(as.character(units(ux ^ -2)), "1/m^2")
  
  expect_equal(as.numeric(ux ** 0), x ** 0)
  expect_equal(as.numeric(ux ^ 0), x ^ 0)
  expect_equal(units(ux ** 0), unitless)
  expect_equal(units(ux ^ 0), unitless)
})

test_that("we can convert units and simplify after multiplication", {
  x <- 1:4
  y <- 1:4
  z <- 1:4
  m <- make_unit("m")
  s <- make_unit("s")
  km <- make_unit("km")
  ux <- x * m
  uy <- y * s
  uz <- z * km
  
  expect_equal(as.numeric(ux/ux), x/x)
  expect_equal(as.character(units(ux/ux)), "1")
  
  expect_equal(as.numeric(ux*uy), x*y)
  expect_equal(as.character(units(ux*uy)), "m*s")
  expect_equal(as.numeric(ux*uz), x*z)
  expect_equal(as.character(units(ux*uz)), "km*m")
  expect_equal(as.numeric(as.units(ux*uz, km * km)), (x/1000)*z)
  expect_equal(as.character(units(as.units(ux*uz, km * km))), "km^2")
  
  expect_equal(as.numeric(ux/ux), x/x)
  expect_equal(as.character(units(ux/ux)), "1")
  expect_equal(as.numeric(ux/uy), x/y)
  expect_equal(as.character(units(ux/uy)), "m/s")
  expect_equal(as.numeric(ux/uz), x/(1000*z))
  expect_equal(as.character(units(ux/uz)), "1")
  expect_equal(as.numeric(ux/uy/uz), x/y/(1000*z))
  expect_equal(as.character(units(ux/uy/uz)), "1/s")
})
