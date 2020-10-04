% Adaptado de: 
% Análisis de Armónicos de Marea Astronómica mediante T_TIDE
% Preproceso y postproceso by Isabel Jalón Rojas
% https://isabeljalonrojas.com/analisis-de-armonicos-de-marea-astronomica-con-t_tide/
%
% y
%
% valid_tides.m de CROCO_TOOLS
%
% 20201002 Andres Sepulveda (andres.sepulveda@gmail.com)
%
close all
clear all
win_start
%
% Data from: https://uhslc.soest.hawaii.edu/
%
nc=netcdf('OS_UH-FDH022_20170628_R.nc','r');  % Easter Island
%nc=netcdf('OS_UH-FDH015_20170628_R.nc','r');  % Papette 376944 points

time=nc{'time'}(300000:end);    %Days since 17000101 / Gregorian
depth=nc{'depth'}(:);  % m
lat=nc{'latitude'}(:);
lon=nc{'longitude'}(:);
slvl=nc{'sea_surface_height_above_reference_level'}(300000:end); % in mm. Bad = -32768
id=nc.id(:);
name=nc.station_name(:);
close(nc)

fecha=datetime(1700,1,1)+days(time);

slvl(slvl < -30000)=NaN;

figure(1)
plot(fecha,slvl/1000)
title([name ' ID: ',id])
xlabel('Fecha')
ylabel('Nivel del Mar [m]')

m_slvl=nanmean(slvl);
nivelmar=(slvl-m_slvl)/1000;   % mm -> m

fecha_v=datevec(fecha(1));

[tidestruc,XOUT]=t_tide(nivelmar,'output','none');

   fsig=tidestruc.tidecon(:,1)>tidestruc.tidecon(:,2); % Significant peaks
   tmp=tidestruc.tidecon(fsig,1);
   [Atides,Itides]=sort(tmp,'descend'); 
   Nbtides=length(Atides);
   tmp=tidestruc.tidecon(fsig,3); Ptides=tmp(Itides);
   tmp=tidestruc.name(fsig,:); Ttides=tmp(Itides,:);
   Atides_m=Atides; Ptides_m=Ptides; Ttides_m=Ttides;

     f=figure(1);
  set(f,'Units','normalized','Position',[0. 0. 0.4 0.4]);
%
  fsig=tidestruc.tidecon(:,1)>tidestruc.tidecon(:,2); % Significant peaks
  semilogy([tidestruc.freq(~fsig),tidestruc.freq(~fsig)]', ...
       [.0005*ones(sum(~fsig),1),tidestruc.tidecon(~fsig,1)]','.-r');
  line([tidestruc.freq(fsig),tidestruc.freq(fsig)]', ...
       [.0005*ones(sum(fsig),1),tidestruc.tidecon(fsig,1)]','marker','.','color','b');
  line(tidestruc.freq,tidestruc.tidecon(:,2),'linestyle',':','color',[0 .5 0]);
  set(gca,'ylim',[.0005 1],'xlim',[0 .5]);
  xlabel('Frecuencia (cph)');
  text(tidestruc.freq,tidestruc.tidecon(:,1),tidestruc.name,'rotation',45,'vertical','base');
  ylabel('Amplitud (m)');
  text(.25,.2,'Constituyentes Significativos','color','b');
  text(.25,.1,'Constituyentes No Significativos','color','r');
  text(.25,.05,'Nivel Significancia 95%','color',[0 .5 0]);
  title(['Datos ' name])

  [NAME,FREQ,TIDECON,XOUT]=t_tide(nivelmar,'output','none');

% En NAME se guarda el nombre del armónico
% En FREQ se guarda la frecuencia
% En TIDECON se guarda la amplitud y fase con sus respectivos errores
% En XOUT se guarda la serie temporal de marea meteorológica

% Tras T_TIDE especificamos: (1) variable del nivel del mar 
%                            (2) 'output' especificamos que es una salida
%                            (3) nombre del fichero de salida
 

% 5. Calculamos la marea meteorológica y la guardamos

meteo = nivelmar-XOUT; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Modificar%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
marmeteo='MarMeteo_MarMenor.txt';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% 6. Representación gráfica

figure(2)

subplot(3,1,1) %Nivel del mar
plot(fecha,nivelmar,'k')
title (['Nivel del Mar (m) ' name ]);
%xlabel('Julian Time (days)')
ylabel('NMM (m)')
datetick('x','yyyy-mm')
hold on

subplot(3,1,2) %Marea astronómica
plot(fecha,XOUT,'b')
title('Marea Astronomica (m)')
%xlabel('Julian Time (days)')
ylabel('NMM_a (m)')
datetick('x','yyyy-mm')

subplot(3,1,3) %Marea meteorológica
plot(fecha,meteo,'r')
title('Marea Meteorologica (m)')
xlabel('Tiempo Juliano (dias)')
ylabel('NMM_m (m)')
datetick('x','yyyy-mm')

% 7. Selección componentes más significativas

media = mean(TIDECON(:,1)); %Calculamos la media de la amplitud
isig = find(TIDECON(:,1) > media); %Busca la posición de valores superiores a la media

TIDECON=round(TIDECON*1000)/1000;

[aux indx]=sort(TIDECON(isig,1));

indx=flipud(indx);   % Orden Decreciente

harm_isig = [TIDECON(isig(indx),1) TIDECON(isig(indx),3)]; %Identifica los valores buscados
name_isig = NAME(isig(indx),:); %Identifica los valores buscados
freq_isig = FREQ(isig(indx)); %Identifica los valores buscados

freq_isig=round(freq_isig*10000)/10000;

TOTAL = [name_isig num2str(freq_isig) name_isig(:,4)  num2str(harm_isig)]
disp(' Nombre Frecuencia Amplitud Fase ')

  
  