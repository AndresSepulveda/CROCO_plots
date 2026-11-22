function plot_ww3_mesh(mshfile, varargin)
%PLOT_WW3_MESH  Plot a WAVEWATCH III unstructured mesh (Gmsh v2 ASCII)
%  and, optionally, a field from a ww3_ounf NetCDF file on that mesh.
%  Works in MATLAB (R2016b+) and GNU Octave (6+).
%
%  plot_ww3_mesh('orkney.msh')
%  plot_ww3_mesh('orkney.msh', 'nc', 'ww3.201001.nc', 'var', 'hs', 'time', 25)
%  plot_ww3_mesh('orkney.msh', 'zoom', [-3.4 -2.9 58.75 59.0])
%
%  Options (name/value):
%    'nc'     ww3_ounf NetCDF file on the same mesh       (default: none)
%    'var'    variable to plot from 'nc'                  (default: 'hs')
%    'time'   time index, 1-based                         (default: 1)
%    'zoom'   [lon0 lon1 lat0 lat1]                       (default: whole mesh)
%    'prefix' prefix for the PNG files                    (default: mesh name)
%    'save'   true/false, write PNG files                 (default: true)
%
%  Figures: <prefix>_mesh.png, _depth.png, _size.png, _<var>_tNNNN.png
%  Octave: the 'nc' option needs the netcdf package (pkg install -forge netcdf).

  % ---------------- options ----------------
  opt = struct('nc', '', 'var', 'hs', 'time', 1, 'zoom', [], ...
               'prefix', '', 'save', true);
  for k = 1:2:numel(varargin)
    opt.(lower(varargin{k})) = varargin{k + 1};
  end
  if isempty(opt.prefix)
    [p, n] = fileparts(mshfile);
    opt.prefix = fullfile(p, n);
  end
  isoct = exist('OCTAVE_VERSION', 'builtin') ~= 0;
  if isoct && ~isempty(opt.nc)
    pkg load netcdf
  end

  % ---------------- read mesh ----------------
  [lon, lat, depth, tri, bnd] = read_gmsh_v2(mshfile);
  sz = element_size_km(lon, lat, tri);
  fprintf('%d nodes, %d triangles, %d open-boundary nodes\n', ...
          numel(lon), size(tri, 1), numel(bnd));
  fprintf('depth %.1f to %.1f m; element size %.3f to %.2f km\n', ...
          min(depth), max(depth), min(sz), max(sz));

  % ---------------- 1. mesh ----------------
  f = figure('Color', 'w');
  patch('Faces', tri, 'Vertices', [lon lat], 'FaceColor', 'none', ...
        'EdgeColor', [0.2 0.2 0.2], 'LineWidth', 0.1);
  hold on
  if ~isempty(bnd)
    plot(lon(bnd), lat(bnd), 'r.', 'MarkerSize', 10);
    legend('mesh', 'open boundary', 'Location', 'southeast');
  end
  title(sprintf('%d nodes, %d elements', numel(lon), size(tri, 1)), 'Interpreter', 'none');
  setup_axes(lon, lat, opt.zoom);
  save_png(f, [opt.prefix '_mesh.png'], opt.save);

  % ---------------- 2. depth ----------------
  f = figure('Color', 'w');
  patch('Faces', tri, 'Vertices', [lon lat], 'FaceVertexCData', depth, ...
        'FaceColor', 'interp', 'EdgeColor', 'none');
  colormap(gca, flipud(parula_or_jet()));
  cb = colorbar; ylabel(cb, 'Depth (m)');
  title('Depth');
  setup_axes(lon, lat, opt.zoom);
  save_png(f, [opt.prefix '_depth.png'], opt.save);

  % ---------------- 3. element size (log colour scale) ----------------
  f = figure('Color', 'w');
  patch('Faces', tri, 'Vertices', [lon lat], 'FaceVertexCData', log10(sz), ...
        'FaceColor', 'flat', 'EdgeColor', 'none');
  colormap(gca, flipud(hot(64)));
  caxis(log10([min(sz) max(sz)]));
  ticks = [0.05 0.1 0.2 0.5 1 2 5 10 20 50];
  ticks = ticks(ticks >= min(sz) & ticks <= max(sz));
  labels = strtrim(cellstr(num2str(ticks(:))));
  cb = colorbar;
  if isoct                                   % Octave colorbar is an axes
    set(cb, 'ytick', log10(ticks), 'yticklabel', labels);
  else                                       % MATLAB ColorBar object
    set(cb, 'Ticks', log10(ticks), 'TickLabels', labels);
  end
  ylabel(cb, 'Mean edge length (km)');
  title('Element size');
  setup_axes(lon, lat, opt.zoom);
  save_png(f, [opt.prefix '_size.png'], opt.save);

  % ---------------- 4. optional WW3 field ----------------
  if ~isempty(opt.nc)
    v = double(ncread(opt.nc, opt.var, [1 opt.time], [Inf 1]));
    v(v > 1e30) = NaN;                       % _FillValue if not applied
    if numel(v) ~= numel(lon)
      error('%s has %d values but the mesh has %d nodes', opt.var, numel(v), numel(lon));
    end
    t = ncread(opt.nc, 'time', opt.time, 1);
    when = nc_time_str(t, ncreadatt(opt.nc, 'time', 'units'));
    units = att_or(opt.nc, opt.var, 'units', '');
    lname = att_or(opt.nc, opt.var, 'long_name', opt.var);

    f = figure('Color', 'w');
    patch('Faces', tri, 'Vertices', [lon lat], 'FaceVertexCData', v(:), ...
          'FaceColor', 'interp', 'EdgeColor', 'none');
    colormap(gca, turbo_or_jet());
    cb = colorbar; ylabel(cb, sprintf('%s (%s)', opt.var, units));
    title(sprintf('%s  %s', lname, when), 'Interpreter', 'none');
    setup_axes(lon, lat, opt.zoom);
    save_png(f, sprintf('%s_%s_t%04d.png', opt.prefix, opt.var, opt.time), opt.save);
  end
end

% =====================================================================
function [lon, lat, depth, tri, bnd] = read_gmsh_v2(fname)
  fid = fopen(fname, 'r');
  if fid < 0, error('Cannot open %s', fname); end
  c = onCleanup(@() fclose(fid));

  skip_to(fid, '$Nodes');
  nn = fscanf(fid, '%d', 1);
  A = fscanf(fid, '%f', [4 nn])';
  pos = zeros(max(A(:, 1)), 1);           % node id -> row index
  pos(A(:, 1)) = 1:nn;
  lon = A(:, 2); lat = A(:, 3); depth = A(:, 4);

  skip_to(fid, '$Elements');
  ne = fscanf(fid, '%d', 1); fgetl(fid);
  tri = zeros(ne, 3); bnd = zeros(ne, 1);
  nt = 0; nb = 0;
  for k = 1:ne
    v = sscanf(fgetl(fid), '%d');
    conn = v(4 + v(3):end);
    if v(2) == 2
      nt = nt + 1; tri(nt, :) = conn(1:3);
    elseif v(2) == 15
      nb = nb + 1; bnd(nb) = conn(1);
    end
  end
  tri = pos(tri(1:nt, :));
  bnd = pos(bnd(1:nb));
end

function skip_to(fid, tag)
  while true
    ln = fgetl(fid);
    if ~ischar(ln), error('Section %s not found', tag); end
    if strcmp(strtrim(ln), tag), return; end
  end
end

function sz = element_size_km(lon, lat, tri)
  R = 6371;                               % km
  lam = deg2rad(lon); phi = deg2rad(lat);
  e = zeros(size(tri, 1), 3);
  pairs = [1 2; 2 3; 3 1];
  for k = 1:3
    a = tri(:, pairs(k, 1)); b = tri(:, pairs(k, 2));
    dphi = phi(b) - phi(a);
    dlam = (lam(b) - lam(a)) .* cos(0.5 * (phi(a) + phi(b)));
    e(:, k) = R * hypot(dlam, dphi);
  end
  sz = mean(e, 2);
end

function setup_axes(lon, lat, zoom)
  daspect([1 / cosd(mean(lat)) 1 1]);
  box on; grid on;
  xlabel('Longitude (\circ)'); ylabel('Latitude (\circ)');
  if isempty(zoom)
    axis([min(lon) max(lon) min(lat) max(lat)]);
  else
    axis(zoom);
  end
end

function save_png(f, name, dosave)
  if dosave
    print(f, '-dpng', '-r150', name);
    fprintf('wrote %s\n', name);
  end
end

function cm = parula_or_jet()
  if exist('parula', 'file') || exist('parula', 'builtin')
    cm = parula(64);
  else
    cm = jet(64);
  end
end

function cm = turbo_or_jet()
  if exist('turbo', 'file') || exist('turbo', 'builtin')
    cm = turbo(64);
  else
    cm = jet(64);
  end
end

function s = att_or(file, var, att, default)
  try
    s = ncreadatt(file, var, att);
  catch
    s = default;
  end
end

function s = nc_time_str(t, units)
  % e.g. 'days since 1990-01-01 00:00:00' (WW3 default)
  tok = regexp(units, '^\s*(\w+)\s+since\s+(\d+)-(\d+)-(\d+)[ T]?(\d*):?(\d*):?(\d*)', ...
               'tokens', 'once');
  if isempty(tok)
    s = sprintf('t = %g %s', t, units); return
  end
  n = str2double(tok(2:end)); n(isnan(n)) = 0;
  t0 = datenum(n(1), n(2), n(3), n(4), n(5), n(6));
  switch lower(tok{1})
    case {'days', 'day'},                  f = 1;
    case {'hours', 'hour'},                f = 1 / 24;
    case {'minutes', 'minute'},            f = 1 / 1440;
    case {'seconds', 'second', 'secs'},    f = 1 / 86400;
    otherwise,                             f = 1;
  end
  s = datestr(t0 + double(t) * f, 'yyyy-mm-dd HH:MM');
end
