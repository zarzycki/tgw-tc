#!/bin/bash -l

#SBATCH --qos=premium
#SBATCH --time=12:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=128
#SBATCH --constraint=cpu

module load parallel
conda activate e3sm_unified_1.8.1_nompi

#historical_1980_2019
#rcp85cooler_2020_2059
#rcp85cooler_2060_2099
#rcp85hotter_2020_2059
#rcp85hotter_2060_2099

CONFIG="rcp85cooler_2020_2059"
INDIR=/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/${CONFIG}/three_hourly/
OUTDIR=/pscratch/sd/c/czarzyck/temp/$CONFIG/
VARS="SST,SSTSK,LH,HFX,U10,V10,OLR,PBLH,HGT,QFX,SFROFF"
NUM_PROCS=40

mkdir -p ${OUTDIR}

export OUTDIR
export VARS

#---------------------------------------------------------------------------------

parallel_process() {
  f=$1
  echo $f
  NEWNAME=${OUTDIR}/$(basename $f)
  ZNAME=${OUTDIR}/_z_$(basename $f)
  NEWFILENC4="${NEWNAME%.nc}.nc4"
  echo $NEWFILENC4
  if [ ! -f "$NEWFILENC4" ]; then
    echo "File $NEWFILENC4 does not exist, processing..."
    time (
      rm -fv $NEWNAME $ZNAME
      ncl interp-Z.ncl 'fn="'$f'"' 'OUTDIR="'$OUTDIR'"'
      ncks -O -6 -F -d Time,1,-1,2 $ZNAME $ZNAME
      ncks -O -6 -F -d Time,1,-1,2 -v XTIME,XLAT,XLONG,${VARS} $f $NEWNAME
      ncks -A $ZNAME $NEWNAME
      rm -fv $ZNAME
      ncap2 -O -s 'XLAT=XLAT(0,:,:)' -s 'XLONG=XLONG(0,:,:)' $NEWNAME $NEWNAME
      start_date="1979-01-01 00:00:00"
      ncatted -a units,XTIME,o,c,'minutes since '"$start_date" $NEWNAME
      ncatted -a calendar,XTIME,o,c,'standard' $NEWNAME
      ncrename -O -d Time,time -v XTIME,time $NEWNAME $NEWNAME
      ncatted -O -h -a _FillValue,SST,o,f,-9999.9 $NEWNAME $NEWNAME
      ncatted -O -h -a _FillValue,SSTSK,o,f,-9999.9 $NEWNAME $NEWNAME
      ncap2 -O -s 'where(SST > 270) SST=SST; elsewhere SST=SST@_FillValue;' -s 'where(SSTSK > 270) SSTSK=SSTSK; elsewhere SSTSK=SSTSK@_FillValue;' $NEWNAME $NEWNAME
      ncks -O -4 -L 1 $NEWNAME $NEWFILENC4
      rm -rv $NEWNAME
    )
  else
    echo "File $NEWFILENC4 already exists, skipping processing."
  fi
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
