%function [z]=get_depths(fname,gname,tindex,type);
close all
clear all
win_start

zetasG0=get_depths('croco_avg.nc','croco_grd.nc',1,'r');
save zetas_G0.mat zetasG0

nc=netcdf('croco_zeta.nc','w');
nc{'zetas'}(1,:,:,:)=zetasG0;
close(nc)

zetasG1=get_depths('croco_avg.nc.1','croco_grd.nc.1',1,'r');
save zetas_G1.mat zetasG1

nc=netcdf('croco_zeta.nc.1','w');
nc{'zetas'}(1,:,:,:)=zetasG1;
close(nc)

zetasG2=get_depths('croco_avg.nc.2','croco_grd.nc.2',1,'r');
save zetas_G2.mat zetasG2

nc=netcdf('croco_zeta.nc.2','w');
nc{'zetas'}(1,:,:,:)=zetasG2;
close(nc)
