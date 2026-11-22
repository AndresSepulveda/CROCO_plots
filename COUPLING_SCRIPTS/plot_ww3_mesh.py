#!/usr/bin/env python3
"""
plot_ww3_mesh.py
----------------
Plot a WAVEWATCH III unstructured mesh (Gmsh v2 ASCII, x=lon, y=lat, z=depth)
and, optionally, a field from a ww3_ounf NetCDF file on that mesh.

Figures:
  <prefix>_mesh.png    triangles + open-boundary nodes (type-15 elements)
  <prefix>_depth.png   depth at the nodes
  <prefix>_size.png    mean edge length per element (km), useful for CFL checks
  <prefix>_<var>.png   (optional) field from ww3_ounf output, e.g. hs

Usage:
  python plot_ww3_mesh.py orkney.msh
  python plot_ww3_mesh.py orkney.msh --nc ww3.201001.nc --var hs --time 24
  python plot_ww3_mesh.py orkney.msh --zoom -3.4 -2.9 58.75 59.0

Requirements: numpy, matplotlib (netCDF4 for --nc)
"""

import argparse

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.tri as mtri

R_EARTH = 6371000.0


def read_gmsh_v2(fname):
    """Return lon, lat, depth, triangles (0-based), open-boundary node ids (0-based)."""
    with open(fname) as f:
        lines = f.read().splitlines()
    i = lines.index("$Nodes")
    nn = int(lines[i + 1])
    nodes = np.loadtxt(lines[i + 2:i + 2 + nn])
    ids = nodes[:, 0].astype(int)
    pos = np.zeros(ids.max() + 1, dtype=int)          # node id -> row index
    pos[ids] = np.arange(nn)
    lon, lat, depth = nodes[:, 1], nodes[:, 2], nodes[:, 3]

    j = lines.index("$Elements")
    ne = int(lines[j + 1])
    tri, bnd = [], []
    for ln in lines[j + 2:j + 2 + ne]:
        v = [int(x) for x in ln.split()]
        etype, ntag = v[1], v[2]
        conn = v[3 + ntag:]
        if etype == 2:
            tri.append(conn[:3])
        elif etype == 15:
            bnd.append(conn[0])
    tri = pos[np.array(tri)]
    bnd = pos[np.array(bnd, dtype=int)] if bnd else np.array([], dtype=int)
    return lon, lat, depth, tri, bnd


def element_size_km(lon, lat, tri):
    """Mean edge length of each triangle (km), small-angle spherical approximation."""
    lam, phi = np.deg2rad(lon), np.deg2rad(lat)
    edges = []
    for a, b in ((0, 1), (1, 2), (2, 0)):
        dphi = phi[tri[:, b]] - phi[tri[:, a]]
        dlam = (lam[tri[:, b]] - lam[tri[:, a]]) * np.cos(0.5 * (phi[tri[:, a]] + phi[tri[:, b]]))
        edges.append(R_EARTH * np.hypot(dlam, dphi))
    return np.mean(edges, axis=0) / 1000.0


def setup_axes(ax, lat, zoom):
    ax.set_aspect(1.0 / np.cos(np.deg2rad(np.mean(lat))))
    ax.set_xlabel("Longitude (°)")
    ax.set_ylabel("Latitude (°)")
    if zoom:
        ax.set_xlim(zoom[0], zoom[1])
        ax.set_ylim(zoom[2], zoom[3])


def save(fig, name):
    fig.savefig(name, dpi=150, bbox_inches="tight")
    plt.close(fig)
    print("wrote", name)


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("mesh", help="Gmsh v2 mesh file (.msh)")
    p.add_argument("--nc", help="ww3_ounf NetCDF file on the same mesh")
    p.add_argument("--var", default="hs", help="variable to plot from --nc (default hs)")
    p.add_argument("--time", type=int, default=0, help="time index for --var (default 0)")
    p.add_argument("--zoom", nargs=4, type=float, metavar=("LON0", "LON1", "LAT0", "LAT1"))
    p.add_argument("--prefix", help="output file prefix (default: mesh file name)")
    a = p.parse_args()
    prefix = a.prefix or a.mesh.rsplit(".", 1)[0]

    lon, lat, depth, tri, bnd = read_gmsh_v2(a.mesh)
    T = mtri.Triangulation(lon, lat, tri)
    size = element_size_km(lon, lat, tri)
    print(f"{len(lon)} nodes, {len(tri)} triangles, {len(bnd)} open-boundary nodes")
    print(f"depth {depth.min():.1f} to {depth.max():.1f} m; "
          f"element size {size.min():.3f} to {size.max():.2f} km")

    # 1. mesh
    fig, ax = plt.subplots(figsize=(10, 8))
    ax.triplot(T, lw=0.15, color="0.2")
    if len(bnd):
        ax.plot(lon[bnd], lat[bnd], "r.", ms=3, label="open boundary")
        ax.legend(loc="lower right")
    ax.set_title(f"{a.mesh}: {len(lon)} nodes, {len(tri)} elements")
    setup_axes(ax, lat, a.zoom)
    save(fig, f"{prefix}_mesh.png")

    # 2. depth
    fig, ax = plt.subplots(figsize=(10, 8))
    tc = ax.tripcolor(T, depth, shading="gouraud", cmap="viridis_r")
    fig.colorbar(tc, ax=ax, label="Depth (m)", shrink=0.8)
    ax.set_title("Depth")
    setup_axes(ax, lat, a.zoom)
    save(fig, f"{prefix}_depth.png")

    # 3. element size
    fig, ax = plt.subplots(figsize=(10, 8))
    tc = ax.tripcolor(T, facecolors=size, cmap="magma_r",
                      norm=matplotlib.colors.LogNorm(vmin=size.min(), vmax=size.max()))
    fig.colorbar(tc, ax=ax, label="Mean edge length (km)", shrink=0.8)
    ax.set_title("Element size")
    setup_axes(ax, lat, a.zoom)
    save(fig, f"{prefix}_size.png")

    # 4. optional WW3 field
    if a.nc:
        from netCDF4 import Dataset, num2date
        with Dataset(a.nc) as nc:
            v = nc[a.var]
            data = np.ma.masked_invalid(np.ma.squeeze(v[a.time, ...]))
            units = getattr(v, "units", "")
            lname = getattr(v, "long_name", a.var)
            t = nc["time"]
            when = num2date(t[a.time], t.units).strftime("%Y-%m-%d %H:%M")
        if data.size != len(lon):
            raise SystemExit(f"{a.var} has {data.size} values but the mesh has {len(lon)} nodes")
        fig, ax = plt.subplots(figsize=(10, 8))
        tc = ax.tripcolor(T, data.filled(np.nan), shading="gouraud", cmap="turbo")
        fig.colorbar(tc, ax=ax, label=f"{a.var} ({units})", shrink=0.8)
        ax.set_title(f"{lname}  {when}")
        setup_axes(ax, lat, a.zoom)
        save(fig, f"{prefix}_{a.var}_t{a.time:04d}.png")


if __name__ == "__main__":
    main()
