#!/usr/bin/env Rscript
# --- Get average daily midday temperature/humidity/uv for countries/states --- #
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
    make_option(c("-v", "--climvars"), type="character", default=NULL, 
                help="comma separated list of climate variables", metavar="character"),
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

# pull the climate variables out into a character string
climvars <- strsplit(opt$climvars, ",")[[1]]


###################################################################
# run the code, depending upon which climate variables are wanted #
###################################################################

# Get countries and states
print("loading shapefiles...")
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

dates <- as.character(all_dates[!is.na(all_dates$date),]$date)

# For future use - it would be better to write this into one function
# that takes the climate variable as an input, rather than copying it
# out three times!

# temperature
if("temperature" %in% climvars){
    print("loading temperature data...")
    # Load climate data and subset into rasters for each day of the year
    temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")
    temp <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)
    
    print("averaging temperature across regions...")
    c.temp <- .avg.wrapper(temp, countries)
    s.temp <- .avg.wrapper(temp, states)
    
    # format
    c.temp <- .give.names(c.temp, countries$NAME_0, dates, TRUE)
    s.temp <- .give.names(s.temp, states$GID_1, dates)
    
    print("merging with old temperature data...")
    # read older climate data
    old.c.temp <- readRDS("output/temp-dailymean-countries-cleaned.RDS")
    old.s.temp <- readRDS("output/temp-dailymean-states-cleaned.RDS")
    
    # merge two climate matrices together
    c.temp <- cbind(old.c.temp, c.temp[, !(colnames(c.temp) %in% colnames(old.c.temp))])
    s.temp <- cbind(old.s.temp, s.temp[, !(colnames(s.temp) %in% colnames(old.s.temp))])
    
    # format and save
    print("saving temperature output files...")
    saveRDS(c.temp, "output/temp-dailymean-countries-cleaned.RDS")
    saveRDS(s.temp, "output/temp-dailymean-states-cleaned.RDS")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.temp))
    saveRDS(old.c.temp, paste("output/temp-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.temp, paste("output/temp-dailymean-states-", enddate, ".RDS", sep = ""))
}

# humidity
if("humidity" %in% climvars){
    print("loading humidity data...")
    # Load climate data and subset into rasters for each day of the year
    humid <- rgdal::readGDAL("data/cds-humid-dailymean.grib")
    humid <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=humid)
    
    print("averaging humidity across regions...")
    c.humid <- .avg.wrapper(humid, countries)
    s.humid <- .avg.wrapper(humid, states)
    
    # format
    c.humid <- .give.names(c.humid, countries$NAME_0, dates, TRUE)
    s.humid <- .give.names(s.humid, states$GID_1, dates)
    
    print("merging with old humidity data...")
    # read older climate data
    old.c.humid <- readRDS("output/humid-dailymean-countries-cleaned.RDS")
    old.s.humid <- readRDS("output/humid-dailymean-states-cleaned.RDS")
    
    # merge two climate matrices together
    c.humid <- cbind(old.c.humid, c.humid[, !(colnames(c.humid) %in% colnames(old.c.humid))])
    s.humid <- cbind(old.s.humid, s.humid[, !(colnames(s.humid) %in% colnames(old.s.humid))])
    
    # format and save
    print("saving humidity output files...")
    saveRDS(c.humid, "output/humid-dailymean-countries-cleaned.RDS")
    saveRDS(s.humid, "output/humid-dailymean-states-cleaned.RDS")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.humid))
    saveRDS(old.c.humid, paste("output/humid-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.humid, paste("output/humid-dailymean-states-", enddate, ".RDS", sep = ""))
}


# UV
if("uv" %in% climvars){
    print("loading uv data...")
    # Load climate data and subset into rasters for each day of the year
    uv <- rgdal::readGDAL("data/cds-uv-dailymean.grib")
    uv <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=uv)
    
    print("averaging uv across regions...")
    c.uv <- .avg.wrapper(uv, countries)
    s.uv <- .avg.wrapper(uv, states)
    
    # format
    c.uv <- .give.names(c.uv, countries$NAME_0, dates, TRUE)
    s.uv <- .give.names(s.uv, states$GID_1, dates)
    
    print("merging with old uv data...")
    # read older climate data
    old.c.uv <- readRDS("output/uv-dailymean-countries-cleaned.RDS")
    old.s.uv <- readRDS("output/uv-dailymean-states-cleaned.RDS")
    
    # merge two climate matrices together
    c.uv <- cbind(old.c.uv, c.uv[, !(colnames(c.uv) %in% colnames(old.c.uv))])
    s.uv <- cbind(old.s.uv, s.uv[, !(colnames(s.uv) %in% colnames(old.s.uv))])
    
    # format and save
    print("saving uv output files...")
    saveRDS(c.uv, "output/uv-dailymean-countries-cleaned.RDS")
    saveRDS(s.uv, "output/uv-dailymean-states-cleaned.RDS")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.uv))
    saveRDS(old.c.uv, paste("output/uv-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.uv, paste("output/uv-dailymean-states-", enddate, ".RDS", sep = ""))
}


# precipitation
if("precipitation" %in% climvars){
    print("loading precipitation data...")
    # Load climate data and subset into rasters for each day of the year
    precip <- rgdal::readGDAL("data/cds-precip-dailymean.grib")
    precip <- lapply(seq_along(dates), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=precip)
    
    print("averaging precipitation across regions...")
    c.precip <- .avg.wrapper(precip, countries)
    s.precip <- .avg.wrapper(precip, states)
    
    # format
    c.precip <- .give.names(c.precip, countries$NAME_0, dates, TRUE)
    s.precip <- .give.names(s.precip, states$GID_1, dates)
    
    print("merging with old precipitation data...")
    # read older climate data
    old.c.precip <- readRDS("output/precip-dailymean-countries-cleaned.RDS")
    old.s.precip <- readRDS("output/precip-dailymean-states-cleaned.RDS")
    
    # merge two climate matrices together
    c.precip <- cbind(old.c.precip, c.precip[, !(colnames(c.precip) %in% colnames(old.c.precip))])
    s.precip <- cbind(old.s.precip, s.precip[, !(colnames(s.precip) %in% colnames(old.s.precip))])
    
    # format and save
    print("saving precipitation output files...")
    saveRDS(c.precip, "output/precip-dailymean-countries-cleaned.RDS")
    saveRDS(s.precip, "output/precip-dailymean-states-cleaned.RDS")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.precip))
    saveRDS(old.c.precip, paste("output/precip-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.precip, paste("output/precip-dailymean-states-", enddate, ".RDS", sep = ""))
}


# Save a file with the date that these data have been updated to
# write.table(max(all_dates[!is.na(all_dates$date),]$date), "output/update-datestamp.txt") # improve this...
