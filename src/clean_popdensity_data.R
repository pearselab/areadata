# --- Get population density for countries/states --- #
#
# 

source("src/packages.R")

# Get countries and states
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")

# location of population density data: https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip
# ^ may need an account to download this directly
pop_data <- raster("data/gpw_v4_population_density_rev11_2020_15_min.tif")

c.popdensity <- raster::extract(x = pop_data, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)
s.popdensity <- raster::extract(x = pop_data, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)

# add names
dimnames(c.popdensity) <- list(
  countries$NAME_0, "Pop_density")
dimnames(s.popdensity) <- list(
  states$GID_1, "Pop_density")

# remove spaces from the country names
rownames(c.popdensity) <- gsub(" ", "_", rownames(c.popdensity))

saveRDS(c.popdensity, "output/population-density-countries.RDS")
saveRDS(s.popdensity, "output/population-density-states.RDS")
