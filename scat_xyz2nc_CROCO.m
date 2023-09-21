%function scat_xyz2nc(filename,name,cmin,cmax);
function scat_xyz2nc_CROCO(filename);

%---------------------------------------------
% cargando batimetria
%---------------------------------------------

%start;

xyz_data=load(filename);

x=xyz_data(:,2);
y=xyz_data(:,1);
%y=y';

z=xyz_data(:,3);


%
% Traspasando datos a matrices
%
dx=1/240;
dy=dx;
lon_0=min(x):dx:max(x);
lat_0=min(y):dy:max(y);

[lon, lat]=meshgrid(lon_0,lat_0);

keyboard
[xx, yy, zz]=griddata(x,y,z,lon,lat);

save -ascii batiti.txt zz

%
% Create NetCDF file
%

grdname=['Talcahuano_grd.nc'];
nw=netcdf(grdname,'clobber');

%
% Create Dimensions
%

nw('X') = size(xx,1);
nw('Y') = size(xx,2);

%
% Create variables and attributes
%

nw{'lon'}  = ncfloat('X');
nw{'lat'}  = ncfloat('Y');
nw{'topo'} = ncfloat('Y','X');

nw{'topo'}.long_name =  ncchar('ocean depth');
nw{'topo'}.long_name =  'ocean depth';
nw{'topo'}.units = ncchar('meter');
nw{'topo'}.units = 'meter';


close(nw);

%
% Fill in the data
%

nc=netcdf(grdname,'write');
nc{'lon'}(:)=squeeze(xx(:,1));
nc{'lat'}(:)=squeeze(yy(1,:));
nc{'topo'}(:,:)=zz;

close(nc)

%  mesh(lon,lat,zz)
% hold on
% plot3(x,y,z,'o')
% hold off
