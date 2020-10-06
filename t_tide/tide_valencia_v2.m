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

clear all
close all
clc

% 1. Entrada: Nivel del mar (ej. Mareógrafos de Puertos del Estado)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Modificar%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_par='C:\Users\dgeo\croco_tools\';  %directorio del fichero de entrada
fichero='REDMAR_HOR_HIS_Valencia97.txt'; %nombre del fichero de entrada
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

data = load([path_par fichero]); % Cargamos los datos

iok = find(data(:,5) > -9000); % Buscamos datos erróneos
                                  % Modificar el -9000 en función de como
                                  % se especifiquen los datos erróneos

dataok = data(iok,:); % Eliminamos datos erróneos

% 2. Definicion de variables 

year=dataok(:,1); %año
mes=dataok(:,2); %mes
dia=dataok(:,3); %dia
hora=dataok(:,4); %hora

nivelmar=dataok(:,5)/100; % nivel del mar (metros)
 
nivelmedio=mean(nivelmar); % Calculamos el nivel medio del mar
nivelmar=nivelmar-nivelmedio; % Referenciamos respecto al nivel medio

time1=datenum(year,mes,dia,hora,0,0); %Convertimos la fecha en tiempo juliano

% 3. Análisis de armónicos mediante T_IIDE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Modificar%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_des = 'C:\Users\dgeo\croco_tools\';  %Carpeta de destino
fichero_out='Armonicos_Valencia97.txt';  %Nombre del fichero de resultados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[tidestruc,XOUT]=t_tide(nivelmar,'output',[path_des fichero_out]);

   fsig=tidestruc.tidecon(:,1)>tidestruc.tidecon(:,2); % Significant peaks
   tmp=tidestruc.tidecon(fsig,1);
   [Atides,Itides]=sort(tmp,'descend'); 
   Nbtides=length(Atides);
   tmp=tidestruc.tidecon(fsig,3); Ptides=tmp(Itides);
   tmp=tidestruc.name(fsig,:); Ttides=tmp(Itides,:);
   Atides_m=Atides; Ptides_m=Ptides; Ttides_m=Ttides;

     f=figure(3);
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
  title('Datos')

  [NAME,FREQ,TIDECON,XOUT]=t_tide(nivelmar,'output',[path_des fichero_out])

% En NAME se guarda el nombre del armónico
% En FREQ se guarda la frecuencia
% En TIDECON se guarda la amplitud y fase con sus respectivos errores
% En XOUT se guarda la serie temporal de marea meteorológica

% Tras T_TIDE especificamos: (1) variable del nivel del mar 
%                            (2) 'output' especificamos que es una salida
%                            (3) nombre del fichero de salida
 

% 5. Calculamos la marea meteorológica

meteo = nivelmar-XOUT; 

% 6. Representación gráfica

figure(3)

subplot(3,1,1) %Nivel del mar
plot(time1,nivelmar,'k')
title ('Nivel del Mar (m)');
ylabel('NMM (m)')
datetick('x','yyyy-mm')
hold on

subplot(3,1,2) %Marea astronómica
plot(time1,XOUT,'b')
title('Marea Astronomica (m)')
ylabel('NMM_a (m)')
datetick('x','yyyy-mm')

subplot(3,1,3) %Marea meteorológica
plot(time1,meteo,'r')
title('Marea Meteorologica (m)')
xlabel('Fecha ')
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

  
  
