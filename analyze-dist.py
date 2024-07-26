import sys
import numpy as np
import xarray as xr
from scipy import stats
import matplotlib.pyplot as plt
import matplotlib.lines as mlines
import csv
import os
import seaborn as sns
import pandas as pd
from seaborn import diverging_palette
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import cartopy.io.shapereader as shpreader
from shapely.geometry import Point
from shapely.prepared import prep
from shapely.ops import unary_union

sys.path.insert(0, './functions')
from getTrajectories import *

def get_arg(index):
    try:
        sys.argv[index]
    except IndexError:
        return ''
    else:
        return sys.argv[index]

# Process trajectory files
def process_trajectory_files(file_list, n_vars, header_str, is_unstructured, mask_min_slp, mask_max_slp):
    data_collection = {
        'xlon': [], 'xlat': [], 'xpres': [], 'xwind': [], 'xdpsl': [],
        'xurmw': [], 'xrmw': [], 'xr8': [], 'xike': [], 'xslp': [],
        'xmax_wind10': [], 'xmax_wind850': [], 'xmax_prect': [], 'xgt10_prect': [],
        'xmax_tmq': [], 'xgt8_wind10': [], 'xgt10_wind850': [], 'xphis': [], 'xsst': [],
        'xyear': [], 'xmonth': [], 'xday': [], 'xhour': []
    }

    index_mapping = {
        'xlon': 2, 'xlat': 3, 'xpres': 4, 'xwind': 5, 'xdpsl': 6,
        'xurmw': 7, 'xrmw': 8, 'xr8': 9, 'xike': 10, 'xslp': 11,
        'xmax_wind10': 12, 'xmax_wind850': 13, 'xmax_prect': 14, 'xgt10_prect': 15,
        'xmax_tmq': 16, 'xgt8_wind10': 17, 'xgt10_wind850': 18, 'xphis': 19, 'xsst': 20,
        'xyear': 21, 'xmonth': 22, 'xday': 23, 'xhour': 24
    }

    iterate = 0

    for file in file_list:
        nstorms, ntimes, ncol, traj_data = getTrajectories(file, n_vars, header_str, is_unstructured)

        # Note, this correctly masks all NaNs and flattens the array to 1-D
        if iterate == 0:
            slpmask = (traj_data[4,:,:] > mask_min_slp) & (traj_data[4,:,:] <= mask_max_slp)

        for key, index in index_mapping.items():
            data_collection[key].append(traj_data[index,:,:][slpmask])

        # This *doesn't* flatten arrays and appends 2D (nstorms x ntimes)
        #for key, index in index_mapping.items():
        #    print(traj_data[index,:,:].shape)
        #    data_collection[key].append(traj_data[index,:,:])

        iterate = iterate + 1

    return data_collection

def apply_conversion_to_key(processed_data, key, conversion_factor):
    num_files = len(processed_data[key])
    for i in range(num_files):
        processed_data[key][i] = processed_data[key][i] * conversion_factor

def apply_nan_filter_to_keys(processed_data, key, threshold, condition):
    """
    Apply a NaN filter to the specified key in processed_data based on a threshold.

    Parameters:
        processed_data (dict): Dictionary containing numerical data arrays.
        key (str): The key for which the NaN filter should be applied.
        threshold (float): The numerical threshold for the filter.
        condition (str): The condition for filtering ('>' or '<').

    Returns:
        None: The function modifies the processed_data in-place.
    """
    num_files = len(processed_data[key])
    for i in range(num_files):
        if condition == '>':
            processed_data[key][i] = np.where(processed_data[key][i] > threshold, np.nan, processed_data[key][i])
        elif condition == '<':
            processed_data[key][i] = np.where(processed_data[key][i] < threshold, np.nan, processed_data[key][i])
        else:
            raise ValueError("Condition must be '>' or '<'")

def synchronize_and_diagnose_nans(processed_data, key):
    num_files = len(processed_data[key])

    # Diagnostic: Store the initial state (copy) of the first dataset for comparison
    initial_state_first_dataset = np.copy(processed_data[key][0])

    # Count NaNs in the initial state of the first dataset
    initial_nan_count = np.count_nonzero(np.isnan(initial_state_first_dataset))
    print(f"Initial number of NaNs in the first dataset for '{key}': {initial_nan_count}")

    # Iterate over each row index
    for i in range(num_files):
        # Find the indices where any dataset has NaN at a specific index
        nan_indices = np.any([np.isnan(processed_data[key][j]) for j in range(num_files)], axis=0)

        # Set all values to NaN at these indices for each dataset
        for j in range(num_files):
            processed_data[key][j][nan_indices] = np.nan

    # Count NaNs in the first dataset after processing
    final_nan_count = np.count_nonzero(np.isnan(processed_data[key][0]))
    print(f"Final number of NaNs in the first dataset for '{key}': {final_nan_count}")

    # Diagnostic: Check where NaNs were added
    for i in range(num_files):
        added_nans = np.isnan(processed_data[key][i]) & ~np.isnan(initial_state_first_dataset)
        added_nan_indices = np.where(added_nans)[0]
        #if added_nan_indices.size > 0:
        #    print(f"Dataset {i+1} for '{key}' - Added NaNs at indices: {added_nan_indices}")
        #else:
        #    print(f"Dataset {i+1} for '{key}' - No NaNs added.")

def calculate_and_print_statistics(processed_data, list_names, case_names, filter_config='all'):
    results = []

    for list_name in list_names:
        data_list = processed_data[list_name]

        # Extract and prepare the control data (first element)
        control_data = data_list[0].flatten()
        control_data = control_data[~np.isnan(control_data)]

        for i, data in enumerate(data_list):
            # Flatten the data to ensure it's in 1D for calculations
            flattened_data = data.flatten()

            # Filter out NaNs
            filtered_data = flattened_data[~np.isnan(flattened_data)]

            # Calculate statistics
            mean_value = np.nanmean(filtered_data)
            percentile_5th = np.nanpercentile(filtered_data, 5)
            percentile_95th = np.nanpercentile(filtered_data, 95)
            median_value = np.nanmedian(filtered_data)
            data_range = np.nan if filtered_data.size == 0 else np.nanmax(filtered_data) - np.nanmin(filtered_data)
            t_stat, p_val = (np.nan, np.nan) if i == 0 else stats.ttest_ind(control_data, filtered_data, nan_policy='omit', equal_var=False)

            # Store results
            result = {
                'Variable': list_name,
                'Dataset': case_names[i],
                'Mean': mean_value,
                '5th Percentile': percentile_5th,
                '95th Percentile': percentile_95th,
                'Median': median_value,
                'Range': data_range,
                'T-Statistic': t_stat,
                'P-value': p_val
            }
            results.append(result)

            # Print the results
            print(f"{list_name} {case_names[i]}: Mean = {mean_value:.2f}, 5th Percentile = {percentile_5th:.2f}, 95th Percentile = {percentile_95th:.2f}, Median = {median_value:.2f}, Range = {data_range:.2f}")
            if i != 0:
                print(f"    T-Statistic = {t_stat:.3f}, P-value = {p_val:.3f}")

    stats_dir = "stats"
    stats_subfolder = os.path.join(stats_dir, filter_config)
    os.makedirs(stats_subfolder, exist_ok=True)

    # Write results to a CSV file
    csv_filename = os.path.join(stats_subfolder, 'statistics_output.csv')
    with open(csv_filename, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=results[0].keys())
        writer.writeheader()
        for data in results:
            writer.writerow(data)

    print(f"Statistics written to {csv_filename}")

def snapshot_percent_increase(processed_data, list_names):
    results = {}

    for list_name in list_names:
        data_list = processed_data[list_name]

        reference = data_list[0].flatten()  # Flatten the reference array
        reference = reference[~np.isnan(reference)]  # Filter out NaNs from the reference
        percentages = []

        for i in range(1, len(data_list)):  # Start from the second index
            current_data = data_list[i].flatten()  # Flatten the current data array
            current_data = current_data[~np.isnan(current_data)]  # Filter out NaNs from current data

            # Ensure arrays are compatible in size
            if len(current_data) == len(reference):
                # Count how many times current data is greater than the reference
                count_greater = np.sum(current_data > reference)
                # Calculate the percentage
                percentage = (count_greater / len(reference)) * 100
                # Flip xpres ordering for sanity (lower pressure means "increase")
                if list_name == "xslp" or list_name == "xpres":
                    percentage = 100 - percentage
                percentages.append(percentage)
            else:
                percentages.append(np.nan)  # Append NaN if sizes are different

        results[list_name] = [round(p) for p in percentages]  # Store results rounded to the nearest integer

    return results

def plot_histograms(processed_data, key, title, units, legend_names, save_figs, subfolder=''):
    data_list = processed_data[key]

    # Find the overall minimum and maximum values across all datasets
    overall_min = min(np.nanmin(data.flatten()) for data in data_list)
    overall_max = max(np.nanmax(data.flatten()) for data in data_list)

    # Set up the figure and axes
    plt.figure(figsize=(11, 6))

    # Loop over each dataset in the data list and plot a line for the histogram
    for i, mydata in enumerate(data_list):
        counts, bin_edges = np.histogram(mydata.flatten(), bins=20, range=(overall_min, overall_max), density=False)
        counts = counts / counts.sum()  # Normalize counts to make the integral equal to 1
        bin_centers = 0.5 * (bin_edges[:-1] + bin_edges[1:])  # Calculate bin centers
        label = legend_names[i] if i < len(legend_names) else f'Dataset {i+1}'
        plt.plot(bin_centers, counts, label=label, linewidth=2)

    # Customize the plot
    plt.title(f'{title} distributions', fontsize=15)
    plt.xlabel(f'{title} ({units})', fontsize=14)
    plt.ylabel('Fraction', fontsize=14)
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)
    plt.legend(fontsize=14)

    if save_figs:
        filename = os.path.join(subfolder, f"{key}_distribution.pdf")
        plt.savefig(filename, bbox_inches='tight')
        plt.close()
    else:
        plt.show()

def plot_histograms_with_control_deviation(processed_data, key, title, units, legend_names, save_figs, subfolder=''):
    data_list = processed_data[key]
    control_data = data_list[0].flatten()  # Control dataset

    # Determine the overall minimum and maximum deviation values across all datasets
    deviations = [data.flatten() - control_data for data in data_list[1:]]  # Skip the first (control)
    overall_min = min(np.nanmin(dev) for dev in deviations)
    overall_max = max(np.nanmax(dev) for dev in deviations)

    # Determine bin width and create bin edges with 0 centered
    num_bins = 21
    bin_width = max(abs(overall_max), abs(overall_min)) / (num_bins / 2)
    bin_edges = np.arange(-bin_width * (num_bins / 2), bin_width * (num_bins / 2) + bin_width, bin_width)

    # Set up the figure and axes for deviation histograms
    plt.figure(figsize=(11, 6))

    # Loop over each deviation dataset and plot a histogram
    for i, deviation_data in enumerate(deviations):
        counts, _ = np.histogram(deviation_data, bins=bin_edges, density=False)
        counts = counts / counts.sum()  # Normalize counts to make the integral equal to 1
        plt.step(bin_edges[:-1], counts, where='post', label=legend_names[i+1] if i+1 < len(legend_names) else f'Dataset {i+2}', linewidth=2)

    # Add a dashed vertical line at 0 for reference
    plt.axvline(x=0, color='gray', linestyle='--')

    # Customize the plot
    plt.title(f'Deviation from Hist.: {title} distributions', fontsize=15)
    plt.xlabel(f'Deviation in {title} ({units})', fontsize=14)
    plt.ylabel('Fraction', fontsize=14)
    plt.xticks(fontsize=14)
    plt.yticks(fontsize=14)
    plt.legend(fontsize=14)

    # Set the y-axis precision format
    plt.gca().yaxis.set_major_formatter(plt.FuncFormatter(lambda x, _: f'{x:.1f}'))

    # Set the x-axis limits to prevent overhang
    REDUCTION_FACTOR=0.975   # Smaller REDUCTION_FACTOR means more aggressive adjustment
    plt.xlim(bin_edges[0], bin_edges[-1] - bin_width / REDUCTION_FACTOR)

    if save_figs:
        filename = os.path.join(subfolder, f"{key}_deviation_from_control.pdf")
        plt.savefig(filename, bbox_inches='tight')
        plt.close()
    else:
        plt.show()

def plot_scatter_points_with_phis(processed_data, traj_files_legend, save_figs, subfolder=''):
    land_shp_fname = shpreader.natural_earth(resolution='110m', category='physical', name='land')
    land_geom = list(shpreader.Reader(land_shp_fname).geometries())
    land_geom_united = unary_union(land_geom)
    land_geom_prepared = prep(land_geom_united)

    panel_labels = ['a.', 'b.', 'c.', 'd.', 'e.']

    for i, data in enumerate(processed_data['xlat']):
        lats = processed_data['xlat'][i]
        lons = processed_data['xlon'][i]
        phis = processed_data['xphis'][i]

        fig, ax = plt.subplots(figsize=(10, 6), subplot_kw={'projection': ccrs.PlateCarree()})
        ax.set_extent([-130, -60, 20, 55], crs=ccrs.PlateCarree())

        ax.coastlines()
        ax.add_feature(cfeature.BORDERS)
        ax.add_feature(cfeature.LAND)
        ax.add_feature(cfeature.OCEAN)

        gl = ax.gridlines(draw_labels=True, color='gray', alpha=0.5, linestyle='--')
        gl.top_labels = False
        gl.right_labels = False

        scatter = ax.scatter(lons, lats, c=phis, cmap='jet', s=10, vmin=0, vmax=500, transform=ccrs.PlateCarree(), label='Surface Geopotential')

        cbar = plt.colorbar(scatter, ax=ax, orientation='vertical', pad=0.02, aspect=50)
        cbar.set_label('Surface Geopotential (m^2/s^2)', fontsize=14)

        ax.set_title(f'Scatter Plot of Surface Geopotential - {traj_files_legend[i]}', fontsize=16)
        ax.text(0.02, 0.96, panel_labels[i], transform=ax.transAxes, fontsize=20, fontweight='bold', va='top', ha='left', bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.2'))

        if save_figs:
            filename_safe = traj_files_legend[i].replace(' ', '_')
            filename = os.path.join(subfolder, f"scatter_phis_{filename_safe}.pdf")
            plt.savefig(filename, bbox_inches='tight')
            plt.close()
        else:
            plt.show()

#--------------------------------------------------------------------------------------------------------

traj_files = [
    './trajs/final.Historical',
    './trajs/final.cold_near',
    './trajs/final.hot_near',
    './trajs/final.cold_far',
    './trajs/final.hot_far'
]

traj_files_legend = ['Historical', 'Cold Near', 'Hot Near', 'Cold Far', 'Hot Far']

num_files = len(traj_files)

isUnstruc=False
nVars=-1
headerStr='start'
wind_factor=1.0
save_figs=True

mask_min_slp=float(get_arg(1))
mask_max_slp=float(get_arg(2))
land_or_ocean = get_arg(3)  # 'all', 'ocn', or 'lnd'

if save_figs:
    figs_dir = "figs"
    subfolder = os.path.join(figs_dir, land_or_ocean)
    os.makedirs(subfolder, exist_ok=True)

bignumber=10e8
if mask_min_slp < 0:
    mask_min_slp = -bignumber
    print("Setting mask_min_slp to: "+str(mask_min_slp))
if mask_max_slp < 0:
    mask_max_slp = bignumber
    print("Setting mask_max_slp to: "+str(mask_max_slp))

processed_data = process_trajectory_files(traj_files, nVars, headerStr, isUnstruc, mask_min_slp, mask_max_slp)

# A diagnostic to ensure the length of each loaded dataset is the same
for key in processed_data:
    lengths = [len(dataset) for dataset in processed_data[key]]
    print(f"Lengths of datasets for key '{key}': {lengths}")

# All values greater than 999/9 will be set to nans
apply_nan_filter_to_keys(processed_data, 'xdpsl', 999, '>')
apply_nan_filter_to_keys(processed_data, 'xwind', 9999, '>')
apply_nan_filter_to_keys(processed_data, 'xpres', 9999, '>')
apply_nan_filter_to_keys(processed_data, 'xike', 1.0e+15, '>')
apply_nan_filter_to_keys(processed_data, 'xsst', -999, '<')

# If any timestep has *any* nan across the datasets, set all of the datasets to nan
# This happens with wind in the TE data because TE may "catch" the missing data at the edge of the domain
# It shouldn't happen with other data which should be 1-to-1 masked
synchronize_and_diagnose_nans(processed_data, 'xdpsl')
synchronize_and_diagnose_nans(processed_data, 'xwind')
synchronize_and_diagnose_nans(processed_data, 'xpres')
synchronize_and_diagnose_nans(processed_data, 'xike')
synchronize_and_diagnose_nans(processed_data, 'xsst')

# Apply land or ocean filtering based on the 'land_or_ocean' argument
if land_or_ocean == 'ocn':
    for key in processed_data:
        for i in range(len(processed_data[key])):
            processed_data[key][i] = np.where(processed_data['xphis'][i] > 5.0, np.nan, processed_data[key][i])
        synchronize_and_diagnose_nans(processed_data, key)

if land_or_ocean == 'lnd':
    for key in processed_data:
        for i in range(len(processed_data[key])):
            processed_data[key][i] = np.where(processed_data['xphis'][i] <= 5.0, np.nan, processed_data[key][i])
        synchronize_and_diagnose_nans(processed_data, key)

# Add scatter plots for all points color-coded by xphis
plot_scatter_points_with_phis(processed_data, traj_files_legend, save_figs, subfolder=subfolder)

# Add new variable for variation of psl (abs dpsl)
processed_data['xvarpsl'] = [np.abs(data) for data in processed_data['xdpsl']]

# Add random white noise to 'xrmw' since it's very discretized
# noise_level is in units of degrees and as randomly distributed around 0.
# we can think of this as adding observational uncertainty
np.random.seed(1998)
noise_level = 0.1
for i in range(len(processed_data['xrmw'])):
    noise = np.random.uniform(low=-noise_level, high=noise_level, size=processed_data['xrmw'][i].shape)
    processed_data['xrmw'][i] += noise
for i in range(len(processed_data['xr8'])):
    noise = np.random.uniform(low=-noise_level, high=noise_level, size=processed_data['xr8'][i].shape)
    processed_data['xr8'][i] += noise

apply_conversion_to_key(processed_data, 'xrmw', 111.1)
apply_conversion_to_key(processed_data, 'xr8', 111.1)
#apply_conversion_to_key(processed_data, 'xike', 1e-9)
# Assuming 0.1x0.1deg GCD, so 11.1^2 = 123.21 km^2 for each cell
apply_conversion_to_key(processed_data, 'xgt10_prect', 123.21/1000)   # 1000 km2
apply_conversion_to_key(processed_data, 'xgt10_wind850', 123.21/1000) # 1000 km2
apply_conversion_to_key(processed_data, 'xgt8_wind10', 123.21/1000) # 1000 km2

n_rapid_deepening = []
n_rapid_collapsing = []
thresh_rapid_deepening = -7.5
thresh_rapid_collapsing = 7.5
deepening_lat_lon = []
collapsing_lat_lon = []

# Create panel labels
panel_labels = ['a.', 'b.', 'c.', 'd.', 'e.']

# Load natural earth features for land/sea masking
land_shp_fname = shpreader.natural_earth(resolution='110m', category='physical', name='land')
land_geom = list(shpreader.Reader(land_shp_fname).geometries())
land_geom_united = unary_union(land_geom)
land_geom_prepared = prep(land_geom_united)

for i, data in enumerate(processed_data['xdpsl']):
    # Find the indices where the pres either goes up/down by threshold
    deepening_indices = np.where(data <= thresh_rapid_deepening)
    collapsing_indices = np.where(data >= thresh_rapid_collapsing)

    count_deepening = len(deepening_indices[0])
    count_collapsing = len(collapsing_indices[0])

    n_rapid_deepening.append(count_deepening)
    n_rapid_collapsing.append(count_collapsing)

    # Extract latitude and longitude points
    deepening_lat_lon.append(list(zip(processed_data['xlat'][i][deepening_indices], processed_data['xlon'][i][deepening_indices])))
    collapsing_lat_lon.append(list(zip(processed_data['xlat'][i][collapsing_indices], processed_data['xlon'][i][collapsing_indices])))

    fig, ax = plt.subplots(figsize=(10, 6), subplot_kw={'projection': ccrs.PlateCarree()})
    ax.set_extent([-130, -60, 20, 55], crs=ccrs.PlateCarree())  # Zoom in on CONUS

    ax.coastlines()
    ax.add_feature(cfeature.BORDERS)
    ax.add_feature(cfeature.LAND)
    ax.add_feature(cfeature.OCEAN)

    # Add gridlines with labels
    gl = ax.gridlines(draw_labels=True, color='gray', alpha=0.5, linestyle='--')
    gl.top_labels = False
    gl.right_labels = False

    # Plot rapid intensification points
    if deepening_lat_lon[i]:
        for lat, lon in deepening_lat_lon[i]:
            point = Point(lon, lat)
            if land_geom_prepared.contains(point):
                ax.plot(lon, lat, 'bo', markerfacecolor='none', markersize=5, label='RI over land')
            else:
                ax.plot(lon, lat, 'bo', markersize=5, label='RI over ocean')

    # Plot rapid weakening points
    if collapsing_lat_lon[i]:
        for lat, lon in collapsing_lat_lon[i]:
            point = Point(lon, lat)
            if land_geom_prepared.contains(point):
                ax.plot(lon, lat, 'ro', markerfacecolor='none', markersize=5, label='RW over land')
            else:
                ax.plot(lon, lat, 'ro', markersize=5, label='RW over ocean')

    ax.set_title(f'Rapid Intensification and Weakening Occurrences - {traj_files_legend[i]}', fontsize=16)

    # Add panel labels
    ax.text(0.02, 0.96, panel_labels[i], transform=ax.transAxes, fontsize=20, fontweight='bold',
            va='top', ha='left', bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.2'))

    # Custom legend entries
    ri_ocean = mlines.Line2D([], [], color='blue', marker='o', markersize=5, linestyle='None', label='RI over ocean')
    ri_land = mlines.Line2D([], [], color='blue', marker='o', markersize=5, markerfacecolor='none', linestyle='None', label='RI over land')
    rw_ocean = mlines.Line2D([], [], color='red', marker='o', markersize=5, linestyle='None', label='RW over ocean')
    rw_land = mlines.Line2D([], [], color='red', marker='o', markersize=5, markerfacecolor='none', linestyle='None', label='RW over land')
    ax.legend(handles=[ri_ocean, ri_land, rw_ocean, rw_land], fontsize=12, loc='upper right', framealpha=0.9)

    filename_safe = traj_files_legend[i].replace(' ', '_')  # Replace spaces with underscores
    filename = os.path.join(subfolder, f"map_ri_events_{filename_safe}.pdf")
    plt.savefig(filename, bbox_inches='tight')
    plt.close()

# Print the results
print("Rapid intensification counts")
print(n_rapid_deepening)
print("Rapid collapsing counts")
print(n_rapid_collapsing)

print("Latitude and longitude points for rapid deepening:")
for lat_lon in deepening_lat_lon:
    print(lat_lon)

print("Latitude and longitude points for rapid collapsing:")
for lat_lon in collapsing_lat_lon:
    print(lat_lon)

## Plot rapid deepening + collapsing

index = np.arange(num_files) # Creating an index for each pair

bar_width = 0.35

plt.figure(figsize=(10, 6))
bar1 = plt.bar(index, n_rapid_deepening, bar_width, color='b', label='Rapid Intensification')
bar2 = plt.bar(index + bar_width, n_rapid_collapsing, bar_width, color='r', label='Rapid Weakening')

#plt.xlabel('Model simulation',fontsize=16)
plt.ylabel('Number of occurances',fontsize=16)
plt.title('Rapid Intensification and Weakening Occurances',fontsize=16)
plt.xticks(index + bar_width / 2, traj_files_legend,fontsize=16)
plt.yticks(fontsize=16)

plt.legend(fontsize=14)

if save_figs:
    filename = os.path.join(subfolder, "rapid_deepening_collapsing.pdf")
    plt.savefig(filename, bbox_inches='tight')
    plt.close()  # Close the plot to free up memory
else:
    plt.show()

##

# Keys for which to calculate and print statistics
# TPZ answers
#keys_for_statistics = ['xpres', 'xslp', 'xwind', 'xmax_wind10', 'xrmw', 'xmax_prect', 'xgt10_prect', 'xmax_tmq']
keys_for_statistics = ['xpres', 'xwind', 'xrmw', 'xurmw', 'xr8', 'xike', 'xmax_prect', 'xgt10_prect', 'xmax_tmq', 'xslp', 'xmax_wind10', 'xmax_wind850', 'xgt8_wind10', 'xgt10_wind850', 'xvarpsl', 'xsst']

# Calculate and print statistics for each list
calculate_and_print_statistics(processed_data, keys_for_statistics, traj_files_legend, filter_config=land_or_ocean)

####

pretty_labels = {
    'xpres': r'MSLP',
    'xrmw': r'RMW',
    'xurmw': 'Wind at Radius of Max. Wind',
    'xr8': r'$r_{8}$',
    'xike': r'IKE',
    'xmax_prect': r'$\mathrm{Prec}_{x}$',
    'xgt10_prect': r'$\mathrm{Prec}_{\mathrm{area}>10}$',
    'xmax_tmq': r'$\mathrm{TPW}_{x}$',
    'xslp': r'MSLP',
    'xmax_wind10': r'$u_{10m,x}$',
    'xmax_wind850': r'$u_{850mb,x}$',
    'xgt8_wind10': 'Area 10m Wind >8 m/s',
    'xgt10_wind850': 'Area 850hPa Wind >10 m/s',
    'xvarpsl': r'$|$dPSL$|$'
}

x_labels_with_newlines = {
    'Cold Near': 'Cold\nNear',
    'Hot Near': 'Hot\nNear',
    'Cold Far': 'Cold\nFar',
    'Hot Far': 'Hot\nFar'
}

keys_for_percentages = ['xslp', 'xmax_wind10', 'xike', 'xmax_tmq', 'xmax_prect', 'xgt10_prect', 'xr8', 'xrmw', 'xvarpsl']

percentages_results = snapshot_percent_increase(processed_data, keys_for_percentages)

for key, percentages in percentages_results.items():
    print(f"Percentages for {key}:", percentages)

# Now, convert this dictionary into a DataFrame suitable for a heatmap
df = pd.DataFrame(percentages_results, index=['Cold Near', 'Hot Near', 'Cold Far', 'Hot Far']).transpose()

# Rename the index of the DataFrame to pretty labels
df.rename(index=pretty_labels, inplace=True)

# Update the columns with new labels that include newlines
df.columns = [x_labels_with_newlines[col] for col in df.columns]

# Create a custom colormap with white in the middle
cmap = diverging_palette(240, 10, s=210, l=20, sep=20, as_cmap=True)

# Create the heatmap
plt.figure(figsize=(8, 10))
heatmap = sns.heatmap(df, annot=True, fmt="d", linewidths=.5, cmap=cmap, center=50, vmin=0, vmax=100, annot_kws={"size": 24})

# Customize the plot
#heatmap.set_title('Snapshot Percentage Increased', fontsize=18)
#heatmap.set_xlabel('Scenario', fontsize=16)
#heatmap.set_ylabel('Variable', fontsize=16)

# Set the size of the tick labels
heatmap.tick_params(axis='x', labelsize=16)
heatmap.tick_params(axis='y', labelsize=16, rotation=0)

# Adjust colorbar label size
cbar = heatmap.collections[0].colorbar
cbar.ax.tick_params(labelsize=18)

# Save or display the plot based on save_figs
if save_figs:
    plt.tight_layout()  # Adjust the padding between and around subplots.
    plt.savefig(os.path.join(subfolder, "heatmap.pdf"), bbox_inches='tight')  # Save the figure, ensuring nothing is cut off
    plt.close()
else:
    plt.show()

####

plot_params = [
    ('xmax_tmq', 'Max. precipitable water', 'mm'),
    ('xmax_prect', 'Max. precip. rate', 'mm/hr'),
    ('xmax_wind10', 'Max. 10m wind speed', 'm/s'),
    ('xmax_wind850', 'Max. 850hPa wind speed', 'm/s'),
    ('xrmw', 'Radius of Maximum Wind', 'km'),
    ('xgt10_prect', 'Area of precip. rates > 10mm/hr', '1000 km$^2$'),
    ('xr8', 'Radius of 8m/s wind', 'km'),
    ('xvarpsl', 'Magnitude of 6h dPSL', 'hPa/6hr'),
    ('xike', 'Integrated Kinetic Energy', 'TJ'),
    ('xslp', 'Minimum Sea Level Pressure', 'hPa'),
    ('xsst', 'Sea Surface Temperature Under TC', 'K')
]

for key, title, units in plot_params:
    plot_histograms(processed_data, key, title, units, traj_files_legend, save_figs, subfolder=subfolder)
    plot_histograms_with_control_deviation(processed_data, key, title, units, traj_files_legend, save_figs, subfolder=subfolder)