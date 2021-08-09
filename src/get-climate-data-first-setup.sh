#!/bin/bash
# Run script to download and then average climate variable across spatial units
# Tom Smith 2021

echo "Run cds download script over a particular date range"

python3 src/cds-era5-args.py -y 2020 -m 01 -c temperature spec_humid rel_humid uv precipitation

echo "Average across single days"

cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib
cdo daymean data/cds-spechumid.grib data/cds-spechumid-dailymean.grib
cdo daymean data/cds-relhumid.grib data/cds-relhumid-dailymean.grib
cdo daymean data/cds-uv.grib data/cds-uv-dailymean.grib
cdo daymean data/cds-precip.grib data/cds-precip-dailymean.grib

# archive the downloads somewhere
cp data/cds-temp.grib data/archive/cds-temp-2020-01.grib
cp data/cds-spechumid.grib data/archive/cds-spechumid-2020-01.grib
cp data/cds-relhumid.grib data/archive/cds-relhumid-2020-01.grib
cp data/cds-uv.grib data/archive/cds-uv-2020-01.grib
cp data/cds-precip.grib data/archive/cds-precip-2020-01.grib

echo "Average daily climate data across spatial regions"

Rscript src/clean-cds-era5.R -y 2020 -m 01 -c 4

echo "... Finished averaging across regions! Files written to output directory!"
