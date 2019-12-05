function roms2fluentBC(jj)
more off
if  nargin < 1
%jj=1;
jj=12;
end

nc=netcdf('b.nc','r');

mask_rho=nc{'mask_rho'}(:,:);
lon_rho=nc{'lon_rho'}(:,:);
lat_rho=nc{'lat_rho'}(:,:);
%lon_u=nc{'lon_u'}(:,:);
%lat_u=nc{'lat_u'}(:,:);
lon_v=nc{'lon_v'}(:,:);
lat_v=nc{'lat_v'}(:,:);

h=nc{'h'}(:,:);
tme=nc{'time'}(:);
tme=tme-min(tme);
sigma_r=nc{'s_rho'}(:);

temp=nc{'temp'}(:,:,:,:);
salt=nc{'salt'}(:,:,:,:);
%u=nc{'u'}(:,:,:,:);
v=nc{'v'}(:,:,:,:);

lonmn=min(min(lon_rho));
lonmx=max(max(lon_rho));
latmn=min(min(lat_rho));
latmx=max(max(lat_rho));

indxlat=lat_rho(jj,1);
aux1=abs((lat_v(:,1))-indxlat);
aux2=min(aux1);
indxvlat=find(aux1 == aux2)
indxvlat=indxvlat(1);

[m n]=size(lon_rho);
tmx=length(tme);

%v = 1;
allvars=[];
for t=1:tmx
	for j=1:n
%		lon_rho(jj,j),lat_rho(jj,j),mask_rho(jj,j)
		if (mask_rho(jj,j) == 1)
			for z=1:length(sigma_r)	
			aux=[tme(t) lon_rho(jj,j) lat_rho(jj,j) sigma_r(z)*h(jj,j) v(t,z,indxvlat,j) temp(t,z,jj,j) salt(t,z,jj,j) ];
			allvars=[allvars; aux];
%			keyboard	
			end	
		end
	end
end

min(allvars(:,2))
max(allvars(:,2))
min(allvars(:,3))
max(allvars(:,3))

dlmwrite('BC2_Fluent.csv',allvars);
