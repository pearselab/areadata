#!/bin/bash
# download all the links from the repo in parallel using 4 cores

# note - might be best to add a "model" argument that can expand this code
# to take different models from the worldclim site by automatically constructing the urls
# then have the R script use the specified model name in the output file

# make a folder to put this stuff, and move everything
cd data

mkdir ./raw-forecasts

cd raw-forecasts


echo "Downloading forecast files..."
cat ../forecast-links.txt | xargs -n 1 -P 4 wget -q

echo "Unzipping and moving downloaded files"
for z in *.zip; do unzip $z; done


# move the stuff from the random folders into the main directory
find . -name "*.tif" -exec mv "{}" ./ \;

# remove unecessary files/folders
rm -rf share
rm *.zip

# run the averaging R script
echo "Averaging climate projections across regions - this may take a while..."
cd ../../

Rscript src/forecast-averaging.R -c 4

# remove the tif files we now have lying around to save space - don't need them anymore
echo "Removing downloaded files"
rm -rf data/raw-forecasts

echo "Finished!"
