more off

%%tini=1 ;    % 0015042011
%%tend=384 ;  % 2430042001 (hasta h 24 del 30)
tini=385 ;    % 0101052011
tend=1128 ;   % 2431052001 (hasta h 24 del 31)
%%tini=1129 ;    % 0101062011
%%tend=1849 ;    % 2430062001 (hasta h 24 del 31)
%%tini=1850 ;    % 0101072011
%%tend=2376 ;    % 2421072001 (hasta h 24 del 21)


eta_u=24;
xi_u=31;
eta_v=23;
xi_v=31;

ncgrd=netcdf('quemchi_grd.nc','r');
nc=netcdf('vientos_ERA.nc','r');

lon_v=ncgrd{'lon_v'}(:,:);
lat_v=ncgrd{'lat_v'}(:,:);
lon_u=ncgrd{'lon_u'}(:,:);
lat_u=ncgrd{'lat_u'}(:,:);

tme=tini:tend; 

uwnd=nc{'uwnd'}(:,:,:,:);
vwnd=nc{'vwnd'}(:,:,:,:);

uvars=[];
vvars=[];
ulls=[];
vlls=[];

tend-tini

for t=tini:tend
	aux2=[];
	for j=1:eta_u
%		for i=1:xi_u
			aux=squeeze(uwnd(t,j,:));
			aux2=[aux2; aux'];
%		end
	end
	uvars=[uvars; aux2];
end

dlmwrite('BC_Fluent_uwnd.csv',uvars);


for j=1:eta_u
	aux=lat_u(j,:);
	ulls=[ulls; aux];
end
for j=1:eta_u
	aux=lon_u(j,:);
	ulls=[ulls; aux];
end

dlmwrite('BC_Fluent_ulatlon.csv',ulls);


for t=tini:tend
	aux2=[];
	for j=1:eta_v
%		for i=1:xi_v
			aux=squeeze(vwnd(t,j,1:31));
			aux2=[aux2;aux'];
%		end
	end
	vvars=[vvars; aux2];
end

dlmwrite('BC_Fluent_vwnd.csv',vvars);

for j=1:eta_v
	aux=lat_v(j,1:31);
	vlls=[vlls; aux];
end
for j=1:eta_v
	aux=lon_v(j,1:31);
	vlls=[vlls; aux];
end

dlmwrite('BC_Fluent_vlatlon.csv',vlls);
