function hovmullersst_v3()

figure('Position', [100, 100, 1000, 700]);
% for i=1:12
clear pos    
% pos=find((imonth==12|imonth==1|imonth==2) & year==10);
pos=find((imonth==1|imonth==2) & year==10);
pos(1);
pos(end);
% tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');
tname='DJF';
ax(1)=subplot(2,2,1);
hovmullersst_v1(fname,Yorig,pos(1),pos(end),tname)
% end
clear pos    
pos=find((imonth==3|imonth==4|imonth==5) & year==10);
pos(1);
pos(end);
% tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');
tname='MAM';
ax(2)=subplot(2,2,2);
hovmullersst_v1(fname,Yorig,pos(1),pos(end),tname)

clear pos    
pos=find((imonth==6|imonth==7|imonth==8) & year==10);
pos(1);
pos(end);
% tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');
tname='JJA';
ax(3)=subplot(2,2,3);
hovmullersst_v1(fname,Yorig,pos(1),pos(end),tname)

clear pos    
pos=find((imonth==9|imonth==10|imonth==11) & year==10);
pos(1);
pos(end);
% tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');
tname='SON';
ax(4)=subplot(2,2,4);
hovmullersst_v1(fname,Yorig,pos(1),pos(end),tname)

%%
for i=[2 4]
set(subplot(2,2,i),'yticklabel',[])
end

for i=[1 2 3 4 5 6 7 8 9]
set(subplot(4,3,i),'xticklabel',[])
end

% for i=[10 11 12]
% set(subplot(4,3,i),'xticklabel',[7 14 21 28])
% end

pos=ax(2).Position;
pos2=ax(3).Position;

ax(2).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(5).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(8).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];
ax(11).Position(1)=[pos(1)-0.05];% pos(2) pos(3) pos(4)];

ax(3).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(6).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(9).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];
ax(12).Position(1)=[pos2(1)-0.1];% pos(2) pos(3) pos(4)];

ax(1).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(4).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(7).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];
ax(10).Position(3)=[pos2(3)];% pos(2) pos(3) pos(4)];

ax(1).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(4).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(7).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];
ax(10).Position(4)=[pos2(4)];% pos(2) pos(3) pos(4)];

barra=colorbar(ax(12),'Eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,' SST (°C) ','FontWeight','bold','FontSize',12);

barra.Position=[pos2(1)+0.15 barra.Position(2) barra.Position(3) pos(2)+pos(4)-barra.Position(2)];

cmap1=colormap_cpt('sst.cpt');
for i=1:12
colormap(ax(i),cmap1)
end

for i=[1 4 7 10]
ylabel(ax(i),'Latitude','FontWeight','bold','FontSize',12)
end

return