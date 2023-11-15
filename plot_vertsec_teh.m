close all
clear all
start

archivo = 'dipolo.mat'; 
datos = load(archivo);

c_dia = datos.rem_cic(:,1);
c_mes = datos.rem_cic(:,2);
c_yr = datos.rem_cic(:,3);
c_lon = datos.rem_cic(:,4);
c_lat = datos.rem_cic(:,5);

ac_dia = datos.rem_ant(:,1);
ac_mes = datos.rem_ant(:,2);
ac_yr = datos.rem_ant(:,3);
ac_lon = datos.rem_ant(:,4);
ac_lat = datos.rem_ant(:,5);

fecha_base = datetime(2000, 1, 1);

c_fecha = datetime(c_yr, c_mes, c_dia);
c_s2000 = seconds(c_fecha - fecha_base);
min(c_s2000)
max(c_s2000)

ac_fecha = datetime(ac_yr, ac_mes, ac_dia);
ac_s2000 = seconds(ac_fecha - fecha_base);

%hisfile='crocT_his_Y2001M09.nc';
hisfile='crocT_avg_Y2000M09.nc';
gridfile='croco_grd.nc';

nh=netcdf(hisfile,'r');
tiempo=nh{'time'}(:);

for i = 1:1 % length(c_s2000)
    [~, tindex] = min(abs(tiempo - c_s2000(i)));
    tindex
    min(tiempo)
    max(tiempo)
    c_s2000(i)
    figure(i)
    vertslice(hisfile,gridfile,[c_lon(i)+0.25 c_lon(i)-0.25],[c_lat(i)+0.25 c_lat(i)-0.25],'temp',tindex,1,10,28,10,-400,10) %,...
%                   1,20,25,0,10,-200)
%    vertslice(hisfile,gridfile,[c_lon+0.5 c_lon-0.5],[c_lat+0.5 c_lat-0.5],'temp',tindex,...
%                   coef,colmin,colmax,ncol,zmin,zmax,xmin,xmax,...
%		   pltstyle,h0,handles,Yorig)

end
