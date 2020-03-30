function lonlateke_v1(fname,Yorig,posi,posf,step,tname)

cmap1=colormap_cpt('ch05m151012');
cmap1=flipud(cmap1);
map2=colormap_cpt('balance');

% skip=18;

nc=netcdf(fname);

clear day month year imonth thedate
day=zeros(length([posi:step:posf]),1);
year=zeros(length([posi:step:posf]),1);
imonth=zeros(length([posi:step:posf]),1);

i=1;
for n=posi:posf
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

u=squeeze(nc{'u'}(posi:step:posf,end,:,:));
v=squeeze(nc{'v'}(posi:step:posf,end,:,:));
for i=1:length(idx1)
u(:,idx1(i),idx2(i))=NaN;
v(:,idx1(i),idx2(i))=NaN;
end
u=squeeze(nanmean(u,1));% lat-lon
v=squeeze(nanmean(u,1));% lat-lon
eketop=1/2.*sqrt((u*100).^2+(v*100).^2);

% u=squeeze(nc{'u'}(posi:posf,end,:,:));
% v=squeeze(nc{'v'}(posi:posf,end,:,:));
% for i=1:length(idx1)
% u(:,idx1(i),idx2(i))=NaN;
% v(:,idx1(i),idx2(i))=NaN;
% end
% u=squeeze(nanmean(u,1));% lat-lon
% v=squeeze(nanmean(u,1));% lat-lon
% ekebottom=1/2.*sqrt(u.^2+v.^2);
% 
% eke=(eketop+ekebottom)/2*100;% m/s to cm/s


% [lonmesh,latmesh]=meshgrid(lon,lat);

%%
cplot=[0 0 0];
% plot(1:100,1:100,'color',cplot,'linewidth',1.5)

%%
% figura
% ax1=figure('Position', [100, 100, 600, 400]);
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% m_quiver(lonmesh(1:skip:end,1:skip:end),latmesh(1:skip:end,1:skip:end),u(1:skip:end,1:skip:end),v(1:skip:end,1:skip:end),'color',cplot);
h1=m_pcolor(lon,lat,eketop);
set(h1, 'EdgeColor', 'none');
% xlabel('')
% % ylabel('Latitude','FontWeight','bold','FontSize',12)
title([tname],'FontWeight','bold','FontSize',13)
% % datetick('x','dd','keepticks','keeplimits')
caxis([0 20])
m_gshhs_i('patch',[0.75 0.75 0.75]);
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');

% barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' Salinity [PSU]) ','FontWeight','bold','FontSize',12);
% colormap(ax1,cmap1)

return