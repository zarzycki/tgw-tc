# tgw-tc

Assuming you have checked out this repository, to reproduce results from Zarzycki et al., 2024 run...

```
mamba env create -f tgw-tc.yml
```

to install a Python environment containing the required depencies. Use `conda` if you'd like.

NOTE: If you do not have NCL already installed on your machine, uncomment the `ncl` line in `tgw-tc.yml`. This is currently commented out due to a long list of other dependencies. Note that NCL has questionable support on M1/M2/MX Macbooks.

Then run:

```
bash auto-write.sh 
```