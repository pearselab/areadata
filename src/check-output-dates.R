# Quick R script to check for missing dates in the data - did we fuck up anywhere while updating?

# read in the data

c.temp <- readRDS("output/temp-dailymean-countries-cleaned.RDS")
c.relhumid <- readRDS("output/relhumid-dailymean-countries-cleaned.RDS")
c.spechumid <- readRDS("output/spechumid-dailymean-countries-cleaned.RDS")
c.precip <- readRDS("output/precip-dailymean-countries-cleaned.RDS")
c.uv <- readRDS("output/uv-dailymean-countries-cleaned.RDS")

# check 1, do the different files have the same lengths of dates?

ll <- list(dimnames(c.temp)[[2]], dimnames(c.relhumid)[[2]], dimnames(c.spechumid)[[2]],
           dimnames(c.precip)[[2]], dimnames(c.uv)[[2]])

if(all(sapply(ll,length) == length(ll[[1]])) == TRUE){
  cat("TRUE")
} else{
  cat("Check 1 FALIED: objects have different date lengths - INVESTIGATE")
}

# check 2, do the lengths of dates match the expected lengths of a sequence of dates

first_date <- dimnames(c.temp)[[2]][[1]]
last_date <- dimnames(c.temp)[[2]][[length(dimnames(c.temp)[[2]])]]

dateseq <- seq(as.Date(first_date), as.Date(last_date), by = "day")

if(length(dimnames(c.temp)[[2]]) == length(dateseq)){
  cat("TRUE")
} else{
  cat("Check 2 FALIED: objects have different lengths than expected - INVESTIGATE")
}