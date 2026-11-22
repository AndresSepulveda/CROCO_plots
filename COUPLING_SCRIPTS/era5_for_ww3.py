#!/usr/bin/env python3
"""
era5_for_ww3.py
---------------
Download ERA5 hourly single-level fields from the Copernicus Climate Data
Store (CDS) and write NetCDF files ready for WAVEWATCH III's ww3_prnc.

Products written (in --outdir):
  era5_wind_<start>_<end>.nc   u10, v10              [m s-1]
                               (+ ast [K] if --ast: air-sea temperature
                                difference t2m - sst, for WIND_AST forcing)
  era5_ice_<start>_<end>.nc    siconc                [0-1]   (if --ice)

What the post-processing does to the raw ERA5 output:
  * renames the new-CDS 'valid_time' to 'time', drops 'number'/'expver'
  * sorts latitude ascending (ERA5 is north->south; WW3 expects south->north)
  * optionally converts longitude to 0..360 (--lon360)
  * fills land NaNs (sea ice -> 0, ast -> 0)
  * float32 fields, CF time 'hours since 1990-01-01', unlimited time dim
  * concatenates the monthly downloads into one continuous file

Requirements
  pip install "cdsapi>=0.7.2" xarray netCDF4 numpy dask
  A CDS account with ~/.cdsapirc:
      url: https://cds.climate.copernicus.eu/api
      key: <your-personal-access-token>
  and the ERA5 single-levels licence accepted on the dataset web page.

Example
  python era5_for_ww3.py --start 2024-01 --end 2024-03 \
      --area -10 -90 -60 -60 --ice --ast --outdir ./forcing

  (--area is North West South East, in degrees)

Matching ww3_prnc.nml (winds)
  &FORCING_NML
    FORCING%TIMESTART        = '19000101 000000'
    FORCING%TIMESTOP         = '29001231 000000'
    FORCING%FIELD%WINDS      = T     ! or FORCING%FIELD%WIND_AST = T with --ast
    FORCING%GRID%LATLON      = T
  /
  &FILE_NML
    FILE%FILENAME  = 'era5_wind_202401_202403.nc'
    FILE%LONGITUDE = 'longitude'
    FILE%LATITUDE  = 'latitude'
    FILE%VAR(1)    = 'u10'
    FILE%VAR(2)    = 'v10'
    ! FILE%VAR(3)  = 'ast'           ! only with WIND_AST
  /

Matching ww3_prnc.nml (ice): FORCING%FIELD%ICE_CONC = T, FILE%VAR(1) = 'siconc'
"""

import argparse
import calendar
import os
import shutil
import sys
import tempfile
import time
import zipfile
from datetime import date

import numpy as np
import xarray as xr

DATASET = "reanalysis-era5-single-levels"

# CDS long names -> short names as they appear in the NetCDF output
CDS_VARS = {
    "10m_u_component_of_wind": "u10",
    "10m_v_component_of_wind": "v10",
    "2m_temperature": "t2m",
    "sea_surface_temperature": "sst",
    "sea_ice_cover": "siconc",
}

TIME_UNITS = "hours since 1990-01-01 00:00:00"


# --------------------------------------------------------------------------
# Download
# --------------------------------------------------------------------------
def month_range(start, end):
    """Yield (year, month) from 'YYYY-MM' start to end inclusive."""
    y, m = map(int, start.split("-"))
    ye, me = map(int, end.split("-"))
    while (y, m) <= (ye, me):
        yield y, m
        y, m = (y + 1, 1) if m == 12 else (y, m + 1)


def download_month(client, year, month, variables, area, grid, target,
                   retries=3):
    """Retrieve one month of hourly ERA5 data into `target` (NetCDF)."""
    ndays = calendar.monthrange(year, month)[1]
    request = {
        "product_type": ["reanalysis"],
        "variable": variables,
        "year": [f"{year:04d}"],
        "month": [f"{month:02d}"],
        "day": [f"{d:02d}" for d in range(1, ndays + 1)],
        "time": [f"{h:02d}:00" for h in range(24)],
        "data_format": "netcdf",
        "download_format": "unarchived",
        "grid": [grid, grid],
    }
    if area is not None:
        request["area"] = area  # [N, W, S, E]

    for attempt in range(1, retries + 1):
        try:
            tmp = target + ".part"
            client.retrieve(DATASET, request, tmp)
            _unzip_if_needed(tmp, target)
            return
        except Exception as exc:  # network / queue errors
            print(f"  attempt {attempt}/{retries} failed: {exc}",
                  file=sys.stderr)
            if attempt == retries:
                raise
            time.sleep(30 * attempt)


def _unzip_if_needed(path, target):
    """The new CDS sometimes returns a zip of several .nc files; merge them."""
    if not zipfile.is_zipfile(path):
        os.replace(path, target)
        return
    tmpdir = tempfile.mkdtemp()
    try:
        with zipfile.ZipFile(path) as zf:
            zf.extractall(tmpdir)
        files = sorted(os.path.join(tmpdir, f) for f in os.listdir(tmpdir)
                       if f.endswith(".nc"))
        dsets = [xr.open_dataset(f) for f in files]
        merged = xr.merge(dsets, compat="override", join="exact")
        merged.load().to_netcdf(target)
        for d in dsets:
            d.close()
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
        os.remove(path)


# --------------------------------------------------------------------------
# Post-processing
# --------------------------------------------------------------------------
def clean_era5(ds, lon360=False):
    """Make an ERA5 dataset CF/WW3-friendly."""
    if "valid_time" in ds.dims or "valid_time" in ds.coords:
        ds = ds.rename({"valid_time": "time"})
    for name in ("lat", "lon"):
        if name in ds.dims:
            ds = ds.rename({name: {"lat": "latitude", "lon": "longitude"}[name]})
    ds = ds.drop_vars([v for v in ("number", "expver") if v in ds.variables])
    if "expver" in ds.dims:  # old-style ERA5/ERA5T mix
        ds = ds.reduce(np.nanmax, dim="expver")

    if lon360:
        ds = ds.assign_coords(longitude=(ds.longitude % 360))
    ds = ds.sortby("longitude").sortby("latitude")  # ascending lat for WW3
    ds = ds.sortby("time")
    return ds


def write_ww3(ds, varnames, path, attrs_extra=None):
    out = ds[varnames].astype("float32")
    out["latitude"].attrs.update(units="degrees_north",
                                 standard_name="latitude", axis="Y")
    out["longitude"].attrs.update(units="degrees_east",
                                  standard_name="longitude", axis="X")
    out["time"].attrs.update(standard_name="time", axis="T")
    out = out.transpose("time", "latitude", "longitude")
    out.attrs = {"title": "ERA5 forcing for WAVEWATCH III",
                 "source": "Copernicus Climate Change Service, ERA5",
                 "Conventions": "CF-1.6"}
    if attrs_extra:
        out.attrs.update(attrs_extra)

    enc = {v: {"dtype": "float32", "zlib": True, "complevel": 4,
               "_FillValue": None} for v in varnames}
    enc["time"] = {"units": TIME_UNITS, "calendar": "standard",
                   "dtype": "float64"}
    enc["latitude"] = {"dtype": "float32", "_FillValue": None}
    enc["longitude"] = {"dtype": "float32", "_FillValue": None}
    out.to_netcdf(path, format="NETCDF4", encoding=enc,
                  unlimited_dims=["time"])
    print(f"  wrote {path}")


def build_products(raw_files, args, tag):
    ds = xr.open_mfdataset(raw_files, combine="by_coords",
                           preprocess=lambda d: clean_era5(d, args.lon360))
    ds = clean_era5(ds, args.lon360)  # final sort after concatenation
    # remove any duplicated time stamps at month boundaries
    _, idx = np.unique(ds["time"].values, return_index=True)
    ds = ds.isel(time=np.sort(idx))

    # --- winds (+ air-sea temperature difference) ---
    wind_vars = ["u10", "v10"]
    ds["u10"].attrs.update(units="m s-1", long_name="10 metre U wind component")
    ds["v10"].attrs.update(units="m s-1", long_name="10 metre V wind component")
    if args.ast:
        ast = (ds["t2m"] - ds["sst"]).fillna(0.0)
        ast.attrs = {"units": "K",
                     "long_name": "air-sea temperature difference (t2m - sst)"}
        ds["ast"] = ast
        wind_vars.append("ast")
    write_ww3(ds, wind_vars, os.path.join(args.outdir, f"era5_wind_{tag}.nc"))

    # --- sea ice concentration ---
    if args.ice:
        ice = ds["siconc"].fillna(0.0).clip(0.0, 1.0)
        ice.attrs = {"units": "1", "long_name": "sea ice area fraction"}
        ds["siconc"] = ice
        write_ww3(ds, ["siconc"], os.path.join(args.outdir, f"era5_ice_{tag}.nc"))
    ds.close()


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser(
        description="Download ERA5 and write WW3 (ww3_prnc) forcing files.")
    p.add_argument("--start", required=True, help="first month, YYYY-MM")
    p.add_argument("--end", required=True, help="last month, YYYY-MM")
    p.add_argument("--area", nargs=4, type=float, metavar=("N", "W", "S", "E"),
                   help="bounding box; omit for global")
    p.add_argument("--grid", type=float, default=0.25,
                   help="output resolution in degrees (default 0.25 = native)")
    p.add_argument("--ice", action="store_true",
                   help="also produce sea-ice concentration file")
    p.add_argument("--ast", action="store_true",
                   help="add air-sea temperature difference to wind file "
                        "(for FORCING%%FIELD%%WIND_AST)")
    p.add_argument("--lon360", action="store_true",
                   help="write longitudes as 0..360 instead of -180..180")
    p.add_argument("--outdir", default="era5_ww3")
    p.add_argument("--rawdir", default=None,
                   help="where monthly raw downloads go (default outdir/raw)")
    p.add_argument("--keep-raw", action="store_true",
                   help="keep monthly raw files after building products")
    return p.parse_args()


def main():
    args = parse_args()
    import cdsapi  # imported here so --help works without it

    rawdir = args.rawdir or os.path.join(args.outdir, "raw")
    os.makedirs(rawdir, exist_ok=True)

    variables = ["10m_u_component_of_wind", "10m_v_component_of_wind"]
    if args.ast:
        variables += ["2m_temperature", "sea_surface_temperature"]
    if args.ice:
        variables += ["sea_ice_cover"]

    client = cdsapi.Client()
    raw_files = []
    for year, month in month_range(args.start, args.end):
        target = os.path.join(rawdir, f"era5_raw_{year:04d}{month:02d}.nc")
        if os.path.exists(target):
            print(f"{year}-{month:02d}: already downloaded, skipping")
        else:
            print(f"{year}-{month:02d}: requesting {', '.join(variables)}")
            download_month(client, year, month, variables, args.area,
                           args.grid, target)
        raw_files.append(target)

    tag = f"{args.start.replace('-', '')}_{args.end.replace('-', '')}"
    print("Building WW3 forcing files ...")
    build_products(raw_files, args, tag)

    if not args.keep_raw:
        shutil.rmtree(rawdir, ignore_errors=True)
    print("Done.")


if __name__ == "__main__":
    main()
