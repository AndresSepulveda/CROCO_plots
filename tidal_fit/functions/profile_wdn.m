function profile_wdn(profile,dates,dateformat,U,V,cbar)

% this function plot a wind/current direction profile 
% 
% input_
%
% profile    : vector with heigth/depth/pressure levels
% dates      : vector with time levels, can be in time format or a simple vector of dt increase
% dateformat : if you use time numeric formate on dates input you can define the format like 'yyyy-mm-dd' or similar, if is a dt increase set dateformat=0
% U          : matrix U component of size profile x dates
% V          : matrix V component of size profile x dates
% cbar       : limits of colormap for magnitude, set to 0 for no magnitude, set to -1 for internal setting, set [BottomLimit UpperLimit] for you desired colorbar limits
%
% Author              : chsegura@udec.cl
% Last modification   : 2020-05-07


%% settings

% tplot='Original Signal';
% tplot='Residual';
% tplot='Constant';
tplot='';
tyaxis='Depth, m';
tcbar='Magnitude, m/s';

if size(profile,2)>1
    profile=profile';
end
if size(dates,1)>1
    dates=dates';
end

Z=1:length(profile);
Z=Z';
time=1:length(dates);

[theta,rho] = cart2pol(U,V);
r=1; 
[u,v]=pol2cart(theta,ones(size(rho)).*r);

% colorbar
auxcmap=jet;
% auxcmap=colormap_cpt('sst.cpt');
% auxcmap=[colormap_cpt('pink-candy'); colormap_cpt('dreaming-copy'); colormap_cpt('twilight')];

% auxcmap=[    0.6196    0.0039    0.2588
%     0.8353    0.2431    0.3098
%     0.9569    0.4275    0.2627
%     0.9922    0.6824    0.3804
%     0.9961    0.8784    0.5451
%     1.0000    1.0000    0.7490
%     0.9020    0.9608    0.5961
%     0.6706    0.8667    0.6431
%     0.4000    0.7608    0.6471
%     0.1961    0.5333    0.7412
%     0.3686    0.3098    0.6353];

wnum=size(auxcmap,1);
wmag=sqrt(U.^2+V.^2);

if (length(cbar)==2 & cbar(1)~=cbar(2) & cbar(1)<cbar(2))
    wcolor=linspace(cbar(1),cbar(2),wnum);
elseif (length(cbar)==2 & cbar(1)==cbar(2))
    disp('Colorbar limits must be different')
    return
elseif (length(cbar)==2 & cbar(1)>cbar(2))
    disp('Colorbar limits must increase')
    return
elseif length(cbar)>2 
    disp('Colorbar limits need only two limits')
    return
elseif cbar==-1
    disp('Colorbar limits are set internally')
    wcolor=linspace(min(min(wmag)),max(max(wmag)),wnum);
elseif cbar==0
    disp('Magnitude are not used')
end


%% plot figure

% h=figure('Position', [100, 100, 1200, 400]);
if length(time)==1
    h=figure('Position', [100, 100, 300, 900]);
else
    h=figure('Position', [100, 100, 1800, 900]);
end

ax=subplot(1,1,1);
for i=1:length(time)
plot(ones(size(Z))*time(i),Z,'k')
hold on
end

if length(dates)>3
space=2;
elseif length(dates)==2
space=1;
elseif length(dates)==1
space=0;
end

if length(time)==1
        xlim([time(1)-1 time(1)+1]);
else
    skip=time(end)-time(end-space);
    skip=abs(skip);
    aux=[time(1)+skip;time(1)-skip;time(end)+skip;time(end)-skip];
    xlim([min(aux) max(aux)]);
end

if length(profile)>3
space=2;
elseif length(profile)==2
space=1;
elseif length(profile)==1
space=0;
end

if length(Z)==1
else
    skip=Z(end)-Z(end-space);
    skip=abs(skip);
    aux=[Z(1)+skip;Z(1)-skip;Z(end)+skip;Z(end)-skip];
    ylim([min(aux) max(aux)]);
end
grid on
set(ax,'tickdir','out')

[xx yy]=meshgrid(time,Z);

for i=1:length(time)
    for j=1:length(Z)
        p1=[xx(j,i) yy(j,i)];
        p2=[xx(j,i)+u(j,i) yy(j,i)+v(j,i)];
        dp=p2-p1;

if cbar==0
    quiver(p1(1),p1(2),dp(1),dp(2),0,'MaxHeadSize',3,'linewidth',1.5,'Color','k')    
else
    if wmag(j,i)<=wcolor(1)
        quiver(p1(1),p1(2),dp(1),dp(2),0,'MaxHeadSize',2,'linewidth',2,'Color',auxcmap(1,:))
    elseif wmag(j,i)>=wcolor(end)
        quiver(p1(1),p1(2),dp(1),dp(2),0,'MaxHeadSize',2,'linewidth',2,'Color',auxcmap(end,:))
    else
        aux=wmag(j,i)-wcolor;
        aux(aux>0)=NaN;
        aux=abs(aux);
        pos=find(aux==min(aux));
        quiver(p1(1),p1(2),dp(1),dp(2),0,'MaxHeadSize',3,'linewidth',1.5,'Color',auxcmap(pos,:)) 
end
end
    
end
end

% xlabel
if dateformat==0
set(ax,'XTick',time,'XTickLabels',dates);  
% xtickangle(45)
else
set(ax,'XTick',time,'XTickLabels',datestr(dates,dateformat));
xtickangle(45)
end
% set(ax,'YTick',flipud(Z),'YTickLabels',flipud(profile));
set(ax,'YTick',Z,'YTickLabels',profile);
xlabel(['Hours'],'FontWeight','b','FontSize',18)

% ylabel
ylabel([tyaxis],'FontWeight','b','FontSize',18)

% title
tname=title({[tplot]},'FontWeight','b','FontSize',20);  
set(tname, 'horizontalAlignment', 'left')
set(tname, 'units', 'normalized')
t1 = get(tname, 'position');
set(tname, 'position', [0 t1(2)+0.02 t1(1)])

% set limits figure
if size(time,2)>1
ax.Position(2)=ax.Position(2)+0.1;
ax.Position(4)=ax.Position(4)-0.2;
pause(1)
posax1=ax.Position;
else
ax.Position(1)=ax.Position(1)+0.15;
ax.Position(2)=ax.Position(2)+0.1;
ax.Position(3)=ax.Position(3)-0.15;
ax.Position(4)=ax.Position(4)-0.2;
pause(1)
posax1=ax.Position;
end

% colormap & colorbar 
if (length(cbar)==2 | cbar(1)==-1)
colormap(ax,auxcmap)

if (length(cbar)==2 & cbar(1)~=cbar(2))
    caxis(ax,[cbar(1) cbar(2)]);
else
    caxis(ax,[min(min(wmag)) max(max(wmag))]);
end

if size(time,2)>1
% barra=colorbar(ax,'location','northoutside','FontWeight','bold','Linewidth',1,'Xtick',wcolor,'XTickLabel',wcolor);
barra=colorbar(ax,'location','northoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,[tcbar],'FontWeight','bold','FontSize',10);
posbar=barra.Position;

barra.Position(1)=posax1(1)+posax1(3)/2;
% barra.Position(2)=posax1(2)+posax1(4)+0.04;
barra.Position(2)=posax1(2)+posax1(4)+0.02;
barra.Position(3)=posbar(3)/2;
% barra.Position(4)=posbar(4)-0.01;
barra.Position(4)=posbar(4);
else
    
barra=colorbar(ax,'location','eastoutside','FontWeight','bold','Linewidth',1);
ylabel(barra,[tcbar],'FontWeight','bold','FontSize',10);
posbar=barra.Position;
    
    
end

end

return