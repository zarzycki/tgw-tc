#!/bin/bash -l

#PBS -l nodes=4:ppn=20
#PBS -l walltime=4:00:00
#PBS -A cmz5202_a_g_sc_default
#PBS -j oe
#PBS -N TE.get_traj

### Navigate to my script directly
cd /storage/home/${LOGNAME}/tempest-scripts/tgw/

### Load required modules
module purge
module load gcc/8.3.1
module load openmpi/3.1.6
module load netcdf/4.4.1

############ USER OPTIONS #####################

## Unique string (useful for processing multiple data sets in same folder
UQSTR=CONUS_TGW_WRF_SSP585_HOT_FAR

## Path to TempestExtremes binaries (I will maintain this)
TEMPESTEXTREMESDIR=/storage/home/cmz5202/sw/tempestextremes/

### Where do we want to write files?
SCRATCHDIR=~/scratch/tempest/tgw/

### Where is the WRF data located
AUXDIR=/gpfs/group/cmz5202/default/tpz5135/TGW/${UQSTR}/aux/

### What is the name of the IBTrACS reference file we are trying to match?
FILTNODE="2059_2100_ibtracs"

### What is the filename of the WRF tracks matched with IBTrACS?
TRAJFILENAME=trajectories.txt.${UQSTR}

#DN and SN settings
DCU_MERGEDIST=4.0
SN_TRAJRANGE=5.0
SN_TRAJMINTIME="12h"
SN_TRAJMAXGAP="12h"
SN_MINWIND=1.0
SN_MINLEN=2

######
# Get start time
starttime=$(date -u +"%s")

echo "Create some dirs"
mkdir -v -p ${SCRATCHDIR}

echo "Gathering precip files"
ls ${AUXDIR}/wrfout_d01_????*.nc > a_file_list.txt

echo "Create filtered files"
PRECIPFILES=`ls ${AUXDIR}/wrfout_d01_????*.nc`
for g in $PRECIPFILES
do
  filename=${g}
  just_filename=`basename $g`
  echo "$SCRATCHDIR/${just_filename}_5deg_filtered.nc" >> a_output_files.txt
done

echo "extract TC precip using a set radius of 3 GCD"
NCPU=80
mpirun --np ${NCPU} --hostfile $PBS_NODEFILE ${TEMPESTEXTREMESDIR}/bin/NodeFileFilter --in_nodefile ${FILTNODE} --in_fmt "lon,lat,pres,wind,phis" --in_data_list "a_file_list.txt" --out_data_list "a_output_files.txt" --bydist 3.0 --var "SLP,U10,V10,OLR" --preserve "XLAT,XLONG" --regional --fillvalue "-9999999.9" --maskvar "mask" --latname "XLAT" --lonname "XLONG"

echo "Cleaning up!"
rm -v log0*.txt
rm -v a_file_list.txt

#######

echo "Clean up some things before detect"
rm -v -rf DN_files/
mkdir -v -p DN_files

echo "Detect candiate cyclones"
NCPU=80
STRDETECT="--verbosity 0 --regional --timestride 2 --mergedist ${DCU_MERGEDIST} --searchbymin SLP --searchbythreshold >0 --outputcmd SLP,min,0;_VECMAG(U10,V10),max,2"
mpirun --np ${NCPU} --hostfile $PBS_NODEFILE ${TEMPESTEXTREMESDIR}/bin/DetectNodes --in_data_list "a_output_files.txt" --out "DN_files/out" --latname "XLAT" --lonname "XLONG" ${STRDETECT}
echo "... done detect"

cat DN_files/out* > wrfout_d01_DN.txt

echo "Stitch candidate cyclones together"
${TEMPESTEXTREMESDIR}/bin/StitchNodes --in_fmt "lon,lat,slp,wind" --range ${SN_TRAJRANGE} --mintime ${SN_TRAJMINTIME} --maxgap ${SN_TRAJMAXGAP} --in wrfout_d01_DN.txt --out ${TRAJFILENAME} --threshold "wind,>=,${SN_MINWIND},${SN_MINLEN}"
echo "... done stitch"

echo "Cleaning up!"
rm a_output_files.txt
rm -v log0*.txt
rm -v -rf DN_files
rm -v -rf wrfout_d01_DN.txt

## Print some timing stats
endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},get_wrf_tracks,${UQSTR}\n" >> timing.txt

exit

