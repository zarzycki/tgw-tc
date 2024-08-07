## Cleanup?
rm -fv *.csv
rm -fv obs-err/*.csv
rm -fv obs-err/*.png
rm -fv trajs/final.*
rm -fv trajs/*.pdf
rm -frv figs/*
rm -frv stats/*
rm -frv supp-plots/*.png
rm -frv supp-plots/*.pdf

mkdir -p figs/

set -e

python write-traj.py Historical
python write-traj.py cold_far
python write-traj.py cold_near
python write-traj.py hot_far
python write-traj.py hot_near

### Analyze all TCs
python analyze-dist.py -1 -1 all
python analyze-dist.py -1 -1 ocn
python analyze-dist.py -1 -1 lnd

### Analyze all TCs between 980 and 1000mb
#python analyze-dist.py 980 1000

python csv-analysis.py all
python csv-analysis.py ocn
python csv-analysis.py lnd

python gen-table.py all
python gen-table.py ocn
python gen-table.py lnd

### Get Fig. 1 full field examples
python 2d_field.py --historical
python 2d_field.py --future

### Get Fig. 1 snap comparison examples
python snap_comparison.py

cd obs-err
( bash batch-errors.sh )
cd ..

### Supp images
cd supp-plots
python plot-shear.py
python plot-sst.py
cd ..

cd trajs
if ! type ncl &> /dev/null ; then
  echo "ERROR: ncl does not exist. Make sure ncl is in your path to plot_traj" ; exit 1
else
  ncl plot_traj.ncl
fi
cd ..

echo "DONE"