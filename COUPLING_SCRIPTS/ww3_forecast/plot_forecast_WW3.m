%=========================================================================
% Read and Plot WW3 outputs 
%
% P. Marchesiello IRD 2009
%=========================================================================
clear all;
close all;
ww3tools_param
%
dirin     = [pwd,'/OUTPUT/GRID'];
%dirout    = 'pmarches@emae:/data/www/users/marchesiello/FIG_WW3';
%coastfile = '/data/ROMS/SWPAC/coastline_f.mat';
%
lonw=ll_lon; lone=ur_lon; lats=ll_lat; latn=ur_lat;  
%
res=2;     % subgrid for wind vectors
cff_vec=0.5; % modulation of vector length
col_vec='k';
%
% Time Zone defined as Local time = UTC + timezone 
% (watch for seasonal changes)
timezone      =tzone;                      % timezone of study site
%
cmin0=0; cint0=0.25; cmax0= 5; % hs
cmin1=0; cint1=1.00; cmax1=20; % tp
%
level=1;
%========================= END USER'S CHANGES =============================

%%addpath('/home/pmarches/matlab/palettes')
%
% Read data and compute time vector
%
d=datestr(now,31);
date0=[d(3:4),d(6:7),d(9:10)];
datenum0=datenum(date);
%
fname=[dirin,'/ww3.',date0,'00.hs'];
[lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(fname);

[x,y]=meshgrid(lon,lat);
[X,Y]=meshgrid([lonw:res:lone],[lats:res:latn]);

spval=-999; %=nodata
%%load Bright.pal
%====================================================================
%                        TEMPORAL ITERATION
%====================================================================
ip=0;
for i0=1:24;
 
%
% Find current date
%
 ip=ip+1;
 d=datestr(datenum0+(ip-1)*6/24,31);
 date1=[d(3:4),d(6:7),d(9:10),d(12:13)];
 localhour=num2str(str2num(d(12:13))+timezone);
 d1=datestr(datenum0+(ip-1)*6/24,1);
 datelocal=[d1(1:11),' ',localhour,d(14:19),' LT'];
 disp([' ... reading files for date ',d]);
%
% read WW3 output files
%
 fname=[dirin,'/ww3.',date1,'.hs'];
 [lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(fname);
 hs=mat1;
 hs=get_missing_val(lon,lat,hs);
%
 fname=[dirin,'/ww3.',date1,'.dir'];
 [lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(fname);
 angle=mat1;
 angle=pi/180*angle; %+pi/2;
%
 %X=x;Y=y;A=angle;H=hs;
 A=griddata(x,y,angle,X,Y,'linear',{'QJ'});
 H=griddata(x,y,hs,X,Y,'linear',{'QJ'});
 U=-sin(A); %U=H.*U;
 V=-cos(A); %V=H.*V;

% fname=[dirin,'/ww3.',date1,'.fp'];
% [lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(fname);
% fp=mat1;
% tp=1./fp;

% fname=[dirin,'/ww3.',date1,'.dp'];
% [lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(fname);
% dp=mat1;
% dp=pi/180*dp;
% DP=griddata(x,y,dp,X,Y);
% FP=griddata(x,y,fp,X,Y);
% UP=-sin(DP); 
% VP=-cos(DP); 

%
% plot significant wave height
%
 lx=30; ly=30;
 figure('units','centimeters','position', ...
          [0 0 lx ly],'paperpositionmode','auto')
 subplot('position',[0 0.15 .85 .75]);
 m_proj('mercator','lon',[lonw lone],'lat',[lats latn]);
 set(gca,'fontsize',15)
 %m_contourf(lon,lat,hs,[cmin0:cint0:cmax0],'k','Linestyle',':'); hold on;
 contourf(lon,lat,hs,[cmin0:cint0:cmax0],'k','Linestyle',':'); hold on;
 % quiver... my old nemesis
 %h1=m_quiver(X,Y,U,V,cff_vec); set(h1,'color',col_vec);
 caxis([cmin0 cmax0]);
 %m_usercoast(coastfile,'patch',[.0 .0 .0]);
% if level==3,
%  m_gshhs_f('patch',[.0 .0 .0]);
%  m_gshhs_f('color','w');
% elseif level==2,
%  m_gshhs_i('patch',[.0 .0 .0]);
%  m_gshhs_i('color','w');
% else
%  m_gshhs_l('patch',[.0 .0 .0]);
%  m_gshhs_l('color','w');
% end
% m_grid('box','fancy');
 title(['Wave Height [m]   ',datelocal],'Fontsize',15)
 my_colorbar([cmin0 cmax0 cint0],'v',' Hs [m]',15);
% colormap(Bright)
 set(gcf, 'PaperPositionMode', 'auto');
 set(gcf, 'InvertHardcopy', 'off');
 set(gcf,'color','none'); set(gca,'color','none');
 set(gca,'fontsize',15)

 outname=['WW3_Hs',num2str(ip)];
 warning off
 eval(['print -painter -depsc2 ',outname,'.eps;'])
 warning on
 eval(['! convert -quality 100 ',outname,'.eps ',outname,'.jpg'])
 eval(['! rm ',outname,'.eps;'])
% eval(['! scp ',outname,'.jpg ',dirout]);
 eval(['! mv ',outname,'.jpg FIG']);

end
return
%$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
%
% plot peak period
%

 lx=30; ly=30;
 figure('units','centimeters','position', ...
          [0 0 lx ly],'paperpositionmode','auto')
 subplot('position',[0 0.15 .85 .75]);
% m_proj('mercator','lon',[lonw lone],'lat',[lats latn]);
 proj('mercator','lon',[lonw lone],'lat',[lats latn]);
 set(gca,'fontsize',15)
% m_contourf(lon,lat,tp,[cmin1:cint1:cmax1],'k','Linestyle',':'); hold on;
 contourf(lon,lat,tp,[cmin1:cint1:cmax1],'k','Linestyle',':'); hold on;
% h1=m_quiver(X,Y,UP,VP,cff_vec); set(h1,'color',col_vec);
 caxis([cmin1 cmax1]);
 %m_usercoast(coastfile,'patch',[.0 .0 .0]);
% if level==3,
%  m_gshhs_f('patch',[.0 .0 .0]);
%  m_gshhs_f('color','w');
% elseif level==2,
%  m_gshhs_i('patch',[.0 .0 .0]);
%  m_gshhs_i('color','w');
% else
%  m_gshhs_l('patch',[.0 .0 .0]);
%  m_gshhs_l('color','w');
% end
% m_grid('box','fancy');
 title(['Peak Period [m]   ',datelocal],'Fontsize',15)
 my_colorbar([cmin0 cmax0 cint0],'v',' Hs [m]',15);
 colormap(Bright)
 set(gcf, 'PaperPositionMode', 'auto');
 set(gcf, 'InvertHardcopy', 'off');
 set(gcf,'color','none'); set(gca,'color','none');
 set(gca,'fontsize',15)

 outname=['WW3_Tp',num2str(ip)];
 warning off
 eval(['print -painter -depsc2 ',outname,'.eps;'])
 warning on
 eval(['! convert -quality 100 ',outname,'.eps ',outname,'.jpg'])
 eval(['! rm ',outname,'.eps;'])
 eval(['! scp ',outname,'.jpg ',dirout]);
 eval(['! mv ',outname,'.jpg FIG']);

 %
 % WAVE PARTITIONS
 %

 for ii=1:3;

  iw=ii-1;
  if iw==0, title0=' Wind Sea - '; end;
  if iw==1, title0=' Primary Swell - '; end;
  if iw==2, title0=' Secondary Swell - '; end;

  fname=['ww3.',date0,num2str(iw),'hs.nc'];
  nc=netcdf(fname,'r');
  hs=nc{'pHs'}(i0,:,:);
  hs(hs==spval)=NaN;
  hs=0.01*hs;
  ncclose(nc)

  fname=['ww3.',date0,num2str(iw),'th.nc'];
  nc=netcdf(fname,'r');
  angle=nc{'pth'}(i0,:,:);
  angle(angle==spval)=NaN;
  angle=pi/180*angle; %+pi/2;
  A=griddata(x,y,angle,X,Y);
  H=griddata(x,y,hs,X,Y);
  U=H.*cos(A);
  V=H.*sin(A);
  ncclose(nc);

  fname=['ww3.',date0,num2str(iw),'tp.nc'];
  nc=netcdf(fname,'r');
  tp=0.01*nc{'p+Tp'}(i0,:,:);
  tp(tp==spval)=NaN;
  ncclose(nc);

  %
  % significant wave height
  %
  figure('units','centimeters','position', ...
           [0 0 lx ly],'paperpositionmode','auto')
  subplot('position',[0 0.15 .85 .75]);
%  m_proj('mercator','lon',[lonw lone],'lat',[lats latn]);
  proj('mercator','lon',[lonw lone],'lat',[lats latn]);
  set(gca,'fontsize',15)
%  m_contourf(lon,lat,hs,[cmin0:cint0:cmax0],'k','Linestyle',':'); hold on;
  contourf(lon,lat,hs,[cmin0:cint0:cmax0],'k','Linestyle',':'); hold on;
%  m_quiver(X,Y,U,V,'b');
  caxis([cmin0 cmax0]);
%  m_usercoast(coastfile,'patch',[.0 .0 .0]);
%  m_grid('box','fancy');
  title(['Wave Height [m] - ',title0,date1],'Fontsize',15)

  my_colorbar([cmin0 cmax0 cint0],'v',' Hs [m]',15);
  set(gcf, 'PaperPositionMode', 'auto');
  set(gca,'fontsize',15)

  outname=['WW3_',num2str(iw),'Hs',num2str(ip)];
  warning off
  eval(['print -painter -depsc2 ',outname,'.eps;'])
  warning on
  eval(['! convert -quality 100 ',outname,'.eps ',outname,'.jpg'])
  eval(['! rm ',outname,'.eps;'])
  eval(['! scp ',outname,'.jpg ',dirout]);
  eval(['! mv ',outname,'.jpg FIG']);

  %
  % peak period
  %
  figure('units','centimeters','position', ...
           [0 0 lx ly],'paperpositionmode','auto')
  subplot('position',[0 0.15 .85 .75]);
%  m_proj('mercator','lon',[lonw lone],'lat',[lats latn]);
  proj('mercator','lon',[lonw lone],'lat',[lats latn]);  set(gca,'fontsize',15)
%  m_contourf(lon,lat,tp,[cmin1:cint1:cmax1],'k','Linestyle',':'); hold on;
  contourf(lon,lat,tp,[cmin1:cint1:cmax1],'k','Linestyle',':'); hold on;
%  m_quiver(X,Y,U,V,'b');
  caxis([cmin1 cmax1]);
%  m_usercoast(coastfile,'patch',[.0 .0 .0]);
%  m_grid('box','fancy');
  title(['Peak Period [s] - ',title0,date1],'Fontsize',15)

  my_colorbar([cmin1 cmax1 cint1],'v',' Tp [s]',15);
  set(gcf, 'PaperPositionMode', 'auto');
  set(gca,'fontsize',15)

  outname=['WW3_',num2str(iw),'Tp',num2str(ip)];
  warning off
  eval(['print -painter -depsc2 ',outname,'.eps;'])
  warning on
  eval(['! convert -quality 100 ',outname,'.eps ',outname,'.jpg'])
  eval(['! rm ',outname,'.eps;'])
  eval(['! scp ',outname,'.jpg ',dirout]);
  eval(['! mv ',outname,'.jpg FIG']);

  close all

 end
%end;

