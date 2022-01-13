clear all

gnameL0='/home/marcela/Ocenography/Otros/Escuela2022/croco_grd.nc'
avgL0='/home/marcela/Ocenography/Otros/Escuela2022/croco_avg.00020.nc'
avgL1='/home/marcela/Ocenography/Otros/Escuela2022/croco_avg.nc'

ncg=netcdf(gnameL0)
maskL0=squeeze(ncg{'mask_rho'}(:));
lonL0=squeeze(ncg{'lon_rho'}(:));
latL0=squeeze(ncg{'lat_rho'}(:));
close(ncg)

% Leyendo TSM de L0, Archivo 00020, primer registro
ncg=netcdf(avgL0)
tempL0=squeeze(ncg{'temp'}(1,end,:,:));
close(ncg)

% Leyendo TSM de L1, Archivo 00020, ultimo registro
ncg=netcdf(avgL1)
maskL1=squeeze(ncg{'mask_rho'}(:));
lonL1=squeeze(ncg{'lon_rho'}(:));
latL1=squeeze(ncg{'lat_rho'}(:));
tempL1=squeeze(ncg{'temp'}(end,end,:,:));
close(ncg)
% Notar que las fechas no coinciden exactamente porque al calcular
% promedios de desajustan

%%
% con lonrange/latrange selecciono el dominio L1
lonrangeE=[lonL1(1,1) lonL1(end,end)]; latrangeE=[latL1(1,1) latL1(end,end)]

fig=figure; %set(fig, 'resize', 'off');
set(fig,'PaperUnits','inches');
set(fig,'PaperSize', [12 9]);
set(fig,'PaperPosition',[0 0 12 9]);
set(fig,'PaperPositionMode','Manual');

CM=othercolor('Mrainbow');%CM=CM(end:-1:1,:); %PRGn11 'PuOr5 'BrBG11'
ax0 = axes('Position',[0.08 0.3 0.4 0.4])
m_proj('mercator','lon',lonrangeE,'lat',latrangeE);hold on
m_grid('linewi',2,'linest','none','tickdir','out','yaxisloc','left','fontsize',14,'ytick',5,'xtick',4);
m_pcolor(lonL0,latL0,(tempL0)); shading flat
colormap(CM); caxis([15 21]);
m_gshhs_h('patch',[.95 .95 .95])
title(ax0,'(a) L0','fontsize',14)

ax1 = axes('Position',[0.53 0.3 0.4 0.4])
m_proj('mercator','lon',lonrangeE,'lat',latrangeE);hold on
m_grid('linewi',2,'linest','none','tickdir','out','yaxisloc','left','fontsize',14,'ytick',5,'xtick',4);
m_pcolor(lonL1,latL1,(tempL1)); shading flat
colormap(CM); caxis([15 21]);
m_gshhs_h('patch',[.95 .95 .95])
title(ax1,'(b) L1','fontsize',14)

cb=colorbar;
set(cb,'position',[0.95 .3 .02 .4])
title(cb,'°C')
%%
print(gcf,'-r1000','-dpdf',['/home/marcela/Ocenography/Otros/Escuela2022/B_L0L1.pdf'])
