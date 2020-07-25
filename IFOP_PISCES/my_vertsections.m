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

vars={'u','v','temp','salt','O2','PO4','Si','NO3','NH4','NCHL','DCHL'}; %,'NPHY','DPHY','MIZOO','MEZOO'};

for j =1:length(vars)
    vname=vars{j}
    for yr = 1:2
        switch j
            case 1
                colmin=-0.25; %u
                colmax=+0.25;
            case 2
                colmin=-0.25; % v
                colmax=+0.25;
            case 3
                colmin=5;     % temp
                colmax=13;
            case 4 
                colmin=33;    % salt
                colmax=34.5;
            case 5
                colmin=200;   % O2
                colmax=300;
            case 6
                colmin=0.8;   % PO4
                colmax=2.2;
            case 7
                colmin=30;    % Si
                colmax=95;
            case 8
                colmin=8;     % NO3
                colmax=20;
            case 9
                colmin=0.1;    % NH4
                colmax=0.8;
            case 10
                colmin=0.05;     % NCHL
                colmax=0.4;
            case 11
                colmin=0;     % DCHL
                colmax=3;
        end
    
        subplot(2,2,1)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_EFM.nc'];
        etitle='Y1\_EFM';    
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
        subplot(2,2,2)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_AMJ.nc'];
        etitle='Y1\_AMJ';
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
        subplot(2,2,3)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_JAS.nc'];
        etitle='Y1\_JAS';
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

        subplot(2,2,4)    
        hisfile=['C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y',num2str(yr),'_OND.nc'];
        etitle='Y1\_OND';
        AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

    print('-dpng',['Y',num2str(yr),'_',vars{j},'.png'])           
    end
end
