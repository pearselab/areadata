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
counties <- shapefile("data/gis/gadm-counties.shp")
UK_NUTS <- shapefile("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
UK_LTLA <- shapefile("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")


print("loading climate data...")
#first import all files in a single folder as a list 
rastlist <- list.files(path = "data/raw-forecasts/", pattern=".tif$", all.files=TRUE, full.names=FALSE)

paste("data/raw-forecasts/", rastlist, sep = "")

allrasters <- lapply(paste("data/raw-forecasts/", rastlist, sep = ""), stack)

# generate some informative (?) column names
namelist <- sub(".tif.*", "", sub(".*wc2.1_10m_bioc_", "", rastlist)) # weird double-sub to get the middle section

# get UK into correct projection
UK_NUTS_reproj <- spTransform(UK_NUTS, crs(allrasters[[1]][[1]]))
UK_LTLA_reproj <- spTransform(UK_LTLA, crs(allrasters[[1]][[1]]))

# now we have a list of rasterstacks
# the first layer in each stack is the forecasted mean annual temperature and that's what we'll work with
meantemp <- c()
for(i in seq_along(namelist)){
  meantemp <- c(meantemp, allrasters[[i]][[1]])
}


c.temp <- .avg.wrapper(meantemp, countries)
c.temp <- .give.names(c.temp, countries$NAME_0, namelist, TRUE)

s.temp <- .avg.wrapper(meantemp, states)
s.temp <- .give.names(s.temp, states$GID_1, namelist)

ct.temp <- .avg.wrapper(meantemp, counties)
ct.temp <- .give.names(ct.temp, counties$GID_2, namelist)

UK_NUTS.temp <- .avg.wrapper(meantemp, UK_NUTS_reproj)
UK_NUTS.temp <- .give.names(UK_NUTS.temp, UK_NUTS$nuts118nm, namelist, TRUE)

UK_LTLA.temp <- .avg.wrapper(meantemp, UK_LTLA_reproj)
UK_LTLA.temp <- .give.names(UK_LTLA.temp, UK_LTLA$lad19nm, namelist, TRUE)


saveRDS(c.temp, "output/annual-mean-temperature-forecast-countries.RDS")
saveRDS(s.temp, "output/annual-mean-temperature-forecast-GID1.RDS")
saveRDS(ct.temp, "output/annual-mean-temperature-forecast-GID2.RDS")
saveRDS(UK_NUTS.temp, "output/annual-mean-temperature-forecast-UK-NUTS.RDS")
saveRDS(UK_LTLA.temp, "output/annual-mean-temperature-forecast-UK-LTLA.RDS")


## side note, RDS files are smaller than csvs, but maybe .csv would be better for usability?
