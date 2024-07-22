#!/bin/bash

##=======================================================================
#PBS -N tempest.par
#PBS -A P93300642
#PBS -l walltime=06:00:00
#PBS -q main
#PBS -j oe
#PBS -l select=1:ncpus=1:mpiprocs=1
################################################################

set -e

### Navigate to my script directly
cd ~/sw/tgw-tc/tempest

MPICOMMAND="mpiexec"

#module list
#module avail
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cray/pe/pmi/6.1.10/lib
#echo $LD_LIBRARY_PATH

############ USER OPTIONS #####################

## Unique string (useful for processing multiple data sets in same folder
UQSTR=CONUS_TGW_WRF_HISTORICAL

## Path to TempestExtremes binaries (I will maintain this)
TEMPESTEXTREMESDIR=/global/homes/p/paullric/tempestextremes/

### Where do we want to write files?
PATHTOFILES=$SCRATCH/tempest/composites/

### Where is the WRF data located
#AUXDIR=/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/historical_1980_2019/three_hourly/
AUXDIR=/pscratch/sd/c/czarzyck/temp/historical_1980_2019/

### What is the traj file from the WRF runs?
TRAJFILENAME=./cleaned/traj.Historical_time_cleaned.txt

#######################################################################################

# Get start time
starttime=$(date -u +"%s")
randomstr=$(date +%s%N)

mkdir -pv $PATHTOFILES

### Clean up if needed
rm -fv aux_file_list.txt
echo "Gathering aux files"
ls ${AUXDIR}/tgw_wrf*_1979-*.nc4 > aux_file_list.txt

variables="T1000,T925,T850,T700,T500,T400,T300,T250,T200,T150,T100,T70,"\
"Q1000,Q925,Q850,Q700,Q500,Q400,Q300,Q250,Q200,Q150,Q100,Q70,"\
"U1000,U925,U850,U700,U500,U400,U300,U250,U200,U150,U100,U70,"\
"V1000,V925,V850,V700,V500,V400,V300,V250,V200,V150,V100,V70,"\
"W1000,W925,W850,W700,W500,W400,W300,W250,W200,W150,W100,W70,"\
"SH2O_005,SH2O_150,"\
"SST,SSTSK,LH,HFX,U10,V10,OLR,PBLH,HGT,QFX,SFROFF"

## Here is an example of compositing the storms we masked off above into one big average using the filtered trajectory file as our list of which storms to composite.
echo "Compositing"
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux_file_list.txt --missingdata --var $variables --regional --max_time_delta "1h" --out_data "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots

# Convert comma-separated variables string into array
IFS=',' read -r -a variable_array <<< "$variables"

function ncattget { ncks --trd -M -m ${3} | grep -E -i "^${2} attribute [0-9]+: ${1}" | cut -f 11- -d ' ' | sort ; }

# Loop through each variable
for VAR in "${variable_array[@]}"; do
  NEWNAME="your_new_file_name_based_on_$VAR"  # Modify this as needed
  echo "Processing $VAR"
  FILLVALUE=$(ncattget _FillValue $VAR "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc" "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc")
  echo $FILLVALUE
  ncatted -O -h -a _FillValue,snap_$VAR,o,f,${FILLVALUE} "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc" "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc"
done

echo "Cleaning up!"
rm -fv aux_file_list.txt

## Print some timing stats
endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},extract_and_composite,${UQSTR}\n" >> timing.txt

## Gracefully exit the script
exit