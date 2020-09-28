close all
clear al

%
% ncra -d time,1,31 temp_dgeo_2018.nc temp_ene_2018.nc
% Feb 32,59, Mar 60 90, Apr  91 102, May  121 151,  Jun 152 181, Jul 182 212,
% Ago 213 243, Sep 244 273, Oct  274 304, Sep  244 273, Oct  274 304, Nov 305 334, Dec  335 365

nc=netcdf('temp_ene_2018.nc','r');

temp=squeeze(nc{'temp'}(1,1,:,:));

close(nc)

dx=1.2;  % en km
dy=dx;

[Fx Fy]=gradient(temp,dx);

gtemp=(Fx.*Fx + Fy.*Fy).^(0.5);
