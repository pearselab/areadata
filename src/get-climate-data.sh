#!/bin/bash
# Run script to download and then average climate variable across spatial units
# Tom Smith 2021

echo "Run cds download script over a particular date range"

python3 src/cds-era5-args.py -y 2020 -m 01 -d 01 02 03 04 05 06 07 -o cds-temp

echo "Average across single days"

cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib

echo "Saving space by deleting unecessary large download files"

rm data/cds-temp.grib

echo "Average daily climate data across spatial regions"

Rscript src/clean_cds-era5.R -y 2020 -m 01 -d 01,02,03,04,05,06,07 -o cleaned

echo "... Finished averaging across regions! Files written to output directory!"
