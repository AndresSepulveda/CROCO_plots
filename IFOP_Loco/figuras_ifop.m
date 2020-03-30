%% Salidas croco IFOP climatologicas 

actualdir=pwd;
crocodir='/home/chris/Documentos/croco_tools-v1.0';
cd(crocodir);
run start.m
cd(actualdir);

% cpt palettes
folder='/atmos/ALL_TOOLBOX/cpt_palettes';
addpath(genpath(folder));

% util functions
addpath('/home/chris/Documentos/Toolbox_WRF_matlab/funciones');
addpath('/home/chris/Documentos/Toolbox_WRF_matlab/funciones/m_map');
addpath('/atmos/ALL_TOOLBOX/seawater_ver3_3.1');

addpath([actualdir,'/funciones']);
figdir=[actualdir,'/figuras'];

% files
addpath('/media/chris/disco01/CROCOOUT');% croco d01
addpath('/media/chris/disco01');% croco d02

file='croco_avg.nc.1';% 

fname=[file];
nc=netcdf(fname);

lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);

% [lat,lon,mask]=read_latlonmask(fname,'u');
% lat=lat(:,1);
% lon=lon(1,:);

%% times croco_out

time=nc{'time'}(:);

clear day month year imonth thedate
day=zeros(length(time),1);
year=zeros(length(time),1);
imonth=zeros(length(time),1);

Yorig=1;

for i=1:length(time)
[day(i),~,year(i),imonth(i),~]=get_date(fname,i,Yorig);
end

% [day imonth year]

%% Posiciones a evaluar (time)

posi=find(imonth==1 & year==10);% posicion inicial a evaluar
posf=find(imonth==12 & year==10);% posicion final a evaluar

dates=datenum(year,imonth,day);

Yorig=1;% año de origen
anio=10;% año a evaluar

%% Surface plots

step=5;% cada 'step' pasos de tiempo

lonlatsst_v2(fname,Yorig,anio,imonth,year,step)% promedios mensuales
saveas(gcf,[figdir,'/001','.png']);close gcf;
lonlateke_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/002','.png']);close gcf;
lonlatmld_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/003','.png']);close gcf;
lonlatvaisala_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/004','.png']);close gcf;

%% hovmollers por latitud y longitud

hovmullersstlat_v2(fname,Yorig,anio,imonth,year,step)% separados por mens
saveas(gcf,[figdir,'/005','.png']);close gcf;
hovmullersstlon_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/006','.png']);close gcf;
%
hovmullerssslat_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/007','.png']);close gcf;
hovmullerssslon_v2(fname,Yorig,anio,imonth,year,step)
saveas(gcf,[figdir,'/008','.png']);close gcf;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% anual sst y sss
tname=[];
figure('Position', [100, 100, 640, 700]);
ax(1)=subplot(1,2,1);
hovmullersstlon_v1(fname,Yorig,posi(1),posf(end),tname,1)
barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
cmap1=colormap_cpt('sst.cpt');
colormap(ax(1),cmap1)
ylabel(barra,' Temperature [°C] ','FontWeight','bold','FontSize',12);
title([''],'FontSize',13)
datetick('y','dd/mm','keepticks','keeplimits')
xt=get(ax(1),'xtick');
for k=1:numel(xt);
    if xt(k)>0
xt1{k}=sprintf('%g°E',abs(round(xt(k),2)));
    elseif xt(k)<0
xt1{k}=sprintf('%g°W',abs(round(xt(k),2)));
    else
xt1{k}=sprintf('%g°0',abs(round(xt(k),2)));
end
set(ax(1),'xticklabel',xt1);
end

ax(2)=subplot(1,2,2);
hovmullerssslon_v1(fname,Yorig,posi(1),posf(end),tname,1)
barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
colormap(ax(2),flipud(colormap_cpt('ch05m151012')));
ylabel(barra,' Salinity [PSU] ','FontWeight','bold','FontSize',12);
title([''],'FontSize',13)
datetick('y','dd/mm','keepticks','keeplimits')
xt=get(ax(2),'xtick');
for k=1:numel(xt);
    if xt(k)>0
xt1{k}=sprintf('%g°E',abs(round(xt(k),2)));
    elseif xt(k)<0
xt1{k}=sprintf('%g°W',abs(round(xt(k),2)));
    else
xt1{k}=sprintf('%g°0',abs(round(xt(k),2)));
end
set(ax(2),'xticklabel',xt1);
end
saveas(gcf,[figdir,'/009','.png']);close gcf;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tname=[];
figure('Position', [100, 100, 700, 400]);
ax(1)=subplot(2,1,1);
hovmullersstlat_v1(fname,Yorig,posi(1),posf(end),tname,1)
barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
cmap1=colormap_cpt('sst.cpt');
colormap(ax(1),cmap1)
ylabel(barra,' Temperature [°C] ','FontWeight','bold','FontSize',12);
title([''],'FontSize',13)
datetick('x','dd/mm','keepticks','keeplimits')
xt=get(ax(1),'ytick');
for k=1:numel(xt);
    if xt(k)>0
xt1{k}=sprintf('%g°N',abs(round(xt(k),2)));
    elseif xt(k)<0
xt1{k}=sprintf('%g°S',abs(round(xt(k),2)));
    else
xt1{k}=sprintf('%g°EQ',abs(round(xt(k),2)));
end
set(ax(1),'yticklabel',xt1);
end

ax(2)=subplot(2,1,2);
hovmullerssslat_v1(fname,Yorig,posi(1),posf(end),tname,1)
barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
colormap(ax(2),flipud(colormap_cpt('ch05m151012')));
ylabel(barra,' Salinity [PSU] ','FontWeight','bold','FontSize',12);
title([''],'FontSize',13)
datetick('x','dd/mm','keepticks','keeplimits')
xt=get(ax(2),'ytick');
for k=1:numel(xt);
    if xt(k)>0
xt1{k}=sprintf('%g°N',abs(round(xt(k),2)));
    elseif xt(k)<0
xt1{k}=sprintf('%g°S',abs(round(xt(k),2)));
    else
xt1{k}=sprintf('%g°EQ',abs(round(xt(k),2)));
end
set(ax(2),'yticklabel',xt1);
end
saveas(gcf,[figdir,'/010','.png']);close gcf;

%% longitude vs depth plots (anual y mensual)

NS='S';
lat1=-30;% latitud del corte a evaluar
step=5;% paso de tiempo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% salinity
tname=[];
figure('Position', [100, 100, 600, 300]);
lonvsdepth_salinity_v1(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,step,tname)
barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
colormap(flipud(colormap_cpt('ch05m151012')));
ylabel(barra,' Salinity [PSU] ','FontWeight','bold','FontSize',12);
title(['Mean salinity at ',num2str(abs(lat1)),' °',NS],'FontSize',13)
set(gca, 'Color',[0.75 0.75 0.75])
saveas(gcf,[figdir,'/011','.png']);close gcf;
%
lonvsdepth_salinity_v2(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,anio,step)
saveas(gcf,[figdir,'/012','.png']);close gcf;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% temperature
tname=[];
figure('Position', [100, 100, 600, 300]);
lonvsdepth_temperature_v1(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,step,tname)
barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
colormap(colormap_cpt('sst.cpt'));
ylabel(barra,'Temperature [°C]','FontWeight','bold','FontSize',12);
title(['Mean temperature at ',num2str(abs(lat1)),' °',NS],'FontSize',13)
set(gca, 'Color',[0.75 0.75 0.75])
saveas(gcf,[figdir,'/013','.png']);close gcf;
%
lonvsdepth_temperature_v2(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,anio,step)
saveas(gcf,[figdir,'/014','.png']);close gcf;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wnd (current)
tname=[];
figure('Position', [100, 100, 600, 300]);
lonvsdepth_wnd_v1(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,step,tname)
barra=colorbar('Southoutside','FontWeight','bold','Linewidth',1);
colormap(colormap_cpt('temp 19lev'));
ylabel(barra,'Velocity [cm/s]','FontWeight','bold','FontSize',12);
title(['Mean meridional current at ',num2str(abs(lat1)),' °',NS],'FontSize',13)
set(gca, 'Color',[0.75 0.75 0.75])
saveas(gcf,[figdir,'/015','.png']);close gcf;
%
lonvsdepth_wnd_v2(fname,lat1,NS,posi(1),posf(end),imonth,year,Yorig,anio,step)
saveas(gcf,[figdir,'/016','.png']);close gcf;

%% validacion ifop

addpath([actualdir,'/validacion_ifop']);

% Cruise|Station|Type|Longitude|Latitude|Year|Month|Day|Hour|Minute|Second|Pressure[db]|Temperature[C]|Salinity[PSU]|Density[sigma-t]|Oxygen|Chlorop
% % data.Cruise
% data.Station=[];
% % data.Type=[];
% data.Longitude=[];
% data.Latitude=[];
% data.Year=[];
% data.Month=[];
% data.Day=[];
% data.Hour=[];
% data.Minute=[];
% data.Second=[];
% data.Pressure=[];
% data.Temperature=[];
% data.Salinity=[];
% data.Density=[];
% data.Oxygen=[];
% data.Chlorop=[];

%% topography

% Recorte datos de relieve etopo 1 minuto
[Z, refvec] = etopo('etopo1_ice_c_i2.bin', 1, [min(lat) max(lat)], [min(lon) max(lon)]);
latlim=linspace(min(lat),max(lat),size(Z,1));
lonlim=linspace(min(lon),max(lon),size(Z,2));

cmap=colormap_cpt('arctic');

%% topography map and ifop ctd positions

Fip200203=importdata('Fip_2002_03');
name=Fip200203.data;% ifop file

name(:,3)=name(:,3)*-1;
name(:,4)=name(:,4)*-1;
name(:,11)=sw_dpth(name(:,11),name(:,4));% negative for south and west 

t=1;
clear aux2
for i=unique(name(:,1))'

    idx=name(:,1)==i;
    aux=name(idx,[3 4]);
    aux2(t,:)=aux(1,:);
        
    t=t+1;
end

% lon=[-90 -60];
% lat=[-25 -55];

figure
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% [C,h]=draw_topo(fname,npts,[15],options);
% m_coast('patch',[0.9 0.9 0.9],'edgecolor','none');
% m_gshhs_i('patch',[.7 .9 .7]);

% m_contourf(lonlim,latlim,Z,126,'LineStyle','none')
m_pcolor(lonlim,latlim,Z);
hold on

% barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' h (m) ');
colormap(cmap)
caxis([-6000 4700]);
barra=colorbar('eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Topography [m]','FontWeight','bold','FontSize',12);
% m_text(pos_lon,pos_lat,pos_name)
m_gshhs_i('color','k');

idx=(aux2(:,1)>=min(lon) & aux2(:,1)<=max(lon) & aux2(:,2)>=min(lat) & aux2(:,2)<=max(lat));
m_plot(aux2(idx,1),aux2(idx,2),'marker','o','color','r','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
m_plot([min(lon) max(lon)],[-29 -29],'--m','linewi',1.5)
m_plot([min(lon) max(lon)],[-30 -30],'--m','linewi',1.5)
title('CTD locations','FontWeight','bold','FontSize',13)
xlabel('Longitude','FontWeight','bold','FontSize',12)
ylabel('Latitude','FontWeight','bold','FontSize',12)
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');
saveas(gcf,[figdir,'/017','.png']);close gcf;

%% ctd profiles ifop

idx2=(name(:,3)>=min(lon) & name(:,3)<=max(lon) & name(:,4)>=min(lat) & name(:,4)<=max(lat));

d1Var=name(idx2,12);
d2Var=name(idx2,13);
d3Var=name(idx2,11);

cmap1=flipud(colormap_cpt('temp-c'));
figure('Position', [100, 100, 400, 600]);
% ax1=subplot(1,2,1);
% theta_sdiag(squeeze(temp(tin,:,idx1,idx2)),squeeze(salt(tin,:,idx1,idx2)),squeeze(z(tin,:,idx1,idx2)));
theta_sdiag(d1Var(:),d2Var(:),-d3Var(:));
barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Depth [m] ','FontWeight','bold','FontSize',12);
% title(['CROCO at Lat:',num2str(lat0),' Lon:',num2str(lon0)],'FontSize',13)
title(['CTD profiles'],'FontSize',13)
colormap(flipud(cmap1))
caxis([-600 0])
xlim([34 35])
ylabel('Theta [°C]','FontWeight','bold','FontSize',12)
xlabel('Salinity [PSU]','FontWeight','bold','FontSize',12)
saveas(gcf,[figdir,'/018','.png']);close gcf;

%% bathymetry CROCO IFOP

bath=nc{'h'}(:);

[~,~,mask]=read_latlonmask(fname,'u');
% lat=lat(:,1);
% lon=lon(1,:);
[idx1,idx2]=find(mask~=1);

for i=1:length(idx1)
bath(idx1(i),idx2(i))=NaN;
end

cmap=colormap_cpt('njbath');

figure
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% [C,h]=draw_topo(fname,npts,[15],options);
% m_coast('patch',[0.9 0.9 0.9],'edgecolor','none');
% m_gshhs_i(max'patch',[.7 .9 .7]);

% m_contourf(lonlim,latlim,Z,126,'LineStyle','none')
m_pcolor(lon,lat,-bath);
hold on

% barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' h (m) ');
% colormap(cmap(1:end-55,:))
colormap(cmap)
caxis([-6000 4700]);
barra=colorbar('eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Bathymetry [m]','FontWeight','bold','FontSize',12);
% m_text(pos_lon,pos_lat,pos_name)
% m_gshhs_i('color','k');
m_gshhs_i('patch',[0.75 0.75 0.75]);

% idx=(aux2(:,1)>=min(lon) & aux2(:,1)<=max(lon) & aux2(:,2)>=min(lat) & aux2(:,2)<=max(lat));
% m_plot(aux2(idx,1),aux2(idx,2),'marker','o','color','r','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
% m_plot([min(lon) max(lon)],[-29 -29],'--m','linewi',1.5)
% m_plot([min(lon) max(lon)],[-30 -30],'--m','linewi',1.5)
% title('CTD locations','FontWeight','bold','FontSize',13)
xlabel('Longitude','FontWeight','bold','FontSize',12)
ylabel('Latitude','FontWeight','bold','FontSize',12)
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');

% h1=surf(lon,lat,-bath);
% axis tight
% set(h1, 'EdgeColor', 'none');
% set(gca, 'Color',[0.75 0.75 0.75])
% daspect([0.0002 0.02 0.02])
saveas(gcf,[figdir,'/019','.png']);close gcf;

%% difference bathymetry (CROCO - ETOPO1)

%interpolacion
[xq yq]=meshgrid(lon,lat); %croco
[xq2 yq2]=meshgrid(lonlim,latlim); %etopo1
for i=1%:length(temp(1,1,:))
zq = interp2(xq2,yq2,Z,xq,yq);
end

% bath=nc{'h'}(:);
% 
% [~,~,mask]=read_latlonmask(fname,'u');
% % lat=lat(:,1);
% % lon=lon(1,:);
% [idx1,idx2]=find(mask~=1);
% 
% for i=1:length(idx1)
% bath(idx1(i),idx2(i))=NaN;
% end

cmap=colormap_cpt('temp_19lev');

figure
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% [C,h]=draw_topo(fname,npts,[15],options);
% m_coast('patch',[0.9 0.9 0.9],'edgecolor','none');
% m_gshhs_i(max'patch',[.7 .9 .7]);

% m_contourf(lonlim,latlim,Z,126,'LineStyle','none')
m_pcolor(lon,lat,-bath-zq);
hold on

% barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' h (m) ');
% colormap(cmap(1:end-55,:))
colormap(cmap)
% caxis([-6000 4700]);
barra=colorbar('eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Bathymetry difference [m]','FontWeight','bold','FontSize',12);
% m_text(pos_lon,pos_lat,pos_name)
% m_gshhs_i('color','k');
m_gshhs_i('patch',[0.75 0.75 0.75]);

% idx=(aux2(:,1)>=min(lon) & aux2(:,1)<=max(lon) & aux2(:,2)>=min(lat) & aux2(:,2)<=max(lat));
% m_plot(aux2(idx,1),aux2(idx,2),'marker','o','color','r','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
% m_plot([min(lon) max(lon)],[-29 -29],'--m','linewi',1.5)
% m_plot([min(lon) max(lon)],[-30 -30],'--m','linewi',1.5)
% title('CTD locations','FontWeight','bold','FontSize',13)
xlabel('Longitude','FontWeight','bold','FontSize',12)
ylabel('Latitude','FontWeight','bold','FontSize',12)
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');
saveas(gcf,[figdir,'/020','.png']);close gcf;

%% ctd croco positions map

[~,~,mask]=read_latlonmask(fname,'u');
% lat=lat(:,1);
% lon=lon(1,:);
[idx1,idx2]=find(mask~=1);

skip=10;

t=1;
clear locations
for i=5:skip:length(lon)-5
    for j=5:skip:length(lat)-5
        if mask(j,i)==1
        locations(t,:)=[lon(i) lat(j)];
        t=t+1;
        end
    end
end

addpath('../');
lat0=locations(1:10,2);
lon0=locations(1:10,1);
% tin=[posi(1):5:posf(end)];

figure
m_proj('mercator','long',[min(lon) max(lon)],'lat',[min(lat) max(lat)]);
% [C,h]=draw_topo(fname,npts,[15],options);
% m_coast('patch',[0.9 0.9 0.9],'edgecolor','none');
% m_gshhs_i('patch',[.7 .9 .7]);

% m_contourf(lonlim,latlim,Z,126,'LineStyle','none')
m_pcolor(lon,lat,-bath);
hold on

% barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' h (m) ');
colormap(cmap)
caxis([-6000 0]);
barra=colorbar('eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Bathymetry [m]','FontWeight','bold','FontSize',12);
% m_text(pos_lon,pos_lat,pos_name)
% m_gshhs_i('color','k');

[meshlon,meshlat]=meshgrid(lon,lat);

% idx=(aux2(:,1)>=min(lon) & aux2(:,1)<=max(lon) & aux2(:,2)>=min(lat) & aux2(:,2)<=max(lat));
% m_plot(meshlon(2:skip:end-1,2:skip:end-1),meshlat(2:skip:end-1,2:skip:end-1),'marker','o','color','m','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')

for i=1:length(locations(:,2))
    if locations(i,2)>-29 & locations(i,1)>-72
        m_plot(locations(i,1),locations(i,2),'marker','o','color','m','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
    elseif locations(i,2)<-30 & locations(i,1)>-72
        m_plot(locations(i,1),locations(i,2),'marker','o','color',[0.9 1 0.1],'linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
    elseif locations(i,2)>=-30 & locations(i,2)<=-29 & locations(i,1)>-72
        m_plot(locations(i,1),locations(i,2),'marker','o','color','g','linewi',1,'linest','none','markersize',4,'markerfacecolor','w')
    end
end

% m_plot([min(lon) max(lon)],[-29 -29],'--m','linewi',1.5)
% m_plot([min(lon) max(lon)],[-30 -30],'--m','linewi',1.5)
title('CTD croco locations','FontWeight','bold','FontSize',13)
xlabel('Longitude','FontWeight','bold','FontSize',12)
ylabel('Latitude','FontWeight','bold','FontSize',12)
m_grid('linest','none','xtick',5,'ytick',5,'box','fancy','fontsize',10,'tickdir','out');
m_gshhs_i('patch',[0.75 0.75 0.75]);
saveas(gcf,[figdir,'/021','.png']);close gcf;

%% ctd croco profiles requested positions (CROCO points)

% idx=(locations(:,2)>-29 & locations(:,1)>-72);
% idx=(locations(:,2)<-30 & locations(:,1)>-72);
idx=(locations(:,2)>=-30 & locations(:,2)<=-29 & locations(:,1)>-72);
    
lat0=locations(idx,2);
lon0=locations(idx,1);

anio=10;

figure('Position', [100, 100, 800, 1000]);
for i=1:12
clear pos    
pos=find(imonth==i & year==anio);
pos(1);
pos(end);
tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');

tin=pos(1:5:end)';
ax(i)=subplot(4,3,i);
% lonlatdepth_v1(fname,Yorig,pos(1),pos(end),tname)
tsdiagram_v1(fname,lat0,lon0,tin)
title([tname],'FontWeight','bold','FontSize',13)
% set(gca, 'Color',[0.75 0.75 0.75])
end

for i=[2 3 5 6 8 9 11 12]
set(subplot(4,3,i),'yticklabel',[])
end

for i=[1 2 3 4 5 6 7 8 9]
set(subplot(4,3,i),'xticklabel',[])
end

for i=[1 4 7 10]
    ylabel(ax(i),'Theta (°C)','FontWeight','bold','FontSize',12)
end

for i=[10 11 12]    
xlabel(ax(i),'Salinity (PSU)','FontWeight','bold','FontSize',12)
end

pos=ax(2).Position;
pos2=ax(3).Position;

ax(2).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(5).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(8).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(11).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];

ax(3).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(6).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(9).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(12).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];

ax(1).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(4).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(7).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(10).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];

ax(1).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(4).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(7).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(10).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];

auxpos=ax(12).Position;

barra=colorbar(ax(12),'Eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,' Depth [m] ','FontWeight','bold','FontSize',12);

% barra.Position=[pos2(1)+0.15 barra.Position(2) barra.Position(3) pos(2)+pos(4)-barra.Position(2)];
barra.Position=[auxpos(1)+auxpos(3)+0.03 auxpos(2) barra.Position(3)+0.01 ax(3).Position(2)+ax(3).Position(4)-auxpos(2)];

% cmap1=colormap_cpt('38 rainbow18');
cmap1=colormap_cpt('humidity');
cmap2=colormap_cpt('28 hardcandy');

for i=1:12
% colormap(ax(i),[cmap2;flipud(cmap1(2:end-1,:))])
colormap(ax(i),[cmap1(1,:).*ones(25,3);cmap1(2,:).*ones(12,3);cmap1(3,:).*ones(12,3);cmap1(4,:).*ones(12,3);cmap1(5,:).*ones(12,3)...
    ;cmap1(6,:).*ones(12,3);cmap1(7,:).*ones(12,3);cmap1(8:end-2,:)])
% set(ax(i),'colorscale','log')
end
saveas(gcf,[figdir,'/022','.png']);close gcf;

