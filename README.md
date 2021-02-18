# climate-averaging
Average climate variables across different regions, updating to present with new data

# THIS DOES NOT WORK YET!

## Installation

1. Copy the file `dummy_config.yml` to create a file called `config.yml` in the same directory.
2. **Python**. 
   1. Ensure you have Python 3 installed on your computer, and that it runs when you type `python3` into your terminal (use something like `python3 --version` to check).
   2. Install the egg `cdsapi` (use something like `sudo pip install cdsapi`).
3. **R**.
   1. Ensure you have R (>= 3.6.3) installed on your computer, and that it runs when you type `Rscript` into your terminal.
   2. Change the parameter `mc.cores` in the `r` block within `config.yml` to tell R how many processor cores it can use.
   3. This repo will try to install all required R packages for you when you need them, but if you like you can run something like `Rscript src/packages.R` now. We recommend doing so and looking at the output: sometimes installing R packages can be hard and, if you're on a Linux system, you make find looking at the package error messages instructive.
4. **CDS AR5 climate data** - follow these instructions if you want to download these data
   1. Register for an API key at https://cds.climate.copernicus.eu/#!/home
   2. Fill in your `key` information in the `cds` block of `config.yml`.
   3. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels?tab=form) 'Reanalysis', 'temperature' and 'relative humidity', '1000hPa', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
   4. Select from here (https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-single-levels?tab=form) 'Reanalysis', 'Radiation and heat: Downward UV radiation at the surface', '2020', 'January, February, March, April, May', all days, all times, 'Whole available region', 'GRIB', and then submit/agree to the download requirements.
5. **Climate Data Operators** - install this program if you want to download and then process the CDS data (point 4 above). There are two ways to do that:
   1. On Ubuntu use `sudo apt install cdo` (likely something similar for other Linux distributions).
   2. Follow the instructions here https://code.mpimet.mpg.de/projects/cdo/wiki#Installation-and-Supported-Platforms to install on other computers.

## 

Plan for this repo - download data from cds on a weekly basis, apply cdo daily averaging code, apply spatial averaging code, delete large unnecessary files.

Main code should be written to do EVERYTHING and store the continuously updated output files somewhere useful.

This would be for first set-up?

Secondary code with "update" button to check what already exists in the weekly files and update to current (or to whatever specified date)?

Potentially users should be able to specify a date range they want as well as specific climate variables?
