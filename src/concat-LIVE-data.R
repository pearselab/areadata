#!/usr/bin/env Rscript

# Author: Francis Windram
# Concatenate runs of Monthly AREAData dumps along with the LIVE data to fully update to the present day

library(rlang)
library(cli)
library(optparse)
library(lubridate)

cli_h1("ERA5 Data Concatenator")
starttime <- lubridate::now()

cli_alert_success("Loaded packages and functions")

if (is_interactive()){
  cli_alert_info(col_green("Running interactively!"))
  opt <- list(start = "2020-01", path = "output/", help = FALSE, allowdiscontinuous = TRUE)
} else {
  cli_alert_info(col_green("Running in batch mode!"))
  # command line arguments
  option_list = list(
    make_option(c("-s", "--start"), type="character", default=1940,
                help="the date from which to start the series of aggregated dumps (inclusive)"),
    make_option(c("-p", "--path"), type="character", default="output/",
                help="the path of the output dump folders"),
    make_option(c("-d", "--allowdiscontinuous"), action="store_true", default=FALSE,
                help="allow dump creation even if discontinuous dates are detected", metavar="logical")
  );

  opt_parser = OptionParser(option_list=option_list);
  opt = parse_args(opt_parser)
}
# Strip trailing slash from path var
opt$path <- gsub("/$", "",opt$path)

# Let user know what parameters are being used.
cli_h2("Parameters")
cli_inform(c(
  ">" = "Start: {.val {opt$start}}",
  ">" = "Path: {.val {opt$path}}",
  ">" = "Allow Discontinuous Dates?: {.val {opt$allowdiscontinuous}}"))

# Search provided folder to see what's there

cli_h1("Concatenating dumps")

folders <- list.dirs(opt$path)
datefolders <- grep("\\d{4}_\\d{2}", folders, value=TRUE)
datefolders <- apply(as.array(datefolders), 1, function(x) {strsplit(x, "/")[[1]][2]})
datefolders_date <- as.Date(paste0(datefolders, "_01"), tryFormats = c("%Y_%m_%d"))

folderdf <- data.frame(folder=datefolders, date=datefolders_date)

# This time take a subset of the folders that are after the start date
folderdf <- subset(folderdf, folderdf$date >= as.Date(paste0(opt$start, "-01")))

dump_concatenator <- function(dumps, metric, agglevel, outpath, allowdiscon = FALSE) {
  outname <- paste0(metric, "-dailymean-", agglevel, "-cleaned.RDS")
  # outname <- paste0(metric, "-dailymean-", agglevel, "-cleaned-2.RDS")  # TODO: Temporary for testing

  # Inject LIVE dump into top of dumps
  dumps <- rbind(data.frame(folder=".", date=NA), dumps)
  # Read all dumps into a list and bind together
  outlist <- apply(as.array(dumps$folder), 1, function(x) {readRDS(file.path(outpath, x, paste0(metric, "-dailymean-", agglevel, "-cleaned.RDS")))})
  outdf <- dplyr::bind_cols(outlist)

  # Convert back to matrix and re-add rownames
  outdf <- as.matrix(outdf)

  final_rownames <- rownames(outlist[[1]])
  rownames(outdf) <- final_rownames

  # If names are discontinuous, we may have a problem in dump integrity
  namevec <- as.Date(colnames(outdf))
  if (!(all(as.integer(namevec[2:length(namevec)] - namevec[1:length(namevec)-1]) == 1))) {
    cli_alert_warning(col_yellow("{outname} has discontinuous dates!"))
    if (!allowdiscon) {
      cli_abort("x" = col_red("{outname} has discontinuous dates!"))
    }
  }

  if (length(namevec) > 3652) {  # 3652 is the maximum number of days in a decade
    cli_alert_warning(col_yellow("{outname} contains more than 10 years of data! {.val {namevec[1]}} - {.val {tail(namevec, 1)}}"))
  }

  # Could do compression here if we want to
  saveRDS(outdf, file=file.path(outpath, outname))
  # Return name just in case it's needed
  outname
}

measures <- c("temp", "spechumid", "relhumid", "uv", "precip")
agglevels <- c("countries", "GID1", "GID2", "UK-NUTS", "UK-LTLA", "UK-STP")

dumptypes <- expand.grid(agglevel=agglevels, measure=measures)

# Take a local copy of dumptypes
dumptypes_tmp <- dumptypes
dumptypes_tmp$filepath <- NA
cli_h2("Processing dumps from {.var {opt$start}} to present.")

# Find the dumps to concatenate
for (j in 1:nrow(dumptypes_tmp)) {
  # Try to concatenate each type of dump (measure/aggregation level)
  dumptype <- dumptypes_tmp[j,]
  filepath <- tryCatch(
    error = function(e) {
      # print(e)
      cli_alert_danger(col_red("{dumptype$measure}@{dumptype$agglevel} failed!"))
      "FAILED"
    }, {
      cli_progress_message("Processing {dumptype$measure}@{dumptype$agglevel}...")
      suppressWarnings(dump_concatenator(folderdf, dumptype$measure, dumptype$agglevel, opt$path, opt$allowdiscontinuous))
      cli_alert_success(col_green("{dumptype$measure}@{dumptype$agglevel} succeeded!"))
    }
  )
  # DEBUG: Just in case you want the paths later
  dumptypes_tmp$filepath[j] <- filepath
}

cli_progress_done()

# Check overall success for this decade
succeeded <- subset(dumptypes_tmp, dumptypes_tmp$filepath != "FAILED")
if (nrow(succeeded) == nrow(dumptypes_tmp)) {
  cli_alert_success(col_green("Completed all dumps. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
} else if (nrow(succeeded) == 0) {
  cli_alert_danger(col_red("Failed all dumps. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
} else {
  cli_alert_warning(col_yellow("Completed some dumps. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
}


