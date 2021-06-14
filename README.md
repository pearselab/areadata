# climate-averaging
## Averaging climate variables across different spatial units, updating to present with new data

RDS files with averaged climate variables across countries (GID.0) and states (GID.1) available in /output. 
The most updated version's name is appended with -cleaned.RDS. 
Currently this is available for temperature, humidity and UV.

Metadata linking country/state names to GID identifiers given in /data/name-matching.csv

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

1. First run the initial setup script from the main directory: bash src/get-climate-data-first-setup.sh
   * By default this will download and clean data for Jan 2020. You could modify the starting date if you wish by changing the arguments in the calls to the python and R scripts.

2. From then, you can update the repository to any month you wish using the update-climate-data.sh script and specifying a range of dates, the climate variables you want to update, and the number of processor cores for R to use
   * e.g. bash src/update-climate-data.sh -y 2020 -m '02 03 04' -c 4 -v 'temperature humidity uv'
   * It's suggested not to do too many dates at once, as this will result in a large download that will take a long time and use up a lot of hard drive space.
   * You can check what date the data was previously updated to in the update-datestamp.txt file in /output before choosing new dates to update to.
   
3. Save space by deleting the large .grib files in the data folder after cleaning


## Future plan:

Include future climate forecasts
