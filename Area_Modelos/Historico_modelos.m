a=load("modelos.txt.txt");

years=a(:,2);
resol=a(:,3);
model=a(:,4);

figure(1)
histogram(years)
xlabel('Año')
ylabel('# modelos')
title('Modelos de la Costa Chilena')

figure(2)
histogram(resol)
xlabel('Tamaño Celda')
ylabel('# modelos')
title('Tamaño Celda de Modelos de la Costa Chilena')

figure(3)
histogram(model)
xlabel('Modelo')
xticks(1:11)
xticklabels({'ROMS','FVCOM','POM','EFDC','FUNDY','NEMO','PE','MOHID','HYCOM','MIKE3','CSIRO'})
ylabel('# usos')
title('Frecuencia de Modelos de la Costa Chilena')