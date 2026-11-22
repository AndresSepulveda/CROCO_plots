%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Create and fill WW3 files with GFS data.
% for a forecast run simulations using WW3TOOLS
% 
%  This file is part of WW3TOOLS
%
%  WW3TOOLS is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published
%  by the Free Software Foundation; either version 2 of the License,
%  or (at your option) any later version.
%
%  WW3TOOLS is distributed in the hope that it will be useful, but
%  WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program; if not, write to the Free Software
%  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
%  MA  02111-1307  USA
%
%  The on-line reference to GFS is at
%  http://nomad3.ncep.noaa.gov/
%
%  Copyright (c) 2011-2012 by Patrick Marchesiello 
%  e-mail:patrick.marchesiello@ird.fr  
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Common parameters
%
start
%
Roa=0;
%
tic
%
Download_data = 0;
it = 1; % increment time index (it=1 --> 3h; it=2 --> 6h)
%
FRCST_dir= [pwd,'/'];
Yorig=0000; % 0000 -> matlab time
%
% model limits
lonmin=LLLON; lonmax=URLON; latmin=LLLAT; latmax=URLAT;
res=DLX;
%
makeplot = 0;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% end of user input  parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% time (in matlab time)
%
%today=floor(now);
%
% date in 'Yorig' time
%
%%%%%rundate=datenum(today)-datenum(Yorig,1,1)
%rundate=floor(now)-datenum(Yorig,1,1);
%
% GFS data name
%
gfs_name=[FRCST_dir,'WW3_GFS.nc']
outfile=[FRCST_dir,'GFS_WW3.ascii'];
%
% Extract data over the internet
%
%if Download_data==1
%
% Download data with DODS 
% 
%  disp('Download data...')
%  download_GFS(today,lonmin,lonmax,latmin,latmax,FRCST_dir,Yorig,it)
%
%end

% system(['mv WW3_GFS.nc ' gfs_name]);

%
% Get the GFS grid 
% 
%gfs_name
nc=netcdf(gfs_name,'r');
lon1=nc{'longitude'}(:);
lon1=lon1-360.;
lat1=nc{'latitude'}(:);
time=nc{'time'}(:);
%mask=nc{'mask'}(:);
tlen=length(time);
%
% Make WW3 grid
%
[lon,lat]=meshgrid(lonmin:res:lonmax,latmin:res:latmax);
%
% Loop on time
%
missval=nan;
default=nan;
nx=size(lon);
ny=size(lat);
fid=fopen(outfile,'w');

time=time/24+datenum(2011,05,06);

for l=1:tlen
  disp(['time index: ',num2str(l),' of total: ',num2str(tlen)])
  
  var=squeeze(nc{'ugrd10m'}(l,:,:));
  if mean(mean(isnan(var)~=1))
    var=get_missing_val(lon1,lat1,var,missval,Roa,default);
    u10=interp2(lon1,lat1,var,lon,lat);
  else
    var=squeeze(nc{'ugrd10m'}(l-1,:,:));
    var=get_missing_val(lon1,lat1,var,missval,Roa,default);
    u10=interp2(lon1,lat1,var,lon,lat);
  end
  var=squeeze(nc{'vgrd10m'}(l,:,:));
  if mean(mean(isnan(var)~=1))
    var=get_missing_val(lon1,lat1,var,missval,Roa,default);
    v10=interp2(lon1,lat1,var,lon,lat);
  else
    var=squeeze(nc{'vgrd10m'}(l-1,:,:));
    var=get_missing_val(lon1,lat1,var,missval,Roa,default);
    v10=interp2(lon1,lat1,var,lon,lat);
  end

%
% Write ascii wind file for WAVEWATCH III
%
  yyyymmddTHHMMSS=datestr(time(l),30);
  yyyymmdd=yyyymmddTHHMMSS(1:8);
  hhmmss=yyyymmddTHHMMSS(10:15);
  fprintf(fid, '%s %s\n',yyyymmdd,hhmmss);
  [Ny,Nx] = size(u10);
  for j = 1:Ny
      a = u10(j,:);
      fprintf(fid,' %8.4f ',a);
      fprintf(fid,'\n');
  end;
  for j = 1:Ny
      a = v10(j,:);
      fprintf(fid,' %8.4f ',a);
      fprintf(fid,'\n');
  end;

end
% 
fclose(fid);
ncclose(nc)

%---------------------------------------------------------------
% Make a few plots
%---------------------------------------------------------------
makeplot=0;
if makeplot==1
  disp(' ')
  disp(' Make a few plots...')
  slides=[10 12 14 16]; 
  test_forcing(gfs_name,grdname,'u10',slides,3,coastfileplot)
  figure
  test_forcing(gfs_name,grdname,'v10',slides,3,coastfileplot)
  figure
  test_forcing(gfs_name,grdname,'tair',slides,3,coastfileplot)
  figure
  test_forcing(gfs_name,grdname,'skt',slides,3,coastfileplot)
end


toc








