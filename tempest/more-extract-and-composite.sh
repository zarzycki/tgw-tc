#!/bin/bash

#SBATCH --qos=shared
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --constraint=cpu
#
set -e

### Navigate to my script directly
cd ~/sw/tgw-tc/tempest

#historical_1980_2019
#rcp85cooler_2020_2059
#rcp85cooler_2060_2099
#rcp85hotter_2020_2059
#rcp85hotter_2060_2099

############ USER OPTIONS #####################

## Unique string (useful for processing multiple data sets in same folder
CONFIG=$1

## Path to TempestExtremes binaries (I will maintain this)
TEMPESTEXTREMESDIR=/global/homes/p/paullric/tempestextremes/

## Where do we want to write files?
PATHTOFILES=$SCRATCH/tempest/composites/

## Where is the WRF data located
AUXDIR=/pscratch/sd/c/czarzyck/temp/$CONFIG/

### What is the traj file from the WRF runs?
case $CONFIG in
  historical_1980_2019)
    TRAJFILENAME=./cleaned/traj.Historical_time_cleaned.txt
    MATCHINGNAME="Historical"
    ;;
  rcp85cooler_2020_2059)
    TRAJFILENAME=./cleaned/traj.cold_near_time_cleaned.txt
    MATCHINGNAME="SSP585_COLD_NEAR"
    ;;
  rcp85cooler_2060_2099)
    TRAJFILENAME=./cleaned/traj.cold_far_time_cleaned.txt
    MATCHINGNAME="SSP585_COLD_FAR"
    ;;
  rcp85hotter_2020_2059)
    TRAJFILENAME=./cleaned/traj.hot_near_time_cleaned.txt
    MATCHINGNAME="SSP585_HOT_NEAR"
    ;;
  rcp85hotter_2060_2099)
    TRAJFILENAME=./cleaned/traj.hot_far_time_cleaned.txt
    MATCHINGNAME="SSP585_HOT_FAR"
    ;;
  *)
    echo "Unknown configuration: $CONFIG"
    exit 1
    ;;
esac

#######################################################################################

# Get start time
starttime=$(date -u +"%s")
randomstr=$(date +%s%N)

mkdir -pv $PATHTOFILES

### Clean up if needed
AUXLIST=aux_${CONFIG}.txt
rm -fv $AUXLIST
echo "Gathering aux files"
ls ${AUXDIR}/tgw_wrf*_????-*.nc4 > $AUXLIST

variables="T1000,T925,T850,T700,T500,T400,T300,T250,T200,T150,T100,T70,"\
"Q1000,Q925,Q850,Q700,Q500,Q400,Q300,Q250,Q200,Q150,Q100,Q70,"\
"U1000,U925,U850,U700,U500,U400,U300,U250,U200,U150,U100,U70,"\
"V1000,V925,V850,V700,V500,V400,V300,V250,V200,V150,V100,V70,"\
"W1000,W925,W850,W700,W500,W400,W300,W250,W200,W150,W100,W70,"\
"Z1000,Z925,Z850,Z700,Z500,Z400,Z300,Z250,Z200,Z150,Z100,Z70,"\
"SH2O_005,SH2O_150,"\
"SST,SSTSK,LH,HFX,OLR,PBLH,HGT,QFX,SFROFF"

COMPOSITEFILE="${PATHTOFILES}/composite_aux3_CONUS_TGW_WRF_${MATCHINGNAME}.nc"
## Here is an example of compositing the storms we masked off above into one big average using the filtered trajectory file as our list of which storms to composite.
echo "Compositing"
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list $AUXLIST --missingdata --var $variables --regional --max_time_delta "2h" --out_data "$COMPOSITEFILE" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots

# Convert comma-separated variables string into array
IFS=',' read -r -a variable_array <<< "$variables"

function ncattget { ncks --trd -M -m ${3} | grep -E -i "^${2} attribute [0-9]+: ${1}" | cut -f 11- -d ' ' | sort ; }

# Loop through each variable
for VAR in "${variable_array[@]}"; do
  echo "Processing $VAR"
  FILLVALUE=$(ncattget _FillValue $VAR "$COMPOSITEFILE" "$COMPOSITEFILE")
  echo $FILLVALUE
  ncatted -O -h -a _FillValue,snap_$VAR,o,f,${FILLVALUE} "$COMPOSITEFILE" "$COMPOSITEFILE"
done

echo "Compressing to nc4"
ncks -O -4 -L 1 "$COMPOSITEFILE" "$COMPOSITEFILE"

echo "Cleaning up!"
rm -fv $AUXLIST

## Print some timing stats
endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},extract_and_composite,${CONFIG}\n" >> timing.txt

## Gracefully exit the script
exit
