function [v,const]=tidalfitvar(data,components)

% this function uses the HAMELS (ordinary least squares) technique to fit
% tidal components to data

% input_
%
% data      :  A two column vector, first column should be a serial date number, second column should be the y-values (i.e. sea level)
% Components: cell-array of strings with names of the which components should be included in the fit (ALL is default)

% ** The routine will only attempt to fit components that have period<data_timespan/4 and period>dt*2

% modified from tidal functions -> Aslak Grinsted
% Last modification   : 2020-05-07

%% tidalfit
if size(data,2)~=2
    error('data must be a two column data matrix')
    return
end

tminmax=[min(data(:,1)) max(data(:,1))];
dt=min(diff(sortrows(data(:,1)))); %SLOW but robust. dt needed for nyquist
if dt==0
    error('dt==0!')
end

T=15;
s=0.54901653;
h=0.04106864;
p=0.00464183;
p1=0.00000196;

ix= 1; tidal.name{ix}='M2'; 	tidal.speed{ix}	=	2*T - 2*s + 2*h ;
ix= 2; tidal.name{ix}='S2'; 	tidal.speed{ix}	=	2*T;
ix= 3; tidal.name{ix}='N2'; 	tidal.speed{ix}	=	2*T - 3*s + 2*h + p;
ix= 4; tidal.name{ix}='K1'; 	tidal.speed{ix}	=	15.0410686;
ix= 5; tidal.name{ix}='M4'; 	tidal.speed{ix}	=	4*(T - s + h) ;
ix= 6; tidal.name{ix}='O1'; 	tidal.speed{ix}	=	T - 2*s + h;
ix= 7; tidal.name{ix}='M6'; 	tidal.speed{ix}	=	6*(T - s + h);
ix= 8; tidal.name{ix}='MK3'; 	tidal.speed{ix}	=	44.0251729;
ix= 9; tidal.name{ix}='S4'; 	tidal.speed{ix}	=	4*T;
ix=10; tidal.name{ix}='MN4'; 	tidal.speed{ix}	=	57.4238337;
ix=11; tidal.name{ix}='NU2'; 	tidal.speed{ix}	=	28.5125831;
ix=12; tidal.name{ix}='S6'; 	tidal.speed{ix}	=	6*T;
ix=13; tidal.name{ix}='MU2'; 	tidal.speed{ix}	=	27.9682084;
ix=14; tidal.name{ix}='2N2'; 	tidal.speed{ix}	=	2*T - 4*s + 2*h + 2*p;
ix=15; tidal.name{ix}='OO1'; 	tidal.speed{ix}	=	T + 2*s + h;
ix=16; tidal.name{ix}='LAM2'; 	tidal.speed{ix}	=	29.4556253;
ix=17; tidal.name{ix}='S1'; 	tidal.speed{ix}	=	T;
ix=18; tidal.name{ix}='M1'; 	tidal.speed{ix}	=	T - s + h + p ;
ix=19; tidal.name{ix}='J1'; 	tidal.speed{ix}	=	15.5854433;
ix=20; tidal.name{ix}='MM'; 	tidal.speed{ix}	=	s-p;
ix=21; tidal.name{ix}='SSA'; 	tidal.speed{ix}	=	2*h;
ix=22; tidal.name{ix}='SA'; 	tidal.speed{ix}	=	h;
ix=23; tidal.name{ix}='MSF'; 	tidal.speed{ix}	=	2*s-2*h;
ix=24; tidal.name{ix}='MF'; 	tidal.speed{ix}	=	2*s;
ix=25; tidal.name{ix}='RHO'; 	tidal.speed{ix}	=	T - 3*s + 3*h - p;
ix=26; tidal.name{ix}='Q1'; 	tidal.speed{ix}	=	T - 3*s + h + p;
ix=27; tidal.name{ix}='T2'; 	tidal.speed{ix}	=	2*T - h + p1 ;
ix=28; tidal.name{ix}='R2'; 	tidal.speed{ix}	=	2*T + h - p1;
ix=29; tidal.name{ix}='2Q1'; 	tidal.speed{ix}	=	T - 4*s + h + 2*p ;
ix=30; tidal.name{ix}='P1'; 	tidal.speed{ix}	=	T-h;
ix=31; tidal.name{ix}='2SM2'; 	tidal.speed{ix}	=	31.0158958;
ix=32; tidal.name{ix}='M3'; 	tidal.speed{ix}	=	3*T - 3*s + 3*h ;
ix=33; tidal.name{ix}='L2'; 	tidal.speed{ix}	=	29.5284789;
ix=34; tidal.name{ix}='2MK3'; 	tidal.speed{ix}	=	42.9271398;
ix=35; tidal.name{ix}='K2'; 	tidal.speed{ix}	=	30.0821373;
ix=36; tidal.name{ix}='M8'; 	tidal.speed{ix}	=	8*(T - s + h);
ix=37; tidal.name{ix}='MS4'; 	tidal.speed{ix}	=	58.9841042;
ix=38; tidal.name{ix}='N';  	tidal.speed{ix}	=	0.00220641;

for ii=1:length(tidal.speed)
    tidal.period{ii}=(360/tidal.speed{ii})/24;
    tidal.amp{ii}=NaN;
    tidal.phase{ii}=NaN;
end

% Components
for i=1:length(components)
    keep(i)=find(strcmp(tidal.name,components{i})==1);
end

if strcmp(components{1},'ALL')
    keep=1:length(tidal.name);
end

%Check nyquist and long period
ix=([tidal.period{keep}]'>=2*dt)&([tidal.period{keep}]'<=diff(tminmax)/3);
keep=keep(ix);

% exclude NaNs and missing values
data(any(isnan(data),2),:)=[];
N=size(data,1);
Np=length(keep);
if Np==0
    error('No predictors kept. Check nyquist.')
end

isOLS=true;% ordinary least square

predictors=ones(N,Np*2+isOLS);
for ii=1:Np
    period=tidal.period{keep(ii)};
    predictors(:,ii)=cos(data(:,1)*2*pi/period);
    predictors(:,ii+Np)=sin(data(:,1)*2*pi/period);
end

if length(data)>5000
    reg=lsqr(predictors,data(:,2));
else
    reg=predictors\data(:,2);
end

for ii=1:Np
    q=reg([ii ii+Np]);
    if all(isnan(q))
        tidal.amp{keep(ii)}=NaN;
        tidal.phase{keep(ii)}=NaN;
    else
        tidal.amp{keep(ii)}=sqrt(nansum(q.^2));
        q(isnan(q))=0;
        tidal.phase{keep(ii)}=atan2(q(2),q(1));
    end
end

%% tidalvar
t=data(:,1);
keep=~isnan([tidal.amp{:}])';
period=[tidal.period{keep}]';
amp=[tidal.amp{keep}]';
phase=[tidal.phase{keep}]';
Np=length(period);
v=zeros(size(t));
for ii=1:Np
    qt=t*2*pi/period(ii);
    v=v+(amp(ii)*cos(phase(ii))).*cos(qt)+(amp(ii)*sin(phase(ii))).*sin(qt);
end
const=reg(end);
v=v+reg(end);

return