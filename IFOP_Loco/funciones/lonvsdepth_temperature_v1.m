function lonvsdepth_temperature_v1(fname,lat1,NS,posi,posf,imonth,year,Yorig,step,tname)

% input
% fname: nombre archivo
% lat0: latitud a evaluar
% lat1: latitud a evaluar
% NS: °N o °S

% NS=

nc=netcdf(fname);

cvar=[6 20];

%Var 
lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);

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

i=1;
clear day month year imonth thedate
day=zeros(length([posi:step:posf]),1);
year=zeros(length([posi:step:posf]),1);
imonth=zeros(length([posi:step:posf]),1);

for n=posi:step:posf
[day(i),~,year(i),imonth(i),~]=get_date(fname,n,Yorig);
i=i+1;
end

for i=1:length(lon)
    Varq1(:,i) = interp1(squeeze(nanmean(z(:,:,i),1)),squeeze(nanmean(nc{'temp'}(posi:step:posf,:,idx1,i),1)),zq1);
end
clear z 

% Varaux1=squeeze(nanmean(Varq1,1));
% clear Varq1

%% figure

h1=pcolor(lon,zq1,Varq1);
set(h1, 'EdgeColor', 'none');
shading flat
hold on 
xlabel('','FontWeight','bold','FontSize',12)
ylabel('','FontWeight','bold','FontSize',12)
title([tname],'FontSize',13)
% title(['Mean temperature at ',num2str(abs(lat(idx1))),' °',NS],'FontSize',13)
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