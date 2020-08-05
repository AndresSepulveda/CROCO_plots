clear all
close all
clc

addpath('C\Users\UDEC\Documents\CHILOE_PISCES')
%_____archivo grilla____________________________________________
bat=netcdf('roms_grd_BGQ.nc','r');
lon=bat{'lon_rho'}(:);
lat=bat{'lat_rho'}(:);
h=bat{'h'}(:);
%_____________________________________________________
file=netcdf('mosa_BGQ_bry_PISCES.nc','r');

o2_west = file{'O2_west'}(:); o2_north = file{'O2_north'}(:); o2_south = file{'O2_south'}(:);
no3_west = file{'NO3_west'}(:); no3_north = file{'NO3_north'}(:); no3_south = file{'NO3_south'}(:);
chla_west = file{'CHLA_west'}(:); chla_north = file{'CHLA_north'}(:); chla_south = file{'CHLA_south'}(:);
phyto_west = file{'PHYTO_west'}(:);phyto_north = file{'PHYTO_north'}(:);phyto_south = file{'PHYTO_south'}(:);
zoo_west = file{'ZOO_west'}(:);zoo_north = file{'ZOO_north'}(:);zoo_south = file{'ZOO_south'}(:);
po4_west = file{'PO4_west'}(:);po4_north = file{'PO4_north'}(:);po4_south = file{'PO4_south'}(:);
dic_west = file{'DIC_west'}(:);dic_north = file{'DIC_north'}(:);dic_south = file{'DIC_south'}(:);
fe_west = file{'FER_west'}(:);fe_north = file{'FER_north'}(:);fe_south = file{'FER_south'}(:);
doc_west = file{'DOC_west'}(:);doc_north = file{'DOC_north'}(:);doc_south = file{'DOC_south'}(:);
talk_west = file{'TALK_west'}(:);talk_north = file{'TALK_north'}(:);talk_south = file{'TALK_south'}(:);
sil_west = file{'Si_west'}(:);sil_north = file{'Si_north'}(:);sil_south = file{'Si_south'}(:);

theta_s=file{'theta_s'}(:);theta_b=file{'theta_b'}(:);hc=file{'hc'}(:);N=length(file('s_rho'));

zeta_north=file{'zeta_north'}(:);zeta_south=file{'zeta_south'}(:);zeta_west=file{'zeta_west'}(:);

zn = squeeze(zlevs(h(end,:),zeta_north(1,:),theta_s,theta_b,hc,N,'r'));
zs = squeeze(zlevs(h(1,:),zeta_south(1,:),theta_s,theta_b,hc,N,'r'));
zw = squeeze(zlevs(h(:,1),zeta_west(1,:)',theta_s,theta_b,hc,N,'r'));

% figura 
for i=1:4
h=figure
%pcolor(lon(1,:),zn,squeeze(o2_north(i,:,:))/44.66); shading interp
%pcolor(lon(1,:),zs,squeeze(o2_south(i,:,:))/44.66); shading interp
%pcolor(lon(1,:),zs,squeeze(no3_south(i,:,:))); shading interp
pcolor(lon(1,:),zs,squeeze(phyto_south(i,:,:))); shading interp
%pcolor(lon(1,:),zn,squeeze(chla_south(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(chla_south(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(doc_south(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(po4_south(i,:,:))); shading interp
%pcolor(lon(1,:),zn,squeeze(zoo_north(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(fe_south(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(dic_south(i,:,:))); shading interp
%pcolor(lon(1,:),zn,squeeze(talk_south(i,:,:))); shading interp
%pcolor(lon(1,:),zs,squeeze(sil_south(i,:,:))); shading interp
hold on
%contour(lon(1,:),zn,squeeze(o2_north(i,:,:))/44.66,'LineColor','k')
axis([-80 -75.5 -1000 0])
set(gca,'fontsize',20)
box on
%axis([-50 -39 -1000 0])

LB=flipud(lbmap(11*2,'RedBlue'));
colormap(LB)
%caxis([1 6.5]) %oxigeno
%caxis([0 40])
%caxis([0 10])
caxis([0 5])
%caxis([0 30])
%caxis([0 2])
%caxis([2000 2400])
%caxis([0 40])
%caxis([0 0.001])
colorbar
title(datestr(i,'dd'))

nombrefig=['bry_',datestr(i,'dd'),'.tiff']
saveas(h,nombrefig)
close(h)
end

%% PROMEDIO ESTACIONAl
for i=1:length(no3_north(:,1,1))
    if i==1 || i==2 || i==3%verano
        sep{1,i}=squeeze(no3_north(i,:,:));
     end
      if i==4 || i==5 || i==6%oton
        sep{2,i-3}=squeeze(no3_north(i,:,:));
     end
      if i==7 || i==8 || i==9%invierno
         sep{3,i-6}=squeeze(no3_north(i,:,:));
        end
      if i==10 || i==11 || i==12%prim
        sep{4,i-9}=squeeze(no3_north(i,:,:));
      end
end

for p=1:length(sep)
for i=1:length(sep{1,1}(1,:))%lon
for  j=1:length(sep{1,1}(:,1))
   est{p,1}(j,i)=mean([sep{p,1}(j,i) sep{p,2}(j,i) sep{p,3}(j,i)]);
end
end
end
clear sep

% figura
for i=1:4
h=figure
%pcolor(lon(1,:),zn,est{i,1}/44.66);shading interp;hold on
pcolor(lon(1,:),zn,est{i,1});shading interp;hold on
axis([-80 -72 -1000 0])

LB=flipud(lbmap(11*2,'RedBlue'));
colormap(LB)
%caxis([1 6.5])
caxis([0 40])
colorbar
title(datestr(i,'dd'))

nombrefig=['bry_',datestr(i,'dd'),'.tiff']
saveas(h,nombrefig)
close(h)
end
