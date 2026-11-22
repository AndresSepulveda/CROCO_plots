#!/usr/bin/env python3
"""
Download surface currents from the Copernicus Marine Service and turn them
into a forcing file that WAVEWATCH III's ww3_prnc can read.

The script does three things:

  1. subsets a CMEMS product over your grid and time window
     (copernicusmarine.subset),
  2. rewrites the result into the shape ww3_prnc expects: a rectilinear
     longitude/latitude/time file holding just the two surface velocity
     components, with no depth dimension and no NaNs,
  3. writes a matching ww3_prnc.inp, with the dimension and variable names
     taken from the file that was actually produced rather than assumed.

Steps 2 and 3 also run on their own (--skip-download) on a NetCDF you
already have, from CMEMS or anywhere else.

    pip install copernicusmarine xarray netcdf4
    copernicusmarine login          # once; stores your credentials

Example, the Orkney grids:

    python get_cmems_currents.py \
        --bbox -4.5 -1.5 58.3 59.7 \
        --start 2024-01-01 --end 2024-01-08 \
        --dataset cmems_mod_nws_phy_anfc_0.027deg-2D_PT15M-i \
        --lon-convention 0-360

Which product to ask for matters more than anything in this script. The
global products (cmems_mod_glo_phy_*, 1/12 deg) carry no tides, so for a
tidal site they give you the residual circulation and nothing of the stream
that actually matters. The North West Shelf products
(NWSHELF_ANALYSISFORECAST_PHY_004_013) are run with tides and resolve the
shelf far better, and the 15-minute 2D dataset above is the one to use
around Orkney. Check the catalogue for the dataset id that covers your dates:
an analysis-forecast product does not reach back in time, and the
corresponding reanalysis (NWSHELF_MULTIYEAR_PHY_004_009) does.
"""

import argparse
import os
import sys
import textwrap

import numpy as np
import xarray as xr


# Pairs of (eastward, northward) names CMEMS uses for velocity across its
# products. The first pair that is present in the file wins.
UV_CANDIDATES = [
    ("uo", "vo"),
    ("utotal", "vtotal"),
    ("utide", "vtide"),
    ("uo_detided", "vo_detided"),
    ("u", "v"),
    ("eastward_sea_water_velocity", "northward_sea_water_velocity"),
]

LON_NAMES = ["longitude", "lon", "nav_lon", "x"]
LAT_NAMES = ["latitude", "lat", "nav_lat", "y"]
TIME_NAMES = ["time", "time_counter"]
DEPTH_NAMES = ["depth", "deptht", "lev", "z"]


def parse_args(argv=None):
    p = argparse.ArgumentParser(
        description="CMEMS surface currents -> WAVEWATCH III forcing",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p.add_argument("--dataset", default="cmems_mod_nws_phy_anfc_0.027deg-2D_PT15M-i",
                   help="CMEMS dataset id (default: North West Shelf 15-min 2D, with tides)")
    p.add_argument("--bbox", nargs=4, type=float, metavar=("LONMIN", "LONMAX", "LATMIN", "LATMAX"),
                   help="area to subset, in the product's own longitude convention")
    p.add_argument("--start", help="first time, YYYY-MM-DD[THH:MM:SS]")
    p.add_argument("--end", help="last time, YYYY-MM-DD[THH:MM:SS]")
    p.add_argument("--variables", nargs="*", default=None,
                   help="variables to ask CMEMS for (default: uo vo)")
    p.add_argument("--raw", default="cmems_raw.nc", help="file the download is written to")
    p.add_argument("--out", default="cur_ww3.nc", help="WW3-ready file to write")
    p.add_argument("--inp", default="ww3_prnc.inp", help="ww3_prnc input file to write")
    p.add_argument("--lon-convention", choices=["keep", "0-360", "pm180"], default="keep",
                   help="longitude convention of the output; must match your WW3 grid. "
                        "0-360 for an eastward grid, pm180 for a -180..180 one. "
                        "(No dashed spelling: argparse would read -180-180 as an option.)")
    p.add_argument("--fill", type=float, default=0.0,
                   help="value put where the current is missing, i.e. over land (default 0)")
    p.add_argument("--skip-download", action="store_true",
                   help="use --raw as it is instead of downloading")
    p.add_argument("--dry-run", action="store_true",
                   help="report the size of the request without downloading")
    return p.parse_args(argv)


# ---------------------------------------------------------------- download

def download(a):
    """Subset the CMEMS product. Credentials come from `copernicusmarine login`."""
    import copernicusmarine

    if a.bbox is None or a.start is None or a.end is None:
        sys.exit("!! --bbox, --start and --end are needed to download "
                 "(or pass --skip-download to work on an existing file)")

    variables = a.variables if a.variables else ["uo", "vo"]
    lon_min, lon_max, lat_min, lat_max = a.bbox

    print(f"Requesting {a.dataset}")
    print(f"  lon {lon_min} .. {lon_max}   lat {lat_min} .. {lat_max}")
    print(f"  {a.start} .. {a.end}   variables {' '.join(variables)}")

    out_dir = os.path.dirname(os.path.abspath(a.raw))
    resp = copernicusmarine.subset(
        dataset_id=a.dataset,
        variables=variables,
        minimum_longitude=lon_min,
        maximum_longitude=lon_max,
        minimum_latitude=lat_min,
        maximum_latitude=lat_max,
        start_datetime=a.start,
        end_datetime=a.end,
        # Surface only. Harmless for a 2D dataset, which has no depth axis.
        minimum_depth=0.0,
        maximum_depth=1.0,
        output_directory=out_dir,
        output_filename=os.path.basename(a.raw),
        overwrite=True,
        dry_run=a.dry_run,
    )

    if a.dry_run:
        print(f"Dry run: {resp.file_size} MB would be downloaded. Nothing written.")
        return None

    path = getattr(resp, "file_path", a.raw)
    print(f"Downloaded {path}")
    return str(path)


# ------------------------------------------------------------ reshaping

def _find(names, candidates):
    for c in candidates:
        if c in names:
            return c
    return None


def find_uv(ds):
    """The eastward/northward velocity pair in the dataset."""
    for u, v in UV_CANDIDATES:
        if u in ds.variables and v in ds.variables:
            return u, v
    # fall back on the CF standard names
    u = v = None
    for name, da in ds.data_vars.items():
        sn = da.attrs.get("standard_name", "")
        if sn == "eastward_sea_water_velocity":
            u = name
        elif sn == "northward_sea_water_velocity":
            v = name
    if u and v:
        return u, v
    sys.exit(f"!! No velocity pair found in {list(ds.data_vars)}. "
             f"Pass the right --variables, or rename them first.")


def to_ww3(src, dst, lon_convention="keep", fill=0.0):
    """Rewrite a CMEMS subset as the rectilinear lon/lat/time file ww3_prnc reads."""
    ds = xr.open_dataset(src)

    uname, vname = find_uv(ds)
    print(f"Velocity components: {uname}, {vname}")

    lon = _find(ds.variables, LON_NAMES)
    lat = _find(ds.variables, LAT_NAMES)
    time = _find(ds.variables, TIME_NAMES)
    if lon is None or lat is None or time is None:
        sys.exit(f"!! Need a longitude, a latitude and a time in {list(ds.variables)}")

    # Two dimensional coordinates mean a curvilinear grid, which the 'LL'
    # format cannot describe. Caught here, before anything is renamed.
    if ds[lon].ndim != 1 or ds[lat].ndim != 1:
        sys.exit("!! The coordinates are 2D, so this is a curvilinear grid. "
                 "ww3_prnc would need a curvilinear setup, which this script "
                 "does not write.")

    u = ds[uname]
    v = ds[vname]

    # ww3_prnc wants a 2D field per time step, so a depth axis has to go.
    depth = _find(u.dims, DEPTH_NAMES)
    if depth is not None:
        dvals = ds[depth].values if depth in ds.variables else None
        k = int(np.argmin(np.abs(dvals))) if dvals is not None else 0
        if dvals is not None:
            print(f"Taking the surface level, depth = {float(dvals[k]):.2f} m")
        u = u.isel({depth: k}, drop=True)
        v = v.isel({depth: k}, drop=True)

    out = xr.Dataset({"uo": u, "vo": v})

    # ww3_prnc looks the dimensions up by name
    ren = {}
    if lon != "longitude":
        ren[lon] = "longitude"
    if lat != "latitude":
        ren[lat] = "latitude"
    if time != "time":
        ren[time] = "time"
    if ren:
        print(f"Renaming {ren}")
        out = out.rename(ren)

    # Longitudes on the same side as the WW3 grid, or the two never overlap
    if lon_convention != "keep":
        x = out["longitude"].values.astype(float)
        if lon_convention == "0-360":
            x = np.where(x < 0.0, x + 360.0, x)
        else:
            x = np.where(x > 180.0, x - 360.0, x)
        out = out.assign_coords(longitude=x).sortby("longitude")
        print(f"Longitudes put on {lon_convention}: "
              f"{out.longitude.values.min():.3f} .. {out.longitude.values.max():.3f}")

    # 'LL' expects both axes increasing
    for ax in ("longitude", "latitude"):
        a = out[ax].values
        if a.size > 1 and a[0] > a[-1]:
            print(f"Flipping {ax} so it increases")
            out = out.sortby(ax)
    out = out.sortby("time")

    # Land is NaN in CMEMS; WW3 interpolates the field as it stands, so the
    # gaps are filled. 0 means no current, which is what a dry cell should be.
    nu = int(np.isnan(out["uo"].values).sum())
    if nu:
        print(f"Filling {nu} missing values ({100.0*nu/out['uo'].size:.1f}%) with {fill}")
    out["uo"] = out["uo"].fillna(fill)
    out["vo"] = out["vo"].fillna(fill)

    out["uo"].attrs = {"units": "m s-1", "long_name": "eastward current"}
    out["vo"].attrs = {"units": "m s-1", "long_name": "northward current"}
    out.attrs["source"] = f"CMEMS {os.path.basename(src)} reshaped for ww3_prnc"

    enc = {k: {"_FillValue": None, "dtype": "float32"} for k in ("uo", "vo")}
    out.to_netcdf(dst, encoding=enc)

    nt = out.sizes["time"]
    print(f"Wrote {dst}: {out.sizes['longitude']} x {out.sizes['latitude']} points, "
          f"{nt} times")
    if nt > 1:
        dt = np.diff(out["time"].values[:2])[0] / np.timedelta64(1, "m")
        print(f"  {str(out.time.values[0])[:16]} .. {str(out.time.values[-1])[:16]}, "
              f"step {dt:g} min")
    sp = np.hypot(out["uo"].values, out["vo"].values)
    print(f"  speed up to {np.nanmax(sp):.2f} m/s, mean {np.nanmean(sp):.3f} m/s")

    ds.close()
    return dst


# ----------------------------------------------------------- ww3_prnc.inp

def write_prnc_inp(path, ncfile):
    """ww3_prnc.inp for the file just written, names read back from it."""
    ds = xr.open_dataset(ncfile)
    uname, vname = find_uv(ds)
    ds.close()

    txt = textwrap.dedent(f"""\
        $ -------------------------------------------------------------------- $
        $ WAVEWATCH III Field preprocessor input file                          $
        $ Written by get_cmems_currents.py                                     $
        $ -------------------------------------------------------------------- $
        $ Field type, format, time flag, header flag
        $   CUR : currents      LL : rectilinear longitude/latitude grid
        $
          'CUR' 'LL' T T
        $
        $ Name of the longitude and latitude dimensions (time is found on its own)
        $
          longitude latitude
        $
        $ The eastward and northward components, in that order, in m/s
        $
          {uname} {vname}
        $
        $ The forcing file
        $
          '{os.path.basename(ncfile)}'
        $
        $ -------------------------------------------------------------------- $
        $ End of input file                                                    $
        $ -------------------------------------------------------------------- $
        """)
    with open(path, "w") as f:
        f.write(txt)
    print(f"Wrote {path}")
    return path


def main(argv=None):
    a = parse_args(argv)

    if a.skip_download:
        if not os.path.exists(a.raw):
            sys.exit(f"!! {a.raw} not found")
        raw = a.raw
    else:
        raw = download(a)
        if raw is None:
            return 0

    to_ww3(raw, a.out, lon_convention=a.lon_convention, fill=a.fill)
    write_prnc_inp(a.inp, a.out)

    print(textwrap.dedent(f"""
        Next:
          ww3_grid                      # once, with FLCX/FLCY/FLCTH/FLCK set (see README)
          ww3_prnc                      # reads {a.inp} -> current.ww3
          ww3_shel                      # with Currents switched on in ww3_shel.inp
        """))
    return 0


if __name__ == "__main__":
    sys.exit(main())
