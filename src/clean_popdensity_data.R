# --- Get population density for countries/states --- #
#
# 

source("src/packages.R")

# Get countries and states
countries <- shapefile("clean-data/gadm-countries.shp")
states <- shapefile("clean-data/gadm-states.shp")

# location of population density data: https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip
# ^ may need an account to download this directly
#pop_data <- raster("../COVID/Pop_density/gpw_v4_population_density_rev11_2020_2pt5_min.tif")
pop_data <- velox("ext-data/gpw_v4_population_density_rev11_2020_15_min.tif")

c.popdensity <- pop_data$extract(countries, small = TRUE, fun=function(x)mean(x, na.rm = TRUE))
s.popdensity <- pop_data$extract(states, small = TRUE, fun=function(x)mean(x, na.rm = TRUE))

# add names
dimnames(c.popdensity) <- list(
  countries$NAME_0, "Pop_density")
dimnames(s.popdensity) <- list(
  states$GID_1, "Pop_density")

# remove spaces from the country names
rownames(c.popdensity) <- gsub(" ", "_", rownames(c.popdensity))

saveRDS(c.popdensity, "clean-data/population-density-countries.RDS")
saveRDS(s.popdensity, "clean-data/population-density-states.RDS")
