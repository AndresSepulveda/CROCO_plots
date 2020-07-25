gridfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\mosa_BGQ_grd.nc';
lonsec=[-74.00 -74.00];
latsec=[-43.8 -43.37];
vname='u';
tindex=1;
coef=1;
colmin=-0.25;
colmax=+0.25;
ncol=10;
zmin=-200;
zmax=0;
xmin=[];
xmax=[];
pltstyle=1;
h0=[];
handles=[];
Yorig=NaN;

figure(1)
    subplot(2,2,1)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y1_EFM.nc';
    etitle='Y1\_EFM';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
    subplot(2,2,2)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y1_AMJ.nc';
    etitle='Y1\_AMJ';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
    subplot(2,2,3)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y1_JAS.nc';
    etitle='Y1\_JAS';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

    subplot(2,2,4)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y1_OND.nc';
    etitle='Y1\_OND';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

figure(2)
    subplot(2,2,1)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y2_EFM.nc';
    etitle='Y2\_EFM';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
    subplot(2,2,2)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y2_AMJ.nc';
    etitle='Y2\_AMJ';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)
               
    subplot(2,2,3)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y2_JAS.nc';
    etitle='Y2\_JAS';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

    subplot(2,2,4)    
    hisfile='C:\Users\dgeo\croco_tools\CONFIGS\MOSA_PISCES\Odette_PISCES_Y2_OND.nc';
    etitle='Y2\_OND';
    AS_vertslice(hisfile,gridfile,lonsec,latsec,vname,tindex,...
                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
            	   pltstyle,h0,handles,Yorig,etitle)

               