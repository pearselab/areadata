# AREAdata
## Administrative Region Environmental Averages "AREA" dataset

### Daily estimates updated to present with new data

RDS files with averaged climate variables across countries (GID.0) and states (GID.1) available in /output. 
The most updated version's name is appended with -cleaned.RDS. 
Currently this is available for temperature, humidity, precipitation and UV.

Metadata linking country/state names to GID identifiers given in /data/name-matching.csv

### Climate forecasts

RDS files with mean annual temperature forecasts based on the CMIP6 future climate projections are given in /output `annual-mean-temperature-forecast-` for countries and states. 
These contain estimates based on nine global climate models (BCC-CSM2-MR, CNRM-CM6-1, CNRM-ESM2-1, CanESM5, GFDL-ESM4, IPSL-CM6A-LR, MIROC-ES2L, MIROC6, MRI-ESM2-0), each for four Shared Socio-economic Pathways (SSPs: 126, 245, 370 and 585).
Column headers give the model, ssp and future year-range estimated for.

## Data sources

When using these data, please also cite the original data sources used to generate the outputs provided here:

### Spatial unit shapefiles

Shapefiles for countries and states were acquired from the Global Administrative Areas (GADM) database of global administrative areas, version 3.6. https://www.gadm.org

Shapefiles for UK NUTS and LTLA regions were acquired from the office for national statistics (ONS): https://geoportal.statistics.gov.uk

### Daily climate variables

Daily climate data were acquired from the Coperincus Climate Data Store (CDS); temperature and relative humidity from ERA5 hourly data on pressure levels, UV and precipitation from ERA5 hourly data on single levels:

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on pressure levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.bd0915c6

Hersbach, H., Bell, B., Berrisford, P., Biavati, G., Horányi, A., Muñoz Sabater, J., Nicolas, J., Peubey, C., Radu, R., Rozum, I., Schepers, D., Simmons, A., Soci, C., Dee, D., Thépaut, J-N. (2018): ERA5 hourly data on single levels from 1979 to present. Copernicus Climate Change Service (C3S) Climate Data Store (CDS). 10.24381/cds.adbb2d47 

### Population density

Center for International Earth Science Information Network, Gridded population of the world, version 4 (GPWv4): Population density, revision 11. https://doi.org/ 10.7927/H49C6VHW

### CMIP6 climate projections

Downscaled CMIP6 future climate projections were acquired from WorldClim: https://worldclim.org/data/cmip6/cmip6_clim10m.html

Fick, S.E. and R.J. Hijmans, 2017. WorldClim 2: new 1km spatial resolution climate surfaces for global land areas. International Journal of Climatology 37 (12): 4302-4315.

# If you would like to set up this repositiory and run it yourself:

## Installation

1. **Python**. 
   1. Ensure you have Python 3 installed on your computer, and that it runs when you type `python3` into your terminal (use something like `python3 --version` to check).
   2. Install the egg `cdsapi` (use something like `sudo pip install cdsapi`).
2. **R**.
   1. Ensure you have R (>= 3.6.3) installed on your computer, and that it runs when you type `Rscript` into your terminal.
   2. Install required R packages: "optparse", "raster", "sf", "tidyr", "rgdal" with install.packages()
3. **CDS AR5 climate data** - follow these instructions if you want to download these data
   1. Register for an API key at https://cds.climate.copernicus.eu/#!/home
   2. Follow instructions here to create a .cdsapirc file in $HOME with your api key information: https://cds.climate.copernicus.eu/api-how-to
   3. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=form) 'Reanalysis', 'temperature' and 'relative humidity', '1000hPa', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
   4. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form) 'Reanalysis', 'Radiation and heat: Downward UV radiation at the surface', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
4. **Climate Data Operators** - install this program to download and then process the CDS data (point 3 above). There are two ways to do that:
   1. On Ubuntu use `sudo apt install cdo` (likely something similar for other Linux distributions).
   2. Follow the instructions here https://code.mpimet.mpg.de/projects/cdo/wiki#Installation-and-Supported-Platforms to install on other computers.


## Usage

1. You can update the repository to any month you wish, for any of the already implemented climate variables, using the update-climate-data.sh script: `bash src/update-climate-data.sh -y <year(s)> -m <month(s)> -c <cores> -v <climate variables>`
   * -y: the **Y**ears you want the data for, e.g. -y 2021 or -y '2020 2021' (must be set)
   * -m: the **M**onth(s) you want the data for, e.g. -m 01 or -m '01 02 03' (must be set)
   * -c: the number of **C**ores you want R to use for the parallelised averaging across regions code, e.g. -c 4 (defaults to 1 if not set)
   * -v the climate **V**ariables you want to update, currently accepts arguments: *temperature, humidity, precipitation, uv*, e.g. -v temperature or -v 'temperature precipitation'
   * It's suggested not to do too many dates at once, as this will result in a large download that will take a long time and use up a lot of hard drive space.

2. Save space by deleting the large .grib files in the data folder after cleaning

3. To modify code to run older dates or gather new climate variables from the cds api, you may wish to alter and run the initial setup script from the main directory: `bash src/get-climate-data-first-setup.sh`
   * By default this will download and clean data for Jan 2020. You could modify the starting date if you wish by changing the arguments in the calls to the python and R scripts, or add new climate variables in the python scripts, but this will be more involved.
   * This generates the first round of data files for the update script to then run off.
 
