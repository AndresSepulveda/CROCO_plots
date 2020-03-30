function lonlatmany_v2(fname,Yorig,anio,imonth,year,step,posi,posf,lat1,lon1)


figure('Position', [100, 100, 800, 1000]);
for i=1:12
clear pos    
pos=find(imonth==i & year==anio);
pos(1);
pos(end);
tname=month(datetime(year(pos(1)),imonth(pos(1)),day(pos(1))),'name');

ax(i)=subplot(4,3,i);
% lonlatsst_v1(fname,Yorig,pos(1),pos(end),step,tname)}
lonlatmany_v1(fname,Yorig,pos(1),pos(end),lat1,lon1,step,tname)
hold on

% lonlatsss_v1(fname,Yorig,pos(1),pos(end),step,tname)
% lonlatcurrent_v1(fname,Yorig,pos(1),pos(end),step,tname)

% set(gca, 'Color',[0.75 0.75 0.75])
end

for i=[1 4 7 10]
    set(subplot(4,3,i));
    yyaxis left
    ylabel('Temperature [°C]','FontWeight','bold','FontSize',12)
end

for i=[3 6 9 12] 
    set(subplot(4,3,i));    
    yyaxis right
    ylabel('EKE [cm^2/s^2]','FontWeight','bold','FontSize',12)
end

    
return