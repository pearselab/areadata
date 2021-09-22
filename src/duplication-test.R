##################################
# GID2 data duplication test
# How often do identical climate estimates occur
# due to polygons sharing the same single cell value?
#
# Tom Smith 2021
##################################

# perhaps the simplest way of asking this is, do two places ALWAYS return the same climate value through time?

source("src/packages.R")
source("src/functions.R")

gid2.temperatures <- as.data.frame(readRDS("output/temp-dailymean-GID2-cleaned.RDS"))

temp.test <- nrow(gid2.temperatures[duplicated(gid2.temperatures),])

if(temp.test == 0){
  print("No data duplications found")
}else if(temp.test > 0){
  print("Duplications found! Investigate the data!")
}
