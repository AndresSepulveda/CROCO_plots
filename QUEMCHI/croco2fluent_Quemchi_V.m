more off
jj=14;

%% 22 en x, 14 en y

nc=netcdf('Quemchi_201801.nc','r');

mask_rho=nc{'mask_rho'}(:,:);
lon_rho=nc{'lon_rho'}(:,:);
lat_rho=nc{'lat_rho'}(:,:);
lon_v=nc{'lon_v'}(:,:);
lat_v=nc{'lat_v'}(:,:);

h=nc{'h'}(:,:);
tme=1:744;  % nc{'time'}(:);
            % tme=tme-min(tme);
sigma_r=nc{'s_rho'}(:);

temp=nc{'temp'}(:,:,:,:);
salt=nc{'salt'}(:,:,:,:);
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

allvars=[];
for t=1:tmx
	for j=1:n
		if (mask_rho(jj,j) == 1)
			for z=1:length(sigma_r)	
			aux=[tme(t) lon_rho(jj,j) lat_rho(jj,j) sigma_r(z)*h(jj,j) v(t,z,indxvlat,j) temp(t,z,jj,j) salt(t,z,jj,j) ];
			allvars=[allvars; aux];
			end	
		end
	end
end

min(allvars(:,2))
max(allvars(:,2))
min(allvars(:,3))
max(allvars(:,3))

dlmwrite('BC_right_Fluent.csv',allvars);
