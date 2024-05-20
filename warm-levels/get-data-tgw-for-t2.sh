#CASES=("historical_1980_2019" "rcp85cooler_2020_2059" "rcp85cooler_2060_2099" "rcp85hotter_2020_2059" "rcp85hotter_2060_2099")
### Loop over these cases, or just submit 5 versions of the script changing CASE each time. Extracts SST and T2 from the raw TGW WRF files.

CASE=rcp85hotter_2020_2059
TGWDIR=/global/homes/c/czarzyck/tgw-wrf-conus/${CASE}/three_hourly/
WRITEDIR=/pscratch/sd/c/czarzyck/TGW/

mkdir -p $WRITEDIR/$CASE

for f in $TGWDIR/*.nc ; do
  echo $f
  time ncks -v SST,T2 $f $WRITEDIR/$CASE/$(basename $f)
done
