%% example 

% for more information check the functions!

%% settings

addpath('data/')
addpath('functions/')

% total depth
H=13;

% levels
s_rho = [-0.9880952, -0.9642857, -0.9404762, -0.9166667, -0.8928571,...
    -0.8690476, -0.8452381, -0.8214286, -0.797619, -0.7738096, -0.75,... 
    -0.7261904, -0.702381, -0.6785714, -0.6547619, -0.6309524, -0.6071429,... 
    -0.5833333, -0.5595238, -0.5357143, -0.5119048, -0.4880952, -0.4642857,... 
    -0.4404762, -0.4166667, -0.3928571, -0.3690476, -0.3452381, -0.3214286,...
    -0.297619, -0.2738095, -0.25, -0.2261905, -0.202381, -0.1785714,...
    -0.1547619, -0.1309524, -0.1071429, -0.08333334, -0.05952381, -0.03571429, -0.01190476];

s_rho=s_rho'; 

% profile
profile=s_rho*H;
format short g
profile=round(profile*100)/100;

% matrix to change
% U=load('u_vels_2014.txt'); 
% V=load('v_vels_2014.txt');
U=load('u_vels.txt'); 
V=load('v_vels.txt');

% 1 hr of dt in datenumber
a1=datenum(2001,06,01,0,30,0);
a2=datenum(2001,06,01,1,30,0);

% vector of time
clear dates
dates(1,:)=a1;
for i=2:size(U,2)
    dates(1,i)=dates(1,i-1)+(a2-a1);
end

% tidal fitting
clear Ures Vres U0 V0
[Ures,Vres,U0,V0]=tidal(profile,dates,U,V);% residuals and constants

% vector of time (not datenumber!)
dateformat=0;% for dt vector
dates=1:size(U,2);

xx=94:94+72;% 3 days selected

%% profiles

% original profiles
profile_wdn(profile,1:length(dates(xx)),dateformat,U(:,xx),V(:,xx),[0 0.4])% for changes on title,labels edit the function first section
title('Original Signal')

% residual profile
profile_wdn(profile,1:length(dates(xx)),dateformat,Ures(:,xx),Vres(:,xx),[0 0.4])
title('Residual')

% constant profile
profile_wdn(profile,1,dateformat,U0,V0,[0 0.4])
title('Residual')

%% serial plots U component

% select a level on profile
ll(1)=length(profile);% top
ll(2)=floor(length(profile)/2);% mid
ll(3)=1;% bottom

h=figure('Position', [100, 100, 1500, 800]);
pos=[1 3 5];
for i=1:3
ax(pos(i))=subplot(3,2,pos(i));
p(1)=plot(U(ll(i),:),'k');% 
hold on
p(3)=plot(Ures(ll(i),:),'r');
p(2)=plot(U(ll(i),:)-Ures(ll(i),:),'g');

% ylabel
ylabel(['magnitude, m/s'],'FontWeight','b','FontSize',12)
% ylim([-0.6 0.6])

% title
tname=title({['U at ',num2str(profile(ll(i))),'m']},'FontWeight','b','FontSize',14);  
set(tname, 'horizontalAlignment', 'left')
set(tname, 'units', 'normalized')
t1 = get(tname, 'position');
set(tname, 'position', [0 t1(2)+0.02 t1(1)])

% legend
legend([p],'Original','Reconstituted','Residual','location','northwest')

% settings
axis tight
grid on
set(ax(pos(i)),'TickDir','out');
end

% xlabel
xlabel(ax(pos(i)),['steps'])

%% serial plots V component

% select a level on profile
ll(1)=length(profile);% top
ll(2)=floor(length(profile)/2);% mid
ll(3)=1;% bottom

% h=figure('Position', [100, 100, 900, 800]);
pos=[2 4 6];
for i=1:3    
ax(pos(i))=subplot(3,2,pos(i));
p(1)=plot(V(ll(i),:),'k');% 
hold on
p(3)=plot(Vres(ll(i),:),'r');
p(2)=plot(V(ll(i),:)-Vres(ll(i),:),'g');

% ylabel
ylabel(['magnitude, m/s'],'FontWeight','b','FontSize',12)
% ylim([-0.6 0.6])

% title
tname=title({['V at ',num2str(profile(ll(i))),'m']},'FontWeight','b','FontSize',14);  
set(tname, 'horizontalAlignment', 'left')
set(tname, 'units', 'normalized')
t1 = get(tname, 'position');
set(tname, 'position', [0 t1(2)+0.02 t1(1)])

% legend
legend([p],'Original','Reconstituted','Residual','location','northwest')

% settings
axis tight
grid on
set(ax(pos(i)),'TickDir','out');
end

% xlabel
xlabel(ax(pos(i)),['steps'])
