#!/usr/bin/env python3
#======================================================================
#
#  lat, lon, mat1, mat2, norm, var, nodata = read_WW31(filename)
#
#  Reads WAVEWATCH III ww3_outf transfer files (ITYPE=3, IDLA=3,
#  IDFM=1) for regular grids (Python port of read_WW31.m).
#  Kept for compatibility with older regular-grid runs: the Orkney
#  unstructured forecast writes netCDF with ww3_ounf instead.
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
#
#======================================================================
import numpy as np

TWO_COMPONENTS = ('.wnd', '.tus', '.uss', '.cur')


def read_WW31(filename):
    with open(filename) as f:
        tok = f.read().split()
    k = 0
    # header: model name (2 words), date (2), lon range, nx, lat range, ny
    k += 2
    k += 2                                   # date, time
    lonr = [float(tok[k]), float(tok[k + 1])]; k += 2
    nx = int(tok[k]); k += 1
    latr = [float(tok[k]), float(tok[k + 1])]; k += 2
    ny = int(tok[k]); k += 1
    var = tok[k]; k += 1
    scale = float(tok[k]); k += 1
    if var not in ('.poc', '.paw'):
        k += 1                               # unit
    k += 2                                   # idla, idfm
    k += 1                                   # format
    nodata = int(tok[k]); k += 1
    n = nx * ny
    vals = np.array(tok[k:k + n], dtype=float); k += n
    mat1 = np.flipud(vals.reshape(ny, nx)) * scale
    mat1[mat1 == nodata * scale] = np.nan
    if var in TWO_COMPONENTS:
        vals = np.array(tok[k:k + n], dtype=float)
        mat2 = np.flipud(vals.reshape(ny, nx)) * scale
        mat2[mat2 == nodata * scale] = np.nan
    else:
        mat2 = 0. * mat1
    norm = np.sqrt(mat1 ** 2 + mat2 ** 2)
    lat = np.linspace(latr[0], latr[1], ny)
    lon = np.linspace(lonr[0], lonr[1], nx)
    return lat, lon, mat1, mat2, norm, var, nodata


if __name__ == '__main__':
    import sys
    out = read_WW31(sys.argv[1])
    print(out[5], out[2].shape, np.nanmin(out[2]), np.nanmax(out[2]))
