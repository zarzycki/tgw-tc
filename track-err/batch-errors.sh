model_files=(
  "traj.Historical_time_cleaned.txt_final"
  "traj.cold_near_time_cleaned.txt_final"
  "traj.hot_near_time_cleaned.txt_final"
  "traj.cold_far_time_cleaned.txt_final"
  "traj.hot_far_time_cleaned.txt_final"
)

reference_file="traj.ibtracs.txt_final"

error_files=()

for track_file in "${model_files[@]}"; do
  this_error_file="errors_$track_file"
  error_files+=($this_error_file)
  ncl get-errors.ncl 'xfile="../trajs/'${reference_file}'"' 'yfile="../trajs/'${track_file}'"' 'outfile="./'$this_error_file'"'
  gsed -i "1i $track_file" "$this_error_file"
done

## Concatenate everything into a multi-column CSV

paste_command="paste -d ',' "
for error_file in "${error_files[@]}"; do
  paste_command+="$error_file "
done

paste_command+="> tk_errors_combined.csv"

eval $paste_command

python analyze-track-errors.py "tk_errors_combined.csv"
