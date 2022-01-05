%% add paths

% m_map
dir = '/atmos/ALL_TOOLBOX/m_map';
addpath([dir]);%

% t_tide
addpath('t_tide_v1.4beta');

set(0,'defaultfigurecolor',[1 1 1])

%% read file

clear all; clc

% file name
fname = 'croco_zeta_Y12M12.nc';

% read latitude and longitude
lat = ncread(fname, 'lat_rho');
lon = ncread(fname, 'lon_rho');
lat = lat(1, :)';
lon = lon(:, 1);

lon = double(lon);
lat = double(lat);

% read mask
mask = ncread(fname, 'mask_rho');
[idx1, idx2] = find(mask < 0.5);

for i=1:length(idx1)
    mask(idx1(i), idx2(i)) = NaN;
end

% model domain
H = figure('units', 'centimeters', 'Position', [5, 5, 20, 20]);
ax = subplot(1, 1, 1);

m_proj('mercator', 'long', [min(lon) max(lon)], 'lat', [min(lat) max(lat)]);
pp = m_pcolor(lon, lat, mask');
hold on
m_grid('linest', ':', 'TickDir', 'out', 'backcolor', [0.94,0.87,0.80]);

auxcmap = [.2 .65 1];% ocean color
colormap(auxcmap);

%% tide maps calc

time    = ncread(fname, 'time');% time units since reference date
time    = time - time(1);% time units since the first time step
reftime = datenum(2000, 12, 01);% reference date ad hoc
time    = datenum(reftime + seconds(time));% time vector

% read and mask zeta
zeta = ncread(fname, 'zeta');
for i = 1:length(idx1)
    zeta(idx1(i), idx2(i), :) = NaN;
end
zeta = zeta*100;% m to cm

clear auxVar
auxVar{1}.AMP  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{1}.PHA  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{1}.NAME = 'K1';

auxVar{2}.AMP  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{2}.PHA  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{2}.NAME = 'O1';

auxVar{3}.AMP  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{3}.PHA  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{3}.NAME = 'M2';

auxVar{4}.AMP  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{4}.PHA  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{4}.NAME = 'S2';

auxVar{5}.F  = NaN(size(zeta, 1), size(zeta, 2));
auxVar{5}.NAME = 'Form factor';

cont = 0;
for i = 1:size(zeta, 1)
    for j = 1:size(zeta, 2)
        if ~isnan(zeta(i, j))
            aux = squeeze(zeta(i, j, :));
            [NAME, ~, TIDECON, ~] = t_tide(aux, 'interval', 1,...
                'output', 'none', 'latitude', lat(j), 'start time', reftime);% interval is the sampling interval in hours!!!
            
            auxVar{1}.AMP(i, j) = TIDECON(6, 1);% tidal component positions are in NAME
            auxVar{1}.PHA(i, j) = TIDECON(6, 3);
            
            auxVar{2}.AMP(i, j) = TIDECON(4, 1);
            auxVar{2}.PHA(i, j) = TIDECON(4, 3);
            
            auxVar{3}.AMP(i, j) = TIDECON(11, 1);
            auxVar{3}.PHA(i, j) = TIDECON(11, 3);
            
            auxVar{4}.AMP(i, j) = TIDECON(12, 1);
            auxVar{4}.PHA(i, j) = TIDECON(12, 3);
        end
        cont = cont + 1;% it takes a bit... counter to know how much is left
        disp(['Position ', num2str(cont), ' of ', num2str(size(zeta, 1)*size(zeta, 2))])
    end
end

K1          = auxVar{1}.AMP;
O1          = auxVar{2}.AMP;
M2          = auxVar{3}.AMP;
S2          = auxVar{4}.AMP;
auxVar{5}.F = (K1 + O1)./(M2 + S2);% form factor

clear K1 O1 M2 S2

%% tide maps figure

auxcmap = [...
    165,0,38
    215,48,39
    244,109,67
    253,174,97
    254,224,144
    255,255,191
    224,243,248
    171,217,233
    116,173,209
    69,117,180
    49,54,149]/255;
auxcmap = flipud(auxcmap);

H = figure('units', 'centimeters', 'Position', [5, 5, 35, 25]);
clear ax

for i = 1:length(auxVar)
    
    if i == length(auxVar)
        Var1 = auxVar{i}.F;
    else
        Var1 = auxVar{i}.AMP;
        Var2 = auxVar{i}.PHA;
    end
    % disruption between 0 and 360 degrees distorts contours, ad hoc fix for this
    Var2(Var2(:)<5)             = Var2(Var2(:)<5) + 360;
    Var2(Var2(:)<7 & Var2(:)>4) = NaN;
    
    ax(i) = subplot(2, 3, i);
    m_proj('mercator', 'long', [min(lon) max(lon)], 'lat', [min(lat) max(lat)]);
    m_contourf(lon, lat, Var1', 'edgecolor', 'none');
    hold on
    if i ~= length(auxVar)
        [C, h] = m_contour(lon, lat, Var2', [10:10:360], 'color', [0 0 0], 'linewidth', 1);
        clabel(C,h)
    end
    m_gshhs_h('patch', [0.94,0.87,0.80], 'edgecolor', 'none');
    m_grid('linest', ':', 'xtick', 6, 'ytick', 6, 'fontsize', 10, 'tickdir', 'out');
    
    % colorbar
    cb1 = colorbar(gca, 'location', 'northoutside', 'FontWeight', 'bold', 'Linewidth', 1);
    if i == length(auxVar)
        ylabel(cb1, [auxVar{i}.NAME], 'FontWeight', 'bold', 'FontSize', 10);
    else
        ylabel(cb1, [auxVar{i}.NAME, ' Tide Amplitude [cm]'], 'FontWeight', 'bold', 'FontSize', 10);
    end
    posbar = cb1.Position;
    
    colormap(auxcmap)
    
    caxis([0 prctile(Var1(:), 95)]);% the magnitudes of the phase are greater than those of the amplitude, the range of the color bar must be specified
end

%% settings

ax(1).Position(3) = ax(1).Position(3)*1.25;
ax(1).Position(4) = ax(1).Position(4)*1.25;

ax(2).Position(3) = ax(2).Position(3)*1.25;
ax(2).Position(4) = ax(2).Position(4)*1.25;

ax(3).Position(3) = ax(3).Position(3)*1.25;
ax(3).Position(4) = ax(3).Position(4)*1.25;

ax(4).Position(3) = ax(4).Position(3)*1.25;
ax(4).Position(4) = ax(4).Position(4)*1.25;

ax(5).Position(3) = ax(5).Position(3)*1.25;
ax(5).Position(4) = ax(5).Position(4)*1.25;

ax(1).Position(2) = ax(1).Position(2) - 0.05;
ax(2).Position(2) = ax(2).Position(2) - 0.05;
ax(3).Position(2) = ax(3).Position(2) - 0.05;
ax(4).Position(2) = ax(4).Position(2) - 0.05;
ax(5).Position(2) = ax(5).Position(2) - 0.05;

%% coast line hovmoller

% run the coastline script to get the coordinates
lonlats = load('lonlats.mat');
lonlats = lonlats.lonlats;
lonlats = flipud(lonlats);% order from south to north

rlon = lonlats(:, 1);
rlat = lonlats(:, 2);

x = lon;
y = lat;

clear minimox positionx minimoy positiony mas_cercanox mas_cercanoy
for i = 1:length(rlon)
    [minimox(i), positionx(i)] = min(abs(x - rlon(i)));
    [minimoy(i), positiony(i)] = min(abs(y - rlat(i)));
    mas_cercanox(i) = x(positionx(i));
    mas_cercanoy(i) = y(positiony(i));
end

clear data
for i = 1:length(positionx)
    aux = squeeze(zeta(positionx(i), positiony(i), :));
    [NAME, ~, TIDECON, XOUT] = t_tide(aux, 'interval', 1,...
        'output', 'none', 'latitude', lat(positiony(i)), 'start time', reftime);% interval is the sampling interval in hours!!!
    data(i, :) = XOUT;
end

H = figure('units', 'centimeters', 'Position', [5, 5, 45, 10]);

ax(1) = subplot(1, 4, 1);
m_proj('mercator', 'long', [min(lon) max(lon)], 'lat', [min(lat) max(lat)]);
pp = m_pcolor(lon, lat, mask');
hold on
m_grid('linest', ':', 'TickDir', 'out', 'backcolor', [0.94,0.87,0.80]);
m_plot(lonlats(:, 1), lonlats(:, 2), '-rs', 'markerfacecolor', 'r', 'markersize', 4)

auxcmap = [.2 .65 1];% ocean color
colormap(ax(1), auxcmap);

ax(2) = subplot(1, 4, [2 4]);

auxcmap = [...
    165,0,38
    215,48,39
    244,109,67
    253,174,97
    254,224,144
    255,255,191
    224,243,248
    171,217,233
    116,173,209
    69,117,180
    49,54,149]/255;
auxcmap = flipud(auxcmap);

x = time;
y = 1:size(data, 1);
contourf(x, y, data, 'edgecolor', 'none')

% colorbar
cb2 = colorbar(ax(2), 'location', 'eastoutside','FontWeight', 'bold', 'Linewidth', 1);
ylabel(cb2, 'Astronomical Tide [cm]', 'FontWeight', 'bold', 'FontSize', 10);
cbpos = cb2.Position;
cb2.Position(1) = cbpos(1) + 0.04;
colormap(ax(2), auxcmap)
caxis([-110 110])

% general settings
set(gca, 'TickDir', 'out');
grid on
box on

ylabel('points along the coast')
step = 48;
set(gca,'XTick',[x(1:step:end)],'XtickLabels',datestr([x(1:step:end)],'mmm/dd'))

%% coast line time serie

% run the coastline script to get the coordinates
lonlats = load('lonlats.mat');
lonlats = lonlats.lonlats;
lonlats = flipud(lonlats);% order from south to north

skip = 50;
lonlats = lonlats(1:skip:end, :);

rlon = lonlats(:, 1);
rlat = lonlats(:, 2);

x = lon;
y = lat;

clear minimox positionx minimoy positiony mas_cercanox mas_cercanoy
for i = 1:length(rlon)
    [minimox(i), positionx(i)] = min(abs(x - rlon(i)));
    [minimoy(i), positiony(i)] = min(abs(y - rlat(i)));
    mas_cercanox(i) = x(positionx(i));
    mas_cercanoy(i) = y(positiony(i));
end

clear data
for i = 1:length(positionx)
    aux = squeeze(zeta(positionx(i), positiony(i), :));
    [NAME, ~, TIDECON, XOUT] = t_tide(aux, 'interval', 1,...
        'output', 'none', 'latitude', lat(positiony(i)), 'start time', reftime);% interval is the sampling interval in hours!!!
    data(i, :) = XOUT;
end

H = figure('units', 'centimeters', 'Position', [5, 5, 45, 10]);

ax(1) = subplot(1, 4, 1);
m_proj('mercator', 'long', [min(lon) max(lon)], 'lat', [min(lat) max(lat)]);
pp = m_pcolor(lon, lat, mask');
hold on
m_grid('linest', ':', 'TickDir', 'out', 'backcolor', [0.94,0.87,0.80]);
m_plot(lonlats(:, 1), lonlats(:, 2), 'marker', 'o', 'color', 'r', 'linewi', 1, 'linest', 'none', 'markersize', 4, 'markerfacecolor', 'r')

auxcmap = [.2 .65 1];% ocean color
colormap(ax(1), auxcmap);

ax(2) = subplot(1, 4, [2 4]);

x = time;

for i = 1:size(data, 1);
    y = data(i, :);
    plot(x, y, '-r')
    hold on
end

% general settings
set(gca, 'TickDir', 'out');
grid on
box on
axis tight

ylabel('Astronomical Tide [cm]')
step = 48;
set(gca,'XTick',[x(1:step:end)],'XtickLabels',datestr([x(1:step:end)],'mmm/dd'))

%% time series

skip = 30;

t = 1;
clear locations
for i = 25:skip:length(lon)-25
    for j = 25:skip:length(lat)-25
        if mask(i, j) > 0.5
            locations(t,:) = [lon(i) lat(j)];
            t = t + 1;
        end
    end
end

skip = 20;

[meshlon, meshlat]=meshgrid(lon(1:skip:end), lat(1:skip:end));

clear locations
locations(:, 1) = [meshlon(meshlon(:) > 11.3 & meshlon(:) < 12.5 & meshlat(:) < 34.7 & meshlat(:) > 33.5)];
locations(:, 2) = [meshlat(meshlon(:) > 11.3 & meshlon(:) < 12.5 & meshlat(:) < 34.7 & meshlat(:) > 33.5)];

rlon = locations(:, 1);
rlat = locations(:, 2);

x = lon;
y = lat;

clear minimox positionx minimoy positiony mas_cercanox mas_cercanoy
for i = 1:length(rlon)
    [minimox(i), positionx(i)] = min(abs(x - rlon(i)));
    [minimoy(i), positiony(i)] = min(abs(y - rlat(i)));
    mas_cercanox(i) = x(positionx(i));
    mas_cercanoy(i) = y(positiony(i));
end

clear data
for i = 1:length(positionx)
    aux = squeeze(zeta(positionx(i), positiony(i), :));
    [NAME, ~, TIDECON, XOUT] = t_tide(aux, 'interval', 1,...
        'output', 'none', 'latitude', lat(positiony(i)), 'start time', reftime);% interval is the sampling interval in hours!!!
    data(i, :) = XOUT;
end

H = figure('units', 'centimeters', 'Position', [5, 5, 45, 10]);

ax(1) = subplot(1, 4, 1);
m_proj('mercator', 'long', [min(lon) max(lon)], 'lat', [min(lat) max(lat)]);
pp = m_pcolor(lon, lat, mask');
hold on
m_grid('linest', ':', 'TickDir', 'out', 'backcolor', [0.94,0.87,0.80]);
for i = 1:length(locations(:, 2))
    m_plot(locations(i, 1), locations(i, 2), 'marker', 'o', 'color', 'r', 'linewi', 1, 'linest', 'none', 'markersize', 4, 'markerfacecolor', 'r')
end
auxcmap = [.2 .65 1];% ocean color
colormap(ax(1), auxcmap);

ax(2) = subplot(1, 4, [2 4]);

x = time;

for i = 1:size(data, 1);
    y = data(i, :);
    plot(x, y, '-r')
    hold on
end

% general settings
set(gca, 'TickDir', 'out');
grid on
box on
axis tight

ylabel('Astronomical Tide [cm]')
step = 48;
set(gca,'XTick',[x(1:step:end)],'XtickLabels',datestr([x(1:step:end)],'mmm/dd'))
