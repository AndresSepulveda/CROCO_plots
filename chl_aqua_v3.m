clear all
close all


%% 
% Enero 2021 - Ignacio Acuna N. (ignacioacu2016@udec.cl)
% EL script genera graficas de resultados de clorofila superficial de
% croco, de datos satelitales (AQUA/MODIS) para la misma zona con la misma 
%resoluciÃ³n de croco, y la diferencias entre datos y modelo.  
%
%
mes1=csvread('CHL_CLIM_01.csv');
mes2=csvread('CHL_CLIM_02.csv');
mes3=csvread('CHL_CLIM_03.csv');
mes4=csvread('CHL_CLIM_04.csv');
mes5=csvread('CHL_CLIM_05.csv');
mes6=csvread('CHL_CLIM_06.csv');
mes7=csvread('CHL_CLIM_07.csv');
mes8=csvread('CHL_CLIM_08.csv');
mes9=csvread('CHL_CLIM_09.csv');
mes10=csvread('CHL_CLIM_10.csv');
mes11=csvread('CHL_CLIM_11.csv');
mes12=csvread('CHL_CLIM_12.csv'); %Ingresar datos de climatologÃ­a mensual

sat=[mes1 mes2 mes3 mes4 mes5 mes6 mes7 mes8 mes9 mes10 mes11 mes12];
sat=reshape(sat,[720,1440,12]);
s=size(sat);
data=squeeze(mean(reshape(sat,[s(1:2),12,s(3)/12]),3));

% calculamos 
filename='croco_avg_anual.nc'; %Nombre de archivo de CROCO (.his o .avg)
STEP=1;     %Paso de tiempo de archivo croco con el que se quiere comparar

%% CARGA DE ARCHIVOS Y GRILLA
modelo=ncread(filename,'CHLA');
modelo=modelo(:,:,32,STEP)';
modelo(find(modelo==0))=NaN;
LON_CROCO=ncread(filename,'lon_rho');
LAT_CROCO=ncread(filename,'lat_rho');
[X_CROCO,Y_CROCO]=size(LON_CROCO);

[Y_DATA,X_DATA,NDATA]=size(data);
LON_DATA=linspace(-180,180,X_DATA);
LAT_DATA=linspace(-90,90,Y_DATA);

%% POSICIONES DE GRILLA DE DATOS CORRESPONDIENTES A DOMINIO 
difx=abs(min(min(LON_CROCO))-LON_DATA);
dify=abs(min(min(LAT_CROCO))-LAT_DATA);
minx=min(abs(min(min(LON_CROCO))-LON_DATA));
miny=min(abs(min(min(LAT_CROCO))-LAT_DATA));
poslon1=find(difx == minx);
poslat1=find(dify == miny);
difx=abs(max(max(LON_CROCO))-LON_DATA);
dify=abs(max(max(LAT_CROCO))-LAT_DATA);
minx=min(abs(max(max(LON_CROCO))-LON_DATA));
miny=min(abs(max(max(LAT_CROCO))-LAT_DATA));
poslon2=find(difx == minx);
poslat2=find(dify == miny);
%% DATOS A RESOLUCIÃ“N DE MODELO 
CORTE=data(poslat1:poslat2,poslon1:poslon2);
[Y_CORTE,X_CORTE]=size(CORTE);
[x,y]=meshgrid(1:X_CORTE,1:Y_CORTE);
[u,v]=meshgrid(linspace(1,X_CORTE,X_CROCO),linspace(1,Y_CORTE,Y_CROCO));
NUEVA=interp2(x,y,CORTE,u,v);
resta=NUEVA-modelo;

%% FIGURAS

figure()
pcolor(LON_CROCO',LAT_CROCO',NUEVA)
set(gca,'FontSize',12,'LineWidth',2)
colorbar
ylabel(colorbar,'[mg/mm3]','FontSize',16)
xlabel('Lon','FontSize',20)
ylabel('Lat','FontSize',20)
title('DATOS','FontSize',18)
%saveas(gcf,'path','png')


figure()
pcolor(LON_CROCO',LAT_CROCO',modelo)
set(gca,'FontSize',12,'LineWidth',2)
colorbar
ylabel(colorbar,'[mg/mm3]','FontSize',16)
xlabel('Lon','FontSize',20)
ylabel('Lat','FontSize',20)
title('MODELO','FontSize',18)
%saveas(gcf,'path','png')


figure()
pcolor(LON_CROCO',LAT_CROCO',resta)
set(gca,'FontSize',12,'LineWidth',2)
colorbar
ylabel(colorbar,'[mg/mm3]','FontSize',16)
xlabel('Lon','FontSize',20)
ylabel('Lat','FontSize',20)
title('DATOS-MODELO','FontSize',18)
%saveas(gcf,'path','png')