import xarray as xr
import matplotlib.pyplot as plt
import numpy as np
import cartopy.crs as ccrs
import cartopy.feature as cfeature
from scipy.ndimage import gaussian_filter

def load_and_concatenate_datasets(file_patterns, decode_times=False):
    datasets = [xr.open_dataset(file, decode_times=decode_times) for file in file_patterns]
    combined_ds = xr.concat(datasets, dim='Time')
    return combined_ds

# User options
fill_wind = True  # Set to True to fill NaN values in wind shear data
smooth_data = True  # Set to True to apply smoothing to the data

# Font size options
title_font_size = 22  # Adjust the font size for the plot titles
colorbar_font_size = 18  # Adjust the font size for the colorbar labels

# Define the file patterns for the datasets
folder_path = '../netcdf/shear/19830903/'  # Adjust the path as needed
file_patterns = [
    f'{folder_path}/cat_historical_1980_2019.nc',
    f'{folder_path}/cat_rcp85cooler_2020_2059.nc',
    f'{folder_path}/cat_rcp85hotter_2020_2059.nc',
    f'{folder_path}/cat_rcp85cooler_2060_2099.nc',
    f'{folder_path}/cat_rcp85hotter_2060_2099.nc'
]

# Labels for each dataset
labels = ['Historical', 'Cold Near', 'Hot Near', 'Cold Far', 'Hot Far']

# Panel labels
panel_labels = ['a.', 'b.', 'c.', 'd.', 'e.']

# Load and concatenate datasets
combined_datasets = [load_and_concatenate_datasets([pattern]) for pattern in file_patterns]

# Calculate wind shear for each dataset
wind_shear_list = []
lats, lons = None, None  # Initialize lat and lon
for ds in combined_datasets:
    # Extract the variables
    u850 = ds['U850']
    v850 = ds['V850']
    u200 = ds['U200']
    v200 = ds['V200']

    lats = ds['XLAT'].values
    lons = ds['XLONG'].values

    # Calculate wind shear
    u_shear = u200 - u850
    v_shear = v200 - v850
    wind_shear = np.sqrt(u_shear**2 + v_shear**2)

    # Fill NaN values if fill_wind is True
    if fill_wind:
        wind_shear = wind_shear.interpolate_na(dim="west_east", method="linear", fill_value="extrapolate")
        wind_shear = wind_shear.interpolate_na(dim="south_north", method="linear", fill_value="extrapolate")

    wind_shear_list.append(wind_shear)

# Define the map extent and color scale
map_extent = [-135, -59, 20, 50]
cbar_limits = [0, 50]  # Adjust the color bar limits as needed
smoothing_sigma = 4  # Define the level of smoothing

# Plot and save each dataset separately
for i, (shear, label) in enumerate(zip(wind_shear_list, labels)):
    # Create a new figure for each plot
    plt.figure(figsize=(10, 8))
    ax = plt.axes(projection=ccrs.PlateCarree())
    ax.set_extent(map_extent, crs=ccrs.PlateCarree())

    # Add geographic features
    ax.add_feature(cfeature.LAND, zorder=1)
    ax.add_feature(cfeature.COASTLINE, edgecolor='white', zorder=2)
    ax.add_feature(cfeature.BORDERS, linestyle='-', alpha=.5, edgecolor='white', zorder=3)

    # Add gridlines
    gridlines = ax.gridlines(draw_labels=True, color='gray', alpha=0.5, linestyle='--')
    gridlines.top_labels = False
    gridlines.right_labels = False
    gridlines.left_labels = False
    gridlines.bottom_labels = False

    # Select the time slice and apply smoothing if smooth_data is True
    shear_data = shear.isel(Time=0).values.squeeze()
    if smooth_data:
        shear_data = gaussian_filter(shear_data, sigma=smoothing_sigma)

    # Plot the wind shear map
    im = ax.pcolormesh(lons, lats, shear_data, cmap='plasma', vmin=cbar_limits[0], vmax=cbar_limits[1], transform=ccrs.PlateCarree())

    ax.set_title(f'Wind Shear: {label}', fontsize=title_font_size)

    # Add a panel label in the top left corner
    ax.text(
        0.02, 0.96, panel_labels[i],
        transform=ax.transAxes,
        fontsize=30, fontweight='bold',
        va='top', ha='left',
        bbox=dict(facecolor='white', edgecolor='black', boxstyle='round,pad=0.2')
    )

    # Add a horizontal colorbar below the plot only for 'Historical'
    if label == 'Historical':
        cbar = plt.colorbar(im, ax=ax, orientation='horizontal', pad=0.02, shrink=0.9, aspect=30)
        cbar.set_label('Wind Shear (m/s)', fontsize=colorbar_font_size)
        cbar.ax.tick_params(labelsize=colorbar_font_size - 2)  # Adjust the tick label font size

    plt.tight_layout(pad=0)  # Reduce padding around the figure
    plt.savefig(f'wind_shear_{label.replace(" ", "_").lower()}.png', dpi=300, bbox_inches='tight')
    plt.close()

    print(f"Saved: wind_shear_{label.replace(' ', '_').lower()}.png")
