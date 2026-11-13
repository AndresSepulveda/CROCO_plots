#!/usr/bin/env python3
"""
croco2qgis.py - Convert CROCO NetCDF output into files that open directly in QGIS.

Outputs (choose with --formats):
  tif   One multiband GeoTIFF per variable (1 band per time step, EPSG:4326,
        band descriptions = timestamps). Regridded to a regular lon/lat grid.
  nc    One CF-compliant NetCDF on a regular lon/lat grid (time, lat, lon).
        QGIS reads it as a temporal raster layer (Temporal Controller works).
  gpkg  GeoPackage of points on the native (curvilinear) rho grid, one layer
        per time step, with all variables as attribute columns. Useful for
        vector styling (arrows from u_east / v_north, etc.).

Features
  * Curvilinear rho grid -> regular lon/lat grid (Delaunay linear interpolation,
    land masked with mask_rho).
  * Staggered u/v points are averaged to rho points.
  * u,v (and ubar,vbar) are rotated to east/north with `angle` and a speed
    field is added.
  * 3-D variables: pick a sigma level (--level, default -1 = surface) or
    interpolate to a fixed depth in metres (--depth), using CROCO's
    Vtransform 1/2 vertical coordinate.

Requirements: numpy, xarray, netCDF4 (or h5netcdf), scipy, rasterio (tif),
              geopandas (gpkg).

Examples
  python croco2qgis.py croco_his.nc --grid croco_grd.nc --vars temp,u,v \
         --depth 50 --formats tif,nc --outdir qgis_out
  python croco2qgis.py croco_avg_*.nc --vars zeta,temp --level -1 --times 0:48:6
  python croco2qgis.py croco_his.nc --formats gpkg --vars u,v --time-origin 2000-01-01
"""
import argparse
import glob
import os
import sys

import numpy as np
import xarray as xr
from scipy.interpolate import LinearNDInterpolator
from scipy.spatial import Delaunay, cKDTree

NODATA = -9999.0
DEFAULT_VARS = ["zeta", "temp", "salt", "u", "v", "ubar", "vbar"]
VECTOR_PAIRS = (("u", "v", "speed"), ("ubar", "vbar", "speed_bar"))


# --------------------------------------------------------------------------
# Grid
# --------------------------------------------------------------------------
class Grid:
    def __init__(self, ds, grid_ds):
        self.dss = [ds] if grid_ds is ds else [ds, grid_ds]
        self.lon = self._get("lon_rho", required=True)
        self.lat = self._get("lat_rho", required=True)
        if np.nanmax(self.lon) > 180:
            self.lon = ((self.lon + 180.0) % 360.0) - 180.0
        mask = self._get("mask_rho")
        self.mask = np.ones_like(self.lon) if mask is None else mask
        self.angle = self._get("angle")
        self.h = self._get("h")
        self.shape = self.lon.shape

    def find(self, name):
        for d in self.dss:
            if name in d.variables:
                return d[name]
        return None

    def _get(self, name, required=False):
        v = self.find(name)
        if v is None:
            if required:
                sys.exit(f"ERROR: '{name}' not found. Pass the grid file with --grid.")
            return None
        return np.asarray(v.values, dtype=float)

    def scalar(self, name, default=None):
        v = self.find(name)
        if v is not None:
            return float(np.asarray(v.values).ravel()[0])
        for d in self.dss:
            if name in d.attrs:
                return float(d.attrs[name])
        return default


class Regridder:
    """Curvilinear rho grid -> regular, north-up lon/lat grid."""

    def __init__(self, g, res=None, bbox=None):
        lon, lat = g.lon, g.lat
        self.ocean = g.mask > 0
        pts = np.column_stack([lon[self.ocean], lat[self.ocean]])
        self.tri = Delaunay(pts)

        dx = np.nanmedian(np.abs(np.diff(lon, axis=1)))
        dy = np.nanmedian(np.abs(np.diff(lat, axis=0)))
        self.res = float(res) if res else float(min(dx, dy))
        west, south, east, north = bbox or (lon.min(), lat.min(), lon.max(), lat.max())
        nx = int(round((east - west) / self.res)) + 1
        ny = int(round((north - south) / self.res)) + 1
        self.lons = west + self.res * np.arange(nx)
        self.lats = north - self.res * np.arange(ny)  # north-up
        self.LON, self.LAT = np.meshgrid(self.lons, self.lats)

        # Land / outside-domain mask: nearest native point must be ocean and close
        tree = cKDTree(np.column_stack([lon.ravel(), lat.ravel()]))
        dist, idx = tree.query(np.column_stack([self.LON.ravel(), self.LAT.ravel()]))
        near = (g.mask.ravel()[idx] > 0) & (dist <= 2.0 * max(dx, dy))
        self.valid = near.reshape(self.LON.shape)

    def __call__(self, field):
        vals = field[self.ocean]
        out = LinearNDInterpolator(self.tri, vals)(self.LON, self.LAT)
        out = np.where(self.valid, out, np.nan)
        return out.astype("float32")


# --------------------------------------------------------------------------
# Field reading
# --------------------------------------------------------------------------
def to_rho(a, shape):
    """Average u- or v-point arrays (last two axes) onto rho points."""
    ny, nx = shape
    a = np.nan_to_num(np.asarray(a, dtype=float), nan=0.0)
    if a.shape[-2:] == (ny, nx):
        return a
    if a.shape[-2:] == (ny, nx - 1):  # u points
        out = np.empty(a.shape[:-1] + (nx,))
        out[..., 1:-1] = 0.5 * (a[..., :-1] + a[..., 1:])
        out[..., 0], out[..., -1] = a[..., 0], a[..., -1]
        return out
    if a.shape[-2:] == (ny - 1, nx):  # v points
        out = np.empty(a.shape[:-2] + (ny, nx))
        out[..., 1:-1, :] = 0.5 * (a[..., :-1, :] + a[..., 1:, :])
        out[..., 0, :], out[..., -1, :] = a[..., 0, :], a[..., -1, :]
        return out
    sys.exit(f"ERROR: unexpected horizontal shape {a.shape[-2:]} for grid {shape}")


def z_rho(g, ds, t):
    """Depths (negative, m) of rho levels, shape (N, ny, nx)."""
    s = g.find("s_rho")
    cs = g.find("Cs_r")
    if s is None or cs is None or g.h is None:
        sys.exit("ERROR: --depth needs s_rho, Cs_r and h (use --grid with the grid/restart file).")
    s = np.asarray(s.values, float)[:, None, None]
    cs = np.asarray(cs.values, float)[:, None, None]
    hc = g.scalar("hc")
    if hc is None:
        sys.exit("ERROR: 'hc' not found in file or attributes.")
    vt = int(g.scalar("Vtransform", 1))
    h = g.h[None]
    if "zeta" in ds.variables:
        tdim = next((d for d in ds["zeta"].dims if "time" in d), None)
        zeta = np.nan_to_num(ds["zeta"].isel({tdim: t}).values if tdim else ds["zeta"].values)[None]
    else:
        zeta = np.zeros_like(h)
    if vt == 2:
        z0 = (hc * s + h * cs) / (hc + h)
        return zeta + (zeta + h) * z0
    z0 = hc * s + (h - hc) * cs
    return z0 + zeta * (1.0 + z0 / h)


def interp_depth(arr, z, target, h):
    nz = z.shape[0]
    idx = np.clip((z < target).sum(axis=0), 1, nz - 1)
    take = lambda a, k: np.take_along_axis(a, k[None], 0)[0]
    z0, z1 = take(z, idx - 1), take(z, idx)
    f0, f1 = take(arr, idx - 1), take(arr, idx)
    w = np.clip((target - z0) / np.where(z1 == z0, 1, z1 - z0), 0, 1)
    out = f0 * (1 - w) + f1 * w
    out[-h > target] = np.nan  # seabed shallower than requested depth
    return out


def read_field(ds, g, name, t, args):
    v = ds[name]
    tdim = next((d for d in v.dims if "time" in d), None)
    sel = v.isel({tdim: t}) if tdim else v
    vdim = next((d for d in sel.dims if d.startswith("s_")), None)
    if vdim is None:
        return to_rho(sel.values, g.shape)
    if vdim != "s_rho":
        sys.exit(f"ERROR: '{name}' is on {vdim}; only s_rho variables are supported.")
    sel = sel.transpose(vdim, ...)
    if args.depth is None:
        return to_rho(sel.values[args.level], g.shape)
    arr = to_rho(sel.values, g.shape)
    return interp_depth(arr, z_rho(g, ds, t), -abs(args.depth), g.h)


def compute_step(ds, g, products, t, args):
    out = {}
    for p in products:
        if p[0] == "scalar":
            out[p[1]] = read_field(ds, g, p[1], t, args)
        else:
            _, a, b, sp = p
            u, v = read_field(ds, g, a, t, args), read_field(ds, g, b, t, args)
            if g.angle is not None:
                ue = u * np.cos(g.angle) - v * np.sin(g.angle)
                vn = u * np.sin(g.angle) + v * np.cos(g.angle)
            else:
                ue, vn = u, v
            out[f"{a}_east"], out[f"{b}_north"], out[sp] = ue, vn, np.hypot(u, v)
    return out


def build_products(names):
    products, used = [], set()
    for a, b, sp in VECTOR_PAIRS:
        if a in names and b in names:
            products.append(("vector", a, b, sp))
            used |= {a, b}
    products += [("scalar", n) for n in names if n not in used]
    return products


# --------------------------------------------------------------------------
# Time handling
# --------------------------------------------------------------------------
def read_times(ds, nt, origin=None):
    """Return (datetime64 array or None, list of label strings)."""
    for name in ("ocean_time", "time", "scrum_time"):
        if name in ds.variables and ds[name].ndim == 1 and ds[name].size == nt:
            v = ds[name]
            vals = np.asarray(v.values, float)
            try:
                if origin:
                    base = np.datetime64(origin)
                    times = base + (vals * 1e9).astype("timedelta64[ns]")
                else:
                    import pandas as pd
                    dec = xr.coding.times.decode_cf_datetime(
                        vals, v.attrs.get("units", ""), v.attrs.get("calendar", "standard"))
                    times = pd.to_datetime(np.asarray(dec).astype(str)).values
                times = times.astype("datetime64[ns]")
                return times, [str(x)[:19] for x in times]
            except Exception:
                return None, [f"{x:g}" for x in vals]
    return None, [f"t{i:04d}" for i in range(nt)]


def parse_times(spec, nt):
    if not spec:
        return list(range(nt))
    if ":" in spec:
        parts = [int(p) if p else None for p in spec.split(":")]
        return list(range(nt))[slice(*parts)]
    return [int(i) for i in spec.split(",")]


# --------------------------------------------------------------------------
# Writers
# --------------------------------------------------------------------------
def write_geotiff(path, stack, rg, labels, name):
    import rasterio
    from rasterio.transform import from_origin
    arr = np.where(np.isnan(stack), NODATA, stack).astype("float32")
    transform = from_origin(rg.lons[0] - rg.res / 2, rg.lats[0] + rg.res / 2, rg.res, rg.res)
    with rasterio.open(path, "w", driver="GTiff", height=arr.shape[1], width=arr.shape[2],
                       count=arr.shape[0], dtype="float32", crs="EPSG:4326",
                       transform=transform, nodata=NODATA, compress="deflate") as dst:
        for i in range(arr.shape[0]):
            dst.write(arr[i], i + 1)
            dst.set_band_description(i + 1, labels[i])
            dst.update_tags(i + 1, TIME=labels[i], VARIABLE=name)


def write_netcdf(path, data, rg, times, labels):
    lat = rg.lats[::-1]  # CF convention: ascending latitude
    nt = len(labels)
    if times is not None:
        tcoord = ("time", times)
    else:
        tcoord = ("time", np.arange(nt), {"long_name": "time index", "labels": "; ".join(labels)})
    ds = xr.Dataset(
        {k: (("time", "lat", "lon"), v[:, ::-1, :], {"grid_mapping": "crs", "_FillValue": np.float32(NODATA)})
         for k, v in data.items()},
        coords={"time": tcoord,
                "lat": ("lat", lat, {"units": "degrees_north", "standard_name": "latitude"}),
                "lon": ("lon", rg.lons, {"units": "degrees_east", "standard_name": "longitude"})},
        attrs={"Conventions": "CF-1.8", "title": "CROCO output regridded for QGIS"})
    ds["crs"] = xr.DataArray(0, attrs={"grid_mapping_name": "latitude_longitude",
                                        "epsg_code": "EPSG:4326",
                                        "semi_major_axis": 6378137.0,
                                        "inverse_flattening": 298.257223563})
    ds.to_netcdf(path)


def write_gpkg_layer(path, layer, fields, g, label):
    import geopandas as gpd
    sel = g.mask > 0
    cols = {k: v[sel] for k, v in fields.items()}
    cols["time"] = label
    gdf = gpd.GeoDataFrame(cols, geometry=gpd.points_from_xy(g.lon[sel], g.lat[sel]), crs="EPSG:4326")
    gdf.to_file(path, layer=layer, driver="GPKG")


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def process_file(path, args):
    ds = xr.open_dataset(path, decode_times=False)
    grid_ds = xr.open_dataset(args.grid, decode_times=False) if args.grid else ds
    g = Grid(ds, grid_ds)

    names = args.vars.split(",") if args.vars else [n for n in DEFAULT_VARS if n in ds.variables]
    missing = [n for n in names if n not in ds.variables]
    if missing:
        sys.exit(f"ERROR: variables not in {path}: {missing}")
    products = build_products(names)

    ref = ds[names[0]]
    tdim = next((d for d in ref.dims if "time" in d), None)
    nt = ds.sizes[tdim] if tdim else 1
    times_all, labels_all = read_times(ds, nt, args.time_origin)
    tsel = parse_times(args.times, nt)
    labels = [labels_all[i] for i in tsel]
    times = times_all[tsel] if times_all is not None else None

    formats = set(args.formats.split(","))
    rg = Regridder(g, args.res, args.bbox) if formats & {"tif", "nc"} else None
    stem = os.path.splitext(os.path.basename(path))[0]
    suffix = f"_z{abs(args.depth):g}m" if args.depth is not None else f"_s{args.level}"
    os.makedirs(args.outdir, exist_ok=True)
    gpkg_path = os.path.join(args.outdir, f"{stem}{suffix}_points.gpkg")
    if "gpkg" in formats and os.path.exists(gpkg_path):
        os.remove(gpkg_path)

    stacks = {}
    for n, t in enumerate(tsel):
        print(f"  {os.path.basename(path)}: step {t} ({labels[n]})", flush=True)
        fields = compute_step(ds, g, products, t, args)
        if "gpkg" in formats:
            write_gpkg_layer(gpkg_path, f"t{t:04d}", fields, g, labels[n])
        if rg is not None:
            for k, v in fields.items():
                stacks.setdefault(k, []).append(rg(v))

    stacks = {k: np.stack(v) for k, v in stacks.items()}
    if "tif" in formats:
        for k, v in stacks.items():
            out = os.path.join(args.outdir, f"{stem}_{k}{suffix}.tif")
            write_geotiff(out, v, rg, labels, k)
            print("  wrote", out)
    if "nc" in formats:
        out = os.path.join(args.outdir, f"{stem}{suffix}_regular.nc")
        write_netcdf(out, stacks, rg, times, labels)
        print("  wrote", out)
    if "gpkg" in formats:
        print("  wrote", gpkg_path)


def main():
    p = argparse.ArgumentParser(description="Convert CROCO NetCDF output to QGIS-ready files.")
    p.add_argument("inputs", nargs="+", help="CROCO NetCDF file(s); wildcards allowed")
    p.add_argument("--grid", help="grid file with lon_rho, lat_rho, mask_rho, angle, h")
    p.add_argument("--vars", help="comma-separated variables (default: those present of %s)" % ",".join(DEFAULT_VARS))
    p.add_argument("--formats", default="tif", help="comma list of: tif, nc, gpkg (default tif)")
    p.add_argument("--level", type=int, default=-1, help="sigma level index for 3-D vars (default -1 = surface)")
    p.add_argument("--depth", type=float, help="interpolate 3-D vars to this depth in metres (overrides --level)")
    p.add_argument("--times", help="time indices: '0,5,9' or 'start:stop:step' (default all)")
    p.add_argument("--time-origin", help="e.g. 2000-01-01; use if time units are not CF-decodable (assumes seconds)")
    p.add_argument("--res", type=float, help="output resolution in degrees (default: native grid spacing)")
    p.add_argument("--bbox", type=float, nargs=4, metavar=("W", "S", "E", "N"), help="output extent")
    p.add_argument("--outdir", default="qgis_out")
    args = p.parse_args()

    files = sorted(f for pat in args.inputs for f in (glob.glob(pat) or [pat]))
    for f in files:
        print("Processing", f)
        process_file(f, args)


if __name__ == "__main__":
    main()
