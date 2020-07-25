more off


%% Quemchi  2018 22 en x, 14 en y
%% Quemchi  2011  4 (-73.5) / 25 (-73.20) ,  3 (-44.22) / 21 (-42.049)
jj      = 25;

%%ntiempo = 2376; %76;

%%tini=1 ;    % 0015042011
%%tend=384 ;  % 2430042001 (hasta h 24 del 30)
%%tini=385 ;    % 0101052011
%%tend=1128 ;   % 2431052001 (hasta h 24 del 31)
%%tini=1129 ;    % 0101062011
%%tend=1849 ;    % 2430062001 (hasta h 24 del 31)
tini=1850 ;    % 0101072011
tend=2376 ;    % 2421072001 (hasta h 24 del 21)


nc=netcdf('quemchi_his_2011a.nc','r');

mask_rho=nc{'mask_rho'}(:,:);
lon_rho=nc{'lon_rho'}(:,:);
lat_rho=nc{'lat_rho'}(:,:);
lon_u=nc{'lon_u'}(:,:);
lat_u=nc{'lat_u'}(:,:);

h=nc{'h'}(:,:);
tme=tini:tend;  % nc{'time'}(:);
            % tme=tme-min(tme);
sigma_r=nc{'s_rho'}(:);

temp=nc{'temp'}(:,:,:,:);
   m_temp=nc{'temp'}.scale_factor;
   n_temp=nc{'temp'}.add_offset;
salt=nc{'salt'}(:,:,:,:);
   m_salt=nc{'salt'}.scale_factor;
   n_salt=nc{'salt'}.add_offset;
u=nc{'u'}(:,:,:,:);
   m_u=nc{'u'}.scale_factor;
   n_u=nc{'u'}.add_offset;

lonmn=min(min(lon_rho));
lonmx=max(max(lon_rho));
latmn=min(min(lat_rho));
latmx=max(max(lat_rho));

indxlon=lon_rho(1,jj);
aux1=abs((lon_u(1,:))-indxlon);
aux2=min(aux1);

indxulon=find(aux1 == aux2)
indxulon=indxulon(1);
lon_u(1,indxulon)

[m n]=size(lon_rho);
%%tmx=length(tme);

allvars=[];
for t=tini:tend
	for j=1:m
		if (mask_rho(j,jj) == 1)
			for z=1:length(sigma_r)	
			aux=[t lon_rho(j,jj) lat_rho(j,jj) sigma_r(z)*h(j,jj) u(t,z,j,indxulon)*m_u+n_u temp(t,z,j,jj)*m_temp+n_temp salt(t,z,j,jj)*m_salt+n_salt ];
			allvars=[allvars; aux];
			end	
		end
	end
end

if length(allvars > 2)
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



if jj == 25
   dlmwrite('BC_Fluent_01-21_072011_W.csv',allvars,'precision',5);
else
   dlmwrite('BC_Fluent_01-21_072011_E.csv',allvars,'precision',5);
end
