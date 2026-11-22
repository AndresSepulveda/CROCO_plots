#!/usr/bin/env python3
#======================================================================
#
#  field, interp_flag = get_missing_val(lon, lat, field, missvalue,
#                                       ro, default)
#
#  Perform an objective analysis to fill the missing points of an
#  horizontal gridded slice (Python port of get_missing_val.m)
#
#  input:
#    lon      : longitude (1-D or 2-D)
#    lat      : latitude  (1-D or 2-D)
#    field    : input 2D field
#    missvalue: value of the bad points (e.g. -99.999), NaN by default
#    ro       : oa decorrelation scale [km] (0 -> nearest neighbour)
#    default  : default value given if there is only missing data
#
#  output:
#    field    : output 2D field
#
#  Further Information:
#  http://www.brest.ird.fr/Roms_tools/
#
#  This file is part of ROMSTOOLS / WW3TOOLS
#
#  ROMSTOOLS is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 2 of the License,
#  or (at your option) any later version.
#
#  ROMSTOOLS is distributed in the hope that it will be useful, but
#  WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston,
#  MA  02111-1307  USA
#
#  Copyright (c) 2001-2006 by Pierrick Penven
#  e-mail:Pierrick.Penven@ird.fr
#
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Contributions from Patrick Marchesiello (IRD) and Jerome Lefevre (IRD)
#
#  Updated    6-Sep-2006 by Pierrick Penven
#  Updated    2-Oct-2006 by Xavier Capet and Pierrick Penven
#                        (add the 'savefile option')
#  Menkes 2007 correct for Ro
#  Updated November 2026 by Andres Sepulveda:
#    - Translated from Matlab/Octave to Python 3 (numpy/scipy)
#    - Objective analysis replaced by a Gaussian-weighted average of
#      the nearest valid points (scipy cKDTree)
#
#======================================================================
import numpy as np
from scipy.spatial import cKDTree

R_EARTH = 6371.0  # km


def _xy(lon, lat):
    """Local equirectangular projection [km]."""
    lat0 = np.deg2rad(np.nanmean(lat))
    x = np.deg2rad(lon) * R_EARTH * np.cos(lat0)
    y = np.deg2rad(lat) * R_EARTH
    return x, y


def get_missing_val(lon, lat, field, missvalue=np.nan, ro=0.0, default=0.0):
    field = np.array(field, dtype=float, copy=True)
    lon = np.asarray(lon, dtype=float)
    lat = np.asarray(lat, dtype=float)
    if lon.ndim == 1 and lat.ndim == 1:
        lon, lat = np.meshgrid(lon, lat)
    if lon.shape != field.shape:
        raise ValueError('GET_MISSING_VAL: sizes do not correspond')
    #
    # get a masking matrix and the good data matrix
    #
    if np.isnan(missvalue):
        ismask = np.isnan(field)
    else:
        ismask = (field == missvalue) | np.isnan(field)
    isdata = ~ismask
    ndata = int(isdata.sum())
    #
    # test if there are any data
    #
    if ndata == 0:
        print(f'GET_MISSING_VAL: No data point -> using default value: {default}')
        return np.zeros_like(field) + default, 0
    if ndata < 6:
        default = field[isdata].mean()
        print(f'GET_MISSING_VAL: only {ndata} data points: using the mean value: {default}')
        return np.zeros_like(field) + default, 0
    if ismask.sum() == 0:
        return field, 1

    x, y = _xy(lon, lat)
    tree = cKDTree(np.c_[x[isdata], y[isdata]])
    targets = np.c_[x[ismask], y[ismask]]
    good = field[isdata]
    if ro > 0:
        #
        # Gaussian weighted average of the 8 nearest data points
        #
        k = min(8, ndata)
        d, i = tree.query(targets, k=k)
        w = np.exp(-(d / ro) ** 2) + 1e-12
        field[ismask] = (w * good[i]).sum(axis=1) / w.sum(axis=1)
    else:
        #
        # Extrapolation using nearest values
        #
        d, i = tree.query(targets, k=1)
        field[ismask] = good[i]
    return field, 1
