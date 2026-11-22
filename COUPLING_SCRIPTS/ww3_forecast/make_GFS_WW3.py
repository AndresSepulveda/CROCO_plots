#!/usr/bin/env python3
#======================================================================
#
#  make_GFS_WW3.py : create the WW3 wind forcing file (wind.nc) from
#  the GFS 0.25 deg hourly GRIB2 subsets downloaded by trae_gen.csh
#  (NOMADS grib filter). The file is read by ww3_prnc ('WND' 'LL').
#  Replaces make_GFS_WW3_gen.m (ascii file for ww3_prep).
#
#  Time series built as in the original "best time series":
#   - day -1 : cycles 00, 06, 12, 18 of yesterday, forecasts f000-f005
#   - forecast: cycle GFS_CYCLE of today, f000 - f(FHMAX)
#  When two files give the same valid time, the most recent cycle wins.
#
#  Environment (exported by ww3_forecast.sh):
#    LLLON LLLAT URLON URLAT DAY_STR DAY_END RUNDIR
#
#  This file is part of WW3TOOLS
#
#  WW3TOOLS is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 2 of the License,
#  or (at your option) any later version.
#
#  WW3TOOLS is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#  MA  02111-1307  USA
#
#  The on-line reference to GFS is at
#  https://nomads.ncep.noaa.gov/
#
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Updated November 2026 by Andres Sepulveda:
#    - Translated to Python 3 (xarray/cfgrib, wgrib2 fallback)
#    - GFS 0.25 deg hourly from NOMADS, netCDF output for ww3_prnc
#
#======================================================================
import glob
import os
import re
import shutil
import subprocess
import datetime as dt

import numpy as np

from start import get_config, write_nc_ll
from get_missing_val import get_missing_val

cfg = get_config()
lonmin, lonmax, latmin, latmax = cfg['lonmin'], cfg['lonmax'], cfg['latmin'], cfg['latmax']
gfsdir = os.path.join(cfg['rundir'], 'GFS')
outfile = os.path.join(cfg['rundir'], 'wind.nc')
pattern = re.compile(r'gfs_(\d{8})(\d{2})_f(\d{3})\.grib2$')


def read_grib(fname):
    """Return lon, lat, u10, v10 from a GFS GRIB2 subset."""
    try:
        import xarray as xr
        ds = xr.open_dataset(fname, engine='cfgrib', backend_kwargs=dict(
            filter_by_keys={'typeOfLevel': 'heightAboveGround', 'level': 10},
            indexpath=''))
        lon, lat = ds['longitude'].values, ds['latitude'].values
        u, v = ds['u10'].values, ds['v10'].values
        ds.close()
    except Exception:
        # fallback: wgrib2 -> netCDF
        if shutil.which('wgrib2') is None:
            raise RuntimeError('install cfgrib (eccodes) or wgrib2 to read GFS GRIB2')
        tmp = fname + '.nc'
        subprocess.run(['wgrib2', fname, '-netcdf', tmp], check=True,
                       stdout=subprocess.DEVNULL)
        from netCDF4 import Dataset
        nc = Dataset(tmp)
        lon, lat = nc['longitude'][:], nc['latitude'][:]
        u = nc['UGRD_10maboveground'][0]
        v = nc['VGRD_10maboveground'][0]
        nc.close()
        os.remove(tmp)
    lon = np.where(lon > 180., lon - 360., lon)
    return np.asarray(lon), np.asarray(lat), np.asarray(u, float), np.asarray(v, float)


#
# Inventory of downloaded files: valid time -> (cycle, file)
#
files = {}
for f in sorted(glob.glob(os.path.join(gfsdir, 'gfs_*.grib2'))):
    m = pattern.search(f)
    if not m or os.path.getsize(f) == 0:
        continue
    cycle = dt.datetime.strptime(m.group(1) + m.group(2), '%Y%m%d%H')
    valid = cycle + dt.timedelta(hours=int(m.group(3)))
    if valid not in files or files[valid][0] < cycle:
        files[valid] = (cycle, f)
times = sorted(files)
if 'tstart' in cfg:
    times = [t for t in times if cfg['tstart'] <= t <= cfg['tend']]
if not times:
    raise SystemExit('make_GFS_WW3: no GFS file found in ' + gfsdir)
print(f'GFS: {len(times)} records from {times[0]} to {times[-1]}')
gaps = [b - a for a, b in zip(times[:-1], times[1:]) if b - a > dt.timedelta(hours=3)]
if gaps:
    print(f'WARNING: {len(gaps)} gaps longer than 3 h in the GFS time series')

#
# Read and subset
#
lon1, lat1, u, v = read_grib(files[times[0]][1])
ix = np.where((lon1 >= lonmin - 0.5) & (lon1 <= lonmax + 0.5))[0]
iy = np.where((lat1 >= latmin - 0.5) & (lat1 <= latmax + 0.5))[0]
sx = np.argsort(lon1[ix]); ix = ix[sx]
sy = np.argsort(lat1[iy]); iy = iy[sy]
lon, lat = lon1[ix], lat1[iy]
U = np.zeros((len(times), len(lat), len(lon)))
V = np.zeros_like(U)
for l, t in enumerate(times):
    print(f'time index: {l + 1} of total: {len(times)}  {t:%Y%m%d %H%M%S}  ({os.path.basename(files[t][1])})')
    _, _, u, v = read_grib(files[t][1])
    u, v = u[np.ix_(iy, ix)], v[np.ix_(iy, ix)]
    U[l], _ = get_missing_val(lon, lat, u)
    V[l], _ = get_missing_val(lon, lat, v)

write_nc_ll(outfile, lon, lat, times,
            {'u10': (U, 'm s-1', 'eastward wind at 10 m'),
             'v10': (V, 'm s-1', 'northward wind at 10 m')},
            title='GFS 0.25 deg 10 m wind for WAVEWATCH III')
