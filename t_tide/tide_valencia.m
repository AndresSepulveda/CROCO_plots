%% Análisis de Armónicos de Marea Astronómica mediante T_TIDE
% Preproceso y postproceso by Isabel Jalón Rojas
%
%
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

whos data dataok

% 2. Definicion de variables 

year=dataok(:,1); %año
mes=dataok(:,2); %mes
dia=dataok(:,3); %dia
hora=dataok(:,4); %hora

nivelmar=dataok(:,5)/100; % nivel del mar (metros)
 
nivelmedio=mean(nivelmar); % Calculamos el nivel medio del mar
nivelmar=nivelmar-nivelmedio; % Referenciamos respecto al nivel medio

time1=datenum(year,mes,dia,hora,0,0); %Convertimos la fecha en tiempo juliano

%ojo, en algunas versiones de matlab la función juliandate no existe y en su lugar hay que usar datenum



% 3. Análisis de armónicos mediante T_IIDE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Modificar%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_des = 'C:\Users\dgeo\croco_tools\';  %Carpeta de destino
fichero_out='Armonicos_Valencia97.txt';  %Nombre del fichero de resultados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[NAME,FREQ,TIDECON,XOUT]=t_tide(nivelmar,'output',[path_des fichero_out])

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

save( [path_des marmeteo], 'meteo', '-ascii')

% 6. Representación gráfica

figure(1)

subplot(3,1,1) %Nivel del mar
plot(time1,nivelmar,'k')
title ('Sea level (m)');
%xlabel('Julian Time (days)')
ylabel('NMM (m)')
hold on

subplot(3,1,2) %Marea astronómica
plot(time1,XOUT,'b')
title('Astronomical Tide (m)')
%xlabel('Julian Time (days)')
ylabel('NMM_a (m)')
hold on

subplot(3,1,3) %Marea meteorológica
plot(time1,meteo,'r')
title('Meteorological Tide (m)')
xlabel('Julian Time (days)')
ylabel('NMM_m (m)')
hold on

% 7. Selección componentes más significativas

media = mean(TIDECON(:,1)); %Calculamos la media de la amplitud
isig = find(TIDECON(:,1) > media) %Busca la posición de valores superiores a la media
harm_isig = [TIDECON(isig,1) TIDECON(isig,3)]; %Identifica los valores buscados
name_isig = NAME(isig); %Identifica los valores buscados
freq_isig = FREQ(isig); %Identifica los valores buscados
TOTAL = [freq_isig harm_isig]
