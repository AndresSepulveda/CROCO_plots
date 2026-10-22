%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% MAKE_3D  3D views of a part of a CROCO domain (Matlab GUI; Matlab version
%          of oct_make_3d, also runs in Octave)
%
%   make_3d
%   make_3d(GRIDFILE)
%   make_3d(GRIDFILE,HISFILE)
%   make_3d(GRIDFILE,HISFILE,TOPOFILE)
%   fig = make_3d(...)          % handle of the selection window
%
%   GRIDFILE : CROCO grid file (h, mask_rho, lon_rho, lat_rho, angle).
%              Default: CROCO_FILES/croco_grd.nc if it exists, else a
%              file dialog.
%   HISFILE  : CROCO output file (croco_his.nc, croco_avg.nc ...) with
%              the 3D variables (temp, salt, u, v, w, ...) and the
%              s-coordinate parameters. Default: CROCO_FILES/croco_his.nc
%              (or croco_avg.nc) if it exists. Without it, only the
%              bathymetry and the land mask are drawn.
%   TOPOFILE : topography file (etopo2.nc ..., read as in make_grid /
%              add_topo: lon, lat, topo positive up) for the relief
%              of the land cells (mask_rho=0). Default: topofile of the
%              crocotools_param.m of the current folder, if it exists.
%              '' : no topography. Button "Topo..." to change it.
%
%   SELECTION WINDOW: map of the bathymetry (land in brown) with black
%   bathymetry contours (checkbox, depths editable, default 0 50 100 200
%   500 m; 0 m = limit of the land mask; the same contours are used by
%   the 3D view). Drag a
%   rectangle on the map (or type the I/J ranges, 0-based grid indices)
%   to select the part of the domain, then "Make 3D". "Max cells"
%   limits the number of cells per direction of the 3D view (the grid is
%   subsampled with a constant stride).
%
%   3D WINDOW: bathymetry (z=-h, blue shades) and land mask (cells with
%   mask_rho=0): land topography of TOPOFILE (terrain colours, menu
%   View > Land topography to switch it off) or a brown plateau at sea
%   level, lighting, rotation with the
%   mouse, vertical exaggeration (auto or 1...2000), black bathymetry
%   contours (checkbox, depths editable, default 0 50 100 200 500 m;
%   0 m = limit of the land mask).
%   Menu "Add":
%     Horizontal section : variable at a constant depth z (m, z <= 0:
%                          negative down, 0 = surface level; positive
%                          values are rejected), optional velocity
%                          vectors (u,v at the same depth, rotated to
%                          east/north with the grid angle);
%     Vertical section W-E, Vertical section S-N: variable from the
%                          bottom to the free surface along a constant J
%                          (W-E) or I (S-N) grid line, or at a constant
%                          latitude (W-E) / longitude (S-N): menu left of
%                          the position box (J index / Latitude, I index /
%                          Longitude); with latitude/longitude the fields
%                          are interpolated at that latitude/longitude;
%                          optional velocity vectors in the plane of
%                          the section: u+w (W-E) or v+w (S-N) (along the
%                          grid line u or v; at a constant latitude /
%                          longitude the eastward / northward velocity),
%                          drawn in the coordinates of the view, so that
%                          they follow the flow with the vertical
%                          exaggeration; "w x" multiplies w; the
%                          arrows are at fixed depths "Vec. z (m)"
%                          (z <= 0, e.g. 0 -10 -50 -100 -200; auto:
%                          regular depths);
%     Isosurface         : surface where the variable is equal to a
%                          value (on regular z levels), transparency;
%     Wind vectors (output file) / Wind vectors from BLK/FRC file...:
%                          wind (u10/v10, uwnd/vwnd, Uwind/Vwind) or
%                          wind stress (taux/tauy, sustr/svstr) vectors
%                          drawn on a horizontal plane ABOVE the sea
%                          surface (height in m, editable), coloured by
%                          the magnitude, rotated to east/north with the
%                          grid angle. From the his/avg file: record of
%                          the current time; from a BLK/FRC file: record
%                          nearest to the model time (cycle_length of the
%                          forcing time taken into account). The pair of
%                          variables is chosen in the "Variable" menu.
%                          Magnitude shown by colour + length, colour
%                          only (equal arrows) or length only (black or
%                          white arrows, reference arrow with its value);
%                          Scale = arrow length in grid cells per unit
%                          (m/s or N/m2), Skip = one arrow every SKIP cells.
%   Z range (m): minimum and maximum of the vertical axis (empty: auto,
%   from the deepest point to above the land / the wind planes); the
%   automatic vertical exaggeration follows this range.
%   Layers panel (right): list of the layers; for the selected layer:
%   variable (3D variables of the file and "speed"), position (depth,
%   J or I index / latitude or longitude, iso value), colour range
%   (min/max, Auto), colormap, transparency, visibility, velocity vectors
%   (skip, scale), Remove.
%   Colours: the colour range and the colormap belong to the VARIABLE:
%   all the layers of a variable (e.g. temp on horizontal and vertical
%   sections and isosurfaces) use the same range and colormap; editing
%   them in one layer changes all of them. Default range: whole 3D field
%   of the variable in the domain at the first time drawn (symmetric
%   around 0 for velocities, zeta, vorticity...), kept fixed in time;
%   "Auto" recomputes it at the current time. Default colormaps: cmocean
%   (tables included in this file): temp thermal, salt haline, rho
%   dense, u/v/w/zeta balance, speed and wind speed, O2 oxy, CHLA
%   algae, nutrients matter...; other Octave colormaps (viridis, jet...)
%   remain available in the menu.
%   The colour bar shows the selected layer.
%   Time: "<" / ">" or the time index box (all the layers are updated).
%   Animation: "Animate" plays the time steps "from"-"to" (button "Stop"
%   to interrupt); with "Record MP4" the frames (3D view and colour bar)
%   are written in the MP4 file (ffmpeg needed; if it is missing the PNG
%   frames are kept in a folder).
%   File menu: save the 3D view as PNG, close.
%
%   Arrays are kept in the (xi,eta,s) order of netcdf.getVar (Matlab
%   netcdf package, same order as octave-netcdf), no transposition.
%   MP4: VideoWriter 'MPEG-4' (Matlab on Windows/macOS), else ffmpeg,
%   else the PNG frames are kept (Matlab on Linux without ffmpeg: Motion
%   JPEG AVI with VideoWriter).
%
%  Matlab version of oct_make_3d (Oct-2026): same code without Octave-only
%  functions or syntax; cmocean colormaps (cmocean v3.0.3, MIT License,
%  Copyright (c) 2015 Kristen M. Thyng; Thyng et al. 2016, Oceanography
%  29(3):9-13) included as local functions. It also runs in Octave.
%
%  Further Information:
%  http://www.croco-ocean.org
%
%  This file is part of CROCOTOOLS
%
%  CROCOTOOLS is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published
%  by the Free Software Foundation; either version 2 of the License,
%  or (at your option) any later version.
%
%  CROCOTOOLS is distributed in the hope that it will be useful, but
%  WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%  MA  02111-1307  USA
%
%  Copyright (c) 2026 by Andres Sepulveda
%  Andres Sepulveda 2026 - Octave adaptations (and this Matlab version)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig_out=make_3d(gridfile,hisfile,topofile)
if nargin<1 || isempty(gridfile)
  gridfile='';
  if exist(fullfile('CROCO_FILES','croco_grd.nc'),'file')
    gridfile=fullfile('CROCO_FILES','croco_grd.nc');
  else
    [fn,pth]=uigetfile('*.nc','Select the CROCO grid file...');
    if isequal(fn,0), if nargout>0, fig_out=[]; end, return, end
    gridfile=[pth,fn];
  end
end
if nargin<2
  hisfile='';
  for f={'croco_his.nc','croco_avg.nc'}
    if exist(fullfile('CROCO_FILES',f{1}),'file')
      hisfile=fullfile('CROCO_FILES',f{1}); break
    end
  end
end
if exist('OCTAVE_VERSION','builtin') && ~any(strcmp(feval('graphics_toolkit'),{'qt','fltk'}))
  try
    feval('graphics_toolkit','qt');           % Octave only
  end
end
old=findobj(0,'tag','make_3d');
if ~isempty(old), delete(old); end
if nargin<3
  topofile=find_topo();
end
S=read_grid(gridfile);
S.hisfile=hisfile;
S=set_topo(S,topofile);
S.f3=[];
S.action=''; S.p0=[0 0];
S.maxcells=150;
S.i1=1; S.i2=S.Lp; S.j1=1; S.j2=S.Mp;
%
% Selection window
%
bg=[.94 .94 .94];
fig=figure('NumberTitle','off','Name','3D view: domain selection','tag','make_3d',...
           'MenuBar','none','ToolBar','none','Color',bg,'IntegerHandle','off',...
           'Units','normalized','Position',[.05 .1 .6 .7]);
S.fig=fig;
S.ax=axes('Parent',fig,'Units','normalized','Position',[0.08 0.1 0.6 0.85]);
S.hmap=surface(S.xcor,S.ycor,zeros(size(S.xcor)),pad_cdata(map_rgb(S)),'Parent',S.ax,...
               'FaceColor','flat','EdgeColor','none');
hold(S.ax,'on');
S.hblk=plot(S.ax,NaN,NaN,'r-','LineWidth',2);
S.hrect=plot(S.ax,NaN,NaN,'m--','LineWidth',1.5);
S.hcontour=plot(S.ax,NaN,NaN,'k-','LineWidth',0.8);
hold(S.ax,'off');
set(S.ax,'Layer','top','Box','on','TickDir','out','DataAspectRatio',[1/S.coslat 1 1]);
axis(S.ax,[min(S.xcor(:)) max(S.xcor(:)) min(S.ycor(:)) max(S.ycor(:))]);
xlabel(S.ax,'Longitude'); ylabel(S.ax,'Latitude');
title(S.ax,'Drag a rectangle to select the area');
x0=0.72; w=0.26; y=0.92;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w .04],'String','Files',...
          'FontWeight','bold','BackgroundColor',bg);
y=y-0.05;
S.hgfile=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w-.08 .04],...
          'String',short_name(S.gridfile),'HorizontalAlignment','left','BackgroundColor',bg);
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0+w-.075 y .075 .04],...
          'String','Grid...','Callback',@cb_opengrid);
y=y-0.05;
S.hhfile=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w-.08 .04],...
          'String',short_name(S.hisfile),'HorizontalAlignment','left','BackgroundColor',bg);
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0+w-.075 y .075 .04],...
          'String','Output...','Callback',@cb_openhis);
y=y-0.05;
S.htfile=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w-.08 .04],...
          'String',topo_label(S),'HorizontalAlignment','left','BackgroundColor',bg,...
          'TooltipString','Land topography (etopo2.nc ...), used on the cells with mask_rho=0');
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0+w-.075 y .075 .04],...
          'String','Topo...','Callback',@cb_opentopo);
y=y-0.06;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w .04],...
          'String','Area (0-based grid indices)','FontWeight','bold','BackgroundColor',bg);
lab={'I from','I to','J from','J to'}; fld={'i1','i2','j1','j2'};
for k=1:4
  y=y-0.05;
  uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .1 .04],'String',lab{k},...
            'HorizontalAlignment','left','BackgroundColor',bg);
  S.hidx(k)=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0+.1 y .08 .045],...
            'String','','Callback',@cb_index);
end
y=y-0.05;
S.hlonlat=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w .045],...
          'String','','HorizontalAlignment','left','BackgroundColor',bg);
y=y-0.06;
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0 y w .045],...
          'String','Whole grid','Callback',@cb_whole);
y=y-0.06;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .12 .04],'String','Max cells',...
          'HorizontalAlignment','left','BackgroundColor',bg);
S.hmaxc=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[x0+.12 y .1 .045],...
          'String',{'50','100','150','200','300','500'},'Value',3,'Callback',@cb_maxc);
y=y-0.06;
S.hcont=uicontrol(fig,'Style','checkbox','Units','normalized','Position',[x0 y w .04],...
          'String','Bathymetry contours (m)','Value',1,'BackgroundColor',bg,'Callback',@cb_selcontours,...
          'TooltipString','Black isobaths (0 m: land/sea mask limit); also used by the 3D view');
y=y-0.05;
S.hclev=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0 y w .045],...
          'String','0 50 100 200 500','Callback',@cb_selcontours,...
          'TooltipString','Depths of the contours (m), separated by spaces or commas');
y=y-0.09;
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0 y w .06],...
          'String','Make 3D','FontWeight','bold','Callback',@cb_make3d);
S.hstat=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 .01 w .1],...
          'String','','HorizontalAlignment','left','BackgroundColor',bg);
set(fig,'WindowButtonDownFcn',@cb_down,'WindowButtonMotionFcn',@cb_move,...
        'WindowButtonUpFcn',@cb_up,'CloseRequestFcn',@cb_close);
guidata(fig,S);
update_block(fig);
cb_selcontours(fig,[]);
if nargout>0, fig_out=fig; end
return
%
%======================================================================
%                          Local functions
%======================================================================
%
function v=ifelse(c,a,b)
if c, v=a; else, v=b; end
return
%
function k=first1(k)
% index found, or 1 (popup menus need a valid Value)
if isempty(k), k=1; end
return
%
function s=short_name(f)
if isempty(f), s='(none)'; return, end
[~,n,e]=fileparts(f); s=[n,e];
return
%
function S=read_grid(gridfile)
if ~exist(gridfile,'file')
  error(['make_3d: grid file not found: ',gridfile])
end
S.gridfile=gridfile;
nc=netcdf.open(gridfile,'NC_NOWRITE');
S.h=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'h')));
S.lon=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'lon_rho')));
S.lat=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'lat_rho')));
[S.Lp,S.Mp]=size(S.h);
S.mask=ones(S.Lp,S.Mp);
try
  S.mask=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'mask_rho'))>0.5);
end
S.angle=zeros(S.Lp,S.Mp);
try
  S.angle=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'angle')));
end
netcdf.close(nc);
[S.xcor,S.ycor]=cell_corners(S.lon,S.lat);
S.coslat=cos(mean(S.lat(:))*pi/180);
return
%
function [xc,yc]=cell_corners(lon,lat)
xe=extrap(lon); ye=extrap(lat);
xc=0.25*(xe(1:end-1,1:end-1)+xe(2:end,1:end-1)+xe(1:end-1,2:end)+xe(2:end,2:end));
yc=0.25*(ye(1:end-1,1:end-1)+ye(2:end,1:end-1)+ye(1:end-1,2:end)+ye(2:end,2:end));
return
%
function e=extrap(a)
[L,M]=size(a);
e=zeros(L+2,M+2);
e(2:end-1,2:end-1)=a;
e(1,2:end-1)=2*a(1,:)-a(min(2,L),:);
e(end,2:end-1)=2*a(end,:)-a(max(L-1,1),:);
e(:,1)=2*e(:,2)-e(:,min(3,M+1));
e(:,end)=2*e(:,end-1)-e(:,max(end-2,1));
return
%
function c=pad_cdata(c)
c=cat(1,c,c(end,:,:));
c=cat(2,c,c(:,end,:));
return
%
function rgb=val2rgb(v,cmap,cr)
% true colours of V with the colormap CMAP and the range CR (NaN: grey)
n=size(cmap,1);
k=round((v-cr(1))/max(cr(2)-cr(1),eps)*(n-1))+1;
bad=~isfinite(k);
k(bad)=1;
k=min(max(k,1),n);
rgb=reshape(cmap(k(:),:),[size(v) 3]);
N=numel(v);
for c=1:3
  rgb(find(bad)+(c-1)*N)=0.7;
end
return
%
function cm=bathy_cmap()
% light blue (shallow) to dark blue (deep)
cm=interp1([0 0.5 1],[0.80 0.90 0.97; 0.35 0.60 0.80; 0.05 0.12 0.35],linspace(0,1,64));
return
%
function rgb=map_rgb(S)
h=S.h; h(S.mask==0)=NaN;
rgb=val2rgb(h,bathy_cmap(),[min(h(:)) max(h(:))]);
rgb=land_rgb(rgb,S.mask,S.topo);
return
%
function cm=terrain_cmap()
% land: green (low) - brown - grey - white (high)
cm=interp1([0 0.15 0.45 0.75 1],[0.20 0.55 0.25; 0.55 0.70 0.35; 0.62 0.48 0.28;...
           0.55 0.47 0.42; 0.96 0.96 0.96],linspace(0,1,64));
return
%
function rgb=land_rgb(rgb,mask,topo)
% colours of the land cells: brown, or terrain colours of the elevation
land=find(mask==0); N=numel(mask);
if isempty(land), return, end
if isempty(topo)
  lc=[0.75 0.68 0.5];
  for c=1:3, rgb(land+(c-1)*N)=lc(c); end
else
  e=max(topo,0);
  tmax=max(e(land)); if ~(tmax>0), tmax=1; end
  lr=val2rgb(e,terrain_cmap(),[0 tmax]);
  for c=1:3, rgb(land+(c-1)*N)=lr(land+(c-1)*N); end
end
return
%
%---------------------------------------------------------------------
% Land topography (etopo2.nc as in make_grid / add_topo)
%---------------------------------------------------------------------
%
function f=find_topo()
% topofile of crocotools_param.m (current folder), if it exists
f='';
if exist(fullfile(pwd,'crocotools_param.m'),'file')
  try
    f=param_topo();
  end
end
if ~isempty(f) && ~exist(f,'file'), f=''; end
return
%
function f=param_topo()
str=evalc('crocotools_param');
f='';
if exist('topofile','var'), f=topofile; end
return
%
function s=topo_label(S)
if isempty(S.topo)
  s='Topo: (none)';
else
  s=['Topo: ',short_name(S.topofile)];
end
return
%
function S=set_topo(S,topofile)
S.topofile=topofile; S.topo=[];
if isempty(topofile), return, end
if ~exist(topofile,'file')
  warning(['make_3d: topography file not found: ',topofile]); return
end
try
  S.topo=read_topo(topofile,S.lon,S.lat);
  disp(sprintf('make_3d: land topography from %s (max %.0f m on land)',topofile,...
       max([0; S.topo(S.mask==0)])))
catch err
  warning(['make_3d: cannot read the topography in ',topofile,': ',err.message]);
  S.topo=[];
end
return
%
function e=read_topo(fname,lon,lat)
%
% Elevation (m, positive up) of the topography file at the points
% (lon,lat), read as in add_topo: 1D lon/lat, variable topo(lon,lat)
% (netcdf.getVar order), longitudes -360/0/+360, the data are averaged
% (resolution halved) while they are finer than the grid
%
nc=netcdf.open(fname,'NC_NOWRITE');
vn={{'lon','lat','topo'},{'x','y','z'},{'lon','lat','elevation'},{'longitude','latitude','topo'}};
ok=0;
for k=1:numel(vn)
  try
    tlon=double(netcdf.getVar(nc,netcdf.inqVarID(nc,vn{k}{1})));
    tlat=double(netcdf.getVar(nc,netcdf.inqVarID(nc,vn{k}{2})));
    vid=netcdf.inqVarID(nc,vn{k}{3});
    ok=1; break
  end
end
if ~ok
  netcdf.close(nc); error('no lon/lat/topo variables');
end
tlon=tlon(:); tlat=tlat(:);
dgrid=max(median(abs(diff(lat(1,:)))),median(abs(diff(lon(:,1)))));
if ~(dgrid>0), dgrid=0.1; end
dl=max(2*dgrid,0.1);
lonmin=min(lon(:))-dl; lonmax=max(lon(:))+dl;
latmin=min(lat(:))-dl; latmax=max(lat(:))+dl;
j=find(tlat>=latmin & tlat<=latmax);
x=[]; T=[];
for sh=[-360 0 360]
  i=find(tlon+sh>=lonmin & tlon+sh<=lonmax);
  if isempty(i) || isempty(j), continue, end
  t=double(netcdf.getVar(nc,vid,[i(1)-1 j(1)-1],[numel(i) numel(j)]));
  x=[x; tlon(i)+sh]; T=[T; t];
end
netcdf.close(nc);
if isempty(T), error('the topography file does not cover the grid'); end
y=tlat(j);
if y(1)>y(end), y=flipud(y); T=fliplr(T); end
T(abs(T)>1e5)=NaN;
dg=abs(mean(diff(x)));
while dgrid>2*dg && numel(x)>3 && numel(y)>3     % smooth the finer data
  x=0.5*(x(1:2:end-1)+x(2:2:end)); y=0.5*(y(1:2:end-1)+y(2:2:end));
  T=0.25*(T(1:2:end-1,1:2:end-1)+T(2:2:end,1:2:end-1)+T(1:2:end-1,2:2:end)+T(2:2:end,2:2:end));
  dg=abs(mean(diff(x)));
end
e=interp2(x,y,T.',lon,lat,'linear');
e(isnan(e))=0;
return
%
function cb_opentopo(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
[fn,pth]=uigetfile('*.nc','Select the topography file (etopo2.nc ...), Cancel: none');
if isequal(fn,0)
  S=set_topo(S,'');
else
  set(S.hstat,'String','Reading the topography...'); drawnow;
  S=set_topo(S,[pth,fn]);
end
set(S.htfile,'String',topo_label(S));
set(S.hmap,'CData',pad_cdata(map_rgb(S)));
set(S.hstat,'String','');
guidata(fig,S);
return
%
%---------------------------------------------------------------------
% Selection window
%---------------------------------------------------------------------
%
function set_status(fig,str)
S=guidata(fig); set(S.hstat,'String',str);
return
%
function update_block(fig)
S=guidata(fig);
v=[S.i1 S.i2 S.j1 S.j2]-1;
for k=1:4, set(S.hidx(k),'String',num2str(v(k))); end
i=S.i1:S.i2; j=S.j1:S.j2;
x=[S.lon(i,S.j1); S.lon(S.i2,j)'; flipud(S.lon(i,S.j2)); flipud(S.lon(S.i1,j)')];
y=[S.lat(i,S.j1); S.lat(S.i2,j)'; flipud(S.lat(i,S.j2)); flipud(S.lat(S.i1,j)')];
set(S.hblk,'XData',x,'YData',y);
st=max(1,ceil(max(numel(i),numel(j))/S.maxcells));
set(S.hlonlat,'String',sprintf('lon %.2f/%.2f  lat %.2f/%.2f\n%d x %d cells (stride %d)',...
    min(min(S.lon(i,j))),max(max(S.lon(i,j))),min(min(S.lat(i,j))),max(max(S.lat(i,j))),...
    numel(i),numel(j),st));
return
%
function p=cur_point(ax)
cp=get(ax,'CurrentPoint'); p=cp(1,1:2);
return
%
function r=inside(ax,p)
xl=xlim(ax); yl=ylim(ax);
r=p(1)>=xl(1) && p(1)<=xl(2) && p(2)>=yl(1) && p(2)<=yl(2);
return
%
function cb_down(fig,~)
S=guidata(fig);
p=cur_point(S.ax);
if ~inside(S.ax,p), return, end
S.action='rect'; S.p0=p;
set(S.hrect,'XData',p(1)*[1 1 1 1 1],'YData',p(2)*[1 1 1 1 1]);
guidata(fig,S);
return
%
function cb_move(fig,~)
S=guidata(fig);
if ~strcmp(S.action,'rect'), return, end
p=cur_point(S.ax); p0=S.p0;
set(S.hrect,'XData',[p0(1) p(1) p(1) p0(1) p0(1)],'YData',[p0(2) p0(2) p(2) p(2) p0(2)]);
return
%
function cb_up(fig,~)
S=guidata(fig);
if ~strcmp(S.action,'rect'), return, end
S.action='';
p=cur_point(S.ax); p0=S.p0;
set(S.hrect,'XData',NaN,'YData',NaN);
sel=(S.lon-p0(1)).*(S.lon-p(1))<=0 & (S.lat-p0(2)).*(S.lat-p(2))<=0;
[I,J]=find(sel);
if numel(unique(I))<2 || numel(unique(J))<2
  guidata(fig,S); set_status(fig,'The area must contain at least 2x2 cells'); return
end
S.i1=min(I); S.i2=max(I); S.j1=min(J); S.j2=max(J);
guidata(fig,S); update_block(fig); set_status(fig,'');
return
%
function cb_index(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=arrayfun(@(h) str2double(get(h,'String')),S.hidx)+1;
if all(isfinite(v))
  v=round(v);
  v(1:2)=sort(min(max(v(1:2),1),S.Lp)); v(3:4)=sort(min(max(v(3:4),1),S.Mp));
  if v(2)>v(1) && v(4)>v(3)
    S.i1=v(1); S.i2=v(2); S.j1=v(3); S.j2=v(4);
  end
end
guidata(fig,S); update_block(fig);
return
%
function cb_whole(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S.i1=1; S.i2=S.Lp; S.j1=1; S.j2=S.Mp;
guidata(fig,S); update_block(fig);
return
%
function cb_maxc(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=get(src,'String'); S.maxcells=str2double(v{get(src,'Value')});
guidata(fig,S); update_block(fig);
return
%
function cb_opengrid(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
[fn,pth]=uigetfile('*.nc','Select the CROCO grid file...');
if isequal(fn,0), return, end
his=S.hisfile;
delete(fig);
make_3d([pth,fn],his);
return
%
function cb_openhis(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
[fn,pth]=uigetfile('*.nc','Select the CROCO output file (his/avg)...');
if isequal(fn,0), return, end
S.hisfile=[pth,fn];
set(S.hhfile,'String',short_name(S.hisfile));
guidata(fig,S);
return
%
function cb_close(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if ~isempty(S) && ~isempty(S.f3) && ishghandle(S.f3)
  setappdata(S.f3,'stop',1);
  delete(S.f3);
end
delete(fig);
return
%
%---------------------------------------------------------------------
% 3D window: creation
%---------------------------------------------------------------------
%
function cb_make3d(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
set_status(fig,'Building the 3D view...'); drawnow;
layers=[]; vr=[];
if ~isempty(S.f3) && ishghandle(S.f3)
  T0=guidata(S.f3);
  if strcmp(T0.hisfile,S.hisfile), layers=T0.layers; end
  for k=1:numel(layers), layers(k).hg=[]; end
  if ~isempty(layers) && ~isfield(layers,'src'), [layers.src]=deal([]); end
  if ~isempty(layers) && ~isfield(layers,'pmode'), [layers.pmode]=deal(0); end
  if ~isempty(layers) && ~isfield(layers,'wfac'), [layers.wfac]=deal(1); end
  if ~isempty(layers) && ~isfield(layers,'vdep'), [layers.vdep]=deal([]); end
  vr=[]; if strcmp(T0.hisfile,S.hisfile) && isfield(T0,'vr'), vr=T0.vr; end
  setappdata(S.f3,'stop',1);
  delete(S.f3);
end
T=make_state(S);
if ~isempty(layers), T.layers=layers; end
if ~isempty(vr), T.vr=vr; end
T.contours=get(S.hcont,'Value'); T.clevels=get(S.hclev,'String');
f3=create_3d_window(T,fig);
S.f3=f3; guidata(fig,S);
T=guidata(f3);
T=render_all(T);
guidata(f3,T);
update_panel(f3);
set_status(fig,sprintf('3D view: %d x %d cells',numel(T.ii),numel(T.jj)));
return
%
function T=make_state(S)
st=max(1,ceil(max(S.i2-S.i1+1,S.j2-S.j1+1)/S.maxcells));
T.ii=unique([S.i1:st:S.i2 S.i2]); T.jj=unique([S.j1:st:S.j2 S.j2]);
T.i1=S.i1; T.i2=S.i2; T.j1=S.j1; T.j2=S.j2;
T.ri=T.ii-S.i1+1; T.rj=T.jj-S.j1+1;          % indices in the read block
T.stride=st;
T.Lp=S.Lp; T.Mp=S.Mp;
T.lon=S.lon(T.ii,T.jj); T.lat=S.lat(T.ii,T.jj);
T.h=S.h(T.ii,T.jj); T.mask=S.mask(T.ii,T.jj); T.angle=S.angle(T.ii,T.jj);
T.topo=[]; T.showtopo=1;
if ~isempty(S.topo), T.topo=S.topo(T.ii,T.jj); end
T.coslat=cos(mean(T.lat(:))*pi/180);
T.gridfile=S.gridfile; T.hisfile=S.hisfile;
T.layers=struct('type',{},'var',{},'pos',{},'cmin',{},'cmax',{},'cmap',{},...
                'alpha',{},'visible',{},'vec',{},'vskip',{},'vscale',{},'hg',{},'src',{},'pmode',{},'wfac',{},'vdep',{});
T.vr=struct('var',{},'cmin',{},'cmax',{},'cmap',{});   % colour range and map per variable
T.zrange=[NaN NaN];
T.exagval=NaN;
T.zl=[];
T.sel=0;
T.cache=struct('key',{},'val',{});
T.vars={}; T.vinfo=struct('name',{},'grid',{},'w',{},'fill',{},'scale',{},'offset',{});
T.nt=0; T.time=[]; T.tindex=1; T.N=0;
om={'viridis','parula','turbo','jet','hot','cool','bone','cubehelix'};
om=om(cellfun(@(c) exist(c)>0,om));
T.cmaps=[cmocean_map(),om];                  % cmocean maps first (default)
T.cmaplab=[strcat('cmo.',cmocean_map()),om];
T.hiswind=[];
if ~isempty(T.hisfile) && exist(T.hisfile,'file')
  T=read_his_info(T);
  T.hiswind=wind_source(T.hisfile,1);
end
return
%
function T=read_his_info(T)
nc=netcdf.open(T.hisfile,'NC_NOWRITE');
gid=netcdf.getConstant('NC_GLOBAL');
[~,T.N]=netcdf.inqDim(nc,netcdf.inqDimID(nc,'s_rho'));
p=struct('theta_s',[],'theta_b',[],'hc',[],'Vtransform',[]);
for f=fieldnames(p)'
  try
    p.(f{1})=double(netcdf.getVar(nc,netcdf.inqVarID(nc,f{1})));
  catch
    try
      p.(f{1})=double(netcdf.getAtt(nc,gid,f{1}));
    end
  end
  if ~isempty(p.(f{1})), p.(f{1})=p.(f{1})(1); end
end
if isempty(p.Vtransform)
  p.Vtransform=1;
  try
    if strcmpi(strtrim(netcdf.getAtt(nc,gid,'VertCoordType')),'NEW'), p.Vtransform=2; end
  end
end
if isempty(p.hc)
  try, p.hc=double(netcdf.getAtt(nc,gid,'Tcline')); end
end
T.sc=p;
[~,nv]=netcdf.inq(nc);
for v=0:nv-1
  [name,~,dims]=netcdf.inqVar(nc,v);
  if numel(dims)~=4, continue, end
  dn=cell(1,4);
  for k=1:4, dn{k}=netcdf.inqDim(nc,dims(k)); end
  if ~any(strcmp(dn{3},{'s_rho','s_w'})), continue, end
  g='r';
  if strcmp(dn{1},'xi_u'), g='u'; elseif strcmp(dn{2},'eta_v'), g='v'; end
  I.name=name; I.grid=g; I.w=strcmp(dn{3},'s_w');
  I.fill=[]; I.scale=1; I.offset=0;
  try, I.fill=double(netcdf.getAtt(nc,v,'_FillValue')); end
  try, I.scale=double(netcdf.getAtt(nc,v,'scale_factor')); end
  try, I.offset=double(netcdf.getAtt(nc,v,'add_offset')); end
  T.vinfo(end+1)=I;
end
T.vars={T.vinfo.name};
if any(strcmp(T.vars,'u')) && any(strcmp(T.vars,'v'))
  T.vars{end+1}='speed';
end
T.time=[];
for tn={'scrum_time','time','ocean_time'}
  try
    T.time=double(netcdf.getVar(nc,netcdf.inqVarID(nc,tn{1})));
    break
  end
end
T.haszeta=1;
try
  netcdf.inqVarID(nc,'zeta');
catch
  T.haszeta=0;
end
try
  [~,T.nt]=netcdf.inqDim(nc,netcdf.inqDimID(nc,'time'));
catch
  T.nt=numel(T.time);
end
netcdf.close(nc);
if isempty(T.time), T.time=(0:T.nt-1)'; end
if numel(T.vars)==0
  warning(['make_3d: no 3D variable in ',T.hisfile]);
end
return
%
function f3=create_3d_window(T,fig0)
bg=[.94 .94 .94];
f3=figure('NumberTitle','off','Name',['3D view - ',short_name(T.gridfile),' ',short_name(T.hisfile)],...
          'tag','make_3d_view','MenuBar','none','ToolBar','figure','Color',bg,...
          'IntegerHandle','off','Units','normalized','Position',[.08 .06 .84 .84]);
T.fig=f3; T.fig0=fig0;
setappdata(f3,'stop',0);
hf=uimenu(f3,'Label','File');
uimenu(hf,'Label','Save view as PNG...','Callback',@cb_savepng);
uimenu(hf,'Label','Close','Callback',@(s,e) delete(f3),'Separator','on');
ha=uimenu(f3,'Label','Add');
en=ifelse(T.nt>0 && ~isempty(T.vars),'on','off');
uimenu(ha,'Label','Horizontal section (depth)','Callback',{@cb_add,'h'},'Enable',en);
uimenu(ha,'Label','Vertical section W-E','Callback',{@cb_add,'vj'},'Enable',en);
uimenu(ha,'Label','Vertical section S-N','Callback',{@cb_add,'vi'},'Enable',en);
uimenu(ha,'Label','Isosurface','Callback',{@cb_add,'iso'},'Enable',en);
uimenu(ha,'Label','Wind vectors (output file)','Callback',{@cb_add,'w'},'Separator','on',...
       'Enable',ifelse(~isempty(T.hiswind),'on','off'));
uimenu(ha,'Label','Wind vectors from BLK/FRC file...','Callback',{@cb_add,'wfile'});
hv=uimenu(f3,'Label','View');
uimenu(hv,'Label','Reset view','Callback',@cb_resetview);
uimenu(hv,'Label','View from above','Callback',@cb_topview);
uimenu(hv,'Label','Hide/show bathymetry','Callback',@cb_togglebathy);
T.htopomenu=uimenu(hv,'Label','Land topography','Callback',@cb_toggletopo,'Checked','on',...
                   'Enable',ifelse(isempty(T.topo),'off','on'));
T.ax=axes('Parent',f3,'Units','normalized','Position',[0.05 0.17 0.63 0.78]);
T.cax=axes('Parent',f3,'Units','normalized','Position',[0.72 0.25 0.018 0.6]);
set(T.cax,'XTick',[],'YAxisLocation','right','Box','on','Visible','off');
T.hcbar=[];
%
% Layers panel
%
x0=0.8; w=0.19; y=0.93;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y w .03],'String','Layers (menu Add)',...
          'FontWeight','bold','BackgroundColor',bg);
T.hlist=uicontrol(f3,'Style','listbox','Units','normalized','Position',[x0 y-.16 w .155],...
          'String',{},'Value',[],'Min',0,'Max',2,'Callback',@cb_select);   % Max-Min>1: empty Value allowed
y=y-.205;
T.hvis=uicontrol(f3,'Style','checkbox','Units','normalized','Position',[x0 y .09 .035],...
          'String','Visible','BackgroundColor',bg,'Callback',@cb_prop);
T.hremove=uicontrol(f3,'Style','pushbutton','Units','normalized','Position',[x0+.1 y .09 .035],...
          'String','Remove','Callback',@cb_remove);
y=y-.045;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .07 .035],'String','Variable',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hvar=uicontrol(f3,'Style','popupmenu','Units','normalized','Position',[x0+.07 y .12 .037],...
          'String',ifelse(isempty(T.vars),{'-'},T.vars),'Callback',@cb_prop);
y=y-.045;
T.hposlab=uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .1 .035],'String','Position',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hposmode=uicontrol(f3,'Style','popupmenu','Units','normalized','Position',[x0 y .1 .037],...
          'String',{'J index','Latitude'},'Value',1,'Callback',@cb_prop,'Visible','off',...
          'TooltipString','Section defined by a grid index or by a longitude/latitude');
T.hpos=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.1 y .09 .037],...
          'String','','Callback',@cb_prop);
y=y-.035;
T.hposinfo=uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y w .03],'String','',...
          'HorizontalAlignment','left','BackgroundColor',bg);
y=y-.045;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .07 .035],'String','Colours',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hcmin=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.07 y .06 .037],...
          'String','','Callback',@cb_prop,'TooltipString','Minimum of the colour range');
T.hcmax=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.13 y .06 .037],...
          'String','','Callback',@cb_prop,'TooltipString','Maximum of the colour range');
y=y-.045;
T.hauto=uicontrol(f3,'Style','pushbutton','Units','normalized','Position',[x0 y .07 .037],...
          'String','Auto','Callback',@cb_auto,...
          'TooltipString','Range of the whole 3D field of the variable at this time (all its layers)');
T.hcmap=uicontrol(f3,'Style','popupmenu','Units','normalized','Position',[x0+.07 y .12 .037],...
          'String',T.cmaplab,'Callback',@cb_prop,...
          'TooltipString','Colormap of the variable (cmo.: cmocean), shared by all its layers');
y=y-.045;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .11 .035],'String','Opacity (0-1)',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.halpha=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.11 y .08 .037],...
          'String','','Callback',@cb_prop);
y=y-.05;
T.hvec=uicontrol(f3,'Style','checkbox','Units','normalized','Position',[x0 y w .035],...
          'String','Velocity vectors (u,v)','BackgroundColor',bg,'Callback',@cb_prop);
T.hwfaclab=uicontrol(f3,'Style','text','Units','normalized','Position',[x0+.13 y .025 .035],...
          'String','w x','HorizontalAlignment','left','BackgroundColor',bg,'Visible','off');
T.hwfac=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.155 y .035 .037],...
          'String','1','Callback',@cb_prop,'Visible','off',...
          'TooltipString',['Factor applied to w in the vectors of the vertical sections (1: true ',...
                           'direction in the view, with its vertical exaggeration)']);
T.hwmode=uicontrol(f3,'Style','popupmenu','Units','normalized','Position',[x0 y w .037],...
          'String',{'Magnitude: colour + length','Magnitude: colour only','Magnitude: length (black)',...
          'Magnitude: length (white)'},'Value',1,'Callback',@cb_prop,'Visible','off',...
          'TooltipString','How the wind magnitude is shown');
y=y-.042;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .04 .035],'String','Skip',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hvskip=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.04 y .05 .037],...
          'String','','Callback',@cb_prop,'TooltipString','One vector every SKIP cells');
uicontrol(f3,'Style','text','Units','normalized','Position',[x0+.1 y .045 .035],'String','Scale',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hvscale=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.145 y .045 .037],...
          'String','','Callback',@cb_prop,'TooltipString','1: the largest vector = SKIP cells');
y=y-.04;
T.hvdlab=uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .07 .033],'String','Vec. z (m)',...
          'HorizontalAlignment','left','BackgroundColor',bg,'Visible','off');
T.hvdep=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.07 y .12 .035],...
          'String','auto','Callback',@cb_prop,'Visible','off',...
          'TooltipString',['Depths z (m, <= 0) of the vectors of the vertical section, e.g. ',...
                           '0 -10 -50 -100 -200 -500; auto (or empty): regular depths']);
y=y-.05;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .11 .035],'String','Vert. exaggeration',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hexag=uicontrol(f3,'Style','popupmenu','Units','normalized','Position',[x0+.11 y .08 .037],...
          'String',{'auto','1','5','10','20','50','100','200','500','1000','2000'},'Value',1,...
          'Callback',@cb_exag);
y=y-.05;
T.hcont=uicontrol(f3,'Style','checkbox','Units','normalized','Position',[x0 y w .035],...
          'String','Bathymetry contours (m)','Value',T.contours,'BackgroundColor',bg,'Callback',@cb_contours,...
          'TooltipString','Black isobaths on the bathymetry (0 m: land/sea mask limit)');
y=y-.042;
T.hclev=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0 y w .037],...
          'String',T.clevels,'Callback',@cb_contours,...
          'TooltipString','Depths of the contours (m), separated by spaces or commas');
T.hcontour=[];
y=y-.055;
uicontrol(f3,'Style','text','Units','normalized','Position',[x0 y .07 .035],'String','Z range (m)',...
          'HorizontalAlignment','left','BackgroundColor',bg);
T.hzmin=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.07 y .06 .037],...
          'String','','Callback',@cb_zrange,'TooltipString','Bottom of the z axis (m, e.g. -500); empty: auto');
T.hzmax=uicontrol(f3,'Style','edit','Units','normalized','Position',[x0+.13 y .06 .037],...
          'String','','Callback',@cb_zrange,'TooltipString','Top of the z axis (m); empty: auto');
%
% Time and animation (bottom)
%
y=0.075;
uicontrol(f3,'Style','text','Units','normalized','Position',[0.05 y .05 .035],'String','Time',...
          'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',bg);
T.hprev=uicontrol(f3,'Style','pushbutton','Units','normalized','Position',[0.1 y .03 .037],...
          'String','<','Callback',{@cb_step,-1});
T.htime=uicontrol(f3,'Style','edit','Units','normalized','Position',[0.135 y .05 .037],...
          'String','1','Callback',@cb_time);
T.hnext=uicontrol(f3,'Style','pushbutton','Units','normalized','Position',[0.19 y .03 .037],...
          'String','>','Callback',{@cb_step,1});
T.htlab=uicontrol(f3,'Style','text','Units','normalized','Position',[0.225 y .25 .035],...
          'String','','HorizontalAlignment','left','BackgroundColor',bg);
y=0.025;
uicontrol(f3,'Style','text','Units','normalized','Position',[0.05 y .08 .035],'String','Animation',...
          'FontWeight','bold','HorizontalAlignment','left','BackgroundColor',bg);
uicontrol(f3,'Style','text','Units','normalized','Position',[0.13 y .035 .035],'String','from',...
          'BackgroundColor',bg);
T.hafrom=uicontrol(f3,'Style','edit','Units','normalized','Position',[0.165 y .04 .037],'String','1');
uicontrol(f3,'Style','text','Units','normalized','Position',[0.21 y .02 .035],'String','to',...
          'BackgroundColor',bg);
T.hato=uicontrol(f3,'Style','edit','Units','normalized','Position',[0.235 y .04 .037],...
          'String',num2str(max(T.nt,1)));
uicontrol(f3,'Style','text','Units','normalized','Position',[0.28 y .03 .035],'String','fps',...
          'BackgroundColor',bg);
T.hfps=uicontrol(f3,'Style','edit','Units','normalized','Position',[0.31 y .035 .037],'String','4');
T.hrec=uicontrol(f3,'Style','checkbox','Units','normalized','Position',[0.355 y .1 .035],...
          'String','Record MP4','BackgroundColor',bg);
T.hmp4=uicontrol(f3,'Style','edit','Units','normalized','Position',[0.455 y .14 .037],...
          'String','make_3d.mp4','TooltipString','MP4 file');
T.hanim=uicontrol(f3,'Style','pushbutton','Units','normalized','Position',[0.6 y .08 .045],...
          'String','Animate','FontWeight','bold','Callback',@cb_animate);
T.hstat=uicontrol(f3,'Style','text','Units','normalized','Position',[0.69 0.005 0.3 0.06],...
          'String','','HorizontalAlignment','left','BackgroundColor',bg);
if T.nt==0
  set([T.hprev T.hnext T.htime T.hanim T.hrec],'Enable','off');
end
set(f3,'CloseRequestFcn',@cb_close3d);
%
% Bathymetry and land mask
%
T=draw_bathy(T);
T=draw_contours(T);
guidata(f3,T);
set_exag(f3);
view(T.ax,-35,35);
update_time_label(f3);
return
%
function T=draw_bathy(T)
ax=T.ax;
cla(ax); hold(ax,'on');
T=redraw_bathy_surface(T);
try
  T.hlight=light('Parent',ax,'Position',[-1 1 3],'Style','infinite');
end
hold(ax,'off');
set(ax,'Box','on','Projection','perspective');
grid(ax,'on');
xlabel(ax,'Longitude'); ylabel(ax,'Latitude'); zlabel(ax,'z (m)');
xlim(ax,[min(T.lon(:)) max(T.lon(:))]); ylim(ax,[min(T.lat(:)) max(T.lat(:))]);
return
%
function T=redraw_bathy_surface(T)
%
% Surface of the bottom (z=-h) and of the land cells (mask_rho=0):
% topography of the topography file (terrain colours) or a brown plateau
% at sea level
%
ax=T.ax;
Z=-T.h;
land=T.mask==0;
hl=max(T.h(:));
topo=[];
if T.showtopo && ~isempty(T.topo), topo=T.topo; end
if isempty(topo)
  Z(land)=0.01*hl;                             % land: plateau at sea level
  ztop=0.05*hl;
else
  Z(land)=max(topo(land),0);                   % land: topography
  ztop=max([0.05*hl; 1.05*Z(land)]);
end
hs=T.h; hs(land)=NaN;
rgb=val2rgb(hs,bathy_cmap(),[min(hs(:)) max(hs(:))]);
if isempty(topo)
  N=numel(Z); lc=[0.62 0.5 0.32];
  for c=1:3, rgb(find(land)+(c-1)*N)=lc(c); end
else
  rgb=land_rgb(rgb,T.mask,topo);
end
if isfield(T,'hbathy') && ~isempty(T.hbathy) && ishghandle(T.hbathy)
  delete(T.hbathy);
end
T.hbathy=surface(T.lon,T.lat,Z,rgb,'Parent',ax,'EdgeColor','none','FaceColor','interp');
try
  set(T.hbathy,'FaceLighting','gouraud','AmbientStrength',0.5,'DiffuseStrength',0.7,'SpecularStrength',0.05);
end
T.ztop=ztop; T.ztopo=ifelse(isempty(topo),0,ztop);
T=apply_zlim(T);
return
%
function T=apply_zlim(T)
%
% Limits of the z axis: Z range of the panel, or automatic (deepest point
% to above the land and the wind planes); then the vertical aspect
%
zl=[-max(T.h(:)) T.ztop];
for k=1:numel(T.layers)
  if strcmp(T.layers(k).type,'w') && T.layers(k).visible
    zl(2)=max(zl(2),1.15*T.layers(k).pos);
  end
end
if isfinite(T.zrange(1)), zl(1)=T.zrange(1); end
if isfinite(T.zrange(2)), zl(2)=T.zrange(2); end
if zl(2)<=zl(1), zl=[-max(T.h(:)) T.ztop]; end
zlim(T.ax,zl);
T.zl=zl;
T=apply_aspect(T);
return
%
function T=apply_aspect(T)
if ~isfield(T,'hexag') || isempty(T.zl), return, end
v=get(T.hexag,'String'); v=v{get(T.hexag,'Value')};
xyr=max((max(T.lon(:))-min(T.lon(:)))*T.coslat,max(T.lat(:))-min(T.lat(:)));
zr=diff(T.zl);
if strcmp(v,'auto')
  dz=zr/(0.35*xyr);
else
  dz=111e3/str2double(v);
end
set(T.ax,'DataAspectRatio',[1/T.coslat 1 dz]);
T.exagval=111e3/dz;
return
%
function cb_zrange(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
v=[str2double(get(T.hzmin,'String')) str2double(get(T.hzmax,'String'))];
if all(isfinite(v)) && v(2)<=v(1)
  set_status3(f3,'Z range: the maximum must be larger than the minimum'); return
end
T.zrange=v;
set(T.hzmin,'String',ifelse(isfinite(v(1)),num2str(v(1)),''));
set(T.hzmax,'String',ifelse(isfinite(v(2)),num2str(v(2)),''));
e0=T.exagval;
T=apply_zlim(T);
T=redraw_secvec(T,e0);
guidata(f3,T); update_title(f3);
set_status3(f3,sprintf('z axis: %g to %g m',T.zl));
return
%
function set_exag(f3)
T=guidata(f3);
e0=ifelse(isfield(T,'exagval'),T.exagval,NaN);
T=apply_aspect(T);
T=redraw_secvec(T,e0);
guidata(f3,T);
update_title(f3);
return
%
function T=redraw_secvec(T,e0)
%
% Vectors of the vertical sections follow the vertical exaggeration:
% redrawn when it changed
%
if ~isfield(T,'exagval') || ~isfinite(T.exagval) || (isfinite(e0) && abs(e0-T.exagval)<=1e-9*T.exagval), return, end
for k=1:numel(T.layers)
  if T.layers(k).vec && any(strcmp(T.layers(k).type,{'vj','vi'}))
    T=render_layer(T,k);
  end
end
return
%
function cb_exag(src,~)
f3=ancestor(src,'figure'); set_exag(f3);
return
%
function cb_topview(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
view(T.ax,0,90);
return
%
function cb_resetview(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
view(T.ax,-35,35);
return
%
function cb_togglebathy(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
vis=ifelse(strcmp(get(T.hbathy,'Visible'),'on'),'off','on');
set(T.hbathy,'Visible',vis);
if ~isempty(T.hcontour) && ishghandle(T.hcontour)
  set(T.hcontour,'Visible',ifelse(get(T.hcont,'Value'),vis,'off'));
end
return
%
function cb_toggletopo(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
T.showtopo=~T.showtopo;
set(T.htopomenu,'Checked',ifelse(T.showtopo,'on','off'));
vis=get(T.hbathy,'Visible');
hold(T.ax,'on');
T=redraw_bathy_surface(T);
hold(T.ax,'off');
set(T.hbathy,'Visible',vis);
guidata(f3,T);
set_exag(f3);
return
%
function cb_contours(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
T=draw_contours(T);
guidata(f3,T);
return
%
function T=draw_contours(T)
%
% Black isobaths on the bathymetry surface. Levels > 0: contours of h on
% the sea cells; level 0: limit of the land/sea mask (coastline of the
% model)
%
if ~isempty(T.hcontour) && ishghandle(T.hcontour), delete(T.hcontour); end
T.hcontour=[];
lev=parse_levels(T.hclev);
if ~get(T.hcont,'Value') || isempty(lev), return, end
[X,Y,Z]=contour_lines(T.lon,T.lat,T.h,T.mask,lev,0.004*max(T.h(:)));
if isempty(X), return, end
T.hcontour=line(X,Y,Z,'Parent',T.ax,'Color','k','LineWidth',1);
if strcmp(get(T.hbathy,'Visible'),'off'), set(T.hcontour,'Visible','off'); end
return
%
function cb_close3d(src,~)
f3=ancestor(src,'figure');
setappdata(f3,'stop',1);
delete(f3);
return
%
function update_title(f3)
T=guidata(f3);
s=sprintf('I=%d:%d J=%d:%d (stride %d), vertical exaggeration x%.0f',T.i1-1,T.i2-1,T.j1-1,T.j2-1,...
          T.stride,T.exagval);
if T.nt>0
  s=sprintf('%s\ntime %d/%d: %s',s,T.tindex,T.nt,time_str(T));
end
title(T.ax,s);
return
%
function s=time_str(T)
t=T.time(T.tindex);
s=sprintf('%.2f days',t/86400);
return
%
function update_time_label(f3)
T=guidata(f3);
if T.nt==0
  set(T.htlab,'String','no output file: bathymetry only');
else
  set(T.htime,'String',num2str(T.tindex));
  set(T.htlab,'String',sprintf('/ %d   %s',T.nt,time_str(T)));
end
update_title(f3);
return
%
function set_status3(f3,str)
T=guidata(f3); set(T.hstat,'String',str);
return
%
%---------------------------------------------------------------------
% Reading the output file
%---------------------------------------------------------------------
%
function [V,T]=get_var(T,name)
%
% Variable NAME at the time T.tindex on the rho points of the block,
% (nI,nJ,N) array (NaN on land). Cached.
%
key=sprintf('%s@%d',name,T.tindex);
k=find(strcmp({T.cache.key},key),1);
if ~isempty(k), V=T.cache(k).val; return, end
switch name
  case 'speed'
    [u,T]=get_var(T,'u'); [v,T]=get_var(T,'v');
    V=sqrt(u.^2+v.^2);
  case 'z_r'
    V=zr_block(T);
  otherwise
    V=read_block(T,name);
end
T.cache(end+1)=struct('key',key,'val',V);
return
%
function V=read_block(T,name)
I=T.vinfo(strcmp({T.vinfo.name},name));
t0=T.tindex-1;
nk=T.N+I.w;
nc=netcdf.open(T.hisfile,'NC_NOWRITE');
vid=netcdf.inqVarID(nc,name);
switch I.grid
  case 'u'
    a=max(T.i1-1,1); b=min(T.i2,T.Lp-1);
    X=double(netcdf.getVar(nc,vid,[a-1 T.j1-1 0 t0],[b-a+1 T.j2-T.j1+1 nk 1]));
  case 'v'
    a=max(T.j1-1,1); b=min(T.j2,T.Mp-1);
    X=double(netcdf.getVar(nc,vid,[T.i1-1 a-1 0 t0],[T.i2-T.i1+1 b-a+1 nk 1]));
  otherwise
    X=double(netcdf.getVar(nc,vid,[T.i1-1 T.j1-1 0 t0],[T.i2-T.i1+1 T.j2-T.j1+1 nk 1]));
end
netcdf.close(nc);
if ~isempty(I.fill), X(X==I.fill)=NaN; end
X=X*I.scale+I.offset;
X(abs(X)>1e30)=NaN;
switch I.grid                                % to rho points
  case 'u'
    if T.i1==1, X=cat(1,X(1,:,:),X); end
    if T.i2==T.Lp, X=cat(1,X,X(end,:,:)); end
    X=0.5*(X(1:end-1,:,:)+X(2:end,:,:));
  case 'v'
    if T.j1==1, X=cat(2,X(:,1,:),X); end
    if T.j2==T.Mp, X=cat(2,X,X(:,end,:)); end
    X=0.5*(X(:,1:end-1,:)+X(:,2:end,:));
end
if I.w                                       % w levels -> rho levels
  X=0.5*(X(:,:,1:end-1)+X(:,:,2:end));
end
V=X(T.ri,T.rj,:);
m=repmat(T.mask==0,[1 1 size(V,3)]);
V(m)=NaN;
return
%
function z=zr_block(T)
% depth of the rho points of the block (nI,nJ,N)
zeta=zeros(size(T.h));
if T.haszeta
  nc=netcdf.open(T.hisfile,'NC_NOWRITE');
  X=double(netcdf.getVar(nc,netcdf.inqVarID(nc,'zeta'),[T.i1-1 T.j1-1 T.tindex-1],...
                         [T.i2-T.i1+1 T.j2-T.j1+1 1]));
  netcdf.close(nc);
  zeta=X(T.ri,T.rj);
  zeta(~isfinite(zeta) | abs(zeta)>1e3)=0;
end
p=T.sc; N=T.N; h=T.h;
sc=((1:N)-N-0.5)/N;
ts=p.theta_s; tb=p.theta_b; hc=p.hc;
z=zeros([size(h) N]);
if p.Vtransform==2
  if ts>0, Cs=(1-cosh(ts*sc))/(cosh(ts)-1); else, Cs=-sc.^2; end
  if tb>0, Cs=(exp(tb*Cs)-1)/(1-exp(-tb)); end
  for k=1:N
    z0=(hc*sc(k)+Cs(k)*h)./(hc+h);
    z(:,:,k)=zeta+(zeta+h).*z0;
  end
else
  Cs=(1-tb)*sinh(ts*sc)/sinh(ts)+tb*(tanh(ts*(sc+0.5))/(2*tanh(0.5*ts))-0.5);
  hh=h; hh(hh==0)=1e-2;
  for k=1:N
    z0=hc*(sc(k)-Cs(k))+Cs(k)*hh;
    z(:,:,k)=z0+zeta.*(1+z0./hh);
  end
end
return
%
function out=hslice(Z,V,d)
% V at the depth d (d>=0 or above the upper level: upper level value)
[L,M,N]=size(Z);
out=NaN(L,M);
top=Z(:,:,N);
m=d>=top;
v=V(:,:,N); out(m)=v(m);
for k=1:N-1
  z1=Z(:,:,k); z2=Z(:,:,k+1);
  m=isnan(out) & z1<=d & z2>=d;
  if any(m(:))
    v1=V(:,:,k); v2=V(:,:,k+1);
    w=(d-z1(m))./max(z2(m)-z1(m),eps);
    out(m)=v1(m)+w.*(v2(m)-v1(m));
  end
end
return
%
%---------------------------------------------------------------------
% Layers
%---------------------------------------------------------------------
%
function s=layer_name(T,L)
switch L.type
  case 'h',   s=sprintf('H %s z=%g m',L.var,L.pos);
  case 'vj'
    if L.pmode, s=sprintf('V W-E %s lat=%g',L.var,L.pos); else, s=sprintf('V W-E %s J=%d',L.var,L.pos); end
  case 'vi'
    if L.pmode, s=sprintf('V S-N %s lon=%g',L.var,L.pos); else, s=sprintf('V S-N %s I=%d',L.var,L.pos); end
  case 'iso', s=sprintf('ISO %s = %g',L.var,L.pos);
  case 'w',   s=sprintf('WIND %s z=+%g m (%s)',L.var,L.pos,short_name(L.src.file));
end
if L.vec, s=[s,' +vec']; end
if ~L.visible, s=[s,' (hidden)']; end
return
%
function cb_add(src,~,type)
f3=ancestor(src,'figure'); T=guidata(f3);
var='';
if ~isempty(T.vars), var=ifelse(any(strcmp(T.vars,'temp')),'temp',T.vars{1}); end
L=struct('type',type,'var',var,'pos',0,'cmin',NaN,'cmax',NaN,'cmap',1,...
         'alpha',1,'visible',1,'vec',0,'vskip',max(1,round(numel(T.ii)/20)),'vscale',1,'hg',[],'src',[],'pmode',0,'wfac',1,'vdep',[]);
if any(strcmp(type,{'w','wfile'}))
  if strcmp(type,'w')
    S=T.hiswind;
  else
    [fn,pth]=uigetfile({'*blk*.nc;*frc*.nc','CROCO bulk/forcing files';'*.nc','All netcdf files'},...
                       'Select the BLK or FRC file (wind or wind stress)');
    if isequal(fn,0), return, end
    S=wind_source(fullfile(pth,fn),0);
  end
  if isempty(S)
    set_status3(f3,'No wind/stress variables (u10/v10, uwnd/vwnd, Uwind/Vwind, taux/tauy, sustr/svstr) in the file');
    return
  end
  if S.nx~=T.Lp || S.ny~=T.Mp
    set_status3(f3,sprintf('%s: grid size %dx%d differs from the model grid %dx%d',...
                short_name(S.file),S.nx,S.ny,T.Lp,T.Mp));
    return
  end
  L.type='w'; L.src=S; L.var=S.labels{1};
  L.src.wmode=1;
  L.pos=round_sig(max(1.3*T.ztop,0.08*max(T.h(:))),2);
  [ue,vn]=get_wind(T,L);                         % default scale: largest
  mag=sqrt(ue.^2+vn.^2);                         % arrow = SKIP cells
  L.vscale=round_sig(L.vskip/max(max(mag(:)),eps),2);
  type='w';
end
switch type
  case 'h'
    L.pos=0;
  case 'vj'
    L.pos=T.jj(round(end/2))-1;
  case 'vi'
    L.pos=T.ii(round(end/2))-1;
  case 'iso'
    [V,T]=get_var(T,var);
    L.pos=round_sig(median(V(isfinite(V))),3);
    L.alpha=0.8;
end
T.layers(end+1)=L;
T.sel=numel(T.layers);
set_status3(f3,'Computing the layer...'); drawnow;
T=render_layer(T,T.sel);
guidata(f3,T);
update_panel(f3); update_title(f3);
set_status3(f3,'');
return
%
function v=round_sig(v,n)
if v==0 || ~isfinite(v), return, end
p=10^(n-1-floor(log10(abs(v))));
v=round(v*p)/p;
return
%
function T=render_all(T)
for k=1:numel(T.layers)
  T=render_layer(T,k);
end
return
%
function T=render_layer(T,k)
%
% (Re)draw layer k at the current time
%
L=T.layers(k);
for h=L.hg(:)'
  if ishghandle(h), delete(h); end
end
L.hg=[];
ax=T.ax;
if strcmp(L.type,'w')
  [ue,vn,L.src]=get_wind(T,L);
  mag=sqrt(ue.^2+vn.^2);
  [T,L]=sync_range(T,L,mag);
  cm=get_cmap(T,L.cmap,128); cr=[L.cmin L.cmax];
  hold(ax,'on');
  L.hg=draw_wind(T,ax,ue,vn,L,cm,cr);
  hold(ax,'off');
  if ~L.visible, set(L.hg,'Visible','off'); end
  T.layers(k)=L;
  e0=T.exagval; T=apply_zlim(T); T=redraw_secvec(T,e0);
  return
end
if T.nt==0, T.layers(k)=L; return, end
[V,T]=get_var(T,L.var);
[Z,T]=get_var(T,'z_r');
[T,L]=sync_range(T,L,V);                       % range of the whole 3D field,
cm=get_cmap(T,L.cmap,128); cr=[L.cmin L.cmax];   % shared by the layers of L.var
hold(ax,'on');
switch L.type
  case 'h'
    d=min(L.pos,0);                            % depth: <=0 (checked in cb_prop)
    C=hslice(Z,V,d);
    Zs=d*ones(size(C)); Zs(~isfinite(C))=NaN;
    L.hg=surface(T.lon,T.lat,Zs,val2rgb(C,cm,cr),'Parent',ax,'EdgeColor','none',...
                 'FaceColor','interp','FaceAlpha',L.alpha,'FaceLighting','none');
    if L.vec
      [u,T]=get_var(T,'u'); [v,T]=get_var(T,'v');
      us=hslice(Z,u,d); vs=hslice(Z,v,d);
      a=T.angle;
      ue=us.*cos(a)-vs.*sin(a); vn=us.*sin(a)+vs.*cos(a);
      sk=max(1,round(L.vskip));
      ii=1:sk:size(C,1); jj=1:sk:size(C,2);
      x=T.lon(ii,jj); y=T.lat(ii,jj); ue=ue(ii,jj); vn=vn(ii,jj);
      sp=sqrt(ue.^2+vn.^2); smax=max(sp(:));
      if smax>0
        dl=median(abs(diff(T.lat(1,:))));
        if ~(dl>0), dl=median(abs(diff(T.lat(:,1)))); end
        f=L.vscale*sk*dl/smax;
        ok=isfinite(ue) & isfinite(vn);
        hq=quiver3(ax,x(ok),y(ok),(d+1e-3*abs(d)+0.01)*ones(sum(ok(:)),1),...
                   f*ue(ok)/T.coslat,f*vn(ok),zeros(sum(ok(:)),1),0,'k');
        set(hq,'LineWidth',1);
        L.hg=[L.hg hq];                          % concatenation: mixed graphics types
      end
    end
  case {'vj','vi'}
    if L.pmode                                 % constant latitude/longitude
      [x,y,z,v,h,m]=geo_section(T,Z,V,L.type,L.pos);
      if numel(x)<2
        hold(ax,'off'); T.layers(k)=L; return
      end
    elseif strcmp(L.type,'vj')
      [~,c]=min(abs(T.jj-1-L.pos)); L.pos=T.jj(c)-1;
      x=T.lon(:,c); y=T.lat(:,c); z=squeeze(Z(:,c,:)); v=squeeze(V(:,c,:)); h=T.h(:,c); m=T.mask(:,c);
    else
      [~,c]=min(abs(T.ii-1-L.pos)); L.pos=T.ii(c)-1;
      x=T.lon(c,:)'; y=T.lat(c,:)'; z=squeeze(Z(c,:,:)); v=squeeze(V(c,:,:)); h=T.h(c,:)'; m=T.mask(c,:)';
    end
    z=[-h z max(z(:,end),0)];                  % bottom ... surface
    v=[v(:,1) v v(:,end)];
    n=size(z,2);
    z(m==0,:)=NaN;
    L.hg=surface(repmat(x,1,n),repmat(y,1,n),z,val2rgb(v,cm,cr),'Parent',ax,...
                 'EdgeColor','none','FaceColor','interp','FaceAlpha',L.alpha,'FaceLighting','none');
    if L.vec && any(strcmp(T.vars,'u')) && any(strcmp(T.vars,'v'))
      if L.pmode, c=[]; end
      [hv,T]=section_vectors(T,ax,L,Z,c);
      L.hg=[L.hg(:); hv(:)]';
    end
  case 'iso'
    L.hg=draw_iso(T,ax,Z,V,L.pos,cm,cr,L.alpha);
end
hold(ax,'off');
if ~L.visible
  set(L.hg,'Visible','off');
end
T.layers(k)=L;
e0=T.exagval; T=apply_zlim(T); T=redraw_secvec(T,e0);
return
%
function [T,L]=sync_range(T,L,C)
%
% Colour range and colormap of the variable L.var, the same for all the
% layers of that variable (T.vr). Not defined yet: range of C (the whole
% 3D field of the variable in the domain at the current time, or the
% wind magnitude), symmetric around 0 for signed variables, and the
% default cmocean colormap of the variable (cmocean_var).
%
k=find(strcmp({T.vr.var},L.var),1);
if isempty(k) || ~isfinite(T.vr(k).cmin) || ~isfinite(T.vr(k).cmax)
  [nm,div]=cmocean_var(L.var);
  c=C(isfinite(C));
  if isempty(c), c=[0 1]; end
  if div
    a=round_out(max(abs(c)),2,1); if a==0, a=1; end
    r=[-a a];
  else
    r=[round_out(min(c),3,-1) round_out(max(c),3,1)];   % range contains the data
    if r(2)<=r(1), r(2)=r(1)+1; end
  end
  if isempty(k)
    k=numel(T.vr)+1;
    cmap=find(strcmp(T.cmaps,nm),1); if isempty(cmap), cmap=1; end
  else
    cmap=T.vr(k).cmap;
  end
  T.vr(k)=struct('var',L.var,'cmin',r(1),'cmax',r(2),'cmap',cmap);
end
L.cmin=T.vr(k).cmin; L.cmax=T.vr(k).cmax; L.cmap=T.vr(k).cmap;
return
%
function v=round_out(v,n,d)
%
% v rounded to n significant digits, down (d<0) or up (d>0)
%
if v==0 || ~isfinite(v), return, end
p=10^(n-1-floor(log10(abs(v))));
if d<0, v=floor(v*p)/p; else, v=ceil(v*p)/p; end
return
%
function cm=get_cmap(T,k,n)
name=T.cmaps{min(max(k,1),numel(T.cmaps))};
if cmocean_map('-isname',name)
  cm=cmocean_map(name,n);
else
  cm=feval(name,n);
end
return
%
function [hv,T]=section_vectors(T,ax,L,Z,c)
%
% Velocity vectors in the plane of a vertical section: along-section
% velocity + w. W-E section: u (grid xi component; at a constant
% latitude: eastward velocity) + w; S-N section: v (eta component; at a
% constant longitude: northward velocity) + w. The arrows are drawn in
% the coordinates of the view (horizontal displacement in lon/lat, w
% displacement in m), so that they follow the flow with the vertical
% exaggeration of the view; w is multiplied by L.wfac. Scale 1: the
% largest vector, as displayed (vertical exaggeration included) = 0.8
% SKIP cells (arrows do not touch). One arrow every SKIP points along the
% section, at fixed depths z (m) given by the user (L.vdep, "Vec. z (m)"),
% or by default regular depths 0, -dz, -2dz ... (dz: 1, 2 or 5 x 10^n,
% about 10 levels down to the deepest point of the section). Velocities
% interpolated in z between the rho levels; between the upper rho level
% and the surface (resp. the lower level and the bottom) the value of
% that level; no arrow under the bottom. Redrawn when the vertical
% exaggeration changes.
%
hv=[];
[u,T]=get_var(T,'u'); [v,T]=get_var(T,'v');
if any(strcmp(T.vars,'w'))
  [w,T]=get_var(T,'w');
elseif any(strcmp(T.vars,'omega'))
  [w,T]=get_var(T,'omega');
else
  w=zeros(size(u));
end
iswe=strcmp(L.type,'vj');
if L.pmode                                    % constant lat/lon: east/north
  a=repmat(T.angle,[1 1 size(u,3)]);
  if iswe, uh=u.*cos(a)-v.*sin(a); else, uh=u.*sin(a)+v.*cos(a); end
  [x,y,z,uh,hb]=geo_section(T,Z,uh,L.type,L.pos);
  [~,~,~,ws]=geo_section(T,Z,w,L.type,L.pos);
elseif iswe                                   % grid line: u (xi direction)
  x=T.lon(:,c); y=T.lat(:,c); z=squeeze(Z(:,c,:)); uh=squeeze(u(:,c,:)); ws=squeeze(w(:,c,:)); hb=T.h(:,c);
else                                          % grid line: v (eta direction)
  x=T.lon(c,:)'; y=T.lat(c,:)'; z=squeeze(Z(c,:,:)); uh=squeeze(v(c,:,:)); ws=squeeze(w(c,:,:)); hb=T.h(c,:)';
end
n=numel(x);
if n<2, return, end
R=6367442.76; d2r=pi/180;
dxm=gradient(x(:)).*R*d2r.*cos(y(:)*d2r); dym=gradient(y(:))*R*d2r;   % tangent (m)
ds=hypot(dxm,dym); ds(ds==0)=NaN;
tx=dxm./ds; ty=dym./ds;
dsm=median(ds(isfinite(ds)));
if L.pmode                                    % exact east / north directions
  if iswe, tx(:)=1; ty(:)=0; else, tx(:)=0; ty(:)=1; end
end
sk=max(1,round(L.vskip));
N=size(z,2);
ii=(1:sk:n)';
zv=L.vdep(:)';                                % arrows at fixed depths z (m)
if isempty(zv), zv=auto_zlevels(max(hb(:))); end
nk=numel(zv); U=NaN(numel(ii),nk); W=U; ZZ=U;
for q=1:numel(ii)
  zc=z(ii(q),:); uc=uh(ii(q),:); wc=ws(ii(q),:);
  g=isfinite(zc) & isfinite(uc) & isfinite(wc);
  if sum(g)<2, continue, end
  zc=zc(g); uc=uc(g); wc=wc(g);
  [zc,o]=sort(zc); uc=uc(o); wc=wc(o);
  in=zv>=-hb(ii(q)) & zv<=max(0,zc(end));    % between the bottom and the surface
  zt=min(max(zv(in),zc(1)),zc(end));          % above the upper / below the lower
  ZZ(q,in)=zv(in);                            % rho level: value of that level
  U(q,in)=interp1(zc,uc,zt);
  W(q,in)=L.wfac*interp1(zc,wc,zt);
end
E=1; if isfield(T,'exagval') && T.exagval>0, E=T.exagval; end
sp=sqrt(U.^2+(E*W).^2); smax=max(sp(isfinite(sp)));   % displayed lengths
if isempty(smax) || ~(smax>0), return, end
dt=0.8*L.vscale*sk*dsm/smax;                  % s: largest arrow = 0.8 SKIP cells
dX=dt*U; dZ=dt*W;                             % m
X=repmat(x(ii),1,nk); Y=repmat(y(ii),1,nk);
TX=repmat(tx(ii),1,nk); TY=repmat(ty(ii),1,nk);
dlon=dX.*TX./(R*d2r*cos(Y*d2r)); dlat=dX.*TY/(R*d2r);
ok=isfinite(X) & isfinite(ZZ) & isfinite(dlon) & isfinite(dlat) & isfinite(dZ);
if ~any(ok(:)), return, end
off=0.004*max(max(T.lon(:))-min(T.lon(:)),max(T.lat(:))-min(T.lat(:)));
%
% Arrows as lines (shaft + head) built in the plane of the section with
% the displayed proportions (vertical x E), so that the heads are not
% distorted by the different units of the horizontal and vertical axes
%
a=dX(ok); b=E*dZ(ok);                          % displayed components (m)
la=hypot(a,b); ca=a./max(la,eps); sa=b./max(la,eps);
hl=0.3*la; th=25*pi/180;
s1=a-hl.*(ca*cos(th)-sa*sin(th)); v1=b-hl.*(sa*cos(th)+ca*sin(th));   % head barbs
s2=a-hl.*(ca*cos(th)+sa*sin(th)); v2=b-hl.*(sa*cos(th)-ca*sin(th));
m2lon=TX(ok)./(R*d2r*cos(Y(ok)*d2r)); m2lat=TY(ok)/(R*d2r);           % m along -> deg
x0=X(ok); y0=Y(ok); z0=ZZ(ok); q=numel(x0); nn=NaN(q,1);
S=[zeros(q,1) a nn s1 a s2 nn]; Vd=[zeros(q,1) b nn v1 b v2 nn];      % (shaft) NaN (head)
XL=x0+S.*m2lon; YL=y0+S.*m2lat; ZL=z0+Vd/E;
XL=XL'; YL=YL'; ZL=ZL';
for sgn=[1 -1]                                 % both sides of the section
  oxs=sgn*(-TY(ok)'*off); oys=sgn*(TX(ok)'*off);
  xs=XL+oxs; ys=YL+oys;
  hv(end+1)=line('XData',xs(:)','YData',ys(:)','ZData',ZL(:)','Parent',ax,'Color','k','LineWidth',1);
end
setappdata(hv(1),'arrows',[x0 y0 z0 dlon(ok) dlat(ok) dZ(ok)]);   % origins and displacements
return
%
function zv=auto_zlevels(hmax)
% regular depths 0, -dz, -2dz ... above hmax (dz: 1, 2 or 5 x 10^n, ~10 levels)
if ~(hmax>0), zv=0; return, end
p=10^floor(log10(hmax/10)); c=[1 2 5 10]*p;
dz=c(find(c>=0.99*hmax/10,1));
zv=-(0:dz:hmax); zv(zv==0)=0;
return
%
function [x,y,z,v,h,m]=geo_section(T,Z,V,type,val)
%
% Vertical section at a constant latitude (type 'vj', W-E) or longitude
% ('vi', S-N): for each I (resp. J) the fields are interpolated linearly
% in J (resp. I) at the given latitude (longitude). Rows that do not
% cross the latitude (longitude) are removed.
%
lon=T.lon; lat=T.lat; hh=T.h; mk=T.mask;
if strcmp(type,'vj')
  A=lat;
else                                      % constant longitude: swap I,J
  A=lon'; lon=lon'; lat=lat'; hh=hh'; mk=mk';
  Z=permute(Z,[2 1 3]); V=permute(V,[2 1 3]);
end
[ni,nj,N]=size(Z);
x=NaN(ni,1); y=x; h=x; m=zeros(ni,1); z=NaN(ni,N); v=z;
for i=1:ni
  a=A(i,:);
  kk=find((a(1:end-1)-val).*(a(2:end)-val)<=0 & a(1:end-1)~=a(2:end),1);
  if isempty(kk), continue, end
  w=(val-a(kk))/(a(kk+1)-a(kk));
  x(i)=(1-w)*lon(i,kk)+w*lon(i,kk+1);
  y(i)=(1-w)*lat(i,kk)+w*lat(i,kk+1);
  h(i)=(1-w)*hh(i,kk)+w*hh(i,kk+1);
  kn=kk+(w>=0.5);
  m(i)=mk(i,kn);
  z(i,:)=(1-w)*squeeze(Z(i,kk,:))+w*squeeze(Z(i,kk+1,:));
  v1=squeeze(V(i,kk,:)); v2=squeeze(V(i,kk+1,:));
  vi=(1-w)*v1+w*v2;
  vn=squeeze(V(i,kn,:));
  vi(~isfinite(vi))=vn(~isfinite(vi));      % near the coast: nearest value
  v(i,:)=vi;
end
ok=isfinite(x);
x=x(ok); y=y(ok); h=h(ok); m=m(ok); z=z(ok,:); v=v(ok,:);
return
%
function hp=draw_iso(T,ax,Z,V,iso,cm,cr,alpha)
%
% Isosurface V=iso: V interpolated on regular z levels, isosurface in
% (i,j,z) space, vertices mapped to lon/lat, faces under the bottom or
% on land removed
%
hp=[];
[nI,nJ,~]=size(V);
nz=40;
zr=linspace(-max(T.h(:)),0,nz);
R=NaN(nI,nJ,nz);
bot=V(:,:,1);
for k=1:nz
  s=hslice(Z,V,zr(k));
  u=isnan(s) & T.mask>0;                       % under the bottom: bottom value
  s(u)=bot(u);
  R(:,:,k)=s;
end
v=V(isfinite(V));
if isempty(v) || iso<min(v) || iso>max(v), return, end
R(isnan(R))=ifelse(iso>median(v),min(v)-1,max(v)+1);   % land: outside the iso
[I,J,K]=ndgrid(1:nI,1:nJ,zr);
[F,P]=isosurface(permute(I,[2 1 3]),permute(J,[2 1 3]),permute(K,[2 1 3]),permute(R,[2 1 3]),iso);
if isempty(F), return, end
hv=interp2(T.h.',P(:,1),P(:,2));
mk=interp2(T.mask.',P(:,1),P(:,2),'nearest');
bad=P(:,3)<-hv-1 | mk==0;
F=F(~any(bad(F),2),:);
if isempty(F), return, end
lon=interp2(T.lon.',P(:,1),P(:,2)); lat=interp2(T.lat.',P(:,1),P(:,2));
col=squeeze(val2rgb(iso,cm,cr))';
hp=patch('Parent',ax,'Faces',F,'Vertices',[lon lat P(:,3)],'FaceColor',col,...
         'EdgeColor','none','FaceAlpha',alpha);
try
  set(hp,'FaceLighting','gouraud','AmbientStrength',0.5);
end
return
%
%---------------------------------------------------------------------
% Layers panel
%---------------------------------------------------------------------
%
function update_panel(f3)
T=guidata(f3);
n=numel(T.layers);
names=cell(1,n);
for k=1:n, names{k}=layer_name(T,T.layers(k)); end
set(T.hlist,'String',names);
h=[T.hvis T.hremove T.hvar T.hpos T.hposmode T.hcmin T.hcmax T.hauto T.hcmap T.halpha T.hvec T.hvskip T.hvscale];
set(T.hvscale,'TooltipString','1: the largest vector = SKIP cells');
if T.sel<1 || T.sel>n
  set(T.hwmode,'Visible','off'); set(T.hvec,'Visible','on'); set([T.hwfaclab T.hwfac T.hvdlab T.hvdep],'Visible','off');
  set(T.hposmode,'Visible','off'); set(T.hposlab,'Visible','on');
  set(T.hlist,'Value',[]);
  set(h,'Enable','off');
  set(T.hposlab,'String','Position'); set(T.hposinfo,'String','');
  draw_cbar(f3);
  return
end
set(h,'Enable','on');
L=T.layers(T.sel);
set(T.hlist,'Value',T.sel);
set(T.hvis,'Value',L.visible);
if strcmp(L.type,'w')
  set(T.hvar,'String',L.src.labels,'Value',first1(find(strcmp(L.src.labels,L.var),1)));
else
  set(T.hvar,'String',ifelse(isempty(T.vars),{'-'},T.vars),'Value',first1(find(strcmp(T.vars,L.var),1)));
end
set(T.hpos,'String',num2str(L.pos));
isv=any(strcmp(L.type,{'vj','vi'}));
set(T.hposmode,'Visible',ifelse(isv,'on','off')); set(T.hposlab,'Visible',ifelse(isv,'off','on'));
if isv
  set(T.hposmode,'String',ifelse(strcmp(L.type,'vj'),{'J index','Latitude'},{'I index','Longitude'}),...
      'Value',L.pmode+1);
end
switch L.type
  case 'h'
    set(T.hposlab,'String','Depth (m)');
    set(T.hposinfo,'String','z (m) <= 0: 0 surface, negative below');
  case 'vj'
    set(T.hposlab,'String','J index');
    if L.pmode
      set(T.hposinfo,'String',sprintf('domain lat %.2f..%.2f',min(T.lat(:)),max(T.lat(:))));
    else
      [~,c]=min(abs(T.jj-1-L.pos));
      set(T.hposinfo,'String',sprintf('lat %.3f (J %d..%d)',mean(T.lat(:,c)),T.jj(1)-1,T.jj(end)-1));
    end
  case 'vi'
    set(T.hposlab,'String','I index');
    if L.pmode
      set(T.hposinfo,'String',sprintf('domain lon %.2f..%.2f',min(T.lon(:)),max(T.lon(:))));
    else
      [~,c]=min(abs(T.ii-1-L.pos));
      set(T.hposinfo,'String',sprintf('lon %.3f (I %d..%d)',mean(T.lon(c,:)),T.ii(1)-1,T.ii(end)-1));
    end
  case 'iso'
    set(T.hposlab,'String','Iso value');
    set(T.hposinfo,'String','');
  case 'w'
    set(T.hposlab,'String','Height (m)');
    if wind_mode(L)==2
      set(T.hposinfo,'String',L.src.info);
    else
      set(T.hposinfo,'String',sprintf('%s; %g cells per %s',L.src.info,L.vscale,wind_units(L)));
    end
end
set(T.hcmin,'String',num2str(L.cmin)); set(T.hcmax,'String',num2str(L.cmax));
set(T.hcmap,'Value',L.cmap);
set(T.halpha,'String',num2str(L.alpha));
set(T.hvec,'Value',L.vec); set(T.hvskip,'String',num2str(L.vskip)); set(T.hvscale,'String',num2str(L.vscale));
set(T.hvec,'Visible',ifelse(strcmp(L.type,'w'),'off','on'));
isv=any(strcmp(L.type,{'vj','vi'}));
pv=get(T.hvec,'Position'); pv(3)=ifelse(isv,.13,.19); set(T.hvec,'Position',pv);
set([T.hwfaclab T.hwfac T.hvdlab T.hvdep],'Visible',ifelse(isv,'on','off'));
set(T.hwfac,'String',num2str(L.wfac),'Enable','on');
set(T.hvdep,'String',ifelse(isempty(L.vdep),'auto',strtrim(sprintf('%g ',L.vdep))),'Enable','on');
switch L.type
  case 'vj', set(T.hvec,'String','Vectors (u,w)','TooltipString','Velocity vectors u+w in the plane of the W-E section');
  case 'vi', set(T.hvec,'String','Vectors (v,w)','TooltipString','Velocity vectors v+w in the plane of the S-N section');
  otherwise, set(T.hvec,'String','Velocity vectors (u,v)','TooltipString','Horizontal velocity vectors');
end
set(T.hwmode,'Visible',ifelse(strcmp(L.type,'w'),'on','off'));
if strcmp(L.type,'w')
  set(T.hwmode,'Value',wind_mode(L));
  set(T.hvscale,'TooltipString','Arrow length in grid cells per unit of the variable (m/s or N/m2)');
  if wind_mode(L)==2, set(T.hvscale,'Enable','off'); end
  if wind_mode(L)>=3, set([T.hcmin T.hcmax T.hauto T.hcmap],'Enable','off'); end
elseif ~any(strcmp(L.type,{'h','vj','vi'})) || ~any(strcmp(T.vars,'u')) || ~any(strcmp(T.vars,'v'))
  set([T.hvec T.hvskip T.hvscale T.hwfac T.hvdep],'Enable','off');
elseif ~L.vec
  set([T.hwfac T.hvdep],'Enable','off');
end
draw_cbar(f3);
return
%
function draw_cbar(f3)
T=guidata(f3);
if ~isempty(T.hcbar) && all(ishghandle(T.hcbar)), delete(T.hcbar); end
T.hcbar=[];
if T.sel<1 || T.sel>numel(T.layers)
  set(T.cax,'Visible','off'); title(T.cax,'');
  guidata(f3,T); return
end
L=T.layers(T.sel);
if strcmp(L.type,'w') && wind_mode(L)>=3        % magnitude shown by the length
  set(T.cax,'Visible','off'); title(T.cax,'');
  guidata(f3,T); return
end
cm=get_cmap(T,L.cmap,128);
hold(T.cax,'on');
T.hcbar=image([0 1],[L.cmin L.cmax],reshape(cm,[size(cm,1) 1 3]),'Parent',T.cax);
if strcmp(L.type,'iso')
  T.hcbar=[T.hcbar plot(T.cax,[0 1],[1 1]*L.pos,'w-','LineWidth',3) ...
           plot(T.cax,[0 1],[1 1]*L.pos,'k-','LineWidth',1)];
end
hold(T.cax,'off');
set(T.cax,'Visible','on','YDir','normal','XTick',[],'YAxisLocation','right','XLim',[0 1],...
          'YLim',[L.cmin L.cmax],'Box','on');
if strcmp(L.type,'w')
  title(T.cax,{L.var,L.src.units{find(strcmp(L.src.labels,L.var),1)}},'Interpreter','none');
else
  title(T.cax,L.var,'Interpreter','none');
end
guidata(f3,T);
return
%
function cb_select(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
v=get(src,'Value');
if isempty(T.layers) || isempty(v), return, end
T.sel=v(1);
guidata(f3,T); update_panel(f3);
return
%
function cb_prop(src,~)
%
% A property of the selected layer was changed: redraw the layer. The
% colour range and the colormap belong to the variable: a change is
% applied to all the layers of that variable.
%
f3=ancestor(src,'figure'); T=guidata(f3);
if T.sel<1, return, end
L=T.layers(T.sel);
num=@(h,def) ifelse(isfinite(str2double(get(h,'String'))),str2double(get(h,'String')),def);
oldvar=L.var; old=[L.cmin L.cmax L.cmap];
L.visible=get(T.hvis,'Value');
if strcmp(L.type,'w')
  L.var=L.src.labels{min(get(T.hvar,'Value'),numel(L.src.labels))};
  L.src.wmode=get(T.hwmode,'Value');
elseif ~isempty(T.vars)
  L.var=T.vars{get(T.hvar,'Value')};
end
msg='';
pos=num(T.hpos,L.pos);
switch L.type
  case 'h'                                     % depth: z <= 0
    if pos>0
      msg=sprintf('Depth %g m rejected: horizontal sections need z <= 0 (e.g. -%g)',pos,pos);
      pos=L.pos;
    end
  case {'vj','vi'}
    pm=get(T.hposmode,'Value')-1;
    if strcmp(L.type,'vj'), A=T.lat; idx=T.jj; dim=1; else, A=T.lon; idx=T.ii; dim=2; end
    if pm~=L.pmode                             % index <-> lon/lat
      if pm                                    % index -> lat (lon) of the line
        [~,c]=min(abs(idx-1-L.pos));
        if dim==1, pos=round_sig(mean(A(:,c)),5); else, pos=round_sig(mean(A(c,:)),5); end
      else                                     % lat (lon) -> nearest index
        if dim==1, a=mean(A,1); else, a=mean(A,2)'; end
        [~,c]=min(abs(a-L.pos)); pos=idx(c)-1;
      end
      L.pmode=pm;
    elseif pm && (pos<min(A(:)) || pos>max(A(:)))
      msg=sprintf('%s %g outside the domain (%.3f..%.3f)',ifelse(dim==1,'Latitude','Longitude'),...
                  pos,min(A(:)),max(A(:)));
      pos=L.pos;
    end
end
L.pos=pos;
if ~strcmp(oldvar,L.var)
  L.cmin=NaN; L.cmax=NaN;                       % new variable: its own range
  if strcmp(L.type,'iso')
    T.layers(T.sel)=L;
    [V,T]=get_var(T,L.var);
    L.pos=round_sig(median(V(isfinite(V))),3);
  end
  changed=false;
else
  L.cmin=num(T.hcmin,L.cmin); L.cmax=num(T.hcmax,L.cmax);
  if L.cmax<=L.cmin, L.cmin=old(1); L.cmax=old(2); msg='The colour maximum must be larger than the minimum'; end
  L.cmap=get(T.hcmap,'Value');
  changed=~isequal(old,[L.cmin L.cmax L.cmap]);
  if changed                                   % range of the variable
    k=find(strcmp({T.vr.var},L.var),1);
    if isempty(k), k=numel(T.vr)+1; end
    T.vr(k)=struct('var',L.var,'cmin',L.cmin,'cmax',L.cmax,'cmap',L.cmap);
  end
end
L.alpha=min(max(num(T.halpha,L.alpha),0),1);
L.vec=get(T.hvec,'Value');
L.vskip=max(1,round(num(T.hvskip,L.vskip)));
L.vscale=num(T.hvscale,L.vscale);
L.wfac=num(T.hwfac,L.wfac);
if any(strcmp(L.type,{'vj','vi'}))             % depths of the section vectors
  str=strtrim(strrep(get(T.hvdep,'String'),',',' '));
  if isempty(str) || strcmpi(str,'auto')
    L.vdep=[];
  else
    zv=sscanf(str,'%f')';
    if isempty(zv)
      msg='Vector depths: numbers (m, <= 0) or auto';
    elseif any(zv>0)
      msg=sprintf('Vector depths rejected: z must be <= 0 (e.g. -%g)',max(zv));
    else
      L.vdep=sort(unique(zv),'descend');     % from the surface down
    end
  end
end
T.layers(T.sel)=L;
set_status3(f3,'Computing the layer...'); drawnow;
T=render_layer(T,T.sel);
if changed, T=render_var(T,L.var,T.sel); end
guidata(f3,T); update_panel(f3); update_title(f3);
set_status3(f3,msg);
return
%
function T=render_var(T,var,skip)
%
% Redraw the layers of the variable VAR (except layer SKIP)
%
for k=1:numel(T.layers)
  if k~=skip && strcmp(T.layers(k).var,var)
    T=render_layer(T,k);
  end
end
return
%
function cb_auto(src,~)
%
% Automatic colour range of the variable of the selected layer: range of
% its whole 3D field at the current time (wind: magnitude), for all the
% layers of that variable
%
f3=ancestor(src,'figure'); T=guidata(f3);
if T.sel<1, return, end
var=T.layers(T.sel).var;
k=find(strcmp({T.vr.var},var),1);
if ~isempty(k), T.vr(k).cmin=NaN; T.vr(k).cmax=NaN; end
T=render_layer(T,T.sel);
T=render_var(T,var,T.sel);
guidata(f3,T); update_panel(f3);
return
%
function cb_remove(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
if T.sel<1, return, end
for h=T.layers(T.sel).hg(:)'
  if ishghandle(h), delete(h); end
end
T.layers(T.sel)=[];
T.sel=min(T.sel,numel(T.layers));
e0=T.exagval; T=apply_zlim(T); T=redraw_secvec(T,e0);
guidata(f3,T); update_panel(f3); update_title(f3);
return
%
%---------------------------------------------------------------------
% Time, animation
%---------------------------------------------------------------------
%
function set_time(f3,t)
T=guidata(f3);
if T.nt==0, return, end
t=min(max(round(t),1),T.nt);
T.tindex=t;
T.cache=T.cache([]);
T=render_all(T);
guidata(f3,T);
update_time_label(f3);
update_panel(f3);
return
%
function cb_step(src,~,d)
f3=ancestor(src,'figure'); T=guidata(f3);
set_time(f3,T.tindex+d);
return
%
function cb_time(src,~)
f3=ancestor(src,'figure');
t=str2double(get(src,'String'));
T=guidata(f3);
if ~isfinite(t), t=T.tindex; end
set_time(f3,t);
return
%
function cb_animate(src,~)
f3=ancestor(src,'figure'); T=guidata(f3);
if strcmp(get(T.hanim,'String'),'Stop')
  setappdata(f3,'stop',1); return
end
t1=round(str2double(get(T.hafrom,'String'))); t2=round(str2double(get(T.hato,'String')));
if ~isfinite(t1), t1=1; end
if ~isfinite(t2), t2=T.nt; end
t1=min(max(t1,1),T.nt); t2=min(max(t2,1),T.nt);
step=ifelse(t2>=t1,1,-1);
rec=get(T.hrec,'Value');
fps=str2double(get(T.hfps,'String')); if ~(fps>0), fps=4; end
mp4=strtrim(get(T.hmp4,'String'));
if rec
  if isempty(mp4), mp4='make_3d.mp4'; end
  [p,n]=fileparts(mp4); if isempty(p), p=pwd; end
  fdir=fullfile(p,[n,'_frames']);
  if ~exist(fdir,'dir'), mkdir(fdir); end
  if ~isempty(dir(fullfile(fdir,'f_*.png'))), delete(fullfile(fdir,'f_*.png')); end
end
setappdata(f3,'stop',0);
set(T.hanim,'String','Stop');
nf=0; rect=[];
for t=t1:step:t2
  if ~ishghandle(f3) || getappdata(f3,'stop'), break, end
  set_time(f3,t);
  drawnow;
  if rec
    [img,rect]=capture_view(f3,rect);
    nf=nf+1;
    imwrite(img,fullfile(fdir,sprintf('f_%04d.png',nf)));
  else
    pause(1/fps);
  end
end
if ~ishghandle(f3), return, end
set(T.hanim,'String','Animate');
if rec && nf>0
  set_status3(f3,'Writing the MP4 file...'); drawnow;
  [ok,msg]=make_mp4(fdir,mp4,fps,nf);
  set_status3(f3,msg);
  disp(['make_3d: ',msg])
end
return
%
function [img,rect]=capture_view(f3,rect)
%
% Image of the 3D view and of the colour bar (same size for all frames)
%
T=guidata(f3);
fr=getframe(f3);
img=fr.cdata;
if isempty(rect)
  [H,W,~]=size(img);
  u=get(f3,'Units'); set(f3,'Units','pixels'); fp=get(f3,'Position'); set(f3,'Units',u);
  sx=W/fp(3); sy=H/fp(4);
  pa=getpixelposition(T.ax); pc=getpixelposition(T.cax);
  x1=max(1,floor(pa(1)*sx)); x2=min(W,ceil((pc(1)+pc(3))*sx)+60);
  y1=max(1,floor(H-(pa(2)+pa(4))*sy)-50); y2=min(H,ceil(H-pa(2)*sy)+5);
  rect=[x1 x2 y1 y2];
  rect(2)=rect(1)+2*floor((rect(2)-rect(1)+1)/2)-1;   % even sizes (H.264)
  rect(4)=rect(3)+2*floor((rect(4)-rect(3)+1)/2)-1;
end
img=img(rect(3):rect(4),rect(1):rect(2),:);
return
%
function [ok,msg]=make_mp4(fdir,mp4,fps,nf)
%
% MP4 from the PNG frames: VideoWriter 'MPEG-4' (Matlab, Windows/macOS),
% else ffmpeg; Matlab without both: Motion JPEG AVI (VideoWriter)
%
ok=0; msg='';
ismat=~exist('OCTAVE_VERSION','builtin');
if ismat
  try
    vw=VideoWriter(mp4,'MPEG-4'); vw.FrameRate=fps; open(vw);
    for k=1:nf, writeVideo(vw,imread(fullfile(fdir,sprintf('f_%04d.png',k)))); end
    close(vw);
    ok=exist(mp4,'file')>0;
  end
end
if ~ok
  [st,~]=system('ffmpeg -version');
  if st==0
    in=fullfile(fdir,'f_%04d.png');
    cmd={sprintf('ffmpeg -y -loglevel error -framerate %g -i "%s" -c:v libx264 -pix_fmt yuv420p "%s"',fps,in,mp4),...
         sprintf('ffmpeg -y -loglevel error -framerate %g -i "%s" -c:v mpeg4 -q:v 2 "%s"',fps,in,mp4)};
    for k=1:2
      [st,out]=system(cmd{k});
      if st==0 && exist(mp4,'file'), ok=1; break, end
    end
    if ~ok, msg=sprintf('ffmpeg error (%s)',strtrim(out)); end
  else
    msg='no MPEG-4 VideoWriter profile and ffmpeg not found';
  end
end
if ~ok && ismat                                % Motion JPEG AVI
  [p,nm]=fileparts(mp4); avi=fullfile(p,[nm,'.avi']);
  try
    vw=VideoWriter(avi,'Motion JPEG AVI'); vw.FrameRate=fps; open(vw);
    for k=1:nf, writeVideo(vw,imread(fullfile(fdir,sprintf('f_%04d.png',k)))); end
    close(vw);
    mp4=avi; ok=exist(avi,'file')>0;
  end
end
if ok
  delete(fullfile(fdir,'f_*.png'));
  try, rmdir(fdir); end
  msg=sprintf('%d frames written in %s',nf,mp4);
else
  msg=sprintf('%s: the %d PNG frames are in %s',msg,nf,fdir);
end
return
%
function cb_savepng(src,~)
f3=ancestor(src,'figure');
[fn,pth]=uiputfile('*.png','Save the 3D view as','make_3d.png');
if isequal(fn,0), return, end
img=capture_view(f3,[]);
imwrite(img,fullfile(pth,fn));
set_status3(f3,['Saved: ',fullfile(pth,fn)]);
return
%
function lev=parse_levels(h)
str=strrep(get(h,'String'),',',' ');
lev=unique(abs(sscanf(str,'%f')))';
set(h,'String',strtrim(sprintf('%g ',lev)));
return
%
function [X,Y,Z]=contour_lines(lon,lat,h,mask,lev,dz)
%
% Isobaths of h (sea cells) for the depths LEV, in lon/lat (NaN
% separated), Z=-depth+DZ. Level 0: limit of the land/sea mask (Z=0).
% Contours computed in grid index space (curvilinear grids).
%
[nI,nJ]=size(h);
hs=h; hs(mask==0)=NaN;
X=[]; Y=[]; Z=[];
for l=lev
  if l==0
    C=contourc(1:nI,1:nJ,double(mask).',[0.5 0.5]); zl=0;
  else
    C=contourc(1:nI,1:nJ,hs.',[l l]); zl=-l+dz;
  end
  k=1;
  while k<size(C,2)
    n=C(2,k);
    xi=C(1,k+1:k+n)'; yi=C(2,k+1:k+n)';
    X=[X; interp2(lon.',xi,yi); NaN];
    Y=[Y; interp2(lat.',xi,yi); NaN];
    Z=[Z; zl*ones(n,1); NaN];
    k=k+n+1;
  end
end
return
%
function cb_selcontours(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
lev=parse_levels(S.hclev);
X=NaN; Y=NaN;
if get(S.hcont,'Value') && ~isempty(lev)
  [X,Y]=contour_lines(S.lon,S.lat,S.h,S.mask,lev,0);
  if isempty(X), X=NaN; Y=NaN; end
end
set(S.hcontour,'XData',X,'YData',Y);
return
%
%---------------------------------------------------------------------
% Wind / wind stress above the sea surface
%---------------------------------------------------------------------
%
function S=wind_source(file,isout)
%
% Pairs of wind (u10/v10, uwnd/vwnd...) or wind stress (taux/tauy,
% sustr/svstr) variables of FILE, with their grid (r/u/v), units and time
% axis (days). isout: 1 for the his/avg file (record = model record).
%
S=[];
cands={{'u10','v10'},{'U10','V10'},{'uwnd','vwnd'},{'Uwind','Vwind'},{'wind_u','wind_v'},...
       {'taux','tauy'},{'sustr','svstr'},{'tx','ty'},{'TAUX','TAUY'}};
nc=netcdf.open(file,'NC_NOWRITE');
P={}; G={}; U={}; TV={}; TT={}; CY=[]; HT=[];
nx=NaN; ny=NaN;
for k=1:numel(cands)
  try
    vu=netcdf.inqVarID(nc,cands{k}{1}); vv=netcdf.inqVarID(nc,cands{k}{2});
  catch
    continue
  end
  [~,~,du]=netcdf.inqVar(nc,vu); [~,~,dv]=netcdf.inqVar(nc,vv);
  if numel(du)<2 || numel(du)>3 || numel(dv)~=numel(du), continue, end
  dn=@(d) netcdf.inqDim(nc,d);
  gu=grid_letter(dn(du(1)),dn(du(2))); gv=grid_letter(dn(dv(1)),dn(dv(2)));
  [~,n1]=netcdf.inqDim(nc,du(1)); [~,n2]=netcdf.inqDim(nc,du(2));
  if gu=='u', n1=n1+1; end
  if gu=='v', n2=n2+1; end
  nx=n1; ny=n2;
  units='';
  try, units=netcdf.getAtt(nc,vu,'units'); end
  tday=[]; cyc=0; ht=numel(du)==3;
  if ht && ~isout
    tname=dn(du(3));
    try
      vt=netcdf.inqVarID(nc,tname);
      tday=double(netcdf.getVar(nc,vt)); tday=tday(:);
      tu='days';
      try, tu=netcdf.getAtt(nc,vt,'units'); end
      if ~isempty(strfind(lower(tu),'sec')), tday=tday/86400; end
      if ~isempty(strfind(lower(tu),'hour')), tday=tday/24; end
      try, cyc=double(netcdf.getAtt(nc,vt,'cycle_length')); end
    end
  end
  P{end+1}=cands{k}; G{end+1}=[gu gv]; U{end+1}=units; TT{end+1}=tday; CY(end+1)=cyc; HT(end+1)=ht;
end
netcdf.close(nc);
if isempty(P), return, end
S.file=file; S.isout=isout; S.pairs=P; S.grid=G; S.units=U; S.time=TT; S.cycle=CY; S.hastime=HT;
S.labels=cellfun(@(p) [p{1},'/',p{2}],P,'UniformOutput',false);
S.nx=nx; S.ny=ny; S.info='';
return
%
function g=grid_letter(d1,d2)
g='r';
if strcmp(d1,'xi_u'), g='u'; elseif strcmp(d2,'eta_v'), g='v'; end
return
%
function [ue,vn,S]=get_wind(T,L)
%
% East/north components of the selected pair on the rho points of the
% block, at the record of the current time
%
S=L.src;
k=find(strcmp(S.labels,L.var),1); if isempty(k), k=1; end
rec=1; tday=NaN;
if S.isout
  rec=T.tindex; tday=T.time(T.tindex)/86400;
elseif S.hastime(k) && ~isempty(S.time{k})
  t=S.time{k};
  if T.nt>0, tm=T.time(T.tindex)/86400; else, tm=t(1); end
  d=abs(t-tm);
  if S.cycle(k)>0
    d=mod(t-tm,S.cycle(k)); d=min(d,S.cycle(k)-d);
  end
  [~,rec]=min(d); tday=t(rec);
end
u=read_2d(T,S.file,S.pairs{k}{1},S.grid{k}(1),rec,S.hastime(k));
v=read_2d(T,S.file,S.pairs{k}{2},S.grid{k}(2),rec,S.hastime(k));
a=T.angle;
ue=u.*cos(a)-v.*sin(a); vn=u.*sin(a)+v.*cos(a);
if isfinite(tday)
  S.info=sprintf('record %d (day %.2f) of %s',rec,tday,short_name(S.file));
else
  S.info=sprintf('record %d of %s',rec,short_name(S.file));
end
return
%
function X=read_2d(T,file,name,g,rec,hastime)
% 2D field (record rec) on the rho points of the block (nI,nJ)
nc=netcdf.open(file,'NC_NOWRITE');
vid=netcdf.inqVarID(nc,name);
switch g
  case 'u'
    a=max(T.i1-1,1); b=min(T.i2,T.Lp-1); st=[a-1 T.j1-1]; ct=[b-a+1 T.j2-T.j1+1];
  case 'v'
    a=max(T.j1-1,1); b=min(T.j2,T.Mp-1); st=[T.i1-1 a-1]; ct=[T.i2-T.i1+1 b-a+1];
  otherwise
    st=[T.i1-1 T.j1-1]; ct=[T.i2-T.i1+1 T.j2-T.j1+1];
end
if hastime, st(end+1)=rec-1; ct(end+1)=1; end
X=double(netcdf.getVar(nc,vid,st,ct));
fv=[]; sc=1; of=0;
try, fv=double(netcdf.getAtt(nc,vid,'_FillValue')); end
try, sc=double(netcdf.getAtt(nc,vid,'scale_factor')); end
try, of=double(netcdf.getAtt(nc,vid,'add_offset')); end
netcdf.close(nc);
if ~isempty(fv), X(X==fv)=NaN; end
X=X*sc+of; X(abs(X)>1e30)=NaN;
switch g
  case 'u'
    if T.i1==1, X=[X(1,:); X]; end
    if T.i2==T.Lp, X=[X; X(end,:)]; end
    X=0.5*(X(1:end-1,:)+X(2:end,:));
  case 'v'
    if T.j1==1, X=[X(:,1) X]; end
    if T.j2==T.Mp, X=[X X(:,end)]; end
    X=0.5*(X(:,1:end-1)+X(:,2:end));
end
X=X(T.ri,T.rj);
return
%
function hg=draw_wind(T,ax,ue,vn,L,cm,cr)
%
% Arrows on the plane z=L.pos (m above the sea surface). Display mode
% L.src.wmode:
%   1 colour + length : coloured by the magnitude, length = scale * value
%   2 colour only     : coloured by the magnitude, all arrows SKIP cells long
%   3/4 length only   : black / white arrows, length = scale * value
% scale (L.vscale) = arrow length in grid cells per unit of the variable
% (m/s or N/m2). A reference arrow with its value is drawn in the
% length modes. Outline of the plane in grey.
%
z=L.pos;
mode=wind_mode(L);
sk=max(1,round(L.vskip));
ii=1:sk:size(ue,1); jj=1:sk:size(ue,2);
x=T.lon(ii,jj); y=T.lat(ii,jj); u=ue(ii,jj); v=vn(ii,jj);
ok=isfinite(u) & isfinite(v) & (u~=0 | v~=0);
x=x(ok); y=y(ok); u=u(ok); v=v(ok);
mag=sqrt(u.^2+v.^2);
dl=cell_deg(T);
if mode==2
  f=0.9*sk*dl./max(mag,eps);                    % same length for all arrows
else
  f=L.vscale*dl;                                % degrees (lat) per unit
end
X=x*T.coslat;                                   % ~isotropic coordinates
[XX,YY]=arrow_lines(X,y,f.*u,f.*v);
hg=[];
% plane outline (boundary of the block)
bxo=[T.lon(:,1); T.lon(end,:)'; flipud(T.lon(:,end)); flipud(T.lon(1,:)')];
byo=[T.lat(:,1); T.lat(end,:)'; flipud(T.lat(:,end)); flipud(T.lat(1,:)')];
hg(end+1)=line(bxo,byo,z*ones(size(bxo)),'Parent',ax,'Color',[0.5 0.5 0.5],'LineStyle','--');
if mode>=3                                      % one colour
  col=ifelse(mode==3,[0 0 0],[1 1 1]);
  hg(end+1)=line(XX(:)/T.coslat,YY(:),z*ones(numel(XX),1),'Parent',ax,'Color',col,'LineWidth',1.5);
else                                            % colour classes
  nb=16;
  kb=min(max(floor((mag-cr(1))/max(cr(2)-cr(1),eps)*nb)+1,1),nb);
  for b=1:nb
    sel=find(kb==b);
    if isempty(sel), continue, end
    xs=XX(:,sel); ys=YY(:,sel);
    c=cm(max(1,round((b-0.5)/nb*size(cm,1))),:);
    hg(end+1)=line(xs(:)/T.coslat,ys(:),z*ones(numel(xs),1),'Parent',ax,'Color',c,'LineWidth',1.5);
  end
end
if mode~=2 && ~isempty(mag)                    % reference arrow
  ref=ref_value(max(mag));
  x0=min(T.lon(:))+0.03*(max(T.lon(:))-min(T.lon(:)));    % SW corner of the plane
  y0=min(T.lat(:))+0.04*(max(T.lat(:))-min(T.lat(:)));
  [RX,RY]=arrow_lines(x0*T.coslat,y0,L.vscale*dl*ref,0);
  col=ifelse(mode==4,[1 1 1],[0 0 0]);
  hg(end+1)=line(RX(:)/T.coslat,RY(:),z*ones(numel(RX),1),'Parent',ax,'Color',col,'LineWidth',2);
  ht=text(x0+(L.vscale*dl*ref)/T.coslat*1.1,y0,z,sprintf(' %g %s',ref,wind_units(L)),...
          'Parent',ax,'Color',col,'FontSize',10,'FontWeight','bold','Interpreter','none');
  hg=[hg ht];                                   % concatenation: lines + text
end
return
%
function [XX,YY]=arrow_lines(X,Y,dx,dy)
% shaft + head of the arrows (columns, NaN separated) in isotropic coordinates
X=X(:).'; Y=Y(:).'; dx=dx(:).'; dy=dy(:).';
len=sqrt(dx.^2+dy.^2);
X1=X+dx; Y1=Y+dy;
bx=-dx./max(len,eps); by=-dy./max(len,eps);
hl=0.3*len; a=25*pi/180;
H1x=X1+hl.*(bx*cos(a)-by*sin(a)); H1y=Y1+hl.*(bx*sin(a)+by*cos(a));
H2x=X1+hl.*(bx*cos(a)+by*sin(a)); H2y=Y1+hl.*(-bx*sin(a)+by*cos(a));
n=numel(X);
XX=[X; X1; NaN(1,n); H1x; X1; H2x; NaN(1,n)];
YY=[Y; Y1; NaN(1,n); H1y; Y1; H2y; NaN(1,n)];
return
%
function dl=cell_deg(T)
dl=median(abs(diff(T.lat(1,:))));
if ~(dl>0), dl=median(abs(diff(T.lat(:,1)))); end
if ~(dl>0), dl=0.1; end
return
%
function r=ref_value(m)
% round reference value (1, 2 or 5 x 10^n) not larger than m
if ~(m>0), r=1; return, end
p=10^floor(log10(m)); c=[1 2 5 10]*p;
r=c(find(c<=m,1,'last'));
return
%
function m=wind_mode(L)
m=1;
if isstruct(L.src) && isfield(L.src,'wmode'), m=L.src.wmode; end
return
%
function u=wind_units(L)
u='';
k=find(strcmp(L.src.labels,L.var),1);
if ~isempty(k), u=L.src.units{k}; end
return
%
%---------------------------------------------------------------------
% cmocean colormaps (cmocean v3.0.3, MIT License, Copyright (c) 2015
% Kristen M. Thyng; Thyng et al. 2016, Oceanography 29(3):9-13) and
% default colormap of a CROCO variable (as oct_cmocean / oct_cmocean_var)
%   cmocean_map()               names
%   cmocean_map('-isname',NAME) true if NAME is a cmocean map
%   cmocean_map(NAME,N)         N x 3 colormap ('-' or '_r': reversed)
%---------------------------------------------------------------------
%
function cm=cmocean_map(name,n)
names={'thermal','haline','solar','ice','gray','oxy','deep','dense','algae',...
       'matter','turbid','speed','amp','tempo','rain','phase','topo',...
       'balance','delta','curl','diff','tarn'};
if nargin==0, cm=names; return, end
if strcmp(name,'-isname')
  s=lower(n); s=regexprep(s,'^-',''); s=regexprep(s,'_r$','');
  cm=any(strcmp(names,s)); return
end
if nargin<2 || isempty(n), n=256; end
name=lower(name); rev=false;
if name(1)=='-', rev=true; name=name(2:end); end
if numel(name)>2 && strcmp(name(end-1:end),'_r'), rev=~rev; name=name(1:end-2); end
switch name
  case 'thermal'
    h=['04233305263b052943072b4b082e540b305d0e316713337219337c1f348727349130339939339e4234a049369f50399e' ...
       '583c9c5e3f9a6341986944966e4794744992794b917e4e9084508e89528d8f548c95568a9a5889a05a87a65c86ac5e83' ...
       'b46080ba627ec0647bc66677cc6873d16a6fd76c6bdc6f66e17262e6755deb7958ee7d53f2814ef5864af78b46f99143' ...
       'fa983ffb9e3efca43dfcaa3cfcb13cfbb73dfabe3ff9c441f8cb43f7d246f5d849f3df4cf1e650eeed53ebf457e8fa5b'];
  case 'haline'
    h=['2a186c2b19752d1a7f2e1c892e1d932d209c2a25a1252da32034a21b3aa016409d12459b0f4a980d4f960c53940d5792' ...
       '105c9013608e16638d19678c1d6b8b206e8b23718a26758a2978892c7c892f7f89318288348688368988388d883a9087' ...
       '3d95873f9986419c8543a08446a48348a7824bab814eae7f51b27d55b67b5ab9785ebd7563c07269c46f70c76c77ca68' ...
       '80ce6489d06192d35e9bd55ca5d75cafd95db8db60c1dd64cadf69d2e16fdae375e1e57ce9e783f0ea8af7ec92fdef9a'];
  case 'solar'
    h=['33141838151a3d171c42191d471a1f4c1c20511d22561f235b20236021246523246a24256f25257427247929247e2b23' ...
       '832d228830218c322090351e93381d973b1c9a3f1b9e421aa14619a44a18a74d17aa5116ad5515af5914b25d14b46113' ...
       'b76613ba6b13bc6f13be7313c07714c27c14c48015c68516c88917ca8e18cb921acd971bcf9b1dd0a01fd2a520d3a922' ...
       'd5af25d6b427d7b92ad9be2cdac32edbc831dccd33ddd236ddd738dedd3bdfe23ddfe740e0ed43e0f245e0f848e1fd4b'];
  case 'ice'
    h=['0406130709180b0d1e0f102413132a17172f1a1a351e1d3b21204125234728264e2b29542e2c5a312f6133326736356e' ...
       '3939763a3d7d3c40843d448a3e48903f4b963f509b3f54a03f58a43e5da83e61ab3e66ae3e6ab03f6fb34073b44178b6' ...
       '437db84581ba4786bb4a8abd4d8ebe5092c05397c1569bc35a9fc45ea3c661a8c765acc96ab0cb6eb4cc73b9ce78bdd0' ...
       '7fc2d285c6d38bcad592ced799d2d9a0d6dca8d9deafdde1b7e1e4bee5e7c6e8ebcdecefd5f0f2dcf4f6e3f9faeafdfd'];
  case 'gray'
    h=['0000000101010303030505050909090d0d0d1211111615151a19191d1d1d2121212525242928282c2c2c30302f343333' ...
       '3838373c3b3b3f3f3f4342424746464a4a494e4d4d5151505554545958585c5c5b605f5f6463636767666b6b6a6f6e6e' ...
       '7373727777767b7b7a7f7e7e8382828786868b8a8a8f8e8e9392929796969b9a9a9f9f9ea3a3a2a7a7a6acabaab0b0af' ...
       'b6b5b4babab9bebebdc3c3c2c8c7c6cccccbd1d1d0d6d6d4dbdad9e0dfdee5e4e3eaeae8efefedf4f4f3f9f9f8fffffd'];
  case 'oxy'
    h=['4005054105054306064406064706074806074906074b06084d07084f070950070951070954070a55070b57070b58070b' ...
       '5b070c5c070c5d070c5f070d62070d63070e64070e66070e68070e6a060f6b060f6d060f6f060f71060f72060f73050f' ...
       '76050f78050f79050f7a050f7d050e7e050e7f060d81060d83080c84090c850a0b860c0b880e0a89100a8a11098b1309' ...
       '8d15088e17088f1808504f4f5050505151505251515353535454535554545655555757565857575958585959585b5a5a' ...
       '5c5b5b5c5c5b5d5d5c5f5e5e5f5f5e60605f6160606262616363626463636564646666656766666867676868676a6969' ...
       '6b6a6a6b6b6a6c6c6b6e6d6d6f6e6e6f6f6e70706f727171727271737372747373767574767675777776787777797978' ...
       '7a7a797b7b7a7c7b7b7d7d7c7e7e7d7f7f7e81807f818180828281838382858483858584868685878786898887898988' ...
       '8a8a898b8b8a8d8c8c8d8d8c8e8e8d8f8f8e9190909291909292919393929595949695959796959797969999989a9a99' ...
       '9b9a9a9c9b9a9d9d9c9e9e9d9f9f9ea0a09fa2a1a0a3a2a1a3a3a2a4a4a3a6a6a5a7a6a6a8a7a7a9a8a7aaaaa9ababaa' ...
       'acacabadadacafaeaeb0afaeb1b0afb1b1b0b3b3b2b4b4b3b5b5b4b7b7b6b8b7b7b9b8b7bab9b8bbbbbabcbcbbbdbdbc' ...
       'bebebdc0c0bfc1c1c0c2c2c1c3c3c2c5c5c3c6c5c4c7c6c5c8c7c6cac9c8cbcac9cccbcacccccbcececdcfcfced0d0cf' ...
       'd1d1d0d3d3d2d4d4d3d5d5d4d6d6d5d8d8d7d9d9d8dadad9dbdbdadddddcdededddfdfdee0e0dfe2e2e1e3e3e2e4e4e3' ...
       'e6e5e4e8e7e6e9e8e7eae9e8ebebe9ededebeeeeecefefeef0f0eff2f2f1f3f3f2f4f4f3f8fe69f6fd67f5fc64f4fc62' ...
       'f1fa5df0f95aeff857eef754ecf54eebf34bebf248eaf145eaee40eaed3eeaeb3deaea3beae738e9e637e9e436e9e334' ...
       'e9e032e8df31e8dd30e8dc30e8d92ee7d82de7d72ce7d52be6d32ae6d129e6d028e5cf28e5cc26e5cb26e4c925e4c825' ...
       'e3c623e3c423e3c322e2c221e2bf20e1be20e1bd1fe0bb1fe0b91edfb81ddfb61ddfb51cdeb31bddb11addb01addaf19'];
  case 'deep'
    h=['fdfeccf5fac7edf7c3e5f4beddf2bad4efb6ccecb3c4e9afbbe6acb2e3aaaae0a8a1dda698daa490d7a487d4a37fd1a3' ...
       '76cda370c9a36ac5a465c2a461bea45dbaa45ab6a457b1a455ada352a9a351a5a24fa1a24d9da14c99a04a959f49919e' ...
       '478c9d46889c45849b44809b427c9a4178994074983f70973f6c963e68963e64953e60943e5b933e57913f538f404e8d' ...
       '41498841458341417d413e76403b703f38693d35623b325c392f55372c4f35294932264330233d2d20372b1d32281a2c'];
  case 'dense'
    h=['e6f1f1dfedeed8eaecd1e7eacbe4e8c4e0e6bedde5b7dae4b1d6e3abd3e3a5cfe29fcce29ac8e294c5e28fc1e28abde3' ...
       '85b8e381b4e37eb0e47bace478a8e476a4e5759fe5749be47396e47391e3748de27488e17583df757edd7679da7775d7' ...
       '786fd3786ad07965cc7961c8795cc37958bf7953ba794fb5784baf7747aa7642a5753e9f743b9973379371338d6f2f87' ...
       '6d2b7f6b287968247266216c631f65601c5e5d1a585a185156164b5215444e133e49123845113340102e3b0f29360e24'];
  case 'algae'
    h=['d7f9d0d2f5cacdf2c4c8eebec3ebb9bee7b3b9e4adb4e0a8afdda2aada9da4d6989fd3929ad08d95cd888fca838ac77e' ...
       '83c3797dc07477bd6f71ba6b6bb76764b4635db25f56af5c4eac5946a9563da65434a3532ca052249d511c9a51169650' ...
       '0f92500b8f4f088b4e07874d07844d08804b0a7c4a0c79490e7548107246126e45136a4315674116634017603e185c3c' ...
       '1958391954371a51351a4d331a4a301a472e1a432c194029193c2718392417352216321f152f1c142b1a132817122414'];
  case 'matter'
    h=['feedb0fde8abfde2a5fcdca0fbd79bfbd196facc91fac68cf9c187f8bb83f8b67ef7b07af6ab76f5a572f4a06ef39a6a' ...
       'f29466f08e63ef8960ee835dec7e5aeb7858e97356e76e55e56854e36353e05e53de5953db5453d84f54d54b54d14656' ...
       'cc4157c83d58c43a5ac0365bbb335cb7305eb22d5fae2b60a92861a426629f24629a2263952063901f638a1d63851c63' ...
       '7e1b62791a61741a606e195f69195d63185b5e18595917575316544e165149154e44144b3e13483912453411412f0f3e'];
  case 'turbid'
    h=['e9f6abe6f1a5e4ec9fe2e89ae0e394dedf8edcda88dad583d8d17ed6cc78d4c873d3c36ed1bf69cfbb65cdb660cbb25c' ...
       'c9ac57c7a853c5a450c3a04dc19b4abf9747bd9345bb8f43b88b41b68840b3843fb0803ead7d3daa793ca7763ca4723b' ...
       '9f6e3b9c6b3b98683b95653a91623a8d603a895d3a855a398158397d5538795338755037714e376d4b36694935644634' ...
       '5f43335b4132573f30533c2f4f3a2e4a382c46352b4233293e30283a2e26362b243229232e26212a241f26211d221f1b'];
  case 'speed'
    h=['fffdcdfcf8c5f9f3bcf7eeb4f4eaabf1e5a2efe19aecdc91e9d889e6d480e3cf77dfcc6edbc866d7c45dd3c155cebd4c' ...
       'c8b943c3b73bbdb434b7b12db1ae27aaac20a4a91b9da71596a5108fa20c88a008819d067a9b067399066c960765940a' ...
       '5c900e548e114d8b144688173f851a38831d317f202a7c222479241e7626187328136f290f6c2b0d682b0b642c0b612d' ...
       '0c5c2d0e582d10542c11512c134d2b15492a164528174127183e25193a2319362119321e192e1c192b19182716172313'];
  case 'amp'
    h=['f1edecefe8e7ede3e1ebdfdce9dad6e7d5d0e6d1cae4ccc5e2c7bfe1c3b9dfbeb3deb9aeddb5a8dbb0a2daac9cd8a796' ...
       'd7a18fd59d89d49884d3947ed18f78d08b73cf866dcd8168cc7d62ca785dc97457c76f52c66a4dc46548c36143c15c3e' ...
       'bf5639bd5134bb4c30b9462db7412ab53c27b23726b03125ad2c24aa2724a62225a21e259e1a269a1627951328911129' ...
       '8b0f29850e29800e297b0e29750e28700e276b0f25650f24600e225b0e20560e1e510d1c4b0c19460b17410a143c0912'];
  case 'tempo'
    h=['fff6f4f9f2eef4eee8eeeae2e9e7dde3e3d7dde0d1d8ddccd2d9c7ccd6c1c6d3bcc0d0b7bacdb3b4caaeaec7aaa8c4a5' ...
       'a0c0a099be9d92bb998bb89685b5937db39076b08d6fad8b67ab895fa88757a58550a284479f823f9c81389981309680' ...
       '27927f218e7e1b8b7d16877c13847b11807a117c79117878127576137174156d7316697118656f19626d1a5e6b1b5a68' ...
       '1b56661c52631c4e611c4b5f1c475d1c435a1c40581b3c561b38531a355119314f182d4c18294a172548162146151d44'];
  case 'rain'
    h=['eeedf3ebe9ece8e5e6e5e1e0e3dcdae0d8d3ded4cbdccfc3dbcbbcd8c7b4d6c3acd3bfa4cfbc9cc9ba96c3b791bcb58d' ...
       'b4b289adb087a6ae849fac8298a98091a77d8aa57b83a3797ca077759e756d9c73659a725d977055956f4c936e43906e' ...
       '388d6d2f8a6e26876e1e846e17816e117d6e0b7a6e07766e05736e036f6d046b6d05686c07646b0b606a0f5d69135967' ...
       '1754651a50631d4c601f485d21455a234157243d5425395125364d25324a252e47252a4424274123233e221f3b221b38'];
  case 'phase'
    h=['a8780dae7414b3701bb96c22be6828c2642ec75f35cb5a3ccf5643d2514bd54b53d8465cdb4066dd3a70de357bdf2f87' ...
       'de2997dd26a3db25b0d827bcd42ac7d02fd0cb35d9c53ce1be43e7b84aecb050efa957f2a05df49863f48f69f4856ff2' ...
       '7875ef6e7aeb637fe65883df4d87d8428ad1388cc9308fc02891b82392b01e93a81a94a01795981496901097880d9880' ...
       '0b99750f9a6b179a61219a552e9a493c993c4b972f5a9423689119748e137f8b0f88870e91830d99800da17c0da8780d'];
  case 'topo'
    h=['281a2c291c2f2b1d322c1f342d20372f223a30233d312540322643342846352949362a4c372c4f382d52392f553a3058' ...
       '3b325c3c335f3d35623e36663f38693f396c403b70403c73413e7641407a41417d424380414583414785414988414b8a' ...
       '404d8c404f8d3f528f3f54903e56913e58923e5a923e5c933e5f933e61943e63943e65953e67953e69963e6b963f6d97' ...
       '3f6f97407197407398407598417799427999427b99437d9a437f9a44819b44839b45859c46879c46899d478b9d488d9d' ...
       '488f9e49919e4a939f4a959f4b97a04c99a04d9ba14d9da14e9fa14fa1a250a3a251a5a251a7a352a9a353aba355ada3' ...
       '56afa457b1a458b3a45ab6a45bb8a45dbaa45fbca461bea463c0a465c2a467c3a46ac5a46dc7a370c9a373cba376cda3' ...
       '7acea37dd0a381d2a385d3a389d5a38dd7a392d8a496daa49adba59fdda5a3dea6a7e0a7ace1a8b0e2a9b5e4aab9e5ac' ...
       'bde7adc1e8afc6eab0caebb2ceecb3d2eeb5d7efb7dbf1b9dff2bbe3f4bde7f5bfebf7c1eff8c4f3fac6f7fbc8fbfdcb' ...
       '0d25140e27150f2915102a16112c17122e1713301814321815331916351a17371a17391b183a1b193c1c1a3e1c1b401c' ...
       '1b411d1c431d1d451d1e471e1f481e204a1e214c1e234e1e254f1e27511e2a521e2d531f305520335622365723395825' ...
       '3c5a263f5b28415c2a445d2b475f2d49602f4c61304e62315163335465345666355967365c68375e6a38616b39646c3a' ...
       '666d3a696f3b6b703c6e713c71723d73743d76753e79763e7b773e7e793f817a3f837b3f867c3f897e408c7f408e8040' ...
       '9181409483409684409985409c86409f8840a18940a48a3fa78c3faa8d3fad8e3fb08f3fb3913fb6923fb9933ebc943e' ...
       'bf953fc19741c39945c49b48c59d4cc69f50c7a153c8a357caa55acba75ecca961cdab65cead68cfb06cd0b26fd1b473' ...
       'd2b676d3b87ad4bb7dd5bd81d6bf84d7c188d8c38bdac68fdbc892dcca96ddcc99decf9ddfd1a0e0d3a4e2d5a7e3d8ab' ...
       'e4daaee5dcb2e6dfb6e8e1b9e9e3bdeae6c0ece8c4edeac7eeedcbf0efcff1f1d2f2f4d6f4f6d9f5f9ddf7fbe1f9fde4'];
  case 'balance'
    h=['181c431a1f491c224f1e255520275b212a62232d69252f6f26327627347d283784293a8c293c93293f9a2942a22745a9' ...
       '2548b0214cb61c50ba1655bd1059be0c5ebe0a62be0b66bd0f6abd136ebc1972bb1e76bb237aba297dba2e81ba3384ba' ...
       '3888ba3e8bba438fba4892ba4e95ba5399ba599cbb5f9fbb65a2bc6ba5bc71a8bd78abbe7eaebf85b1c08bb4c291b7c3' ...
       '98bac59ebcc7a4bfc9aac2cbb0c5cdb6c9cfbcccd2c1cfd4c7d2d7cdd5d9d3d9dcd8dcdedee0e1e3e3e4e9e7e7eeeaea' ...
       'f0eae9eee5e3ece0deeadcd8e8d7d2e6d2cde5cec7e3c9c1e1c4bbe0c0b5dfbbb0ddb6aadcb2a4daad9ed9a998d8a493' ...
       'd69f8dd59b87d39681d2927cd18d76cf8970ce846bcd7f65cb7b60ca765bc87255c76d50c5684bc36346c25f41c05a3c' ...
       'be5538bd5034bb4b30b9452cb74029b43b27b23525af3024ac2b24a92624a52125a11d259d1926991627941328901029' ...
       '8b0f29860e29800e297b0e29760e28700e276b0f25650f24600e225b0e20560e1e510d1c4b0c19460b17410a143c0912'];
  case 'delta'
    h=['11204012214314224615244916254c1727501928531a29561b2a5a1c2c5d1e2d601f2e6420306721316b22326f233372' ...
       '24357625367a25377e263882263a86273b8a273d8d263e9125409424429723449821479a20499b1f4b9b1e4d9c1d509c' ...
       '1c529d1c549d1b569d1b589e1b5a9e1b5c9e1b5e9f1b609f1b639f1b659f1c67a01c69a01d6aa01e6ca11e6ea11f70a2' ...
       '2072a22174a22276a32378a3247aa4257ca4267ea52780a52882a62a84a62b85a62c87a72e89a72f8ba8308da8328fa9' ...
       '3391a93593aa3795aa3897ab3a98ab3c9aac3e9cac409ead42a0ad45a2ae47a3ae4aa5ae4da7af50a9af53aab056acb0' ...
       '5aaeb05dafb161b1b165b3b269b4b36db6b371b7b475b8b579bab57dbbb681bdb784beb888c0b98cc1ba90c3bc94c4bd' ...
       '97c5be9bc7bf9ec8c1a2cac2a6cbc3a9cdc4accec6b0d0c7b3d2c9b7d3cabad5ccbdd6cdc1d8cec4dad0c7dbd1caddd3' ...
       'cddfd4d1e0d6d4e2d7d7e4d9dae6dadde7dbe0e9dde3ebdee6eddfeaefe0edf1e2f0f3e3f3f5e3f6f7e4faf8e5fdfae6' ...
       'fffcccfdfac8fcf7c4faf5bff9f3bbf8f0b7f6eeb2f5ebaef4e9aaf2e7a6f1e4a1f0e29deee099edde94ebdc90ead98c' ...
       'e8d787e7d583e5d37fe4d17ae2cf76e0cd71dfcb6dddc969dbc764d9c560d7c45cd5c258d2c053d0be4fcebd4bcbbb47' ...
       'c8ba43c6b83fc3b73cc0b538bdb434bab331b7b12eb4b02ab1af27aead24abac21a8ab1ea4aa1ba1a8189ea7169aa613' ...
       '97a51193a40e90a20c8ca10a89a009859f07829e067e9c067b9b06779a067499067098076c960769950865940a61920b' ...
       '5e910d5a900e578f10538d114f8c134c8b154889164488184186193d851b3a831c36821d33801f2f7f202c7d21297c22' ...
       '267a242279251f77261d75271a7427177228157029136e2a116d2a0f6b2b0d692b0c672c0b652c0b642c0b622d0b602d' ...
       '0b5e2d0c5c2d0d5a2d0e582d0f562c0f552c10532c11512c124f2b134d2b144b2a15492a164729164528174327174127' ...
       '184026183e25193c24193a2319382219362119341f19321e19301d192e1c192c1a192b19182917182716182514172313'];
  case 'curl'
    h=['151d4416214617254818294a182d4c19314f1a35511b38531b3c561c40581c435a1c475d1c4b5f1c4e611c52641b5666' ...
       '1b59681a5d6a19616c18656e176870156c72147074127476117877117b79117f7a13837b16877c1a8a7d1f8e7e26917f' ...
       '2d95803498803c9b81449e824ca18354a4845ca78664a9886cac8a73af8c7ab28f82b49189b79490ba9896bd9b9dbf9f' ...
       'a3c2a3aac5a7b0c8abb6cbb0bcceb4c3d1b9c8d4beced7c3d4dac8dadecee0e1d3e5e5d9ebe8dff0ece4f6efeafbf3f0' ...
       'fcf3f0faeeeaf7e9e3f5e4dcf3dfd6f1dacfefd5c8eed0c2eccbbbebc6b5e9c1afe8bda8e6b8a2e5b39ce4ae97e3a991' ...
       'e1a48ce09e87df9982dd947ddc8f79da8a75d98572d7806fd57b6cd37669d17267cf6d66cc6864ca6363c75f62c45a61' ...
       'c15661be5260bb4e60b74a60b44660b04260ac3e60a83a60a43760a033609c3060982c619429618f26608b2360862160' ...
       '811e5f7c1c5f771a5e72185c6d175b6816596315575d145458135153134e4d124a4811464310423e0f3e390e3a340d35'];
  case 'diff'
    h=['0823400c2a470f314f123756153e5e1945641f4c6928526d3158713a5e7643647a4b6a7f5370845c7688647c8d6c8292' ...
       '768a997f919e8797a38f9ea998a5afa0abb4a9b2bab2bac0bbc1c7c4c8cdcdd0d4d6d8dbe0e0e2e8e7e8f0edeef5f1f0' ...
       'f5f0eef1ebe8eae5dfe3ddd4dbd5cad3cdc0ccc5b5c5bdabbeb5a1b7ae98b0a68ea99f85a3987b9c9172968a69908460' ...
       '887b5582754c7c6e4376683b6f6233685c2b615625595121514b1e49451b4240183a3a153334122b2e0e24280a1c2207'];
  case 'tarn'
    h=['17230e19270e1c2a0f1f2e10213110233510263810283c102b3f0f2e420f30460e34490c394b0c3f4e0e4450104a5312' ...
       '4f55145557165a5918605c1a655e1b6b601d70621f7664217b6722816924866b268c6d27926f2998712b9e732da3752f' ...
       'a97731af7933b57b36bb7d39c17f3cc68141cb8448cd884fcf8c57d1915dd29664d49a6bd69f72d8a379daa880dbad87' ...
       'ddb18edfb695e1ba9ce3bfa3e5c4aae7c8b1e9cdb8ebd2bfedd7c6f0dbcdf2e0d4f4e5dbf7eae2f9efe9fbf3effcf6f4' ...
       'fcf7f5fbf5f0f8f2eaf4eee3f0eadcede6d5e9e2cde5ddc6e1d9bfddd6b8d7d2b2d1cfadcbccaac4c9a7bec6a5b7c3a3' ...
       'b1c0a1abbd9fa5b99d9fb69b99b39994b0978ead9588aa9382a7927ca49076a18e709e8c6a9b8a6498895e9587579285' ...
       '518f844a8c834489823d868037837f31807e2c7c7d27797c24757b21727a206e781f6a761e67751d63731c5f711a5c6f' ...
       '19586e18546c16516b144d691249681046660f42650d3e630b3b620937610933600a2f5e0c2a5b0e26580f2254101e4f'];
  otherwise
    error('make_3d: unknown cmocean colormap "%s"',name);
end
c=reshape(hex2dec(reshape(h,2,[])'),3,[])'/255;
x=linspace(0,1,size(c,1));
cm=interp1(x,c,linspace(0,1,n));
if n==1, cm=c(round(end/2),:); end
cm=min(max(cm,0),1);
if rev, cm=flipud(cm); end
return
%
function [name,div]=cmocean_var(var)
if nargin<1 || isempty(var), var=''; end
v=lower(strtrim(var));
div=false;
if any(strcmp(v,{'temp','sst','t','temperature','theta','tpas'})) || ~isempty(regexp(v,'^(temp|sst)','once'))
  name='thermal';
elseif any(strcmp(v,{'salt','sss','s','salinity'})) || ~isempty(regexp(v,'^(salt|sss)','once'))
  name='haline';
elseif any(strcmp(v,{'rho','sig','sigma','sigma_t','sigmat','rho1','bvf'})) || ~isempty(regexp(v,'^(rho|sigma)','once'))
  name='dense';
elseif any(strcmp(v,{'speed','spd','wspd','ke','eke','mke','mag','magnitude','|v|'})) || ...
       ~isempty(regexp(v,'(speed|magnitude|^\|)','once'))
  name='speed';
elseif ~isempty(regexp(v,'^(u|v|w|ubar|vbar|ue|vn|u10|v10|uwnd|vwnd|uwind|vwind|taux|tauy|sustr|svstr|omega|zeta|ssh|pv|psi|bustr|bvstr|div)$','once')) ...
       || ~isempty(regexp(v,'(vort|flux|curl|anom|/)','once'))
  name='balance'; div=true;
  if ~isempty(regexp(v,'/','once')), name='speed'; div=false; end   % wind pair label: magnitude
elseif any(strcmp(v,{'h','depth','bathy','hraw','z_r','z_w','hbl','hbbl'}))
  name='deep';
elseif ~isempty(regexp(v,'^(o2|oxy|doxy)','once'))
  name='oxy';
elseif ~isempty(regexp(v,'^(chl|phy|sphyto|lphyto|diat|nano)','once'))
  name='algae';
elseif ~isempty(regexp(v,'^(no3|po4|si|nh4|fer|dic|talk|don|dop|nut)','once'))
  name='matter';
elseif ~isempty(regexp(v,'^(zoo|szoo|lzoo|det|sdet|ldet|poc|goc|mes)','once'))
  name='turbid';
elseif ~isempty(regexp(v,'^(ak|kv|kt|tke)','once'))
  name='amp';
elseif strcmp(v,'hz')
  name='deep';
else
  name='thermal';
end
return
