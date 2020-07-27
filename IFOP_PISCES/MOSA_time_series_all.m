close all
clear all
win_start
%function time_series(hisfile,gridfile,lon0,lat0,vname,vlevel,coef)
coef=1;

hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_BGQ_Y1S1-Y3S2.nc'];
gridfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\mosa_BGQ_grd.nc';
vars={'O2','PO4','Si','NO3','NH4','NDCHL'}; % 'NCHL','DCHL'}; %,'NPHY','DPHY','MIZOO','MEZOO'};
%
titles={'Boca-FReloncavi','Cabeza-FReloncavi','Centro-SReloncavi', ...
 'Entrada-SReloncavi','Centro-GAncud','Norte-BGuafo','Centro-BGuafo', ...
 'Sur-BGuafo','M-Balmaceda','Cabeza-FAysen','Medio-FAysen','Boca-FAysen',...
 'Medio-FPuyuhuapi'};
lons=[-72.675,-72.300,-72.875,-72.875,-73.125,-74.025,-74.000,-74.000,-73.050, ...
    -72.875,-73.225,-73.450,-72.775];
lats=[-41.719,-41.476,-41.644,-41.887,-42.054,-43.467,-43.648,-43.700,-43.684, ...
    -45.412,-45.289,-45.395,-44.724];
vlevel=-5;
for i = 1:length(lons)
    figure(i)
for j = 1:length(vars)
    vname = vars{j}
    subplot(3,2,j)
    lon0=lons(i);
    lat0=lats(i);
        switch j
            case 1
                colmin=200;   % O2
                colmax=300;
                cunits='\mu M';
            case 2
                colmin=0;   % PO4
                colmax=2;
                cunits='\mu M';
            case 3
                colmin=0;    % Si
                colmax=100;
                cunits='\mu M';
            case 4
                colmin=0;     % NO3
                colmax=35;
                cunits='\mu M';
            case 5
                colmin=0;    % NH4
                colmax=1;
                cunits='\mu M';
            case 6
                colmin=0;     % NCHL+DCHL
                colmax=2;
                cunits='\mu M';
        end
    AS_time_series(hisfile,gridfile,lon0,lat0,vname,vlevel,coef,titles{i}) %,colmin,colmax)
end
    text(-.5,-.4,[num2str(lons(i)),' ',num2str(lats(i))],'Units','Normalized','FontSize',12)
    print('-dpng',['TimeSeries_',titles{i},'.png'])
end
    
               