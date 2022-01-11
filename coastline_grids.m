%% coastline

close all
clear all;clc

nfile = 'croco_zeta_Y12M12.nc';% nombre del archivo

lat = ncread(nfile, 'lat_psi');% latitud 2D
lon = ncread(nfile, 'lon_psi');% longitud 2D

lati = double(lat(1, :))';% latitud 1D
loni = double(lon(:, 1));% longitud 1D

mask = ncread(nfile, 'mask_psi');% mask valores 0/1

figure
[C,hc] = contour(loni, lati, mask', [1 1], 'k');% Overlay contour line

lvls = hc.LevelList;
clvl = lvls(1);% choose level

startcols = find(C(1,:) == clvl);% find columns where the level begins

for k1 = 1:numel(startcols)
    xy{k1} = C(:, startcols(k1)+1:startcols(k1)+C(2, startcols(k1)));% get (x,y) coordinates
end
disp(['-> number of contours: ', num2str(length(xy))])
disp(['-> select one of them in the line "cs = ?"'])

% all contours
for i = 1:length(xy)
    plot(xy{i}(1, :), xy{i}(2, :), '-b')
    hold on
end

cs = 1;% contour selected (thick red line)

plot(xy{cs}(1, :), xy{cs}(2, :), '-r', 'linewidth', 2)

%% contour order

clear data
data(:, 1) = xy{cs}(1, :)';% lons
data(:, 2) = xy{cs}(2, :)';% lats

ugg = data;

lon_grillasmascercanas = ugg(:, 1);
lat_grillasmascercanas = ugg(:, 2);

lonlats = [(floor(100*ugg(:, 1)))/100 (floor(100*ugg(:, 2)))/100];

save('lonlats.mat','lonlats')

%% figure 

H = figure('Units', 'centimeters', 'Position', [1, 5, 30, 20]);
subplot(1, 2, 1)
m_proj('lambert', 'long', [min(loni) max(loni)], 'lat', [min(lati) max(lati)]);
m_pcolor(loni, lati, mask')
hold on
m_grid('lambert', ':', 'tickdir', 'out');

subplot(1, 2, 2)
m_proj('lambert', 'long', [min(loni) max(loni)], 'lat', [min(lati) max(lati)]);
m_pcolor(loni, lati, mask')
hold on
m_grid('linest', ':', 'tickdir', 'out');
m_plot(lon_grillasmascercanas(:), lat_grillasmascercanas(:), '-rs', 'markerfacecolor', 'r', 'markersize', 4)

