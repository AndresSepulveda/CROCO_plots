win_start
close all

latmin=-38;
latmax=-26;
lonmin=8;
lonmax=22;

dl=1/3;

filename='.\DATASETS_CROCOTOOLS\SST_pathfinder\climato_pathfinder.nc';
pf=netcdf(filename,'r');
% nc('X') = 4096;
% nc('Y') = 2048;
% nc('T') = 12;
lon=pf{'X'}(:);
lat=pf{'Y'}(:);
tiempo=pf{'T'}(:);
sst=pf{'SST'}(:,:,:);
close(pf)

indxlon=find(lon > lonmin & lon < lonmax);
indxlat=find(lat > latmin & lat < latmax);

lon_area=lon(indxlon);
lat_area=lat(indxlat);
sst_area=sst(:,indxlat,indxlon);

newlat=latmax:-dl:latmin;
newlon=lonmin:dl:lonmax;

[new_lon_area, new_lat_area]=meshgrid(newlon,newlat);
[old_lon_area, old_lat_area]=meshgrid(lon_area,lat_area);

for i=1:12
    figure(i)
    sst_area_new=griddata(old_lon_area,old_lat_area,squeeze(sst_area(i,:,:)),new_lon_area,new_lat_area);
    subplot(1,2,1)
    pcolor(lon_area,lat_area,squeeze(sst_area(i,:,:)));
    subplot(1,2,2)
    pcolor(new_lon_area,new_lat_area,squeeze(sst_area_new(:,:)));
end