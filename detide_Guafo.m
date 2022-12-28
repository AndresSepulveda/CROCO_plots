%
%  detide_Guafo.m
%
%  Andres Sepulveda (2022/12/28)
%
win_start

nc=netcdf('mosa_BGQ_BGuafo.nc','r');
%
% eta_rho (Y direction) = 33, s_rho = 42, time = 721, xi_u = 1
%
%            t,z,y,x   
uvel=nc{'u'}(:,:,:,:);
uvel=squeeze(uvel);

aux_uvel=squeeze(uvel(1,:,:));
residual=aux_uvel*NaN;
ampM2=aux_uvel*NaN;
phaM2=aux_uvel*NaN;
ampO1=aux_uvel*NaN;
phaO1=aux_uvel*NaN;
ampS2=aux_uvel*NaN;
phaS2=aux_uvel*NaN;

time1=nc{'time'}(:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%Modificar%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
path_des = 'C:\Users\geofisica\croco_tools\';  %Carpeta de destino
fichero_out='Armonicos_Guafo.txt';  %Nombre del fichero de resultados
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

j=1; % Plots

for y=1:33
    for z=1:42
        ts_u=uvel(:,z,y);
        nivelmar=ts_u;
        if abs(max(nivelmar))+abs(min(nivelmar)) > 0
            
        [NAME,FREQ,TIDECON,XOUT]=t_tide(nivelmar,'output',[path_des fichero_out]);

        % En NAME se guarda el nombre del armónico
        % En FREQ se guarda la frecuencia
        % En TIDECON se guarda la amplitud y fase con sus respectivos errores
        % En XOUT se guarda la serie temporal de marea astronomica

        % Tras T_TIDE especificamos: (1) variable del nivel del mar 
        %                            (2) 'output' especificamos que es una salida
        %                            (3) nombre del fichero de salida
 
        % 5. Calculamos la marea meteorológica y la guardamos

        meteo = nivelmar-XOUT; 

        % 6. Representación gráfica
    
        %figure(j)

        %subplot(3,1,1) %Nivel del mar
        %plot(time1,nivelmar,'k')
        %title ('Nivel del Mar (m)');
        %%xlabel('Julian Time (days)')
        %ylabel('NMM (m)')
        %datetick('x','yyyy-mm')
        %hold on

        %subplot(3,1,2) %Marea astronómica
        %plot(time1,XOUT,'b')
        %title('Marea Astronomica (m)')
        %xlabel('Julian Time (days)')
        %ylabel('NMM_a (m)')
        %datetick('x','yyyy-mm')

        %subplot(3,1,3) %Marea meteorológica
        %plot(time1,meteo,'r')
        %title('Marea Meteorologica (m)')
        %xlabel('Tiempo Juliano (dias)')
        %ylabel('NMM_m (m)')
        %datetick('x','yyyy-mm')

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

        TOTAL = [name_isig num2str(freq_isig) name_isig(:,4)  num2str(harm_isig)];
        %disp(' Nombre Frecuencia Amplitud Fase ');

        aux=ismember(NAME,'K1  ','rows');
        indxK1=find(aux==1);
        aux=ismember(NAME,'O1  ','rows');
        indxO1=find(aux==1);
        aux=ismember(NAME,'M2  ','rows');
        indxM2=find(aux==1);
        aux=ismember(NAME,'S2  ','rows');
        indxS2=find(aux==1);

        aK1=TIDECON(indxK1,1);
        aO1=TIDECON(indxO1,1);
        aM2=TIDECON(indxM2,1);
        aS2=TIDECON(indxS2,1);

        pK1=TIDECON(indxK1,3);
        pO1=TIDECON(indxO1,3);
        pM2=TIDECON(indxM2,3);
        pS2=TIDECON(indxS2,3);

        residual(z,y)=median(meteo);
        %hist(meteo,20)
        %pause
        ampM2(z,y)=aM2;
        ampO1(z,y)=aO1;
        ampS2(z,y)=aS2;
        phaM2(z,y)=pM2;
        phaO1(z,y)=pO1;       
        phaS2(z,y)=pS2;
        
        %disp('                   ')
        %disp('Factor de Forma (F)')

        F=(aK1+aO1)/(aM2+aS2);

        if F <0.26 
            disp('Marea Semidiurna')
        elseif 0.25 < F  & F < 1.5
           disp('Marea mixta con predominio semidiurno')
        elseif 1.50 < F  & F < 3
            disp('Marea mixta con predominio diurno')
        else
            disp('Marea Diurna')
        end 
        j=j+1;
%        keyboard
        end     
    end
end

save -ascii Guafo_ampM2.txt ampM2
save -ascii Guafo_ampO1.txt ampO1
save -ascii Guafo_phaM2.txt phaM2
save -ascii Guafo_phaO1.txt phaO1
save -ascii Guafo_residual.txt residual

figure(1)
pcolor(flipud(ampM2))
colorbar
title('Amplitud M2')
figure(2)
pcolor(flipud(ampS2))
colorbar
title('Amplitud S2')
figure(3)
pcolor(flipud(ampO1))
colorbar
title('Amplitud O1')
figure(4)
pcolor(flipud(residual))
colorbar
title('Residual')
