# Notes

### Running jobs on Perlmutter

```
sbatch proc-data.sh historical_1980_2019
sbatch proc-data.sh rcp85cooler_2020_2059
sbatch proc-data.sh rcp85cooler_2060_2099
sbatch proc-data.sh rcp85hotter_2020_2059
sbatch proc-data.sh rcp85hotter_2060_2099

sbatch more-extract-and-composite.sh rcp85hotter_2020_2059
sbatch more-extract-and-composite.sh historical_1980_2019
sbatch more-extract-and-composite.sh rcp85cooler_2020_2059
sbatch more-extract-and-composite.sh rcp85cooler_2060_2099
sbatch more-extract-and-composite.sh rcp85hotter_2060_2099
```

### Tracking progress of NodeFileCompose

This code will grep for "Time" and print how many composites have been generated in the more-extract-and-composite.sh script.

```
for k in slurm-*; do
  echo $k ; cat $k | grep Time | wc -l
done
```

### Example script of pulling code from loop in proc-data for testing

This needs to be modified based on the most recent proc-data.sh script.

```
OUTDIR="/pscratch/sd/c/czarzyck/temp/"
f=/global/homes/c/czarzyck/TGW2/tgw-wrf-conus/historical_1980_2019/three_hourly//tgw_wrf_historical_three_hourly_1981-09-17_00_00_00.nc
VARS="SST,SSTSK,LH,HFX,U10,V10,OLR,PBLH,HGT,QFX,SFROFF,SH2O,SMOIS"

echo $f
NEWNAME=${OUTDIR}/$(basename $f)
ZNAME=${OUTDIR}/_z_$(basename $f)
echo $NEWNAME

## DO NCL

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
ncks -O -4 -L 1 $NEWNAME $NEWNAME
```