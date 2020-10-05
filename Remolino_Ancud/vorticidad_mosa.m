clear; close all; clc;
addpath('/home/oartal/opt/croco/croco_tools/Visualization_tools')

direc = '/media/oartal/osvaldo1t/MOSA-ROMS_2018/AVG/';
dir_fig = '/home/oartal/Documentos/IFOP/Figuras/';
file1 = [direc,'roms_avg_ver.nc'];
file2 = [direc,'roms_avg_oto.nc'];
file3 = [direc,'roms_avg_inv.nc'];
file4 = [direc,'roms_avg_pri.nc'];
grdname = '/home/oartal/Documentos/Proyectos/IFOP_Pronostico/Datos/roms_MIC_grd_v8b.nc';

[lat,lon,mask,xi1] = get_vort(file1,grdname,1,42,1);
mask(mask==0)=NaN;
[~,~,~,xi2] = get_vort(file2,grdname,1,42,1);
[~,~,~,xi3] = get_vort(file3,grdname,1,42,1);
[~,~,~,xi4] = get_vort(file4,grdname,1,42,1);


figure(1); clf
set(gcf,'Position',get(0,'Screensize'));
set(gcf,'color',[1 1 1])
set(gcf,'InvertHardcopy','off')

subplot(1,4,1)
m_proj('miller','long',[-76 -72.5],'lat',[-47 -41]);
m_pcolor(lon,lat,(xi1).*mask);shading flat
cptcmap('BlueWhiteOrangeRed', 'mapping', 'scaled');
caxis([-0.0001 0.0001]);
c(1) = colorbar('Location','southoutside');
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6]);
title('Summer')

subplot(1,4,2)
m_proj('miller','long',[-76 -72.5],'lat',[-47 -41]);
m_pcolor(lon,lat,(xi2).*mask);shading flat
cptcmap('BlueWhiteOrangeRed', 'mapping', 'scaled');
caxis([-0.0001 0.0001]);
c(2) = colorbar('Location','southoutside');
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6]);
title('Autumn')

subplot(1,4,3)
m_proj('miller','long',[-76 -72.5],'lat',[-47 -41]);
m_pcolor(lon,lat,(xi3).*mask);shading flat
cptcmap('BlueWhiteOrangeRed', 'mapping', 'scaled');
caxis([-0.0001 0.0001]);
c(3) = colorbar('Location','southoutside');
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6]);
title('Winter')

subplot(1,4,4)
m_proj('miller','long',[-76 -72.5],'lat',[-47 -41]);
m_pcolor(lon,lat,(xi4).*mask);shading flat
cptcmap('BlueWhiteOrangeRed', 'mapping', 'scaled');
caxis([-0.0001 0.0001]);
c(4) = colorbar('Location','southoutside');
m_grid('box','fancy','tickdir','in','backcolor',[.6 .6 .6]);
title('Spring')

set(c(1),'position',[0.28 0.15 0.47 0.0275])
set(c(2),'position',[0.28 0.15 0.47 0.0275])
set(c(3),'position',[0.28 0.15 0.47 0.0275])
set(c(4),'position',[0.28 0.15 0.47 0.0275])
set(c(4),'Ticks',linspace(-1.0000e-04,1.0000e-04,5))

xlabel(c(4),'Vorticity')

img = getframe(gcf);
imwrite(img.cdata, [dir_fig,'vorticity_mosa_2018.png']);

