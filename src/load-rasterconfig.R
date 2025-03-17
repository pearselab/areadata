#!/usr/bin/env Rscript
# Simply load the rasterconfig json file and retrieve the appropriate variables

library(optparse)

option_list = list(
  make_option(c("-p", "--path"), type="character", default="src/rasterconfig.json",
              help="the path of the raster config json", metavar="character"),
  make_option(c("-a", "--agglevels"), action="store_true", default=FALSE,
              help="Also retrieve agglevels and return", metavar="logical")
);

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

rconfig <- jsonlite::fromJSON(opt$path)
measures <- names(rconfig$rasterlookup)
agglevels <- rconfig$agglevels
outstr <- paste0(measures, collapse = ",")
if (opt$agglevels)
  outstr <- paste0(outstr, ";", paste0(agglevels, collapse = ","))
cat(outstr)
