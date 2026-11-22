function [lon,lat,depth,mask,sx,sy] = oct_view_grid3d(fname,varargin)

% -------------------------------------------------------------------------
%|                    | GRIDGEN          NOAA/NCEP |                      |
%|                    |                            |                      |
%|                    | Last Update :  17-Nov-2026 |                      |
%|                    +----------------------------+                      |
%|                     Distributed with WAVEWATCH III                     |
%|                                                                        |
%| DESCRIPTION                                                            |
%| Three dimensional view of the files written by gridgen (the .meta,     |
%| .depth_ascii, .maskorig_ascii and .obstr_lev1 of a single grid).       |
%|                                                                        |
%| The grid is drawn as a relief surface: the bathymetry is the height,   |
%| the dry cells are left out, and the colour is whichever field is being |
%| inspected (the depth itself, the mask, or either obstruction).         |
%|                                                                        |
%| [lon,lat,depth,mask,sx,sy] = oct_view_grid3d(fname,...)                |
%|                                                                        |
%| INPUT                                                                  |
%|  fname       : Base name of the grid, WITHOUT extension, as given to   |
%|                oct_write_ww3file / oct_write_ww3meta                   |
%|                (e.g. './output/glo_15m')                               |
%|                                                                        |
%| OPTIONS (name/value pairs)                                             |
%|  'field'     : What the colour shows. One of                           |
%|                  'depth'   : depth in m                     (default)  |
%|                  'mask'    : land sea mask                             |
%|                  'obstrx'  : sub grid obstruction in x                 |
%|                  'obstry'  : sub grid obstruction in y                 |
%|  'zex'       : Vertical exaggeration. The height is the depth in m     |
%|                divided by this many m per degree. Default 400, so      |
%|                4000 m of ocean is 10 degrees of relief. 0 gives a      |
%|                flat map seen from above                                |
%|  'box'       : [lat_min lon_min lat_max lon_max] to look at a region   |
%|                instead of the whole grid. Default: the whole grid      |
%|  'stride'    : Plot every n-th cell. 0 (default) picks a stride that   |
%|                keeps the surface near 250000 cells, which is what      |
%|                makes a global 15' grid usable                          |
%|  'land'      : 1 draws the dry cells as a flat grey floor, 0 leaves    |
%|                them out. Default 1                                     |
%|  'dry'       : Value that marks a dry cell in the depth file.          |
%|                Default 999                                             |
%|                                                                        |
%| OUTPUT (all on the plotted, possibly strided, sub grid)                |
%|  lon,lat     : Coordinate arrays                                       |
%|  depth       : Depth in m, with the dry cells set to NaN               |
%|  mask        : Land sea mask                                           |
%|  sx,sy       : Obstructions in x and y                                 |
%|                                                                        |
%| REQUIRES  oct_read_ww3meta, oct_read_mask, oct_read_obstr              |
%|                                                                        |
%| NOTE  The .meta must carry its numeric records. A .meta written by the |
%|       original create_glo_15m.m holds only the comment header (the     |
%|       write_ww3meta call there is missing its grid type), and then     |
%|       there is nothing here to read.                                   |
% -------------------------------------------------------------------------

%@@@ Options

opt = struct('field','depth','zex',400,'box',[],'stride',0,'land',1,'dry',999);
for i = 1:2:length(varargin)-1
    nm = lower(varargin{i});
    if (~isfield(opt,nm))
        fprintf(1,'!!ERROR!!: Unknown option %s \n',nm);
        return;
    end;
    opt.(nm) = varargin{i+1};
end;

%@@@ Coordinates, and with them the size of the grid

metaf = [fname,'.meta'];
if (exist(metaf,'file') ~= 2)
    fprintf(1,'!!ERROR!!: Cannot find %s \n',metaf);
    return;
end;

[lon,lat] = oct_read_ww3meta(metaf);
if (isempty(lon))
    fprintf(1,'!!ERROR!!: No grid records in %s \n',metaf);
    return;
end;
[Ny,Nx] = size(lon);
fprintf(1,'Grid %s : %d x %d cells \n',fname,Nx,Ny);

%@@@ Scaling factors, as written in the meta file

%@@@ oct_write_ww3meta writes the bathymetry record as
%@@@    ZLIM DMIN NDSF SF IDLA IDFM FORMAT FROM FILENAME
%@@@ and the sub grid record as
%@@@    NDSF SF IDLA IDFM FORMAT FROM FILENAME
%@@@ so the scaling factor SF is the 4th number on the first and the 2nd on
%@@@ the second

sc_dep = meta_scale(metaf,'.depth_ascii',4,0.001);
sc_obs = meta_scale(metaf,'.obstr_lev1',2,0.01);
fprintf(1,'Scaling factors from the meta file : depth %g, obstructions %g \n',...
    sc_dep,sc_obs);

%@@@ The fields themselves

depth = double(oct_read_mask([fname,'.depth_ascii'],Nx,Ny))*sc_dep;
mask  = double(oct_read_mask([fname,'.maskorig_ascii'],Nx,Ny));

sx = [];  sy = [];
obsf = [fname,'.obstr_lev1'];
if (exist(obsf,'file') == 2)
    [sx,sy] = oct_read_obstr(obsf,Nx,Ny);
    sx = double(sx)*sc_obs;
    sy = double(sy)*sc_obs;
end;

%@@@ Region of interest

if (~isempty(opt.box))
    kk = find(lat(:,1) >= opt.box(1) & lat(:,1) <= opt.box(3));
    jj = find(lon(1,:) >= opt.box(2) & lon(1,:) <= opt.box(4));
    if (isempty(kk) || isempty(jj))
        fprintf(1,'!!ERROR!!: The box does not overlap the grid \n');
        return;
    end;
    [lon,lat,depth,mask,sx,sy] = sub_grid(kk,jj,lon,lat,depth,mask,sx,sy);
end;

%@@@ Decimation, so that a global grid can still be drawn

st = opt.stride;
if (st <= 0)
    st = max(1,round(sqrt(numel(depth)/250000)));
end;
if (st > 1)
    fprintf(1,'Plotting every %d-th cell \n',st);
    kk = 1:st:size(depth,1);
    jj = 1:st:size(depth,2);
    [lon,lat,depth,mask,sx,sy] = sub_grid(kk,jj,lon,lat,depth,mask,sx,sy);
end;

%@@@ Dry cells out of the way

wet = (mask ~= 0) & (depth ~= opt.dry);
depth(~wet) = NaN;

%@@@ Height of the surface. gridgen keeps the depth negative downwards, so
%@@@ the relief is the depth itself, shrunk to the scale of the axes

if (opt.zex > 0)
    z = depth/opt.zex;
else
    z = zeros(size(depth));
    z(~wet) = NaN;
end;

%@@@ What the colour shows

switch lower(opt.field)
    case 'depth'
        c = depth;   ctitle = 'Depth (m)';
    case 'mask'
        c = mask;    c(~wet) = NaN;   ctitle = 'Land sea mask';
    case 'obstrx'
        if (isempty(sx))
            fprintf(1,'!!ERROR!!: No obstruction file for %s \n',fname);
            return;
        end;
        c = sx;      c(~wet) = NaN;   ctitle = 'Obstruction in x';
    case 'obstry'
        if (isempty(sy))
            fprintf(1,'!!ERROR!!: No obstruction file for %s \n',fname);
            return;
        end;
        c = sy;      c(~wet) = NaN;   ctitle = 'Obstruction in y';
    otherwise
        fprintf(1,'!!ERROR!!: Unrecognized field %s \n',opt.field);
        return;
end;

%@@@ The plot

figure;
hold on;

if (opt.land ~= 0)
    zl = zeros(size(depth));
    zl(wet) = NaN;
    hl = surf(lon,lat,zl);
    set(hl,'FaceColor',[0.75 0.73 0.68],'EdgeColor','none');
end;

h = surf(lon,lat,z,c);

%@@@ The face colour is set on the surface itself rather than with
%@@@ "shading interp", which would act on every surface of the axes and so
%@@@ would repaint the land as well

set(h,'FaceColor','interp','EdgeColor','none');

colormap(ocean_map(128));
hc = colorbar;

%@@@ In Octave, and in Matlab up to R2014a, the colour bar is an axes and is
%@@@ labelled through its YLabel; from R2014b Matlab returns a ColorBar
%@@@ object, labelled through its Label. Octave carries both properties, so
%@@@ the two are told apart by the interpreter and not by the property

if (exist('OCTAVE_VERSION','builtin') ~= 0)
    set(get(hc,'YLabel'),'String',ctitle);
else
    try
        set(get(hc,'Label'),'String',ctitle);
    catch
        set(get(hc,'YLabel'),'String',ctitle);
    end;
end;

xlabel('Longitude');
ylabel('Latitude');
if (opt.zex > 0)
    zlabel(sprintf('Depth / %g (m per degree)',opt.zex));
else
    zlabel('');
end;

[~,base,ext] = fileparts(fname);
title(sprintf('%s%s   (%s)',base,ext,ctitle),'interpreter','none');

axis tight;
box on;
grid on;
view(-35,55);

%@@@ A degree of longitude is shorter than a degree of latitude away from
%@@@ the equator, so the axes are set on the middle latitude of the grid

cosl = cos(mean(lat(:))*pi/180);
daspect([1 max(cosl,0.15) 1]);

try
    camlight headlight;
    lighting gouraud;
    material dull;
catch
    %@@@ lighting is not available everywhere; the surface is drawn anyway
end;

hold off;

return;

%% ------------------------------------------------------------------------
function varargout = sub_grid(kk,jj,varargin)
%@@@ Take the same rows and columns out of every (possibly empty) array
for i = 1:length(varargin)
    a = varargin{i};
    if (isempty(a))
        varargout{i} = a;
    else
        varargout{i} = a(kk,jj);
    end;
end;
return;

%% ------------------------------------------------------------------------
function cm = ocean_map(n)
%@@@ Blue ramp for bathymetry: pale on the shelf, dark in the deep. Built
%@@@ here so that the colours do not depend on the Matlab/Octave version.
p = [0.031 0.113 0.267; ...
     0.063 0.251 0.467; ...
     0.129 0.420 0.639; ...
     0.278 0.588 0.761; ...
     0.494 0.737 0.853; ...
     0.729 0.863 0.925; ...
     0.890 0.945 0.969];
x = linspace(0,1,size(p,1));
xi = linspace(0,1,n);
cm = [interp1(x,p(:,1),xi)' interp1(x,p(:,2),xi)' interp1(x,p(:,3),xi)'];
cm = min(max(cm,0),1);
return;

%% ------------------------------------------------------------------------
function sc = meta_scale(metaf,tag,pos,sc_def)
%@@@ Scaling factor of the record that names the file ending in "tag", taken
%@@@ as the pos-th number on that line (the records do not all carry the
%@@@ same leading fields). Falls back to sc_def when the record is missing.
sc = sc_def;
fid = fopen(metaf,'r');
if (fid < 0)
    return;
end;
while (1)
    tmp = fgetl(fid);
    if (~ischar(tmp))
        break;
    end;
    if (isempty(strfind(tmp,tag)) || (~isempty(tmp) && tmp(1) == '$'))
        continue;
    end;
    v = sscanf(tmp,'%f',pos);
    if (length(v) == pos && v(pos) ~= 0)
        sc = v(pos);
    end;
    break;
end;
fclose(fid);
return;
