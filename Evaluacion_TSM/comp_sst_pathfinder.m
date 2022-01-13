function comp_sst_pathfinder(hisfile)
%
% Grafica comparativa de temperaturas superficiales observadas y modeladas.
%

clear all
close all

nr=netcdf(hisfile,'r');
lon_r=nr{'lon_rho'}(:,:);
lat_r=nr{'lat_rho'}(:,:);
time_r=nr{'scrum_time'}(:);
sst_r=nr{'temp'}(:,1,:,:);
close(nr)

lonmn=min(min(lon_r));
lonmx=max(max(lon_r));
latmn=min(min(lat_r));
latmx=max(max(lat_r));

np=netcdf('/ocean/ROMS/DATABASE/SST_pathfinder/climato_pathfinder.nc','r');
lon_p=np{'X'}(:);
lat_p=np{'Y'}(:);
time_p=np{'T'}(:);
sst_p=np{'SST'}(:,:,:);
close(np);

indxlon=find(lon_p >= lonmn & lon_p <= lonmx);
indxlat=find(lat_p >= latmn & lat_p <= latmx);

alon_p=lon_p(indxlon);
alat_p=lat_p(indxlat);
asst_p=sst_p(:,indxlat,indxlon);

%
%save -V7 eval_benguela.mat sst_r time_r lon_r lat_r asst_p alat_p alon_p
%

mask_r=squeeze(sst_r(1,1,:,:));
mask_r(mask_r>0)=1;
mask_r(mask_r==0)=NaN;

%
% Figura 1 : Promedio, Desviacion Estandard y Diferencia Estacional 
%

prom_mr=[];
std_mr=[];
prom_mp=[];
std_mp=[];

for i=1:12
    aux1=reshape(sst_r(i,1,:,:),1,1892);
    aux2=reshape(asst_p(i,:,:),1,21942);
    aux1(aux1==0)=[];
    aux2((isnan(aux2) == 1))=[];
    prom_mr=[prom_mr mean(aux1)];
    std_mr=[std_mr std(aux1)];
    prom_mp=[prom_mp mean(aux2)];
    std_mp=[std_mp std(aux2)];
end

difer=prom_mr-prom_mp;

fecha=datenum(2009,1:12,15);

figure(1)

subplot(2,1,1)
errorbar(fecha,prom_mp,std_mp,"~ ",fecha,prom_mr,std_mr);
title('Promedio Mensual TSM : Caso BENGUELA')
legend('ROMS','PATHFINDER')
datetick('x','mmm')
ylabel('[ C]')
axis([datenum(2009,1,1) datenum(2009,12,31) 14 22])

subplot(2,1,2)
plot(fecha,difer,'-xr');
legend('ROMS - PATHFINDER')
datetick('x','mmm')
xlabel('Mes Climatologico')
ylabel('[ C]')
axis([datenum(2009,1,1) datenum(2009,12,31) -1.4 -0.4])

print -f1 -dpng promedio_estacional_tsm_benguela.png

%
% Figura 2 : Histograma 
%

aux1=reshape(sst_r,1,22704);
aux2=reshape(asst_p,1,263304);
aux1(aux1==0)=[];
aux2((isnan(aux2) == 1))=[];

mean_r=mean(aux1);
median_r=median(aux1);
std_r=std(aux1);

mean_p=mean(aux2);
median_p=median(aux2);
std_p=std(aux2);

figure(2)

subplot(1,2,1)
hist(aux1,30,100)
title('ROMS')
ylabel('Porcentaje [%]')
xlabel('[ C]')
axis([12 24 0 10])
hold on
plot([mean_r mean_r],[0 10],'r',[median_r median_r],[0 10],'g', ...
	[mean_r-std_r mean_r-std_r],[0 10],'k', ... 
        [mean_r+std_r mean_r+std_r],[0 10],'k')
%legend([],'Mean','Median','Desv.Est')
hold off

subplot(1,2,2)
hist(aux2,30,100)
title('Pathfinder HiRes')
xlabel('[ C]')
axis([12 24 0 10])
hold on
plot([mean_p mean_p],[0 10],'r',[median_p median_p],[0 10],'g', ...
	[mean_p-std_p mean_p-std_p],[0 10],'k', ... 
        [mean_p+std_p mean_p+std_p],[0 10],'k')
hold off

print -f2 -dpng histograma_tsm_benguela.png

%
% Figura 3 : Scatterplot 
%
%% sst_r time_r lon_r lat_r asst_p alat_p alon_p

figure(3)
 [lon_m, lat_m]=meshgrid(lon_r(1,:),lat_r(:,1));
 [plon_m, plat_m]=meshgrid(alon_p,alat_p);

sstp_l=squeeze(sst_r(:,1,:,:)).*0;

for i=1:12
 sstp_l(i,:,:) = interp2(plon_m,plat_m, ...
         squeeze(asst_p(i,:,:)),lon_m,lat_m,'cubic');
end

scat_r=reshape(sst_r,1,22704);
scat_p=reshape(sstp_l,1,22704);

plot(scat_r,scat_p,'xr',[12 24],[12 24],'k')
xlabel('ROMS')
ylabel('Pathfinder LowRes')
axis([12 24 12 24]) 
grid on
box off

print -f3 -dpng scatterplot_tsm_benguela.png

%
% Figura 4 : Diferencia Espacial 
%

figure(4)
subplot(2,2,1)

aux1=squeeze(sst_r(1,1,:,:));
aux1(aux1==0)=NaN;
surface(lon_r,lat_r,aux1)
axis([min(lon_r(1,:)) max(lon_r(1,:)) min(lat_r(:,1)) max(lat_r(:,1))])
title('ROMS')
h=colorbar;
caxis(h,[12 24])
shading flat

subplot(2,2,2)

aux2=squeeze(sstp_l(1,:,:));
aux2=aux2.*mask_r;
surface(lon_r,lat_r,aux2)
axis([min(lon_r(1,:)) max(lon_r(1,:)) min(lat_r(:,1)) max(lat_r(:,1))])
title('Pathfinder LowRes')
h=colorbar;
caxis(h,[12 24])
shading flat

subplot(2,2,3)

d_sst = aux1-aux2;
d_sst=d_sst.*mask_r;
surface(lon_r,lat_r,d_sst)
axis([min(lon_r(1,:)) max(lon_r(1,:)) min(lat_r(:,1)) max(lat_r(:,1))])
title('ROMS - Pathfinder')
colorbar
shading flat

print -f4 -dpng diferencias_superficie_tsm_benguela.png

