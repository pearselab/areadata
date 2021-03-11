#!/usr/bin/env Rscript
# --- Get average daily midday temperature/humidity/uv for countries/states --- #
#

library(optparse)
library(raster)
library(velox)
library(sf)
library(tidyr)
library(rgdal)
library(parallel)

# command line arguments options

option_list = list(
    make_option(c("-y", "--years"), type="character", default=NULL, 
                help="comma separated list of years", metavar="character"),
    make_option(c("-m", "--months"), type="character", default=NULL, 
                help="comma separated list of months", metavar="character"),
    make_option(c("-d", "--days"), type="character", default=NULL, 
                help="comma separated list of days", metavar="character"),
    make_option(c("-o", "--out"), type="character", default="output", 
                help="output file name [default= %default]", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

# pull the dates out into numeric strings
years <- as.numeric(strsplit(opt$years, ",")[[1]])
months <- as.numeric(strsplit(opt$months, ",")[[1]])
days <- as.numeric(strsplit(opt$days, ",")[[1]])

all_dates <- expand_grid(years, months, days)
all_dates$date <- as.Date(paste(all_dates$years, all_dates$months, all_dates$days, sep = "/"))

# Get countries and states
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

# Load climate data and subset into rasters for each day of the year
dates <- as.character(all_dates$date)
temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")
# humid <- rgdal::readGDAL("raw-data/gis/cds-era5-humid-dailymean.grib")
# uv <- rgdal::readGDAL("raw-data/gis/cds-era5-uv-dailymean.grib")
.drop.col <- function(i, sp.df){
    sp.df@data <- sp.df@data[,i,drop=FALSE]
    return(sp.df)
}
temp <- lapply(seq_along(dates), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=temp)
# humid <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=humid)
# uv <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=uv)
#
# # Do work; format and save
.avg.wrapper <- function(climate, region)
    return(do.call(cbind, mcMap(
                              function(r) r$extract(region, small = TRUE, fun = function(x) median(x, na.rm = TRUE)),
                              climate)))
.give.names <- function(output, rows, cols, rename=FALSE){
    dimnames(output) <- list(rows, cols)
    if(rename)
        rownames(output) <- gsub(" ", "_", rownames(output))
    return(output)
}


saveRDS(
    .give.names(.avg.wrapper(temp, countries), countries$NAME_0, dates, TRUE),
    paste("output/temp-dailymean-countries-", opt$out, ".RDS", sep = "")
)
saveRDS(
    .give.names(.avg.wrapper(temp, states), states$GID_1, dates),
    paste("output/temp-dailymean-states-", opt$out, ".RDS", sep = "")
)

# Save a file with the date that these data have been updated to
write.table(max(all_dates$date), "output/update-datestamp.txt")

# saveRDS(
#     .give.names(.avg.wrapper(humid, countries), countries$NAME_0, days, TRUE),
#     "clean-data/humid-dailymean-countries.RDS"
# )
# saveRDS(
#     .give.names(.avg.wrapper(humid, states), states$GID_1, days),
#     "clean-data/humid-dailymean-states.RDS"
# )
# saveRDS(
#     .give.names(.avg.wrapper(uv, countries), countries$NAME_0, days, TRUE),
#     "clean-data/uv-dailymean-countries.RDS"
# )
# saveRDS(
#     .give.names(.avg.wrapper(uv, states), states$GID_1, days),
#     "clean-data/uv-dailymean-states.RDS"
# )
