#!/bin/bash

#
#    Limites Quemchi
#                     -42.05 (lat_u = 497)
#   -73.50 (lon_u = 396)      -73.20  (lon_u = 417)
#                    -42.22 (lat_u = 484)

##
##ncks -d xi_u,396,417 -d eta_v,484,497 -d xi_rho,396,417 -d eta_rho,484,497 roms_MIC_grd_v8b.nc latlons_Quemchi.nc
##

for j in 1 # {1..9}
do
	for i in {1..9}
	do
		echo $j $i
		ncks -d xi_u,396,417 -d eta_v,484,497 -d xi_rho,396,417 -d eta_rho,484,497 roms_his_20180${j}0${i}_l.nc Quemchi_20180${j}0${i}.nc
	done
	for i in  {10..31}
	do
		echo $j $i
		ncks -d xi_u,396,417 -d eta_v,484,497 -d xi_rho,396,417 -d eta_rho,484,497 roms_his_20180${j}${i}_l.nc Quemchi_20180${j}${i}.nc
	done
done

##
##ncks -h -A latlons_Quemchi.nc Quemchi/Quemchi_201801.nc 
##

#
#  s_rho is missing. Add.
#
## ncks -v s_rho /var/www/html/MOSAv6/seleccion_fecha_de_datos/2019-12-05/part_3d_roms_his_20191205.nc s_rho.nc
##
##ncks -h -A s_rho.nc Quemchi/Quemchi_201801.nc 
