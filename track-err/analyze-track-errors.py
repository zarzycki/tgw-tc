#!/usr/bin/env python
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import sys

if len(sys.argv) < 2:
    print("Usage: python analyze-track-errors.py filename.csv")
    sys.exit(1)

filename = sys.argv[1]  # Get the filename from command line arguments

data = pd.read_csv(filename)

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

# Set the style of the seaborn plot
sns.set(style="whitegrid")

# Plotting the density plots for each column
plt.figure(figsize=(10, 6))
for column in data.columns:
    #sns.kdeplot(data[column], label=column, fill=True, common_norm=False, alpha=0.4)
    sns.kdeplot(data[column], bw_adjust=0.7, label=column, fill=True, common_norm=False, alpha=0.4)

# Adding labels and title
plt.xlabel('Value')
plt.ylabel('Density')
plt.title('Probability Density Function of Each Variable')
plt.legend(title='Variable')

# Save the figure
plt.savefig('density_plot.png', dpi=300, bbox_inches='tight')