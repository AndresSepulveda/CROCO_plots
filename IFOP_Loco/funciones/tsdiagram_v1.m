function tsdiagram_v1(fname,lat0,lon0,tin)

nc=netcdf(fname);

lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);
lon=lon(1:end-1);

xx=lat0;
yy=lon0;

x=lat; % x vector arbitrario
y=lon; % x vector arbitrario

clear minimox positionx minimoy positiony mas_cercanox mas_cercanoy
for i=1:length(xx)
[minimox(i),positionx(i)]=min(abs(x-xx(i)));
[minimoy(i),positiony(i)]=min(abs(y-yy(i)));
mas_cercanox(i)=x(positionx(i));
mas_cercanoy(i)=y(positiony(i));
end

idx1=positionx;
idx2=positiony;
clear xx yy x y minimox minimoy positionx positiony mas_cercanox mas_cercanoy

% time=nc{'time'}(:);

% fname=;
gname=fname;
% tindex=1;
type='u';
clear z
% for i=1:length(time)
%     tindex=i;
%     [z(i,:,:,:)]=get_depths(fname,gname,tindex,type);
% end
i=1;
for n=tin
    [z(i,:,:,:)]=get_depths(fname,gname,n,type);
    i=i+1;
end

clear d1Var d2Var d3Var
for i=1:length(idx1)
d1Var(:,:,i)=nc{'temp'}(tin,:,idx1(i),idx2(i));
d2Var(:,:,i)=nc{'salt'}(tin,:,idx1(i),idx2(i));
d3Var(:,:,i)=squeeze(z(:,:,idx1(i),idx2(i)));
end

% cmap1=flipud(colormap_cpt('temperature'));
cmap1=colormap_cpt('temperature');


% figure('Position', [100, 100, 500, 600]);
% ax1=subplot(1,2,1);
% theta_sdiag(squeeze(temp(tin,:,idx1,idx2)),squeeze(salt(tin,:,idx1,idx2)),squeeze(z(tin,:,idx1,idx2)));
theta_sdiag(d1Var(:),d2Var(:),d3Var(:));
% barra=colorbar('Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' Depth [m] ','FontSize',10);
% title(['CROCO at Lat:',num2str(lat0),' Lon:',num2str(lon0)],'FontSize',13)

% ax2=subplot(1,2,2);
% % theta_sdiag(squeeze(temp(tin,:,idx1,idx2)),squeeze(salt(tin,:,idx1,idx2)),squeeze(z(tin,:,idx1,idx2)));
% theta_sdiag(d1Var(:),d2Var(:),d3Var(:));
% 
% pos2=get(ax2,'Position');
% 
% barra=colorbar(ax2,'Eastoutside','FontWeight','bold','Linewidth',1);
% ylabel(barra,' m ','FontSize',10);
% title('b) CROCO','FontSize',13)
% 
% % pos1=get(ax1,'Position');
% ax2.Position=[pos2(1) pos2(2) pos2(3) pos2(4)];
% % ax1.Position=[pos1(1) pos1(2) pos2(3) pos2(4)];
% % pos1=get(ax1,'Position');
% a=get(barra);
% a=a.Position;
% barra.Position=[pos2(1)+pos2(3)+0.01 a(2) a(3) a(4)];
colormap(cmap1)
% colormap(ax1,cmap1);
% colormap(ax2,cmap1);
xlim([34 35])
ylim([0 20])
caxis([-6000 0])
