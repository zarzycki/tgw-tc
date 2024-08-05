import xarray as xr
import matplotlib.pyplot as plt
import numpy as np
import glob
import matplotlib.dates as mdates
import cftime
from matplotlib.cm import get_cmap

def load_and_concatenate_datasets(file_patterns, decode_times=False):
    datasets = [xr.open_dataset(file, decode_times=decode_times) for file in file_patterns]
    combined_ds = xr.concat(datasets, dim='Time')
    return combined_ds

def find_nearest_grid_point(latitudes, longitudes, target_lat, target_lon):
    lat_diff = np.abs(latitudes - target_lat)
    lon_diff = np.abs(longitudes - target_lon)
    total_diff = lat_diff + lon_diff
    min_diff_index = np.unravel_index(np.argmin(total_diff), total_diff.shape)
    return min_diff_index

def decode_time_if_needed(timeseries, start_date='2003-09-03'):
    if not np.issubdtype(timeseries['Time'].dtype, np.datetime64):
        times = xr.cftime_range(start=start_date, periods=timeseries.sizes['Time'], freq='3H')
        timeseries = timeseries.assign_coords(Time=times)
    return timeseries

first_file_date='2003-09-03'
target_lat = 28.1
target_lon = -71.5
folder_path = '../netcdf/SST/2003_isabel/'

#first_file_date='2005-08-06'
#target_lat = 27.2
#target_lon = -89.2
#folder_path = '/pscratch/sd/c/czarzyck/SST/2005_katrina/'

# Define the file patterns for the datasets
file_patterns = [
    f'{folder_path}/cat_historical_1980_2019.nc',
    f'{folder_path}/cat_rcp85cooler_2020_2059.nc',
    f'{folder_path}/cat_rcp85hotter_2020_2059.nc',
    f'{folder_path}/cat_rcp85cooler_2060_2099.nc',
    f'{folder_path}/cat_rcp85hotter_2060_2099.nc'
]

# Load and concatenate datasets
combined_datasets = [load_and_concatenate_datasets([pattern]) for pattern in file_patterns]

# Extract the latitude and longitude arrays from the first dataset
latitudes = combined_datasets[0]['XLAT'][0, :, :].values
longitudes = combined_datasets[0]['XLONG'][0, :, :].values

# Find the nearest grid point
min_diff_index = find_nearest_grid_point(latitudes, longitudes, target_lat, target_lon)

# Extract SST timeseries and decode time for all datasets
sst_timeseries_list = []
for ds in combined_datasets:
    sst_timeseries = ds['SST'][:, min_diff_index[0], min_diff_index[1]]
    sst_timeseries = decode_time_if_needed(sst_timeseries, start_date=first_file_date)
    sst_timeseries_list.append(sst_timeseries)

plt.figure(figsize=(10, 5))
labels = ['Historical',
          'Cold Near',
          'Hot Near',
          'Cold Far',
          'Hot Far']

cmap = plt.colormaps.get_cmap('cool')
colors = cmap(np.linspace(0, 1, len(labels)))

for sst_timeseries, label, color in zip(sst_timeseries_list, labels, colors):
    sst_timeseries.plot(label=label, color=color)

user_date_cftime = cftime.DatetimeGregorian(2003, 9, 17)

# Add the vertical line at the user-specified date
plt.axvline(user_date_cftime, color='black', linestyle='-', linewidth=2)

plt.title(f'SST trace at grid cell nearest to {target_lat}, {target_lon}')
plt.xlabel('Time')
plt.ylabel('SST (Sea Surface Temperature)')
plt.legend()
plt.grid()

# Set x-axis major locator to display labels every 5 days with a smaller font size
plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=3))
#plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%Y-%m-%d'))
plt.gcf().autofmt_xdate()
plt.tick_params(axis='x', labelsize=8)  # Set the font size for x-axis labels

plt.tight_layout(pad=0)  # Reduce padding around the figure
plt.savefig('sst_trace.pdf', bbox_inches='tight')
plt.close()
