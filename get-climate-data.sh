#!/bin/bash
# Run script to download and then average climate variable across spatial units
# Tom Smith 2021

echo "Run cds download script over a particular date range"

python3 src/cds-era5-args.py -y 2020 -m 01 -d 01 -o cds-temp

echo "Average across single days, then delete unecessary large download files"



echo "... Finished doing the stuff! Stuff written to XYZ directory!"
