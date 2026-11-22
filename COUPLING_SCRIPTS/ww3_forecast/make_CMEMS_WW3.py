#!/usr/bin/env python3
#======================================================================
#
#  make_CMEMS_WW3.py : create the WW3 current (current.nc) and water
#  level (level.nc) forcing files from the Copernicus Marine hourly
#  forecast files downloaded in ww3_forecast.sh:
#     CMEMS_cur.nc  (uo, vo)  e.g. cmems_mod_nws_phy-cur_anfc_1.5km-2D_PT1H-i
#     CMEMS_ssh.nc  (zos)     e.g. cmems_mod_nws_phy-ssh_anfc_1.5km-2D_PT1H-i
#  Land points are filled by nearest-neighbour extrapolation
#  (get_missing_val) so that ww3_prnc never interpolates fill values
#  near the coast. Curvilinear inputs are regridded to a regular grid.
#  The files are read by ww3_prnc ('CUR' 'LL' and 'LEV' 'LL').
#
#  Environment (exported by ww3_forecast.sh):
#    LLLON LLLAT URLON URLAT DAY_STR DAY_END RUNDIR
#    CMEMS_UVAR CMEMS_VVAR CMEMS_ZVAR  (variable names, default uo vo zos)
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
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Updated November 2026 by Andres Sepulveda:
#    - New script: Copernicus Marine hourly currents and sea level
#      forcing for the Orkney WW3 forecast
#
#======================================================================
import os
import sys

import numpy as np
from netCDF4 import Dataset, num2date
from scipy.interpolate import griddata

from start import env, get_config, write_nc_ll
from get_missing_val import get_missing_val

cfg = get_config()
rundir = cfg['rundir']
uvar = env('CMEMS_UVAR', 'uo')
vvar = env('CMEMS_VVAR', 'vo')
zvar = env('CMEMS_ZVAR', 'zos')


def coord(nc, names):
    for n in names:
        if n in nc.variables:
            return np.ma.getdata(nc.variables[n][:]).astype(float)
    raise KeyError(f'none of {names} in file')


def read_cmems(fname, varnames):
    nc = Dataset(fname)
    lon = coord(nc, ('longitude', 'lon', 'nav_lon'))
    lat = coord(nc, ('latitude', 'lat', 'nav_lat'))
    tv = nc.variables['time']
    times = num2date(tv[:], tv.units, getattr(tv, 'calendar', 'standard'),
                     only_use_cftime_datetimes=False, only_use_python_datetimes=True)
    data = {}
    for v in varnames:
        a = nc.variables[v]
        x = np.ma.filled(a[:].astype(float), np.nan)
        if x.ndim == 4:                    # (time, depth, y, x) -> surface
            x = x[:, 0]
        data[v] = x
    nc.close()
    #
    # time window of the run
    #
    times = list(times)
    keep = [k for k, t in enumerate(times)
            if 'tstart' not in cfg or cfg['tstart'] <= t <= cfg['tend']]
    times = [times[k] for k in keep]
    for v in data:
        data[v] = data[v][keep]
    #
    # curvilinear -> regular grid (same mean resolution)
    #
    if lon.ndim == 2:
        dl = np.median(np.abs(np.diff(lat[:, 0])))
        rlon = np.arange(lon.min(), lon.max() + dl / 2, dl / np.cos(np.deg2rad(lat.mean())))
        rlat = np.arange(lat.min(), lat.max() + dl / 2, dl)
        RLON, RLAT = np.meshgrid(rlon, rlat)
        for v in data:
            out = np.empty((len(times), len(rlat), len(rlon)))
            for l in range(len(times)):
                out[l] = griddata((lon.ravel(), lat.ravel()), data[v][l].ravel(),
                                  (RLON, RLAT), method='linear')
            data[v] = out
        lon, lat = rlon, rlat
    if lat[0] > lat[-1]:
        lat = lat[::-1]
        for v in data:
            data[v] = data[v][:, ::-1, :]
    #
    # fill land points
    #
    for v in data:
        for l in range(len(times)):
            data[v][l], _ = get_missing_val(lon, lat, data[v][l], np.nan, 0, 0.)
    print(f'{fname}: {len(times)} records from {times[0]} to {times[-1]}')
    return lon, lat, times, data


curfile = os.path.join(rundir, 'CMEMS_cur.nc')
sshfile = os.path.join(rundir, 'CMEMS_ssh.nc')
what = sys.argv[1:] or ['cur', 'lev']

if 'cur' in what:
    lon, lat, times, d = read_cmems(curfile, [uvar, vvar])
    write_nc_ll(os.path.join(rundir, 'current.nc'), lon, lat, times,
                {'ucur': (d[uvar], 'm s-1', 'eastward surface current'),
                 'vcur': (d[vvar], 'm s-1', 'northward surface current')},
                title='Copernicus Marine hourly surface currents for WAVEWATCH III')
if 'lev' in what:
    lon, lat, times, d = read_cmems(sshfile, [zvar])
    write_nc_ll(os.path.join(rundir, 'level.nc'), lon, lat, times,
                {'wlv': (d[zvar], 'm', 'sea surface height')},
                title='Copernicus Marine hourly sea level for WAVEWATCH III')
