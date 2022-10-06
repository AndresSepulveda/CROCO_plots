start

infile='./DATA/mercator_MICHILE/clim_fisic_2000-2011.nc';
bryname='croco_bry_mercator_clim_mosa.nc';
grdname='croco_grd.nc';

theta_s=7;
theta_b=2;
hc=200;
N=42;
vtransform=2;
croco_time=15:30:345; 

create_bryfile(bryname,grdname,CROCO_title,[1 1 1 1],...
                       theta_s,theta_b,hc,N,...
                       croco_time,0,'clobber',vtransform);

nc_bry=netcdf(bryname,'write');

interp_method='linear';

OGCM_dir=
OGCM_prefix=
Y=
M=
Roa=
angle=
ntimes=length(croco_time);

%
% del infile (CMEMS)
%
nc=netcdf(infile,'r');
lonT=nc{'lonT'}(:);
latT=nc{'latT'}(:);
lonU=nc{'lonU'}(:);
latU=nc{'latU'}(:);
lonV=nc{'lonV'}(:);
latV=nc{'latV'}(:);
Z=-nc{'depth'}(:);
NZ=length(Z);
NZ=NZ-rmdepth;
Z=Z(1:NZ);
close(nc)

%
% GRD?
%
lon
lat
h
obc

for tndx_OGCM=1:ntimes
  interp_OGCM(OGCM_dir,OGCM_prefix,Y,M,Roa,interp_method,...
           lonU,latU,lonV,latV,lonT,latT,Z,tndx_OGCM,...
           nc_clm,nc_bry,lon,lat,angle,h,tndx_OGCM+itolap_a,obc,vtransform)
end

close(nc_bry);
