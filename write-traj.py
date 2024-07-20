import sys
import re
import numpy as np
import xarray as xr
import operator
from scipy.interpolate import RegularGridInterpolator

sys.path.insert(0, './functions')
from getTrajectories import *

def get_arg(index):
    try:
        sys.argv[index]
    except IndexError:
        return ''
    else:
        return sys.argv[index]

def count_spatial_gridpoints(data_array, operator_str, threshold):
    """
    Count the number of cells in each spatial grid of a data array that meet a given condition.

    :param data_array: xarray DataArray representing the spatial grid data.
    :param operator_str: Comparison operator as a string (e.g., '<', '>', '==').
    :param threshold: Threshold value for comparison.
    :return: 1D NumPy array with the count for each spatial grid.
    """
    # Map the operator string to an actual operator
    ops = {
        "<": operator.lt,
        ">": operator.gt,
        "==": operator.eq,
        "<=": operator.le,
        ">=": operator.ge,
        "!=": operator.ne
    }

    if operator_str not in ops:
        raise ValueError(f"Invalid operator: {operator_str}")

    # Initialize an empty array to store the counts
    count_array = np.zeros(data_array.shape[0])

    # Loop over each spatial array
    for i in range(data_array.shape[0]):
        # Apply the condition and count
        condition = ops[operator_str](data_array[i], threshold)
        count_array[i] = np.sum(condition)

    return count_array

def conform_to_reference_2d(ref_array, one_d_array):
    """
    Reshape a 1D array to conform to the shape of a 2D reference array.
    NaN values in the reference array indicate positions to be filled with NaNs.

    :param ref_array: 2D reference array with NaNs.
    :param one_d_array: 1D array to be reshaped.
    :return: 2D array reshaped to match ref_array's shape.
    """
    reshaped_array = np.full(ref_array.shape, np.nan)
    one_d_iter = iter(one_d_array)

    for i in range(ref_array.shape[0]):
        for j in range(ref_array.shape[1]):
            if not np.isnan(ref_array[i, j]):
                reshaped_array[i, j] = next(one_d_iter, np.nan)

    return reshaped_array

def write_cyclone_tracks(filename, xix, xjy, xlat, xlon, xyear, xmonth, xday, xhour, **optional_columns_with_format):
    # Number of storms and time steps
    num_storms, num_time_steps = xlon.shape

    with open(filename, 'w') as file:
        for i in range(num_storms):
            # Write the header for each storm with integer values
            file.write(f"start\t{len(np.where(~np.isnan(xlon[i]))[0])}\t{int(xyear[i][0])}\t{int(xmonth[i][0])}\t{int(xday[i][0])}\t{int(xhour[i][0])}\n")

            for j in range(num_time_steps):
                if not np.isnan(xlon[i][j]):  # Skip NaN values
                    # Start each row with lat and lon
                    row = [f"{xix[i][j]:.0f}", f"{xjy[i][j]:.0f}", f"{xlon[i][j]:.6f}", f"{xlat[i][j]:.6f}"]

                    # Add optional columns with specified formatting
                    for column, (data, fmt) in optional_columns_with_format.items():
                        row.append(f"{data[i][j]:{fmt}}")

                    # End each row with year, month, day, and hour
                    row.extend([f"{int(xyear[i][j])}", f"{int(xmonth[i][j])}", f"{int(xday[i][j])}", f"{int(xhour[i][j])}"])

                    # Write the row
                    file.write("\t" + "\t".join(row) + "\n")

    print(filename+" written successfully.")

experiment=get_arg(1)
# Historical, cold_far, cold_near, hot_far, hot_near

trajfile='trajs/traj.'+experiment+'_time_cleaned.txt_final'
isUnstruc=False
nVars=-1
headerStr='start'
wind_factor=1.0

nstorms, ntimes, ncol, traj_data = getTrajectories(trajfile,nVars,headerStr,isUnstruc)
xix    = traj_data[0,:,:]
xjy    = traj_data[1,:,:]
xlon   = traj_data[2,:,:]
xlat   = traj_data[3,:,:]
xpres  = traj_data[4,:,:]#/100.
xwind  = traj_data[5,:,:]#*wind_factor
xdpsl  = traj_data[6,:,:]
xurmw  = traj_data[7,:,:]
xrmw   = traj_data[8,:,:]
xr8    = traj_data[9,:,:]
xike   = traj_data[10,:,:]
xyear  = traj_data[ncol-4,:,:]
xmonth = traj_data[ncol-3,:,:]
xday   = traj_data[ncol-2,:,:]
xhour  = traj_data[ncol-1,:,:]

# Open the snapshot files
snapshot_map = {
    "Historical": "Historical",
    "cold_near": "SSP585_COLD_NEAR",
    "hot_near": "SSP585_HOT_NEAR",
    "cold_far": "SSP585_COLD_FAR",
    "hot_far": "SSP585_HOT_FAR"
}

ds_aux   = xr.open_dataset('./netcdf/composite_aux_CONUS_TGW_WRF_'+snapshot_map[experiment]+'.nc')
ds_aux2  = xr.open_dataset('./netcdf/composite_aux2_CONUS_TGW_WRF_'+snapshot_map[experiment]+'.nc')
ds_prect = xr.open_dataset('./netcdf/composite_prect_CONUS_TGW_WRF_'+snapshot_map[experiment]+'.nc')

# Load variables
snap_SLP = ds_aux['snap_SLP']
snap_U10 = ds_aux['snap_U10']
snap_V10 = ds_aux['snap_V10']
snap_U850 = ds_aux2['snap_U850']
snap_V850 = ds_aux2['snap_V850']
snap_PRECT = ds_prect['snap_PRECT']
snap_TMQ = ds_aux2['snap_TMQ']

# Derived variables
snap_WIND10 = np.sqrt(snap_U10**2 + snap_V10**2)
snap_WIND850 = np.sqrt(snap_U850**2 + snap_V850**2)
snap_PRECT = snap_PRECT * 3.6e6    # m/s to mm/hr

# Close xarray datasets
ds_aux.close()
ds_aux2.close()
ds_prect.close()

min_SLP    = snap_SLP.min(dim=['y', 'x'])
max_WIND10 = snap_WIND10.max(dim=['y', 'x'])
max_WIND850 = snap_WIND850.max(dim=['y', 'x'])
max_PRECT  = snap_PRECT.max(dim=['y', 'x'])
max_TMQ  = snap_TMQ.max(dim=['y', 'x'])

LT1000_SLP = count_spatial_gridpoints(snap_SLP, '<', 1000)
GT8_WIND10 = count_spatial_gridpoints(snap_WIND10, '>=', 8.0)
GT10_WIND850 = count_spatial_gridpoints(snap_WIND850, '>=', 10.0)
GT10_PRECT = count_spatial_gridpoints(snap_PRECT, '>=', 10.0)

meters_x_composite=11000
thresh_ike_850 = 17.5
thresh_ike_10 = 10.0
ike_850wind_scaling = 0.80   # Correction from 850 to surface winds
derivIKE850 = ((ike_850wind_scaling*snap_WIND850) ** 2) * (meters_x_composite ** 2)
derivIKE850 = derivIKE850.where(snap_WIND850 > thresh_ike_850, 0)
derivIKE850_sum = 0.5 * derivIKE850.sum(dim=['y', 'x'])
derivIKE850_sum = derivIKE850_sum * 1e-12
derivIKE10 = (snap_WIND10 ** 2) * (meters_x_composite ** 2)
derivIKE10 = derivIKE10.where(snap_WIND10 > thresh_ike_10, 0)
derivIKE10_sum = 0.5 * derivIKE10.sum(dim=['y', 'x'])
derivIKE10_sum = derivIKE10_sum * 1e-12

### Add PHIS to the output
snap_lat = ds_aux['snap_lat']
snap_lon = ds_aux['snap_lon']
ds_topo = xr.open_dataset('./obs-err/ERA5.topo.nc')
phis = ds_topo['PHIS'].values
phislats = ds_topo['lat'].values
phislons = ds_topo['lon'].values
interpolator = RegularGridInterpolator((phislats, phislons), phis, bounds_error=False, fill_value=np.nan)

def interpolate_phis(lat, lon, interpolator):
    points = np.array([lat, lon]).T
    return interpolator(points)

PHIS_values = interpolate_phis(snap_lat, snap_lon+360.0, interpolator)

# Reshape any new arrays
xslp = conform_to_reference_2d(xwind, min_SLP)
xmax_prect = conform_to_reference_2d(xwind, max_PRECT)
xmax_tmq = conform_to_reference_2d(xwind, max_TMQ)
xmax_wind10 = conform_to_reference_2d(xwind, max_WIND10)
xmax_wind850 = conform_to_reference_2d(xwind, max_WIND850)
xlt1000_slp = conform_to_reference_2d(xwind, LT1000_SLP)
xgt8_wind10 = conform_to_reference_2d(xwind, GT8_WIND10)
xgt10_wind850 = conform_to_reference_2d(xwind, GT10_WIND850)
xgt10_prect = conform_to_reference_2d(xwind, GT10_PRECT)
xike850 = conform_to_reference_2d(xwind, derivIKE850_sum)
xike10 = conform_to_reference_2d(xwind, derivIKE10_sum)
xphis = conform_to_reference_2d(xwind, PHIS_values)

# Write file
write_cyclone_tracks(
    'trajs/final.'+experiment,
    xix, xjy, xlat, xlon, xyear, xmonth, xday, xhour,
    xpres=(xpres,'.6e'),  # Specify the format for each optional column
    #xlt1000_slp= (xlt1000_slp, '.0f'),
    xwind=(xwind,'.6e'),
    xdpsl=(xdpsl,'.4e'),
    xurmw=(xurmw,'.6e'),
    xrmw =(xrmw, '.6e'),
    xr8  =(xr8,  '.6e'),
    #xike =(xike, '.6e'),
    #xike10 =(xike10, '.6e'),
    xike850 =(xike850, '.6e'),
    xslp =(xslp, '.6e'),
    xmax_wind10=(xmax_wind10,'.6e'),
    xmax_wind850=(xmax_wind850,'.6e'),
    xmax_prect=(xmax_prect,'.6e'),
    xgt10_prect=(xgt10_prect,'.0f'),
    xmax_tmq=(xmax_tmq,'.6e'),
    xgt8_wind10= (xgt8_wind10, '.0f'),
    xgt10_wind850= (xgt10_wind850, '.0f'),
    xphis= (xphis, '.6e')
)