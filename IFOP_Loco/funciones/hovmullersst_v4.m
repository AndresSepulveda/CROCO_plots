function hovmullersst_v4(fname,Yorig,posi,posf,anio)

cmap1=colormap_cpt('thermal');
cmap2=colormap_cpt('balance');

nc=netcdf(fname);

clear day month year imonth thedate
day=zeros(length([posi:posf]),1);
year=zeros(length([posi:posf]),1);
imonth=zeros(length([posi:posf]),1);

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

clear dates
for i=1:12
aux=find(imonth==i);

sstaux=squeeze(nc{'temp'}(posi:posi+aux(end),end,:,:));
for k=1:length(idx1)
sstaux(:,idx1(k),idx2(k))=NaN;
end
sstaux=squeeze(nanmean(sstaux,3));% time-lat

sst(i,:)=nanmean(sstaux,1);

clear pos    
pos=find(imonth==i & year==anio);
pos(1);
pos(end);
tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');
% ax(i)=subplot(4,3,i);
dates(i)=datenum(anio,i,15);
end

figure('Position', [100, 100, 1000, 700]);
h1=pcolor(dates,lat,sst');
set(h1, 'EdgeColor', 'none');
xlabel('')
ylabel('Latitude','FontWeight','bold','FontSize',12)
% xlim([dates(1) dates(28)])
title(['Climatology of zonally averaged modeled SST'],'FontWeight','bold','FontSize',13)
datetick('x','mmm','keepticks','keeplimits')
caxis([10 20])
shading interp

barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,' SST (°C) ','FontWeight','bold','FontSize',12);

cmap1=colormap_cpt('sst.cpt');
colormap(cmap1)

return