win_start
grdfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\mosa_BGQ_grd.nc';
vname='u';
tindex=1;
vlevel=-5;
rempts=[10 10 10 10];
coef=1;
gridlevs=0;
colmin=0;
colmax=1;
lonmin=[-73.89];
latmin=[-45.60];
lonmax=[-72.65];
latmax=[-45.20];
ncol=10;
pltstyle=1;
isobath='100 100';
cstep=0;
cscale=1;
cunit=0.1;
coastfile=[];
townfile=[];
gridfile=grdfile;
h0=[];
handles=[];
Yorig=NaN;

vars={'u','v','temp','salt','O2','PO4','Si','NO3','NH4','NDCHL'}; % 'NCHL','DCHL'}; %,'NPHY','DPHY','MIZOO','MEZOO'};
season={'EFM','AMJ','JAS','OND'};
for j =1:length(vars)
    vname = vars{j}
    for yr = 1:3
        for m = 1:4
        switch j
            case 1
                colmin=-0.25; %u
                colmax=+0.25;
                cunits='m/s';
            case 2
                colmin=-0.25; % v
                colmax=+0.25;
                cunits='m/s';
            case 3
                colmin=5;     % temp
                colmax=13;
                cunits='°C';
            case 4 
                colmin=33;    % salt
                colmax=34.5;
                cunits='';
            case 5
                colmin=200;   % O2
                colmax=300;
                cunits='\mu M';
            case 6
                colmin=0;   % PO4
                colmax=2;
                cunits='\mu M';
            case 7
                colmin=0;    % Si
                colmax=100;
                cunits='\mu M';
            case 8
                colmin=0;     % NO3
                colmax=35;
                cunits='\mu M';
            case 9
                colmin=0;    % NH4
                colmax=1;
                cunits='\mu M';
            case 10
                colmin=0;     % NCHL+DCHL
                colmax=2;
                cunits='\mu M';
        end
    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_',season{m},'.nc'];
        etitle=['Y',num2str(yr),'\_OND'];
        AS_horizslice(hisfile,vname,tindex,vlevel,rempts,coef,gridlevs,...
                    colmin,colmax,lonmin,lonmax,latmin,latmax,...
		    ncol,pltstyle,isobath,cstep,cscale,cunit,...
		    coastfile,townfile,gridfile,h0,handles,Yorig,yr,season{m})

       print('-dpng',['Surface_FAysen_Y',num2str(yr),'_',season{m},'_',vars{j},'.png'])           
        end 
   end
end
               