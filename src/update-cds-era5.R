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
countries <- sf::read_sf("data/gis/gadm-countries.shp")
states <- sf::read_sf("data/gis/gadm-states.shp")
counties <- sf::read_sf("data/gis/gadm-counties.shp")
UK_NUTS <- sf::read_sf("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
UK_LTLA <- sf::read_sf("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")
UK_STP <- sf::read_sf("data/gis/Sustainability_and_Transformation_Partnerships_(April_2021)_EN_BFC.shp")

dates <- as.character(all_dates[!is.na(all_dates$date),]$date)

# For future use - it would be better to write this into one function
# that takes the climate variable as an input, rather than copying it
# out three times!

# temperature
if("temperature" %in% climvars){
    print("loading temperature data...")
    # Load climate data and subset into rasters for each day of the year
    temp <- terra::as.list(terra::rast("data/cds-temp-dailymean.grib"))
    
    # get the UK spatial data into the correct projection
    UK_NUTS_reproj <- st_transform(UK_NUTS, crs(temp[[1]]))
    UK_LTLA_reproj <- st_transform(UK_LTLA, crs(temp[[1]]))
    UK_STP_reproj <- st_transform(UK_STP, crs(temp[[1]]))
    
    print("averaging temperature across regions...")
    c.temp <- .avg.wrapper(temp, countries)
    s.temp <- .avg.wrapper(temp, states)
    ct.temp <- .avg.wrapper(temp, counties)
    UK_NUTS.temp <- .avg.wrapper(temp, UK_NUTS_reproj)
    UK_LTLA.temp <- .avg.wrapper(temp, UK_LTLA_reproj)
    UK_STP.temp <- .avg.wrapper(temp, UK_STP_reproj)
    
    # format
    c.temp <- .give.names(c.temp, countries$NAME_0, dates, TRUE)
    s.temp <- .give.names(s.temp, states$GID_1, dates)
    ct.temp <- .give.names(ct.temp, counties$GID_2, dates)
    UK_NUTS.temp <- .give.names(UK_NUTS.temp, UK_NUTS$nuts118nm, dates, TRUE)
    UK_LTLA.temp <- .give.names(UK_LTLA.temp, UK_LTLA$lad19nm, dates, TRUE)
    UK_STP.temp <- .give.names(UK_STP.temp, UK_STP$STP21NM, dates, TRUE)
    
    print("merging with old temperature data...")
    # read older climate data
    old.c.temp <- readRDS("output/temp-dailymean-countries-cleaned.RDS")
    old.s.temp <- readRDS("output/temp-dailymean-GID1-cleaned.RDS")
    old.ct.temp <- readRDS("output/temp-dailymean-GID2-cleaned.RDS")
    old.UK_NUTS.temp <- readRDS("output/temp-dailymean-UK-NUTS-cleaned.RDS")
    old.UK_LTLA.temp <- readRDS("output/temp-dailymean-UK-LTLA-cleaned.RDS")
    old.UK_STP.temp <- readRDS("output/temp-dailymean-UK-STP-cleaned.RDS")
    
    # merge two climate matrices together
    c.temp <- cbind(old.c.temp, c.temp[, !(colnames(c.temp) %in% colnames(old.c.temp))])
    s.temp <- cbind(old.s.temp, s.temp[, !(colnames(s.temp) %in% colnames(old.s.temp))])
    ct.temp <- cbind(old.ct.temp, ct.temp[, !(colnames(ct.temp) %in% colnames(old.ct.temp))])
    UK_NUTS.temp <- cbind(old.UK_NUTS.temp, UK_NUTS.temp[, !(colnames(UK_NUTS.temp) %in% colnames(old.UK_NUTS.temp))])
    UK_LTLA.temp <- cbind(old.UK_LTLA.temp, UK_LTLA.temp[, !(colnames(UK_LTLA.temp) %in% colnames(old.UK_LTLA.temp))])
    UK_STP.temp <- cbind(old.UK_STP.temp, UK_STP.temp[, !(colnames(UK_STP.temp) %in% colnames(old.UK_STP.temp))])
    
    # format and save
    print("saving temperature output files...")
    saveRDS(c.temp, "output/temp-dailymean-countries-cleaned.RDS")
    saveRDS(s.temp, "output/temp-dailymean-GID1-cleaned.RDS")
    saveRDS(ct.temp, "output/temp-dailymean-GID2-cleaned.RDS")
    saveRDS(UK_NUTS.temp, "output/temp-dailymean-UK-NUTS-cleaned.RDS")
    saveRDS(UK_LTLA.temp, "output/temp-dailymean-UK-LTLA-cleaned.RDS")
    saveRDS(UK_STP.temp, "output/temp-dailymean-UK-STP-cleaned.RDS")
    # also save tab delimited versions
    write.table(c.temp, "output/temp-dailymean-countries-cleaned.txt")
    write.table(s.temp, "output/temp-dailymean-GID1-cleaned.txt")
    write.table(ct.temp, "output/temp-dailymean-GID2-cleaned.txt")
    write.table(UK_NUTS.temp, "output/temp-dailymean-UK-NUTS-cleaned.txt")
    write.table(UK_LTLA.temp, "output/temp-dailymean-UK-LTLA-cleaned.txt")
    write.table(UK_STP.temp, "output/temp-dailymean-UK-STP-cleaned.txt")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.temp))
    saveRDS(old.c.temp, paste("output/archive/temp-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.temp, paste("output/archive/temp-dailymean-GID1-", enddate, ".RDS", sep = ""))
    saveRDS(old.ct.temp, paste("output/archive/temp-dailymean-GID2-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_NUTS.temp, paste("output/archive/temp-dailymean-UK-NUTS-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_LTLA.temp, paste("output/archive/temp-dailymean-UK-LTLA-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_STP.temp, paste("output/archive/temp-dailymean-UK-STP-", enddate, ".RDS", sep = ""))
}

# specific humidity
if("spec_humid" %in% climvars){
    print("loading specific humidity data...")
    # Load climate data and subset into rasters for each day of the year
    spechumid <- terra::as.list(terra::rast("data/cds-spechumid-dailymean.grib"))
    
    # get the UK spatial data into the correct projection
    UK_NUTS_reproj <- st_transform(UK_NUTS, crs(spechumid[[1]]))
    UK_LTLA_reproj <- st_transform(UK_LTLA, crs(spechumid[[1]]))
    UK_STP_reproj <- st_transform(UK_STP, crs(spechumid[[1]]))
    
    print("averaging humidity across regions...")
    c.spechumid <- .avg.wrapper(spechumid, countries)
    s.spechumid <- .avg.wrapper(spechumid, states)
    ct.spechumid <- .avg.wrapper(spechumid, counties)
    UK_NUTS.spechumid <- .avg.wrapper(spechumid, UK_NUTS_reproj)
    UK_LTLA.spechumid <- .avg.wrapper(spechumid, UK_LTLA_reproj)
    UK_STP.spechumid <- .avg.wrapper(spechumid, UK_STP_reproj)
    
    # format
    c.spechumid <- .give.names(c.spechumid, countries$NAME_0, dates, TRUE)
    s.spechumid <- .give.names(s.spechumid, states$GID_1, dates)
    ct.spechumid <- .give.names(ct.spechumid, counties$GID_2, dates)
    UK_NUTS.spechumid <- .give.names(UK_NUTS.spechumid, UK_NUTS$nuts118nm, dates, TRUE)
    UK_LTLA.spechumid <- .give.names(UK_LTLA.spechumid, UK_LTLA$lad19nm, dates, TRUE)
    UK_STP.spechumid <- .give.names(UK_STP.spechumid, UK_STP$STP21NM, dates, TRUE)
    
    print("merging with old humidity data...")
    # read older climate data
    old.c.spechumid <- readRDS("output/spechumid-dailymean-countries-cleaned.RDS")
    old.s.spechumid <- readRDS("output/spechumid-dailymean-GID1-cleaned.RDS")
    old.ct.spechumid <- readRDS("output/spechumid-dailymean-GID2-cleaned.RDS")
    old.UK_NUTS.spechumid <- readRDS("output/spechumid-dailymean-UK-NUTS-cleaned.RDS")
    old.UK_LTLA.spechumid <- readRDS("output/spechumid-dailymean-UK-LTLA-cleaned.RDS")
    old.UK_STP.spechumid <- readRDS("output/spechumid-dailymean-UK-STP-cleaned.RDS")
    
    # merge two climate matrices together
    c.spechumid <- cbind(old.c.spechumid, c.spechumid[, !(colnames(c.spechumid) %in% colnames(old.c.spechumid))])
    s.spechumid <- cbind(old.s.spechumid, s.spechumid[, !(colnames(s.spechumid) %in% colnames(old.s.spechumid))])
    ct.spechumid <- cbind(old.ct.spechumid, ct.spechumid[, !(colnames(ct.spechumid) %in% colnames(old.ct.spechumid))])
    UK_NUTS.spechumid <- cbind(old.UK_NUTS.spechumid, UK_NUTS.spechumid[, !(colnames(UK_NUTS.spechumid) %in% colnames(old.UK_NUTS.spechumid))])
    UK_LTLA.spechumid <- cbind(old.UK_LTLA.spechumid, UK_LTLA.spechumid[, !(colnames(UK_LTLA.spechumid) %in% colnames(old.UK_LTLA.spechumid))])
    UK_STP.spechumid <- cbind(old.UK_STP.spechumid, UK_STP.spechumid[, !(colnames(UK_STP.spechumid) %in% colnames(old.UK_STP.spechumid))])
    
    # format and save
    print("saving humidity output files...")
    saveRDS(c.spechumid, "output/spechumid-dailymean-countries-cleaned.RDS")
    saveRDS(s.spechumid, "output/spechumid-dailymean-GID1-cleaned.RDS")
    saveRDS(ct.spechumid, "output/spechumid-dailymean-GID2-cleaned.RDS")
    saveRDS(UK_NUTS.spechumid, "output/spechumid-dailymean-UK-NUTS-cleaned.RDS")
    saveRDS(UK_LTLA.spechumid, "output/spechumid-dailymean-UK-LTLA-cleaned.RDS")
    saveRDS(UK_STP.spechumid, "output/spechumid-dailymean-UK-STP-cleaned.RDS")
    # also save tab delimited versions
    write.table(c.spechumid, "output/spechumid-dailymean-countries-cleaned.txt")
    write.table(s.spechumid, "output/spechumid-dailymean-GID1-cleaned.txt")
    write.table(ct.spechumid, "output/spechumid-dailymean-GID2-cleaned.txt")
    write.table(UK_NUTS.spechumid, "output/spechumid-dailymean-UK-NUTS-cleaned.txt")
    write.table(UK_LTLA.spechumid, "output/spechumid-dailymean-UK-LTLA-cleaned.txt")
    write.table(UK_STP.spechumid, "output/spechumid-dailymean-UK-STP-cleaned.txt")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.spechumid))
    saveRDS(old.c.spechumid, paste("output/archive/spechumid-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.spechumid, paste("output/archive/spechumid-dailymean-GID1-", enddate, ".RDS", sep = ""))
    saveRDS(old.ct.spechumid, paste("output/archive/spechumid-dailymean-GID2-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_NUTS.spechumid, paste("output/archive/spechumid-dailymean-UK-NUTS-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_LTLA.spechumid, paste("output/archive/spechumid-dailymean-UK-LTLA-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_STP.spechumid, paste("output/archive/spechumid-dailymean-UK-STP-", enddate, ".RDS", sep = ""))
}

# relative humidity
if("rel_humid" %in% climvars){
    print("loading humidity data...")
    # Load climate data and subset into rasters for each day of the year
    relhumid <- terra::as.list(terra::rast("data/cds-relhumid-dailymean.grib"))
    
    # get the UK spatial data into the correct projection
    UK_NUTS_reproj <- st_transform(UK_NUTS, crs(relhumid[[1]]))
    UK_LTLA_reproj <- st_transform(UK_LTLA, crs(relhumid[[1]]))
    UK_STP_reproj <- st_transform(UK_STP, crs(relhumid[[1]]))
    
    print("averaging humidity across regions...")
    c.relhumid <- .avg.wrapper(relhumid, countries)
    s.relhumid <- .avg.wrapper(relhumid, states)
    ct.relhumid <- .avg.wrapper(relhumid, counties)
    UK_NUTS.relhumid <- .avg.wrapper(relhumid, UK_NUTS_reproj)
    UK_LTLA.relhumid <- .avg.wrapper(relhumid, UK_LTLA_reproj)
    UK_STP.relhumid <- .avg.wrapper(relhumid, UK_STP_reproj)
    
    # format
    c.relhumid <- .give.names(c.relhumid, countries$NAME_0, dates, TRUE)
    s.relhumid <- .give.names(s.relhumid, states$GID_1, dates)
    ct.relhumid <- .give.names(ct.relhumid, counties$GID_2, dates)
    UK_NUTS.relhumid <- .give.names(UK_NUTS.relhumid, UK_NUTS$nuts118nm, dates, TRUE)
    UK_LTLA.relhumid <- .give.names(UK_LTLA.relhumid, UK_LTLA$lad19nm, dates, TRUE)
    UK_STP.relhumid <- .give.names(UK_STP.relhumid, UK_STP$STP21NM, dates, TRUE)
    
    print("merging with old humidity data...")
    # read older climate data
    old.c.relhumid <- readRDS("output/relhumid-dailymean-countries-cleaned.RDS")
    old.s.relhumid <- readRDS("output/relhumid-dailymean-GID1-cleaned.RDS")
    old.ct.relhumid <- readRDS("output/relhumid-dailymean-GID2-cleaned.RDS")
    old.UK_NUTS.relhumid <- readRDS("output/relhumid-dailymean-UK-NUTS-cleaned.RDS")
    old.UK_LTLA.relhumid <- readRDS("output/relhumid-dailymean-UK-LTLA-cleaned.RDS")
    old.UK_STP.relhumid <- readRDS("output/relhumid-dailymean-UK-STP-cleaned.RDS")
    
    # merge two climate matrices together
    c.relhumid <- cbind(old.c.relhumid, c.relhumid[, !(colnames(c.relhumid) %in% colnames(old.c.relhumid))])
    s.relhumid <- cbind(old.s.relhumid, s.relhumid[, !(colnames(s.relhumid) %in% colnames(old.s.relhumid))])
    ct.relhumid <- cbind(old.ct.relhumid, ct.relhumid[, !(colnames(ct.relhumid) %in% colnames(old.ct.relhumid))])
    UK_NUTS.relhumid <- cbind(old.UK_NUTS.relhumid, UK_NUTS.relhumid[, !(colnames(UK_NUTS.relhumid) %in% colnames(old.UK_NUTS.relhumid))])
    UK_LTLA.relhumid <- cbind(old.UK_LTLA.relhumid, UK_LTLA.relhumid[, !(colnames(UK_LTLA.relhumid) %in% colnames(old.UK_LTLA.relhumid))])
    UK_STP.relhumid <- cbind(old.UK_STP.relhumid, UK_STP.relhumid[, !(colnames(UK_STP.relhumid) %in% colnames(old.UK_STP.relhumid))])
    
    # format and save
    print("saving humidity output files...")
    saveRDS(c.relhumid, "output/relhumid-dailymean-countries-cleaned.RDS")
    saveRDS(s.relhumid, "output/relhumid-dailymean-GID1-cleaned.RDS")
    saveRDS(ct.relhumid, "output/relhumid-dailymean-GID2-cleaned.RDS")
    saveRDS(UK_NUTS.relhumid, "output/relhumid-dailymean-UK-NUTS-cleaned.RDS")
    saveRDS(UK_LTLA.relhumid, "output/relhumid-dailymean-UK-LTLA-cleaned.RDS")
    saveRDS(UK_STP.relhumid, "output/relhumid-dailymean-UK-STP-cleaned.RDS")
    # also save tab delimited versions
    write.table(c.relhumid, "output/relhumid-dailymean-countries-cleaned.txt")
    write.table(s.relhumid, "output/relhumid-dailymean-GID1-cleaned.txt")
    write.table(ct.relhumid, "output/relhumid-dailymean-GID2-cleaned.txt")
    write.table(UK_NUTS.relhumid, "output/relhumid-dailymean-UK-NUTS-cleaned.txt")
    write.table(UK_LTLA.relhumid, "output/relhumid-dailymean-UK-LTLA-cleaned.txt")
    write.table(UK_STP.relhumid, "output/relhumid-dailymean-UK-STP-cleaned.txt")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.relhumid))
    saveRDS(old.c.relhumid, paste("output/archive/relhumid-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.relhumid, paste("output/archive/relhumid-dailymean-GID1-", enddate, ".RDS", sep = ""))
    saveRDS(old.ct.relhumid, paste("output/archive/relhumid-dailymean-GID2-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_NUTS.relhumid, paste("output/archive/relhumid-dailymean-UK-NUTS-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_LTLA.relhumid, paste("output/archive/relhumid-dailymean-UK-LTLA-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_STP.relhumid, paste("output/archive/relhumid-dailymean-UK-STP-", enddate, ".RDS", sep = ""))
}


# UV
if("uv" %in% climvars){
    print("loading uv data...")
    # Load climate data and subset into rasters for each day of the year
    uv <- terra::as.list(terra::rast("data/cds-uv-dailymean.grib"))
    
    # get the UK spatial data into the correct projection
    UK_NUTS_reproj <- st_transform(UK_NUTS, crs(uv[[1]]))
    UK_LTLA_reproj <- st_transform(UK_LTLA, crs(uv[[1]]))
    UK_STP_reproj <- st_transform(UK_STP, crs(uv[[1]]))
    
    print("averaging uv across regions...")
    c.uv <- .avg.wrapper(uv, countries)
    s.uv <- .avg.wrapper(uv, states)
    ct.uv <- .avg.wrapper(uv, counties)
    UK_NUTS.uv <- .avg.wrapper(uv, UK_NUTS_reproj)
    UK_LTLA.uv <- .avg.wrapper(uv, UK_LTLA_reproj)
    UK_STP.uv <- .avg.wrapper(uv, UK_STP_reproj)
    
    # format
    c.uv <- .give.names(c.uv, countries$NAME_0, dates, TRUE)
    s.uv <- .give.names(s.uv, states$GID_1, dates)
    ct.uv <- .give.names(ct.uv, counties$GID_2, dates)
    UK_NUTS.uv <- .give.names(UK_NUTS.uv, UK_NUTS$nuts118nm, dates, TRUE)
    UK_LTLA.uv <- .give.names(UK_LTLA.uv, UK_LTLA$lad19nm, dates, TRUE)
    UK_STP.uv <- .give.names(UK_STP.uv, UK_STP$STP21NM, dates, TRUE)
    
    print("merging with old uv data...")
    # read older climate data
    old.c.uv <- readRDS("output/uv-dailymean-countries-cleaned.RDS")
    old.s.uv <- readRDS("output/uv-dailymean-GID1-cleaned.RDS")
    old.ct.uv <- readRDS("output/uv-dailymean-GID2-cleaned.RDS")
    old.UK_NUTS.uv <- readRDS("output/uv-dailymean-UK-NUTS-cleaned.RDS")
    old.UK_LTLA.uv <- readRDS("output/uv-dailymean-UK-LTLA-cleaned.RDS")
    old.UK_STP.uv <- readRDS("output/uv-dailymean-UK-STP-cleaned.RDS")
    
    # merge two climate matrices together
    c.uv <- cbind(old.c.uv, c.uv[, !(colnames(c.uv) %in% colnames(old.c.uv))])
    s.uv <- cbind(old.s.uv, s.uv[, !(colnames(s.uv) %in% colnames(old.s.uv))])
    ct.uv <- cbind(old.ct.uv, ct.uv[, !(colnames(ct.uv) %in% colnames(old.ct.uv))])
    UK_NUTS.uv <- cbind(old.UK_NUTS.uv, UK_NUTS.uv[, !(colnames(UK_NUTS.uv) %in% colnames(old.UK_NUTS.uv))])
    UK_LTLA.uv <- cbind(old.UK_LTLA.uv, UK_LTLA.uv[, !(colnames(UK_LTLA.uv) %in% colnames(old.UK_LTLA.uv))])
    UK_STP.uv <- cbind(old.UK_STP.uv, UK_STP.uv[, !(colnames(UK_STP.uv) %in% colnames(old.UK_STP.uv))])
    
    # format and save
    print("saving uv output files...")
    saveRDS(c.uv, "output/uv-dailymean-countries-cleaned.RDS")
    saveRDS(s.uv, "output/uv-dailymean-GID1-cleaned.RDS")
    saveRDS(ct.uv, "output/uv-dailymean-GID2-cleaned.RDS")
    saveRDS(UK_NUTS.uv, "output/uv-dailymean-UK-NUTS-cleaned.RDS")
    saveRDS(UK_LTLA.uv, "output/uv-dailymean-UK-LTLA-cleaned.RDS")
    saveRDS(UK_STP.uv, "output/uv-dailymean-UK-STP-cleaned.RDS")
    # also save tab delimited versions
    write.table(c.uv, "output/uv-dailymean-countries-cleaned.txt")
    write.table(s.uv, "output/uv-dailymean-GID1-cleaned.txt")
    write.table(ct.uv, "output/uv-dailymean-GID2-cleaned.txt")
    write.table(UK_NUTS.uv, "output/uv-dailymean-UK-NUTS-cleaned.txt")
    write.table(UK_LTLA.uv, "output/uv-dailymean-UK-LTLA-cleaned.txt")
    write.table(UK_STP.uv, "output/uv-dailymean-UK-STP-cleaned.txt")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.uv))
    saveRDS(old.c.uv, paste("output/archive/uv-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.uv, paste("output/archive/uv-dailymean-GID1-", enddate, ".RDS", sep = ""))
    saveRDS(old.ct.uv, paste("output/archive/uv-dailymean-GID2-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_NUTS.uv, paste("output/archive/uv-dailymean-UK-NUTS-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_LTLA.uv, paste("output/archive/uv-dailymean-UK-LTLA-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_STP.uv, paste("output/archive/uv-dailymean-UK-STP-", enddate, ".RDS", sep = ""))
}


# precipitation
if("precipitation" %in% climvars){
    print("loading precipitation data...")
    # Load climate data and subset into rasters for each day of the year
    precip <- terra::as.list(terra::rast("data/cds-precip-dailymean.grib"))
    
    # get the UK spatial data into the correct projection
    UK_NUTS_reproj <- st_transform(UK_NUTS, crs(precip[[1]]))
    UK_LTLA_reproj <- st_transform(UK_LTLA, crs(precip[[1]]))
    UK_STP_reproj <- st_transform(UK_STP, crs(precip[[1]]))
    
    print("averaging precipitation across regions...")
    c.precip <- .avg.wrapper(precip, countries)
    s.precip <- .avg.wrapper(precip, states)
    ct.precip <- .avg.wrapper(precip, counties)
    UK_NUTS.precip <- .avg.wrapper(precip, UK_NUTS_reproj)
    UK_LTLA.precip <- .avg.wrapper(precip, UK_LTLA_reproj)
    UK_STP.precip <- .avg.wrapper(precip, UK_STP_reproj)
    
    # format
    c.precip <- .give.names(c.precip, countries$NAME_0, dates, TRUE)
    s.precip <- .give.names(s.precip, states$GID_1, dates)
    ct.precip <- .give.names(ct.precip, counties$GID_2, dates)
    UK_NUTS.precip <- .give.names(UK_NUTS.precip, UK_NUTS$nuts118nm, dates, TRUE)
    UK_LTLA.precip <- .give.names(UK_LTLA.precip, UK_LTLA$lad19nm, dates, TRUE)
    UK_STP.precip <- .give.names(UK_STP.precip, UK_STP$STP21NM, dates, TRUE)
    
    print("merging with old precipitation data...")
    # read older climate data
    old.c.precip <- readRDS("output/precip-dailymean-countries-cleaned.RDS")
    old.s.precip <- readRDS("output/precip-dailymean-GID1-cleaned.RDS")
    old.ct.precip <- readRDS("output/precip-dailymean-GID2-cleaned.RDS")
    old.UK_NUTS.precip <- readRDS("output/precip-dailymean-UK-NUTS-cleaned.RDS")
    old.UK_LTLA.precip <- readRDS("output/precip-dailymean-UK-LTLA-cleaned.RDS")
    old.UK_STP.precip <- readRDS("output/precip-dailymean-UK-STP-cleaned.RDS")
    
    # merge two climate matrices together
    c.precip <- cbind(old.c.precip, c.precip[, !(colnames(c.precip) %in% colnames(old.c.precip))])
    s.precip <- cbind(old.s.precip, s.precip[, !(colnames(s.precip) %in% colnames(old.s.precip))])
    ct.precip <- cbind(old.ct.precip, ct.precip[, !(colnames(ct.precip) %in% colnames(old.ct.precip))])
    UK_NUTS.precip <- cbind(old.UK_NUTS.precip, UK_NUTS.precip[, !(colnames(UK_NUTS.precip) %in% colnames(old.UK_NUTS.precip))])
    UK_LTLA.precip <- cbind(old.UK_LTLA.precip, UK_LTLA.precip[, !(colnames(UK_LTLA.precip) %in% colnames(old.UK_LTLA.precip))])
    UK_STP.precip <- cbind(old.UK_STP.precip, UK_STP.precip[, !(colnames(UK_STP.precip) %in% colnames(old.UK_STP.precip))])
    
    # format and save
    print("saving precipitation output files...")
    saveRDS(c.precip, "output/precip-dailymean-countries-cleaned.RDS")
    saveRDS(s.precip, "output/precip-dailymean-GID1-cleaned.RDS")
    saveRDS(ct.precip, "output/precip-dailymean-GID2-cleaned.RDS")
    saveRDS(UK_NUTS.precip, "output/precip-dailymean-UK-NUTS-cleaned.RDS")
    saveRDS(UK_LTLA.precip, "output/precip-dailymean-UK-LTLA-cleaned.RDS")
    saveRDS(UK_STP.precip, "output/precip-dailymean-UK-STP-cleaned.RDS")
    # also save tab delimited versions
    write.table(c.precip, "output/precip-dailymean-countries-cleaned.txt")
    write.table(s.precip, "output/precip-dailymean-GID1-cleaned.txt")
    write.table(ct.precip, "output/precip-dailymean-GID2-cleaned.txt")
    write.table(UK_NUTS.precip, "output/precip-dailymean-UK-NUTS-cleaned.txt")
    write.table(UK_LTLA.precip, "output/precip-dailymean-UK-LTLA-cleaned.txt")
    write.table(UK_STP.precip, "output/precip-dailymean-UK-STP-cleaned.txt")
    
    # save a backup of the older data
    enddate <- max(colnames(old.c.precip))
    saveRDS(old.c.precip, paste("output/archive/precip-dailymean-countries-", enddate, ".RDS", sep = ""))
    saveRDS(old.s.precip, paste("output/archive/precip-dailymean-GID1-", enddate, ".RDS", sep = ""))
    saveRDS(old.ct.precip, paste("output/archive/precip-dailymean-GID2-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_NUTS.precip, paste("output/archive/precip-dailymean-UK-NUTS-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_LTLA.precip, paste("output/archive/precip-dailymean-UK-LTLA-", enddate, ".RDS", sep = ""))
    saveRDS(old.UK_STP.precip, paste("output/archive/precip-dailymean-UK-STP-", enddate, ".RDS", sep = ""))
}


# Save a file with the date that these data have been updated to
# cat(max(all_dates),file="output/update-datestamp.txt") # improve this...
