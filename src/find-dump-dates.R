#!/usr/bin/env Rscript

# Author: Francis Windram
# Find the dates of the current areadata dump

# suppressMessages(library(rlang))
suppressMessages(library(lubridate))
suppressMessages(library(cli))

args <- commandArgs(trailingOnly = TRUE)

if (length(args) > 0) {
  sampledump <- args[1]
} else {
  sampledump <- "output/temp-dailymean-countries-cleaned.RDS"
}

# If file not present then try and find a file following the standard format within output
if (!file.exists(sampledump)) {
  # cli_alert_danger(col_red("Dump file {sampledump} does not exist!"))
  # cli_alert_warning(col_yellow("Checking alternatives within output/..."))
  rconfig <- jsonlite::fromJSON("src/rasterconfig.json")
  measures <- names(rconfig$rasterlookup)
  agglevels <- rconfig$agglevels

  dumptypes <- expand.grid(agglevel=agglevels, measure=measures)
  for (i in 1:nrow(dumptypes)) {
    dumpvars <- dumptypes[i,]
    sampledump <-paste0("output/", dumpvars$measure, "-dailymean-", dumpvars$agglevel, "-cleaned.RDS")
    # print(sampledump)
    if (file.exists(sampledump)) {
      # cli_alert_success(col_green("File {sampledump} exists!"))
      break
    } else {
      # cli_alert_danger(col_red("File {sampledump} does not exist!"))
    }
  }
}

# Read dump and get last date
df <- readRDS(sampledump)
dumpdates <- as.Date(colnames(df))
dumpend <- tail(dumpdates, 1)
# dumpend <- as.Date("2025-02-28")  # For testing only

# Roll current date backwards to the start of the previous month
targetmonth <- rollbackward(rollbackward(Sys.Date(), preserve_hms = FALSE), roll_to_first = TRUE)

# Roll dump end date forwards to first of the next month
newdumpstart <- rollforward(dumpend, preserve_hms = FALSE, roll_to_first = TRUE)

# Calculate target months
missingmonths <- time_length(as.period(interval(newdumpstart, targetmonth)), "months")
if (missingmonths < 0) {
  # If there's nothing to get, just return nothing
  cat("")
} else {
  toget <- newdumpstart + months(0:missingmonths)
  # Return target months
  cat(format(toget, "%Y-%m"), sep=",")
}

