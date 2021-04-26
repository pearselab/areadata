#!/usr/bin/env Rscript
# --- Get average daily midday temperature/humidity/uv for countries/states --- #
#

library(optparse)
library(raster)
library(sf)
library(tidyr)
library(rgdal)

# command line arguments options

option_list = list(
    make_option(c("-y", "--years"), type="character", default=NULL, 
                help="comma separated list of years", metavar="character"),
    make_option(c("-m", "--months"), type="character", default=NULL, 
                help="comma separated list of months", metavar="character"),
    make_option(c("-d", "--days"), type="character", default="all", 
                help="comma separated list of days", metavar="character"),
    make_option(c("-o", "--out"), type="character", default="output", 
                help="output file name [default= %default]", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

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
# humid <- rgdal::readGDAL("raw-data/gis/cds-era5-humid-dailymean.grib")
# uv <- rgdal::readGDAL("raw-data/gis/cds-era5-uv-dailymean.grib")
.drop.col <- function(i, sp.df){
    sp.df@data <- sp.df@data[,i,drop=FALSE]
    return(sp.df)
}
temp <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)
# humid <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=humid)
# uv <- lapply(seq_along(days), function(i, sp.df) velox(raster::rotate(raster(.drop.col(i, sp.df)))), sp.df=uv)
#
# Functions to run climate averaging
.avg.wrapper <- function(shapefile, climate){
    # average the climate variable across each object in the shapefile
    return(raster::extract(x = climate, y = shapefile, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE))
}
.give.names <- function(output, rows, cols, rename=FALSE){
    dimnames(output) <- list(rows, cols)
    if(rename)
        rownames(output) <- gsub(" ", "_", rownames(output))
    return(output)
}

# do work
print("averaging across regions...")
c.temp <- sapply(temp, function(x) .avg.wrapper(shapefile = countries, climate = x))
s.temp <- sapply(temp, function(x) .avg.wrapper(shapefile = states, climate = x))

# format
c.temp <- .give.names(c.temp, countries$NAME_0, dates, TRUE)
s.temp <- .give.names(s.temp, states$GID_1, dates)

print("merging with old data...")
# read older climate data
old.c.temp <- readRDS("output/temp-dailymean-countries-cleaned.RDS")
old.s.temp <- readRDS("output/temp-dailymean-states-cleaned.RDS")

# merge two climate matrices together
c.temp <- cbind(old.c.temp, c.temp[, !(colnames(c.temp) %in% colnames(old.c.temp))])
s.temp <- cbind(old.s.temp, s.temp[, !(colnames(s.temp) %in% colnames(old.s.temp))])

# format and save
print("saving output files...")
saveRDS(c.temp, paste("output/temp-dailymean-countries-", opt$out, ".RDS", sep = "")
)
saveRDS(s.temp, paste("output/temp-dailymean-states-", opt$out, ".RDS", sep = "")
)

# save a backup of the older data
enddate <- max(colnames(old.c.temp))
saveRDS(old.c.temp, paste("output/temp-dailymean-countries-", enddate, ".RDS", sep = ""))
saveRDS(old.s.temp, paste("output/temp-dailymean-states-", enddate, ".RDS", sep = ""))

# Save a file with the date that these data have been updated to
write.table(max(all_dates[!is.na(all_dates$date),]$date), "output/update-datestamp.txt")
