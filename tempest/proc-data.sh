#!/bin/bash -l

#SBATCH --qos=premium
#SBATCH --time=06:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --constraint=cpu

module load parallel

#historical_1980_2019
#rcp85cooler_2020_2059
#rcp85cooler_2060_2099
#rcp85hotter_2020_2059
#rcp85hotter_2060_2099

CONFIG="historical_1980_2019"
INDIR=/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/${CONFIG}/three_hourly/
OUTDIR=/pscratch/sd/c/czarzyck/temp/$CONFIG/
VARS="SST,LH,HFX,U10,V10,OLR,PBLH,HGT"
NUM_PROCS=62

mkdir -p ${OUTDIR}

export OUTDIR
export VARS

#---------------------------------------------------------------------------------

parallel_process() {
  f=$1
  echo $f
  NEWNAME=${OUTDIR}/$(basename $f)
  echo $NEWNAME
  ncks -O -6 -F -d Time,1,-1,2 -v XLAT,XLONG,${VARS} $f $NEWNAME
  ncap2 -O -s 'XLAT=XLAT(0,:,:)' -s 'XLONG=XLONG(0,:,:)' $NEWNAME $NEWNAME
  start_date="1979-01-01 00:00:00"
  ncatted -a units,XTIME,o,c,'minutes since '"$start_date" $NEWNAME
  ncatted -a calendar,XTIME,o,c,'standard' $NEWNAME
  ncrename -O -d Time,time -v XTIME,time $NEWNAME $NEWNAME
  ncatted -O -h -a _FillValue,SST,o,f,-9999.9 $NEWNAME $NEWNAME
  ncap2 -O -s 'where(SST > 270) SST=SST; elsewhere SST=SST@_FillValue;' $NEWNAME $NEWNAME
  #ncks -O -4 -L 1 $NEWNAME $NEWNAME
}
export -f parallel_process

#---------------------------------------------------------------------------------

case $CONFIG in
  historical_1980_2019)
    INDIR2="/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/spinup_files/historical/three_hourly/"
    find ${INDIR2} -name 'tgw_wrf_*_three_hourly_*.nc' | parallel -j $NUM_PROCS parallel_process
    ;;
  rcp85cooler_2020_2059)
    INDIR2="/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/spinup_files/rcp85cooler/three_hourly/"
    find ${INDIR2} -name 'tgw_wrf_*_three_hourly_2019*.nc' | parallel -j $NUM_PROCS parallel_process
    ;;
  rcp85cooler_2060_2099)
    INDIR2="/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/spinup_files/rcp85cooler/three_hourly/"
    find ${INDIR2} -name 'tgw_wrf_*_three_hourly_2059*.nc' | parallel -j $NUM_PROCS parallel_process
    ;;
  rcp85hotter_2020_2059)
    INDIR2="/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/spinup_files/rcp85hotter/three_hourly/"
    find ${INDIR2} -name 'tgw_wrf_*_three_hourly_2019*.nc' | parallel -j $NUM_PROCS parallel_process
    ;;
  rcp85hotter_2060_2099)
    INDIR2="/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/spinup_files/rcp85hotter/three_hourly/"
    find ${INDIR2} -name 'tgw_wrf_*_three_hourly_2059*.nc' | parallel -j $NUM_PROCS parallel_process
    ;;
  *)
    echo "Unknown configuration: $CONFIG"
    exit 1
    ;;
esac

find ${INDIR} -name 'tgw_wrf_*_three_hourly_*.nc' | parallel -j $NUM_PROCS parallel_process
