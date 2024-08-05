import pandas as pd
import numpy as np
import sys

def get_arg(index):
    try:
        sys.argv[index]
    except IndexError:
        return ''
    else:
        return sys.argv[index]

land_or_ocean = get_arg(1)  # 'all', 'ocn', or 'lnd'

# Load the CSV file
csv_file = "stats/"+land_or_ocean+"/statistics_output.csv"
df = pd.read_csv(csv_file)

# Create an empty dictionary to store the formatted data
table_data = {}

# Define the parameters and their corresponding columns in the CSV
parameters = [
    ("Min. Sea Level Pressure", "xpres", "MSLP", "hPa"),
    ("Max. 10-m Wind", "xmax_wind10", "u10m,x", "m s⁻¹"),
    ("Storm Integrated Kinetic Energy", "xike", "IKE", "TJ"),
    ("Max. Total Precipitable Water", "xmax_tmq", "TPWx", "mm"),
    ("Max. Precipitation Rate", "xmax_prect", "Prec,x", "mm hr⁻¹"),
    ("Area Precipitation Rate > 10 mm hr⁻¹", "xgt10_prect", "Prec,area>10", "1000 km²"),
    ("Radius of 8 m s⁻¹ 850-hPa Wind", "xr8", "r8", "km"),
    ("Radius of Max. 10-m Wind", "xrmw", "RMW", "km"),
    ("6-hourly Sea Level Pressure Variation", "xvarpsl", "|dPSL|", "hPa 6hr⁻¹"),
    ("Sea Surface Temperature", "xsst", "SST", "K"),
]

datasets = ["Historical", "Cold Near", "Hot Near", "Cold Far", "Hot Far"]

# Loop through each parameter and extract the required statistics
for param_name, param, notation, unit in parameters:
    table_data[param_name] = {
        "notation": notation,
        "unit": unit,
        "mean": [],
        "percentile": []
    }
    for dataset in datasets:
        subset = df[(df["Variable"] == param) & (df["Dataset"] == dataset)]

        if param in ["xr8", "xrmw"]:  # Integer precision for radius values
            mean = int(round(subset["Mean"].values[0]))
            if param in ["xpres", "xrmw"]:  # Use 5th percentile for MSLP and RMW
                percentile = int(round(subset["5th Percentile"].values[0]))
            else:
                percentile = int(round(subset["95th Percentile"].values[0]))
        else:
            mean = round(subset["Mean"].values[0], 1)
            if param in ["xpres", "xrmw"]:  # Use 5th percentile for MSLP and RMW
                percentile = round(subset["5th Percentile"].values[0], 1)
            else:
                percentile = round(subset["95th Percentile"].values[0], 1)

        if dataset != "Historical":
            p_value = subset["P-value"].values[0]
            if p_value < 0.01:
                mean_str = f"<b><u>{mean}</u></b>"
            elif p_value < 0.05:
                mean_str = f"<b>{mean}</b>"
            elif p_value < 0.10:
                mean_str = f"<u>{mean}</u>"
            else:
                mean_str = f"{mean}"
        else:
            mean_str = f"{mean}"

        table_data[param_name]["mean"].append(mean_str)
        table_data[param_name]["percentile"].append(f"<i>({percentile})</i>")

# Create a DataFrame from the dictionary for better manipulation
mean_df = pd.DataFrame({param: data["mean"] for param, data in table_data.items()}, index=datasets).T
percentile_df = pd.DataFrame({param: data["percentile"] for param, data in table_data.items()}, index=datasets).T

# Combine mean and percentile data
combined_df = mean_df.copy()
for col in combined_df.columns:
    combined_df[col] = combined_df[col] + "<br>" + percentile_df[col]

# Add notation and unit columns
notations = pd.Series({param: data["notation"] for param, data in table_data.items()}, name="Notation")
units = pd.Series({param: data["unit"] for param, data in table_data.items()}, name="Unit")
combined_df.insert(0, "Notation", notations)
combined_df.insert(1, "Unit", units)

# Save to HTML with a style to center all cells
html = f"""
<html>
<head>
<style>
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ border: 1px solid black; text-align: center; padding: 8px; }}
    th {{ text-align: center; }}
</style>
</head>
<body>
{combined_df.to_html(escape=False, index=True)}
</body>
</html>
"""

# Write HTML to a file
out_file_name = "stats/"+land_or_ocean+"/generated_table.html"
with open(out_file_name, "w") as file:
    file.write(html)

print("Table saved as HTML.")
