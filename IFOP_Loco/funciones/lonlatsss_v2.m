function lonlatsss_v2(fname,Yorig,anio,imonth,year,step)

figure('Position', [100, 100, 800, 1000]);
for i=1:12
clear pos    
pos=find(imonth==i & year==anio);
pos(1);
pos(end);
tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');

ax(i)=subplot(4,3,i);
lonlatsss_v1(fname,Yorig,pos(1),pos(end),step,tname)
% set(gca, 'Color',[0.75 0.75 0.75])

end

for i=[2 3 5 6 8 9 11 12]
set(subplot(4,3,i),'yticklabel',[])
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

auxpos=ax(12).Position;

barra=colorbar(ax(12),'Eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,'Salinity [PSU] ','FontWeight','bold','FontSize',12);

% barra.Position=[pos2(1)+0.15 barra.Position(2) barra.Position(3) pos(2)+pos(4)-barra.Position(2)];
barra.Position=[auxpos(1)+auxpos(3) auxpos(2) barra.Position(3)+0.01 ax(3).Position(2)+ax(3).Position(4)-auxpos(2)];

cmap1=colormap_cpt('ch05m151012');
cmap1=flipud(cmap1);
for i=1:12
colormap(ax(i),cmap1)
end

% for i=[1 4 7 10]
% % ylabel(ax(i),'Latitude','FontWeight','bold','FontSize',12)
% xt=get(ax(i),'ytick');
% for k=1:numel(xt);
%     if xt(k)>0
% xt1{k}=sprintf('%g°N',abs(round(xt(k),2)));
%     elseif xt(k)<0
% xt1{k}=sprintf('%g°S',abs(round(xt(k),2)));
%     else
% xt1{k}=sprintf('%g°EQ',abs(round(xt(k),2)));
% end
% set(ax(i),'yticklabel',xt1);
% % set(ax(i),'TickDir','out');
% end
% end
% 
% for i=[10 11 12]
% % ylabel(ax(i),'Latitude','FontWeight','bold','FontSize',12)
% xt=get(ax(i),'xtick');
% for k=1:numel(xt);
%     if xt(k)>0
% xt1{k}=sprintf('%g°E',abs(round(xt(k),2)));
%     elseif xt(k)<0
% xt1{k}=sprintf('%g°W',abs(round(xt(k),2)));
%     else
% xt1{k}=xt(k);
% end
% set(ax(i),'xticklabel',xt1);
% % set(ax(i),'TickDir','out');
% end
% end

return