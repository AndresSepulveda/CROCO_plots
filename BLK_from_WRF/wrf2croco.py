#
# Desarrollado por Osvaldo Artal (IFOP-Putemún): osvaldo.artal@ifop.cl
#
from netCDF4 import Dataset
from datetime import datetime, date, timedelta
from scipy.interpolate import griddata
from uv2rho import u2rho_2d,v2rho_2d

import numpy as np


today2 = date.today()
today = today2.strftime("%Y%m%d")

romsdirec = './CROCO_FILES/';
wrfdirec = './WRF/';

gridfile = romsdirec+'croco_grd.nc'  
wrffile = wrfdirec+today+'/wrfout'+str(today2)+'.nc'
print wrffile

# Extrae datos de grilla ROMS
ng = Dataset(gridfile)
latr = ng.variables['lat_rho'][:]
latu = ng.variables['lat_u'][:]
latv = ng.variables['lat_v'][:]
lonr = ng.variables['lon_rho'][:]
lonu = ng.variables['lon_u'][:]
lonv = ng.variables['lon_v'][:]

etar = ng.dimensions['eta_rho'].size
etau = ng.dimensions['eta_u'].size
etav = ng.dimensions['eta_v'].size
xir = ng.dimensions['xi_rho'].size
xiu = ng.dimensions['xi_u'].size
xiv = ng.dimensions['xi_v'].size

ncw = Dataset(wrffile)
time = ncw.variables['time'][:];
latw = ncw.variables['south_north'][:];
lonw = ncw.variables['west_east'][:];
sst = ncw.variables['SST'][:];
t2m = ncw.variables['T_2m'][:];
rh = ncw.variables['rh_2m'][:];
u10 = ncw.variables['u_10m_gr'][:];
v10 = ncw.variables['v_10m_gr'][:];
rain1 = ncw.variables['precip_g'][:];
rain2 = ncw.variables['precip_c'][:];
sw_d = ncw.variables['SW_d'][:];
lw_d = ncw.variables['LW_d'][:];
lw_u = ncw.variables['LW_u_toa'][:];
sh = ncw.variables['SH'][:];
lh = ncw.variables['LH'][:];

nt = ncw.dimensions['time'].size
ny = ncw.dimensions['south_north'].size
nx = ncw.dimensions['west_east'].size

## procesa variables

# tiempo
t0 = date.toordinal(date.today()) -  date.toordinal(date(2000,1,1))
tf = date.toordinal(date.today()) -  date.toordinal(date(2000,1,1)) + 5 
dt = (time[2] - time[1]) / 24
btime = np.arange(t0,tf,dt)

# Lluvia [cm/dia]
rain = (rain1 + rain2)/10 #% Paso mm a cm
prain = np.zeros((nt,ny,nx))    # Se pasa de acumulativo a horas, quedando cm/h
prain[1:,:,:] = (rain[1:,:,:]-rain[:-1,:,:])*24
prain[0,:,:] = prain[1,:,:]
prain[prain<0] = 0

# Radiacion onda larga
lw = lw_d-lw_u

# Humedad relativa
rh = rh/100

## Interpolando datos
print('Interpolando Datos')
X,Y = np.meshgrid(lonw,latw)

bulkfile = romsdirec+'/croco_blk_WRF_'+str(t0)+'.nc'
nc = Dataset(bulkfile,'w')

nc.createDimension('bulk_time',nt)
nc.createDimension('xi_rho',xir)
nc.createDimension('xi_u',xiu)
nc.createDimension('xi_v',xiv)
nc.createDimension('eta_rho',etar)
nc.createDimension('eta_u',etau)
nc.createDimension('eta_v',etav)

bulk_time = nc.createVariable('bulk_time','f8', ('bulk_time',))
tair = nc.createVariable('tair','f8', ('bulk_time','eta_rho','xi_rho',))
rhum = nc.createVariable('rhum','f8', ('bulk_time','eta_rho','xi_rho',))
wspd = nc.createVariable('wspd','f8', ('bulk_time','eta_rho','xi_rho',))
uwnd = nc.createVariable('uwnd','f8', ('bulk_time','eta_u','xi_u',))
vwnd = nc.createVariable('vwnd','f8', ('bulk_time','eta_v','xi_v',))
radlw = nc.createVariable('radlw','f8', ('bulk_time','eta_rho','xi_rho',))
radlw_in = nc.createVariable('radlw_in','f8', ('bulk_time','eta_rho','xi_rho',))
radsw = nc.createVariable('radsw','f8', ('bulk_time','eta_rho','xi_rho',))
prate = nc.createVariable('prate','f8', ('bulk_time','eta_rho','xi_rho',))

for cc in range(1,nt+1):
	print('Procesando Datos', cc)	
	bulk_time[cc-1] = btime[cc-1]
	tair[cc-1] = griddata((X.flatten(),Y.flatten()), t2m[cc-1].flatten(), (lonr, latr), method='linear')
	rhum[cc-1] = griddata((X.flatten(),Y.flatten()), rh[cc-1].flatten(), (lonr, latr), method='linear')
	uwnd[cc-1] = griddata((X.flatten(),Y.flatten()), u10[cc-1].flatten(), (lonu, latu), method='linear')
	vwnd[cc-1] = griddata((X.flatten(),Y.flatten()), v10[cc-1].flatten(), (lonv, latv), method='linear')
	wspd[cc-1] = np.sqrt(u2rho_2d(np.squeeze(uwnd[cc-1]))**2 + v2rho_2d(np.squeeze(vwnd[cc-1])**2))
	radlw[cc-1] = griddata((X.flatten(),Y.flatten()), lw[cc-1].flatten(), (lonr, latr), method='linear')
	radlw_in[cc-1] = griddata((X.flatten(),Y.flatten()), lw_d[cc-1].flatten(), (lonr, latr), method='linear')
	radsw[cc-1] = griddata((X.flatten(),Y.flatten()), sw_d[cc-1].flatten(), (lonr, latr), method='linear')
	prate[cc-1] = griddata((X.flatten(),Y.flatten()), prain[cc-1].flatten(), (lonr, latr), method='linear')

nc.close()

