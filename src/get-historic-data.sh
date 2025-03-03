#!/bin/bash
#SBATCH --time=0-02:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8 # Number of CPU cores per task
#SBATCH --mem=12G # Memory per node
#SBATCH --partition=large_336 # Must keep this requirement on anything running on Harvey

# Run script to download and then average climate variable across spatial units
# Run on SLURM (e.g. for 10 years of data) using `sbatch --array=0-119 -J AREAData_Download`
# Francis Windram 2025 (based on Tom Smith 2021)

start=`date +%s`

OPTSTRING="dms:e:c:i:v:"

while getopts ${OPTSTRING} flag; do
  case "${flag}" in
      d) deletefiles=1;;
      m) movefiles=1;;
      s) startdate=${OPTARG};;
      e) enddate=${OPTARG};;
      v) desiredclimvars=${OPTARG};;
      c) cores=${OPTARG};;
      i) index=${OPTARG};;
  esac
done

# Set defaults and set array index if present in global env
if [ -z "$startdate" ]; then echo "Please prove a start and end date in yyyy-mm format!"; exit 1; fi
if [ -z "$enddate" ]; then echo "Please prove a start and end date in yyyy-mm format!"; exit 1; fi
if [ -z "$desiredclimvars" ]; then desiredclimvars="temp,spechumid,relhumid,uv,precip"; fi
if [ -z "$cores" ]; then cores=1; fi
if [ -z "$index" ]; then index=0; fi
if [ -z "$movefiles" ]; then movefiles=0; fi
if [ -z "$deletefiles" ]; then deletefiles=0; fi
if [ -v "$SLURM_ARRAY_TASK_ID" ]; then echo -e "\nSLURM ID: $SLURM_ARRAY_TASK_ID \n"; index=$SLURM_ARRAY_TASK_ID; fi

# detect starting delimiter
startdelim="-"
case "$startdate" in
  *-*) startdelim="-";;
  *_*) startdelim="_";;
  */*) startdelim="/";;
esac

# detect ending delimiter
enddelim="-"
case "$enddate" in
  *-*) enddelim="-";;
  *_*) enddelim="_";;
  */*) enddelim="/";;
esac

# Split and parse years or months
startIN=(${startdate//${startdelim}/ })
startyear=${startIN[0]}
startmonth=${startIN[1]}
if [ -z "$startmonth" ]; then startmonth=01; fi
# Make sure month is 2 digits
printf -v startmonth "%02d" $startmonth

endIN=(${enddate//${enddelim}/ })
endyear=${endIN[0]}
endmonth=${endIN[1]}
if [ -z "$endmonth" ]; then endmonth=12; fi
printf -v endmonth "%02d" $endmonth

echo -e "\n=============== RUN PARAMETERS ===============\n"

echo "Start year: ${startyear}"
echo "Start month: ${startmonth}"
echo "End year: ${endyear}"
echo "End month: ${endmonth}"
echo "Cores: ${cores}"
echo "Index: ${index}"
echo "Delete files: ${deletefiles}"
echo "Move source files: ${movefiles}"

# Parse the dates to figure out what year and month should be provided

workingyear=$startyear
workingmonth=$startmonth
finalyear=$workingyear
finalmonth=$workingmonth
iter=$index

while [[ "$iter" -gt 0 ]];do
  # Increment working month
  workingmonth=$((workingmonth + 1))

  # Test if working month rolls over, if so increment working year
  if [[ "$workingmonth" -gt 12 ]]; then
    workingyear=$((workingyear + 1))
    workingmonth=1
  fi

  # If working year is greater than end year
  if [[ "$workingyear" -gt "$endyear" ]]; then
    echo "Index beyond end date (${endyear}-${endmonth}), exiting!"
    exit 1
  fi

  # If working year is => the final year, check month
  if [[ "$workingyear" -ge "$endyear" ]]; then
    if [[ "$workingmonth" -gt "$endmonth" ]]; then
      echo "Index beyond end date (${endyear}-${endmonth}), exiting!"
      exit 1
    fi
  fi
  finalyear=$workingyear
  finalmonth=$workingmonth
  iter=$((iter - 1))
  # echo "Final = ${finalyear}-${finalmonth}, Working = ${workingyear}-${workingmonth}, Iter=${iter}"
done

printf -v finalmonth "%02d" $finalmonth
echo -e "\nRunning download for ${finalyear}-${finalmonth}"

# Make datapath

datapath="data/${finalyear}_${finalmonth}"

echo -e "\n=============== DOWNLOAD DATA ===============\n"

# Create array of desired climvars
desiredclimvars=(${desiredclimvars//,/ })

# If we really wanted to, we could take a set intersection between the desired and default variables to provide more sanity checking

requireddownloads=()

# Check if downloading is required
for climvar in ${desiredclimvars[@]}; do
    [ ! -e "${datapath}/cds-${climvar}.grib" ] && requireddownloads+=( $climvar )
done

# Download all the files that are not currently present
if [[ ${#requireddownloads[@]} -gt 0 ]]; then
  printf -v requireddownloads ' %s' "${requireddownloads[@]}"
  requireddownloads=${requireddownloads:1}
  echo "Files to download: $requireddownloads"
  python3 src/cds-era5-args.py -y "${finalyear}" -m "${finalmonth}" -c $requireddownloads -f
else
  echo "No files to download!"
fi

echo -e "\n=============== AVERAGE DATA ===============\n"

# Average every desired climvar
for climvar in ${desiredclimvars[@]}; do
    [ -e "${datapath}/cds-${climvar}.grib" ] && cdo daymean "${datapath}/cds-${climvar}.grib" "${datapath}/cds-${climvar}-dailymean.grib"
done

# archive the downloads somewhere or delete
if [[ $movefiles -eq 1 ]]; then
  echo "Moving source files to data/archive."
  mkdir -p data/archive

  for climvar in ${desiredclimvars[@]}; do
    [ -e "${datapath}/cds-${climvar}.grib" ] && mv "${datapath}/cds-${climvar}.grib" "data/archive/cds-${climvar}-${finalyear}-${finalmonth}.grib"
  done

elif [[ $deletefiles -eq 1 ]]; then
  echo "Deleting source files."

  for climvar in ${desiredclimvars[@]}; do
    [ -e "${datapath}/cds-${climvar}.grib" ] && rm "${datapath}/cds-${climvar}.grib"
  done

else
  echo "Leaving source files in-place."

fi

echo -e "\n=============== AGGREGATE DATA ===============\n"
# Construct list of desired climate vars for aggregation
printf -v desiredclimvars_str ',%s' "${desiredclimvars[@]}"
desiredclimvars_str=${desiredclimvars_str:1}
Rscript src/clean-cds-era5.R -y "${finalyear}" -m "${finalmonth}" -v "${desiredclimvars_str}", -c "${cores}" -f

echo -e "\n=============== RUN COMPLETE ===============\n"

end=`date +%s`
runtime=$((end-start))
# echo "Ran in ${runtime}s"
echo "Elapsed: $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec"
