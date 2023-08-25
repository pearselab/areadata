#!/bin/bash
# Run script to download and average climate variable across spatial units
# then merge this with previously downloaded data
# Tom Smith 2021

# parse the command line options
while getopts y:m:c:v: flag
do
    case "${flag}" in
        y) year=${OPTARG};;
        m) months=${OPTARG};;
        c) cores=${OPTARG};;
        v) climvar=${OPTARG};;
    esac
done

echo "Updating climate data for:"
echo "Climate variable(s): $climvar";
echo "Year(s): $year";
echo "Month(s): $months";
echo "Using $cores cores in R";

# turn months and climate variables into a comma separated list for R later
monthlist=$(echo "$months" | tr ' ' ,)
climatelist=$(echo "$climvar" | tr ' ' ,)

# also get arrays of years and months to access elements for file naming
yeararr=($year)
montharr=($months)

echo "Run cds download script over a selected date range"

python3 src/cds-era5-args.py -y $year -m $months -c $climvar

echo "Average across single days"
# use wildcards to check if climvar string contains each variable

if [[ "$climvar" == *"temperature"* ]]; then
  cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib
  # make a backup of the raw download using first and last date elements
  base="data/archive/cds-temp-"
  new_path=${base}-${yeararr[0]}-${montharr[0]}-${yeararr[-1]}-${montharr[-1]}.grib
  cp data/cds-temp.grib $new_path
fi

if [[ "$climvar" == *"spec_humid"* ]]; then
  cdo daymean data/cds-spechumid.grib data/cds-spechumid-dailymean.grib
  # make a backup of the raw download using first and last date elements
  base="data/archive/cds-spechumid-"
  new_path=${base}-${yeararr[0]}-${montharr[0]}-${yeararr[-1]}-${montharr[-1]}.grib
  cp data/cds-spechumid.grib $new_path
fi

if [[ "$climvar" == *"rel_humid"* ]]; then
  cdo daymean data/cds-relhumid.grib data/cds-relhumid-dailymean.grib
  # make a backup of the raw download using first and last date elements
  base="data/archive/cds-relhumid-"
  new_path=${base}-${yeararr[0]}-${montharr[0]}-${yeararr[-1]}-${montharr[-1]}.grib
  cp data/cds-relhumid.grib $new_path
fi

if [[ "$climvar" == *"uv"* ]]; then
  cdo daymean data/cds-uv.grib data/cds-uv-dailymean.grib
  # make a backup of the raw download using first and last date elements
  base="data/archive/cds-uv-"
  new_path=${base}-${yeararr[0]}-${montharr[0]}-${yeararr[-1]}-${montharr[-1]}.grib
  cp data/cds-uv.grib $new_path
fi

if [[ "$climvar" == *"precipitation"* ]]; then
  cdo daymean data/cds-precip.grib data/cds-precip-dailymean.grib
  # make a backup of the raw download using first and last date elements
  base="data/archive/cds-precip-"
  new_path=${base}-${yeararr[0]}-${montharr[0]}-${yeararr[-1]}-${montharr[-1]}.grib
  cp data/cds-precip.grib $new_path
fi

echo "Average daily climate data across spatial regions"

Rscript src/update-cds-era5.R -y $year -m $monthlist, -v $climatelist -c $cores

echo "... Finished averaging across regions! Files written to output directory!"

echo "Generating new hashes"

md5sum output/* > output/hashes

echo "Done"
