function oct_topo_cap(infile,outfile,varname,value)
%
%  oct_topo_cap(INFILE,OUTFILE)
%  oct_topo_cap(INFILE,OUTFILE,VARNAME,VALUE)
%
%  Copy the NetCDF file INFILE to OUTFILE and, in OUTFILE, replace all
%  the positive values (land topography) of the variable VARNAME
%  (default 'topo') by VALUE (default +50). The negative values
%  (bathymetry), the zeros and the missing values (_FillValue,
%  missing_value, NaN) are not changed. INFILE is not modified.
%
%  - scale_factor / add_offset: the comparison and the new value are
%    in physical units (VALUE is packed before writing).
%  - Large files: the variable is processed in slabs along its last
%    dimension (e.g. rows of a lon/lat grid), not read all at once.
%
%  Example:
%    oct_topo_cap('etopo.nc','etopo_cap50.nc')            % topo > 0 -> 50
%    oct_topo_cap('gebco.nc','gebco_cap.nc','elevation',50)
%
%  Needs the octave-netcdf package (pkg load netcdf).
%
%  Andres Sepulveda 2026
%  This program is free software; you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation; either version 2 of the License, or (at
%  your option) any later version.
%
if nargin<2
  error('Usage: oct_topo_cap(infile,outfile[,varname[,value]])')
end
if nargin<3 || isempty(varname), varname='topo'; end
if nargin<4 || isempty(value),   value=50;       end
if ~exist(infile,'file')
  error(['oct_topo_cap: file not found: ',infile])
end
if strcmp(canon(infile),canon(outfile))
  error('oct_topo_cap: OUTFILE must be different from INFILE')
end
pkg load netcdf
%
% Copy the file, then modify the copy
%
[ok,msg]=copyfile(infile,outfile,'f');
if ~ok
  error(['oct_topo_cap: cannot copy ',infile,' to ',outfile,': ',msg])
end
ncid=netcdf.open(outfile,'NC_WRITE');
try
  vid=netcdf.inqVarID(ncid,varname);
catch
  netcdf.close(ncid);
  error(['oct_topo_cap: no variable ',varname,' in ',infile])
end
[~,xtype,dimids]=netcdf.inqVar(ncid,vid);
nd=numel(dimids);
sz=ones(1,max(nd,1));
for k=1:nd
  [~,sz(k)]=netcdf.inqDim(ncid,dimids(k));
end
%
% Packing and missing values
%
sf=getatt(ncid,vid,'scale_factor',1);
ao=getatt(ncid,vid,'add_offset',0);
fv=[getatt(ncid,vid,'_FillValue',[]) getatt(ncid,vid,'missing_value',[])];
isint=any(xtype==[netcdf.getConstant('NC_BYTE') netcdf.getConstant('NC_SHORT') ...
                  netcdf.getConstant('NC_INT')]);
vraw=(value-ao)/sf;                       % new value in file units
if isint, vraw=round(vraw); end
%
% Process the variable in slabs along its last dimension (Fortran order)
%
if nd==0
  nslab=1; step=1;
else
  nslab=sz(nd);
  step=max(1,floor(2e7/max(1,prod(sz(1:nd-1)))));   % ~2e7 values per slab
end
nchg=0; npos=0; nneg=0; nmiss=0;
for i0=0:step:nslab-1
  start=zeros(1,nd); count=sz;
  if nd>0
    start(nd)=i0; count(nd)=min(step,nslab-i0);
  end
  if nd==0
    raw=netcdf.getVar(ncid,vid);
  else
    raw=netcdf.getVar(ncid,vid,start,count);
  end
  miss=isnan(double(raw));
  for f=fv(:)'
    miss=miss | double(raw)==double(f);
  end
  val=double(raw)*sf+ao;                  % physical values
  pos=val>0 & ~miss;
  npos=npos+nnz(pos); nneg=nneg+nnz(val<0 & ~miss); nmiss=nmiss+nnz(miss);
  if any(pos(:))
    nchg=nchg+nnz(pos & val~=value);
    raw(pos)=vraw;
    if nd==0
      netcdf.putVar(ncid,vid,raw);
    else
      netcdf.putVar(ncid,vid,start,count,raw);
    end
  end
end
%
% History attribute
%
gid=netcdf.getConstant('NC_GLOBAL');
hist=getatt(ncid,gid,'history','');
if ~ischar(hist), hist=''; end
line=sprintf('%s: oct_topo_cap: %s > 0 set to %g',datestr(now,'yyyy-mm-dd HH:MM:SS'),varname,value);
netcdf.reDef(ncid);
if isempty(hist)
  netcdf.putAtt(ncid,gid,'history',line);
else
  netcdf.putAtt(ncid,gid,'history',[line,char(10),hist]);
end
netcdf.endDef(ncid);
netcdf.close(ncid);
disp(sprintf('oct_topo_cap: %s in %s',varname,outfile))
disp(sprintf('  %d positive values set to %g (%d were different), %d negative and %d missing values unchanged',...
             npos,value,nchg,nneg,nmiss))
return
%
function v=getatt(ncid,vid,name,def)
try
  v=double(netcdf.getAtt(ncid,vid,name));
  if strcmp(name,'history'), v=char(v); end
catch
  v=def;
end
return
%
function p=canon(f)
p=f;
try
  p=canonicalize_file_name(f);
  if isempty(p), p=make_absolute_filename(f); end
catch
end
return
