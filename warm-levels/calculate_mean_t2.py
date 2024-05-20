import sys
import xarray as xr
import glob
import csv
import os

def calculate_mean_t2(basedir, directory, casename, output_file):

    # Get list of files
    full_directory = os.path.join(basedir, directory)
    file_pattern = f"{full_directory}/*.nc"
    files = sorted(glob.glob(file_pattern))

    print("loading all files as a single dataset using xarray")
    # NOTE: TGW has weird times -- I don't care about them here so don't decode them
    ds = xr.open_mfdataset(files, combine='nested', concat_dim='Time', decode_times=False)
    print("... done loading")

    # Manually hardcode this to deal with slightly different array lengths
    NTIMES=118960
    ds_sliced = ds.isel(Time=slice(0, NTIMES))

    print("calculating mean of T2 over all dimensions for the sliced dataset")
    mean_t2 = ds_sliced['T2'].mean().values
    print("... done calculating mean")

    # Write the result to the CSV file
    with open(output_file, 'a', newline='') as csvfile:
        writer = csv.writer(csvfile, dialect='unix')
        writer.writerow([casename, mean_t2])

    print(f"Mean T2 in {directory} ({casename}): {mean_t2}")

if __name__ == "__main__":
    basedir = sys.argv[1]
    directory = sys.argv[2]
    casename = sys.argv[3]
    output_file = sys.argv[4]
    calculate_mean_t2(basedir, directory, casename, output_file)
