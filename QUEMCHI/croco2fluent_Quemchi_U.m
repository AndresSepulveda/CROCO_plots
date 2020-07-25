more off
jj=22;

%% 22 en x, 14 en y

nc=netcdf('Quemchi_201801.nc','r');

mask_rho=nc{'mask_rho'}(:,:);
lon_rho=nc{'lon_rho'}(:,:);
lat_rho=nc{'lat_rho'}(:,:);
lon_u=nc{'lon_u'}(:,:);
lat_u=nc{'lat_u'}(:,:);

h=nc{'h'}(:,:);
tme=1:744;  % nc{'time'}(:);
            % tme=tme-min(tme);
sigma_r=nc{'s_rho'}(:);

temp=nc{'temp'}(:,:,:,:);
salt=nc{'salt'}(:,:,:,:);
u=nc{'u'}(:,:,:,:);

lonmn=min(min(lon_rho));
lonmx=max(max(lon_rho));
latmn=min(min(lat_rho));
latmx=max(max(lat_rho));

indxlon=lon_rho(1,jj);
aux1=abs((lon_u(1,:))-indxlon);
aux2=min(aux1);

indxvlon=find(aux1 == aux2)
indxvlon=indxvlon(1);

[m n]=size(lon_rho);
tmx=length(tme);

allvars=[];
for t=1:tmx
	for j=1:m
		if (mask_rho(j,jj) == 1)
			for z=1:length(sigma_r)	
			aux=[tme(t) lon_rho(j,jj) lat_rho(j,jj) sigma_r(z)*h(j,jj) u(t,z,j,indxvlon) temp(t,z,j,jj) salt(t,z,j,jj) ];
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
