function lonvsdepth_wnd_v1(fname,lat1,NS,posi,posf,imonth,year,Yorig,step,tname)

% input
% fname: nombre archivo
% lat0: latitud a evaluar
% lat1: latitud a evaluar
% NS: °N o °S

nc=netcdf(fname);

cmap1=colormap_cpt('temp 19lev');
cmap2=colormap_cpt('balance');

cmask=[0.5 0.5 0.5];% color mascara

cvar=[-20 20];
cdif=[-0.5 0.5];

%Var 
lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);
lon=lon(1:end-1);

xx=lat1;
yy=lat1;

x=lat; % x vector arbitrario
y=lat; % x vector arbitrario

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

gname=fname;
type='u';
clear z
i=1;
for n=posi:step:posf
    [z(i,:,:,:)]=get_depths(fname,gname,n,type);
    i=i+1;
end
z=squeeze(z(:,:,idx1,:));

zq1=[-600:20:0];

clear Varq1 Varq2

i=1;
clear day month year imonth thedate
day=zeros(length([posi:step:posf]),1);
year=zeros(length([posi:step:posf]),1);
imonth=zeros(length([posi:step:posf]),1);

for n=posi:step:posf
[day(i),~,year(i),imonth(i),~]=get_date(fname,n,Yorig);
i=i+1;
end

% Varq1=zeros(12,length(zq1),length(lon));
clear dates

for i=1:length(lon)
%     for j=1
%         for n=posi:posf
Varq1(:,i) = interp1(squeeze(nanmean(z(:,:,i),1)),squeeze(nanmean(nc{'v'}(posi:step:posf,:,idx1,i),1)),zq1);
% Varq2(t,:,i) = interp1(squeeze(nanmean(z(1:1+aux(end)-1,:,i),1)),squeeze(nanmean(nc{'u'}(posi:step:posi+aux(end)-1,:,idx1,i),1)),zq1);
% Varq3(t,:,i) = interp1(squeeze(nanmean(z(1:1+aux(end)-1,:,i),1)),squeeze(nanmean(nc{'w'}(posi:step:posi+aux(end)-1,:,idx1,i),1)),zq1);

Varq4(:,i) = interp1(squeeze(nanmean(z(:,:,i),1)),squeeze(nanmean(nc{'temp'}(posi:step:posf,:,idx1,i),1)),zq1);
Varq5(:,i) = interp1(squeeze(nanmean(z(:,:,i),1)),squeeze(nanmean(nc{'salt'}(posi:step:posf,:,idx1,i),1)),zq1);
% Varq2(t,:,j,i) = interp1(z(t,:,idx2,i),nc{'salt'}(n,:,idx2,i),zq2);
%         end
%     end
end
clear z 

% Varaux1=squeeze(nanmean(Varq1,1));
% % Varaux2=squeeze(nanmean(Varq2,1));
% % Varaux3=squeeze(nanmean(Varq3,1));
% 
% Varaux4=squeeze(nanmean(Varq4,1));
% Varaux5=squeeze(nanmean(Varq5,1));
% 
% % [lonmesh,zq1mesh]=meshgrid(lon,zq1);
% 
% % clear Varq1

% skip=5;

%%

h1=pcolor(lon,zq1,Varq1*100);% m/s to cm/s
hold on
set(h1, 'EdgeColor', 'none');
shading flat
hold on 

cplot=[0 0 0];
[C,h2]=contour(lon,zq1,Varq4,[4 6 8 10 12 14 16 18],'color',cplot,'linewidth',1.5);% m/s to cm/s
clabel(C,h2,'Color',cplot,'FontWeight','bold');

cplot=[0.7 0 0.9];
[C3,h3]=contour(lon,zq1,Varq5,[34:0.2:35],'color',cplot,'linewidth',1.5);% m/s to cm/s
clabel(C3,h3,'Color',cplot,'FontWeight','bold');

%
% [C,h2]=contour(lon,zq1,Varaux3*100,[0 0],'color',cplot,'linewidth',1.5);% m/s to cm/s
% clabel(C,h2,'Color',cplot,'FontWeight','bold');
% % [~, hContour] = contourf(YourData, [0, other_levels_go_here]);
% % idx = hContour.LevelList == 0;
% % hContour.FacePrims(idx).ColorData = uint8([255; 255; 255; 255]);

% idx = ~isnan(Varaux2) & ~isnan(Varaux3); 
% quiver(lonmesh(idx),zq1mesh(idx),Varaux2(idx),Varaux3(idx),'color',cplot);
% H1=area(lon,zq1,'FaceColor',cmask,'EdgeColor','none');
xlabel('')
% ylabel('Depth [m]','FontWeight','bold','FontSize',12)
title([tname],'FontSize',13)
% title(['Mean meridional current at ',num2str(abs(lat(idx1))),' °',NS],'FontSize',13)
% set(ax1,'xticklabel',[])
caxis(cvar)

xt=get(gca,'xtick');
for k=1:numel(xt);
    if xt(k)>0
xt1{k}=sprintf('%g°E',abs(round(xt(k),2)));
    elseif xt(k)<0
xt1{k}=sprintf('%g°W',abs(round(xt(k),2)));
    else
xt1{k}=xt1{k};
    end
end
set(gca,'xticklabel',xt1);
set(gca,'TickDir','out'); 

return