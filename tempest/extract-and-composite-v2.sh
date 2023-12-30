#!/bin/bash -l

#PBS -l nodes=4:ppn=20
#PBS -l walltime=23:00:00
#PBS -A cmz5202_a_g_sc_default
#PBS -j oe
#PBS -N TE.extract

set -e

### Navigate to my script directly
cd /storage/home/${LOGNAME}/tempest-scripts/tgw/

### Load required modules
module purge
module load gcc/8.3.1
module load openmpi/3.1.6
module load netcdf/4.4.1
NCLBIN=/storage/work/cmz5202/sw/miniconda3/bin/

############ USER OPTIONS #####################

### This is useful if you are running on a Macbook, where this command is "gsed"
THISSED="sed"

## Unique string (useful for processing multiple data sets in same folder
UQSTR=CONUS_TGW_WRF_Historical

## Path to TempestExtremes binaries (I will maintain this)
TEMPESTEXTREMESDIR=/storage/home/cmz5202/sw/tempestextremes/

### Where do we want to write files?
PATHTOFILES=/storage/home/tpz5135/tempest-scripts/tgw/

### Where is the WRF data located
AUXDIR=/gpfs/group/cmz5202/default/tpz5135/TGW/${UQSTR}/aux/
AUX2DIR=/gpfs/group/cmz5202/default/tpz5135/TGW/${UQSTR}/aux2/
AUX3DIR=/gpfs/group/cmz5202/default/tpz5135/TGW/${UQSTR}/PRECT_6h/
### What is the traj file from the WRF runs?
TRAJFILENAME=traj.Historical_time_cleaned.txt

# Get start time
starttime=$(date -u +"%s")
randomstr=$(date +%s%N)

### Clean up if needed
rm -fv aux_file_list.txt
rm -fv aux2_file_list.txt
rm -fv aux3_file_list.txt
echo "Gathering aux files"
ls ${AUXDIR}/wrfout_d01_????*.nc > aux_file_list.txt
echo "Gathering aux2 files"
ls ${AUX2DIR}/wrfout_d01_????*.nc > aux2_file_list.txt
echo "Gathering Pre files"
ls ${AUX3DIR}/wrfout_d01_????*.nc > aux3_file_list.txt

rm -fv filt_output_files.txt
echo "Create filtered files"
PRECIPFILES=`ls ${AUXDIR}/wrfout_d01_????*.nc`
for g in $PRECIPFILES
do
  filename=${g}
  just_filename=`basename $g`
  echo "${PATHTOFILES}/${just_filename}_filtered.nc" >> filt_output_files.txt
done

FINALTRAJ=${TRAJFILENAME}_final

echo "Appending any other diags"
$NCLBIN/ncl append-stats.ncl 'thefile="'${TRAJFILENAME}'"' 'filename="'${FINALTRAJ}'"'

## First, we want to take the trajectory file, take the WRF files, and mask off grid cells *beyond* 5deg of a TC center point defined by the trajectory.
echo "extracting TC precip using a set radius of 3 GCD"
NCPU=80
mpirun --np ${NCPU} --hostfile $PBS_NODEFILE ${TEMPESTEXTREMESDIR}/bin/NodeFileFilter --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list "aux_file_list.txt" --out_data_list "filt_output_files.txt" --bydist 5.0 --var "IVTE,IVTN,T200,SLP,U10,V10,OLR" --preserve "XLAT,XLONG" --regional --fillvalue "-9999999.9" --maskvar "mask" --latname "XLAT" --lonname "XLONG"
rm -fv log0*.txt

## Here is an example of taking the trajectory file and getting a subfile out that *only* includes TCs with SLP < 965mb
#echo "Filter strong cyclones"
#singlefile=`head -1 filt_output_files.txt`
#${TEMPESTEXTREMESDIR}/bin/NodeFileEditor --in_nodefile ${TRAJFILENAME} --in_data ${singlefile} --in_fmt "lon,lat,slp,wind" --out_nodefile ${TRAJFILENAME}_strong.txt --out_fmt "lon,lat,slp,wind" --colfilter "slp,<=,965." --latname "XLAT" --lonname "XLONG"

## Here is an example of creating a simple histogram map with 5x5deg grid boxes of the strong TC track density
#echo "Create a density map of all intense storms"
#${TEMPESTEXTREMESDIR}/bin/HistogramNodes --in ${TRAJFILENAME}_strong.txt --nlat 36 --nlon 72 --iloncol 3 --ilatcol 4 --lon_begin -180.0 --lon_end 180.0 --out "${PATHTOFILES}/density_${UQSTR}.nc"

## Here is an example of compositing the storms we masked off above into one big average using the filtered trajectory file as our list of which storms to composite.
echo "Compositing"
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux_file_list.txt --missingdata --var "U10,V10,SLP,OLR,IVTE,IVTN" --regional --max_time_delta "2h" --out_data "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux2_file_list.txt --missingdata --var "TMQ,U850,V850" --regional --max_time_delta "2h" --out_data "${PATHTOFILES}/new_composite1_aux2_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux3_file_list.txt --missingdata --var "PRECT" --regional --max_time_delta "2h" --out_data "{PATHTOFILES}/new_composite_aux3_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots

##
echo "Calculating diagnostics with NFE"
${TEMPESTEXTREMESDIR}/bin/NodeFileEditor --in_data_list aux_file_list.txt  --in_nodefile ${FINALTRAJ}      --in_fmt "lon,lat,slp,wind,dps"                           --out_nodefile tmp1.${randomstr} --regional --latname "XLAT" --lonname "XLONG" --calculate "rprof=radial_wind_profile(U10,V10,50,0.1);r_max_az_wind=lastwhere(rprof,=,max);max_az_wind=value(rprof,r_max_az_wind)"   --out_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind"
${TEMPESTEXTREMESDIR}/bin/NodeFileEditor --in_data_list aux2_file_list.txt --in_nodefile tmp1.${randomstr} --in_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind" --out_nodefile tmp2.${randomstr}  --regional --latname "XLAT" --lonname "XLONG" --calculate "rprof=radial_wind_profile(U850,V850,40,0.25);r8=lastwhere(rprof,>=,8.0);ike=eval_ike(U850,V850,5.0)"                    --out_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind,r8,ike"

mv -v tmp2.${randomstr} ${FINALTRAJ}

echo "Cleaning up!"
rm -fv aux_file_list.txt
rm -fv aux2_file_list.txt
rm -fv aux3_file_list.txt
rm -fv filt_output_files.txt
rm -fv *${randomstr}

## Print some timing stats
endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},extract_and_composite,${UQSTR}\n" >> timing.txt

## Gracefully exit the script
exit

