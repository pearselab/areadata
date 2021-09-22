silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("optparse", "raster", "sf", "exactextractr", "dplyr", "tidyr", "rgdal", "parallel",
              "ggplot2", "viridis", "lubridate"
)

ready <- sapply(packages, silent.require)