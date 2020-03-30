function lonlatmany_v1(fname,Yorig,posi,posf,lat1,lon1,step,tname)

nc=netcdf(fname);

lat=readlat(nc);
lon=readlon(nc);
lat=lat(:,1);
lon=lon(1,:);
[~,~,mask]=read_latlonmask(fname,'u');
% % lat=lat(:,1);
% % lon=lon(1,:);
[idx1mask,idx2mask]=find(mask~=1);

xx=lat1;
yy=lon1;

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
% temp= squeeze(nanmean(squeeze(nanmean(nc{'temp'}(posi:step:posf,end,idx1,idx2),1)),1));
temp= squeeze(nanmean(nc{'temp'}(posi:step:posf,end,:,:,1),1));
u= squeeze(nanmean(nc{'u'}(posi:step:posf,end,:,:,1),1));
v= squeeze(nanmean(nc{'v'}(posi:step:posf,end,:,:,1),1));

for i=1:length(idx1mask)
temp(idx1mask(i),idx2mask(i))=NaN;
u(idx1mask(i),idx2mask(i))=NaN;
v(idx1mask(i),idx2mask(i))=NaN;
end
% size(temp)
% size(u)
% size(v)
eketop=1/2.*sqrt((u*100).^2+(v*100).^2);

temp=nanmean(temp,1);
eketop=nanmean(eketop,1);

% Varq4(t,:) = squeeze(nanmean(squeeze(nanmean(nc{'v'}(posi:step:posi+aux(end)-1,end,idx1,idx2),1)),1));
% Varq5(t,:) = squeeze(nanmean(squeeze(nanmean(nc{'v'}(posi:step:posi+aux(end)-1,end,idx1,idx2),1)),1));

% size(lon1)
% size(temp)

%%
skip=15;
yyaxis left
plot(lon(5:skip:end-4),temp(5:skip:end-4),'-o','linewidth',1.5)
hold on
ylim([10 20])
yyaxis right 
plot(lon(5:skip:end-4),eketop(5:skip:end-4),'-v','linewidth',1.5)
ylim([0 20])

xlabel('')
% ylabel('Depth (m)','FontWeight','bold','FontSize',12)
title([tname],'FontSize',13)
% caxis(cvar)

% set(gca, 'Color',[0.75 0.75 0.75])

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