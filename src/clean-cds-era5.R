#!/usr/bin/env Rscript
# --- Get average daily midday temperature/humidity/uv for countries/states --- #
#

library(optparse)
library(raster)
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
    make_option(c("-d", "--days"), type="character", default="all", 
                help="comma separated list of days", metavar="character"),
    make_option(c("-c", "--cores"), type="integer", default=1, 
                help="number of cores to use for parallelised code", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

# set number of cores
options(mc.cores = opt$cores)
print(paste("Cores =", opt$cores, sep = " "))

# pull the dates out into numeric strings
years <- as.numeric(strsplit(opt$years, ",")[[1]])
months <- as.numeric(strsplit(opt$months, ",")[[1]])

if(opt$days == "all"){
    days <- seq(1, 31, 1)
} else{
    days <- as.numeric(strsplit(opt$days, ",")[[1]])
}

all_dates <- expand_grid(years, months, days)
all_dates$date <- as.Date(paste(all_dates$years, all_dates$months, all_dates$days, sep = "/"), "%Y/%m/%d")

# Get countries and states
print("loading shapefiles...")
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

print("loading climate data...")
# Load climate data and subset into rasters for each day of the year
dates <- as.character(all_dates[!is.na(all_dates$date),]$date)
temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")
humid <- rgdal::readGDAL("data/cds-humid-dailymean.grib")
uv <- rgdal::readGDAL("data/cds-uv-dailymean.grib")
.drop.col <- function(i, sp.df){
    sp.df@data <- sp.df@data[,i,drop=FALSE]
    return(sp.df)
}
temp <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)
humid <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=humid)
uv <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=uv)

######################################
# Functions to run climate averaging #
######################################

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

################
# run the code #
################

print("averaging across regions...")
c.temp <- .avg.wrapper(temp, countries)
s.temp <- .avg.wrapper(temp, states)

c.humid <- .avg.wrapper(humid, countries)
s.humid <- .avg.wrapper(humid, states)

c.uv <- .avg.wrapper(uv, countries)
s.uv <- .avg.wrapper(uv, states)

# format and save
print("saving output files...")
saveRDS(
    .give.names(c.temp, countries$NAME_0, dates, TRUE),
    "output/temp-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.temp, states$GID_1, dates),
    "output/temp-dailymean-states-cleaned.RDS"
)
saveRDS(
    .give.names(c.humid, countries$NAME_0, dates, TRUE),
    "output/humid-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.humid, states$GID_1, dates),
    "output/humid-dailymean-states-cleaned.RDS"
)
saveRDS(
    .give.names(c.uv, countries$NAME_0, dates, TRUE),
    "output/uv-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.uv, states$GID_1, dates),
    "output/uv-dailymean-states-cleaned.RDS"
)
# Save a file with the date that these data have been updated to
# write.table(max(all_dates$date), "output/update-datestamp.txt") # this needs improvement
