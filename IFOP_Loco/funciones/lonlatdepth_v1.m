function lonlatdepth_v1(fname,Yorig,posi,posf,step,tname)

cmap1=colormap_cpt('ch05m151012');
cmap1=flipud(cmap1);
map2=colormap_cpt('balance');

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

% salt=squeeze(nc{'salt'}(posi:posf,end,:,:));
% for i=1:length(idx1)
% salt(:,idx1(i),idx2(i))=NaN;
% end
% salt=squeeze(nanmean(salt,1));% lat-lon

gname=fname;
type='u';
clear z
i=1;
for n=posi:step:posf
    [z(i,:,:,:)]=get_depths(fname,gname,n,type);
    i=i+1;
end

z=squeeze(z(:,end,:,:));
z=squeeze(nanmean(z,1));% lat-lon

cplot=[0 0 0];

% figura
% ax1=figure('Position', [100, 100, 600, 400]);
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% h1=m_pcolor(lon(1:end-1),lat,z);
% set(h1, 'EdgeColor', 'none');
[C,h1]=m_contour(lon,lat,z,10,'color',cplot,'linewidth',1.5);
clabel(C,h1,'Color',cplot,'FontWeight','bold');
xlabel('')
% ylabel('Latitude','FontWeight','bold','FontSize',12)
title([tname],'FontWeight','bold','FontSize',13)
% datetick('x','dd','keepticks','keeplimits')
% caxis([-4 0])
m_gshhs_i('patch',[0.75 0.75 0.75]);
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');


% barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' Salinity [PSU]) ','FontWeight','bold','FontSize',12);
% colormap(ax1,cmap1)


return