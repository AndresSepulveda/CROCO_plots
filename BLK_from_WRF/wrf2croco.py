from netCDF4 import Dataset
from datetime import datetime, date, timedelta
from scipy.interpolate import griddata
from uv2rho import u2rho_2d,v2rho_2d

import numpy as np

today = date.today().strftime("%Y%m%d")
#today = '20250123'

romsdirec = '/data/test_wrf2croco/';
wrfdirec = '/data/test_wrf2croco/';


gridfile = romsdirec+'croco_grd.nc'  
wrffile = wrfdirec+today+'/wrfforecast_'+str(today)+'.nc'
print(wrffile)

# Extrae informacion grilla ROMS
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

# Extrae informacion salida  WRF
ncw = Dataset(wrffile)
time = ncw.variables['XTIME'][:];
latw = ncw.variables['XLAT'][0,:,:];
lonw = ncw.variables['XLONG'][0,:,:];
t2m = ncw.variables['T2'][:]
pres = ncw.variables['PSFC'][:];
qvap = ncw.variables['QVAPOR'][:,0,:,:];
u10 = ncw.variables['U10'][:];
v10 = ncw.variables['V10'][:];
rain1 = ncw.variables['RAINNC'][:];
rain2 = ncw.variables['RAINC'][:];
sw_d = ncw.variables['SWDOWN'][:];
lw_d = ncw.variables['GLW'][:];
lw_u = ncw.variables['OLR'][:];

nt = ncw.dimensions['Time'].size
ny = ncw.dimensions['south_north'].size
nx = ncw.dimensions['west_east'].size

## procesa variables

# tiempo
t0 = date.toordinal(date.today()) -  date.toordinal(date(2000,1,1))
btime = np.array([t0 + i/24 for i in range(nt)])

# Lluvia [cm/dia]
rain = (rain1 + rain2)/10 #% Paso mm a cm
prain = np.zeros((nt,ny,nx))    # Se pasa de acumulativo a horas, quedando cm/h
prain[1:,:,:] = (rain[1:,:,:]-rain[:-1,:,:])*24
prain[0,:,:] = prain[1,:,:]
prain[prain<0] = 0

# Radiacion onda larga
lw = lw_d-lw_u

# Humedad relativa
#rh = rh/100
svp1=611.2
svp2=17.67
svp3=29.65
svpt0=273.15
eps=0.622

rh = (1.E2 * (pres * qvap / (qvap * (1. - eps) + eps)) / (svp1 * np.exp(svp2 * (t2m - svpt0) / (t2m - svp3)))) / 100

t2m = t2m - 273.15

# Escribe netCDF
bulkfile = wrfdirec+'SCRATCH/croco_blk_'+today+'.nc'
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

bulk_time.cycle_length = 0.0
##Interpolando datos
print('Interpolando Datos')

for cc in range(1,nt+1):
	print('Procesando Datos', cc)	
	bulk_time[cc-1] = btime[cc-1]
	tair[cc-1] = griddata((lonw.flatten(),latw.flatten()), t2m[cc-1].flatten(), (lonr, latr), method='linear')
	rhum[cc-1] = griddata((lonw.flatten(),latw.flatten()), rh[cc-1].flatten(), (lonr, latr), method='linear')
	uwnd[cc-1] = griddata((lonw.flatten(),latw.flatten()), u10[cc-1].flatten(), (lonu, latu), method='linear')
	vwnd[cc-1] = griddata((lonw.flatten(),latw.flatten()), v10[cc-1].flatten(), (lonv, latv), method='linear')
	wspd[cc-1] = np.sqrt(u2rho_2d(np.squeeze(uwnd[cc-1]))**2 + v2rho_2d(np.squeeze(vwnd[cc-1])**2))
	radlw[cc-1] = griddata((lonw.flatten(),latw.flatten()), lw[cc-1].flatten(), (lonr, latr), method='linear')
	radlw_in[cc-1] = griddata((lonw.flatten(),latw.flatten()), lw_d[cc-1].flatten(), (lonr, latr), method='linear')
	radsw[cc-1] = griddata((lonw.flatten(),latw.flatten()), sw_d[cc-1].flatten(), (lonr, latr), method='linear')
	prate[cc-1] = griddata((lonw.flatten(),latw.flatten()), prain[cc-1].flatten(), (lonr, latr), method='linear')

nc.close()

