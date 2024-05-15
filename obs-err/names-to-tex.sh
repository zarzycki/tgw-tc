#!/bin/bash

ncolumns=3
input_file="storm_names.txt"
output_file="storm_names.tex"

rm -rf -v $output_file

# Function to write a table to the LaTeX file
write_table() {
  local caption=$1
  local columns=$2

  # Calculate column width as a fraction of the text width
  local column_width=$(awk "BEGIN {print 1.0/$columns}")

  # Generate the column format string for the LaTeX tabular environment
  local column_format=""
  for ((i=0; i<$columns; i++)); do
    column_format+="p{$column_width\textwidth}"
  done

  echo "\begin{table}[H]" >> $output_file
  echo "\centering" >> $output_file
  echo "\footnotesize" >> $output_file
  echo "\begin{tabular}{${column_format}}" >> $output_file

  count=0
  for entry in "${entries[@]}"; do
    echo -n "${entry}" >> $output_file
    count=$((count + 1))
    if [ $((count % $columns)) -eq 0 ]; then
      echo " \\\\" >> $output_file
      #echo "\hline" >> $output_file
    else
      echo " &" >> $output_file
    fi
  done

  # Close the last row if it isn't complete
  if [ $((count % $columns)) -ne 0 ]; then
    echo " \\\\" >> $output_file
    #echo "\hline" >> $output_file
  fi

  echo "\hline" >> $output_file
  echo "\end{tabular}" >> $output_file
  echo "\caption{${caption}}" >> $output_file
  echo "\end{table}" >> $output_file
}

# Read data and split into entries
entries=()
while IFS=$'\t' read -r name yyyy mm dd hh timesteps; do
  # Escape underscores in the name
  escaped_name=$(echo "$name" | sed 's/_/\\_/g')
  formatted_entry="${escaped_name}, ${hh}Z ${mm}/${dd}/${yyyy}, (${timesteps})"
  entries+=("${formatted_entry}")
done < $input_file

# Split the entries into two halves and write two tables
entries_part1=("${entries[@]:0:181}")
entries_part2=("${entries[@]:181}")

# Write the first table with a specific caption and 4 columns
entries=("${entries_part1[@]}")
write_table "1980-2002 analyzed storms. Each line contains the WMO storm name, track initiation time and date, and number of points along that storm's trajectory in the TGW runs." $ncolumns

# Page break between tables
echo "\newpage" >> $output_file

# Write the second table with a different caption and 3 columns
entries=("${entries_part2[@]}")
write_table "2003-2019 analyzed storms. Each line contains the WMO storm name, track initiation time and date, and number of points along that storm's trajectory in the TGW runs." $ncolumns
