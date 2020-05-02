more off

jj=20; % 20;  %3 20


nc=netcdf('quemchi_his_2011a.nc','r');

mask_rho=nc{'mask_rho'}(:,:);
lon_rho=nc{'lon_rho'}(:,:);
lat_rho=nc{'lat_rho'}(:,:);
lon_v=nc{'lon_v'}(:,:);
lat_v=nc{'lat_v'}(:,:);

h=nc{'h'}(:,:);

%%tini = 1;   % 0015042011
%%tend = 384; % 2430042011
%%tini = 385;   % 0001052011
%%tend = 1128;  % 2431052011 ??
tini = 1129;   % 0001062011
tend = 1849;   % 2430062011 ??


sigma_r=nc{'s_rho'}(:);

temp=nc{'temp'}(:,:,:,:);
	m_temp=nc{'temp'}.scale_factor;
	n_temp=nc{'temp'}.add_offset;
salt=nc{'salt'}(:,:,:,:);
	m_salt=nc{'salt'}.scale_factor;
	n_salt=nc{'salt'}.add_offset;
v=nc{'v'}(:,:,:,:);
	m_v=nc{'v'}.scale_factor;
	n_v=nc{'v'}.add_offset;

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

allvars=[];
for t= tini:tend
	for j=1:n
		if (mask_rho(jj,j) == 1)
			for z=1:length(sigma_r)	
			aux=[t lon_rho(jj,j) lat_rho(jj,j) sigma_r(z)*h(jj,j) v(t,z,indxvlat,j)*m_v+n_v temp(t,z,jj,j)*m_temp+n_temp salt(t,z,jj,j)*m_salt+n_salt ];
			allvars=[allvars; aux];
			end	
		end
	end
end

if  length(allvars) > 2
   min(allvars(:,2))
   max(allvars(:,2))
   min(allvars(:,3))
   max(allvars(:,3))
   min(allvars(:,5))
   max(allvars(:,5))
   min(allvars(:,6))
   max(allvars(:,6))
   min(allvars(:,7))
   max(allvars(:,7))
end

if jj == 3
%% dlmwrite('BC_Fluent_15-30_042011_S.csv',allvars,'precision',5);
%% dlmwrite('BC_Fluent_052011_S.csv',allvars,'precision',5);
 dlmwrite('BC_Fluent_062011_S.csv',allvars,'precision',5);
else
%% dlmwrite('BC_Fluent_15-30_042011_N.csv',allvars,'precision',5);
%% dlmwrite('BC_Fluent_052011_N.csv',allvars,'precision',5);
 dlmwrite('BC_Fluent_062011_N.csv',allvars,'precision',5);
end
