import numpy as np
import matplotlib.pyplot as plt
import xarray as xr
import cartopy
import cartopy.crs as ccrs
import os
import matplotlib.patches as mpatches

historical=True
box_size=9.0
plot_index=20

root_dir = "/Users/cmz5202/Software/tgw-tc/netcdf/"
if historical:
    plotstring="hist"
    aux = "wrfout_d01_2005-08-27_00_00_00_3hourly.aux.nc"
    aux2 = "wrfout_d01_2005-08-27_00_00_00_3hourly.aux2.nc"
    prec3hr = "wrfout_d01_2005-08-27_00_00_00_3hourly.nc"
    center_lat=28.992945
    center_lon=-89.544250
else:
    plotstring="hotfar"
    aux = "wrfout_d01_2085-08-27_00_00_00_3hourly.aux.nc"
    aux2 = "wrfout_d01_2085-08-27_00_00_00_3hourly.aux2.nc"
    prec3hr = "wrfout_d01_2085-08-27_00_00_00_3hourly.nc"
    center_lat=28.877024
    center_lon=-89.431458

# Historical
#        277     29      -89.146942      26.702517       9.411511e+02    4.618120e+01    -4.6751e+00     3.554471e+01    5.000000e-01    6.750000e+00    4.802183e+10    2005    8       29      0
#        273     38      -89.538849      27.698549       9.408697e+02    4.482832e+01    -2.8140e-01     3.390970e+01    5.000000e-01    6.500000e+00    4.689358e+10    2005    8       29      6
#        272     50      -89.544250      28.992945       9.436472e+02    4.383317e+01    2.7775e+00      3.354059e+01    5.000000e-01    6.500000e+00    6.206907e+10    2005    8       29      12
#        270     63      -89.664734      30.407757       9.476641e+02    3.935865e+01    4.0169e+00      2.327278e+01    4.000000e-01    7.000000e+00    2.931679e+10    2005    8       29      18
#        271     78      -89.387665      32.017033       9.579952e+02    2.614924e+01    1.0331e+01      1.432309e+01    6.000000e-01    6.750000e+00    1.660234e+10    2005    8       30      0

# Hot far
#        277     28      -89.156921      26.595924       9.273777e+02    4.918905e+01    -3.2096e+00     3.891207e+01    4.000000e-01    6.750000e+00    8.891731e+10    2085    8       29      0
#        275     37      -89.307190      27.574308       9.289442e+02    5.123971e+01    1.5665e+00      3.619181e+01    5.000000e-01    6.500000e+00    1.666073e+11    2085    8       29      6
#        273     49      -89.431458      28.877024       9.376172e+02    4.548707e+01    8.6730e+00      3.494300e+01    5.000000e-01    6.250000e+00    5.238389e+10    2085    8       29      12
#        272     62      -89.425140      30.282936       9.417640e+02    4.069601e+01    4.1468e+00      2.675985e+01    5.000000e-01    7.000000e+00    7.438304e+10    2085    8       29      18
#        273     77      -89.143646      31.891199       9.556469e+02    2.781671e+01    1.3883e+01      1.633762e+01    6.000000e-01    7.000000e+00    4.569173e+10    2085    8       30      0

nc_aux = xr.open_dataset(root_dir + aux)
nc_aux2 = xr.open_dataset(root_dir + aux2)
nc_prec = xr.open_dataset(root_dir + prec3hr)

time = nc_aux.time
lat  = nc_aux.XLAT
lon  = nc_aux.XLONG
PREC = nc_prec.PRECT
TMQ  = nc_aux2.TMQ


plt.figure(figsize=(15, 10))
ax = plt.axes(projection=ccrs.PlateCarree())

# Adding geographic features with specified colors
ax.add_feature(cartopy.feature.LAND)
ax.add_feature(cartopy.feature.COASTLINE, edgecolor='white')  # Set coastlines to white color
ax.add_feature(cartopy.feature.BORDERS, linestyle='-', alpha=.5, edgecolor='white')  # Set borders to white color

# Set the extent of the map
ax.set_extent([-135, -59, 20, 50])

# Adding gridlines
gridlines = ax.gridlines(draw_labels=True)
gridlines.top_labels = False
gridlines.right_labels = False
gridlines.left_labels = False
gridlines.bottom_labels = False

# Adjust color scale and plot data with specified colorbar limits
im = plt.pcolormesh(lon, lat, TMQ[plot_index], cmap='inferno', vmin=10, vmax=110, transform=ccrs.PlateCarree())

# Shrink the vertical extent of the colorbar
plt.colorbar(im, pad=0.015, shrink=0.55)

# Format the time coordinate and set as title
time_str = time[plot_index].dt.strftime('%Y-%m-%d %H:%M').item()  # Adjust this line if necessary
plt.title(time_str, fontsize=20)
ax.set_xlabel('')
ax.set_ylabel('')

# Draw a XxX lat/lon box around the storm center
no_box = mpatches.Rectangle((center_lon - (box_size/2.), center_lat - (box_size/2.)), box_size, box_size, fill=False, edgecolor='lime', linewidth=4, linestyle='-', transform=ccrs.PlateCarree())
ax.add_patch(no_box)

# Apply tight layout to minimize whitespace
plt.tight_layout(pad=0)  # Reduce padding around the figure

#plt.savefig('./figs/2dTMQ_'+plotstring+'.pdf')
plt.savefig('./figs/2dTMQ_'+plotstring+'.png', dpi=400, bbox_inches='tight', pad_inches=0)

#plt.show()