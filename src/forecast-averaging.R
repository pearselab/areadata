# test averaging across forecasting shapefiles

library(optparse)
library(raster)
library(sf)
library(tidyr)
library(rgdal)
library(parallel)

options(mc.cores = 4)

# Get countries and states
print("loading shapefiles...")
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

print("loading climate data...")
#first import all files in a single folder as a list 
rastlist <- list.files(path = "data/raw-forecasts/", pattern=".tif$", all.files=TRUE, full.names=FALSE)

paste("data/raw-forecasts/", rastlist, sep = "")

allrasters <- lapply(paste("data/raw-forecasts/", rastlist, sep = ""), stack)

# generate some informative (?) column names
namelist <- sub(".tif.*", "", sub(".*wc2.1_10m_bioc_", "", rastlist)) # weird double-sub to get the middle section

# now we have a list of rasterstacks
# the first layer in each stack is the forecasted mean annual temperature and that's what we'll work with
meantemp <- c()
for(i in seq_along(namelist)){
  meantemp <- c(meantemp, allrasters[[i]][[1]])
}


# functions
.avg.climate <- function(shapefile, x){
  # average the climate variable across each object in the shapefile
  return(raster::extract(x = x, y = shapefile, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE))
}

.avg.wrapper <- function(climate, region){
  # use parallelised code to run this for a list of temperature data
  return(do.call(cbind, mcMap(
    function(x) .avg.climate(shapefile=region, x),
    climate)))
}

.give.names <- function(output, rows, cols, rename=FALSE){
  # add names to the climate averaging output
  dimnames(output) <- list(rows, cols)
  if(rename)
    rownames(output) <- gsub(" ", "_", rownames(output))
  return(output)
}


c.temp <- .avg.wrapper(meantemp, countries)
c.temp <- .give.names(c.temp, countries$NAME_0, namelist, TRUE)

saveRDS(c.temp, "output/annual-mean-temperature-forecast-countries.RDS")

## side note, RDS files are smaller than csvs, but maybe .csv would be better for usability?
