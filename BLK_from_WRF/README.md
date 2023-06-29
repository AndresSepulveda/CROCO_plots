# Descripcion
Códigos para usar WRF como forzante (BLK) de CROCO
# Instrucciones de uso

1) ncl 'file_in="wrfout.nc"' 'file_out="wrfpost.nc"' wrfout_to_cf.ncl
2) Editar líneas 12-13, 15-16, 18-91 de wrf2croco.py.
   Asume que:
   2.1) El archivo de salida de WRF se encuentra en el subdirectorio ./WRF
   2.2) El archivo de salida de WRF se llama wrfoutYYYYMMDD.nc (con la fecha de hoy)
   2.3) El archivo de grilla deCROCO se encuentra en el subdirectorio ./CROCO
   2.3) El archivo de grilla de CROCO se llama croco_grd.nc
 3) python wrf2croco.py
