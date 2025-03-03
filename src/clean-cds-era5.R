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
  opt <- list(years = "2020", months = "01", days = "all", climvars=NULL, cores = 4L, help = FALSE, folder = FALSE)
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
    make_option(c("-v", "--climvars"), type="character", default=NULL,
                help="comma separated list of desired climvars (defaults to all)", metavar="character"),
    make_option(c("-c", "--cores"), type="integer", default=1,
                help="number of cores to use for parallelised code", metavar="number"),
    make_option(c("-f", "--folder"), action="store_true", default=FALSE,
                help="whether to read from and store into a subfolder based upon the arguments provided", metavar="logical")
  );

  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser)
}

measures <- c("temp", "spechumid", "relhumid", "uv", "precip")

if (!is.null(opt$climvars)) {
  measures_tmp <- gsub(" ", "", strsplit(opt$climvars, ",")[[1]])

  # Only try allowed measures
  measures <- intersect(measures, measures_tmp)
}

# Let user know what parameters are being used.
cli_h2("Parameters")
cli_inform(c(
  ">" = "Years: {.val {opt$years}}",
  ">" = "Months: {.val {opt$months}}",
  ">" = "Days: {.val {opt$days}}",
  ">" = "Climvars: {.val {measures}}",
  ">" = "Cores: {.val {opt$cores}}",
  ">" = "Subfolder: {.val {opt$folder}}"))

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

datafolder <- "data/"
outputfolder <- "output/"
subfolder <- ""

if (opt$folder) {
  # Some slightly arcane method for forcing 2-digit months
  subfolder <- paste0(paste0(years, collapse = "-"), "_", paste0(sprintf("%02d", as.integer(months)), collapse = "-"), "/")
  cli_alert_info("Working from/to subfolder {.path {subfolder}}")
}
datafolder <- paste0(datafolder, subfolder)
outputfolder <- paste0(outputfolder, subfolder)
# Check if output folder exists, and make it if needed
if (!dir.exists(outputfolder)){
  cli_alert_info("Creating output folder at {.path {outputfolder}}")
  dir.create(outputfolder, showWarnings = FALSE)
}
# quit()

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

# Get dates for later naming
dates <- as.character(all_dates[!is.na(all_dates$date),]$date)

# set up to detect if reprojection has been done yet

UK_NUTS_reproj <- NULL
UK_LTLA_reproj <- NULL
UK_STP_reproj <- NULL

# Package up location data into list for easy transferal
# locdata <- list(countries=countries, states=states, counties=counties, UK_NUTS=UK_NUTS_reproj, UK_LTLA=UK_LTLA_reproj, UK_STP=UK_STP_reproj)

cli_h1("Average Across Regions")
# Measures is located at the top of the script
for (measure in measures) {
  tryCatch(
    error = function(cnd) {
      cli_warn(c("!"="Failed run on {.val {measure}}! Skipping...", "!"="{cnd}"))
    }, {
      cli_progress_message("Loading {measure}...")
      climvar <- terra::as.list(terra::rast(paste0(datafolder, "cds-", measure,"-dailymean.grib")))
      cli_alert_success(col_red("Loaded {measure}"))

      if (any(is.null(c(UK_NUTS_reproj, UK_LTLA_reproj, UK_STP_reproj)))) {
        # get the UK spatial data into the correct projection
        UK_NUTS_reproj <- st_transform(UK_NUTS, crs(climvar[[1]]))
        UK_LTLA_reproj <- st_transform(UK_LTLA, crs(climvar[[1]]))
        UK_STP_reproj <- st_transform(UK_STP, crs(climvar[[1]]))
      }

      cli_progress_message("Averaging {measure}...")
      c.climvar <- .avg.wrapper(climvar, countries)
      s.climvar <- .avg.wrapper(climvar, states)
      ct.climvar <- .avg.wrapper(climvar, counties)
      UK_NUTS.climvar <- .avg.wrapper(climvar, UK_NUTS_reproj)
      UK_LTLA.climvar <- .avg.wrapper(climvar, UK_LTLA_reproj)
      UK_STP.climvar <- .avg.wrapper(climvar, UK_STP_reproj)
      cli_alert_success(col_yellow("Averaged {measure}"))

      cli_progress_message("Saving {measure}...")
      saveRDS(
        .give.names(c.climvar, countries$NAME_0, dates, TRUE),
        paste0(outputfolder, measure, "-dailymean-countries-cleaned.RDS")
      )
      saveRDS(
        .give.names(s.climvar, states$GID_1, dates),
        paste0(outputfolder, measure, "-dailymean-GID1-cleaned.RDS")
      )
      saveRDS(
        .give.names(ct.climvar, counties$GID_2, dates),
        paste0(outputfolder, measure, "-dailymean-GID2-cleaned.RDS")
      )
      saveRDS(
        .give.names(UK_NUTS.climvar, UK_NUTS$nuts118nm, dates, TRUE),
        paste0(outputfolder, measure, "-dailymean-UK-NUTS-cleaned.RDS")
      )
      saveRDS(
        .give.names(UK_LTLA.climvar, UK_LTLA$lad19nm, dates, TRUE),
        paste0(outputfolder, measure, "-dailymean-UK-LTLA-cleaned.RDS")
      )
      saveRDS(
        .give.names(UK_STP.climvar, UK_STP$STP21NM, dates, TRUE),
        paste0(outputfolder, measure, "-dailymean-UK-STP-cleaned.RDS")
      )
      cli_alert_success(col_green("Saved {measure}"))
    }
  )
}

cli_progress_done()

cli_h1("Run Complete!")
cli_alert_info("Finished in {.val {round(lubridate::as.duration(lubridate::now()-starttime), 2)}}")

# Save a file with the date that these data have been updated to
# write.table(max(all_dates$date), "output/update-datestamp.txt") # this needs improvement
