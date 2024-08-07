#!/usr/bin/env python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import numpy as np
import sys

if len(sys.argv) < 2:
    print("Usage: python analyze-track-errors.py filename.csv")
    sys.exit(1)

filename = sys.argv[1]  # Get the filename from command line arguments

# Determine the plot title and axis labels based on the filename
if "psl_errors_combined" in filename:
    x_label = 'Pressure Bias (hPa)'
    plot_title = 'Pressure Bias Distribution in Historical'
    plot_color = 'red'
    filename_suffix = 'psl'
elif "track_errors_combined" in filename:
    x_label = 'Track Error (km)'
    plot_title = 'Track Error Distribution in Historical'
    plot_color = 'black'
    filename_suffix = 'track'
elif "wind_errors_combined" in filename:
    x_label = 'Wind Speed Bias (m/s)'
    plot_title = 'Wind Speed Bias Distribution in Historical'
    plot_color = 'blue'
    filename_suffix = 'wind'
else:
    x_label = 'Value'
    plot_title = 'Probability Density Function'
    plot_color = 'green'
    filename_suffix = 'XXX'

data = pd.read_csv(filename)

# Replace values <= -9000 with NaN
data[data <= -9000] = np.nan

stats = {
    'Mean': data.mean(),
    'Median': data.median(),
    'Min': data.min(),
    'Max': data.max(),
    '5% Percentile': data.quantile(0.05),
    '95% Percentile': data.quantile(0.95)
}

# Print the statistics for each column
for stat_name, stat_values in stats.items():
    print(f"{stat_name}:\n{stat_values}\n")

# Prepare the statistics for CSV output
output_data = {
    'min': stats['Min'],
    '5th': stats['5% Percentile'],
    'median': stats['Median'],
    'mean': stats['Mean'],
    '95th': stats['95% Percentile'],
    'max': stats['Max']
}

# Convert to DataFrame
output_df = pd.DataFrame(output_data)

# Write to CSV
output_df.to_csv('output_statistics.csv', index_label='Column')

# Set the style of the seaborn plot
sns.set(style="whitegrid")

# Plotting the density plots for each column
plt.figure(figsize=(10, 6))
for column in data.columns:
    #sns.kdeplot(data[column], label=column, fill=True, common_norm=False, alpha=0.4)
    sns.kdeplot(data[column], bw_adjust=0.9, label=column, fill=True, common_norm=False, alpha=0.2)

# Adding labels and title
plt.xlabel('Value')
plt.ylabel('Density')
plt.title('Probability Density Function of Each Variable')
plt.legend(title='Variable')

# Save the figure
plt.savefig(f'density_bias_{filename_suffix}_ALL.png', dpi=300, bbox_inches='tight')

### NEW

# Plotting the density plot for only the first column
plt.figure(figsize=(10, 6))

# Extract the first column's name
first_column_name = data.columns[0]

# Plot the density plot for the first column without a legend
sns.kdeplot(data[first_column_name], bw_adjust=0.9, fill=True, common_norm=False, alpha=0.2, color=plot_color)

# Adding labels and title
plt.xlabel(x_label)
plt.ylabel('Density')
plt.title(plot_title)

# Save the figure without a legend
plt.savefig(f'density_bias_{filename_suffix}_hist.png', dpi=300, bbox_inches='tight')
plt.close()