---
title: "AREAdata - Methods"
layout: textlay
excerpt: "AREAdata -- Methods"
sitemap: false
permalink: /protocol/
---

# Methods

AREAdata provides daily estimates of climate variables which have been averaged across different levels of spatial units (i.e. countries, states, etc), updated to the near-present. 
Here we detail the methods used to generate these datasets, largely following the methods presented in our paper ["Temperature and Population Density Influence SARS-CoV-2 Transmission in the Absence of Nonpharmaceutical Interventions", 2021, PNAS, doi: 10.1073/pnas.2019284118](https://doi.org/10.1073/pnas.2019284118).


## Data collection

### Spatial unit shapefiles

Shapefiles for countries and states were acquired from the Global Administrative Areas (GADM) database of global administrative areas, version 3.6. https://www.gadm.org

Shapefiles for UK NUTS and LTLA regions were acquired from the office for national statistics (ONS): https://geoportal.statistics.gov.uk

### Daily climate variables

Daily climate data were acquired from the Coperincus Climate Data Store (CDS); temperature and relative humidity from ERA5 hourly data on pressure levels (at 1000 hpa - surface level atmospheric pressure), UV and precipitation from ERA5 hourly data on single levels (surface level):

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on pressure levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.bd0915c6

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.adbb2d47 

Temperature is given in degrees Celsius, humidity is the relative humidity % (water vapour pressure as a percentage of the air saturatation value), UV is the the amount of UV radiation reaching the surface (J m<sup>-2</sup>), and precipitation is the accumulated liquid and frozen water falling to the Earth's surface, depth in metres of water equivalent.

### Population density

Center for International Earth Science Information Network, Gridded population of the world, version 4 (GPWv4): Population density, revision 11. https://doi.org/ 10.7927/H49C6VHW

### CMIP6 climate projections

Downscaled CMIP6 future climate projections were acquired from WorldClim: https://worldclim.org/data/cmip6/cmip6_clim10m.html

Fick, S.E. and R.J. Hijmans, 2017. WorldClim 2: new 1km spatial resolution climate surfaces for global land areas. International Journal of Climatology 37 (12): 4302-4315.


## Methods Pipeline

We use the Climate Data Operators (CDO) program to compute daily means from the hourly data for each of the climate variables acquired from the CDS, using the `daymean` command. 
We then average (median) the value of each environmental variable across the administrative units given in each of our acquired shapefiles (*i.e.* countries, states, etc), using the `extract()` function in the *raster* R package. The UK shapefiles are first transformed into the same spatial projection as the climate data, using the `spTransform()` function in the *sp* R package. 
Our code is written such that when new climate data is available, these are appended to the previously extracted data to produce a single live updated output file. The data produced are simple files containing the daily climate estimates by spatial unit, *e.g.* country (rows) and by date (columns), which we output as .RDS files for use in R. 
An example of the input data for temperature from the 1st January, 2020, and the output following application of our methodology for country-level spatial units is given in Figure 1 below. 
We use the same methods to process the gridded population density data, which we provide similarly with a single population density column for spatial units (rows). 
We process annual mean temperatures from the climate forecast data, and again provide estimates by spatial unit (rows) for each combination of GCM, SSP and year-range (columns). 
The population density and temperature forecast output files are static (not continually updated). See the downloads page to directly acquire the .RDS climate data files.

![image-title-here]({{ site.url }}{{ site.baseurl }}/images/temperature-countries.svg){:class="img-responsive"}

*Figure 1: Depiction of AREAdata methodology. A. Climate data rasters are acquired, the example figure shows daily mean temperature (C) for 2020-01-01. B. Shapefiles are used to demarcate the boundaries of different administrative units, in this case countries (GID 0). C. The climate variable is averaged (median) across each spatial unit.*
