#!/bin/bash
# Run script to download and then average climate variable across spatial units
# Tom Smith 2021

echo "Run cds download script over a particular date range"

python3 src/cds-era5-args.py -y 2020 -m 01 -o cds-temp

echo "Average across single days"

cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib

echo "Average daily climate data across spatial regions"

Rscript src/clean-cds-era5.R -y 2020 -m 01 -o cleaned

echo "... Finished averaging across regions! Files written to output directory!"
