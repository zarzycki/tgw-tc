model_files=(
  "traj.Historical_time_cleaned.txt_final"
  "traj.cold_near_time_cleaned.txt_final"
  "traj.hot_near_time_cleaned.txt_final"
  "traj.cold_far_time_cleaned.txt_final"
  "traj.hot_far_time_cleaned.txt_final"
)

reference_file="traj.ibtracs.txt_final"

error_vars=(
  "track"
  "psl"
  "wind"
)

if command -v gsed >/dev/null 2>&1; then
  sed_cmd="gsed"
else
  sed_cmd="sed"
fi

for var in "${error_vars[@]}"; do

  error_files=()

  echo "var: $var"
  for track_file in "${model_files[@]}"; do
    this_error_file="${var}_errors_${track_file}"
    error_files+=($this_error_file)

    if [ "$track_file" == "traj.Historical_time_cleaned.txt_final" ] && [ "$var" == "wind" ]; then
      plot_pw="True"
    else
      plot_pw="False"
    fi

    ncl get-errors.ncl 'xfile="../trajs/'${reference_file}'"' 'yfile="../trajs/'${track_file}'"' 'outfile="./'$this_error_file'"' 'error_var="'${var}'"' 'plot_pw='${plot_pw}
    $sed_cmd -i "1i $track_file" "$this_error_file"

  done

  ## Concatenate everything into a multi-column CSV

  paste_command="paste -d ',' "
  for error_file in "${error_files[@]}"; do
    paste_command+="$error_file "
  done

  paste_command+="> ${var}_errors_combined.csv"

  eval $paste_command

  for error_file in "${error_files[@]}"; do
    rm -v -rf "$error_file"
  done

done

python analyze-track-errors.py "track_errors_combined.csv"
mv -v output_statistics.csv stats_track_err.csv
python analyze-track-errors.py "psl_errors_combined.csv"
mv -v output_statistics.csv stats_psl_err.csv
python analyze-track-errors.py "wind_errors_combined.csv"
mv -v output_statistics.csv stats_wind_err.csv
