%
%  ncks -F -d time,7297,8016  MOSA_sup_2018_sml_v3.nc MOSA_sup_201811_sml_v3.nc &
%
close all
clear all
oct_start
more off

for i=2:12
	if i < 10
		mnth=['0',num2str(i)];
	else
		mnth=num2str(i);
	end

	hisfile=['MOSA_sup_2018',mnth,'_sml_v3.nc']
	outfile= ['LCS_sup_2018',mnth,'_sml_v3.nc']
	nc=netcdf(hisfile,'r');
	switch i
		case 1
			tini=1;
			tend=744;
		case 2
			tini=745;
			tend=1416;
		case 3
			tini=1417;
			tend=2160;
		case 4
			tini=2161;
			tend=2880;
		case 5
			tini=2881;
			tend=3624;
		case 6
			tini=3625;
			tend=4344;
		case 7
			tini=4345;
			tend=5088;
		case 8
			tini=5089;
			tend=5832;
		case 9
			tini=5833;
			tend=6552;
		case 10
			tini=6553;
			tend=7296;
		case 11
			tini=7297;
			tend=8016;
		case 12 
			tini=8017;
			tend=8760;
	endswitch
        dete=(tend-tini)+1;
        zeta=nc{'zeta'}(:,:,:);
        otime=nc{'ocean_time'}(:);	
    	m_u=nc{'u'}.scale_factor;
	n_u=nc{'u'}.add_offset;
	m_v=nc{'v'}.scale_factor;
	n_v=nc{'v'}.add_offset;
	close(nc)

	whos zeta otime

	gridfile='grd_MIC_1semana.nc';
	coef=1;
	a=1

	[lat,lon,mask]=read_latlonmask(gridfile,'r');
	a=2

	u_rho=zeros(dete,603,231);
	v_rho=u_rho;

	a=3

	vlevel=1;

	for tindex=1:dete %8760
	    tindex
	    u=u2rho_2d(get_hslice(hisfile,gridfile,'u',...
	             tindex,vlevel,'u'));
	    v=v2rho_2d(get_hslice(hisfile,gridfile,'v',...
	             tindex,vlevel,'v'));
	    u_rho(tindex,:,:)=u(:,1:231);
	    v_rho(tindex,:,:)=v;
	end
	u_rho=u_rho.*m_u + n_u;
	v_rho=v_rho.*m_v + n_v;

	a=4

	nout=netcdf(outfile,'c');
		%
		% Dimensions
		%
		nout('longitude') = 231;
		nout('latitude')  = 603;
		nout('time')      = 0;
		%
		% Variables
		%
		nout{'time'} = ncdouble('time');
		nout{'time'}(1:dete) = tini:tend;

		nout{'u_rho'} = ncdouble('time','latitude','longitude');
		nout{'u_rho'}(:,:,:) = u_rho;
	
		nout{'v_rho'} = ncdouble('time','latitude','longitude');
		nout{'v_rho'}(:,:,:) = v_rho;
	close(nout)

end
