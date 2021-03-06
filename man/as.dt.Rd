% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/conversion.R
\name{as.dt}
\alias{as.dt}
\title{convert units object into difftime object}
\usage{
as.dt(x)
}
\arguments{
\item{x}{object of class \code{units}}
}
\description{
convert units object into difftime object
}
\details{
\link{as.difftime} is not a generic, hence this strange name.
}
\examples{

t1 = Sys.time() 
t2 = t1 + 3600 
d = t2 - t1
du <- as.units(d)
dt = as.dt(du)
class(dt)
dt
}

