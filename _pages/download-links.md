---
title: "AREAdata - Downloads"
layout: textlay
excerpt: "AREAdata -- Downloads"
sitemap: false
permalink: /download-links/
---

# Downloads

Here we provide links to download the spatially averaged data either as .RDS files for use in R or as zipped tab-delimited txt files for other applications. 
See methods page for the processing methods and the units given. Please cite the original data sources when using
these data (given with the download links and presented at the bottom of this page).

## Metadata

Download the metadata linking GID admin codes with place names: [HERE](https://github.com/pearselab/areadata/raw/main/data/name-matching.csv)

----

## GID level 0 (Countries)

### Daily Climate

Matrices of daily climate estimates by spatial units (rows) and by date (columns):

 * Temperature<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-countries-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-countries-cleaned.zip)
 * Specific humidity<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-countries-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-countries-cleaned.zip)
 * Relative humidity<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-countries-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-countries-cleaned.zip)
 * UV<sup>2,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-countries-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-countries-cleaned.zip)
 * Precipitation<sup>2,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-countries-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-countries-cleaned.zip)

### Population Density 

Matrices of population density estimates by spatial units (rows)<sup>3,4</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/population-density-countries.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/population-density-countries.zip)

### Future climate Scenario Forecasts

Matrices of future climate forecasts by spatial units (rows) and by each combination of global climate model and shared socio-economic pathway for given year-ranges (columns)<sup>3,5</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-countries.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-countries.zip)

----

## GID level 1 (States)

### Daily Climate

Matrices of daily climate estimates by spatial units (rows) and by date (columns):

 * Temperature<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-GID1-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-GID1-cleaned.zip)
 * Specific humidity<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-GID1-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-GID1-cleaned.zip)
 * Relative humidity<sup>1,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-GID1-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-GID1-cleaned.zip)
 * UV<sup>2,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-GID1-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-GID1-cleaned.zip)
 * Precipitation<sup>2,3</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-GID1-cleaned.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-GID1-cleaned.zip)

### Population Density 

Matrices of population density estimates by spatial units (rows)<sup>3,4</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/population-density-GID1.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/population-density-GID1.zip)

### Future climate Scenario Forecasts

Matrices of future climate forecasts by spatial units (rows) and by each combination of global climate model and shared socio-economic pathway for given year-ranges (columns)<sup>3,5</sup>: [[.RDS]](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-GID1.RDS) &#124; [[zipped .txt]](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-GID1.zip)

----

## GID level 2 (Counties)

All GID-2 downloads available from figshare: [https://doi.org/10.6084/m9.figshare.16587311](https://doi.org/10.6084/m9.figshare.16587311)

Temperature, speficic humidity, relative humidity citations: 1,3

UV, precipitation citations: 2,3

Population density citations: 3,4

Future climate scenario forecasts citations: 3,5

---

## Experimental branch - UK regions

Here we additionally provide UK specific estimates at three different administrative levels, based on shapefiles provided by the UKs office for national statistics (ONS): NUTS 1 regions (Nomenclature of Territorial Units for Statistics; comprising Wales, Scotland, Northern Ireland, and 9 regions of England), LTLAs (Lower-tier local authorities; districts, boroughs or city councils), STPs (sustainability and transformation partnerships; 42 National Healthcare Service regions in England).

 * Temperature<sup>1</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-UK-NUTS-cleaned.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-UK-LTLA-cleaned.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/temp-dailymean-UK-STP-cleaned.RDS)
 * Specific humidity<sup>1</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-UK-NUTS-cleaned.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-UK-LTLA-cleaned.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/spechumid-dailymean-UK-STP-cleaned.RDS)
 * Relative humidity<sup>1</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-UK-NUTS-cleaned.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-UK-LTLA-cleaned.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/relhumid-dailymean-UK-STP-cleaned.RDS)
 * UV<sup>2</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-UK-NUTS-cleaned.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-UK-LTLA-cleaned.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/uv-dailymean-UK-STP-cleaned.RDS)
 * Precipitation<sup>2</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-UK-NUTS-cleaned.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-UK-LTLA-cleaned.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/precip-dailymean-UK-STP-cleaned.RDS)
 * Population density<sup>4</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/population-density-UK-NUTS.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/population-density-UK-LTLA.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/population-density-UK-STP.RDS)
 * Future climate forecasts<sup>5</sup>: [NUTS](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-UK-NUTS.RDS) &#124; [LTLAs](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-UK-LTLA.RDS) &#124; [STPs](https://github.com/pearselab/areadata/raw/main/output/annual-mean-temperature-forecast-UK-STP.RDS)

----

## Citations

 1. Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on pressure levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.bd0915c6
 2. Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.adbb2d47 
 3. Global Administrative Areas (GADM) database of global administrative areas, version 3.6. https://www.gadm.org
 4. Center for International Earth Science Information Network, Gridded population of the world, version 4 (GPWv4): Population density, revision 11. https://doi.org/10.7927/H49C6VHW
 5. Fick, S.E. and R.J. Hijmans, 2017. WorldClim 2: new 1km spatial resolution climate surfaces for global land areas. International Journal of Climatology 37 (12): 4302-4315.