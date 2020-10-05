clear; close all; clc;
%
%  Created by: Osvaldo Artal    (osvaldo.artal@ifop.cl) 2020
%  Modified:   Andres Sepulveda (andres.sepulveda@gmail.com)
%
win_start
direc = './';
dir_fig = './';
file = ['temp_dgeo_2018.nc'];
grdname = 'roms_MIC_grd_v8b.nc';
dx=1.2; % km

nc = netcdf(grdname,'r');
lon = nc{'lon_rho'}(:);
lat = nc{'lat_rho'}(:);
mask= nc{'mask_rho'}(:);
close(nc)
mask(mask==0)=NaN;


nc = netcdf(file,'r');
temp01 = squeeze(nc{'temp'}(1:31,1,:,:));
temp02 = squeeze(nc{'temp'}(32:59,1,:,:));
temp03 = squeeze(nc{'temp'}(60:90,1,:,:));
temp04 = squeeze(nc{'temp'}(91:120,1,:,:));
temp05 = squeeze(nc{'temp'}(121:151,1,:,:));
temp06 = squeeze(nc{'temp'}(152:181,1,:,:));
temp07 = squeeze(nc{'temp'}(182:212,1,:,:));
temp08 = squeeze(nc{'temp'}(213:243,1,:,:));
temp09 = squeeze(nc{'temp'}(244:273,1,:,:));
temp10 = squeeze(nc{'temp'}(274:304,1,:,:));
temp11 = squeeze(nc{'temp'}(305:334,1,:,:));
temp12 = squeeze(nc{'temp'}(335:365,1,:,:));
close(nc)

temp01 = squeeze(mean(temp01)).*mask;
[gtx01,gty01] = gradient(temp01,dx);
G01 = sqrt(gtx01.^2+gty01.^2);

temp02 = squeeze(mean(temp02)).*mask;
[gtx02,gty02] = gradient(temp02,dx);
G02 = sqrt(gtx02.^2+gty02.^2);

temp03 = squeeze(mean(temp03)).*mask;
[gtx03,gty03] = gradient(temp03,dx);
G03 = sqrt(gtx03.^2+gty03.^2);

temp04 = squeeze(mean(temp04)).*mask;
[gtx04,gty04] = gradient(temp04,dx);
G04 = sqrt(gtx04.^2+gty04.^2);

temp05 = squeeze(mean(temp05)).*mask;
[gtx05,gty05] = gradient(temp05,dx);
G05 = sqrt(gtx05.^2+gty05.^2);

temp06 = squeeze(mean(temp06)).*mask;
[gtx06,gty06] = gradient(temp06,dx);
G06 = sqrt(gtx06.^2+gty06.^2);

temp07 = squeeze(mean(temp07)).*mask;
[gtx07,gty07] = gradient(temp07,dx);
G07 = sqrt(gtx07.^2+gty07.^2);

temp08 = squeeze(mean(temp08)).*mask;
[gtx08,gty08] = gradient(temp08,dx);
G08 = sqrt(gtx08.^2+gty08.^2);

temp09 = squeeze(mean(temp09)).*mask;
[gtx09,gty09] = gradient(temp09,dx);
G09 = sqrt(gtx09.^2+gty09.^2);

temp10 = squeeze(mean(temp10)).*mask;
[gtx10,gty10] = gradient(temp10,dx);
G10 = sqrt(gtx10.^2+gty10.^2);

temp11 = squeeze(mean(temp11)).*mask;
[gtx11,gty11] = gradient(temp11,dx);
G11 = sqrt(gtx11.^2+gty11.^2);

temp12 = squeeze(mean(temp12)).*mask;
[gtx12,gty12] = gradient(temp12,dx);
G12 = sqrt(gtx12.^2+gty12.^2);

%%
figure(1);
set(gcf,'Position',get(0,'Screensize'));
set(gcf,'color',[1 1 1])
set(gcf,'InvertHardcopy','off')

ax(1) = subplot(2,3,1);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G01.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(1) = colorbar('Location','eastoutside');
cptcmap('Reds_08','mapping','scaled')   % Valid for all plots
title('Enero, 2018')

ax(2) = subplot(2,3,2);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G02.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(2) = colorbar('Location','eastoutside');
title('Febrero, 2018')

ax(3) = subplot(2,3,3);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G03.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(3) = colorbar('Location','eastoutside');
title('Marzo, 2018')

ax(4) = subplot(2,3,4);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G04.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(4) = colorbar('Location','eastoutside');
title('Abril, 2018')

ax(5) = subplot(2,3,5);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G05.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(5) = colorbar('Location','eastoutside');
title('Mayo, 2018')

ax(6) = subplot(2,3,6);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G06.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(6) = colorbar('Location','eastoutside');
title('Junio, 2018')


set(c(1),'Position',[0.86 0.2 0.013 0.65])
set(c(2),'Position',[0.86 0.2 0.013 0.65])
set(c(3),'Position',[0.86 0.2 0.013 0.65])
set(c(4),'Position',[0.86 0.2 0.013 0.65])
set(c(5),'Position',[0.86 0.2 0.013 0.65])
set(c(6),'Position',[0.86 0.2 0.013 0.65])

set(ax(1),'Position',[0.1  .55 0.3 0.3])
set(ax(2),'Position',[0.32 .55 0.3 0.3])
set(ax(3),'Position',[0.54 .55 0.3 0.3])
set(ax(4),'Position',[0.1  .1 0.3 0.3])
set(ax(5),'Position',[0.32 .1 0.3 0.3])
set(ax(6),'Position',[0.54 .1 0.3 0.3])

title(c(1),'°C/km')
img = getframe(gcf);
imwrite(img.cdata, [dir_fig,'gradient_temp_2018S1.png']);

%
%
%

figure(2);
set(gcf,'Position',get(0,'Screensize'));
set(gcf,'color',[1 1 1])
set(gcf,'InvertHardcopy','off')

ax(1) = subplot(2,3,1);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G07.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(1) = colorbar('Location','eastoutside');
cptcmap('Reds_08','mapping','scaled')   % Valid for all plots
title('Julio, 2018')

ax(2) = subplot(2,3,2);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G08.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(2) = colorbar('Location','eastoutside');
title('Agosto, 2018')

ax(3) = subplot(2,3,3);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G09.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(3) = colorbar('Location','eastoutside');
title('Septiembre, 2018')

ax(4) = subplot(2,3,4);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G10.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(4) = colorbar('Location','eastoutside');
title('Octubre, 2018')

ax(5) = subplot(2,3,5);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G11.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(5) = colorbar('Location','eastoutside');
title('Noviembre, 2018')

ax(6) = subplot(2,3,6);
m_proj('miller','long',[-73.60 -72.20],'lat',[-42.45 -41.4]);
m_pcolor(lon,lat,G12.*mask); shading flat
hold on
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6],'xtick',4,'ytick',4);
caxis([0 0.3])
c(6) = colorbar('Location','eastoutside');
title('Diciembre, 2018')


set(c(1),'Position',[0.86 0.2 0.013 0.65])
set(c(2),'Position',[0.86 0.2 0.013 0.65])
set(c(3),'Position',[0.86 0.2 0.013 0.65])
set(c(4),'Position',[0.86 0.2 0.013 0.65])
set(c(5),'Position',[0.86 0.2 0.013 0.65])
set(c(6),'Position',[0.86 0.2 0.013 0.65])

set(ax(1),'Position',[0.1  .55 0.3 0.3])
set(ax(2),'Position',[0.32 .55 0.3 0.3])
set(ax(3),'Position',[0.54 .55 0.3 0.3])
set(ax(4),'Position',[0.1  .1 0.3 0.3])
set(ax(5),'Position',[0.32 .1 0.3 0.3])
set(ax(6),'Position',[0.54 .1 0.3 0.3])

title(c(1),'°C/km')
img = getframe(gcf);
imwrite(img.cdata, [dir_fig,'gradient_temp_2018S2.png']);











