
## Correct error

    GET_INITIAL - unable to find variable: hmorph
               in input NetCDF file: croco_ini_sed.nc

with

    ncks -v h croco_ini_sed.nc hmorph.nc
    ncrename -h -O -v h,hmorph hmorph.nc
    ncatted -O -a long_name,hmorph,o,c,"moving bathymetry " hmorph.nc
    ncatted -O -a field,hmorph,o,c,"moving bathymetry, scalar, series " hmorph.nc
    ncatted -O -a standard_name,hmorph,o,c,"moving bathymetry " hmorph.nc 
    ncks -h -A hmorph.nc croco_ini_sed.nc
