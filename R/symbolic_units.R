
.symbolic_units <- function(nominator, denominator = vector("character")) {
  structure(list(nominator = nominator, 
                 denominator = denominator), 
            class = "symbolic_units")
}

.invert_symbolic_units <- function(e) {
  .symbolic_units(e$denominator, e$nominator)
}

.multiply_symbolic_units <- function(e1, e2) {
  nominator <- sort(c(e1$nominator, e2$nominator))
  denominator <- sort(c(e1$denominator, e2$denominator))
  .simplify_units(.symbolic_units(nominator, denominator))
}

.same_units <- function(e1, e2) {
  all(e1$nominator == e2$nominator) && all(e1$denominator == e2$denominator)
}

# Inside the group generic functions we do have .Generic even if the diagnostics
# think we do not.
# !diagnostics suppress=.Generic
#' @export
Ops.symbolic_units <- function(e1, e2) {
  if (nargs() == 1)
    stop(paste("unary", .Generic, "not defined for \"units\" objects"))
  
  eq <- switch(.Generic, "==" = , "!=" = TRUE, FALSE)
  if (eq) {
    if (.Generic == "==") return(.same_units(e1, e2))
    else return(!.same_units(e1, e2))
  }
  
  prd <- switch(.Generic, "*" = , "/" = TRUE, FALSE)
  if (!prd) stop(paste("operation", .Generic, "not allowed for symbolic operators"))
  
  if (!inherits(e1, "symbolic_units") || !inherits(e2, "symbolic_units")) {
    stop(paste("Arithmetic operations on symbolic units only possible ",  # nocov
               "if both arguments are symbolic units", sep = "\n"))       # nocov
  }
  
  if (.Generic == "*") .multiply_symbolic_units(e1, e2)         # multiplication
  else .multiply_symbolic_units(e1, .invert_symbolic_units(e2)) # division
}

.make_symbolic_units <- function(name) {
  .symbolic_units(name)
}

#' The "unit" type for vectors that are actually dimension-less.
#' @export
unitless <- .symbolic_units(vector("character"), vector("character"))

#' @export
as.character.symbolic_units <- function(x, ...) {
  nom_str <- ""
  sep <- ""
  denom_str <- ""
  
  if (length(x$nominator) == 0) {
    nom_str <- "1"
  } else if (length(x$nominator) == 1) {
    nom_str <- x$nominator
  } else {
    nom_str <- paste0(x$nominator, collapse = "*")
  }
  
  if (length(x$denominator) > 0) {
    sep = "/"
    if (length(x$denominator) == 1) {
      denom_str = x$denominator
    } else {
      denom_str <- paste0(x$denominator, collapse = "/")
    }
  }

  paste0(nom_str, sep, denom_str)
}

#' Create a new unit from a unit name.
#' 
#' @param name  Name of the new unit
#' @return A new unit object that can be used in arithmetics
#' 
#' @export
make_unit <- function(name) {
  as.units.default(1, .make_symbolic_units(name))
}

.get_unit_conversion_constant <- function(u1, u2) {
  # FIXME: Unit conversion only has limited support right now
  # I always just ask ud to convert units.
  su1 <- as.character(u1)
  su2 <- as.character(u2)
  
  if (!udunits2::ud.are.convertible(su1, su2)) return(NA)
  ud.convert(1, su1, su2)
}

.get_conversion_constant_sequence <- function(s1, s2) {
  conversion_constant <- 1
  remaining_s2 <- s2
  for (i in seq_along(s1)) {
    for (j in seq_along(remaining_s2)) {
      convert <- .get_unit_conversion_constant(s1[i], remaining_s2[j])
      if (!is.na(convert)) {
        conversion_constant <- conversion_constant * convert
        remaining_s2 <- remaining_s2[-j]
        break
      }
    }
  }
  # if we make it through these loops and there are still units left in s2
  # then there are some we couldn't convert, and then we return NA
  if (length(remaining_s2) > 0) 
    NA
  else 
    conversion_constant
}

.get_conversion_constant <- function(u1, u2) {
  # if the expressions are well formed, and can be converted, we can convert
  # nominator and denominator independently. If either cannot be converted
  # then the function call returns NA which will also be returned (since NA and /)
  # will convert to NA.
  .get_conversion_constant_sequence(u1$nominator, u2$nominator) /
    .get_conversion_constant_sequence(u1$denominator, u2$denominator)
}

.simplify_units <- function(sym_units) {
  
  # This is just a brute force implementation that takes each element in the
  # nominator and tries to find a value in the denominator that can be converted
  # to the same unit. If so, we pull out the conversion constant, get rid of
  # both terms, and move on. At the end we return a units object with the
  # conversion constant and the new symbolic units type. Converting units can then
  # be done as this `x <- as.numeric(x) * .simplify_units(units(x))`.
  
  # Returning a units instead of a symbolic_units object is not idea, it means that
  # you cannot simply multiply or divide symbolic units together, you need to wrap
  # each pair-wise operator in units() but it is necessary when conversion constants
  # must be taken into account.
  
  conversion_constant <- 1
  new_nominator <- sym_units$nominator
  new_denominator <- sym_units$denominator
  
  delete_nom <- c()
  for (i in seq_along(new_nominator)) {
    for (j in seq_along(new_denominator)) {
      conversion <- .get_unit_conversion_constant(new_nominator[i], new_denominator[j])
      if (!is.na(conversion)) {
        conversion_constant <- conversion_constant * conversion
        delete_nom <- c(delete_nom, i)
        new_denominator <- new_denominator[-j]
        break
      }
    }
  }
  if (length(delete_nom) > 0)
    new_nominator <- new_nominator[-delete_nom]
  
  as.units(conversion_constant, .symbolic_units(new_nominator, new_denominator))
}
