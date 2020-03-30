function lonlatsss_v1(fname,Yorig,posi,posf,step,tname)

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

salt=squeeze(nc{'salt'}(posi:step:posf,end,:,:));
for i=1:length(idx1)
salt(:,idx1(i),idx2(i))=NaN;
end
salt=squeeze(nanmean(salt,1));% lat-lon
%%
cplot=[0 0 0];
% plot(1:100,1:100,'color',cplot,'linewidth',1.5)

%%
% figura
% ax1=figure('Position', [100, 100, 600, 400]);
% m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
[C,h1]=m_contour(lon,lat,salt,[34 34.1 34.2 34.3 34.4 34.5 34.6 34.7  34.8 34.9 35],'color',cplot,'linewidth',1.5);
clabel(C,h1,[34.3 34.5 34.7 34.9],'Color',cplot,'FontWeight','bold');
% % h1=m_pcolor(lon,lat,salt);
% % set(h1, 'EdgeColor', 'none');
% xlabel('')
% % ylabel('Latitude','FontWeight','bold','FontSize',12)
% title([tname],'FontWeight','bold','FontSize',13)
% % datetick('x','dd','keepticks','keeplimits')
% caxis([34 35])
% m_gshhs_i('patch',[0.75 0.75 0.75]);
% m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');

% barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' Salinity [PSU]) ','FontWeight','bold','FontSize',12);
% colormap(ax1,cmap1)

return