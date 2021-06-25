#!/usr/bin/env Rscript
# --- Get average daily mean temperature/humidity/uv/precipitation for countries/states --- #
#

source("src/packages.R")
source("src/functions.R")

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
UK_NUTS <- shapefile("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
UK_LTLA <- shapefile("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")

print("loading climate data...")
# Load climate data and subset into rasters for each day of the year
dates <- as.character(all_dates[!is.na(all_dates$date),]$date)
temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")
humid <- rgdal::readGDAL("data/cds-humid-dailymean.grib")
uv <- rgdal::readGDAL("data/cds-uv-dailymean.grib")
precip <- rgdal::readGDAL("data/cds-precip-dailymean.grib")

temp <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)
humid <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=humid)
uv <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=uv)
precip <- lapply(seq_along(days), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=precip)

# get the UK spatial data into the correct projection
UK_NUTS_reproj <- spTransform(UK_NUTS, crs(temp[[1]]))
UK_LTLA_reproj <- spTransform(UK_LTLA, crs(temp[[1]]))


################
# run the code #
################

print("averaging across regions...")
UK_NUTS.temp <- .avg.wrapper(temp, UK_NUTS_reproj)
UK_LTLA.temp <- .avg.wrapper(temp, UK_LTLA_reproj)

UK_NUTS.humid <- .avg.wrapper(humid, UK_NUTS_reproj)
UK_LTLA.humid <- .avg.wrapper(humid, UK_LTLA_reproj)

UK_NUTS.uv <- .avg.wrapper(uv, UK_NUTS_reproj)
UK_LTLA.uv <- .avg.wrapper(uv, UK_LTLA_reproj)

UK_NUTS.precip <- .avg.wrapper(precip, UK_NUTS_reproj)
UK_LTLA.precip <- .avg.wrapper(precip, UK_LTLA_reproj)

# format and save
print("saving output files...")
saveRDS(
    .give.names(UK_NUTS.temp, UK_NUTS$nuts118nm, dates, TRUE),
    "output/temp-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.temp, UK_LTLA$lad19nm, dates),
    "output/temp-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.humid, UK_NUTS$nuts118nm, dates, TRUE),
    "output/humid-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.humid, UK_LTLA$lad19nm, dates),
    "output/humid-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.uv, UK_NUTS$nuts118nm, dates, TRUE),
    "output/uv-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.uv, UK_LTLA$lad19nm, dates),
    "output/uv-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.precip, UK_NUTS$nuts118nm, dates, TRUE),
    "output/precip-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.precip, UK_LTLA$lad19nm, dates),
    "output/precip-dailymean-UK-LTLA-cleaned.RDS"
)
# Save a file with the date that these data have been updated to
# write.table(max(all_dates$date), "output/update-datestamp.txt") # this needs improvement
