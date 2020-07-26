win_start
gridfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\mosa_BGQ_grd.nc';
lonsec=[-74.00 -74.00];
latsec=[-43.8 -43.37];
vname='u';
tindex=1;
coef=1;
ncol=10;
zmin=-200;
zmax=0;
xmin=[];
xmax=[];
pltstyle=1;
h0=[];
handles=[];
Yorig=NaN;
cunits=[];

vars={'u','v','temp','salt','O2','PO4','Si','NO3','NH4','NDCHL'}; % 'NCHL','DCHL'}; %,'NPHY','DPHY','MIZOO','MEZOO'};

for j =1:length(vars)
    vname=vars{j}
    for yr = 3:3
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
    
        subplot(2,2,1)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_EFM.nc'];
        etitle=['Y',num2str(yr),'\_EFM'];    
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle,cunits)
               
        subplot(2,2,2)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_AMJ.nc'];
        etitle=['Y',num2str(yr),'\_AMJ'];
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle,cunits)
               
        subplot(2,2,3)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_JAS.nc'];
        etitle=['Y',num2str(yr),'\_JAS'];
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle,cunits)

        subplot(2,2,4)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_OND.nc'];
        etitle=['Y',num2str(yr),'\_OND'];
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle,cunits)

    print('-dpng',['BGuafo_VSection_Y',num2str(yr),'_',vars{j},'.png'])           
    end
end
               