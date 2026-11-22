#!/usr/bin/env python3
"""
get_cmems_sealevel.py
---------------------
Download hourly sea level (zos) from the Copernicus Marine Service for a
box and period, month by month, and merge it into one NetCDF file.
Optionally prepare the file for ww3_prnc (WW3 water-level forcing).

Default products (North-West European Shelf, with tides):
  anfc : NWSHELF_ANALYSISFORECAST_PHY_004_013, 1/36 deg, from 2022-11-23
         dataset cmems_mod_nws_phy_anfc_0.027deg-2D_PT1H-m   (hourly means)
  my   : NWSHELF_MULTIYEAR_PHY_004_009 (reanalysis), ~7 km, from 1993
         dataset cmems_mod_nws_phy-ssh_my_7km-2D_PT1H-i      (instantaneous)
  auto : anfc if the period starts on/after 2022-11-23, otherwise my

Before the first use:
  pip install copernicusmarine xarray netCDF4
  copernicusmarine login          # stores your Copernicus Marine credentials

Usage:
  python get_cmems_sealevel.py --start 2024-01-01 --end 2024-02-01 \
         --area 59.8 -4.5 58.3 -1.5 --out sealevel_202401.nc
  python get_cmems_sealevel.py --start 2024-01-01 --end 2024-02-01 \
         --area 59.8 -4.5 58.3 -1.5 --out level.nc --ww3
  python get_cmems_sealevel.py ... --dataset <another-dataset-id> --var zos

  --area is North West South East (degrees). --end is inclusive (00:00 of
  that day is the last time downloaded).

With --ww3 the output has a _FillValue, a 'time' variable in
'days since 1990-01-01', ascending latitude and float32 data, as needed by
ww3_prnc v6.07 ('LEV' 'LL' T T / longitude latitude / zos).
"""

import argparse
import os
import sys
from datetime import datetime, timedelta

import numpy as np
import xarray as xr

DATASETS = {
    "anfc": "cmems_mod_nws_phy_anfc_0.027deg-2D_PT1H-m",
    "my": "cmems_mod_nws_phy-ssh_my_7km-2D_PT1H-i",
}
ANFC_START = datetime(2022, 11, 23)
FILL = np.float32(9.96921e36)


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--start", required=True, help="first day, YYYY-MM-DD")
    p.add_argument("--end", required=True, help="last day (inclusive), YYYY-MM-DD")
    p.add_argument("--area", nargs=4, type=float, required=True,
                   metavar=("N", "W", "S", "E"))
    p.add_argument("--product", choices=("auto", "anfc", "my"), default="auto")
    p.add_argument("--dataset", help="dataset id (overrides --product)")
    p.add_argument("--var", default="zos", help="sea level variable (default zos)")
    p.add_argument("--out", default="cmems_sealevel.nc")
    p.add_argument("--ww3", action="store_true", help="prepare the file for ww3_prnc")
    p.add_argument("--keep-monthly", action="store_true")
    return p.parse_args()


def month_chunks(t0, t1):
    """Yield (start, end) datetimes, one per calendar month, covering t0..t1."""
    a = t0
    while a <= t1:
        nxt = datetime(a.year + (a.month == 12), a.month % 12 + 1, 1)
        b = min(nxt - timedelta(hours=1), t1)
        yield a, b
        a = nxt


def download(dataset, var, area, t0, t1, fname):
    import copernicusmarine
    n, w, s, e = area
    copernicusmarine.subset(
        dataset_id=dataset,
        variables=[var],
        minimum_longitude=w, maximum_longitude=e,
        minimum_latitude=s, maximum_latitude=n,
        start_datetime=t0.strftime("%Y-%m-%dT%H:%M:%S"),
        end_datetime=t1.strftime("%Y-%m-%dT%H:%M:%S"),
        coordinates_selection_method="outside",   # make sure the box is covered
        output_filename=os.path.basename(fname),
        output_directory=os.path.dirname(os.path.abspath(fname)),
        overwrite=True,
    )


def standard_names(ds):
    ren = {}
    for old, new in (("lat", "latitude"), ("lon", "longitude"),
                     ("valid_time", "time")):
        if old in ds.variables and new not in ds.variables:
            ren[old] = new
    return ds.rename(ren)


def merge(files, var):
    parts = [standard_names(xr.open_dataset(f)) for f in files]
    for f, p in zip(files, parts):
        if var not in p:
            sys.exit(f"'{var}' not in {f}. Variables: {list(p.data_vars)}")
    ds = xr.concat(parts, dim="time", data_vars="minimal", coords="minimal",
                   compat="override")[[var]]
    ds = ds.sortby("time")
    _, keep = np.unique(ds.time.values, return_index=True)
    return ds.isel(time=keep).load(), parts


def write(ds, var, out, ww3):
    if not ww3:
        ds.to_netcdf(out)
        return
    # extra dimensions of size 1 (e.g. depth) are not wanted by ww3_prnc
    for d in list(ds[var].dims):
        if d not in ("time", "latitude", "longitude") and ds.sizes[d] == 1:
            ds = ds.isel({d: 0}, drop=True)
    ds = ds.drop_vars([c for c in ds.coords if c not in ("time", "latitude", "longitude")])
    if ds.latitude.values[0] > ds.latitude.values[-1]:
        ds = ds.sortby("latitude")
    da = ds[var].transpose("time", "latitude", "longitude").astype(np.float32)
    for a in ("scale_factor", "add_offset", "missing_value", "_FillValue"):
        da.attrs.pop(a, None)
    ds[var] = da
    enc = {var: {"_FillValue": FILL, "dtype": "float32", "zlib": True, "complevel": 4},
           "time": {"units": "days since 1990-01-01 00:00:00", "calendar": "standard",
                    "dtype": "float64", "_FillValue": None},
           "latitude": {"dtype": "float32", "_FillValue": None},
           "longitude": {"dtype": "float32", "_FillValue": None}}
    ds.to_netcdf(out, format="NETCDF4_CLASSIC", encoding=enc, unlimited_dims=["time"])


def main():
    a = parse_args()
    t0 = datetime.strptime(a.start, "%Y-%m-%d")
    t1 = datetime.strptime(a.end, "%Y-%m-%d")
    if t1 < t0:
        sys.exit("--end is before --start")
    n, w, s, e = a.area
    if not (n > s and e > w):
        sys.exit("--area must be North West South East")

    product = a.product
    if product == "auto":
        product = "anfc" if t0 >= ANFC_START else "my"
    dataset = a.dataset or DATASETS[product]
    print(f"Dataset: {dataset}   variable: {a.var}")
    if dataset == DATASETS["anfc"] and t0 < ANFC_START:
        print("  warning: the analysis/forecast archive starts on 2022-11-23; "
              "use --product my for earlier dates")

    base = os.path.splitext(a.out)[0]
    files = []
    for c0, c1 in month_chunks(t0, t1):
        f = f"{base}_{c0:%Y%m}.part.nc"
        if os.path.exists(f):
            print(f"{f} exists, skipping download")
        else:
            print(f"Downloading {c0:%Y-%m-%d %H:%M} -> {c1:%Y-%m-%d %H:%M}")
            download(dataset, a.var, a.area, c0, c1, f)
        files.append(f)

    ds, parts = merge(files, a.var)
    write(ds, a.var, a.out, a.ww3)
    for p in parts:
        p.close()
    if not a.keep_monthly:
        for f in files:
            os.remove(f)

    z = ds[a.var].values
    print(f"Wrote {a.out}: {ds.sizes['time']} times "
          f"{str(ds.time.values[0])[:16]} .. {str(ds.time.values[-1])[:16]}, "
          f"{ds.sizes['latitude']} x {ds.sizes['longitude']} points, "
          f"{a.var} {np.nanmin(z):.2f} .. {np.nanmax(z):.2f} m")


if __name__ == "__main__":
    main()
