# --- Get population density for countries/states --- #
#
# 

source("src/packages.R")

# Get countries and states
countries <- shapefile("data/gis/gadm-countries.shp")
states <- shapefile("data/gis/gadm-states.shp")
counties <- shapefile("data/gis/gadm-counties.shp")
UK_NUTS <- shapefile("data/gis/NUTS_Level_1_(January_2018)_Boundaries.shp")
UK_LTLA <- shapefile("data/gis/Local_Authority_Districts_(December_2019)_Boundaries_UK_BFC.shp")

# location of population density data: https://sedac.ciesin.columbia.edu/downloads/data/gpw-v4/gpw-v4-population-density-rev11/gpw-v4-population-density-rev11_2020_2pt5_min_tif.zip
# ^ may need an account to download this directly
pop_data <- raster("data/gpw_v4_population_density_rev11_2020_15_min.tif")

# get UK shapefiles into correct projection
UK_NUTS_reproj <- spTransform(UK_NUTS, crs(pop_data))
UK_LTLA_reproj <- spTransform(UK_LTLA, crs(pop_data))

# extract across regions
c.popdensity <- raster::extract(x = pop_data, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)
s.popdensity <- raster::extract(x = pop_data, y = countries, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)
ct.popdensity <- raster::extract(x = pop_data, y = counties, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)
UK_NUTS.popdensity <- raster::extract(x = pop_data, y = UK_NUTS_reproj, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)
UK_LTLA.popdensity <- raster::extract(x = pop_data, y = UK_LTLA_reproj, fun=function(x, na.rm = TRUE)median(x, na.rm = TRUE), small = TRUE)

# add names
dimnames(c.popdensity) <- list(
  countries$NAME_0, "Pop_density")
dimnames(s.popdensity) <- list(
  states$GID_1, "Pop_density")
dimnames(ct.popdensity) <- list(
  counties$GID_2, "Pop_density")
dimnames(UK_NUTS.popdensity) <- list(
  UK_NUTS$nuts118nm, "Pop_density")
dimnames(UK_LTLA.popdensity) <- list(
  UK_LTLA$lad19nm, "Pop_density")

# remove spaces from the country names
rownames(c.popdensity) <- gsub(" ", "_", rownames(c.popdensity))
rownames(UK_NUTS.popdensity) <- gsub(" ", "_", rownames(UK_NUTS.popdensity))
rownames(UK_LTLA.popdensity) <- gsub(" ", "_", rownames(UK_LTLA.popdensity))

saveRDS(c.popdensity, "output/population-density-countries.RDS")
saveRDS(s.popdensity, "output/population-density-GID1.RDS")
saveRDS(ct.popdensity, "output/population-density-GID2.RDS")
saveRDS(UK_NUTS.popdensity, "output/population-density-UK-NUTS.RDS")
saveRDS(UK_LTLA.popdensity, "output/population-density-UK-LTLA.RDS")