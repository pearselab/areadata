#!/usr/bin/env Rscript

library(cli)

cli_h1("Checking integrity of output folder structure")

outdir <- "output"

output_folders <- list.dirs(outdir)
datefolders <- grep("\\d{4}_\\d{2}", output_folders, value=TRUE)

measures <- c("temp", "spechumid", "relhumid", "uv", "precip")
agglevels <- c("countries", "GID1", "GID2", "UK-NUTS", "UK-LTLA", "UK-STP")

dumptypes <- expand.grid(agglevel=agglevels, measure=measures)
expected_files <- paste0(dumptypes$measure, "-dailymean-", dumptypes$agglevel, "-cleaned.RDS")

num_expected <- length(expected_files)

outputdf <- data.frame(folder=datefolders, missing=0, extra=0)

for (folder in datefolders) {
  cli_h3("Evaluating {folder}")
  successful <- TRUE
  folder_contents <- list.files(folder)
  missingfiles <- setdiff(expected_files, folder_contents)
  extrafiles <- setdiff(folder_contents, expected_files)
  if (length(missingfiles) > 0) {
    cli_alert_danger(col_red("Missing {length(missingfiles)} file{?s}!"))
    cli_bullets(setNames(missingfiles, rep_len(">", length(missingfiles))))
    outputdf$missing[which(outputdf$folder == folder)] <- length(missingfiles)
    successful <- FALSE
  }

  if (length(extrafiles) > 0) {
    cli_alert_warning(col_yellow("Extra {length(extrafiles)} file{?s}!"))
    cli_bullets(setNames(extrafiles, rep_len(">", length(extrafiles))))
    outputdf$extra[which(outputdf$folder == folder)] <- length(extrafiles)
    successful <- FALSE
  }

  if (successful) {
    cli_alert_success(col_green("All files present, no extras."))
  }
}

cli_h1("Summary report")
reportdf <- subset(outputdf, (outputdf$missing+outputdf$extra) > 0)
if (nrow(reportdf > 0)) {
  if (sum(reportdf$missing) > 0) {
    cli_alert_danger(col_red("Crucial files missing!"))
  } else {
    cli_alert_warning(col_yellow("Extra files detected!"))
  }
  print(reportdf)
} else {
  cli_alert_success(col_green("All folders correct!"))
}
