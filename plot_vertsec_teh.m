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
%min(c_s2000)
%max(c_s2000)

ac_fecha = datetime(ac_yr, ac_mes, ac_dia);
ac_s2000 = seconds(ac_fecha - fecha_base);

%hisfile='crocT_his_Y2001M09.nc';
hisfile09='crocT_avg_Y2000M09.nc';
hisfile10='crocT_avg_Y2000M10.nc';
gridfile='croco_grd.nc';

nh09=netcdf(hisfile09,'r');
tiempo09=nh09{'time'}(:);
nh10=netcdf(hisfile10,'r');
tiempo10=nh10{'time'}(:);

for i = 1:3 % length(c_s2000)
    figure(i)
    c_fecha(i)
    [~, tindex] = min(abs(tiempo09 - c_s2000(i)));
    vertslice(hisfile09,gridfile,[c_lon(i)+0.25 c_lon(i)-0.25], ...
      [c_lat(i)+0.25 c_lat(i)-0.25],'temp',tindex,1,10,28,10,-400,10)
end

for i = 4:length(c_s2000)
    figure(i)
    c_fecha(i)
    [~, tindex] = min(abs(tiempo10 - c_s2000(i)));
    vertslice(hisfile10,gridfile,[c_lon(i)+0.25 c_lon(i)-0.25], ...
      [c_lat(i)+0.25 c_lat(i)-0.25],'temp',tindex,1,10,28,10,-400,10)
end
