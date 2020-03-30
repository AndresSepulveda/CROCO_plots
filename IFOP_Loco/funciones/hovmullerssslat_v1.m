function hovmullerssslat_v1(fname,Yorig,posi,posf,tname,step)

cmap1=colormap_cpt('algae');
cmap2=colormap_cpt('balance');

nc=netcdf(fname);

clear day month year imonth thedate
day=zeros(length([posi:step:posf]),1);
year=zeros(length([posi:step:posf]),1);
imonth=zeros(length([posi:step:posf]),1);

i=1;
for n=posi:step:posf
[day(i),~,year(i),imonth(i),~]=get_date(fname,n,Yorig);
i=i+1;
end

dates=datenum(year,imonth,day);

%Var 
lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);
[~,~,mask]=read_latlonmask(fname,'u');
% lat=lat(:,1);
% lon=lon(1,:);
[idx1,idx2]=find(mask~=1);

salt=squeeze(nc{'salt'}(posi:step:posf,end,:,:));
for i=1:length(idx1)
salt(:,idx1(i),idx2(i))=NaN;
end
salt=squeeze(nanmean(salt,3));% time-lat

% figura
% ax1=figure('Position', [100, 100, 600, 400]);
h1=pcolor(dates,lat,salt');
set(h1, 'EdgeColor', 'none');
xlabel('')
% ylabel('Latitude','FontWeight','bold','FontSize',12)
title([tname],'FontWeight','bold','FontSize',13)
datetick('x','dd','keepticks','keeplimits')
caxis([34 35])

% barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' Salinity (PSU) ','FontWeight','bold','FontSize',12);
% colormap(ax1,cmap1)


return
