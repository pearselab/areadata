#!/usr/bin/env Rscript
# --- Concatenate runs of Monthly AREAData dumps into larger aggregated dumps --- #
#
# source("src/packages.R")
# source("src/functions.R")
library(rlang)
library(cli)
library(optparse)
library(lubridate)

cli_h1("ERA5 Data Concatenator")
starttime <- lubridate::now()

cli_alert_success("Loaded packages and functions")

if (is_interactive()){
  cli_alert_info(col_green("Running interactively!"))
  opt <- list(start = 1940L, end = 2019L, length = 10, path = "output/", help = FALSE, allowdiscontinuous = TRUE)
} else {
  cli_alert_info(col_green("Running in batch mode!"))
  # command line arguments
  option_list = list(
    make_option(c("-s", "--start"), type="integer", default=1940,
                help="the year from which to start the series of aggregated dumps (inclusive)"),
    make_option(c("-e", "--end"), type="integer", default=2024,
                help="the year to end the series of aggregated dumps (inclusive)"),
    make_option(c("-l", "--length"), type="double", default=10,
                help="the number of years per dump"),
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
  ">" = "End: {.val {opt$end}}",
  ">" = "Length: {.val {opt$length}}",
  ">" = "Path: {.val {opt$path}}",
  ">" = "Allow Discontinuous Dates?: {.val {opt$allowdiscontinuous}}"))

# Search provided folder to see what's there

cli_h1("Concatenating dumps")

folders <- list.dirs(opt$path)
datefolders <- grep("\\d{4}_\\d{2}", folders, value=TRUE)
datefolders <- apply(as.array(datefolders), 1, function(x) {strsplit(x, "/")[[1]][2]})
datefolders_date <- as.Date(paste0(datefolders, "_01"), tryFormats = c("%Y_%m_%d"))

folderdf <- data.frame(folder=datefolders, date=datefolders_date)

# Now we know what folders are there, we COULD construct a df of all the dumps and then form a strategy.
# For now though let's just work out the dumps that should exist
startdates <- as.Date(paste0(seq(opt$start, opt$end, by = opt$length), "/01/01"))
enddates <- rollbackward(startdates + years(opt$length))
final_intervals <- interval(startdates, enddates)

folderdf$intervalstart <- NA
folderdf$intervalend <- NA

# Find the starting date of the interval each date folder is within
for (i in 1:length(final_intervals)){
  matching_intervals <- which(folderdf$date %within% final_intervals[i])
  folderdf$intervalstart[matching_intervals] <- year(startdates[i])
  folderdf$intervalend[matching_intervals] <- year(enddates[i])
}

dump_intervals <- na.omit(dplyr::distinct(folderdf[,c("intervalstart", "intervalend")]))
cli_alert_success("Found {nrow(dump_intervals)} dump interval{?s} to process")

dump_concatenator <- function(startyear, endyear, dumps, metric, agglevel, outpath, allowdiscon = FALSE) {
  outname <- paste0(metric, "-dailymean-", agglevel, "-cleaned-", startyear,"-", endyear, ".RDS")

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

  # Could do compression here if we want to
  saveRDS(outdf, file=file.path(outpath, outname))
  # Return name just in case it's needed
  outname
}

# Load measures & agglevels
rconfig <- jsonlite::fromJSON("src/rasterconfig.json")
measures <- names(rconfig$rasterlookup)
agglevels <- rconfig$agglevels

dumptypes <- expand.grid(agglevel=agglevels, measure=measures)

# For each dump file
for (i in 1:nrow(dump_intervals)) {
  # Take a local copy of dumptypes
  dumptypes_tmp <- dumptypes
  dumptypes_tmp$filepath <- NA
  startyear <- dump_intervals[i, "intervalstart"]
  endyear <- dump_intervals[i, "intervalend"]
  cli_h2("Processing dumps for {.val {startyear}}-{.val {endyear}}")

  # Find the dumps to concatenate
  dump_subset <- subset(folderdf, folderdf$intervalstart == startyear)
  for (j in 1:nrow(dumptypes_tmp)) {
    # Try to concatenate each type of dump (measure/aggregation level)
    dumptype <- dumptypes_tmp[j,]
    filepath <- tryCatch(
      error = function(e) {
        # print(e)
        cli_alert_danger(col_red("{startyear}-{endyear}: {dumptype$measure}@{dumptype$agglevel} failed!"))
        "FAILED"
        }, {
          cli_progress_message("Processing {startyear}-{endyear}: {dumptype$measure}@{dumptype$agglevel}...")
          suppressWarnings(dump_concatenator(startyear, endyear, dump_subset, dumptype$measure, dumptype$agglevel, opt$path, opt$allowdiscontinuous))
          cli_alert_success(col_green("{startyear}-{endyear}: {dumptype$measure}@{dumptype$agglevel} succeeded!"))
          }
    )
    # DEBUG: Just in case you want the paths later
    dumptypes_tmp$filepath[j] <- filepath
  }

  cli_progress_done()

  # Check overall success for this decade
  succeeded <- subset(dumptypes_tmp, dumptypes_tmp$filepath != "FAILED")
  if (nrow(succeeded) == nrow(dumptypes_tmp)) {
    cli_alert_success(col_green("Completed all dumps for {.val {startyear}}-{.val {endyear}}. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
  } else if (nrow(succeeded) == 0) {
    cli_alert_danger(col_red("Failed all dumps for {.val {startyear}}-{.val {endyear}}. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
  } else {
    cli_alert_warning(col_yellow("Completed some dumps for {.val {startyear}}-{.val {endyear}}. {nrow(succeeded)}/{nrow(dumptypes_tmp)} succeeded."))
  }
}

