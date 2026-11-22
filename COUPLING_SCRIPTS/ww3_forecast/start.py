#!/usr/bin/env python3
#======================================================================
#
#  start.py : common parameters and helper functions shared by the
#             WW3TOOLS Python scripts (replaces start.m and the old
#             ww3tools_param.m). All the domain/date parameters are
#             read from the environment variables exported by
#             ww3_forecast.sh, so no sed-edited copies are needed.
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
#    - Translated from Matlab/Octave to Python 3
#    - Parameters read from the environment (ww3_forecast.sh)
#    - Helpers to read the output point list and to write CF-netCDF
#      forcing files readable by ww3_prnc (Orkney forecast)
#
#======================================================================
import os
import sys
import datetime as dt

import numpy as np

TIME_UNITS = 'days since 1990-01-01 00:00:00'
TIME_ORIGIN = dt.datetime(1990, 1, 1)


def env(name, default=None, cast=str):
    """Read an environment variable exported by ww3_forecast.sh."""
    val = os.environ.get(name, default)
    if val is None:
        sys.exit(f'start.py: environment variable {name} is not defined')
    if cast is bool:
        return str(val).strip() in ('1', 'T', 'True', 'true', 'yes')
    return cast(val)


def get_config():
    """Return the forecast configuration as a dictionary."""
    cfg = dict(
        lonmin=env('LLLON', cast=float),
        latmin=env('LLLAT', cast=float),
        lonmax=env('URLON', cast=float),
        latmax=env('URLAT', cast=float),
        config=env('WW3_config', 'Orkney'),
        rundir=env('RUNDIR', os.getcwd()),
        tzone=env('TZONE', 0, float),
    )
    if 'DAY_STR' in os.environ:
        cfg['tstart'] = dt.datetime.strptime(os.environ['DAY_STR'], '%Y%m%d')
    if 'DAY_END' in os.environ:
        cfg['tend'] = dt.datetime.strptime(os.environ['DAY_END'], '%Y%m%d')
    return cfg


def read_points(fname='points.list'):
    """Read the output points written by ww3_forecast.sh.
    One point per line: lon lat 'NAME' (name <= 10 characters)."""
    pts = []
    if not os.path.exists(fname):
        return pts
    with open(fname) as f:
        for line in f:
            line = line.split('#')[0].strip()
            if not line:
                continue
            p = line.split(None, 2)
            pts.append((float(p[0]), float(p[1]), p[2].strip().strip("'").strip()))
    return pts


def to_ww3_time(times):
    """datetime list -> days since 1990-01-01 (CF time used by ww3_prnc)."""
    return np.array([(t - TIME_ORIGIN).total_seconds() / 86400. for t in times])


def write_nc_ll(fname, lon, lat, times, fields, title=''):
    """Write a regular lon/lat CF-netCDF file for ww3_prnc ('LL' format).

    fields : dict  name -> (array[nt,ny,nx], units, long_name)
    lon/lat must be 1-D and increasing.
    """
    from netCDF4 import Dataset
    nc = Dataset(fname, 'w', format='NETCDF4_CLASSIC')
    nc.title = title
    nc.history = 'Created ' + dt.datetime.utcnow().strftime('%Y-%m-%d %H:%M') + \
                 ' UTC by WW3TOOLS (Python)'
    nc.Conventions = 'CF-1.6'
    nc.createDimension('time', None)
    nc.createDimension('latitude', len(lat))
    nc.createDimension('longitude', len(lon))
    vt = nc.createVariable('time', 'f8', ('time',))
    vt.units = TIME_UNITS
    vt.calendar = 'standard'
    vt.long_name = 'time'
    vt[:] = to_ww3_time(times)
    vy = nc.createVariable('latitude', 'f4', ('latitude',))
    vy.units = 'degree_north'
    vy.standard_name = 'latitude'
    vy[:] = lat
    vx = nc.createVariable('longitude', 'f4', ('longitude',))
    vx.units = 'degree_east'
    vx.standard_name = 'longitude'
    vx[:] = lon
    for name, (data, units, lname) in fields.items():
        v = nc.createVariable(name, 'f4', ('time', 'latitude', 'longitude'),
                              zlib=True, fill_value=np.float32(9.999e20))
        v.units = units
        v.long_name = lname
        v[:] = np.asarray(data, dtype='f4')
    nc.close()
    print(f' ... wrote {fname}  ({len(times)} records)')


if __name__ == '__main__':
    print('Add the paths of the different toolboxes')
    print(get_config())
