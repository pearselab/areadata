#!/usr/bin/env Rscript
# --- Get average daily mean temperature/humidity/uv/precipitation for countries/states --- #
#
source("src/packages.R")
source("src/functions.R")

cli_h1("ERA5 Data Cleaner")
starttime <- lubridate::now()

cli_alert_success("Loaded packages and functions")

if (is_interactive()){
  # FW: Only really needed for debug analysis, but worth having a place for it
  # just in case we want to add more interactive stuff anon (e.g. an interactive CLI selection thing)
  cli_alert_info(col_green("Running interactively!"))
  opt <- list(years = "2020", months = "01", days = "all", cores = 4L, help = FALSE)
} else {
  cli_alert_info(col_green("Running in batch mode!"))
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
}

# Let user know what parameters are being used.
cli_h2("Parameters")
cli_inform(c(
  ">" = "Years: {.val {opt$years}}",
  ">" = "Months: {.val {opt$months}}",
  ">" = "Days: {.val {opt$days}}",
  ">" = "Cores: {.val {opt$cores}}"))

# set number of cores
options(mc.cores = opt$cores)

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
# print("loading shapefiles...")
# countries <- shapefile("data/gis/gadm-countries.shp")
# states <- shapefile("data/gis/gadm-states.shp")
# counties <- shapefile("data/gis/gadm-counties.shp")
# UK_NUTS <- shapefile("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
# UK_LTLA <- shapefile("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")
# UK_STP <- shapefile("data/gis/Sustainability_and_Transformation_Partnerships_(April_2021)_EN_BFC.shp")

# FW: Remake with no rgdal
# Get countries and states
cli_h1("Load Data")
cli_progress_message("Loading shapefiles...")
countries <- sf::read_sf("data/gis/gadm-countries.shp")
states <- sf::read_sf("data/gis/gadm-states.shp")
counties <- sf::read_sf("data/gis/gadm-counties.shp")
UK_NUTS <- sf::read_sf("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
UK_LTLA <- sf::read_sf("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")
UK_STP <- sf::read_sf("data/gis/Sustainability_and_Transformation_Partnerships_(April_2021)_EN_BFC.shp")
cli_alert_success("Loaded shapefiles")

cli_progress_message("Loading climate data...")
# Load climate data and subset into rasters for each day of the year
dates <- as.character(all_dates[!is.na(all_dates$date),]$date)
temp <- terra::as.list(terra::rast("data/cds-temp-dailymean.grib"))
spechumid <- terra::as.list(terra::rast("data/cds-spechumid-dailymean.grib"))
relhumid <- terra::as.list(terra::rast("data/cds-relhumid-dailymean.grib"))
uv <- terra::as.list(terra::rast("data/cds-uv-dailymean.grib"))
precip <- terra::as.list(terra::rast("data/cds-precip-dailymean.grib"))
cli_alert_success("Loaded climate data")

# get the UK spatial data into the correct projection
UK_NUTS_reproj <- st_transform(UK_NUTS, crs(temp[[1]]))
UK_LTLA_reproj <- st_transform(UK_LTLA, crs(temp[[1]]))
UK_STP_reproj <- st_transform(UK_STP, crs(temp[[1]]))

################
# run the code #
################

cli_h1("Average Across Regions")
cli_progress_message("Averaging temperature...")
c.temp <- .avg.wrapper(temp, countries)
s.temp <- .avg.wrapper(temp, states)
ct.temp <- .avg.wrapper(temp, counties)
UK_NUTS.temp <- .avg.wrapper(temp, UK_NUTS_reproj)
UK_LTLA.temp <- .avg.wrapper(temp, UK_LTLA_reproj)
UK_STP.temp <- .avg.wrapper(temp, UK_STP_reproj)
cli_alert_success(col_red("Averaged temperature"))

cli_progress_message("Averaging specific humidity...")
c.spechumid <- .avg.wrapper(spechumid, countries)
s.spechumid <- .avg.wrapper(spechumid, states)
ct.spechumid <- .avg.wrapper(spechumid, counties)
UK_NUTS.spechumid <- .avg.wrapper(spechumid, UK_NUTS_reproj)
UK_LTLA.spechumid <- .avg.wrapper(spechumid, UK_LTLA_reproj)
UK_STP.spechumid <- .avg.wrapper(spechumid, UK_STP_reproj)
cli_alert_success(col_cyan("Averaged specific humidity"))

cli_progress_message("Averaging relative humidity...")
c.relhumid <- .avg.wrapper(relhumid, countries)
s.relhumid <- .avg.wrapper(relhumid, states)
ct.relhumid <- .avg.wrapper(relhumid, counties)
UK_NUTS.relhumid <- .avg.wrapper(relhumid, UK_NUTS_reproj)
UK_LTLA.relhumid <- .avg.wrapper(relhumid, UK_LTLA_reproj)
UK_STP.relhumid <- .avg.wrapper(relhumid, UK_STP_reproj)
cli_alert_success(col_cyan("Averaged relative humidity"))

cli_progress_message("Averaging UV...")
c.uv <- .avg.wrapper(uv, countries)
s.uv <- .avg.wrapper(uv, states)
ct.uv <- .avg.wrapper(uv, counties)
UK_NUTS.uv <- .avg.wrapper(uv, UK_NUTS_reproj)
UK_LTLA.uv <- .avg.wrapper(uv, UK_LTLA_reproj)
UK_STP.uv <- .avg.wrapper(uv, UK_STP_reproj)
cli_alert_success(col_magenta("Averaged UV"))


cli_progress_message("Averaging precipitation...")
c.precip <- .avg.wrapper(precip, countries)
s.precip <- .avg.wrapper(precip, states)
ct.precip <- .avg.wrapper(precip, counties)
UK_NUTS.precip <- .avg.wrapper(precip, UK_NUTS_reproj)
UK_LTLA.precip <- .avg.wrapper(precip, UK_LTLA_reproj)
UK_STP.precip <- .avg.wrapper(precip, UK_STP_reproj)
cli_alert_success(col_blue("Averaged precipitation"))


# format and save
# print("saving output files...")
cli_h1("Save output files")
cli_progress_message("Saving output files...")
# Temperature
cli_progress_message("Saving temperature...")
saveRDS(
    .give.names(c.temp, countries$NAME_0, dates, TRUE),
    "output/temp-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.temp, states$GID_1, dates),
    "output/temp-dailymean-GID1-cleaned.RDS"
)
saveRDS(
    .give.names(ct.temp, counties$GID_2, dates),
    "output/temp-dailymean-GID2-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.temp, UK_NUTS$nuts118nm, dates, TRUE),
    "output/temp-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.temp, UK_LTLA$lad19nm, dates, TRUE),
    "output/temp-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_STP.temp, UK_STP$STP21NM, dates, TRUE),
    "output/temp-dailymean-UK-STP-cleaned.RDS"
)
cli_alert_success(col_red("Saved temperature"))

# Specific Humidity
cli_progress_message("Saving specific humidity...")
saveRDS(
    .give.names(c.spechumid, countries$NAME_0, dates, TRUE),
    "output/spechumid-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.spechumid, states$GID_1, dates),
    "output/spechumid-dailymean-GID1-cleaned.RDS"
)
saveRDS(
    .give.names(ct.spechumid, counties$GID_2, dates),
    "output/spechumid-dailymean-GID2-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.spechumid, UK_NUTS$nuts118nm, dates, TRUE),
    "output/spechumid-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.spechumid, UK_LTLA$lad19nm, dates, TRUE),
    "output/spechumid-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_STP.spechumid, UK_STP$STP21NM, dates, TRUE),
    "output/spechumid-dailymean-UK-STP-cleaned.RDS"
)
cli_alert_success(col_cyan("Saved specific humidity"))

# Relative humidity
cli_progress_message("Saving relative humidity...")
saveRDS(
    .give.names(c.relhumid, countries$NAME_0, dates, TRUE),
    "output/relhumid-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.relhumid, states$GID_1, dates),
    "output/relhumid-dailymean-GID1-cleaned.RDS"
)
saveRDS(
    .give.names(ct.relhumid, counties$GID_2, dates),
    "output/relhumid-dailymean-GID2-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.relhumid, UK_NUTS$nuts118nm, dates, TRUE),
    "output/relhumid-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.relhumid, UK_LTLA$lad19nm, dates, TRUE),
    "output/relhumid-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_STP.relhumid, UK_STP$STP21NM, dates, TRUE),
    "output/relhumid-dailymean-UK-STP-cleaned.RDS"
)
cli_alert_success(col_cyan("Saved relative humidity"))

# UV
cli_progress_message("Saving UV...")
saveRDS(
    .give.names(c.uv, countries$NAME_0, dates, TRUE),
    "output/uv-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.uv, states$GID_1, dates),
    "output/uv-dailymean-GID1-cleaned.RDS"
)
saveRDS(
    .give.names(ct.uv, counties$GID_2, dates),
    "output/uv-dailymean-GID2-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.uv, UK_NUTS$nuts118nm, dates, TRUE),
    "output/uv-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.uv, UK_LTLA$lad19nm, dates, TRUE),
    "output/uv-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_STP.uv, UK_STP$STP21NM, dates, TRUE),
    "output/uv-dailymean-UK-STP-cleaned.RDS"
)
cli_alert_success(col_magenta("Saved UV"))

# Precipitation
cli_progress_message("Saving precipitation...")
saveRDS(
    .give.names(c.precip, countries$NAME_0, dates, TRUE),
    "output/precip-dailymean-countries-cleaned.RDS"
)
saveRDS(
    .give.names(s.precip, states$GID_1, dates),
    "output/precip-dailymean-GID1-cleaned.RDS"
)
saveRDS(
    .give.names(ct.precip, counties$GID_2, dates),
    "output/precip-dailymean-GID2-cleaned.RDS"
)
saveRDS(
    .give.names(UK_NUTS.precip, UK_NUTS$nuts118nm, dates, TRUE),
    "output/precip-dailymean-UK-NUTS-cleaned.RDS"
)
saveRDS(
    .give.names(UK_LTLA.precip, UK_LTLA$lad19nm, dates, TRUE),
    "output/precip-dailymean-UK-LTLA-cleaned.RDS"
)
saveRDS(
    .give.names(UK_STP.precip, UK_STP$STP21NM, dates, TRUE),
    "output/precip-dailymean-UK-STP-cleaned.RDS"
)
cli_alert_success(col_blue("Averaged precipitation"))

cli_progress_done()

cli_h1("Run Complete!")
cli_alert_info("Finished in {.val {round(lubridate::as.duration(lubridate::now()-starttime), 2)}}")

# Save a file with the date that these data have been updated to
# write.table(max(all_dates$date), "output/update-datestamp.txt") # this needs improvement
