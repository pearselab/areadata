silent.require <- function(x) suppressMessages(require(package=x, character.only=TRUE, quietly=TRUE))

# Load packages that are already installed
packages <- c("optparse", "terra", "sf", "exactextractr", "dplyr", "tidyr", "parallel",
              "ggplot2", "viridis", "lubridate", "cli", "rlang"
)

ready <- sapply(packages, silent.require)
