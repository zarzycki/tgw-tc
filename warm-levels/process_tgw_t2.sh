#!/bin/bash

# Where are T2 files?
TGW_T2_BASEDIR="/pscratch/sd/c/czarzyck/TGW/"

declare -a dirs=("historical_1980_2019" "rcp85cooler_2020_2059" "rcp85hotter_2020_2059" "rcp85cooler_2060_2099" "rcp85hotter_2060_2099")
declare -a cases=("Historical" "Cold Near" "Hot Near" "Cold Far" "Hot Far")

# Create an empty CSV file
output_file="mean_t2_results.csv"
echo "CASENAME,mean_t2" > "$output_file"

for i in "${!dirs[@]}"; do
  dir="${dirs[i]}"
  casename="${cases[i]}"
  echo "Processing $dir with case name $casename"
  python calculate_mean_t2.py "$TGW_T2_BASEDIR" "$dir" "$casename" "$output_file"
done
