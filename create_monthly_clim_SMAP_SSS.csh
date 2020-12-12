#!/bin/bash

for yr in `seq 2015 2020`
do
	for j in  `seq 1 9`
	do
		ncks --mk_rec_dmn time SMAP_L3_SSS_${yr}0${j}_MONTHLY_V5.0.nc ${yr}0${j}.nc
	done
	for j in  `seq 10 12`
	do
		ncks --mk_rec_dmn time SMAP_L3_SSS_${yr}${j}_MONTHLY_V5.0.nc ${yr}${j}.nc	
	done
done


for j in `seq 1 9`
do
	ncrcat *0$j.nc aux_0${j}.nc
        ncra -F -d time,1,,1 aux_0${j}.nc 0${j}.nc 
done
for j in `seq 10 12`
do
	ncrcat *$j.nc aux_${j}.nc
        ncra -F -d time,1,,1 aux_${j}.nc ${j}.nc 
done

ncrcat ??.nc SMAP_L3_SSS_MONTHLY_CLIM_V5.0.nc

