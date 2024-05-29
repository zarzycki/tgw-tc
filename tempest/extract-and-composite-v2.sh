#!/bin/bash -l

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
cd /glade/u/home/$LOGNAME/sw/tgw-tc/tempest

## Where is NCL located?
NCLBIN=/glade/u/apps/derecho/23.06/spack/opt/spack/ncl/6.6.2/gcc/7.5.0/q5mj/bin/

MPICOMMAND="mpiexec"

#module list
#module avail
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cray/pe/pmi/6.1.10/lib
#echo $LD_LIBRARY_PATH

############ USER OPTIONS #####################

## Unique string (useful for processing multiple data sets in same folder
UQSTR=CONUS_TGW_WRF_SSP585_HOT_NEAR

## Path to TempestExtremes binaries (I will maintain this)
TEMPESTEXTREMESDIR=/glade/u/home/zarzycki/work/derecho/tempestextremes/

### Where do we want to write files?
PATHTOFILES=/glade/derecho/scratch/zarzycki/tempest/composites/

### Where is the WRF data located
TGWDIR=/glade/derecho/scratch/zarzycki/TGW
AUXDIR=${TGWDIR}/${UQSTR}/aux/
AUX2DIR=${TGWDIR}/${UQSTR}/aux2/
AUX3DIR=${TGWDIR}/${UQSTR}/PRECT_6h/

### What is the traj file from the WRF runs?
TRAJFILENAME=./cleaned/traj.hot_near_time_cleaned.txt

#######################################################################################

# Get start time
starttime=$(date -u +"%s")
randomstr=$(date +%s%N)

mkdir -pv $PATHTOFILES

### Clean up if needed
rm -fv aux_file_list.txt
rm -fv aux2_file_list.txt
rm -fv aux3_file_list.txt
echo "Gathering aux files"
ls ${AUXDIR}/wrfout_d01_????*.nc > aux_file_list.txt
echo "Gathering aux2 files"
ls ${AUX2DIR}/wrfout_d01_????*.nc > aux2_file_list.txt
echo "Gathering Precip files"
ls ${AUX3DIR}/wrfout_d01_????*.nc > aux3_file_list.txt

## What is the name of the final script we want to create?
FINALTRAJ=${TRAJFILENAME}_final

## This code adds dPSL to the track files using TRAJFILENAME (from get-wrf-tracks) and FINALTRAJ (traj needed for the composite code)
echo "Appending any other diags"
$NCLBIN/ncl append-stats.ncl 'thefile="'${TRAJFILENAME}'"' 'filename="'${FINALTRAJ}'"'

## Here is an example of compositing the storms we masked off above into one big average using the filtered trajectory file as our list of which storms to composite.
echo "Compositing"
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux_file_list.txt --missingdata --var "U10,V10,SLP,OLR,IVTE,IVTN" --regional --max_time_delta "2h" --out_data "${PATHTOFILES}/new_composite_aux_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux2_file_list.txt --missingdata --var "TMQ,U850,V850" --regional --max_time_delta "2h" --out_data "${PATHTOFILES}/new_composite_aux2_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots
${TEMPESTEXTREMESDIR}/bin/NodeFileCompose --in_nodefile ${TRAJFILENAME} --in_fmt "lon,lat,slp,wind" --in_data_list aux3_file_list.txt --missingdata --var "PRECT" --regional --max_time_delta "2h" --out_data "${PATHTOFILES}/new_composite_aux3_${UQSTR}.nc" --dx 0.1 --resx 100 --op "mean" --latname "XLAT" --lonname "XLONG" --snapshots

## Add rmw, wind@rmw, r8, ike to tempest files
echo "Calculating additional derived diagnostics with NFE"
${TEMPESTEXTREMESDIR}/bin/NodeFileEditor --in_data_list aux_file_list.txt  --in_nodefile ${FINALTRAJ}      --in_fmt "lon,lat,slp,wind,dps"                           --out_nodefile tmp1.${randomstr} --regional --latname "XLAT" --lonname "XLONG" --calculate "rprof=radial_wind_profile(U10,V10,50,0.1);r_max_az_wind=lastwhere(rprof,=,max);max_az_wind=value(rprof,r_max_az_wind)"  --out_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind"
${TEMPESTEXTREMESDIR}/bin/NodeFileEditor --in_data_list aux2_file_list.txt --in_nodefile tmp1.${randomstr} --in_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind" --out_nodefile tmp2.${randomstr} --regional --latname "XLAT" --lonname "XLONG" --calculate "rprof=radial_wind_profile(U850,V850,40,0.25);r8=lastwhere(rprof,>=,8.0);ike=eval_ike(U850,V850,5.0)"                    --out_fmt "lon,lat,slp,wind,dps,max_az_wind,r_max_az_wind,r8,ike"

## Overwrite intermediate ASCII tempest tracks with FINALTRAJ to be used in analysis code
mv -v tmp2.${randomstr} ${FINALTRAJ}

echo "Cleaning up!"
rm -fv aux_file_list.txt
rm -fv aux2_file_list.txt
rm -fv aux3_file_list.txt
rm -fv *${randomstr}

## Print some timing stats
endtime=$(date -u +"%s")
tottime=$(($endtime-$starttime))
printf "${tottime},extract_and_composite,${UQSTR}\n" >> timing.txt

## Gracefully exit the script
exit