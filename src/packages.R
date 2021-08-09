silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("optparse", "raster", "sf", "exactextractr", "tidyr", "rgdal", "parallel",
              "ggplot2", "viridis"
)

ready <- sapply(packages, silent.require)