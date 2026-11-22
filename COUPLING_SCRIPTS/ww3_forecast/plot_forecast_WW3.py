#!/usr/bin/env python3
#======================================================================
#
#  plot_forecast_WW3.py : Read and plot the WW3 forecast outputs
#  (Python port of plot_forecast_WW3.m) for the unstructured grid.
#
#   - maps of Hs with mean-direction arrows and maps of peak period
#     (ww3_ounf netCDF: OUTPUT/ww3.YYYYMM.nc, triangular mesh)
#   - time series of Hs, Tp and Dp at the spectral output points
#     (ww3_ounp table file ww3.YYYYMM_tab.nc)
#   - directional spectrum at the time of maximum Hs at each point
#     (ww3_ounp spectral file ww3.YYYYMM_spec.nc)
#  Figures are written to FIG/ (copied to WEBDIR if defined).
#
#  Environment (exported by ww3_forecast.sh):
#    LLLON LLLAT URLON URLAT OUTDIR TZONE WEBDIR(optional) PLOTINT
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
#  P. Marchesiello IRD 2009
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Updated November 2026 by Andres Sepulveda:
#    - Translated from Matlab/Octave to Python 3 (matplotlib)
#    - Unstructured-grid netCDF outputs, EMEC point time series and
#      directional spectra (Orkney forecast)
#
#======================================================================
import glob
import os
import shutil
import datetime as dt

import numpy as np
from netCDF4 import Dataset, num2date
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.tri as mtri

from start import env, get_config

cfg = get_config()
lonw, lone, lats, latn = cfg['lonmin'], cfg['lonmax'], cfg['latmin'], cfg['latmax']
dirin = env('OUTDIR', os.path.join(cfg['rundir'], 'OUTPUT'))
dirfig = os.path.join(cfg['rundir'], 'FIG')
webdir = os.environ.get('WEBDIR', '')
timezone = cfg['tzone']               # Local time = UTC + timezone
plotint = env('PLOTINT', 6, int)      # hours between maps
os.makedirs(dirfig, exist_ok=True)
#
cmin0, cint0, cmax0 = 0., 0.25, 8.    # hs
cmin1, cint1, cmax1 = 0., 1.00, 20.   # tp
res = 0.04                            # sub-grid for direction arrows [deg]
coslat = np.cos(np.deg2rad(0.5 * (lats + latn)))
#========================= END USER'S CHANGES =============================


def read_times(nc):
    tv = nc.variables['time']
    return np.array(num2date(tv[:], tv.units, only_use_cftime_datetimes=False,
                             only_use_python_datetimes=True))


def local(t):
    return (t + dt.timedelta(hours=timezone)).strftime('%d-%b-%Y %H:%M') + ' LT'


def save(fig, name):
    path = os.path.join(dirfig, name + '.png')
    fig.savefig(path, dpi=120, bbox_inches='tight')
    plt.close(fig)
    if webdir:
        shutil.copy(path, webdir)


#====================================================================
#                        FIELD MAPS
#====================================================================
ffiles = sorted(f for f in glob.glob(os.path.join(dirin, 'ww3.*.nc'))
                if not (f.endswith('_spec.nc') or f.endswith('_tab.nc')))
for fname in ffiles:
    nc = Dataset(fname)
    lon = nc['longitude'][:]
    lat = nc['latitude'][:]
    tri = nc['tri'][:] - 1
    T = mtri.Triangulation(lon, lat, tri)
    times = read_times(nc)
    X, Y = np.meshgrid(np.arange(lonw, lone, res / coslat), np.arange(lats, latn, res))
    for i0, t in enumerate(times):
        if t.hour % plotint:
            continue
        print(' ... plotting fields for date', t)
        hs = np.ma.filled(nc['hs'][i0], np.nan)
        stamp = t.strftime('%Y%m%d%H')
        #
        # significant wave height and mean direction
        #
        fig, ax = plt.subplots(figsize=(11, 9))
        cs = ax.tricontourf(T, hs, levels=np.arange(cmin0, cmax0 + cint0, cint0),
                            cmap='turbo', extend='max')
        if 'dir' in nc.variables:
            d = np.deg2rad(np.ma.filled(nc['dir'][i0], np.nan))
            # dir: direction waves come from (nautical) -> propagation vector
            U = mtri.LinearTriInterpolator(T, -np.sin(d))(X, Y)
            V = mtri.LinearTriInterpolator(T, -np.cos(d))(X, Y)
            ax.quiver(X[::3, ::3], Y[::3, ::3], U[::3, ::3], V[::3, ::3],
                      scale=40, width=0.0015, color='k')
        ax.set_aspect(1. / coslat)
        ax.set_xlim(lonw, lone); ax.set_ylim(lats, latn)
        plt.colorbar(cs, ax=ax, label='Hs [m]', shrink=0.8)
        ax.set_title(f'Significant Wave Height [m]   {local(t)}')
        save(fig, f'WW3_Hs_{stamp}')
        #
        # peak period
        #
        if 'fp' in nc.variables:
            fp = np.ma.filled(nc['fp'][i0], np.nan)
            tp = np.where(fp > 0, 1. / fp, np.nan)
            fig, ax = plt.subplots(figsize=(11, 9))
            cs = ax.tricontourf(T, tp, levels=np.arange(cmin1, cmax1 + cint1, cint1),
                                cmap='viridis', extend='max')
            ax.set_aspect(1. / coslat)
            ax.set_xlim(lonw, lone); ax.set_ylim(lats, latn)
            plt.colorbar(cs, ax=ax, label='Tp [s]', shrink=0.8)
            ax.set_title(f'Peak Period [s]   {local(t)}')
            save(fig, f'WW3_Tp_{stamp}')
    nc.close()

#====================================================================
#                 POINT TIME SERIES (EMEC test sites)
#====================================================================
tfiles = sorted(glob.glob(os.path.join(dirin, 'ww3.*_tab.nc')))
if tfiles:
    series = {}
    for fname in tfiles:
        nc = Dataset(fname)
        names = [''.join(c.decode() if isinstance(c, bytes) else c for c in s).strip()
                 for s in np.ma.filled(nc['station_name'][:], b' ')]
        t = read_times(nc)
        for k, n in enumerate(names):
            s = series.setdefault(n, {'t': [], 'hs': [], 'tp': [], 'dp': []})
            s['t'].extend(t)
            s['hs'].extend(np.ma.filled(nc['hs'][:, k], np.nan))
            fp = np.ma.filled(nc['fp'][:, k], np.nan) if 'fp' in nc.variables else np.nan * t
            s['tp'].extend(np.where(fp > 0, 1. / fp, np.nan))
            dname = next((v for v in ('dp', 'th1p', 'dir', 'th1m') if v in nc.variables), None)
            s['dp'].extend(np.ma.filled(nc[dname][:, k], np.nan) if dname
                           else np.nan * np.ones(len(t)))
        nc.close()
    fig, axs = plt.subplots(3, 1, figsize=(12, 10), sharex=True)
    for n, s in series.items():
        axs[0].plot(s['t'], s['hs'], label=n)
        axs[1].plot(s['t'], s['tp'])
        axs[2].plot(s['t'], s['dp'], '.', ms=3)
    axs[0].set_ylabel('Hs [m]'); axs[1].set_ylabel('Tp [s]'); axs[2].set_ylabel('Dir. at peak [deg]')
    axs[2].set_ylim(0, 360)
    axs[0].legend(ncol=4, fontsize=8)
    for a in axs:
        a.grid(alpha=0.3)
    axs[0].set_title('WW3 forecast at EMEC test sites (UTC)')
    save(fig, 'WW3_points_timeseries')

#====================================================================
#          DIRECTIONAL SPECTRA at the time of maximum Hs
#====================================================================
for fname in sorted(glob.glob(os.path.join(dirin, 'ww3.*_spec.nc'))):
    nc = Dataset(fname)
    names = [''.join(c.decode() if isinstance(c, bytes) else c for c in s).strip()
             for s in np.ma.filled(nc['station_name'][:], b' ')]
    t = read_times(nc)
    f = nc['frequency'][:]
    th = nc['direction'][:]                         # deg, direction towards (WW3)
    efth = np.ma.filled(nc['efth'][:], 0.)          # (time, station, freq, dir)
    df = np.gradient(f)
    dth = 2 * np.pi / len(th)
    order = np.argsort(th)
    for k, n in enumerate(names):
        hs_t = 4. * np.sqrt((efth[:, k] * df[None, :, None]).sum(axis=(1, 2)) * dth)
        it = int(np.argmax(hs_t))
        E = efth[it, k][:, order]
        thr = np.deg2rad(np.r_[th[order], th[order][0] + 360.])
        E = np.c_[E, E[:, :1]]
        fig = plt.figure(figsize=(7, 7))
        ax = fig.add_subplot(projection='polar')
        ax.set_theta_zero_location('N'); ax.set_theta_direction(-1)
        pc = ax.contourf(thr, f, np.log10(np.maximum(E, 1e-6)), levels=20, cmap='magma_r')
        ax.set_rmax(0.4)
        plt.colorbar(pc, ax=ax, label='log10 E(f,theta) [m2 s rad-1]', shrink=0.7)
        ax.set_title(f'{n}  Hs={hs_t[it]:.2f} m  {t[it]:%Y-%m-%d %H} UTC\n(direction towards)')
        save(fig, f'WW3_spec_{n}_{os.path.basename(fname)[4:10]}')
    nc.close()
print('plot_forecast_WW3: done')
