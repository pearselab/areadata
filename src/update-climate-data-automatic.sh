#!/bin/bash
# Run script to download and average climate variable across spatial units
# then merge this with previously downloaded data
# This script can be scheduled to run monthly and it will fetch the previous month's data
# Tom Smith 2021

# parse the command line options
while getopts c:v: flag
do
    case "${flag}" in
        c) cores=${OPTARG};;
        v) climvar=${OPTARG};;
    esac
done

# get year and month to update, based on current date
# we're going to run this once a month and update the previous months data

year=`date -d "- 1 month" +%Y`
months=`date -d "- 1 month" +%m`

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

echo "...Checking for processing errors..."

output=`Rscript src/check-output-dates.R`

if [[ "$output" == "TRUETRUE" ]]
then
  echo "no processing errors encountered"

  echo "zipping tab delimited files"
  zip -m -T output/temp-dailymean-countries-cleaned.zip output/temp-dailymean-countries-cleaned.txt
  zip -m -T output/temp-dailymean-GID1-cleaned.zip output/temp-dailymean-GID1-cleaned.txt
  zip -m -T output/temp-dailymean-GID2-cleaned.zip output/temp-dailymean-GID2-cleaned.txt
  zip -m -T output/temp-dailymean-UK-LTLA-cleaned.zip output/temp-dailymean-UK-LTLA-cleaned.txt
  zip -m -T output/temp-dailymean-UK-NUTS-cleaned.zip output/temp-dailymean-UK-NUTS-cleaned.txt
  zip -m -T output/temp-dailymean-UK-STP-cleaned.zip output/temp-dailymean-UK-STP-cleaned.txt

  zip -m -T output/spechumid-dailymean-countries-cleaned.zip output/spechumid-dailymean-countries-cleaned.txt
  zip -m -T output/spechumid-dailymean-GID1-cleaned.zip output/spechumid-dailymean-GID1-cleaned.txt
  zip -m -T output/spechumid-dailymean-GID2-cleaned.zip output/spechumid-dailymean-GID2-cleaned.txt
  zip -m -T output/spechumid-dailymean-UK-LTLA-cleaned.zip output/spechumid-dailymean-UK-LTLA-cleaned.txt
  zip -m -T output/spechumid-dailymean-UK-NUTS-cleaned.zip output/spechumid-dailymean-UK-NUTS-cleaned.txt
  zip -m -T output/spechumid-dailymean-UK-STP-cleaned.zip output/spechumid-dailymean-UK-STP-cleaned.txt

  zip -m -T output/relhumid-dailymean-countries-cleaned.zip output/relhumid-dailymean-countries-cleaned.txt
  zip -m -T output/relhumid-dailymean-GID1-cleaned.zip output/relhumid-dailymean-GID1-cleaned.txt
  zip -m -T output/relhumid-dailymean-GID2-cleaned.zip output/relhumid-dailymean-GID2-cleaned.txt
  zip -m -T output/relhumid-dailymean-UK-LTLA-cleaned.zip output/relhumid-dailymean-UK-LTLA-cleaned.txt
  zip -m -T output/relhumid-dailymean-UK-NUTS-cleaned.zip output/relhumid-dailymean-UK-NUTS-cleaned.txt
  zip -m -T output/relhumid-dailymean-UK-STP-cleaned.zip output/relhumid-dailymean-UK-STP-cleaned.txt

  zip -m -T output/precip-dailymean-countries-cleaned.zip output/precip-dailymean-countries-cleaned.txt
  zip -m -T output/precip-dailymean-GID1-cleaned.zip output/precip-dailymean-GID1-cleaned.txt
  zip -m -T output/precip-dailymean-GID2-cleaned.zip output/precip-dailymean-GID2-cleaned.txt
  zip -m -T output/precip-dailymean-UK-LTLA-cleaned.zip output/precip-dailymean-UK-LTLA-cleaned.txt
  zip -m -T output/precip-dailymean-UK-NUTS-cleaned.zip output/precip-dailymean-UK-NUTS-cleaned.txt
  zip -m -T output/precip-dailymean-UK-STP-cleaned.zip output/precip-dailymean-UK-STP-cleaned.txt

  zip -m -T output/uv-dailymean-countries-cleaned.zip output/uv-dailymean-countries-cleaned.txt
  zip -m -T output/uv-dailymean-GID1-cleaned.zip output/uv-dailymean-GID1-cleaned.txt
  zip -m -T output/uv-dailymean-GID2-cleaned.zip output/uv-dailymean-GID2-cleaned.txt
  zip -m -T output/uv-dailymean-UK-LTLA-cleaned.zip output/uv-dailymean-UK-LTLA-cleaned.txt
  zip -m -T output/uv-dailymean-UK-NUTS-cleaned.zip output/uv-dailymean-UK-NUTS-cleaned.txt
  zip -m -T output/uv-dailymean-UK-STP-cleaned.zip output/uv-dailymean-UK-STP-cleaned.txt

  echo "...Generating new hashes..."
  md5sum output/* > output/hashes

  echo "... updating GID2 files on figshare ..."
  python3 src/figshare-update.py

  echo ".. pushing changes to git"
  git add -A
  git commit -m "updated data for $months $year"
  git push origin main # do we need to put something here so git doesn't ask for a password... sudo?
  echo "... Finished averaging across regions! Files written to output directory and pushed to Git!"
else
  echo "Errors encountered:"
  echo $output

  echo "Failed to write files, nothing pushed to Git or figshare, check for problems"
fi
