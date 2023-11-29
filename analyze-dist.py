import sys
import numpy as np
import xarray as xr
from scipy import stats
import matplotlib.pyplot as plt

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
        'xmax_tmq': [], 'xgt8_wind10': [], 'xgt10_wind850': [], 'xyear': [],
        'xmonth': [], 'xday': [], 'xhour': []
    }

    index_mapping = {
        'xlon': 2, 'xlat': 3, 'xpres': 4, 'xwind': 5, 'xdpsl': 6,
        'xurmw': 7, 'xrmw': 8, 'xr8': 9, 'xike': 10, 'xslp': 11,
        'xmax_wind10': 12, 'xmax_wind850': 13, 'xmax_prect': 14, 'xgt10_prect': 15,
        'xmax_tmq': 16, 'xgt8_wind10': 17, 'xgt10_wind850': 18, 'xyear': 19,
        'xmonth': 20, 'xday': 21, 'xhour': 22
    }

    for file in file_list:
        nstorms, ntimes, ncol, traj_data = getTrajectories(file, n_vars, header_str, is_unstructured)

        # Note, this correctly masks all NaNs and flattens the array to 1-D
        if file == 'final.Historical':
            slpmask = (traj_data[4,:,:] > mask_min_slp) & (traj_data[4,:,:] <= mask_max_slp)
        for key, index in index_mapping.items():
            data_collection[key].append(traj_data[index,:,:][slpmask])

        # This *doesn't* flatten arrays and appends 2D (nstorms x ntimes)
        #for key, index in index_mapping.items():
        #    print(traj_data[index,:,:].shape)
        #    data_collection[key].append(traj_data[index,:,:])

    return data_collection

def apply_conversion_to_key(processed_data, key, conversion_factor):
    num_files = len(processed_data[key])
    for i in range(num_files):
        processed_data[key][i] = processed_data[key][i] * conversion_factor

def apply_nan_filter_to_keys(processed_data, key, threshold):
    num_files = len(processed_data[key])
    for i in range(num_files):
        processed_data[key][i] = np.where(processed_data[key][i] > threshold, np.nan, processed_data[key][i])

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

def calculate_and_print_statistics(processed_data, list_names):
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

            # Calculate mean, percentiles, and median while ignoring NaNs
            mean_value = np.nanmean(filtered_data)
            percentile_5th = np.nanpercentile(filtered_data, 5)
            percentile_95th = np.nanpercentile(filtered_data, 95)
            median_value = np.nanmedian(filtered_data)

            # Calculate range
            if filtered_data.size > 0:  # Check if there are non-NaN values
                data_range = np.nanmax(filtered_data) - np.nanmin(filtered_data)
            else:
                data_range = np.nan  # Set range as NaN if all values are NaN

            # Print the results, rounded to 1 decimal place
            print(f"{list_name} {i}: Mean = {mean_value:.1f}, 5th Percentile = {percentile_5th:.1f}, 95th Percentile = {percentile_95th:.1f}, Median = {median_value:.1f}, Range = {data_range:.1f}")

            # Perform t-test with the control data, if i is not 0
            if i != 0:
                t_stat, p_val = stats.ttest_ind(control_data, filtered_data, nan_policy='omit', equal_var=False)
                print(f"    T-Statistic = {t_stat:.3f}, P-value = {p_val:.3f}")

        print("---")

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
                percentages.append(percentage)
            else:
                percentages.append(np.nan)  # Append NaN if sizes are different

        results[list_name] = [round(p) for p in percentages]  # Store results rounded to the nearest integer

    return results

def plot_histograms(processed_data, key, title, units, legend_names):
    data_list = processed_data[key]

    # Find the overall minimum and maximum values across all datasets
    overall_min = min(np.nanmin(data.flatten()) for data in data_list)
    overall_max = max(np.nanmax(data.flatten()) for data in data_list)

    # Set up the figure and axes
    plt.figure(figsize=(10, 6))

    # Loop over each dataset in the data list and plot a line for the histogram
    for i, mydata in enumerate(data_list):
        counts, bin_edges = np.histogram(mydata.flatten(), bins=20, range=(overall_min, overall_max))
        bin_centers = 0.5 * (bin_edges[:-1] + bin_edges[1:])  # Calculate bin centers
        label = legend_names[i] if i < len(legend_names) else f'Dataset {i+1}'
        plt.plot(bin_centers, counts, label=label, linewidth=2)

    # Customize the plot
    plt.title(f'{title} distributions')
    plt.xlabel(f'{title} ({units})')  # Include units in the x-axis label
    plt.ylabel('Frequency')
    plt.legend()

    # Show the plot
    plt.show()

#--------------------------------------------------------------------------------------------------------
traj_files = [
    'final.Historical',
    'final.cold_near',
    'final.hot_near',
    'final.cold_far',
    'final.hot_far'
]

traj_files_legend = ['Historical', 'Cold Near', 'Hot Near', 'Cold Far', 'Hot Far']

num_files = len(traj_files)

isUnstruc=False
nVars=-1
headerStr='start'
wind_factor=1.0

mask_min_slp=float(get_arg(1))
mask_max_slp=float(get_arg(2))

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

apply_conversion_to_key(processed_data, 'xrmw', 111.1)

# All values greater than 999/9 will be set to nans
apply_nan_filter_to_keys(processed_data, 'xdpsl', 999)
apply_nan_filter_to_keys(processed_data, 'xwind', 9999)
apply_nan_filter_to_keys(processed_data, 'xpres', 9999)

# If any timestep has *any* nan across the datasets, set all of the datasets to nan
# This happens with wind in the TE data because TE may "catch" the missing data at the edge of the domain
# It shouldn't happen with other data which should be 1-to-1 masked
synchronize_and_diagnose_nans(processed_data, 'xdpsl')
synchronize_and_diagnose_nans(processed_data, 'xwind')
synchronize_and_diagnose_nans(processed_data, 'xpres')


n_rapid_deepening = []
n_rapid_collapsing = []
thresh_rapid_deepening = -10
thresh_rapid_collapsing = 10

for data in processed_data['xdpsl']:
    count_deepening = np.sum(data <= thresh_rapid_deepening)
    count_collapsing = np.sum(data >= thresh_rapid_collapsing)
    n_rapid_deepening.append(count_deepening)
    n_rapid_collapsing.append(count_collapsing)

print("Rapid deepening counts")
print(n_rapid_deepening)
print("Rapid collapsing counts")
print(n_rapid_collapsing)


# Keys for which to calculate and print statistics
keys_for_statistics = ['xpres', 'xslp', 'xwind', 'xmax_wind10', 'xrmw', 'xmax_prect', 'xgt10_prect', 'xmax_tmq']

# Calculate and print statistics for each list
calculate_and_print_statistics(processed_data, keys_for_statistics)


keys_for_percentages = ['xpres','xwind','xrmw', 'xurmw', 'xr8', 'xike', 'xmax_prect', 'xgt10_prect', 'xmax_tmq', 'xslp', 'xmax_wind10', 'xmax_wind850', 'xgt8_wind10', 'xgt10_wind850']

percentages_results = snapshot_percent_increase(processed_data, keys_for_percentages)

for key, percentages in percentages_results.items():
    print(f"Percentages for {key}:", percentages)


plot_params = [
    ('xmax_tmq', 'Maximum precipitable water', 'mm'),
    ('xmax_prect', 'Maximum precipitation rate', 'mm/hr'),
    ('xmax_wind850', 'Maximum 850 hPa wind speed', 'm/s'),
    ('xrmw', 'Radius of Maximum Wind', 'km'),
    ('xgt10_prect', 'Area of precipitation rates greater than 10', 'square km'),
    ('xgt10_wind850', 'Area of 850mb winds greater than 10 m/s', 'square km')
]

for key, title, units in plot_params:
    plot_histograms(processed_data, key, title, units, traj_files_legend)

