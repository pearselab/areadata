# averaging across forecasting shapefiles

source("src/packages.R")
source("src/functions.R")

option_list = list(
  make_option(c("-c", "--cores"), type="integer", default=1, 
              help="number of cores to use for parallelised code", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser)

# set number of cores
options(mc.cores = opt$cores)
print(paste("Cores =", opt$cores, sep = " "))

# Get countries and states
print("loading shapefiles...")
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

print("loading climate data...")
#first import all files in a single folder as a list 
rastlist <- list.files(path = "data/raw-forecasts/", pattern=".tif$", all.files=TRUE, full.names=FALSE)

paste("data/raw-forecasts/", rastlist, sep = "")

allrasters <- lapply(paste("data/raw-forecasts/", rastlist, sep = ""), stack)

# generate some informative (?) column names
namelist <- sub(".tif.*", "", sub(".*wc2.1_10m_bioc_", "", rastlist)) # weird double-sub to get the middle section

# now we have a list of rasterstacks
# the first layer in each stack is the forecasted mean annual temperature and that's what we'll work with
meantemp <- c()
for(i in seq_along(namelist)){
  meantemp <- c(meantemp, allrasters[[i]][[1]])
}


c.temp <- .avg.wrapper(meantemp, countries)
c.temp <- .give.names(c.temp, countries$NAME_0, namelist, TRUE)

s.temp <- .avg.wrapper(meantemp, states)
s.temp <- .give.names(s.temp, states$GID_1, namelist, TRUE)

saveRDS(c.temp, "output/annual-mean-temperature-forecast-countries.RDS")
saveRDS(s.temp, "output/annual-mean-temperature-forecast-states.RDS")

## side note, RDS files are smaller than csvs, but maybe .csv would be better for usability?
