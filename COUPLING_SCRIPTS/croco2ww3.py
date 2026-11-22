#!/usr/bin/env python3
"""
croco2ww3.py
------------
Convert CROCO history/average files into a NetCDF file that ww3_prnc can read
as water-level ('LEV') and current ('CUR') forcing for WAVEWATCH III.

What it does
  * reads zeta and the currents from one or more CROCO files (in time order):
      --current surface    : u, v at the top sigma level (default)
      --current barotropic : ubar, vbar (depth-averaged)
  * moves u, v from the u/v points to the rho points and rotates them to
    eastward / northward components with the grid angle
  * fills land points with the nearest sea value, so that ww3_prnc does not
    interpolate land values into the coastal sea points of the WW3 grid
  * interpolates everything to a REGULAR lon-lat grid (ww3_prnc 'LL' format)
  * writes  ssh(time,latitude,longitude)  [m]
            ucur, vcur(time,latitude,longitude)  [m s-1]
    with _FillValue, 'time' in days since 1990-01-01 and ascending latitude
  * writes ww3_prnc_lev.inp and ww3_prnc_cur.inp for that file

Time
  CROCO stores time in seconds since an origin. If the time variable has
  units "seconds since YYYY-MM-DD ..." it is used; otherwise give the origin
  with --yorig (the Yorig of crocotools_param.m, origin = Yorig-01-01).

Usage
  python croco2ww3.py croco_his_Y2024M1.nc --grid croco_grd.nc --yorig 2000 \
         --out croco_ww3_202401.nc
  python croco2ww3.py croco_his_*.nc --yorig 2000 --current barotropic \
         --res 0.01 --out croco_ww3.nc

  --res: resolution of the regular grid in degrees (default: the mean CROCO
         grid spacing in latitude).

Then, with the WW3 mod_def.ww3 of the target grid in the directory:
  cp ww3_prnc_lev.inp ww3_prnc.inp ; ww3_prnc     # -> level.ww3
  cp ww3_prnc_cur.inp ww3_prnc.inp ; ww3_prnc     # -> current.ww3
and in ww3_shel.inp:   T F  Water levels  /  T F  Currents

Requirements: numpy scipy netCDF4
"""

import argparse
import sys
from datetime import datetime, timedelta

import numpy as np
from netCDF4 import Dataset, num2date, date2num
from scipy.interpolate import RegularGridInterpolator, LinearNDInterpolator
from scipy.spatial import Delaunay, cKDTree

FILL = np.float32(9.96921e36)
TUNITS = "days since 1990-01-01 00:00:00"


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("files", nargs="+", help="CROCO his/avg files, in time order")
    p.add_argument("--grid", help="CROCO grid file (if lon_rho... are not in the files)")
    p.add_argument("--yorig", type=int, help="time origin year (Yorig-01-01)")
    p.add_argument("--current", choices=("surface", "barotropic"), default="surface")
    p.add_argument("--res", type=float, help="regular grid resolution (deg)")
    p.add_argument("--bbox", nargs=4, type=float, metavar=("LON0", "LAT0", "LON1", "LAT1"),
                   help="limits of the regular grid (default: inside the CROCO domain)")
    p.add_argument("--out", default="croco_ww3.nc")
    return p.parse_args()


# ----------------------------------------------------------------------------
# CROCO grid and helpers
# ----------------------------------------------------------------------------
def read_grid(src):
    with Dataset(src) as nc:
        nc.set_auto_mask(False)
        v = nc.variables
        for name in ("lon_rho", "lat_rho"):
            if name not in v:
                sys.exit(f"{name} not found in {src}: give the CROCO grid with --grid")
        lon = v["lon_rho"][:].astype(float)
        lat = v["lat_rho"][:].astype(float)
        ang = v["angle"][:].astype(float) if "angle" in v else np.zeros_like(lon)
        if "mask_rho" in v:
            mask = v["mask_rho"][:].astype(float) > 0.5
        else:
            mask = None
    return lon, lat, ang, mask


def u2rho(u):
    """(..., eta, xi_u) -> (..., eta, xi_rho), edges copied."""
    r = np.empty(u.shape[:-1] + (u.shape[-1] + 1,), dtype=float)
    r[..., 1:-1] = 0.5 * (u[..., :-1] + u[..., 1:])
    r[..., 0], r[..., -1] = r[..., 1], r[..., -2]
    return r


def v2rho(v):
    """(..., eta_v, xi) -> (..., eta_rho, xi), edges copied."""
    r = np.empty(v.shape[:-2] + (v.shape[-2] + 1, v.shape[-1]), dtype=float)
    r[..., 1:-1, :] = 0.5 * (v[..., :-1, :] + v[..., 1:, :])
    r[..., 0, :], r[..., -1, :] = r[..., 1, :], r[..., -2, :]
    return r


def time_of(nc, yorig):
    """Datetimes of the records of an open CROCO file."""
    for name in ("time", "scrum_time", "ocean_time"):
        if name in nc.variables:
            t = nc[name]
            break
    else:
        sys.exit("no time variable (time, scrum_time, ocean_time) in the CROCO file")
    units = getattr(t, "units", "")
    vals = np.asarray(t[:], dtype=float)
    if "since" in units:
        return list(num2date(vals, units, only_use_cftime_datetimes=False,
                             only_use_python_datetimes=True))
    if yorig is None:
        sys.exit(f"time units '{units}' have no origin: give --yorig (Yorig of croco_tools)")
    t0 = datetime(yorig, 1, 1)
    scale = 86400.0 if units.lower().startswith("day") else 1.0
    return [t0 + timedelta(seconds=float(x) * scale) for x in vals]


class Regridder:
    """CROCO rho grid -> regular lon-lat grid (rectilinear fast path or Delaunay)."""

    def __init__(self, lon, lat, mask, res=None, bbox=None):
        self.mask = mask
        sea = mask.ravel() if mask is not None else np.ones(lon.size, bool)
        # nearest sea point for every point (land filling)
        tree = cKDTree(np.c_[lon.ravel()[sea], lat.ravel()[sea]])
        _, k = tree.query(np.c_[lon.ravel(), lat.ravel()])
        self.fill_idx = np.flatnonzero(sea)[k]

        if res is None:
            res = float(np.median(np.abs(np.diff(lat[:, lat.shape[1] // 2]))))
        if bbox is None:
            # largest lon-lat box inside the CROCO interior (rho points 1..L-1)
            bbox = (max(lon[:, 1].max(), lon[:, 0].max()),
                    max(lat[1, :].max(), lat[0, :].max()),
                    min(lon[:, -2].min(), lon[:, -1].min()),
                    min(lat[-2, :].min(), lat[-1, :].min()))
        x0, y0, x1, y1 = bbox
        if not (x1 > x0 and y1 > y0):
            sys.exit("empty target box: give --bbox")
        self.lon1d = np.arange(x0, x1 + 0.5 * res, res)
        self.lat1d = np.arange(y0, y1 + 0.5 * res, res)
        self.lon1d = self.lon1d[self.lon1d <= x1 + 1e-9]
        self.lat1d = self.lat1d[self.lat1d <= y1 + 1e-9]
        LON, LAT = np.meshgrid(self.lon1d, self.lat1d)
        self.target = np.c_[LAT.ravel(), LON.ravel()]
        self.shape = LON.shape

        rect = (np.allclose(lon, lon[0:1, :], atol=1e-6) and
                np.allclose(lat, lat[:, 0:1], atol=1e-6))
        self.rect = rect
        if rect:
            self.x, self.y = lon[0, :], lat[:, 0]
        else:
            self.tri = Delaunay(np.c_[lat.ravel(), lon.ravel()])
            # targets outside the CROCO domain get the nearest CROCO value
            self.outside = self.tri.find_simplex(self.target) < 0
            if self.outside.any():
                _, self.out_idx = cKDTree(np.c_[lat.ravel(), lon.ravel()]).query(
                    self.target[self.outside])
                print(f"  {int(self.outside.sum())} target points outside the CROCO "
                      f"domain: nearest-neighbour values")
        print(f"CROCO grid {lon.shape[1]} x {lon.shape[0]} "
              f"({'rectilinear' if rect else 'curvilinear'}), "
              f"regular grid {len(self.lon1d)} x {len(self.lat1d)} at {res:.4f} deg, "
              f"lon {self.lon1d[0]:.3f}..{self.lon1d[-1]:.3f}, "
              f"lat {self.lat1d[0]:.3f}..{self.lat1d[-1]:.3f}")

    def __call__(self, field):
        f = np.asarray(field, dtype=float).ravel()
        f = f[self.fill_idx]                       # land <- nearest sea value
        if self.rect:
            g = RegularGridInterpolator((self.y, self.x), f.reshape(len(self.y), len(self.x)),
                                        bounds_error=False, fill_value=None)
            out = g(self.target)
        else:
            out = LinearNDInterpolator(self.tri, f)(self.target)
            if self.outside.any():
                out[self.outside] = f[self.out_idx]
        return out.reshape(self.shape)


# ----------------------------------------------------------------------------
def main():
    a = parse_args()
    lon, lat, ang, mask = read_grid(a.grid or a.files[0])
    if mask is None:
        print("no mask_rho found: all points treated as sea")
        mask = np.ones_like(lon, bool)
    rg = Regridder(lon, lat, mask, a.res, a.bbox)
    cosa, sina = np.cos(ang), np.sin(ang)
    uname, vname = ("u", "v") if a.current == "surface" else ("ubar", "vbar")

    out = Dataset(a.out, "w", format="NETCDF4_CLASSIC")
    out.createDimension("time", None)
    out.createDimension("latitude", len(rg.lat1d))
    out.createDimension("longitude", len(rg.lon1d))
    vt = out.createVariable("time", "f8", ("time",))
    vt.units, vt.calendar, vt.standard_name = TUNITS, "standard", "time"
    vy = out.createVariable("latitude", "f4", ("latitude",))
    vy.units, vy.standard_name = "degrees_north", "latitude"
    vx = out.createVariable("longitude", "f4", ("longitude",))
    vx.units, vx.standard_name = "degrees_east", "longitude"
    vy[:], vx[:] = rg.lat1d, rg.lon1d
    dims = ("time", "latitude", "longitude")
    kw = dict(fill_value=FILL, zlib=True, complevel=4)
    vs = out.createVariable("ssh", "f4", dims, **kw)
    vs.units, vs.long_name = "m", "sea surface height (CROCO zeta)"
    vu = out.createVariable("ucur", "f4", dims, **kw)
    vu.units, vu.long_name = "m s-1", f"eastward {a.current} current"
    vv = out.createVariable("vcur", "f4", dims, **kw)
    vv.units, vv.long_name = "m s-1", f"northward {a.current} current"
    out.source = "croco2ww3.py from " + ", ".join(a.files)

    n, last = 0, None
    for fname in a.files:
        with Dataset(fname) as nc:
            nc.set_auto_mask(False)
            times = time_of(nc, a.yorig)
            for k, t in enumerate(times):
                if last is not None and t <= last:   # skip repeated records
                    continue
                z = nc["zeta"][k]
                if a.current == "surface":
                    u = nc[uname][k, -1]               # top sigma level
                    v = nc[vname][k, -1]
                else:
                    u = nc[uname][k]
                    v = nc[vname][k]
                ur, vr = u2rho(u), v2rho(v)
                ue = ur * cosa - vr * sina             # rotate to east / north
                vn = ur * sina + vr * cosa
                vt[n] = date2num(t, TUNITS, "standard")
                vs[n] = rg(z).astype(np.float32)
                vu[n] = rg(ue).astype(np.float32)
                vv[n] = rg(vn).astype(np.float32)
                n += 1
                last = t
            print(f"  {fname}: {len(times)} records, last {last:%Y-%m-%d %H:%M}")
    out.close()
    print(f"Wrote {a.out}: {n} times")

    for kind, field, var in (("lev", "LEV", "ssh"), ("cur", "CUR", "ucur vcur")):
        with open(f"ww3_prnc_{kind}.inp", "w") as f:
            f.write("$ WAVEWATCH III field preprocessor input (version 6.07)\n"
                    f"$ CROCO {'sea level' if kind == 'lev' else a.current + ' currents'}"
                    " written by croco2ww3.py\n"
                    f"  '{field}' 'LL' T T\n"
                    "  longitude latitude\n"
                    f"  {var}\n"
                    f"  '{a.out}'\n"
                    "$ End of input file\n")
    print("Wrote ww3_prnc_lev.inp and ww3_prnc_cur.inp")


if __name__ == "__main__":
    main()
