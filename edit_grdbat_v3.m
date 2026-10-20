%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% EDIT_GRDBAT_V3  Interactive bathymetry (h) editor for CROCO grids
%                 (Matlab version of oct_edit_grdbat; also runs in Octave)
%
%   edit_grdbat_v3
%   edit_grdbat_v3(CMIN,CMAX)
%   edit_grdbat_v3(CMIN,CMAX,BATHYMETRYFILE)
%   edit_grdbat_v3(CMIN,CMAX,BATHYMETRYFILE,COASTLINEFILE)
%   fig = edit_grdbat_v3(...)        % returns the figure handle
%
%   CMIN, CMAX     : colour range (m). [] (or not given): range of the
%                    sea depths of the file. The range can be changed in
%                    the window (boxes above/below the colour bar).
%   BATHYMETRYFILE : CROCO grid file (h, mask_rho, lon_rho, lat_rho).
%                    Not given: a file dialog is opened (and a second
%                    one for the optional coastline file).
%   COASTLINEFILE  : optional coastline:
%                    - MAT file with lon/lat vectors (the *_mask.mat
%                      files of make_coast), ncst (N,2) (GSHHS file
%                      saved by m_map) or C.Icst/C.Jcst (ijcoast),
%                    - two-column text file [lon lat],
%                    - ESRI shapefile (.shp, polylines/polygons, lon/lat).
%                    Not given: coastfilemask/coastfileplot of
%                    crocotools_param.m (current folder) or a *_mask.mat
%                    file of the current folder. Menu "Coastline": load
%                    another file, GSHHS (m_map) or remove it.
%
%   VIEW (menu "View", as in editmask):
%     Geographic (lon/lat) : each cell is drawn with its real lon/lat
%                            shape (also for rotated/curvilinear grids),
%                            coastline with its original resolution;
%     Grid indices (I,J)   : image in grid indices (I along xi, J along
%                            eta, starting at 0 as in editmask).
%
%   EDIT TOOLS (left panel):
%     Point / brush : click a cell, or click and drag to paint several
%                     cells ("Brush size" = width in cells);
%     Rectangle     : click and drag a rectangle (area);
%     Polygon       : click the vertices; right click, double click or
%                     Enter closes the polygon and applies it, Esc
%                     cancels.
%   OPERATION applied to the sea cells of the point/stroke/area with
%   VALUE (m):
%     Set to value      h = value
%     Add value         h = h + value     (value < 0: shallower)
%     Multiply by value h = h * value
%     Deepen to value   h = max(h,value)  (cells shallower than value)
%     Shoal to value    h = min(h,value)  (cells deeper than value)
%     Smooth            local smoothing of the area (see below)
%   In a stroke each cell is edited only once (Add and Multiply do not
%   accumulate while dragging). Land cells (mask_rho=0) are never edited.
%   VALUE: type it, click (or drag) on the colour bar, or right click a
%   cell of the map (point/rectangle tools) to take its depth.
%
%   SMOOTHING ("Smooth last edit" button or "Smooth" operation):
%   the cells of the last edit, plus "Width" cells around them, are
%   smoothed (sea cells only, cells outside the area are kept fixed, so
%   the area is connected smoothly to the rest of the bathymetry).
%   Passes of a 5-point filter on log(h) are made until the slope factor
%   rx0 = |h1-h2|/(h1+h2) of all the neighbour pairs of the area is below
%   "rx0 max" (as in the smoothing of make_grid), at least 2 passes,
%   at most 1000 (or until the filter has converged: then the area is
%   too narrow for the slopes around it, increase "Width"). The status
%   line gives rx0 before/after.
%
%   LAND CELLS AND MASK:
%     "Edit h on land cells too": the h operations (Set, Add, ...) also
%     change h on the land cells (mask unchanged; land drawn with greyed
%     colours, its depth can be taken with a right click).
%     Operations "Mask: set land" / "Mask: set sea" change mask_rho with
%     any tool (point/brush, rectangle, polygon).
%     "Remove islands": the land patches (8-connected) that do not touch
%     the grid boundary become sea; only those with at most N cells if a
%     number is given in the box ("all": any size).
%     "Fill h of new sea cells": the cells that become sea get the mean
%     depth of their sea neighbours (from the edges inwards); then
%     "Smooth last edit" can be used on them.
%     Save writes h, mask_rho and the recomputed mask_u, mask_v,
%     mask_psi (as editmask) when the mask has been changed.
%
%   PROFILE: button "Profile", then click the points of the section on
%   the map (right/double click or Enter to end). A window shows z=-h
%   along the section (distance in km), land cells in green, the h of
%   the file in red dashes where it was changed. It is updated after
%   each edit.
%
%   3D VIEW: button "3D view", then drag a box on the map (a simple
%   click takes the visible area). A window shows the 3D surface z=-h of
%   the area (same colours, coastline at z=0, lighting), with a vertical
%   exaggeration menu (auto, 1...1000) and Refresh; it can be rotated
%   with the mouse.
%
%   OPEN BOUNDARIES: button "Open boundaries" with N (box, default 10)
%   and the boundaries S, E, N, W (checked by default if they have sea
%   cells): along each line perpendicular to a checked boundary, the N
%   cells next to the boundary get the depth of the cell N+1, so that
%   the inflow does not meet abrupt bathymetry changes near the
%   boundary. S/N are done before E/W (corner blocks: depth of cell
%   (N+1,N+1)). Land cells are kept (unless "Edit h on land cells too");
%   lines whose cell N+1 is land are skipped. "Smooth last edit" can
%   then smooth the transition at cell N+1.
%
%   COLOUR BAR: on the right, outside the map. Its range is edited in
%   the boxes above (max) and below (min) it, "Auto" = range of the sea
%   depths; colormap menu (and reverse) below.
%
%   Other: Undo (30 levels, h and mask), Revert (h and mask of the
%   file), Zoom in (box), Zoom out, Save, Exit; menu File: Open. Keyboard: arrows
%   pan, +/- zoom, u (Ctrl+z) undo, s save, Esc cancel, Enter close the
%   polygon.
%
%   COLORMAPS: cmocean deep (default), ice, haline, dense (tables
%   included in this file, cmocean v3.0.3, MIT license, Thyng et al.
%   2016, Oceanography 29(3):9-13) and the Matlab colormaps.
%
%   Original Matlab version (edit_grdbat_v2.m) created by Osvaldo Artal,
%   with A. Sepulveda and C. Torregrosa (2008-2011). Octave version
%   oct_edit_grdbat (Oct-2026): figure-level mouse callbacks, geographic
%   and index views, point/brush/rectangle/polygon edits, colour range
%   edition, local smoothing, mask edition, profile, 3D view and open
%   boundaries. This file is the same code for Matlab (Oct-2026):
%   netcdf.* API of Matlab (same (xi,eta) order as octave-netcdf), no
%   Octave-only function or syntax; it also runs in Octave (qt or fltk
%   graphics toolkit). Needs m_map only for the GSHHS coastlines.
%
%--------------------------------------------------------------------------
%  EDITBATHYMETRY is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published
%  by the Free Software Foundation; either version 2 of the License,
%  or (at your option) any later version.
%
%  EDITHBATIMETRY is distributed in the hope that it will be useful, but
%  WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%  MA  02111-1307  USA
%
%  Copyright (c) 2008
%  Andres Sepulveda, e-mail: andres@dgeo.udec.cl
%  Christian Torregrosa, e-mail: chtorregrosa@gmail.com
%  Osvaldo Artal, e-mail: oartal@oasc.cl (8,sept,2011)
%  Original creator of the Matlab version (edit_grdbat_v2.m): Osvaldo Artal
%  Andres Sepulveda 2026 - Octave adaptations (and this Matlab version)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function fig_out=edit_grdbat_v3(cmin,cmax,bathymetryfile,coastlinefile)
if nargin<1, cmin=[]; end
if nargin<2, cmax=[]; end
if nargin<4, coastlinefile=[]; end
if nargin<3 || isempty(bathymetryfile)
  [fn,pth]=uigetfile('*.nc','Select CROCO grid file (bathymetry)...');
  if isequal(fn,0), if nargout>0, fig_out=[]; end, return, end
  bathymetryfile=[pth,fn];
  if nargin<4
    [fn,pth2]=uigetfile({'*.mat;*.shp;*.dat;*.txt','Coastline files (*.mat,*.shp,*.dat,*.txt)'},...
                        'Select a coastline file (optional, Cancel: none)...',pth);
    if ~isequal(fn,0), coastlinefile=[pth2,fn]; end
  end
end
if ~exist(bathymetryfile,'file')
  error(['edit_grdbat_v3: grid file not found: ',bathymetryfile])
end
if exist('OCTAVE_VERSION','builtin') && ~any(strcmp(feval('graphics_toolkit'),{'qt','fltk'}))
  try
    feval('graphics_toolkit','qt');           % Octave only
  end
end
old=findobj(0,'tag','edit_grdbat_v3');
if ~isempty(old), delete(old); end
%
% Read the grid: netcdf.getVar gives (xi,eta) = (Lp,Mp) arrays, kept in
% this order (no transposition)
%
S=struct();
S.file=bathymetryfile;
S.figname='Bathymetry editor';
ncid=netcdf.open(S.file,'NC_NOWRITE');
S.h=double(netcdf.getVar(ncid,netcdf.inqVarID(ncid,'h')));
[S.Lp,S.Mp]=size(S.h);
S.mask=ones(S.Lp,S.Mp);
try
  S.mask=double(netcdf.getVar(ncid,netcdf.inqVarID(ncid,'mask_rho')));
end
S.mask=double(S.mask>0.5);
S.lon=[]; S.lat=[];
for nm={{'lon_rho','lat_rho'},{'x_rho','y_rho'}}
  try
    S.lon=double(netcdf.getVar(ncid,netcdf.inqVarID(ncid,nm{1}{1})));
    S.lat=double(netcdf.getVar(ncid,netcdf.inqVarID(ncid,nm{1}{2})));
    S.lonname=nm{1}{1}(1:3); S.latname=nm{1}{2}(1:3);
    break
  end
end
netcdf.close(ncid);
S.hfile=S.h;                 % h of the file (last saved)
S.maskfile=S.mask;
S.maskstart=S.mask;
S.undo={};
S.maxundo=30;
S.changed=0;
S.last=false(S.Lp,S.Mp);     % cells of the last edit
S.touched=false(S.Lp,S.Mp);
S.hstart=S.h;
S.tool=1;                    % 1 point/brush, 2 rectangle, 3 polygon
S.brush=1;
S.op=1;                      % operation (see OPS)
S.ops={'Set to value','Add value','Multiply by value','Deepen to value',...
       'Shoal to value','Smooth','Mask: set land','Mask: set sea'};
S.editland=0;                % 1: the h operations also act on land cells
S.fillh=1;                   % 1: h of new sea cells from the sea neighbours
S.pick='';                   % '', 'profile', '3d'
S.prof=zeros(0,2);           % profile vertices (0-based I,J)
S.hproffig=[]; S.h3dfig=[];
S.blk3d=[];
S.width=2;                   % smoothing: cells around the last edit
S.rmax=0.2;                  % smoothing: target rx0
S.action='';
S.p0=[0 0];
S.poly=zeros(0,2);
S.zoomnext=0;
S.landcolor=[0.75 0.75 0.75];
[S.mx,S.my]=ndgrid(0:S.Lp-1,0:S.Mp-1);
sea=S.h(S.mask>0);
if isempty(sea), sea=S.h(:); end
if isempty(cmin), cmin=min(sea); end
if isempty(cmax), cmax=max(sea); end
if ~(cmax>cmin), cmax=cmin+1; end
S.cmin=cmin; S.cmax=cmax;
S.value=round(0.5*(cmin+cmax));
cm={'viridis','parula','turbo','cubehelix','ocean','bone','gray','hot','cool','jet'};
S.cmaps=[{'cmo.deep','cmo.ice','cmo.haline','cmo.dense'},cm(cellfun(@(c) exist(c)>0,cm))];  % cmocean first (default deep)
S.cmapk=1; S.cmaprev=0;
S.cmap=make_cmap(S);
if ~isempty(S.lon)
  [S.xcor,S.ycor]=cell_corners(S.lon,S.lat);
  S.coslat=cos(mean(S.lat(:))*pi/180);
  S.view='geo';
else
  S.view='ij';
end
%
% Coastline
%
if isempty(coastlinefile)
  coastlinefile=find_coast_file();
end
S.coastfile=coastlinefile;
S.cst=read_coast(coastlinefile,S);
%
% Figure and menus
%
bg=[.94 .94 .94];
fig=figure('NumberTitle','off','Name',S.figname,'tag','edit_grdbat_v3',...
           'MenuBar','none','ToolBar','none','Color',bg,...
           'IntegerHandle','off','Units','normalized',...
           'Position',[.06 .06 .86 .84]);
S.fig=fig;
hf=uimenu(fig,'Label','File');
uimenu(hf,'Label','Open grid file...','Callback',@cb_open);
uimenu(hf,'Label','Save h and mask','Callback',@cb_save);
uimenu(hf,'Label','Revert to the file','Callback',@cb_revert);
uimenu(hf,'Label','Exit','Callback',@cb_exit,'Separator','on');
hv=uimenu(fig,'Label','View');
S.hview(1)=uimenu(hv,'Label','Geographic (lon/lat)','Callback',{@cb_view,'geo'});
S.hview(2)=uimenu(hv,'Label','Grid indices (I,J)','Callback',{@cb_view,'ij'});
if isempty(S.lon), set(S.hview(1),'Enable','off'); end
hm=uimenu(fig,'Label','Coastline');
uimenu(hm,'Label','Load coastline file (.mat, .shp, text)...','Callback',@cb_coastfile);
uimenu(hm,'Label','Load shapefile (.shp)...','Callback',@cb_shapefile);
res={'c','crude';'l','low';'i','intermediate';'h','high';'f','full'};
for k=1:size(res,1)
  uimenu(hm,'Label',['GSHHS ',res{k,2},' resolution'],'Callback',{@cb_gshhs,res{k,1}},...
         'Separator',ifelse(k==1,'on','off'));
end
uimenu(hm,'Label','Remove coastline','Callback',@cb_nocoast,'Separator','on');
%
% Map (centre) and colour bar (right, outside the map)
%
S.ax=axes('Parent',fig,'Units','normalized','Position',[0.25 0.11 0.58 0.84]);
hold(S.ax,'on');
S.himg=image(0:S.Lp-1,0:S.Mp-1,zeros(S.Mp,S.Lp,3),'Parent',S.ax);
S.hsurf=[];
if ~isempty(S.lon)
  S.hsurf=surface(S.xcor,S.ycor,zeros(size(S.xcor)),zeros([size(S.xcor) 3]),...
                  'Parent',S.ax,'FaceColor','flat','EdgeColor','none');
end
S.hcst=plot(S.ax,NaN,NaN,'k','LineWidth',1);
S.hlast=plot(S.ax,NaN,NaN,'w.','MarkerSize',8);
S.hrect=plot(S.ax,NaN,NaN,'r-','LineWidth',1.5);
S.hpoly=plot(S.ax,NaN,NaN,'r.-','LineWidth',1.5,'MarkerSize',12);
S.hprof=plot(S.ax,NaN,NaN,'m.-','LineWidth',2,'MarkerSize',14);
hold(S.ax,'off');
set(S.ax,'YDir','normal','Layer','top','TickDir','out','Box','on');
xc=0.875; wc=0.08;
uicontrol(fig,'Style','text','Units','normalized','Position',[xc .955 wc .03],...
          'String','h (m)','FontWeight','bold','BackgroundColor',bg);
S.hcmax=uicontrol(fig,'Style','edit','Units','normalized','Position',[xc .915 wc .035],...
          'String',num2str(S.cmax),'Callback',@cb_range,...
          'TooltipString','Maximum of the colour range');
S.cax=axes('Parent',fig,'Units','normalized','Position',[xc .2 .025 .69]);
S.hcbar=image([0 1],[S.cmin S.cmax],reshape(S.cmap,[size(S.cmap,1) 1 3]),'Parent',S.cax);
hold(S.cax,'on');
S.hcline=plot(S.cax,[0 1],[1 1]*S.value,'r-','LineWidth',2);
hold(S.cax,'off');
set(S.cax,'YDir','normal','XTick',[],'YAxisLocation','right','TickDir','out',...
          'XLim',[0 1],'YLim',[S.cmin S.cmax],'Box','on');
S.hcmin=uicontrol(fig,'Style','edit','Units','normalized','Position',[xc .155 wc .035],...
          'String',num2str(S.cmin),'Callback',@cb_range,...
          'TooltipString','Minimum of the colour range');
uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[xc .115 wc .035],...
          'String','Auto','Callback',@cb_auto,'TooltipString','Range of the sea depths');
S.hcmapk=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[xc .07 wc .035],...
          'String',S.cmaps,'Value',S.cmapk,'Callback',@cb_cmap);
S.hcmaprev=uicontrol(fig,'Style','checkbox','Units','normalized','Position',[xc .03 wc .035],...
          'String','Reverse','Value',0,'BackgroundColor',bg,'Callback',@cb_cmap);
%
% Left panel
%
x0=0.01; w=0.2; rh=0.03; hh=0.028;
y=0.86;
S.hinfo=uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w .125],...
          'String',{'---'},'HorizontalAlignment','left','BackgroundColor',[1 1 1]);
y=y-0.035;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w hh],...
          'String','Edit tool','FontWeight','bold','BackgroundColor',bg);
tools={'Point / brush','Rectangle (area)','Polygon (area)'};
for k=1:3
  y=y-rh;
  S.htool(k)=uicontrol(fig,'Style','radiobutton','Units','normalized',...
     'Position',[x0 y w rh],'String',tools{k},'Value',k==S.tool,...
     'BackgroundColor',bg,'Callback',{@set_tool,k});
end
y=y-rh-0.003;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .1 rh],...
          'String','Brush size','HorizontalAlignment','left','BackgroundColor',bg);
S.hbrush=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[x0+.1 y .1 rh+.003],...
          'String',{'1','3','5','9','15'},'Value',1,'Callback',@set_brush);
y=y-0.038;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w hh],...
          'String','Operation','FontWeight','bold','BackgroundColor',bg);
y=y-rh-0.002;
S.hop=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[x0 y w rh+.003],...
          'String',S.ops,'Value',S.op,'Callback',@set_op);
y=y-rh-0.006;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .08 rh],...
          'String','Value (m)','HorizontalAlignment','left','BackgroundColor',bg);
S.hval=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0+.08 y .12 rh+.003],...
          'String',num2str(S.value),'Callback',@cb_value,...
          'TooltipString','Type it, click the colour bar or right click a cell');
y=y-rh-0.002;
S.heditland=uicontrol(fig,'Style','checkbox','Units','normalized','Position',[x0 y w rh],...
          'String','Edit h on land cells too','Value',S.editland,'BackgroundColor',bg,...
          'Callback',@cb_editland,'TooltipString','h operations also change land cells (mask unchanged)');
y=y-0.038;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w hh],...
          'String','Smoothing','FontWeight','bold','BackgroundColor',bg);
y=y-rh-0.002;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .1 rh],...
          'String','Width (cells)','HorizontalAlignment','left','BackgroundColor',bg);
S.hwidth=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[x0+.1 y .1 rh+.003],...
          'String',{'0','1','2','3','5','8'},'Value',3,'Callback',@set_width);
y=y-rh-0.004;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y .1 rh],...
          'String','rx0 max','HorizontalAlignment','left','BackgroundColor',bg);
S.hrmax=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0+.1 y .1 rh+.003],...
          'String',num2str(S.rmax),'Callback',@cb_rmax);
y=y-0.042;
S.hsmooth=uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0 y w .037],...
          'String','Smooth last edit','Callback',@cb_smooth,'Enable','off');
y=y-0.04;
uicontrol(fig,'Style','text','Units','normalized','Position',[x0 y w hh],...
          'String','Land/sea mask','FontWeight','bold','BackgroundColor',bg);
y=y-0.037;
S.hislands=uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0 y .12 .035],...
          'String','Remove islands','Callback',@cb_islands,...
          'TooltipString','Land patches not connected to the grid boundary, up to "max cells"');
S.hislmax=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0+.125 y .075 .035],...
          'String','all','TooltipString','Maximum size (cells) of the islands to remove ("all": any size)');
y=y-rh-0.002;
S.hfill=uicontrol(fig,'Style','checkbox','Units','normalized','Position',[x0 y w rh],...
          'String','Fill h of new sea cells','Value',S.fillh,'BackgroundColor',bg,...
          'Callback',@cb_fill);
y=y-0.045;
bt={'Profile',@cb_profile,'3D view',@cb_3d; 'Undo',@cb_undo,'Revert',@cb_revert;...
    'Zoom in (box)',@cb_zoomin,'Zoom out',@cb_zoomout; 'Save',@cb_save,'Exit',@cb_exit};
for k=1:size(bt,1)
  S.hbut(k,1)=uicontrol(fig,'Style','pushbutton','Units','normalized',...
     'Position',[x0 y w/2-.003 .037],'String',bt{k,1},'Callback',bt{k,2});
  S.hbut(k,2)=uicontrol(fig,'Style','pushbutton','Units','normalized',...
     'Position',[x0+w/2+.003 y w/2-.003 .037],'String',bt{k,3},'Callback',bt{k,4});
  y=y-0.042;
end
% open boundaries: h of cell N+1 copied to the N cells next to the boundary
S.hobc=uicontrol(fig,'Style','pushbutton','Units','normalized','Position',[x0 y .12 .037],...
          'String','Open boundaries','Callback',@cb_obc,...
          'TooltipString','Copy h of cell N+1 to the N cells next to each checked open boundary');
S.hobcn=uicontrol(fig,'Style','edit','Units','normalized','Position',[x0+.125 y .075 .037],...
          'String','10','TooltipString','N: number of cells next to the boundary');
y=y-0.038;
sides={'S','E','N','W'};
isopen=[any(S.mask(:,1)) any(S.mask(end,:)) any(S.mask(:,end)) any(S.mask(1,:))];
for k=1:4
  S.hobcs(k)=uicontrol(fig,'Style','checkbox','Units','normalized','Position',[x0+(k-1)*.05 y .05 .034],...
     'String',sides{k},'Value',isopen(k),'BackgroundColor',bg,...
     'TooltipString',[sides{k},' boundary (checked if it has sea cells)']);
end
S.hstat=uicontrol(fig,'Style','text','Units','normalized','Position',[0.25 0.003 0.58 0.035],...
          'String','','HorizontalAlignment','left','BackgroundColor',bg);
set(fig,'WindowButtonDownFcn',@cb_down,'WindowButtonMotionFcn',@cb_move,...
        'WindowButtonUpFcn',@cb_up,'KeyPressFcn',@cb_key,...
        'CloseRequestFcn',@cb_exit);
S=set_view(S,S.view);
guidata(fig,S);
update_value(fig);
refresh_map(fig);
set_status(fig,hint(S));
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
function cm=make_cmap(S)
name=S.cmaps{S.cmapk};
if strncmp(name,'cmo.',4), cm=cmo_map(name(5:end),256); else, cm=feval(name,256); end
if S.cmaprev, cm=flipud(cm); end
return
%
function rgb=h2rgb(S)
%
% True colour image of h (land cells in grey, or greyed colours when the
% land cells can be edited): no NaN in the CData and no figure colormap
% needed
%
n=size(S.cmap,1);
k=round((S.h-S.cmin)/(S.cmax-S.cmin)*(n-1))+1;
k(~isfinite(k))=1;
k=min(max(k,1),n);
rgb=reshape(S.cmap(k(:),:),[size(S.h) 3]);
land=find(S.mask==0);
N=numel(S.h);
for c=1:3
  if S.editland
    rgb(land+(c-1)*N)=0.45*rgb(land+(c-1)*N)+0.55*S.landcolor(c);
  else
    rgb(land+(c-1)*N)=S.landcolor(c);
  end
end
return
%
function r=is_changed(S)
r=~isequal(S.h,S.hfile) || ~isequal(S.mask,S.maskfile);
return
%
function c=pad_cdata(c)
% CData of the corner surface (flat shading: colour of the lower corner)
c=cat(1,c,c(end,:,:));
c=cat(2,c,c(:,end,:));
return
%
function refresh_map(fig)
S=guidata(fig);
rgb=h2rgb(S);
if strcmp(S.view,'geo')
  set(S.hsurf,'CData',pad_cdata(rgb));
else
  set(S.himg,'CData',permute(rgb,[2 1 3]));
end
if any(S.last(:))
  set(S.hlast,'XData',S.px(S.last),'YData',S.py(S.last));
else
  set(S.hlast,'XData',NaN,'YData',NaN);
end
set(S.hsmooth,'Enable',ifelse(any(S.last(:)),'on','off'));
if ~strcmp(S.action,'paint') && ~isempty(S.hproffig) && ishghandle(S.hproffig)
  draw_profile(fig);
end
nm=[S.figname,' - ',S.file];
if S.changed, nm=[nm,' *']; end
set(fig,'Name',nm);
return
%
function set_status(fig,str)
S=guidata(fig);
set(S.hstat,'String',str);
return
%
function s=hint(S)
if strcmp(S.pick,'profile')
  s='PROFILE: click the points of the section; right/double click or Enter: draw it, Esc: cancel.';
  return
elseif strcmp(S.pick,'3d')
  s='3D VIEW: drag a box over the area (simple click: visible area), Esc: cancel.';
  return
end
switch S.tool
  case 1, s='Click/drag: edit cells.  Right click: take the depth of a cell.';
  case 2, s='Drag a rectangle.  Right click: take the depth of a cell.';
  otherwise, s='Click the vertices; right/double click or Enter: apply, Esc: cancel.';
end
s=[s,'  [',S.ops{S.op},']'];
return
%
function update_value(fig)
%
% Colour of the value box and marker on the colour bar
%
S=guidata(fig);
v=S.value;
set(S.hval,'String',sprintf('%.2f',v));
if any(S.op==[1 4 5])
  n=size(S.cmap,1);
  k=min(max(round((v-S.cmin)/(S.cmax-S.cmin)*(n-1))+1,1),n);
  col=S.cmap(k,:);
  set(S.hval,'BackgroundColor',col,...
      'ForegroundColor',ifelse(max(col)<0.6 || mean(col)<0.45,[1 1 1],[0 0 0]));
  set(S.hcline,'YData',[v v],'Visible','on');
else
  set(S.hval,'BackgroundColor',[1 1 1],'ForegroundColor',[0 0 0]);
  set(S.hcline,'Visible','off');
end
return
%
%---------------------------------------------------------------------
% Grid geometry, views
%---------------------------------------------------------------------
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
function S=set_view(S,view)
if strcmp(view,'geo') && isempty(S.lon), view='ij'; end
S.view=view;
if strcmp(view,'geo')
  S.px=S.lon; S.py=S.lat;
  S.xl=[min(S.xcor(:)) max(S.xcor(:))];
  S.yl=[min(S.ycor(:)) max(S.ycor(:))];
  S.tol=0.5*median(abs(diff(S.lat(1,:))));
  if ~(S.tol>0), S.tol=0.01; end
  set(S.himg,'Visible','off'); set(S.hsurf,'Visible','on');
  xlabel(S.ax,'Longitude'); ylabel(S.ax,'Latitude');
  set(S.ax,'DataAspectRatio',[1/S.coslat 1 1]);
else
  S.px=S.mx; S.py=S.my;
  S.xl=[-0.5 S.Lp-0.5]; S.yl=[-0.5 S.Mp-0.5];
  S.tol=0.5;
  set(S.himg,'Visible','on');
  if ~isempty(S.hsurf), set(S.hsurf,'Visible','off'); end
  xlabel(S.ax,'I (xi\_rho index - 1)'); ylabel(S.ax,'J (eta\_rho index - 1)');
  set(S.ax,'DataAspectRatio',[1 1 1]);
end
[x,y]=coast_xy(S);
set(S.hcst,'XData',x,'YData',y);
set(S.hrect,'XData',NaN,'YData',NaN); set(S.hpoly,'XData',NaN,'YData',NaN);
[x,y]=prof_xy(S,S.prof);
set(S.hprof,'XData',x,'YData',y);
xlim(S.ax,S.xl); ylim(S.ax,S.yl);
set(S.hview(1),'Checked',ifelse(strcmp(view,'geo'),'on','off'));
set(S.hview(2),'Checked',ifelse(strcmp(view,'ij'),'on','off'));
return
%
function cb_view(src,~,view)
fig=ancestor(src,'figure'); S=guidata(fig);
S=cancel_action(S);
S=set_view(S,view);
guidata(fig,S); refresh_map(fig);
return
%
function [i,j]=p2ij(S,p)
% (1-based) cell indices of a point of the current view
if strcmp(S.view,'geo')
  d=((S.lon-p(1))*S.coslat).^2+(S.lat-p(2)).^2;
  [~,k]=min(d(:));
  [i,j]=ind2sub([S.Lp S.Mp],k);
else
  i=min(max(round(p(1))+1,1),S.Lp); j=min(max(round(p(2))+1,1),S.Mp);
end
return
%
%---------------------------------------------------------------------
% Coastline
%---------------------------------------------------------------------
%
function f=find_coast_file()
f='';
if exist(fullfile(pwd,'crocotools_param.m'),'file')
  try
    P=param_coast();
    for c={P.mask,P.plot}
      if ~isempty(c{1}) && exist(c{1},'file')
        f=c{1}; return
      end
    end
  end
end
d=dir('*_mask.mat');
if ~isempty(d)
  f=d(1).name;
end
return
%
function P=param_coast()
str=evalc('crocotools_param');
P.mask=''; P.plot='';
if exist('coastfilemask','var'), P.mask=coastfilemask; end
if exist('coastfileplot','var'), P.plot=coastfileplot; end
return
%
function C=read_coast(coast_file,S)
C=struct('lon',[],'lat',[],'icst',[],'jcst',[]);
if isempty(coast_file), return, end
if ~exist(coast_file,'file')
  warning(['edit_grdbat_v3: coast file not found: ',coast_file]); return
end
[~,~,ext]=fileparts(coast_file);
switch lower(ext)
  case '.shp'
    [lon,lat]=read_shapefile(coast_file);
  case '.mat'
    D=load(coast_file);
    if isfield(D,'C') && isstruct(D.C) && isfield(D.C,'Icst')
      C.icst=D.C.Icst(:); C.jcst=D.C.Jcst(:); return
    end
    if isfield(D,'lon') && isfield(D,'lat')
      lon=D.lon(:); lat=D.lat(:);
    elseif isfield(D,'ncst')
      lon=D.ncst(:,1); lat=D.ncst(:,2);
    else
      lon=[]; lat=[];
      f=fieldnames(D);
      for k=1:numel(f)
        v=D.(f{k});
        if isnumeric(v) && ismatrix(v) && size(v,2)==2 && size(v,1)>2
          lon=v(:,1); lat=v(:,2); break
        end
      end
      if isempty(lon)
        warning(['edit_grdbat_v3: no coastline in ',coast_file]); return
      end
    end
  otherwise                                   % text file [lon lat]
    D=load(coast_file);
    lon=D(:,1); lat=D(:,2);
end
C=set_coast_lonlat(C,double(lon),double(lat),S);
return
%
function C=set_coast_lonlat(C,lon,lat,S)
%
% Coastline vertices near the grid (original resolution, NaN separators
% kept), longitudes in the convention of the grid
%
C.lon=[]; C.lat=[]; C.icst=[]; C.jcst=[];
lon=lon(:); lat=lat(:);
if isempty(S.lon)
  warning('edit_grdbat_v3: no lon_rho/lat_rho in the grid: coastline not drawn'); return
end
lon0=mean(S.lon(:));
w=lon<lon0-180 | lon>=lon0+180;
lon(w)=mod(lon(w)-lon0+180,360)-180+lon0;
dx=2*max(abs(diff(S.lon(:,1)))); dy=2*max(abs(diff(S.lat(1,:))));
if isempty(dx) || dx==0, dx=1; end
if isempty(dy) || dy==0, dy=1; end
out=lon<min(S.lon(:))-dx | lon>max(S.lon(:))+dx | lat<min(S.lat(:))-dy | lat>max(S.lat(:))+dy;
lon(out)=NaN; lat(out)=NaN;
keep=~isnan(lon);
keep=keep | [false; keep(1:end-1)] | [keep(2:end); false];
C.lon=lon(keep); C.lat=lat(keep);
if ~any(isfinite(C.lon))
  warning('edit_grdbat_v3: no coastline point inside the grid domain');
end
return
%
function [x,y]=coast_xy(S)
x=NaN; y=NaN;
C=S.cst;
if strcmp(S.view,'geo')
  if ~isempty(C.lon)
    x=C.lon; y=C.lat;
  elseif ~isempty(C.icst)
    x=interp2(S.lon.',C.icst+1,C.jcst+1);
    y=interp2(S.lat.',C.icst+1,C.jcst+1);
  end
else
  if ~isempty(C.icst)
    x=C.icst; y=C.jcst;
  elseif ~isempty(C.lon)
    x=NaN(size(C.lon)); y=x;
    ok=isfinite(C.lon);
    if any(ok)
      x(ok)=griddata(S.lon(:),S.lat(:),S.mx(:),C.lon(ok),C.lat(ok),'linear');
      y(ok)=griddata(S.lon(:),S.lat(:),S.my(:),C.lon(ok),C.lat(ok),'linear');
    end
  end
end
return
%
function [lon,lat]=read_shapefile(fname)
% Minimal ESRI shapefile reader (polylines/polygons, lon/lat)
fid=fopen(fname,'r','ieee-be');
if fid<0, error(['edit_grdbat_v3: cannot open ',fname]), end
if fread(fid,1,'int32')~=9994
  fclose(fid); error(['edit_grdbat_v3: ',fname,' is not a shapefile'])
end
fseek(fid,24,'bof'); flen=2*fread(fid,1,'int32');
fseek(fid,100,'bof');
X={}; Y={};
while ftell(fid)<flen
  hdr=fread(fid,2,'int32',0,'ieee-be');
  if numel(hdr)<2, break, end
  pos=ftell(fid); clen=2*hdr(2);
  t=fread(fid,1,'int32',0,'ieee-le');
  if any(t==[3 5 13 15 23 25])
    fread(fid,4,'double',0,'ieee-le');
    np=fread(fid,1,'int32',0,'ieee-le'); n=fread(fid,1,'int32',0,'ieee-le');
    parts=[fread(fid,np,'int32',0,'ieee-le'); n];
    xy=fread(fid,[2 n],'double',0,'ieee-le');
    for k=1:np
      ii=parts(k)+1:parts(k+1);
      X{end+1}=[xy(1,ii) NaN]; Y{end+1}=[xy(2,ii) NaN];
    end
  end
  fseek(fid,pos+clen,'bof');
end
fclose(fid);
lon=[X{:}]'; lat=[Y{:}]';
if isempty(lon), lon=NaN; lat=NaN; end
return
%
function [lon,lat]=gshhs_coast(S,res)
lon0=min(S.lon(:)); lon1=max(S.lon(:));
lat0=min(S.lat(:)); lat1=max(S.lat(:));
dl=0.1*max(lon1-lon0,lat1-lat0);
m_proj('mercator','lon',[lon0-dl lon1+dl],'lat',[max(lat0-dl,-89) min(lat1+dl,89)]);
f=[tempname(),'.mat'];
feval(['m_gshhs_',res],'save',f);
D=load(f);
delete(f);
lon=D.ncst(:,1); lat=D.ncst(:,2);
return
%
function set_coast(fig,C)
S=guidata(fig);
S.cst=C;
[x,y]=coast_xy(S);
set(S.hcst,'XData',x,'YData',y);
guidata(fig,S);
return
%
function cb_coastfile(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
[fn,pth]=uigetfile({'*.mat;*.shp;*.dat;*.txt','Coastline (*.mat,*.shp,*.dat,*.txt)'},...
                   'Select a coastline file');
if isequal(fn,0), return, end
S.coastfile=fullfile(pth,fn); guidata(fig,S);
set_coast(fig,read_coast(S.coastfile,S));
return
%
function cb_shapefile(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
[fn,pth]=uigetfile('*.shp','Select a coastline shapefile (lon/lat)');
if isequal(fn,0), return, end
S.coastfile=fullfile(pth,fn); guidata(fig,S);
set_coast(fig,read_coast(S.coastfile,S));
return
%
function cb_gshhs(src,~,res)
fig=ancestor(src,'figure'); S=guidata(fig);
if isempty(S.lon), return, end
set_status(fig,'Reading GSHHS coastline...'); drawnow
try
  [lon,lat]=gshhs_coast(S,res);
  set_coast(fig,set_coast_lonlat(S.cst,lon,lat,S));
  set_status(fig,'');
catch err
  errordlg(['GSHHS coastline: ',err.message],S.figname);
end
return
%
function cb_nocoast(src,~)
fig=ancestor(src,'figure');
set_coast(fig,struct('lon',[],'lat',[],'icst',[],'jcst',[]));
return
%
%---------------------------------------------------------------------
% Edition
%---------------------------------------------------------------------
%
function S=push_undo(S)
S.undo{end+1}=struct('h',S.h,'mask',S.mask,'last',S.last);
if numel(S.undo)>S.maxundo, S.undo(1)=[]; end
return
%
function h=apply_op(S,h)
v=S.value;
switch S.op
  case 1, h(:)=v;
  case 2, h=h+v;
  case 3, h=h*v;
  case 4, h=max(h,v);
  case 5, h=min(h,v);
end
return
%
function S=paint(S,p)
[i,j]=p2ij(S,p);
r=(S.brush-1)/2;
c=false(S.Lp,S.Mp);
c(max(1,i-r):min(S.Lp,i+r),max(1,j-r):min(S.Mp,j+r))=true;
c=c & ~S.touched & editable(S);
if ~any(c(:)), return, end
if S.op<=5
  S.h(c)=apply_op(S,S.hstart(c));
elseif S.op>=7
  S.mask(c)=(S.op==8);
end
S.touched=S.touched | c;
return
%
function e=editable(S)
% cells that the current operation can change
if S.op>=7
  e=true(S.Lp,S.Mp);                  % mask operations: any cell
elseif S.op==6 || ~S.editland
  e=S.mask>0;                         % sea cells only
else
  e=true(S.Lp,S.Mp);                  % h operations on land too
end
return
%
function [S,msg]=apply_sel(S,sel,pushed)
%
% Apply the operation to the editable cells of SEL (one undo level)
%
msg='';
sel=sel & editable(S);
if ~any(sel(:))
  if pushed, S.undo(end)=[]; end
  msg='No editable cell selected (land cells: check "Edit h on land cells too")';
  return
end
if ~pushed, S=push_undo(S); end
if S.op==6
  [S,msg]=smooth_area(S,sel);
elseif S.op>=7
  [S,msg]=set_mask(S,sel,S.op==8,S.mask);
else
  S.h(sel)=apply_op(S,S.h(sel));
  msg=sprintf('%s (%g m): %d cells',S.ops{S.op},S.value,sum(sel(:)));
  nneg=sum(S.h(sel)<=0);
  if nneg>0
    msg=sprintf('%s  - WARNING: h<=0 in %d cells',msg,nneg);
  end
end
S.last=sel;
S.changed=is_changed(S);
return
%
function r=rx0_pairs(h,sea,R)
%
% Maximum rx0=|h1-h2|/(h1+h2) of the neighbour sea pairs with at least
% one cell in R
%
r=0;
a=h(1:end-1,:); b=h(2:end,:);
v=sea(1:end-1,:) & sea(2:end,:) & (R(1:end-1,:) | R(2:end,:));
if any(v(:)), r=max(r,max(abs(a(v)-b(v))./abs(a(v)+b(v)))); end
a=h(:,1:end-1); b=h(:,2:end);
v=sea(:,1:end-1) & sea(:,2:end) & (R(:,1:end-1) | R(:,2:end));
if any(v(:)), r=max(r,max(abs(a(v)-b(v))./abs(a(v)+b(v)))); end
return
%
function r=rx0_cell(S,i,j)
r=NaN;
if ~S.mask(i,j), return, end
r=0;
for d=[-1 0;1 0;0 -1;0 1]'
  ii=i+d(1); jj=j+d(2);
  if ii>=1 && ii<=S.Lp && jj>=1 && jj<=S.Mp && S.mask(ii,jj)
    r=max(r,abs(S.h(i,j)-S.h(ii,jj))/abs(S.h(i,j)+S.h(ii,jj)));
  end
end
return
%
function [S,msg]=smooth_area(S,R)
%
% Local smoothing of the sea cells of R: passes of a 5-point filter on
% log(h) inside R (cells outside R are fixed) until rx0 <= rmax for all
% the neighbour pairs touching R (at least 2 passes, at most 1000)
%
sea=S.mask>0;
R=R & sea;
if ~any(R(:)), msg='Nothing to smooth'; return, end
[I,J]=find(R);
i1=max(min(I)-1,1); i2=min(max(I)+1,S.Lp);
j1=max(min(J)-1,1); j2=min(max(J)+1,S.Mp);
hb=S.h(i1:i2,j1:j2); sb=sea(i1:i2,j1:j2); Rb=R(i1:i2,j1:j2);
r0=rx0_pairs(hb,sb,Rb);
uselog=all(hb(sb)>0);
x=hb;
if uselog, x(sb)=log(hb(sb)); end
[L,M]=size(x);
P=zeros(L+2,M+2); Q=P;
Q(2:end-1,2:end-1)=sb;
n=Q(1:end-2,2:end-1)+Q(3:end,2:end-1)+Q(2:end-1,1:end-2)+Q(2:end-1,3:end);
upd=Rb & n>0;
maxit=1000;
for it=1:maxit
  P(2:end-1,2:end-1)=x.*sb;
  s=P(1:end-2,2:end-1)+P(3:end,2:end-1)+P(2:end-1,1:end-2)+P(2:end-1,3:end);
  xo=x(upd);
  x(upd)=0.5*xo+0.5*s(upd)./n(upd);
  hn=hb;                                % cells outside R: unchanged
  if uselog, hn(upd)=exp(x(upd)); else, hn(upd)=x(upd); end
  if it>=2
    r1=rx0_pairs(hn,sb,Rb);
    if r1<=S.rmax, break, end
    if max(abs(x(upd)-xo))<1e-7*max(1,max(abs(xo))), break, end   % converged
  end
end
S.h(i1:i2,j1:j2)=hn;
msg=sprintf('Smoothed %d cells: rx0 max %.3f -> %.3f (%d passes)',sum(R(:)),r0,r1,it);
if r1>S.rmax
  msg=[msg,sprintf('  - rx0 > %.2f: increase the width',S.rmax)];
end
return
%
function D=dilate(R,w)
if w<=0, D=R; return, end
D=conv2(double(R),ones(2*w+1),'same')>0;
return
%
function cb_smooth(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if ~any(S.last(:)), return, end
last=S.last;
S=push_undo(S);
[S,msg]=smooth_area(S,dilate(last,S.width));
S.last=last;                         % same area if smoothed again
S.changed=is_changed(S);
guidata(fig,S); refresh_map(fig); set_status(fig,msg);
return
%
%---------------------------------------------------------------------
% Panel callbacks
%---------------------------------------------------------------------
%
function set_tool(src,~,k)
fig=ancestor(src,'figure'); S=guidata(fig);
S=cancel_action(S);
S.tool=k;
for n=1:3, set(S.htool(n),'Value',n==k); end
guidata(fig,S); set_status(fig,hint(S));
return
%
function set_brush(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=get(src,'String'); S.brush=str2double(v{get(src,'Value')});
guidata(fig,S);
return
%
function set_op(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S.op=get(src,'Value');
guidata(fig,S); update_value(fig); set_status(fig,hint(S));
return
%
function set_width(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=get(src,'String'); S.width=str2double(v{get(src,'Value')});
guidata(fig,S);
return
%
function cb_rmax(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=str2double(get(src,'String'));
if isfinite(v) && v>0 && v<1, S.rmax=v; end
set(src,'String',num2str(S.rmax));
guidata(fig,S);
return
%
function cb_value(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
v=str2double(get(src,'String'));
if isfinite(v), S.value=v; end
guidata(fig,S); update_value(fig);
return
%
function set_value(fig,v)
S=guidata(fig); S.value=v; guidata(fig,S); update_value(fig);
return
%
function set_range(fig,cmin,cmax)
S=guidata(fig);
if isfinite(cmin) && isfinite(cmax) && cmax>cmin
  S.cmin=cmin; S.cmax=cmax;
end
set(S.hcmin,'String',num2str(S.cmin)); set(S.hcmax,'String',num2str(S.cmax));
set(S.hcbar,'YData',[S.cmin S.cmax],'CData',reshape(S.cmap,[size(S.cmap,1) 1 3]));
set(S.cax,'YLim',[S.cmin S.cmax]);
guidata(fig,S); update_value(fig); refresh_map(fig);
return
%
function cb_range(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
set_range(fig,str2double(get(S.hcmin,'String')),str2double(get(S.hcmax,'String')));
return
%
function cb_auto(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
sea=S.h(S.mask>0);
if isempty(sea), sea=S.h(:); end
c0=min(sea); c1=max(sea);
if ~(c1>c0), c1=c0+1; end
set_range(fig,c0,c1);
return
%
function cb_cmap(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S.cmapk=get(S.hcmapk,'Value'); S.cmaprev=get(S.hcmaprev,'Value');
S.cmap=make_cmap(S);
guidata(fig,S);
set_range(fig,S.cmin,S.cmax);
return
%
%---------------------------------------------------------------------
% Mouse and keyboard
%---------------------------------------------------------------------
%
function p=cur_point(ax)
cp=get(ax,'CurrentPoint');
p=cp(1,1:2);
return
%
function r=inside(S,p)
xl=xlim(S.ax); yl=ylim(S.ax);
r=p(1)>=xl(1) && p(1)<=xl(2) && p(2)>=yl(1) && p(2)<=yl(2) && ...
  p(1)>=S.xl(1) && p(1)<=S.xl(2) && p(2)>=S.yl(1) && p(2)<=S.yl(2);
return
%
function r=in_cbar(S,p)
r=p(1)>=0 && p(1)<=1 && p(2)>=S.cmin && p(2)<=S.cmax;
return
%
function S=cancel_action(S)
if strcmp(S.pick,'profile') && size(S.prof,1)<2
  S.prof=zeros(0,2);
end
S.pick='';
[x,y]=prof_xy(S,S.prof);
set(S.hprof,'XData',x,'YData',y);
S.action=''; S.poly=zeros(0,2); S.zoomnext=0;
set(S.hrect,'XData',NaN,'YData',NaN);
set(S.hpoly,'XData',NaN,'YData',NaN);
return
%
function draw_rect(S,p0,p1)
set(S.hrect,'XData',[p0(1) p1(1) p1(1) p0(1) p0(1)],...
            'YData',[p0(2) p0(2) p1(2) p1(2) p0(2)]);
return
%
function cb_down(fig,~)
S=guidata(fig);
pc=cur_point(S.cax);
if in_cbar(S,pc)                              % colour bar: pick a value
  S.action='cbar'; guidata(fig,S);
  set_value(fig,pc(2));
  return
end
p=cur_point(S.ax);
if ~inside(S,p), return, end
msg='';
if ~isempty(S.pick)
  S=pick_down(fig,S,p,get(fig,'SelectionType'));
  guidata(fig,S);
  return
end
switch get(fig,'SelectionType')
  case 'alt'                                  % right click
    if S.tool==3
      if size(S.poly,1)>=3
        [S,msg]=close_poly(S);
      else
        S=cancel_action(S);
      end
    else
      [i,j]=p2ij(S,p);
      if S.mask(i,j) || S.editland
        guidata(fig,S); set_value(fig,S.h(i,j)); S=guidata(fig);
        msg=sprintf('Value = h(%d,%d) = %.2f m',i-1,j-1,S.h(i,j));
      else
        msg='Land cell: no depth taken';
      end
    end
  case 'open'                                 % double click
    if S.tool==3 && size(S.poly,1)>=3
      [S,msg]=close_poly(S);
    end
  case 'normal'                               % left click
    if S.zoomnext
      S.action='zoom'; S.p0=p; draw_rect(S,p,p);
    else
      switch S.tool
        case 1
          S=push_undo(S);
          S.hstart=S.h; S.maskstart=S.mask;
          S.touched=false(S.Lp,S.Mp);
          S=paint(S,p);
          S.action='paint';
        case 2
          S.action='rect'; S.p0=p; draw_rect(S,p,p);
        case 3
          S.action='poly';
          S.poly(end+1,:)=p;
          set(S.hpoly,'XData',S.poly(:,1),'YData',S.poly(:,2));
      end
    end
end
guidata(fig,S);
refresh_map(fig);
if ~isempty(msg), set_status(fig,msg); end
return
%
function cb_move(fig,~)
S=guidata(fig);
if strcmp(S.action,'cbar')
  pc=cur_point(S.cax);
  set_value(fig,min(max(pc(2),S.cmin),S.cmax));
  return
end
p=cur_point(S.ax);
if inside(S,p)
  [i,j]=p2ij(S,p);
  s={sprintf('I,J = %d, %d',i-1,j-1)};
  if ~isempty(S.lon)
    s{end+1}=sprintf('%s = %.4f   %s = %.4f',S.lonname,S.lon(i,j),S.latname,S.lat(i,j));
  end
  if S.mask(i,j)
    s{end+1}=sprintf('h = %.2f m',S.h(i,j));
    if S.h(i,j)~=S.hfile(i,j)
      s{end+1}=sprintf('h in file = %.2f m',S.hfile(i,j));
    end
    s{end+1}=sprintf('rx0 = %.3f',rx0_cell(S,i,j));
  elseif S.editland
    s{end+1}=sprintf('LAND, h = %.2f m',S.h(i,j));
  else
    s{end+1}=sprintf('LAND (h = %.2f m, not edited)',S.h(i,j));
  end
  set(S.hinfo,'String',s);
  set(fig,'Pointer','crosshair');
else
  set(S.hinfo,'String',{'---'});
  set(fig,'Pointer','arrow');
end
switch S.action
  case 'paint'
    if inside(S,p)
      S=paint(S,p); guidata(fig,S); refresh_map(fig);
    end
  case {'rect','zoom'}
    draw_rect(S,S.p0,p);
  case 'poly'
    if ~isempty(S.poly)
      set(S.hpoly,'XData',[S.poly(:,1);p(1)],'YData',[S.poly(:,2);p(2)]);
    end
  case 'box3d'
    draw_rect(S,S.p0,p);
end
if strcmp(S.pick,'profile') && ~isempty(S.prof)
  [x,y]=prof_xy(S,S.prof);
  set(S.hprof,'XData',[x(:);p(1)],'YData',[y(:);p(2)]);
end
return
%
function cb_up(fig,~)
S=guidata(fig);
p=cur_point(S.ax);
msg='';
switch S.action
  case 'cbar'
    S.action='';
  case 'paint'
    S.action='';
    if S.op==6                                % smooth the painted cells
      S.h=S.hstart;
      [S,msg]=apply_sel(S,S.touched,true);
    elseif S.op>=7 && any(S.touched(:))       % mask: fill h of new sea cells
      [S,msg]=set_mask(S,S.touched,S.op==8,S.maskstart);
      S.last=S.touched;
      S.changed=is_changed(S);
    elseif any(S.touched(:))
      S.last=S.touched;
      S.changed=is_changed(S);
      msg=sprintf('%s (%g m): %d cells',S.ops{S.op},S.value,sum(S.touched(:)));
    else
      S.undo(end)=[];                         % nothing changed (land)
    end
    S.touched(:)=false;
  case 'rect'
    if abs(p(1)-S.p0(1))<S.tol && abs(p(2)-S.p0(2))<S.tol    % simple click
      [i,j]=p2ij(S,p);
      sel=false(S.Lp,S.Mp); sel(i,j)=true;
    else
      sel=(S.px-S.p0(1)).*(S.px-p(1))<=0 & (S.py-S.p0(2)).*(S.py-p(2))<=0;
    end
    [S,msg]=apply_sel(S,sel,false);
    S=cancel_action(S);
  case 'box3d'
    if abs(p(1)-S.p0(1))<S.tol && abs(p(2)-S.p0(2))<S.tol    % click: visible area
      xl=xlim(S.ax); yl=ylim(S.ax);
      sel=S.px>=xl(1) & S.px<=xl(2) & S.py>=yl(1) & S.py<=yl(2);
    else
      sel=(S.px-S.p0(1)).*(S.px-p(1))<=0 & (S.py-S.p0(2)).*(S.py-p(2))<=0;
    end
    S=cancel_action(S);
    if any(sel(:))
      [I,J]=find(sel);
      S.blk3d=[min(I) max(I) min(J) max(J)];
      guidata(fig,S); draw_3d(fig); S=guidata(fig);
      msg=sprintf('3D view of I=%d:%d, J=%d:%d',S.blk3d-1);
    else
      msg='3D view: no cell in the box';
    end
  case 'zoom'
    if abs(p(1)-S.p0(1))<S.tol || abs(p(2)-S.p0(2))<S.tol
      zoom_at(S,p,0.5);
    else
      xlim(S.ax,sort([S.p0(1) p(1)])); ylim(S.ax,sort([S.p0(2) p(2)]));
    end
    S=cancel_action(S);
end
guidata(fig,S);
refresh_map(fig);
if ~isempty(msg), set_status(fig,msg); end
return
%
function [S,msg]=close_poly(S)
P=S.poly;
msg='';
if size(P,1)>=3
  sel=inpolygon(S.px,S.py,P([1:end 1],1),P([1:end 1],2));
  [S,msg]=apply_sel(S,sel,false);
end
S=cancel_action(S);
return
%
function zoom_at(S,p,f)
xl=xlim(S.ax); yl=ylim(S.ax);
w=diff(xl)*f/2; h=diff(yl)*f/2;
xn=p(1)+[-w w]; yn=p(2)+[-h h];
xn=min(max(xn,S.xl(1)),S.xl(2)); yn=min(max(yn,S.yl(1)),S.yl(2));
if diff(xn)>S.tol && diff(yn)>S.tol
  xlim(S.ax,xn); ylim(S.ax,yn);
end
return
%
function pan(S,dx,dy)
xl=xlim(S.ax); yl=ylim(S.ax);
sx=dx*diff(xl)/4; sy=dy*diff(yl)/4;
sx=min(max(sx,S.xl(1)-xl(1)),S.xl(2)-xl(2));
sy=min(max(sy,S.yl(1)-yl(1)),S.yl(2)-yl(2));
xlim(S.ax,xl+sx); ylim(S.ax,yl+sy);
return
%
function cb_key(fig,evt)
S=guidata(fig);
ctrl=any(strcmp(evt.Modifier,'control'));
switch evt.Key
  case 'leftarrow',  pan(S,-1,0);
  case 'rightarrow', pan(S,1,0);
  case 'uparrow',    pan(S,0,1);
  case 'downarrow',  pan(S,0,-1);
  case {'add','plus','equal'}
    zoom_at(S,[mean(xlim(S.ax)) mean(ylim(S.ax))],0.5);
  case {'subtract','minus','hyphen'}
    zoom_at(S,[mean(xlim(S.ax)) mean(ylim(S.ax))],2);
  case 'escape'
    S=cancel_action(S); guidata(fig,S); set_status(fig,hint(S));
  case 'return'
    if strcmp(S.pick,'profile')
      S=finish_profile(fig,S); guidata(fig,S);
    elseif S.tool==3
      [S,msg]=close_poly(S); guidata(fig,S); refresh_map(fig);
      if ~isempty(msg), set_status(fig,msg); end
    end
  case 'u'
    cb_undo(fig,[]);
  case 'z'
    if ctrl, cb_undo(fig,[]); end
  case 's'
    cb_save(fig,[]);
end
return
%
%---------------------------------------------------------------------
% Buttons
%---------------------------------------------------------------------
%
function cb_zoomin(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S=cancel_action(S); S.zoomnext=1;
guidata(fig,S); set_status(fig,'Zoom: drag a box (or click)');
return
%
function cb_zoomout(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
xlim(S.ax,S.xl); ylim(S.ax,S.yl);
return
%
function cb_undo(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if ~isempty(S.undo)
  U=S.undo{end}; S.undo(end)=[];
  S.h=U.h; S.mask=U.mask; S.last=U.last;
  S.changed=is_changed(S);
  guidata(fig,S); refresh_map(fig);
  set_status(fig,sprintf('Undo (%d levels left)',numel(S.undo)));
end
return
%
function cb_revert(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if ~is_changed(S), return, end
S=push_undo(S);
S.h=S.hfile; S.mask=S.maskfile; S.last(:)=false; S.changed=0;
guidata(fig,S); refresh_map(fig); set_status(fig,'h and mask of the file restored');
return
%
function cb_save(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
ncid=netcdf.open(S.file,'NC_WRITE');
netcdf.putVar(ncid,netcdf.inqVarID(ncid,'h'),[0 0],size(S.h),S.h);   % (xi,eta)
nm=sum(S.mask(:)~=S.maskfile(:));
if nm>0
  write_masks(ncid,S.mask);
end
netcdf.close(ncid);
n=sum(S.h(:)~=S.hfile(:));
S.hfile=S.h; S.maskfile=S.mask; S.changed=0;
guidata(fig,S); refresh_map(fig);
msg=sprintf('h saved in %s (%d cells changed)',S.file,n);
if nm>0
  msg=sprintf('%s, mask_rho/u/v/psi saved (%d rho cells changed)',msg,nm);
end
set_status(fig,msg); disp(['edit_grdbat_v3: ',msg])
return
%
function ok=ask_save(fig)
S=guidata(fig);
ok=1;
if S.changed
  res=questdlg('The bathymetry/mask has been changed. Save?',S.figname,'Yes','No','Cancel','Yes');
  switch res
    case 'Yes', cb_save(fig,[]);
    case 'No',  disp('edit_grdbat_v3: bathymetry NOT saved');
    otherwise,  ok=0;
  end
end
return
%
function cb_open(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if ~ask_save(fig), return, end
[fn,pth]=uigetfile('*.nc','Select CROCO grid file (bathymetry)...');
if isequal(fn,0), return, end
cf=S.coastfile;
delete(fig);
edit_grdbat_v3([],[],[pth,fn],cf);
return
%
function cb_exit(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
if isempty(S), delete(fig); return, end
if ~ask_save(fig), return, end
for h=[S.hproffig S.h3dfig]
  if ishghandle(h), delete(h); end
end
delete(fig);
return
%
%---------------------------------------------------------------------
% Land/sea mask
%---------------------------------------------------------------------
%
function [S,msg]=set_mask(S,sel,val,mask0)
%
% mask_rho(sel)=val. The cells that become sea (land in MASK0) get h
% from their sea neighbours if "New sea cells: h from neighbours" is on
%
S.mask(sel)=val;
newsea=sel & mask0==0 & S.mask>0;
msg=sprintf('Mask: %d cells set to %s',sum(sel(:)),ifelse(val,'sea','land'));
if val && S.fillh && any(newsea(:))
  S=fill_h(S,newsea);
  msg=sprintf('%s (h of %d new sea cells from the neighbours)',msg,sum(newsea(:)));
end
return
%
function S=fill_h(S,cells)
%
% h of CELLS = mean of the known sea neighbours (4 directions), filled
% from the edges of CELLS inwards
%
known=S.mask>0 & ~cells;
todo=cells;
[L,M]=size(S.h);
P=zeros(L+2,M+2); Q=P;
for it=1:max(L,M)
  P(2:end-1,2:end-1)=S.h.*known; Q(2:end-1,2:end-1)=known;
  s=P(1:end-2,2:end-1)+P(3:end,2:end-1)+P(2:end-1,1:end-2)+P(2:end-1,3:end);
  n=Q(1:end-2,2:end-1)+Q(3:end,2:end-1)+Q(2:end-1,1:end-2)+Q(2:end-1,3:end);
  can=todo & n>0;
  if ~any(can(:)), break, end
  S.h(can)=s(can)./n(can);
  known=known | can; todo=todo & ~can;
end
return
%
function write_masks(ncid,rmask)
%
% mask_rho and the U-, V-, PSI-masks (uvp_masks) in the open file
% (variables defined if missing)
%
[Lp,Mp]=size(rmask); L=Lp-1; M=Mp-1;
umask=rmask(2:Lp,:).*rmask(1:L,:);
vmask=rmask(:,2:Mp).*rmask(:,1:M);
pmask=rmask(1:L,1:M).*rmask(2:Lp,1:M).*rmask(1:L,2:Mp).*rmask(2:Lp,2:Mp);
names={'mask_rho','mask_u','mask_v','mask_psi'};
dims={{'xi_rho','eta_rho'},{'xi_u','eta_u'},{'xi_v','eta_v'},{'xi_psi','eta_psi'}};
lnames={'mask on RHO-points','mask on U-points','mask on V-points','mask on PSI-points'};
vals={rmask,umask,vmask,pmask};
redef=0;
for k=1:4
  try
    netcdf.inqVarID(ncid,names{k});
  catch
    if ~redef, netcdf.reDef(ncid); redef=1; end
    d1=netcdf.inqDimID(ncid,dims{k}{1}); d2=netcdf.inqDimID(ncid,dims{k}{2});
    vid=netcdf.defVar(ncid,names{k},'NC_DOUBLE',[d1 d2]);
    netcdf.putAtt(ncid,vid,'long_name',lnames{k});
    netcdf.putAtt(ncid,vid,'option_0','land');
    netcdf.putAtt(ncid,vid,'option_1','water');
  end
end
if redef, netcdf.endDef(ncid); end
for k=1:4
  netcdf.putVar(ncid,netcdf.inqVarID(ncid,names{k}),[0 0],size(vals{k}),vals{k});
end
return
%
function cb_islands(src,~)
%
% Remove the islands: land patches (8-connected) that do not touch the
% grid boundary, with at most "max cells" cells
%
fig=ancestor(src,'figure'); S=guidata(fig);
nmax=str2double(get(S.hislmax,'String'));
if ~(nmax>0), nmax=Inf; set(S.hislmax,'String','all'); end
land=S.mask==0;
reach=false(S.Lp,S.Mp);
reach([1 end],:)=land([1 end],:); reach(:,[1 end])=land(:,[1 end]);
for it=1:numel(land)                  % land connected to the boundary
  nr=(conv2(double(reach),ones(3),'same')>0) & land;
  if isequal(nr,reach), break, end
  reach=nr;
end
isl=land & ~reach;
if ~any(isl(:))
  set_status(fig,'No island (all the land cells are connected to the grid boundary)'); return
end
lab=zeros(S.Lp,S.Mp); lab(isl)=find(isl);
P=zeros(S.Lp+2,S.Mp+2);
for it=1:numel(land)                  % label of each island: max index
  P(2:end-1,2:end-1)=lab;
  m=lab;
  for di=-1:1
    for dj=-1:1
      m=max(m,P(2+di:end-1+di,2+dj:end-1+dj));
    end
  end
  new=lab; new(isl)=m(isl);
  if isequal(new,lab), break, end
  lab=new;
end
[ids,~,k]=unique(lab(isl));
sz=accumarray(k,1);
rm=ids(sz<=nmax);
remove=isl & ismember(lab,rm);
if ~any(remove(:))
  set_status(fig,sprintf('%d islands, none with <= %g cells',numel(ids),nmax)); return
end
S=push_undo(S);
[S,msg]=set_mask(S,remove,1,S.mask);
S.last=remove;
S.changed=is_changed(S);
guidata(fig,S); refresh_map(fig);
set_status(fig,sprintf('%d islands removed (%d cells), %d kept. %s',numel(rm),sum(remove(:)),...
           numel(ids)-numel(rm),msg));
return
%
function cb_editland(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S.editland=get(src,'Value');
guidata(fig,S); refresh_map(fig);
return
%
function cb_fill(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S.fillh=get(src,'Value');
guidata(fig,S);
return
%
%---------------------------------------------------------------------
% Profile and 3D view
%---------------------------------------------------------------------
%
function S=pick_down(fig,S,p,type)
if strcmp(S.pick,'profile')
  switch type
    case 'normal'
      [i,j]=p2ij(S,p);
      v=[i-1 j-1];
      if isempty(S.prof) || any(S.prof(end,:)~=v)
        S.prof(end+1,:)=v;
      end
      [x,y]=prof_xy(S,S.prof);
      set(S.hprof,'XData',x,'YData',y);
    case {'alt','open'}
      S=finish_profile(fig,S);
  end
elseif strcmp(S.pick,'3d') && strcmp(type,'normal')
  S.action='box3d'; S.p0=p; draw_rect(S,p,p);
end
return
%
function S=finish_profile(fig,S)
if size(S.prof,1)<2
  S=cancel_action(S); set_status(fig,'Profile: at least 2 points'); return
end
S.pick='';
[x,y]=prof_xy(S,S.prof);
set(S.hprof,'XData',x,'YData',y);
guidata(fig,S);
draw_profile(fig);
S=guidata(fig);
set_status(fig,sprintf('Profile with %d points (updated after each edit)',size(S.prof,1)));
return
%
function [x,y]=prof_xy(S,V)
% profile vertices (0-based I,J) in the coordinates of the current view
if isempty(V), x=NaN; y=NaN; return, end
if strcmp(S.view,'geo')
  k=sub2ind([S.Lp S.Mp],V(:,1)+1,V(:,2)+1);
  x=S.lon(k); y=S.lat(k);
else
  x=V(:,1); y=V(:,2);
end
return
%
function [d,idx,unit]=profile_samples(S)
%
% Points along the profile (4 per cell), nearest cell and distance
%
V=S.prof; F=zeros(0,2);
for k=1:size(V,1)-1
  dv=V(k+1,:)-V(k,:);
  n=max(1,ceil(4*max(abs(dv))));
  t=(0:n)'/n;
  if k>1, t=t(2:end); end
  F=[F; V(k,:)+t*dv];
end
idx=sub2ind([S.Lp S.Mp],round(F(:,1))+1,round(F(:,2))+1);
if ~isempty(S.lon)
  lo=interp2(S.lon.',F(:,1)+1,F(:,2)+1)*pi/180;
  la=interp2(S.lat.',F(:,1)+1,F(:,2)+1)*pi/180;
  a=sin(diff(la)/2).^2+cos(la(1:end-1)).*cos(la(2:end)).*sin(diff(lo)/2).^2;
  d=[0; cumsum(2*6371*asin(min(1,sqrt(a))))];
  unit='Distance (km)';
else
  d=[0; cumsum(hypot(diff(F(:,1)),diff(F(:,2))))];
  unit='Distance (grid cells)';
end
return
%
function draw_profile(fig)
S=guidata(fig);
if size(S.prof,1)<2, return, end
hf=S.hproffig;
if isempty(hf) || ~ishghandle(hf)
  cur=get(0,'CurrentFigure');
  hf=figure('Name','Bathymetry profile','NumberTitle','off','IntegerHandle','off',...
            'tag','edit_grdbat_v3_profile','Units','normalized','Position',[.15 .1 .55 .4]);
  axes('Parent',hf,'Tag','profax');
  S.hproffig=hf; guidata(fig,S);
  if ~isempty(cur) && ishghandle(cur), set(0,'CurrentFigure',cur); end
end
ax=findobj(hf,'Tag','profax');
cla(ax); hold(ax,'on');
[d,idx,unit]=profile_samples(S);
h=S.h(idx); h0=S.hfile(idx); m=S.mask(idx);
z=-h;
yb=min(z)-0.05*max(1,max(z)-min(z));
try, hl=gobjects(0); catch, hl=[]; end   % graphics array (Matlab), [] (Octave)
lg={};
patch([d; flipud(d)],[z; yb*ones(size(z))],[0.85 0.75 0.6],'EdgeColor','none','Parent',ax);
plot(ax,[d(1) d(end)],[0 0],'k:');
if any(h~=h0)
  hl(end+1)=plot(ax,d,-h0,'r--','LineWidth',1); lg{end+1}='h in file';
end
hl(end+1)=plot(ax,d,z,'b-','LineWidth',1.5); lg{end+1}='h (edited)';
zl=z; zl(m>0)=NaN;
if any(m==0)
  hl(end+1)=plot(ax,d,zl,'-','Color',[0 0.6 0],'LineWidth',4); lg{end+1}='land (mask=0)';
end
% vertices of the section
dv=d(1+[0; cumsum(max(1,ceil(4*max(abs(diff(S.prof)),[],2))))]);
plot(ax,dv,interp1(d,z,dv),'mo','MarkerSize',6,'LineWidth',1.5);
hold(ax,'off');
set(ax,'Box','on','Layer','top');
grid(ax,'on');
xlim(ax,[d(1) max(d(end),d(1)+eps)]); ylim(ax,[yb max(0,max(z))+0.02*(max(z)-yb)]);
xlabel(ax,unit); ylabel(ax,'z = -h (m)');
title(ax,sprintf('Section I,J = (%d,%d) -> (%d,%d)    h min/max = %.1f / %.1f m',...
      S.prof(1,:),S.prof(end,:),min(h(m>0 | all(m==0))),max(h(m>0 | all(m==0)))));
legend(ax,hl,lg,'Location','southeast');
return
%
function cb_profile(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S=cancel_action(S);
S.pick='profile'; S.prof=zeros(0,2);
set(S.hprof,'XData',NaN,'YData',NaN);
guidata(fig,S); set_status(fig,hint(S));
return
%
function cb_3d(src,~)
fig=ancestor(src,'figure'); S=guidata(fig);
S=cancel_action(S);
S.pick='3d';
guidata(fig,S); set_status(fig,hint(S));
return
%
function draw_3d(fig)
S=guidata(fig);
b=S.blk3d;
if isempty(b), return, end
hf=S.h3dfig; new=0;
if isempty(hf) || ~ishghandle(hf)
  cur=get(0,'CurrentFigure');
  hf=figure('Name','Bathymetry 3D','NumberTitle','off','IntegerHandle','off',...
            'tag','edit_grdbat_v3_3d','ToolBar','figure','Units','normalized',...
            'Position',[.2 .15 .55 .6]);
  axes('Parent',hf,'Tag','ax3d','Units','normalized','Position',[.08 .12 .75 .8]);
  uicontrol(hf,'Style','text','Units','normalized','Position',[.01 .01 .2 .05],...
            'String','Vertical exaggeration','HorizontalAlignment','right');
  uicontrol(hf,'Style','popupmenu','Units','normalized','Position',[.22 .01 .12 .055],'Tag','exag',...
            'String',{'auto','1','5','10','20','50','100','200','500','1000'},'Value',1,...
            'Callback',@(s,e) draw_3d(fig));
  uicontrol(hf,'Style','pushbutton','Units','normalized','Position',[.36 .01 .12 .055],...
            'String','Refresh','Callback',@(s,e) draw_3d(fig));
  S.h3dfig=hf; guidata(fig,S); new=1;
  if ~isempty(cur) && ishghandle(cur), set(0,'CurrentFigure',cur); end
end
ax=findobj(hf,'Tag','ax3d');
st=max(1,ceil(max(b(2)-b(1)+1,b(4)-b(3)+1)/300));     % at most ~300x300 cells
ii=unique([b(1):st:b(2) b(2)]); jj=unique([b(3):st:b(4) b(4)]);
if numel(ii)<2 || numel(jj)<2
  set_status(fig,'3D view: the area must have at least 2x2 cells'); return
end
geo=~isempty(S.lon);
if geo
  X=S.lon(ii,jj); Y=S.lat(ii,jj);
else
  X=S.mx(ii,jj); Y=S.my(ii,jj);
end
Z=-S.h(ii,jj);
rgb=h2rgb(S); C=rgb(ii,jj,:);
vw=get(ax,'View');
cla(ax);
hs=surface(X,Y,Z,C,'Parent',ax,'EdgeColor','none','FaceColor','interp');
try
  set(hs,'FaceLighting','gouraud','AmbientStrength',0.55,'DiffuseStrength',0.6,...
         'SpecularStrength',0.1);
  light('Parent',ax,'Position',[-1 1 2],'Style','infinite');
end
if geo && ~isempty(S.cst.lon)                         % coastline at z=0
  cx=S.cst.lon; cy=S.cst.lat;
  out=cx<min(X(:)) | cx>max(X(:)) | cy<min(Y(:)) | cy>max(Y(:));
  cx(out)=NaN; cy(out)=NaN;
  line(cx,cy,zeros(size(cx)),'Parent',ax,'Color','k','LineWidth',1);
end
zr=max(Z(:))-min(Z(:)); if ~(zr>0), zr=1; end
v=get(findobj(hf,'Tag','exag'),'String'); v=v{get(findobj(hf,'Tag','exag'),'Value')};
if geo
  cs=cos(mean(Y(:))*pi/180);
  xyr=max((max(X(:))-min(X(:)))*cs,max(Y(:))-min(Y(:)));
  if strcmp(v,'auto'), dz=zr/(0.35*xyr); else, dz=111e3/str2double(v); end
  set(ax,'DataAspectRatio',[1/cs 1 dz]);
  ex=sprintf('vertical exaggeration x%.0f',111e3/dz);
  xlabel(ax,'Longitude'); ylabel(ax,'Latitude');
else
  dz=zr/(0.35*max(numel(ii),numel(jj))*st);
  set(ax,'DataAspectRatio',[1 1 dz]);
  ex='z scaled to the area';
  xlabel(ax,'I'); ylabel(ax,'J');
end
zlabel(ax,'z = -h (m)');
title(ax,sprintf('I = %d:%d, J = %d:%d   (%s)',b-1,ex));
set(ax,'Box','on'); grid(ax,'on');
axis(ax,'tight');
set(hf,'Colormap',S.cmap); caxis(ax,[S.cmin S.cmax]);
if ~new && ~isequal(vw,[0 90])
  set(ax,'View',vw);                                   % keep the rotation
else
  view(ax,-35,40);
end
if new
  try
    cb=colorbar(ax); ylabel(cb,'h (m)');
  end
  try
    rotate3d(hf,'on');
  end
end
return
%
%---------------------------------------------------------------------
% Open boundaries
%---------------------------------------------------------------------
%
function cb_obc(src,~)
%
% For each checked open boundary (S: j=1, E: i=Lp, N: j=Mp, W: i=1),
% the N cells next to the boundary get the depth of the cell N+1 of the
% same line, so that the inflow does not meet abrupt bathymetry changes.
% S and N are done first, then E and W: the corner blocks get the depth
% of the cell (N+1,N+1). Land cells are not changed (unless "Edit h on
% land cells too"); a line whose cell N+1 is land is skipped.
%
fig=ancestor(src,'figure'); S=guidata(fig);
n=round(str2double(get(S.hobcn,'String')));
if ~(n>=1), n=10; end
set(S.hobcn,'String',num2str(n));
side=arrayfun(@(h) get(h,'Value'),S.hobcs);
names={'S','E','N','W'};
if ~any(side)
  set_status(fig,'Open boundaries: no boundary checked'); return
end
if (any(side([1 3])) && n+1>S.Mp) || (any(side([2 4])) && n+1>S.Lp)
  set_status(fig,sprintf('Open boundaries: the grid has less than %d cells',n+1)); return
end
ed=S.mask>0 | S.editland;          % cells that can be changed / used
h=S.h;
ch=false(S.Lp,S.Mp); skip=0;
for k=[1 3 2 4]                    % S, N, then E, W
  if ~side(k), continue, end
  switch k
    case 1, band=1:n;            from=n+1;        dim=2;
    case 3, band=S.Mp-n+1:S.Mp;  from=S.Mp-n;     dim=2;
    case 2, band=S.Lp-n+1:S.Lp;  from=S.Lp-n;     dim=1;
    case 4, band=1:n;            from=n+1;        dim=1;
  end
  if dim==2
    v=h(:,from); ok=ed(:,from);
    for b=band
      c=ed(:,b) & ok & h(:,b)~=v;
      h(c,b)=v(c); ch(c,b)=true;
    end
    skip=skip+sum(~ok & any(ed(:,band),2));
  else
    v=h(from,:); ok=ed(from,:);
    for b=band
      c=ed(b,:) & ok & h(b,:)~=v;
      h(b,c)=v(c); ch(b,c)=true;
    end
    skip=skip+sum(~ok & any(ed(band,:),1));
  end
end
done=strjoin(names(side>0),',');
if ~any(ch(:))
  set_status(fig,sprintf('Open boundaries %s: nothing to change (already flat over %d cells)',done,n));
  return
end
S=push_undo(S);
S.h=h; S.last=ch;
S.changed=is_changed(S);
guidata(fig,S); refresh_map(fig);
msg=sprintf('Open boundaries %s: h of cell %d copied to the %d cells next to the boundary (%d cells changed)',...
            done,n+1,n,sum(ch(:)));
if skip>0
  msg=sprintf('%s, %d lines skipped (land at cell %d)',msg,skip,n+1);
end
set_status(fig,msg);
return
%
%---------------------------------------------------------------------
% cmocean colormaps (cmocean v3.0.3, MIT License, Copyright (c) 2015
% Kristen M. Thyng; Thyng et al. 2016, Oceanography 29(3):9-13):
% 64 nodes, linearly interpolated
%---------------------------------------------------------------------
%
function cm=cmo_map(name,n)
switch name
  case 'deep'
    h=['fdfeccf5fac7edf7c3e5f4beddf2bad4efb6ccecb3c4e9afbbe6acb2e3aaaae0a8a1dda698daa490d7a487d4a37fd1a3' ...
       '76cda370c9a36ac5a465c2a461bea45dbaa45ab6a457b1a455ada352a9a351a5a24fa1a24d9da14c99a04a959f49919e' ...
       '478c9d46889c45849b44809b427c9a4178994074983f70973f6c963e68963e64953e60943e5b933e57913f538f404e8d' ...
       '41498841458341417d413e76403b703f38693d35623b325c392f55372c4f35294932264330233d2d20372b1d32281a2c'];
  case 'ice'
    h=['0406130709180b0d1e0f102413132a17172f1a1a351e1d3b21204125234728264e2b29542e2c5a312f6133326736356e' ...
       '3939763a3d7d3c40843d448a3e48903f4b963f509b3f54a03f58a43e5da83e61ab3e66ae3e6ab03f6fb34073b44178b6' ...
       '437db84581ba4786bb4a8abd4d8ebe5092c05397c1569bc35a9fc45ea3c661a8c765acc96ab0cb6eb4cc73b9ce78bdd0' ...
       '7fc2d285c6d38bcad592ced799d2d9a0d6dca8d9deafdde1b7e1e4bee5e7c6e8ebcdecefd5f0f2dcf4f6e3f9faeafdfd'];
  case 'haline'
    h=['2a186c2b19752d1a7f2e1c892e1d932d209c2a25a1252da32034a21b3aa016409d12459b0f4a980d4f960c53940d5792' ...
       '105c9013608e16638d19678c1d6b8b206e8b23718a26758a2978892c7c892f7f89318288348688368988388d883a9087' ...
       '3d95873f9986419c8543a08446a48348a7824bab814eae7f51b27d55b67b5ab9785ebd7563c07269c46f70c76c77ca68' ...
       '80ce6489d06192d35e9bd55ca5d75cafd95db8db60c1dd64cadf69d2e16fdae375e1e57ce9e783f0ea8af7ec92fdef9a'];
  case 'dense'
    h=['e6f1f1dfedeed8eaecd1e7eacbe4e8c4e0e6bedde5b7dae4b1d6e3abd3e3a5cfe29fcce29ac8e294c5e28fc1e28abde3' ...
       '85b8e381b4e37eb0e47bace478a8e476a4e5759fe5749be47396e47391e3748de27488e17583df757edd7679da7775d7' ...
       '786fd3786ad07965cc7961c8795cc37958bf7953ba794fb5784baf7747aa7642a5753e9f743b9973379371338d6f2f87' ...
       '6d2b7f6b287968247266216c631f65601c5e5d1a585a185156164b5215444e133e49123845113340102e3b0f29360e24'];
  otherwise
    error(['edit_grdbat_v3: unknown cmocean colormap ',name])
end
c=reshape(hex2dec(reshape(h,2,[])'),3,[])'/255;
cm=interp1(linspace(0,1,size(c,1)),c,linspace(0,1,n));
cm=min(max(cm,0),1);
return
