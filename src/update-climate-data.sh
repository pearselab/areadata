#!/bin/bash
# Run script to download and average climate variable across spatial units
# then merge this with previously downloaded data
# Tom Smith 2021

# parse the command line options
while getopts y:m: flag
do
    case "${flag}" in
        y) year=${OPTARG};;
        m) months=${OPTARG};;
    esac
done

echo "Updating climate data for:"
echo "Year: $year";
echo "Months: $months";

# turn months into a comma separated list for R later
monthlist=$(echo "$months" | tr ' ' ,)


echo "Run cds download script over a selected date range"

python3 src/cds-era5-args.py -y $year -m $months -o cds-temp

echo "Average across single days"

cdo daymean data/cds-temp.grib data/cds-temp-dailymean.grib

echo "Average daily climate data across spatial regions"

Rscript src/update-cds-era5.R -y $year -m $monthlist, -o cleaned

echo "... Finished averaging across regions! Files written to output directory!"
