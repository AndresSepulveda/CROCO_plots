clear all
close all
clc

cmap1=colormap_cpt('mby.cpt',256);
colors=[{'r'},{'g'},{'m'},{'y'},{'c'},{'w'}];
data = readtable('coordenadas_dominios.csv');
nm=length(data.lon)/2;
nc=length(colors);
q=floor(nm/nc);
r=rem(nm,nc);

c=1;
for i=1:nm
    lon(:,i)=data.lon(c:c+1);
    lat(:,i)=data.lat(c:c+1);
    c=c+2;
end

for j=0:q
    if j==q
        nf=r;
    else
        nf=nc;
    end
    f=figure(j+1);
    set(gcf, 'Position',  [100, 100, 500, 575])
    m_proj('mercator','lon',[-130 -60],'lat',[-50 25]); 
    m_gshhs('i','save','costa_dominios');
    vec=linspace(-8000,5000,256);

    [CS,CH]=m_etopo2('contourf',vec,'edgecolor','none');
    axes=gca;
    colormap(cmap1)
    m_usercoast('costa_dominios');
    c=0;
    for i=(nc*j+1):(nf+nc*j)
        c=c+1;
        hold on
        m_line([lon(1,i) lon(2,i) lon(2,i) lon(1,i) lon(1,i)],[lat(1,i) lat(1,i) lat(2,i) lat(2,i) lat(1,i)],'linewi',1.5,'color',string(colors(c)))  
        m_text(nanmean(lon(:,i)),nanmean(lat(:,i)),num2str(i),'horizontal','center','vertical','middle','Color',string(colors(c)),'FontSize',16,'FontWeight','bold');
    end
    m_grid('box','fancy','tickdir','out','fontsize',10,'xtick',[-120, -110, -100, -90, -80, -70, -60],'ytick',[20,10,0,-10,-20,-30,-40,-50]);
    if c==1
        nombre=strcat('Dominio de modelo',{' '},num2str(nc*j+1));
        nombre2=strcat('Dominio_de_modelo_',num2str(nc*j+1));
    else        
        nombre=strcat('Dominios de modelos',{' '},num2str(nc*j+1),{' '},'a',{' '},num2str(nf+nc*j));
        nombre2=strcat('Dominios_de_modelos_',num2str(nc*j+1),'_a_',num2str(nf+nc*j));   
    end
    title(nombre)
    print(string(nombre2),'-dpng','-r150');
end