##############################
# validation-figures.R
# 
# Reproduce the figures in the manuscript
# Run this line by line and follow instructions...
#
# Tom Smith 2021
##############################

source("src/packages.R")
source("src/functions.R")



## -------------- FIGURE 1 -------------- ##

# Figure 1 shows the temperature raster, then overlaid with a shapefile,
# and finally the extracted temperature averages

# In order to reproduce this, you need a temperature raster in /data/ called "cds-temp-dailymean.grib"
# acquire this by using the cds-era5-args.py script for Jan 2020 and Temperature
# then run the cdo daymean command on that hourly data: cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib

countries_shp <- shapefile("data/gis/gadm-countries.shp")
area_thresh <- units::set_units(10, km^2)

temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")
temp <- lapply(seq(1, 31, 1), function(i, sp.df) raster::rotate(raster(.drop.col(i, sp.df))), sp.df=temp)

pdf("output/fig_1_a.pdf", width = 9, height = 5)
plot(temp[[1]], col = viridis(200), axes= FALSE, box = FALSE)
dev.off()

pdf("output/fig_1_b.pdf", width = 9, height = 5)
plot(temp[[1]], col = viridis(200), axes= FALSE, box = FALSE)
plot(countries_shp, add = TRUE)
dev.off()

# get the countries again as an st object for plotting with average temperature
countries <- st_read("data/gis/gadm-countries.shp")
c.temp <- readRDS("output/temp-dailymean-countries-cleaned.RDS")

countries$temperature <- c.temp[,1]

c.plot <- ggplot(countries) +
  geom_sf(aes(fill = temperature)) +
  scale_fill_viridis(limits = c(-45, 41)) +
  theme_bw() +
  theme(panel.grid = element_blank(),
        panel.border = element_blank(),
        legend.position = "none")
c.plot

pdf("output/fig_1_c.pdf", width = 9, height = 5)
c.plot
dev.off()


## -------------- FIGURE 2 -------------- ##

c.temp <- as.data.frame(readRDS("output/temp-dailymean-countries-cleaned.RDS"))
s.temp <- as.data.frame(readRDS("output/temp-dailymean-GID1-cleaned.RDS"))
co.temp <- as.data.frame(readRDS("output/temp-dailymean-GID2-cleaned.RDS"))

c.temp$country <- row.names(c.temp)
s.temp$state <- row.names(s.temp)
co.temp$county <- row.names(co.temp)

metadata <- read.csv("data/name-matching.csv")

# take USA as an example

# get only USA counties/states/countries
county_df <- co.temp[with(co.temp, grepl("USA", county)),]
county_df_long <- pivot_longer(county_df,
                               cols = c(1:(ncol(county_df)-1)),
                               names_to = "date",
                               values_to = "temperature")

state_df <- s.temp[with(s.temp, grepl("USA", state)),]

state_df_long <- pivot_longer(state_df,
                              cols = c(1:(ncol(state_df)-1)),
                              names_to = "date",
                              values_to = "temperature")

# and the country data
country_df <- c.temp[c.temp$country == "United_States",]

country_df_long <- pivot_longer(country_df,
                                cols = c(1:(ncol(country_df)-1)),
                                names_to = "date",
                                values_to = "temperature")

# do some cunning merging with the metadata to more easily see what we're looking at

county_df_long <- merge(county_df_long, metadata, by.x = "county", by.y = "GID_2", all.x = TRUE)
state_df_long <- merge(state_df_long, distinct(metadata[,c("GID_0", "NAME_0", "GID_1", "NAME_1")]), 
                       by.x = "state", by.y = "GID_1", all.x = TRUE)


NY_counties <- ggplot() +
  geom_line(data = county_df_long[county_df_long$NAME_1 == "New York",], aes(x = as.Date(date), y = temperature, group = county, col = "lightgrey")) +
  geom_line(data = state_df_long[state_df_long$NAME_1 == "New York",], aes(x = as.Date(date), y = temperature, group = state, col = "blue")) +
  # geom_line(data = country_df_long, aes(x = as.Date(date), y = temperature), col = "red") +
  labs(y = "Temperature (°C)") +
  scale_colour_manual(values = c("lightgrey" = "lightgrey", "blue" = "blue"), labels = c("NY State", "NY Counties")) +
  theme_bw() +
  theme(axis.title.y = element_text(size = 20),
        axis.title.x = element_blank(),
        axis.text = element_text(size = 14),
        legend.position = c(0.4, 0.2),
        legend.title = element_blank(),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 28, hjust = 0.5))


US_states <- ggplot() +
  geom_line(data = state_df_long, aes(x = as.Date(date), y = temperature, group = state, col = "lightgrey")) +
  # geom_line(data = state_df_long[state_df_long$NAME_1 == "New York",], aes(x = as.Date(date), y = temperature, group = state), col = "blue") +
  geom_line(data = country_df_long, aes(x = as.Date(date), y = temperature, col = "red")) +
  labs(y = "Temperature (°C)") +
  scale_colour_manual(values = c("lightgrey" = "lightgrey", "red" = "red"), labels = c("USA States", "USA Average")) +
  theme_bw() +
  theme(axis.title.y = element_text(size = 20),
        axis.title.x = element_blank(),
        axis.text = element_text(size = 14),
        legend.position = c(0.4, 0.2),
        legend.title = element_blank(),
        legend.text = element_text(size = 18),
        plot.title = element_text(size = 28, hjust = 0.5))


svg("output/fig_2_a.svg", width = 9, height = 3)
NY_counties
dev.off()

svg("output/fig_2_b.svg", width = 9, height = 3)
US_states
dev.off()


## -------------- FIGURE 3 -------------- ##

# quantify the number of ERA5 observations within spatial units files

countries_shp <- shapefile("data/gis/gadm-countries.shp")
gid1_shp <- shapefile("data/gis/gadm-states.shp")
gid2_shp <- shapefile("data/gis/gadm-counties.shp")

# need the downloaded daily climate raster again
# see figure 1 text for how to acquire this
temp <- rgdal::readGDAL("data/cds-temp-dailymean.grib")

temp <- temp[1]
temp@data <- temp@data[,1,drop=FALSE]
temp_rotate <- raster::rotate(raster(temp))

# count is the sum of fractions of cells covered, variety is number of distinct cells (i,e, containing different values)
c.temp <- exact_extract(temp_rotate, countries_shp, c("count", "variety")) 
s.temp <- exact_extract(temp_rotate, gid1_shp, c("count", "variety")) 
ct.temp <- exact_extract(temp_rotate, gid2_shp, c("count", "variety")) 

# create some bins for a sensible plot
c.temp$bin <- NA
c.temp[c.temp$variety == 1,]$bin <- "1"
c.temp[c.temp$variety > 1 & c.temp$variety <= 9,]$bin <- "2-9"
c.temp[c.temp$variety >= 10 & c.temp$variety <= 99,]$bin <- "10-99"
c.temp[c.temp$variety >= 100 & c.temp$variety <= 999,]$bin <- "100-999"
c.temp[c.temp$variety >= 1000,]$bin <- "1000+"

s.temp$bin <- NA
s.temp[s.temp$variety == 1,]$bin <- "1"
s.temp[s.temp$variety > 1 & s.temp$variety <= 9,]$bin <- "2-9"
s.temp[s.temp$variety >= 10 & s.temp$variety <= 99,]$bin <- "10-99"
s.temp[s.temp$variety >= 100 & s.temp$variety <= 999,]$bin <- "100-999"
s.temp[s.temp$variety >= 1000,]$bin <- "1000+"

ct.temp$bin <- NA
ct.temp[ct.temp$variety == 1,]$bin <- "1"
ct.temp[ct.temp$variety > 1 & ct.temp$variety <= 9,]$bin <- "2-9"
ct.temp[ct.temp$variety >= 10 & ct.temp$variety <= 99,]$bin <- "10-99"
ct.temp[ct.temp$variety >= 100 & ct.temp$variety <= 999,]$bin <- "100-999"
ct.temp[ct.temp$variety >= 1000,]$bin <- "1000+"

binlist <- c("1", "2-9", "10-99", "100-999", "1000+")

granularity_1 <- ggplot(c.temp, aes(x = bin)) + geom_bar() + scale_x_discrete(limits = binlist) + 
  theme_bw() +
  theme(axis.text = element_text(size = 16),
        axis.title = element_blank(),
        aspect.ratio = 1)
granularity_2 <- ggplot(s.temp, aes(x = bin)) + geom_bar() + scale_x_discrete(limits = binlist)+ 
  theme_bw() +
  theme(axis.text = element_text(size = 16),
        axis.title = element_blank(),
        aspect.ratio = 1)
granularity_3 <- ggplot(ct.temp, aes(x = bin)) + geom_bar() + scale_x_discrete(limits = binlist)+ 
  theme_bw() +
  theme(axis.text = element_text(size = 16),
        axis.title = element_blank(),
        aspect.ratio = 1)

svg("output/fig_3_a.svg")
granularity_1
dev.off()
svg("output/fig_3_b.svg")
granularity_2
dev.off()
svg("output/fig_3_c.svg")
granularity_3
dev.off()

# what percentage of GID2 things are represented by only one grid cell?
(length(ct.temp[ct.temp$bin == "1",]$count)/length(ct.temp$count))*100


## -------------- FIGURE 4 -------------- ##

# Comparing AREAdata outputs to CCKP data

# Going to need to download some of the CCKP data for this to work
# go to: https://climateknowledgeportal.worldbank.org/download-data
# Select: Climatology
# Collection: Observed data (CRU)
# Variable: Mean-Temperature
# Climatology: 1991-2020
# Country: < Select all of them >
# Aggregation: Monthly
# save the csv file somewhere to read in on the following line

wb_all <- read.csv("tas_1991_2020_AFG_ALB_DZA_AND_AGO_ATG_ARG_ARM_AUS_AUT_AZE_BHS_BHR_BGD_BRB_BLR_BEL_BLZ_BEN_BTN_BOL_BIH_BWA_BRA_BRN_BGR_BFA_BDI_KHM_CMR_CAN_CPV_CAF_TCD_CHL_CHN_COL_COM_COD_COG_COK_CRI_CIV_HRV_CUB_CYP_CZE_DNK_DJI_DMA_DOM_ECU_EGY_.csv")
wb_all$Country <- gsub(" ", "", wb_all$Country)

areadata <- as.data.frame(readRDS("output/temp-dailymean-countries-cleaned.RDS"))
areadata$country <- gsub("_", "", row.names(areadata))

# make long
areadata_long <- pivot_longer(areadata,
                              cols = c(1:(ncol(areadata)-1)),
                              names_to = "date",
                              values_to = "temperature")



# aggregate by month
areadata_month <- areadata_long %>% 
  group_by(country = country, yr = year(date), mon = month(date)) %>% 
  summarise(mean_temp = mean(temperature))

# bring to 2020
areadata_month <- areadata_month[areadata_month$yr == 2020,]

wb_2020 <- wb_all[wb_all$Year == "2020",]
wb_2020 <- wb_2020[!is.na(wb_2020$Year),]

# add a month column the same as areadata months
wb_2020$mon <- seq(1, 12, 1)

# I propose looking at the country correlations for 2020 - merge the datasets
names(wb_2020) <- c("wb_temp", "yr", "month_long", "country", "IS03", "mon")
names(areadata_month) <- c("country", "yr", "mon", "areadata_temp")
wb_2020$wb_temp <- as.numeric(wb_2020$wb_temp)

combined_data <- merge(areadata_month, wb_2020, by = c("country", "yr", "mon"))

# update some columns for plotting
combined_data$month <- NA
combined_data[combined_data$mon == 1,]$month <- "Jan"
combined_data[combined_data$mon == 2,]$month <- "Feb"
combined_data[combined_data$mon == 3,]$month <- "Mar"
combined_data[combined_data$mon == 4,]$month <- "Apr"
combined_data[combined_data$mon == 5,]$month <- "May"
combined_data[combined_data$mon == 6,]$month <- "Jun"
combined_data[combined_data$mon == 7,]$month <- "Jul"
combined_data[combined_data$mon == 8,]$month <- "Aug"
combined_data[combined_data$mon == 9,]$month <- "Sep"
combined_data[combined_data$mon == 10,]$month <- "Oct"
combined_data[combined_data$mon == 11,]$month <- "Nov"
combined_data[combined_data$mon == 12,]$month <- "Dec"

combined_data$month = factor(combined_data$month, levels=c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"))

wb_vs_areadata <- ggplot(combined_data, aes(x = wb_temp, y = areadata_temp)) + 
  geom_point() +
  geom_abline(slope = 1) +
  geom_smooth(method = lm) +
  facet_wrap(~month) +
  labs(x = "CCKP Temperature", y = "AREAdata Temperature") +
  theme_bw() +
  theme(axis.text = element_text(size = 14),
        axis.title = element_text(size = 16),
        strip.text = element_text(size = 14),
        aspect.ratio = 1)

pdf("fig_4.pdf")
wb_vs_areadata
dev.off()

# check the correlation
cor(combined_data$wb_temp, combined_data$areadata_temp)
