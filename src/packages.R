silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("optparse", "raster", "sf", "tidyr", "rgdal", "parallel"
)

ready <- sapply(packages, silent.require)