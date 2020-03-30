function hovmullermld_v1(fname,Yorig,posi,posf)

%% hovmuller hbl (croco / otro / diferencia / diferencia promedio)

cmap1=colormap_cpt('deep');
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

hbl=squeeze(nanmean(squeeze(nc{'hbl'}(posi:posf,end,:,:)),3));% time-lat

% figura
ax1=figure('Position', [100, 100, 1000, 600]);
h1=pcolor(dates,lat,hbl');
set(h1, 'EdgeColor', 'none');
xlabel('')
ylabel('Latitude')
title('a) CROCO')
datetick('x','mmm')
caxis([20 160])
colormap(ax1,cmap1)

% subplot(1,4,1)
barra=colorbar(ax1,'Southoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,' MLD (m) ');
% a=get(barra);
% a=a.Position;
% barra.Position=[a(1) a(2)-0.15 pos2(1)+pos2(3)-a(1) a(4)/2];

return
