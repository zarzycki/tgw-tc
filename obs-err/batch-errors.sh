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

for var in "${error_vars[@]}"; do

  error_files=()

  echo "var: $var"
  for track_file in "${model_files[@]}"; do
    this_error_file="${var}_errors_${track_file}"
    error_files+=($this_error_file)
    ncl get-errors.ncl 'xfile="../trajs/'${reference_file}'"' 'yfile="../trajs/'${track_file}'"' 'outfile="./'$this_error_file'"' 'error_var="'${var}'"'
    gsed -i "1i $track_file" "$this_error_file"
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
mv -v density_plot.png plot_track_errors.png
python analyze-track-errors.py "psl_errors_combined.csv"
mv -v density_plot.png plot_psl_errors.png