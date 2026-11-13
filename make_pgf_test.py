#!/usr/bin/env python3
"""
make_pgf_test.py
================
Build the input files for a pressure-gradient-error (PGF / sigma-coordinate
error) test of a realistic CROCO grid.

From an existing croco_grd.nc it writes:

  croco_grd_closed.nc  copy of the grid with the 4 lateral boundaries masked
                       (land) so the basin is closed
  croco_ini.nc         ocean at rest (u=v=ubar=vbar=zeta=0) with a horizontally
                       uniform, statically stable stratification T(z), S(z)
  croco_blk.nc         bulk forcing designed to give (nearly) zero air-sea
                       fluxes: no wind, no radiation, no rain, Tair = SST
  croco_frc.nc         strictly zero fluxes (sustr, svstr, shflux, swflux,
                       swrad) for a run WITHOUT BULK_FLUX  (recommended)

Because T and S depend on z only, the horizontal pressure gradient is exactly
zero in the continuous equations. Any current that develops in the run is the
discrete pressure gradient error of the grid (bathymetry + vertical grid).

IMPORTANT: theta_s, theta_b, hc, N and Vtransform given here MUST be identical
to the values in croco.in / param.h / cppdefs.h (NEW_S_COORD -> Vtransform=2).

Usage example
-------------
  python make_pgf_test.py croco_grd.nc --N 32 --theta_s 7 --theta_b 2 --hc 200

  # with your own profile (ASCII columns: depth[m]  temp[C]  salt[psu])
  python make_pgf_test.py croco_grd.nc --N 32 --theta_s 7 --theta_b 2 \
         --hc 200 --profile my_profile.txt

Requires: numpy, netCDF4
"""
import argparse
import os
import shutil
import sys
from datetime import datetime

import numpy as np
from netCDF4 import Dataset


# ----------------------------------------------------------------------------
# Vertical grid (same formulas as CROCO set_scoord.F / croco_tools zlevs.m)
# ----------------------------------------------------------------------------
def scoord(N, theta_s, theta_b, vtransform):
    """Return sc_r, Cs_r, sc_w, Cs_w."""
    k_r = np.arange(1, N + 1)
    k_w = np.arange(0, N + 1)
    sc_r = (k_r - N - 0.5) / N
    sc_w = (k_w - N) / N

    if vtransform == 1:  # old S-coordinate (Song & Haidvogel 1994)
        def cs(sc):
            cff1 = 1.0 / np.sinh(theta_s)
            cff2 = 0.5 / np.tanh(0.5 * theta_s)
            return ((1.0 - theta_b) * cff1 * np.sinh(theta_s * sc)
                    + theta_b * (cff2 * np.tanh(theta_s * (sc + 0.5)) - 0.5))
    elif vtransform == 2:  # NEW_S_COORD (Shchepetkin 2010)
        def cs(sc):
            if theta_s > 0:
                csrf = (1.0 - np.cosh(sc * theta_s)) / (np.cosh(theta_s) - 1.0)
            else:
                csrf = -sc ** 2
            if theta_b > 0:
                return (np.exp(theta_b * csrf) - 1.0) / (1.0 - np.exp(-theta_b))
            return csrf
    else:
        raise ValueError("vtransform must be 1 or 2")
    return sc_r, cs(sc_r), sc_w, cs(sc_w)


def zlevs(h, zeta, sc, Cs, hc, vtransform):
    """Depths z(k, eta, xi) [m, negative downward] for given sc, Cs levels."""
    sc = sc[:, None, None]
    Cs = Cs[:, None, None]
    h3 = h[None, :, :]
    z3 = zeta[None, :, :]
    if vtransform == 1:
        z0 = hc * sc + (h3 - hc) * Cs
        return z0 + z3 * (1.0 + z0 / h3)
    z0 = (hc * sc + h3 * Cs) / (hc + h3)
    return z3 + (z3 + h3) * z0


# ----------------------------------------------------------------------------
# Stratification: functions of z ONLY
# ----------------------------------------------------------------------------
def analytic_profile(z, t_surf, t_bot, delta, s_const):
    """Exponential thermocline, constant salinity (classic seamount-type test)."""
    temp = t_bot + (t_surf - t_bot) * np.exp(z / delta)
    salt = np.full_like(temp, s_const)
    return temp, salt


def load_profile(fname):
    """ASCII file: depth[m] temp[C] salt[psu]. Depth sign is ignored."""
    data = np.loadtxt(fname, comments="#")
    if data.ndim != 2 or data.shape[1] < 3:
        sys.exit("Profile file must have 3 columns: depth temp salt")
    zp = -np.abs(data[:, 0])
    order = np.argsort(zp)               # increasing z (deep -> surface)
    return zp[order], data[order, 1], data[order, 2]


def linear_rho(temp, salt):
    """Rough linear EOS, used ONLY for the static-stability check."""
    return 1025.0 * (1.0 - 2.0e-4 * (temp - 10.0) + 7.6e-4 * (salt - 35.0))


# ----------------------------------------------------------------------------
# Grid stiffness diagnostics (they control the size of the PGF error)
# ----------------------------------------------------------------------------
def stiffness(h, mask, z_w):
    """Return max rx0 (Beckmann & Haidvogel) and max rx1 (Haney number)."""
    rx0 = 0.0
    rx1 = 0.0
    for axis in (0, 1):
        sl_a = [slice(None)] * 2
        sl_b = [slice(None)] * 2
        sl_a[axis] = slice(0, -1)
        sl_b[axis] = slice(1, None)
        a, b = tuple(sl_a), tuple(sl_b)
        wet = (mask[a] * mask[b]) > 0.5
        if not wet.any():
            continue
        r0 = np.abs(h[b] - h[a]) / (h[b] + h[a])
        rx0 = max(rx0, r0[wet].max())
        za = z_w[(slice(None),) + a]
        zb = z_w[(slice(None),) + b]
        num = np.abs(zb[1:] - za[1:] + zb[:-1] - za[:-1])
        den = np.abs(zb[1:] + za[1:] - zb[:-1] - za[:-1])
        r1 = num / np.maximum(den, 1e-12)
        rx1 = max(rx1, r1[:, wet].max())
    return rx0, rx1


# ----------------------------------------------------------------------------
# File writers
# ----------------------------------------------------------------------------
def close_grid(grd_in, grd_out):
    """Copy the grid and mask the outermost rho row/column on the 4 sides."""
    shutil.copyfile(grd_in, grd_out)
    with Dataset(grd_out, "a") as nc:
        if "mask_rho" not in nc.variables:
            sys.exit("Grid has no mask_rho variable")
        m = np.array(nc["mask_rho"][:], dtype=float)
        m[0, :] = m[-1, :] = 0.0
        m[:, 0] = m[:, -1] = 0.0
        mu = m[:, :-1] * m[:, 1:]
        mv = m[:-1, :] * m[1:, :]
        mp = mu[:-1, :] * mu[1:, :]
        nc["mask_rho"][:] = m
        for name, val in (("mask_u", mu), ("mask_v", mv), ("mask_psi", mp)):
            if name in nc.variables:
                nc[name][:] = val
        nc.history = (getattr(nc, "history", "") +
                      f"\n{datetime.now():%Y-%m-%d %H:%M} lateral boundaries "
                      "closed by make_pgf_test.py")
    return m


def horiz_dims(nc, L, M):
    nc.createDimension("xi_rho", L)
    nc.createDimension("eta_rho", M)
    nc.createDimension("xi_u", L - 1)
    nc.createDimension("eta_u", M)
    nc.createDimension("xi_v", L)
    nc.createDimension("eta_v", M - 1)


def write_ini(fname, grdname, h, temp, salt, p):
    N = p["N"]
    M, L = h.shape
    with Dataset(fname, "w", format="NETCDF4_CLASSIC") as nc:
        horiz_dims(nc, L, M)
        nc.createDimension("s_rho", N)
        nc.createDimension("s_w", N + 1)
        nc.createDimension("time", None)
        nc.createDimension("one", 1)

        def var(name, dtype, dims, long_name, units=None):
            v = nc.createVariable(name, dtype, dims)
            v.long_name = long_name
            if units:
                v.units = units
            return v

        var("spherical", "S1", ("one",), "grid type logical switch")[:] = "T"
        var("Vtransform", "i4", ("one",),
            "vertical terrain-following transformation equation")[:] = p["vtransform"]
        var("Vstretching", "i4", ("one",),
            "vertical terrain-following stretching function")[:] = 1
        var("tstart", "f8", ("one",), "start processing day", "day")[:] = 0.0
        var("tend", "f8", ("one",), "end processing day", "day")[:] = 0.0
        var("theta_s", "f8", ("one",), "S-coordinate surface control parameter")[:] = p["theta_s"]
        var("theta_b", "f8", ("one",), "S-coordinate bottom control parameter")[:] = p["theta_b"]
        var("Tcline", "f8", ("one",), "S-coordinate surface/bottom layer width", "meter")[:] = p["hc"]
        var("hc", "f8", ("one",), "S-coordinate parameter, critical depth", "meter")[:] = p["hc"]
        var("sc_r", "f8", ("s_rho",), "S-coordinate at RHO-points")[:] = p["sc_r"]
        var("Cs_r", "f8", ("s_rho",), "S-coordinate stretching curves at RHO-points")[:] = p["Cs_r"]
        var("sc_w", "f8", ("s_w",), "S-coordinate at W-points")[:] = p["sc_w"]
        var("Cs_w", "f8", ("s_w",), "S-coordinate stretching curves at W-points")[:] = p["Cs_w"]
        var("ocean_time", "f8", ("time",), "time since initialization", "second")[0] = 0.0
        var("scrum_time", "f8", ("time",), "time since initialization", "second")[0] = 0.0

        var("zeta", "f8", ("time", "eta_rho", "xi_rho"), "free-surface", "meter")[0] = 0.0
        var("ubar", "f8", ("time", "eta_u", "xi_u"),
            "vertically integrated u-momentum component", "meter second-1")[0] = 0.0
        var("vbar", "f8", ("time", "eta_v", "xi_v"),
            "vertically integrated v-momentum component", "meter second-1")[0] = 0.0
        var("u", "f8", ("time", "s_rho", "eta_u", "xi_u"),
            "u-momentum component", "meter second-1")[0] = 0.0
        var("v", "f8", ("time", "s_rho", "eta_v", "xi_v"),
            "v-momentum component", "meter second-1")[0] = 0.0
        var("temp", "f8", ("time", "s_rho", "eta_rho", "xi_rho"),
            "potential temperature", "Celsius")[0] = temp
        var("salt", "f8", ("time", "s_rho", "eta_rho", "xi_rho"),
            "salinity", "PSU")[0] = salt

        nc.title = "PGF error test: ocean at rest, T(z), S(z) horizontally uniform"
        nc.grd_file = grdname
        nc.type = "CROCO initial file"
        nc.history = f"Created by make_pgf_test.py on {datetime.now():%Y-%m-%d %H:%M}"


def write_blk(fname, grdname, h, sst, cycle):
    """Bulk file with no wind, no radiation, no rain, Tair = SST."""
    M, L = h.shape
    t = (np.arange(12) + 0.5) * cycle / 12.0      # 12 records over the cycle
    nt = t.size
    with Dataset(fname, "w", format="NETCDF4_CLASSIC") as nc:
        horiz_dims(nc, L, M)
        nc.createDimension("bulk_time", None)

        tv = nc.createVariable("bulk_time", "f8", ("bulk_time",))
        tv.long_name = "bulk formulation execution time"
        tv.units = "days"
        tv.cycle_length = cycle
        tv[:] = t

        rho = ("bulk_time", "eta_rho", "xi_rho")
        specs = [
            # name, dims, long_name, units, value
            ("tair", rho, "surface air temperature", "Celsius", sst),
            # 0.98 = salinity reduction of saturation humidity over sea water
            # used in the bulk formulae -> q_air = q_sea -> no latent heat flux
            ("rhum", rho, "relative humidity", "fraction", 0.98),
            ("prate", rho, "precipitation rate", "cm day-1", 0.0),
            ("wspd", rho, "wind speed 10m", "m s-1", 0.0),
            ("radlw", rho, "net outgoing longwave radiation", "Watts meter-2", 0.0),
            ("radlw_in", rho, "downward longwave radiation", "Watts meter-2", None),
            ("radsw", rho, "solar shortwave radiation", "Watts meter-2", 0.0),
            ("uwnd", ("bulk_time", "eta_u", "xi_u"), "u-wind", "m s-1", 0.0),
            ("vwnd", ("bulk_time", "eta_v", "xi_v"), "v-wind", "m s-1", 0.0),
            ("sustr", ("bulk_time", "eta_u", "xi_u"),
             "surface u-momentum stress", "Newton meter-2", 0.0),
            ("svstr", ("bulk_time", "eta_v", "xi_v"),
             "surface v-momentum stress", "Newton meter-2", 0.0),
        ]
        # downward LW that balances the sea-surface emission (case BULK_LW)
        emiss, sigma = 0.985, 5.6697e-8
        lw_in = emiss * sigma * (sst + 273.16) ** 4 / emiss  # = sigma*T^4

        for name, dims, long_name, units, val in specs:
            v = nc.createVariable(name, "f8", dims)
            v.long_name = long_name
            v.units = units
            v.time = "bulk_time"
            if name == "radlw_in":
                val = lw_in
            for i in range(nt):
                v[i] = val

        nc.title = "PGF error test: bulk forcing with (nearly) zero air-sea fluxes"
        nc.grd_file = grdname
        nc.type = "CROCO heat flux bulk forcing file"
        nc.history = f"Created by make_pgf_test.py on {datetime.now():%Y-%m-%d %H:%M}"


def write_frc(fname, grdname, h, cycle):
    """Classic forcing file with exactly zero fluxes (run without BULK_FLUX)."""
    M, L = h.shape
    t = (np.arange(12) + 0.5) * cycle / 12.0
    with Dataset(fname, "w", format="NETCDF4_CLASSIC") as nc:
        horiz_dims(nc, L, M)
        fields = [
            ("sms_time", "surface momentum stress time", [
                ("sustr", ("eta_u", "xi_u"), "surface u-momentum stress", "Newton meter-2"),
                ("svstr", ("eta_v", "xi_v"), "surface v-momentum stress", "Newton meter-2")]),
            ("shf_time", "surface heat flux time", [
                ("shflux", ("eta_rho", "xi_rho"), "surface net heat flux", "Watts meter-2")]),
            ("swf_time", "surface freshwater flux time", [
                ("swflux", ("eta_rho", "xi_rho"),
                 "surface freshwater flux (E-P)", "centimeter day-1")]),
            ("srf_time", "solar shortwave radiation time", [
                ("swrad", ("eta_rho", "xi_rho"),
                 "solar shortwave radiation", "Watts meter-2")]),
        ]
        for tname, tlong, vlist in fields:
            nc.createDimension(tname, t.size)
            tv = nc.createVariable(tname, "f8", (tname,))
            tv.long_name = tlong
            tv.units = "days"
            tv.cycle_length = cycle
            tv[:] = t
            for name, dims, long_name, units in vlist:
                v = nc.createVariable(name, "f8", (tname,) + dims)
                v.long_name = long_name
                v.units = units
                v[:] = 0.0
        nc.title = "PGF error test: zero surface fluxes"
        nc.grd_file = grdname
        nc.type = "CROCO forcing file"
        nc.history = f"Created by make_pgf_test.py on {datetime.now():%Y-%m-%d %H:%M}"


# ----------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(
        description="Create closed grid + ini + blk/frc files for a CROCO "
                    "pressure-gradient-error test.")
    ap.add_argument("grid", help="input croco_grd.nc")
    ap.add_argument("--outdir", default=".", help="output directory")
    ap.add_argument("--N", type=int, required=True, help="number of sigma levels")
    ap.add_argument("--theta_s", type=float, required=True)
    ap.add_argument("--theta_b", type=float, required=True)
    ap.add_argument("--hc", type=float, required=True, help="hc / Tcline [m]")
    ap.add_argument("--vtransform", type=int, default=2, choices=(1, 2),
                    help="2 = NEW_S_COORD defined (default), 1 = old S-coord")
    ap.add_argument("--profile", help="ASCII profile: depth temp salt")
    ap.add_argument("--t_surf", type=float, default=20.0, help="surface T [C]")
    ap.add_argument("--t_bot", type=float, default=2.0, help="deep T [C]")
    ap.add_argument("--delta", type=float, default=500.0,
                    help="e-folding depth of the thermocline [m]")
    ap.add_argument("--salt", type=float, default=35.0, help="constant salinity")
    ap.add_argument("--cycle", type=float, default=360.0,
                    help="cycle_length of forcing files [days]")
    ap.add_argument("--keep-open", action="store_true",
                    help="do NOT mask the lateral boundaries of the grid")
    a = ap.parse_args()

    os.makedirs(a.outdir, exist_ok=True)
    grd_out = os.path.join(a.outdir, "croco_grd_closed.nc")
    ini_out = os.path.join(a.outdir, "croco_ini.nc")
    blk_out = os.path.join(a.outdir, "croco_blk.nc")
    frc_out = os.path.join(a.outdir, "croco_frc.nc")

    # --- grid ---------------------------------------------------------------
    with Dataset(a.grid) as nc:
        h = np.array(nc["h"][:], dtype=float)
        mask = (np.array(nc["mask_rho"][:], dtype=float)
                if "mask_rho" in nc.variables else np.ones_like(h))
    if a.keep_open:
        grd_used = a.grid
        print("Grid left untouched (close the boundaries with undef OBC_*)")
    else:
        mask = close_grid(a.grid, grd_out)
        grd_used = grd_out
        print(f"Wrote {grd_out}")

    # --- vertical grid ------------------------------------------------------
    hmin = h.min()
    hc = a.hc
    if a.vtransform == 1:
        hc = min(hmin, a.hc)             # as CROCO does for the old S-coord
        if hc != a.hc:
            print(f"Vtransform=1: hc reset to min(hmin,Tcline) = {hc:.2f} m")
    sc_r, Cs_r, sc_w, Cs_w = scoord(a.N, a.theta_s, a.theta_b, a.vtransform)
    zeta = np.zeros_like(h)
    z_r = zlevs(h, zeta, sc_r, Cs_r, hc, a.vtransform)
    z_w = zlevs(h, zeta, sc_w, Cs_w, hc, a.vtransform)

    # --- stratification, function of z only ----------------------------------
    if a.profile:
        zp, tp, sp = load_profile(a.profile)
        if zp.min() > z_r.min():
            print(f"WARNING: profile ends at {zp.min():.0f} m but the grid "
                  f"reaches {z_r.min():.0f} m; deepest value is extended.")
        temp = np.interp(z_r, zp, tp)
        salt = np.interp(z_r, zp, sp)
        zc = np.linspace(z_r.min(), 0.0, 2000)
        rho_c = linear_rho(np.interp(zc, zp, tp), np.interp(zc, zp, sp))
    else:
        temp, salt = analytic_profile(z_r, a.t_surf, a.t_bot, a.delta, a.salt)
        zc = np.linspace(z_r.min(), 0.0, 2000)
        rho_c = linear_rho(*analytic_profile(zc, a.t_surf, a.t_bot, a.delta, a.salt))

    if np.any(np.diff(rho_c) > 1e-10):   # density must decrease upward
        print("WARNING: the profile is NOT statically stable everywhere "
              "(linear EOS check). Convection would contaminate the test.")
    else:
        n2max = (9.81 / 1025.0) * np.max(-np.diff(rho_c) / np.diff(zc))
        print(f"Stable profile. Max N^2 ~ {n2max:.2e} s-2 (linear EOS estimate)")

    # --- write files --------------------------------------------------------
    p = dict(N=a.N, theta_s=a.theta_s, theta_b=a.theta_b, hc=hc,
             vtransform=a.vtransform, sc_r=sc_r, Cs_r=Cs_r, sc_w=sc_w, Cs_w=Cs_w)
    write_ini(ini_out, grd_used, h, temp, salt, p)
    print(f"Wrote {ini_out}")
    write_blk(blk_out, grd_used, h, temp[-1], a.cycle)
    print(f"Wrote {blk_out}")
    write_frc(frc_out, grd_used, h, a.cycle)
    print(f"Wrote {frc_out}")

    # --- diagnostics --------------------------------------------------------
    rx0, rx1 = stiffness(h, mask, z_w)
    print("\nGrid summary")
    print(f"  size (eta_rho, xi_rho) : {h.shape},  N = {a.N}")
    print(f"  hmin / hmax            : {hmin:.1f} / {h.max():.1f} m")
    print(f"  Vtransform, theta_s, theta_b, hc : "
          f"{a.vtransform}, {a.theta_s}, {a.theta_b}, {hc}")
    print(f"  max rx0 (slope parameter) : {rx0:.3f}   (usual target < 0.2-0.25)")
    print(f"  max rx1 (Haney number)    : {rx1:.2f}   (usual target < 5-8)")
    print(f"  T range : {temp.min():.2f} - {temp.max():.2f} C,  "
          f"S range : {salt.min():.2f} - {salt.max():.2f}")


if __name__ == "__main__":
    main()
