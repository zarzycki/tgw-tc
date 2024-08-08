# tgw-tc

To reproduce results from Zarzycki et al., 2024 ("Changes in four decades of near-CONUS tropical cyclones in an ensemble of 12km thermodynamic global warming simulations"), follow these steps:

1. Create the Python environment with the required dependencies using either `mamba` or `conda`:

```
mamba env create -f tgw-tc.yml
```

If you prefer, you can use `conda` instead of `mamba`.

**Note:** If you already have NCL installed on your machine, comment out the `ncl` line in `tgw-tc.yml`. Be aware that NCL has questionable support on M1/M2/MX Macbooks. NCL is only required for a few plots and error statistics, and the code is designed to work without it.

2. Place the NetCDF files from [doi:10.5281/zenodo.11453972](https://doi.org/10.5281/zenodo.11453972) in a subfolder of this codebase named `netcdf`.

3. Run the following script:

```
bash auto-write.sh
```
