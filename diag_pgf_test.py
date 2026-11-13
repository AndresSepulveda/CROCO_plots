#!/usr/bin/env python3
"""
diag_pgf_test.py
================
Diagnostics for a CROCO pressure-gradient-error test (ocean at rest,
horizontally uniform stratification, closed basin, no forcing).

Reads one or several croco_his.nc files (processed record by record, so
memory use stays low) and produces:

  pgf_timeseries.csv   time, max|u|, max|v|, max speed, max barotropic speed,
                       volume-mean KE, max|zeta|
  pgf_timeseries.png   max velocities (log axis) and volume-mean KE vs time
  pgf_maps.png         maps of (a) time-max of the depth-max speed,
                       (b) depth-max speed at the last record,
                       (c) time-max barotropic speed, (d) bathymetry
  + printed location (i, j, sigma level, depth) of the largest spurious current

Usage
-----
  python diag_pgf_test.py croco_his.nc --grid croco_grd_closed.nc
  python diag_pgf_test.py croco_his.*.nc --grid croco_grd_closed.nc --outdir figs

The vertical grid parameters are read from the history file. If they are not
found, give them with --theta_s --theta_b --hc --vtransform.

Requires: numpy, netCDF4, matplotlib
"""
import argparse
import csv
import os
import sys

import numpy as np
from netCDF4 import Dataset

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


# ----------------------------------------------------------------------------
# Vertical grid
# ----------------------------------------------------------------------------
def cs_w_levels(N, theta_s, theta_b, vtransform):
    sc = (np.arange(0, N + 1) - N) / N
    if vtransform == 1:
        cff1 = 1.0 / np.sinh(theta_s)
        cff2 = 0.5 / np.tanh(0.5 * theta_s)
        cs = ((1.0 - theta_b) * cff1 * np.sinh(theta_s * sc)
              + theta_b * (cff2 * np.tanh(theta_s * (sc + 0.5)) - 0.5))
    else:
        if theta_s > 0:
            csrf = (1.0 - np.cosh(sc * theta_s)) / (np.cosh(theta_s) - 1.0)
        else:
            csrf = -sc ** 2
        if theta_b > 0:
            cs = (np.exp(theta_b * csrf) - 1.0) / (1.0 - np.exp(-theta_b))
        else:
            cs = csrf
    return sc, cs


def z_w_levels(h, zeta, sc, cs, hc, vtransform):
    sc = sc[:, None, None]
    cs = cs[:, None, None]
    if vtransform == 1:
        z0 = hc * sc + (h - hc) * cs
        return z0 + zeta * (1.0 + z0 / h)
    z0 = (hc * sc + h * cs) / (hc + h)
    return zeta + (zeta + h) * z0


def get_param(nc, name):
    """Look for a scalar parameter as global attribute or variable."""
    if name in nc.ncattrs():
        return float(np.atleast_1d(nc.getncattr(name))[0])
    if name in nc.variables:
        return float(np.atleast_1d(nc[name][:])[0])
    return None


def vertical_setup(nc, N, args):
    theta_s = args.theta_s if args.theta_s is not None else get_param(nc, "theta_s")
    theta_b = args.theta_b if args.theta_b is not None else get_param(nc, "theta_b")
    hc = args.hc if args.hc is not None else get_param(nc, "hc")
    vt = args.vtransform
    if vt is None:
        if "VertCoordType" in nc.ncattrs():
            vt = 2 if str(nc.getncattr("VertCoordType")).strip().upper() == "NEW" else 1
        else:
            v = get_param(nc, "Vtransform")
            vt = int(v) if v is not None else None
    if None in (theta_s, theta_b, hc, vt):
        sys.exit("Vertical grid parameters not found in the history file: "
                 "give --theta_s --theta_b --hc --vtransform")
    sc, cs = cs_w_levels(N, theta_s, theta_b, vt)
    print(f"Vertical grid: N={N}, theta_s={theta_s}, theta_b={theta_b}, "
          f"hc={hc}, Vtransform={vt}")
    return sc, cs, hc, vt


def time_name(nc):
    for name in ("scrum_time", "ocean_time", "time"):
        if name in nc.variables:
            return name
    sys.exit("No time variable (scrum_time / ocean_time / time) in history file")


def filled(var, idx):
    return np.ma.filled(var[idx].astype(float), 0.0)


# ----------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(description="Diagnostics of a CROCO PGF error test")
    ap.add_argument("his", nargs="+", help="croco_his.nc file(s), in time order")
    ap.add_argument("--grid", required=True, help="grid file used in the run")
    ap.add_argument("--outdir", default=".", help="output directory")
    ap.add_argument("--theta_s", type=float)
    ap.add_argument("--theta_b", type=float)
    ap.add_argument("--hc", type=float)
    ap.add_argument("--vtransform", type=int, choices=(1, 2))
    a = ap.parse_args()
    os.makedirs(a.outdir, exist_ok=True)

    # --- grid ---------------------------------------------------------------
    with Dataset(a.grid) as g:
        h = np.array(g["h"][:], dtype=float)
        pm = np.array(g["pm"][:], dtype=float)
        pn = np.array(g["pn"][:], dtype=float)
        mask = (np.array(g["mask_rho"][:], dtype=float)
                if "mask_rho" in g.variables else np.ones_like(h))
    wet = mask > 0.5
    area = mask / (pm * pn)                       # wet cell area [m2]

    def u2rho(u):                                 # (..., M, L-1) -> (..., M, L)
        out = np.zeros(u.shape[:-1] + (u.shape[-1] + 1,))
        out[..., 1:-1] = 0.5 * (u[..., :-1] + u[..., 1:])
        return out

    def v2rho(v):                                 # (..., M-1, L) -> (..., M, L)
        out = np.zeros(v.shape[:-2] + (v.shape[-2] + 1, v.shape[-1]))
        out[..., 1:-1, :] = 0.5 * (v[..., :-1, :] + v[..., 1:, :])
        return out

    rows = []
    max_map = np.zeros_like(h)                    # time-max of depth-max speed
    max_bt_map = np.zeros_like(h)                 # time-max of barotropic speed
    last_map = None
    best = dict(speed=-1.0)
    vert = None

    for fname in a.his:
        with Dataset(fname) as nc:
            nc.set_auto_mask(True)
            tname = time_name(nc)
            time = np.array(nc[tname][:], dtype=float) / 86400.0   # days
            N = nc["u"].shape[1]
            if vert is None:
                vert = vertical_setup(nc, N, a)
            sc, cs, hc, vt = vert
            for it in range(time.size):
                u = filled(nc["u"], it)
                v = filled(nc["v"], it)
                zeta = filled(nc["zeta"], it) if "zeta" in nc.variables \
                    else np.zeros_like(h)
                zeta = np.where(np.abs(zeta) > 1e4, 0.0, zeta)
                ur, vr = u2rho(u), v2rho(v)
                speed = np.sqrt(ur ** 2 + vr ** 2) * mask

                z_w = z_w_levels(h, zeta, sc, cs, hc, vt)
                hz = np.diff(z_w, axis=0)                           # (N, M, L)
                vol = hz * area
                ke = 0.5 * (ur ** 2 + vr ** 2)
                ke_mean = (ke * vol).sum() / vol.sum()              # m2 s-2

                depth = hz.sum(axis=0)
                ubt = (ur * hz).sum(axis=0) / depth
                vbt = (vr * hz).sum(axis=0) / depth
                sbt = np.sqrt(ubt ** 2 + vbt ** 2) * mask

                smax2d = speed.max(axis=0)
                max_map = np.maximum(max_map, smax2d)
                max_bt_map = np.maximum(max_bt_map, sbt)
                last_map = smax2d

                if speed.max() > best["speed"]:
                    k, j, i = np.unravel_index(speed.argmax(), speed.shape)
                    z_r = 0.5 * (z_w[k, j, i] + z_w[k + 1, j, i])
                    best = dict(speed=speed.max(), t=time[it], k=k, j=j, i=i,
                                z=z_r, h=h[j, i])

                rows.append((time[it], np.abs(u).max(), np.abs(v).max(),
                             speed.max(), sbt.max(), ke_mean,
                             np.abs(zeta[wet]).max()))
        print(f"Processed {fname} ({time.size} records)")

    if not rows:
        sys.exit("No records found")
    r = np.array(rows)
    r = r[np.argsort(r[:, 0], kind="stable")]
    t = r[:, 0]

    # --- CSV ----------------------------------------------------------------
    csv_name = os.path.join(a.outdir, "pgf_timeseries.csv")
    with open(csv_name, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["time_days", "max_abs_u_m_s", "max_abs_v_m_s",
                    "max_speed_m_s", "max_barotropic_speed_m_s",
                    "mean_KE_m2_s2", "max_abs_zeta_m"])
        w.writerows(r.tolist())

    # --- time series figure ---------------------------------------------------
    tiny = 1e-16
    fig, ax = plt.subplots(2, 1, figsize=(8, 7), sharex=True)
    ax[0].semilogy(t, r[:, 3] + tiny, "k-", lw=2, label="max speed (3D)")
    ax[0].semilogy(t, r[:, 1] + tiny, "-", lw=1, label="max |u|")
    ax[0].semilogy(t, r[:, 2] + tiny, "-", lw=1, label="max |v|")
    ax[0].semilogy(t, r[:, 4] + tiny, "--", lw=1.5, label="max barotropic speed")
    ax[0].set_ylabel("velocity [m s$^{-1}$]")
    ax[0].set_title("Spurious currents from pressure gradient error")
    ax[0].grid(True, which="both", alpha=0.3)
    ax[0].legend(fontsize=9)
    ax[1].semilogy(t, r[:, 5] + tiny, "k-", lw=2)
    ax[1].set_ylabel("volume-mean KE [m$^2$ s$^{-2}$]")
    ax[1].set_xlabel("time [days]")
    ax[1].grid(True, which="both", alpha=0.3)
    fig.tight_layout()
    ts_name = os.path.join(a.outdir, "pgf_timeseries.png")
    fig.savefig(ts_name, dpi=150)
    plt.close(fig)

    # --- maps -----------------------------------------------------------------
    def masked(x):
        return np.ma.masked_where(~wet, x)

    fig, ax = plt.subplots(2, 2, figsize=(12, 9), sharex=True, sharey=True)
    panels = [
        (max_map, "Time-max of depth-max speed [m s$^{-1}$]", "viridis"),
        (last_map, f"Depth-max speed, last record (day {t[-1]:.1f}) [m s$^{-1}$]",
         "viridis"),
        (max_bt_map, "Time-max barotropic speed [m s$^{-1}$]", "viridis"),
        (h, "Bathymetry h [m]", "Blues"),
    ]
    for axx, (fld, title, cmap) in zip(ax.ravel(), panels):
        pc = axx.pcolormesh(masked(fld), cmap=cmap, shading="auto")
        axx.contour(h, levels=[100, 200, 500, 1000, 2000, 3000, 4000],
                    colors="w" if cmap == "viridis" else "k",
                    linewidths=0.4, alpha=0.6)
        axx.set_title(title, fontsize=10)
        axx.set_aspect("equal")
        fig.colorbar(pc, ax=axx, shrink=0.85)
    ax[0, 0].plot(best["i"], best["j"], "r*", ms=12, mec="w")
    for axx in ax[1]:
        axx.set_xlabel("xi index")
    for axx in ax[:, 0]:
        axx.set_ylabel("eta index")
    fig.tight_layout()
    map_name = os.path.join(a.outdir, "pgf_maps.png")
    fig.savefig(map_name, dpi=150)
    plt.close(fig)

    # --- summary --------------------------------------------------------------
    print("\nSummary")
    print(f"  records: {t.size},  days {t[0]:.2f} - {t[-1]:.2f}")
    print(f"  largest spurious speed : {best['speed']:.3e} m/s at day {best['t']:.2f}")
    print(f"     location (0-based)  : xi={best['i']}, eta={best['j']}, "
          f"sigma level k={best['k'] + 1} of {N}")
    print(f"     depth of the point  : z = {best['z']:.1f} m  (h = {best['h']:.1f} m)")
    print(f"  final max speed        : {r[-1, 3]:.3e} m/s")
    print(f"  final max barotropic   : {r[-1, 4]:.3e} m/s")
    print(f"  final volume-mean KE   : {r[-1, 5]:.3e} m2/s2")
    print(f"  max |zeta| over run    : {r[:, 6].max():.3e} m")
    print(f"\nWrote {csv_name}\nWrote {ts_name}\nWrote {map_name}")


if __name__ == "__main__":
    main()
