#!/bin/bash

conda activate meteo

python write-traj.py Historical
python write-traj.py cold_far
python write-traj.py cold_near
python write-traj.py hot_far
python write-traj.py hot_near

## Analyze all TCs
python analyze-dist.py -1 -1

## Analyze all TCs between 980 and 1000mb
python analyze-dist.py 980 1000

