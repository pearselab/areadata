#!/bin/bash

# Author: Francis Windram
# Run a LIVE update up to the present time and concatenate with the previous LIVE dump
# Command example: bash src/update-AD-topresent.sh

# Find date of current AD dump/s
dumpdates=$(Rscript src/find-dump-dates.R)
dumpdates=(${dumpdates//,/ })
# printf '%s\n' "${dumpdates[@]}"

if [[ ${#dumpdates[@]} -eq 0 ]]; then
    echo "No dates to retrieve!"
    exit 0
fi

# Make archive folder for this run
backupfolder=$(date +'%Y%m%d')
mkdir -p output/archive/$backupfolder

# Make placeholder final run date 1 year after last one desired
# (just to make sure that we can get a sensible call to get-historic-data.sh)
firstdate=${dumpdates[0]}
finaldate=${dumpdates[-1]}
finaldate_arr=(${finaldate//-/ })
finalyear=${finaldate_arr[0]}
runendyear=$((finalyear + 1))

runenddate="${runendyear}-${finaldate_arr[1]}"

# Run get-historic-data.sh for these months
for dumpdate in ${dumpdates[@]}; do
    # echo "src/get-historic-data.sh -s $dumpdate -e $runenddate -c 8 -d -i 0"
    src/get-historic-data.sh -s $dumpdate -e $runenddate -c 8 -d -i 0  # TODO: temporarily disabled
done

archivedcount=0
# Take backup of current state of dumps
climvars=("temp" "spechumid" "relhumid" "uv" "precip")
agglevels=("countries" "GID1" "GID2" "UK-NUTS" "UK-LTLA" "UK-STP")
for climvar in ${climvars[@]}; do
    for agglevel in ${agglevels[@]}; do
        if [ -e "output/${climvar}-dailymean-${agglevel}-cleaned.RDS" ]; then
            # echo "${climvar}-dailymean-${agglevel}-cleaned.RDS" output/archive/$backupfolder
            cp "${climvar}-dailymean-${agglevel}-cleaned.RDS" output/archive/$backupfolder  # TODO: temporarily disabled
            archivedcount=$((archivedcount + 1))
        fi
        if [ -e "output/${climvar}-dailymean-${agglevel}-cleaned.txt" ]; then
            # echo "${climvar}-dailymean-${agglevel}-cleaned.txt" output/archive/$backupfolder
            cp "${climvar}-dailymean-${agglevel}-cleaned.txt" output/archive/$backupfolder  # TODO: temporarily disabled
            archivedcount=$((archivedcount + 1))
        fi

    done
done

echo Archived $archivedcount dumps.

# Merge dumps up to current date
# echo "Rscript src/concat-LIVE-data.R -s ${firstdate} -p output/ -d"
Rscript src/concat-LIVE-data.R -s $firstdate -p output/ -d  # TODO: temporarily disabled
# Later handle uploads to figshare?
