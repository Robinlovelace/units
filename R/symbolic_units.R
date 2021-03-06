
.symbolic_units <- function(numerator, denominator = vector("character")) {
  structure(list(numerator = numerator, 
                 denominator = denominator), 
            class = "symbolic_units")
}

.invert_symbolic_units <- function(e) {
  .symbolic_units(e$denominator, e$numerator)
}

.multiply_symbolic_units <- function(e1, e2) {
  numerator <- sort(c(e1$numerator, e2$numerator))
  denominator <- sort(c(e1$denominator, e2$denominator))
  .simplify_units(.symbolic_units(numerator, denominator))
}

.same_units <- function(e1, e2) {
  all(e1$numerator == e2$numerator) && all(e1$denominator == e2$denominator)
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

.pretty_print_sequence <- function(terms, op, neg_power = FALSE, sep = "") {
  # `fix` handles cases where a unit is actually an expression. We would have to
  # deparse these to really do a pretty printing, but for now we leave them alone...
  fix <- function(term) {
    if (length(grep("/", term)) || length(grep("-", term)))
      paste0("(", term, ")")
    else
      term
  }
  fixed <- vapply(terms, fix, "")
  fixed_tbl <- table(fixed)
  
  names <- names(fixed_tbl)
  result <- vector("character", length(fixed_tbl))
  for (i in seq_along(fixed_tbl)) {
    name <- names[i]
    value <- fixed_tbl[i]
    if (value > 1 || (value == 1 && neg_power)) {
	  if (neg_power)
	  	value <- value * -1
      result[i] <- paste0(name, "^", value)
    } else {
      result[i] <- name
    }
  }
  
  paste0(result, collapse = paste0(op, sep))
}

#' @export
as.character.symbolic_units <- function(x, ..., 
		neg_power = get(".units.negative_power", envir=.units_options), plot_sep = "") {
  num_str <- character(0)
  denom_str <- character(0)
  sep <- plot_sep

  if (length(x$numerator) == 0) {
    if (! neg_power)
	  num_str <- "1" # 1/cm^2/h
  } else {
    num_str <- .pretty_print_sequence(x$numerator, "*", FALSE, plot_sep)
  }
  
  if (length(x$denominator) > 0) {
    sep <- if (neg_power)
	    paste0("*", plot_sep)
	  else
        "/"
    denom_str <- .pretty_print_sequence(x$denominator, sep, neg_power, plot_sep)
  }

  if (length(num_str) == 0) {
    if (length(denom_str) == 0)
	  return("")
    else
	  return(denom_str)
  }

  if (length(denom_str) == 0)
    return(num_str)

  paste(num_str, denom_str, sep = sep)
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
  
  if (su1 == su2) return(1.)

  if (!udunits2::ud.are.convertible(su1, su2)) return(NA)
  udunits2::ud.convert(1, su1, su2)
}

.get_conversion_constant_sequence <- function(s1, s2) {
  conversion_constant <- 1
  remaining_s2 <- s2
  for (i in seq_along(s1)) {
    converted <- FALSE
    for (j in seq_along(remaining_s2)) {
      convert <- .get_unit_conversion_constant(s1[i], remaining_s2[j])
      if (!is.na(convert)) {
        conversion_constant <- conversion_constant * convert
        remaining_s2 <- remaining_s2[-j]
        converted <- TRUE
        break
      }
    }
    if (!converted) return(NA_real_)
  }
  # if we make it through these loops and there are still units left in s2
  # then there are some we couldn't convert return NA
  if (length(remaining_s2) > 0) {
      NA_real_
  } else 
    conversion_constant
}

.get_conversion_constant <- function(u1, u2) {
  # if the expressions are well formed, and can be converted, we can convert
  # numerator and denominator independently. If either cannot be converted
  # then the function call returns NA which will also be returned (since NA and /)
  # will convert to NA.

  const = NA_real_
  # FIXME:
  const = .get_conversion_constant_sequence(u1$numerator, u2$numerator) /
    .get_conversion_constant_sequence(u1$denominator, u2$denominator)
  if (is.na(const)) { # try brute force, through udunits2:
    str1 <- as.character(u1)
	  str2 <- as.character(u2)
  	if (udunits2::ud.are.convertible(str1, str2))
      const = udunits2::ud.convert(1, str1, str2)
  } 
  const
}

.simplify_units <- function(sym_units) {
  
  # This is just a brute force implementation that takes each element in the
  # numerator and tries to find a value in the denominator that can be converted
  # to the same unit. If so, we pull out the conversion constant, get rid of
  # both terms, and move on. At the end we return a units object with the
  # conversion constant and the new symbolic units type. Converting units can then
  # be done as this `x <- as.numeric(x) * .simplify_units(units(x))`.
  
  # Returning a units instead of a symbolic_units object is not idea, it means that
  # you cannot simply multiply or divide symbolic units together, you need to wrap
  # each pair-wise operator in units() but it is necessary when conversion constants
  # must be taken into account.
  
  conversion_constant <- 1
  new_numerator <- sym_units$numerator
  new_denominator <- sym_units$denominator
  
  delete_num <- c()
  for (i in seq_along(new_numerator)) {
    for (j in seq_along(new_denominator)) {
      conversion <- .get_unit_conversion_constant(new_numerator[i], new_denominator[j])
      if (!is.na(conversion)) {
        conversion_constant <- conversion_constant * conversion
        delete_num <- c(delete_num, i)
        new_denominator <- new_denominator[-j]
        break
      }
    }
  }
  if (length(delete_num) > 0)
    new_numerator <- new_numerator[-delete_num]
  
  as.units(conversion_constant, .symbolic_units(new_numerator, new_denominator))
}

