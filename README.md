# tgw-tc

Assuming you have checked out this repository, to reproduce results from Zarzycki et al., 2024 run...

```
mamba env create -f tgw-tc.yml
```

to install a Python environment containing the required depencies. Use `conda` if you'd like.

NOTE: If you have NCL already installed on your machine, comment the `ncl` line in `tgw-tc.yml`. Note that NCL has questionable support on M1/M2/MX Macbooks. NCL is only required for a few plots and error statistics, the code is designed to not fail if it is not installed.

You should also place the NetCDF files from doi:10.5281/zenodo.11453972 in a subfolder named "netcdf".

Then run:

```
bash auto-write.sh 
```
