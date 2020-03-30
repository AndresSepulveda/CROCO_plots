function lonlatvaisala_v1(fname,Yorig,posi,posf,step,tname)

cmap1=colormap_cpt('thermal');
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

temp=squeeze(nc{'temp'}(posi:step:posf,:,:,:));
for i=1:length(idx1)
temp(:,:,idx1(i),idx2(i))=NaN;
end
temp=squeeze(nanmean(temp,1));% lev-lat-lon

salt=squeeze(nc{'salt'}(posi:step:posf,:,:,:));
for i=1:length(idx1)
salt(:,:,idx1(i),idx2(i))=NaN;
end
salt=squeeze(nanmean(salt,1));% lev-lat-lon

gname=fname;
type='u';
clear z
i=1;
for n=posi:step:posf
    [z(i,:,:,:)]=get_depths(fname,gname,n,type);
    i=i+1;
end
for i=1:length(idx1)
z(:,:,idx1(i),idx2(i))=NaN;
end
z=squeeze(nanmean(z,1));% lev-lat-lon


latin=readlat(nc);
for k=1:size(temp,1)
for i=1:size(temp,2)
    for j=1:size(temp,3)
temp(k,i,j) = sw_temp(salt(k,i,j),temp(k,i,j),sw_pres(z(k,i,j),latin(i,j)),0);% potential temperature to temperature
    end
end
end

clear bfrq
% bfrq=zeros(size(temp,2),size(temp,3));

for i=1:size(temp,2)
    for j=1:size(temp,3)
%         salinidad=flipud(squeeze(salt(:,i,j)))
%         temperatura=flipud(squeeze(temp(:,i,j)))
%         profundidad=flipud(squeeze(z(:,i,j)))
% MLD(i,j) = get_mld(fliplr(squeeze(salt(:,i,j))),fliplr(squeeze(temp(:,i,j))),fliplr(squeeze(z(:,i,j))));
% MLD(i,j) = ra_mld(),flipud(squeeze(z(:,i,j))),0.3);
[bfrq(:,i,j),~,~] = sw_bfrq((squeeze(salt(end-5:end,i,j))),(squeeze(temp(end-5:end,i,j))),sw_pres(z(end-5:end,i,j),latin(i,j)));
    end
end

size(bfrq)

% figura
% ax1=figure('Position', [100, 100, 600, 400]);
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
h1=m_pcolor(lon,lat,squeeze(mean(bfrq,1)));
set(h1, 'EdgeColor', 'none');
hold on
xlabel('')
% ylabel('Latitude','FontWeight','bold','FontSize',12)
title([tname],'FontWeight','bold','FontSize',13)
% datetick('x','dd','keepticks','keeplimits')
% caxis([-100 0])
m_gshhs_i('patch',[0.75 0.75 0.75]);
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');

% barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' SST (°C) ','FontWeight','bold','FontSize',12);
% colormap(ax1,cmap1)

return