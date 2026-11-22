#!/usr/bin/env python3
"""
make_orkney_mesh.py
-------------------
Build an unstructured triangular mesh around the Orkney Islands for
WAVEWATCH III and write it as a Gmsh v2 ASCII file (lon, lat, depth).

Inputs (download yourself):
  * Coastline : GSHHG full-resolution land polygons, level 1
                e.g. GSHHS_shp/f/GSHHS_f_L1.shp
                https://www.soest.hawaii.edu/pwessel/gshhg/
  * Bathymetry: GEBCO grid subset in NetCDF (lat, lon, elevation)
                https://download.gebco.net/  (select the box below + margin)

Outputs:
  * orkney.msh       Gmsh v2 ASCII mesh: x=lon, y=lat, z=depth (m, positive down)
                     open-boundary nodes are written as type-15 point elements
  * orkney_mesh.png  quick-look plot of the mesh and depth

Requirements:
  pip install gmsh shapely pyproj pyshp netCDF4 scipy matplotlib

Usage:
  python make_orkney_mesh.py --coast GSHHS_f_L1.shp --bathy gebco_orkney.nc
"""

import argparse
import sys

import numpy as np
import shapefile                       # pyshp
import gmsh
from shapely.geometry import box, shape, Polygon, MultiPolygon, LineString
import shapely
from shapely.ops import unary_union
from shapely import ops as shapely_ops
from pyproj import Transformer
from netCDF4 import Dataset
from scipy.interpolate import RegularGridInterpolator

# --------------------------------------------------------------------------
# Default settings (all can be overridden from the command line)
# --------------------------------------------------------------------------
BBOX = (-4.20, 58.45, -1.80, 59.60)    # lon_min, lat_min, lon_max, lat_max
HMIN = 200.0          # element size at the coast (m)
HMAX = 4000.0         # element size far offshore (m)
DIST_MIN = 500.0      # keep HMIN up to this distance from the coast (m)
DIST_MAX = 20000.0    # reach HMAX at this distance from the coast (m)
MIN_ISLAND = 0.05     # drop islands smaller than this (km^2)
DEPTH_MIN = 2.0       # minimum depth assigned to wet nodes (m)
UTM_EPSG = 32630      # UTM zone 30N (metric projection for meshing)


def parse_args():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--coast", required=True, help="GSHHG L1 shapefile (.shp)")
    p.add_argument("--bathy", required=True, help="GEBCO NetCDF subset")
    p.add_argument("--out", default="orkney.msh", help="output Gmsh file")
    p.add_argument("--bbox", nargs=4, type=float, default=BBOX,
                   metavar=("LON0", "LAT0", "LON1", "LAT1"))
    p.add_argument("--hmin", type=float, default=HMIN)
    p.add_argument("--hmax", type=float, default=HMAX)
    p.add_argument("--dist-min", type=float, default=DIST_MIN)
    p.add_argument("--dist-max", type=float, default=DIST_MAX)
    p.add_argument("--min-island", type=float, default=MIN_ISLAND,
                   help="minimum island area kept (km^2)")
    p.add_argument("--depth-min", type=float, default=DEPTH_MIN)
    p.add_argument("--no-plot", action="store_true")
    return p.parse_args()


# --------------------------------------------------------------------------
# 1. Coastline -> ocean polygon (in metres)
# --------------------------------------------------------------------------
def read_land(coast_file, bbox_ll):
    """Read land polygons from the shapefile that intersect the box."""
    bb = box(*bbox_ll)
    r = shapefile.Reader(coast_file)
    polys = []
    for shp in r.iterShapes():
        x0, y0, x1, y1 = shp.bbox
        if x1 < bbox_ll[0] or x0 > bbox_ll[2] or y1 < bbox_ll[1] or y0 > bbox_ll[3]:
            continue
        g = shape(shp.__geo_interface__)
        if not g.is_valid:
            g = g.buffer(0)
        g = g.intersection(bb)
        if not g.is_empty:
            polys.append(g)
    if not polys:
        sys.exit("No coastline found inside the box - check --coast and --bbox")
    return unary_union(polys)


def ocean_polygon(land_ll, bbox_ll, to_m, hmin, min_island_km2):
    """Box minus land, projected to metres, cleaned for meshing."""
    def proj(g):
        if hasattr(shapely, "transform"):          # shapely >= 2.0
            return shapely.transform(
                g, lambda c: np.column_stack(to_m.transform(c[:, 0], c[:, 1])))
        return shapely_ops.transform(to_m.transform, g)   # shapely 1.x
    # densify the box edges before projecting so they stay straight-ish
    lon0, lat0, lon1, lat1 = bbox_ll
    n = 200
    edge = np.concatenate([
        np.c_[np.linspace(lon0, lon1, n), np.full(n, lat0)],
        np.c_[np.full(n, lon1), np.linspace(lat0, lat1, n)],
        np.c_[np.linspace(lon1, lon0, n), np.full(n, lat1)],
        np.c_[np.full(n, lon0), np.linspace(lat1, lat0, n)],
    ])
    bb_ll = Polygon(edge)
    ocean = proj(bb_ll).difference(proj(land_ll))

    # simplify the coastline to roughly half the minimum element size
    ocean = ocean.simplify(hmin / 2.0, preserve_topology=True).buffer(0)

    # keep only the largest connected water body (drops isolated lochs)
    if isinstance(ocean, MultiPolygon):
        ocean = max(ocean.geoms, key=lambda g: g.area)

    # drop tiny islands (holes) that the mesh cannot resolve
    min_area = max(min_island_km2 * 1e6, 4.0 * hmin**2)
    holes = [h for h in ocean.interiors if Polygon(h).area >= min_area]
    ocean = Polygon(ocean.exterior, holes)
    return ocean, proj(bb_ll)


# --------------------------------------------------------------------------
# 2. Mesh with Gmsh
# --------------------------------------------------------------------------
def build_mesh(ocean, bbox_m, args):
    """Mesh the ocean polygon; return nodes (m), triangles (0-based), open-boundary node ids."""
    bbox_line = bbox_m.exterior
    tol = args.hmin  # m: segments this close to the box edge are open boundary
                     # (matches the coastline simplification tolerance)

    gmsh.initialize()
    gmsh.option.setNumber("General.Terminal", 1)
    gmsh.option.setNumber("General.Verbosity", 2)   # warnings and errors only
    gmsh.model.add("orkney")
    geo = gmsh.model.geo

    coast_curves, open_curves = [], []

    def add_ring(coords):
        coords = list(coords)[:-1]                   # drop closing point
        pts = [geo.addPoint(x, y, 0.0) for x, y in coords]
        lines = []
        for i in range(len(pts)):
            a, b = pts[i], pts[(i + 1) % len(pts)]
            ln = geo.addLine(a, b)
            lines.append(ln)
            seg = LineString([coords[i], coords[(i + 1) % len(coords)]])
            if bbox_line.distance(seg.interpolate(0.5, normalized=True)) < tol \
               and bbox_line.distance(seg.boundary.geoms[0]) < tol \
               and bbox_line.distance(seg.boundary.geoms[1]) < tol:
                open_curves.append(ln)
            else:
                coast_curves.append(ln)
        return geo.addCurveLoop(lines)

    loops = [add_ring(ocean.exterior.coords)]
    for h in ocean.interiors:
        loops.append(add_ring(h.coords))
    surf = geo.addPlaneSurface(loops)
    geo.synchronize()

    gmsh.model.addPhysicalGroup(1, open_curves, 1, name="open")
    gmsh.model.addPhysicalGroup(1, coast_curves, 2, name="coast")
    gmsh.model.addPhysicalGroup(2, [surf], 3, name="water")

    # size field: fine at the coast, coarse offshore
    f_dist = gmsh.model.mesh.field.add("Distance")
    gmsh.model.mesh.field.setNumbers(f_dist, "CurvesList", coast_curves)
    gmsh.model.mesh.field.setNumber(f_dist, "Sampling", 20)
    f_thr = gmsh.model.mesh.field.add("Threshold")
    gmsh.model.mesh.field.setNumber(f_thr, "InField", f_dist)
    gmsh.model.mesh.field.setNumber(f_thr, "SizeMin", args.hmin)
    gmsh.model.mesh.field.setNumber(f_thr, "SizeMax", args.hmax)
    gmsh.model.mesh.field.setNumber(f_thr, "DistMin", args.dist_min)
    gmsh.model.mesh.field.setNumber(f_thr, "DistMax", args.dist_max)
    gmsh.model.mesh.field.setAsBackgroundMesh(f_thr)

    gmsh.option.setNumber("Mesh.MeshSizeExtendFromBoundary", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromPoints", 0)
    gmsh.option.setNumber("Mesh.MeshSizeFromCurvature", 0)
    gmsh.option.setNumber("Mesh.Algorithm", 6)       # Frontal-Delaunay
    gmsh.option.setNumber("Mesh.Smoothing", 5)
    gmsh.model.mesh.generate(2)
    gmsh.model.mesh.optimize("Laplace2D")

    tags, xyz, _ = gmsh.model.mesh.getNodes()
    xy = xyz.reshape(-1, 3)[:, :2]
    idx = {t: i for i, t in enumerate(tags)}

    _, _, tri_nodes = gmsh.model.mesh.getElements(2, surf)
    tri = np.array([idx[t] for t in tri_nodes[0]]).reshape(-1, 3)

    open_nodes = set()
    for c in open_curves:
        ntags, _, _ = gmsh.model.mesh.getNodes(1, c, includeBoundary=True)
        open_nodes.update(idx[t] for t in ntags)
    gmsh.finalize()

    # remove nodes not used by any triangle and renumber
    used = np.unique(tri)
    remap = -np.ones(len(xy), dtype=int)
    remap[used] = np.arange(len(used))
    xy = xy[used]
    tri = remap[tri]
    open_nodes = sorted(remap[i] for i in open_nodes if remap[i] >= 0)
    return xy, tri, np.array(open_nodes, dtype=int)


# --------------------------------------------------------------------------
# 3. Bathymetry
# --------------------------------------------------------------------------
def interp_depth(bathy_file, lon, lat, depth_min):
    """Bilinear interpolation of bathymetry/topography -> positive depth (m).

    Works with regional or global grids, longitudes in -180..180 or 0..360,
    ascending or descending latitude, and only reads the window it needs.
    """
    with Dataset(bathy_file) as nc:
        nc.set_auto_mask(False)
        names = list(nc.variables.keys())
        vlon = next((v for v in ("lon", "longitude", "x") if v in names), None)
        vlat = next((v for v in ("lat", "latitude", "y") if v in names), None)
        vz = next((v for v in ("elevation", "z", "Band1", "height", "topo",
                               "bathy", "depth") if v in names), None)
        if vz is None:   # fall back to the first 2-D variable
            vz = next((v for v in names if nc[v].ndim == 2), None)
        if None in (vlon, vlat, vz):
            sys.exit(f"Cannot identify lon/lat/elevation variables in {bathy_file}: {names}")
        glon = nc[vlon][:].astype(float)
        glat = nc[vlat][:].astype(float)
        zvar = nc[vz]
        lat_first = zvar.dimensions[0] in (nc[vlat].dimensions[0], vlat)
        positive_down = vz in ("depth", "bathy")
        print(f"  using {vz}({', '.join(zvar.dimensions)}) from {bathy_file}, "
              f"lon {glon.min():.2f}..{glon.max():.2f}")

        # put the mesh longitudes in the grid's convention
        if glon.max() > 180.0:
            qlon = np.mod(lon, 360.0)
        else:
            qlon = (lon + 180.0) % 360.0 - 180.0
        # box crosses the grid's seam (e.g. 0/360): work in a shifted frame
        seam = qlon.max() - qlon.min() > 180.0
        if seam:
            qlon = np.where(qlon > 180.0, qlon - 360.0, qlon) if glon.max() > 180.0 \
                else np.mod(qlon, 360.0)

        dlon = np.abs(np.diff(glon)).max()
        dlat = np.abs(np.diff(glat)).max()
        jlat = np.where((glat >= lat.min() - 2 * dlat) & (glat <= lat.max() + 2 * dlat))[0]
        if jlat.size < 2:
            sys.exit("Bathymetry file does not cover the mesh latitudes")
        ja, jb = jlat.min(), jlat.max() + 1

        def read(ia, ib):
            if lat_first:
                return zvar[ja:jb, ia:ib].astype(float)
            return zvar[ia:ib, ja:jb].astype(float).T

        lo, hi = qlon.min() - 2 * dlon, qlon.max() + 2 * dlon
        if not seam:
            ilon = np.where((glon >= lo) & (glon <= hi))[0]
            sel_lon, z = glon[ilon], read(ilon.min(), ilon.max() + 1)
        else:
            # stitch the two sides of the seam together
            shift = -360.0 if glon.max() > 180.0 else 360.0
            glon2 = np.where(glon > 180.0, glon + shift, glon) if shift < 0 \
                else np.where(glon < 0.0, glon + shift, glon)
            parts = []
            for side in (glon2 != glon, glon2 == glon):
                idx = np.where(side & (glon2 >= lo) & (glon2 <= hi))[0]
                if idx.size:
                    parts.append((glon2[idx.min():idx.max() + 1], read(idx.min(), idx.max() + 1)))
            parts.sort(key=lambda p: p[0][0])
            sel_lon = np.concatenate([p[0] for p in parts])
            z = np.concatenate([p[1] for p in parts], axis=1)
            sel_lon, keep = np.unique(sel_lon, return_index=True)   # drop 0/360 duplicate
            z = z[:, keep]
        sel_lat = glat[ja:jb]

    if sel_lat[0] > sel_lat[-1]:
        sel_lat, z = sel_lat[::-1], z[::-1, :]
    if sel_lon[0] > sel_lon[-1]:
        sel_lon, z = sel_lon[::-1], z[:, ::-1]
    if qlon.min() < sel_lon.min() or qlon.max() > sel_lon.max() \
       or lat.min() < sel_lat.min() or lat.max() > sel_lat.max():
        sys.exit("Bathymetry file does not cover the mesh box - download a larger subset")
    z[np.abs(z) > 1e20] = np.nan                       # fill values

    f = RegularGridInterpolator((sel_lat, sel_lon), z)
    zz = f(np.c_[lat, qlon])
    depth = zz if positive_down else -zz
    depth = np.where(np.isnan(depth), depth_min, depth)
    n_dry = int((depth < depth_min).sum())
    return np.maximum(depth, depth_min), n_dry


# --------------------------------------------------------------------------
# 4. Writers
# --------------------------------------------------------------------------
def make_ccw(lon, lat, tri):
    """Ensure counter-clockwise triangle ordering."""
    x, y = lon[tri], lat[tri]
    area2 = (x[:, 1] - x[:, 0]) * (y[:, 2] - y[:, 0]) - (x[:, 2] - x[:, 0]) * (y[:, 1] - y[:, 0])
    tri = tri.copy()
    cw = area2 < 0
    tri[cw] = tri[cw][:, [0, 2, 1]]
    return tri


def write_gmsh_v2(fname, lon, lat, depth, tri, open_nodes):
    """Gmsh v2 ASCII as read by ww3_grid (UNST)."""
    with open(fname, "w") as f:
        f.write("$MeshFormat\n2 0 8\n$EndMeshFormat\n")
        f.write(f"$Nodes\n{len(lon)}\n")
        for i, (x, y, d) in enumerate(zip(lon, lat, depth), start=1):
            f.write(f"{i} {x:.7f} {y:.7f} {d:.3f}\n")
        f.write("$EndNodes\n")
        nel = len(open_nodes) + len(tri)
        f.write(f"$Elements\n{nel}\n")
        k = 0
        for n in open_nodes:                       # open-boundary nodes
            k += 1
            f.write(f"{k} 15 2 0 {n + 1} {n + 1}\n")
        for t in tri:                              # triangles
            k += 1
            f.write(f"{k} 2 3 0 {k} 0 {t[0] + 1} {t[1] + 1} {t[2] + 1}\n")
        f.write("$EndElements\n")


def plot_mesh(fname, lon, lat, depth, tri, open_nodes):
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    fig, ax = plt.subplots(1, 2, figsize=(15, 7), constrained_layout=True)
    ax[0].triplot(lon, lat, tri, lw=0.2, color="k")
    ax[0].plot(lon[open_nodes], lat[open_nodes], "r.", ms=3, label="open boundary")
    ax[0].legend(loc="lower right")
    ax[0].set_title(f"Mesh: {len(lon)} nodes, {len(tri)} triangles")
    tc = ax[1].tripcolor(lon, lat, tri, depth, shading="gouraud", cmap="viridis_r")
    fig.colorbar(tc, ax=ax[1], label="depth (m)")
    ax[1].set_title("Depth")
    for a in ax:
        a.set_aspect(1.0 / np.cos(np.deg2rad(lat.mean())))
        a.set_xlabel("lon")
        a.set_ylabel("lat")
    fig.savefig(fname, dpi=150)


# --------------------------------------------------------------------------
def main():
    args = parse_args()
    bbox_ll = tuple(args.bbox)
    to_m = Transformer.from_crs(4326, UTM_EPSG, always_xy=True)
    to_ll = Transformer.from_crs(UTM_EPSG, 4326, always_xy=True)

    print("Reading coastline ...")
    land = read_land(args.coast, bbox_ll)
    ocean, bbox_m = ocean_polygon(land, bbox_ll, to_m, args.hmin, args.min_island)
    print(f"  ocean area {ocean.area / 1e6:.0f} km^2, {len(ocean.interiors)} islands kept")

    print("Meshing ...")
    xy, tri, open_nodes = build_mesh(ocean, bbox_m, args)
    lon, lat = to_ll.transform(xy[:, 0], xy[:, 1])
    lon, lat = np.asarray(lon), np.asarray(lat)
    tri = make_ccw(lon, lat, tri)

    print("Interpolating bathymetry ...")
    depth, n_dry = interp_depth(args.bathy, lon, lat, args.depth_min)
    if n_dry:
        print(f"  {n_dry} nodes shallower than {args.depth_min} m were set to {args.depth_min} m")

    write_gmsh_v2(args.out, lon, lat, depth, tri, open_nodes)
    print(f"Wrote {args.out}: {len(lon)} nodes, {len(tri)} triangles, "
          f"{len(open_nodes)} open-boundary nodes, depth {depth.min():.1f}-{depth.max():.1f} m")

    if not args.no_plot:
        png = args.out.rsplit(".", 1)[0] + "_mesh.png"
        plot_mesh(png, lon, lat, depth, tri, open_nodes)
        print(f"Wrote {png}")


if __name__ == "__main__":
    main()
