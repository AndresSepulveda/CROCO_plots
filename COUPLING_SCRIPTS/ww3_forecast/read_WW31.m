%  Reads WAVEWATCH IDLA=3, IDFM=1 output files
function [lat,lon,mat1,mat2,norm,var,nodata]=read_WW31(filename)
% 
fid=fopen(filename,'r');
modelname=fscanf(fid,' %s13');
% to be fixed later
modelname2=fscanf(fid,' %s13');
date=fscanf(fid,'%d',2);
lonr=fscanf(fid,'%f',2);
nx=fscanf(fid,'%d',1);
latr=fscanf(fid,'%f',2);
ny=fscanf(fid,'%d',1);
var=fscanf(fid,'%s',1)
scale=fscanf(fid,'%f',1);
tv1=size(var);
if (tv1(2)==2) 
  if (var(1:2)=='.t') 
     var='.t  ';
  end
elseif (tv1(2)==3) 
  if (var(1:3)=='.hs') 
     var='.hs ';
   end
   if (var(1:3)=='.fp') 
     var='.fp ';
   end
end
if (var=='.poc') 
      unit='S.D.';
    elseif (var=='.paw') 
      unit='S.D.';
    else
       unit=fscanf(fid,'%s',1);
end
idla=fscanf(fid,'%d',1);
idlafm=fscanf(fid,'%d',1);
form=fscanf(fid,'%s',1);
nodata=fscanf(fid,'%d',1);
mat1=flipud(reshape(fscanf(fid,'%d',nx*ny).*scale,nx,ny)');
I = find(mat1==nodata.*scale);
mat1(I)=NaN;
if (var=='.wnd') 
   mat2=flipud(reshape(fscanf(fid,'%d',nx*ny).*scale,nx,ny)');
elseif (var=='.tus') 
   mat2=flipud(reshape(fscanf(fid,'%d',nx*ny).*scale,nx,ny)');
elseif (var=='.uss') 
   mat2=flipud(reshape(fscanf(fid,'%d',nx*ny).*scale,nx,ny)');
else
   mat2=0.*mat1.*scale;
end
I = find(mat2==nodata.*scale);
mat2(I)=NaN;
norm=sqrt(mat1.^2+mat2.^2);
lat=linspace(latr(1),latr(2),ny)';
lon=linspace(lonr(1),lonr(2),nx)';
fclose(fid);
