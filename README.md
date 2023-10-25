# CROCO_plots
Random files for plotting CROCO model output

# Util commands
ncatted -O -h -a parent_grid,global,m,c,"croco_grd.nc.2" croco_grd.nc.3 croco_grd.nc.3.new


 ncks -F -d time,1,24 20230515/croco_his.nc.3 20230516/croco_his.nc.3
 ncks -F -d time,25,48 20230515/croco_his.nc.3 20230516/croco_his.nc.3
 ncks -F -d time,49,72 20230515/croco_his.nc.3 20230516/croco_his.nc.3

# Creating big files

mode = bitor(nc_noclobber_mode,nc_64bit_offset_mode); nc_create_empty(clmname,mode); nc = netcdf(clmname,'write');

If the function nc_create_empty is not found add this to your start.m

addpath([myutilpath,'mexcdf/snctools'])

# For animations

convert -delay 100 croco_his_*.png all.gif

# For GPU

Use nvfortran in jobcomp

modify .baschrc to update nvfortran location

Add key OPENACC in cppdefs.h (instead of MPI/OpenMP?)

nvidia-smi for GPU info

You can select your card with the environment variable NVCOMPILER_ACC_DEVICE_NUM, I think default is 0. The number correspond to the number(s) returned by nvaccelinfo. See https://docs.nvidia.com/hpc-sdk//compilers/openacc-gs/index.html#env-vars  (Thanks to RBenshila) 
