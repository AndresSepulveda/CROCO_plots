function croco2qgis (infile, varargin)
% CROCO2QGIS  Convert CROCO NetCDF output into files that open directly in QGIS.
%
%   croco2qgis (infile, 'option', value, ...)
%
% Outputs (choose with 'formats', a cell array, default {'nc'}):
%   'nc'   One CF-compliant NetCDF on a regular lon/lat grid (time, lat, lon).
%          QGIS reads it as a temporal raster layer (Temporal Controller works).
%   'asc'  ESRI ASCII grids (+ .prj, EPSG:4326), one file per variable and
%          time step. Drag and drop into QGIS as raster layers.
%   'csv'  Points on the native (curvilinear) rho grid, one file per time
%          step, all variables as columns. Load in QGIS with
%          Layer > Add Layer > Add Delimited Text Layer (X = lon, Y = lat).
%          Useful for arrows from u_east / v_north.
%
% Options:
%   'grid'         grid file with lon_rho, lat_rho, mask_rho, angle, h
%                  (needed only if they are not in infile)
%   'vars'         cell array of variable names
%                  (default: those present of zeta,temp,salt,u,v,ubar,vbar)
%   'formats'      cell array with any of 'nc', 'asc', 'csv'
%   'level'        sigma level for 3-D variables, 1 = bottom
%                  (default 0 = surface, i.e. the last level)
%   'depth'        interpolate 3-D variables to this depth in metres
%                  (overrides 'level')
%   'times'        vector of time indices, 1-based (default: all)
%   'time_origin'  e.g. '2000-01-01'; used when the time variable has no
%                  "seconds/days since ..." units (values taken as seconds)
%   'res'          output resolution in degrees (default: native spacing)
%   'bbox'         [west south east north] output extent
%   'outdir'       output folder (default 'qgis_out')
%
% Features: curvilinear rho grid -> regular lon/lat grid (linear, land masked
% with mask_rho); u/v averaged to rho points, rotated to east/north with
% 'angle', plus speed; Vtransform 1 and 2 for 'depth'.
%
% Requires the netcdf package:  pkg install -forge netcdf
%
% Examples:
%   croco2qgis ('croco_his.nc', 'grid', 'croco_grd.nc', ...
%               'vars', {'temp','u','v'}, 'depth', 50, 'formats', {'nc','asc'})
%   croco2qgis ('croco_avg.nc', 'vars', {'zeta'}, 'times', 1:6:48)
%   croco2qgis ('croco_his.nc', 'formats', {'csv'}, 'time_origin', '2000-01-01')

  if (exist ('OCTAVE_VERSION', 'builtin'))
    pkg load netcdf
  end

  o = struct ('grid', '', 'vars', {{}}, 'formats', {{'nc'}}, 'level', 0, ...
              'depth', [], 'times', [], 'time_origin', '', 'res', [], ...
              'bbox', [], 'outdir', 'qgis_out');
  for k = 1:2:numel (varargin)
    if (! isfield (o, varargin{k}))
      error ('croco2qgis: unknown option ''%s''', varargin{k});
    end
    o.(varargin{k}) = varargin{k+1};
  end
  if (ischar (o.vars)),    o.vars = strsplit (o.vars, ',');       end
  if (ischar (o.formats)), o.formats = strsplit (o.formats, ','); end
  NODATA = -9999;

  % ---------------------------------------------------------------- grid
  files = {infile};
  if (! isempty (o.grid)), files{end+1} = o.grid; end
  g.files = files;
  g.lon = double (getvar (files, 'lon_rho', true));   % (xi, eta)
  g.lat = double (getvar (files, 'lat_rho', true));
  if (max (g.lon(:)) > 180), g.lon = mod (g.lon + 180, 360) - 180; end
  g.mask = getvar (files, 'mask_rho', false);
  if (isempty (g.mask)), g.mask = ones (size (g.lon)); end
  g.angle = getvar (files, 'angle', false);
  g.h = getvar (files, 'h', false);
  [nx, ny] = size (g.lon);

  % ----------------------------------------------------------- variables
  info = ncinfo (infile);
  present = {info.Variables.Name};
  if (isempty (o.vars))
    o.vars = intersect ({'zeta','temp','salt','u','v','ubar','vbar'}, present, 'stable');
  end
  missing = setdiff (o.vars, present);
  if (! isempty (missing))
    error ('croco2qgis: variables not in %s: %s', infile, strjoin (missing, ', '));
  end

  % ---------------------------------------------------------------- time
  d = {ncinfo(infile, o.vars{1}).Dimensions.Name};
  it = find (! cellfun (@isempty, strfind (d, 'time')), 1);
  if (isempty (it))
    nt = 1;
  else
    nt = ncinfo (infile, o.vars{1}).Size(it);
  end
  [tnum, labels] = read_times (infile, present, nt, o.time_origin);
  if (isempty (o.times)), o.times = 1:nt; end
  tsel = o.times(:)';

  % ------------------------------------------------------------- outputs
  do_nc  = any (strcmp (o.formats, 'nc'));
  do_asc = any (strcmp (o.formats, 'asc'));
  do_csv = any (strcmp (o.formats, 'csv'));
  if (! exist (o.outdir, 'dir')), mkdir (o.outdir); end
  [~, stem] = fileparts (infile);
  if (isempty (o.depth))
    suffix = sprintf ('_s%d', o.level);
  else
    suffix = sprintf ('_z%gm', abs (o.depth));
  end
  if (do_nc || do_asc)
    rg = make_regridder (g, o.res, o.bbox);
  end
  ncfile = fullfile (o.outdir, [stem suffix '_regular.nc']);
  nc_ready = false;

  for n = 1:numel (tsel)
    t = tsel(n);
    printf ('  %s: step %d (%s)\n', stem, t, labels{t}); fflush (stdout);
    F = compute_step (infile, g, o, t);          % struct of (xi, eta) fields
    names = fieldnames (F);

    if (do_csv)
      out = fullfile (o.outdir, sprintf ('%s%s_points_t%04d.csv', stem, suffix, t));
      write_csv (out, F, g, labels{t});
    end

    if (do_nc || do_asc)
      if (do_nc && ! nc_ready)
        init_nc (ncfile, names, rg, tnum, labels, tsel, NODATA);
        nc_ready = true;
      end
      for k = 1:numel (names)
        R = regrid (rg, F.(names{k}));           % (lon, lat), lat ascending
        R(isnan (R)) = NODATA;
        if (do_nc)
          ncwrite (ncfile, names{k}, single (R), [1 1 n]);
        end
        if (do_asc)
          out = fullfile (o.outdir, sprintf ('%s_%s%s_t%04d.asc', stem, names{k}, suffix, t));
          write_asc (out, R, rg, NODATA);
        end
      end
    end
  end
  if (do_nc),  printf ('  wrote %s\n', ncfile); end
  if (do_asc), printf ('  wrote %s\n', fullfile (o.outdir, [stem '_*' suffix '_t*.asc'])); end
  if (do_csv), printf ('  wrote %s\n', fullfile (o.outdir, [stem suffix '_points_t*.csv'])); end
end

% ======================================================================
% Reading
% ======================================================================
function v = getvar (files, name, required)
  v = [];
  for k = 1:numel (files)
    try
      v = double (ncread (files{k}, name));
      return
    catch
    end
  end
  if (required)
    error ('croco2qgis: ''%s'' not found. Pass the grid file with ''grid''.', name);
  end
end

function v = getscalar (files, name, default)
  v = getvar (files, name, false);
  if (! isempty (v)), v = v(1); return, end
  for k = 1:numel (files)
    try
      v = double (ncreadatt (files{k}, '/', name));
      v = v(1);
      return
    catch
    end
  end
  v = default;
end

function a = to_rho (a, nx, ny)
  % Average u- or v-point arrays (first two dims) onto rho points.
  a = double (a);
  a(isnan (a)) = 0;
  s = size (a);
  if (s(1) == nx && s(2) == ny)
    return
  elseif (s(1) == nx - 1 && s(2) == ny)           % u points
    a = cat (1, a(1,:,:), 0.5 * (a(1:end-1,:,:) + a(2:end,:,:)), a(end,:,:));
  elseif (s(1) == nx && s(2) == ny - 1)           % v points
    a = cat (2, a(:,1,:), 0.5 * (a(:,1:end-1,:) + a(:,2:end,:)), a(:,end,:));
  else
    error ('croco2qgis: unexpected horizontal shape %dx%d for grid %dx%d', s(1), s(2), nx, ny);
  end
end

function f = read_field (infile, g, name, t, o)
  [nx, ny] = size (g.lon);
  vi = ncinfo (infile, name);
  d = {vi.Dimensions.Name};
  start = ones (1, numel (d));
  count = vi.Size;
  it = find (! cellfun (@isempty, strfind (d, 'time')), 1);
  if (! isempty (it)), start(it) = t; count(it) = 1; end
  iz = find (strncmp (d, 's_', 2), 1);
  if (isempty (iz))
    f = to_rho (ncread (infile, name, start, count), nx, ny);
    return
  end
  if (! strcmp (d{iz}, 's_rho'))
    error ('croco2qgis: ''%s'' is on %s; only s_rho variables are supported.', name, d{iz});
  end
  if (isempty (o.depth))
    N = vi.Size(iz);
    lev = o.level;
    if (lev <= 0), lev = N + lev; end
    start(iz) = lev; count(iz) = 1;
    f = to_rho (ncread (infile, name, start, count), nx, ny);
  else
    a = to_rho (ncread (infile, name, start, count), nx, ny);   % (xi, eta, N)
    f = interp_depth (a, z_rho (infile, g, t), -abs (o.depth), g.h);
  end
end

function z = z_rho (infile, g, t)
  % Depths (negative, m) of rho levels, size (xi, eta, N).
  s  = getvar (g.files, 's_rho', false);
  cs = getvar (g.files, 'Cs_r', false);
  hc = getscalar (g.files, 'hc', []);
  if (isempty (s) || isempty (cs) || isempty (g.h) || isempty (hc))
    error ('croco2qgis: ''depth'' needs s_rho, Cs_r, hc and h (use ''grid'').');
  end
  vt = getscalar (g.files, 'Vtransform', 1);
  h = g.h;
  try
    vi = ncinfo (infile, 'zeta');
    if (numel (vi.Size) == 3)
      zeta = double (ncread (infile, 'zeta', [1 1 t], [Inf Inf 1]));
    else
      zeta = double (ncread (infile, 'zeta'));
    end
    zeta(isnan (zeta)) = 0;
  catch
    zeta = zeros (size (h));
  end
  N = numel (s);
  z = zeros ([size(h) N]);
  for k = 1:N
    if (vt == 2)
      z0 = (hc * s(k) + h * cs(k)) ./ (hc + h);
      z(:,:,k) = zeta + (zeta + h) .* z0;
    else
      z0 = hc * s(k) + (h - hc) * cs(k);
      z(:,:,k) = z0 + zeta .* (1 + z0 ./ h);
    end
  end
end

function f = interp_depth (a, z, target, h)
  N = size (z, 3);
  f = a(:,:,1);                                   % below deepest level
  for k = 1:N-1
    z0 = z(:,:,k); z1 = z(:,:,k+1);
    w = (target - z0) ./ (z1 - z0);
    sel = (target >= z0) & (target < z1);
    lin = a(:,:,k) .* (1 - w) + a(:,:,k+1) .* w;
    f(sel) = lin(sel);
  end
  top = a(:,:,N);
  sel = target >= z(:,:,N);                       % above shallowest level
  f(sel) = top(sel);
  f(-h > target) = NaN;                           % seabed shallower than depth
end

function F = compute_step (infile, g, o, t)
  F = struct ();
  pairs = {'u', 'v', 'speed'; 'ubar', 'vbar', 'speed_bar'};
  used = {};
  for p = 1:rows (pairs)
    a = pairs{p,1}; b = pairs{p,2};
    if (any (strcmp (o.vars, a)) && any (strcmp (o.vars, b)))
      u = read_field (infile, g, a, t, o);
      v = read_field (infile, g, b, t, o);
      if (! isempty (g.angle))
        F.([a '_east'])  = u .* cos (g.angle) - v .* sin (g.angle);
        F.([b '_north']) = u .* sin (g.angle) + v .* cos (g.angle);
      else
        F.([a '_east']) = u;  F.([b '_north']) = v;
      end
      F.(pairs{p,3}) = hypot (u, v);
      used = [used, {a, b}];
    end
  end
  for k = 1:numel (o.vars)
    if (! any (strcmp (used, o.vars{k})))
      F.(o.vars{k}) = read_field (infile, g, o.vars{k}, t, o);
    end
  end
end

function [tnum, labels] = read_times (infile, present, nt, origin)
  % tnum: datenum per step ([] if unknown); labels: cellstr per step.
  tnum = [];
  labels = arrayfun (@(i) sprintf ('t%04d', i), 1:nt, 'UniformOutput', false);
  cand = {'ocean_time', 'time', 'scrum_time'};
  for k = 1:numel (cand)
    if (! any (strcmp (present, cand{k}))), continue, end
    vals = double (ncread (infile, cand{k}));
    if (numel (vals) != nt), continue, end
    vals = vals(:)';
    scale = 1 / 86400;  base = [];
    try
      units = ncreadatt (infile, cand{k}, 'units');
      tok = regexp (units, '^\s*(\w+)\s+since\s+(\d+)-(\d+)-(\d+)[T ]?(\d+)?:?(\d+)?:?(\d+)?', 'tokens', 'once');
      if (! isempty (tok))
        switch (lower (tok{1}(1)))
          case 'd', scale = 1;
          case 'h', scale = 1 / 24;
          case 'm', scale = 1 / 1440;
        end
        c = cellfun (@str2double, tok(2:end));
        c(isnan (c)) = 0;
        base = datenum (c(1), c(2), c(3), c(4), c(5), c(6));
      end
    catch
    end
    if (! isempty (origin)), base = datenum (origin, 'yyyy-mm-dd'); scale = 1 / 86400; end
    if (isempty (base))
      labels = arrayfun (@(x) sprintf ('%g', x), vals, 'UniformOutput', false);
    else
      tnum = base + vals * scale;
      labels = arrayfun (@(x) datestr (x, 'yyyy-mm-ddTHH:MM:SS'), tnum, 'UniformOutput', false);
    end
    return
  end
end

% ======================================================================
% Regridding: curvilinear rho grid -> regular lon/lat grid
% ======================================================================
function rg = make_regridder (g, res, bbox)
  [nx, ny] = size (g.lon);
  dx = median (abs (diff (g.lon, 1, 1))(:));
  dy = median (abs (diff (g.lat, 1, 2))(:));
  if (isempty (res)), res = min (dx, dy); end
  if (isempty (bbox))
    bbox = [min(g.lon(:)) min(g.lat(:)) max(g.lon(:)) max(g.lat(:))];
  end
  rg.res = res;
  rg.lons = bbox(1) + res * (0:round ((bbox(3) - bbox(1)) / res));
  rg.lats = bbox(2) + res * (0:round ((bbox(4) - bbox(2)) / res));
  [LON, LAT] = ndgrid (rg.lons, rg.lats);
  rg.size = size (LON);

  % Triangulate the structured grid: two triangles per cell.
  [I, J] = ndgrid (1:nx-1, 1:ny-1);
  p00 = sub2ind ([nx ny], I(:), J(:));
  p10 = p00 + 1;  p01 = p00 + nx;  p11 = p01 + 1;
  tri = [p00 p10 p11; p00 p11 p01];

  x = g.lon(:);  y = g.lat(:);
  idx = tsearch (x, y, tri, LON(:), LAT(:));
  in = ! isnan (idx);
  T = tri(idx(in), :);
  x1 = x(T(:,1)); y1 = y(T(:,1));
  x2 = x(T(:,2)); y2 = y(T(:,2));
  x3 = x(T(:,3)); y3 = y(T(:,3));
  xq = LON(in);   yq = LAT(in);
  det = (y2 - y3) .* (x1 - x3) + (x3 - x2) .* (y1 - y3);
  w1 = ((y2 - y3) .* (xq - x3) + (x3 - x2) .* (yq - y3)) ./ det;
  w2 = ((y3 - y1) .* (xq - x3) + (x1 - x3) .* (yq - y3)) ./ det;
  rg.in = in;  rg.T = T;  rg.W = [w1, w2, 1 - w1 - w2];
  rg.ocean = double (g.mask(:) > 0);
  rg.wsum = sum (rg.ocean(T) .* rg.W, 2);          % ocean fraction at target
end

function R = regrid (rg, f)
  % Mask-weighted linear interpolation; land where ocean fraction < 0.5.
  f = f(:);
  f(isnan (f)) = 0;
  f = f .* rg.ocean;
  val = sum (f(rg.T) .* rg.W, 2) ./ rg.wsum;
  val(rg.wsum < 0.5) = NaN;
  R = NaN (rg.size);
  R(rg.in) = val;
end

% ======================================================================
% Writers
% ======================================================================
function init_nc (ncfile, names, rg, tnum, labels, tsel, NODATA)
  if (exist (ncfile, 'file')), delete (ncfile); end
  nx = numel (rg.lons); ny = numel (rg.lats); nt = numel (tsel);
  nccreate (ncfile, 'lon', 'Dimensions', {'lon', nx}, 'Datatype', 'double');
  nccreate (ncfile, 'lat', 'Dimensions', {'lat', ny}, 'Datatype', 'double');
  nccreate (ncfile, 'time', 'Dimensions', {'time', nt}, 'Datatype', 'double');
  nccreate (ncfile, 'crs', 'Datatype', 'int32');
  for k = 1:numel (names)
    nccreate (ncfile, names{k}, 'Dimensions', {'lon', nx, 'lat', ny, 'time', nt}, ...
              'Datatype', 'single', 'FillValue', single (NODATA));
    ncwriteatt (ncfile, names{k}, 'grid_mapping', 'crs');
  end
  ncwrite (ncfile, 'lon', rg.lons(:));
  ncwrite (ncfile, 'lat', rg.lats(:));
  ncwriteatt (ncfile, 'lon', 'units', 'degrees_east');
  ncwriteatt (ncfile, 'lon', 'standard_name', 'longitude');
  ncwriteatt (ncfile, 'lat', 'units', 'degrees_north');
  ncwriteatt (ncfile, 'lat', 'standard_name', 'latitude');
  if (isempty (tnum))
    ncwrite (ncfile, 'time', tsel(:));
    ncwriteatt (ncfile, 'time', 'long_name', 'time index');
    ncwriteatt (ncfile, 'time', 'labels', strjoin (labels(tsel), '; '));
  else
    t0 = datenum (1970, 1, 1);
    ncwrite (ncfile, 'time', round ((tnum(tsel)(:) - t0) * 86400));
    ncwriteatt (ncfile, 'time', 'units', 'seconds since 1970-01-01 00:00:00');
    ncwriteatt (ncfile, 'time', 'calendar', 'standard');
    ncwriteatt (ncfile, 'time', 'standard_name', 'time');
  end
  ncwriteatt (ncfile, 'crs', 'grid_mapping_name', 'latitude_longitude');
  ncwriteatt (ncfile, 'crs', 'epsg_code', 'EPSG:4326');
  ncwriteatt (ncfile, 'crs', 'semi_major_axis', 6378137.0);
  ncwriteatt (ncfile, 'crs', 'inverse_flattening', 298.257223563);
  ncwriteatt (ncfile, '/', 'Conventions', 'CF-1.8');
  ncwriteatt (ncfile, '/', 'title', 'CROCO output regridded for QGIS');
end

function write_asc (out, R, rg, NODATA)
  % R is (lon, lat) with lat ascending; ASCII grid rows run north to south.
  fid = fopen (out, 'w');
  fprintf (fid, 'ncols %d\nnrows %d\n', numel (rg.lons), numel (rg.lats));
  fprintf (fid, 'xllcorner %.10f\nyllcorner %.10f\n', rg.lons(1) - rg.res / 2, rg.lats(1) - rg.res / 2);
  fprintf (fid, 'cellsize %.10f\nNODATA_value %g\n', rg.res, NODATA);
  fmt = [repmat('%.6g ', 1, numel (rg.lons) - 1) '%.6g\n'];
  fprintf (fid, fmt, R(:, end:-1:1));
  fclose (fid);
  fid = fopen ([out(1:end-4) '.prj'], 'w');
  fprintf (fid, ['GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],' ...
                 'PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]']);
  fclose (fid);
end

function write_csv (out, F, g, label)
  names = fieldnames (F);
  sel = g.mask(:) > 0;
  M = [g.lon(sel), g.lat(sel)];
  for k = 1:numel (names)
    M(:, end+1) = F.(names{k})(sel);
  end
  fid = fopen (out, 'w');
  fprintf (fid, 'lon,lat,%s,time\n', strjoin (names', ','));
  fmt = ['%.6f,%.6f,' repmat('%.6g,', 1, numel (names)) label '\n'];
  fprintf (fid, fmt, M');
  fclose (fid);
end
