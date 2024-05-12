import xarray as xr
import numpy as np
import matplotlib.pyplot as plt

snap_his = xr.open_dataset('/Users/cmz5202/Software/tgw-tc/netcdf/composite_aux2_CONUS_TGW_WRF_Historical.nc')
snap_fut = xr.open_dataset('/Users/cmz5202/Software/tgw-tc/netcdf/composite_aux2_CONUS_TGW_WRF_SSP585_HOT_FAR.nc')
time = snap_his.snap_time
time_strings = time.dt.strftime('%Y-%m-%d %H:%M:%S').values
#for t in time_strings:
#    print(t)

# Ensure it's in datetime format for comparison; convert if necessary
if not isinstance(time.values[0], np.datetime64):
    time = pd.to_datetime(time.values)

# The target time as a string
target_time = '2005-08-29 12:00'

# Find the index
index = (time == np.datetime64(target_time)).argmax()  # This gives 0 if not found unless the match is at index 0

# Verify if the time is actually found
if time[index] == np.datetime64(target_time):
    print(f"Index of the time {target_time} is: {index}")
else:
    print(f"Time {target_time} not found in the array.")

snap_TMQ_his = snap_his.snap_TMQ[index]
snap_TMQ_fut = snap_fut.snap_TMQ[index]
diff = snap_TMQ_fut - snap_TMQ_his

# Assuming 'snap_TMQ_his', 'snap_TMQ_fut', and 'diff' are already defined Xarray DataArrays
snap_TMQ_his = snap_his.snap_TMQ[index]
snap_TMQ_fut = snap_fut.snap_TMQ[index]
diff = snap_TMQ_fut - snap_TMQ_his

# Create a figure with 3 subplots, arranged horizontally
fig, axs = plt.subplots(nrows=1, ncols=3, figsize=(15, 4), sharey='row', gridspec_kw={'width_ratios': [1, 1, 1]})

# Plot historical simulation
im1 = axs[0].pcolormesh(snap_TMQ_his, cmap='inferno', vmin=10, vmax=110)
fig.colorbar(im1, ax=axs[0], orientation='vertical')
axs[0].set_title('Historical TPW')
axs[0].set_aspect('auto')  # Adjust aspect ratio
axs[0].set_xticks([])  # Remove x tick marks
axs[0].set_yticks([])  # Remove y tick marks

# Plot future simulation
im2 = axs[1].pcolormesh(snap_TMQ_fut, cmap='inferno', vmin=10, vmax=110)
fig.colorbar(im2, ax=axs[1], orientation='vertical')
axs[1].set_title('Hot Far TPW')
axs[1].set_aspect('auto')  # Adjust aspect ratio
axs[1].set_xticks([])  # Remove x tick marks
axs[1].set_yticks([])  # Remove y tick marks

# Plot the difference
im3 = axs[2].pcolormesh(diff, cmap='RdBu_r', vmin=-35, vmax=35)
fig.colorbar(im3, ax=axs[2], orientation='vertical')
axs[2].set_title('Diff. TPW (Hot Far - Historical)')
axs[2].set_aspect('auto')  # Adjust aspect ratio
axs[2].set_xticks([])  # Remove x tick marks
axs[2].set_yticks([])  # Remove y tick marks

# Apply tight layout to minimize whitespace
plt.tight_layout(pad=0)  # Reduce padding around the figure

#plt.savefig('./figs/2dTMQ_'+plotstring+'.pdf')
plt.savefig('./figs/snap_panel_comparison.png', dpi=400, bbox_inches='tight', pad_inches=0)

plt.show()