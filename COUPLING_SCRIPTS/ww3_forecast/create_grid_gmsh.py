#!/usr/bin/env python3
#======================================================================
#
#  create_grid_gmsh.py : build the unstructured (triangular) WW3 grid
#  for the forecast domain with the gmsh Python API.
#  Replaces create_grid_regional_gen.m (gridgen, regular grid).
#
#  Steps
#   1. Clip the GSHHG coastline (shapefile, level L1) to the domain box,
#      keep the largest water body (removes lakes / isolated basins,
#      as remove_lake did) and drop islands smaller than ISLAND_MIN.
#   2. Build a mesh-size map on the bathymetry grid:
#        h = min( h_depth(depth), h_coast(distance to land),
#                 h_site(distance to the output points) )
#   3. Mesh the water polygon with gmsh (Frontal-Delaunay) in a local
#      metric projection [km], then convert nodes back to lon/lat.
#   4. Interpolate the bathymetry on the nodes and write
#        <config>.msh            Gmsh 2.2 ASCII (lon lat depth[m, >0])
#        <config>.obc            open boundary node list (ww3_grid.inp)
#        <config>_obc_lonlat.txt open boundary nodes lon/lat (to define
#                                output boundary points in a parent grid)
#        <config>_grid.png       plot of the mesh (if PLOTGRID=1)
#
#  Environment (exported by ww3_forecast.sh):
#    LLLON LLLAT URLON URLAT WW3_config PLOTGRID
#    COASTFILE  GSHHG shapefile, e.g. .../GSHHS_shp/f/GSHHS_f_L1.shp
#    BATHYFILE  netCDF bathymetry (GEBCO or EMODnet, elevation < 0 at sea)
#    HMIN HMAX HCOAST DCOAST HSITE RSITE [km]   DREF DMIN [m]
#    ISLAND_MIN [km2]
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
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Updated November 2026 by Andres Sepulveda:
#    - Translated to Python 3; gridgen regular grid replaced by an
#      unstructured gmsh mesh refined with depth, coastline distance
#      and around the EMEC test sites (Orkney forecast)
#
#======================================================================
import sys
import numpy as np
from netCDF4 import Dataset
from scipy.interpolate import RegularGridInterpolator
from scipy.ndimage import distance_transform_edt
import shapefile                      # pyshp
from shapely.geometry import Polygon, MultiPolygon, box
from shapely.ops import unary_union
import shapely
import gmsh

from start import env, get_config, read_points

R_EARTH = 6371.0

#
# Parameters
#
cfg = get_config()
lonmin, lonmax, latmin, latmax = cfg['lonmin'], cfg['lonmax'], cfg['latmin'], cfg['latmax']
fname = cfg['config']
coastfile = env('COASTFILE')
bathyfile = env('BATHYFILE')
hmin = env('HMIN', 0.4, float)          # minimum element size [km]
hmax = env('HMAX', 4.0, float)          # maximum element size [km]
hcoast = env('HCOAST', 0.5, float)      # size at the coastline [km]
dcoast = env('DCOAST', 10.0, float)     # distance where h reaches hmax [km]
hsite = env('HSITE', 0.25, float)       # size at the output points [km]
rsite = env('RSITE', 2.0, float)        # radius of hsite around points [km]
dref = env('DREF', 100.0, float)        # depth where h_depth reaches hmax [m]
dmin = env('DMIN', 2.0, float)          # minimum depth of wet nodes [m]
island_min = env('ISLAND_MIN', 0.1, float)  # smallest island kept [km2]
plotgrid = env('PLOTGRID', 0, bool)

lon0 = 0.5 * (lonmin + lonmax)
lat0 = 0.5 * (latmin + latmax)
coslat0 = np.cos(np.deg2rad(lat0))


def ll2xy(lon, lat):
    x = np.deg2rad(np.asarray(lon) - lon0) * R_EARTH * coslat0
    y = np.deg2rad(np.asarray(lat) - lat0) * R_EARTH
    return x, y


def xy2ll(x, y):
    lon = lon0 + np.rad2deg(np.asarray(x) / (R_EARTH * coslat0))
    lat = lat0 + np.rad2deg(np.asarray(y) / R_EARTH)
    return lon, lat


#----------------------------------------------------------------------
# 1. Bathymetry
#----------------------------------------------------------------------
print('.........Reading bathymetry..................')
nc = Dataset(bathyfile)
vnames = list(nc.variables)
xname = next(v for v in ('lon', 'longitude', 'x') if v in vnames)
yname = next(v for v in ('lat', 'latitude', 'y') if v in vnames)
zname = next(v for v in ('elevation', 'z', 'depth', 'Band1', 'topo') if v in vnames)
blon = nc.variables[xname][:].astype(float)
blat = nc.variables[yname][:].astype(float)
ix = np.where((blon >= lonmin - 0.1) & (blon <= lonmax + 0.1))[0]
iy = np.where((blat >= latmin - 0.1) & (blat <= latmax + 0.1))[0]
elev = np.ma.filled(nc.variables[zname][iy[0]:iy[-1] + 1, ix[0]:ix[-1] + 1].astype(float), np.nan)
blon, blat = blon[ix], blat[iy]
nc.close()
if zname == 'depth':                     # positive-down file
    elev = -elev
if blat[0] > blat[-1]:
    blat, elev = blat[::-1], elev[::-1, :]
depth = -elev                            # > 0 at sea
print(f'   bathymetry {zname}: {elev.shape[1]} x {elev.shape[0]} points')

#----------------------------------------------------------------------
# 2. Coastline polygons
#----------------------------------------------------------------------
print('.........Reading coastline..................')
domain = box(lonmin, latmin, lonmax, latmax)
search = domain.buffer(0.2)
sf = shapefile.Reader(coastfile)
land = []
for shp in sf.iterShapes():
    bx = shp.bbox
    if bx[2] < lonmin - 0.2 or bx[0] > lonmax + 0.2 or \
       bx[3] < latmin - 0.2 or bx[1] > latmax + 0.2:
        continue
    parts = list(shp.parts) + [len(shp.points)]
    for p0, p1 in zip(parts[:-1], parts[1:]):
        poly = Polygon(shp.points[p0:p1]).buffer(0)
        if poly.intersects(search):
            land.append(poly)
land = unary_union(land) if land else Polygon()
print(f'   {len(land.geoms) if hasattr(land, "geoms") else 1} land polygons in domain')

print('.........Computing water body..................')
water = shapely.transform(domain.difference(land), lambda c: np.c_[ll2xy(c[:, 0], c[:, 1])])
if isinstance(water, MultiPolygon):
    water = max(water.geoms, key=lambda g: g.area)  # largest water body
#
# simplify (in km), remove small islands
#
water = water.simplify(hcoast / 3.0, preserve_topology=True).buffer(0)
if isinstance(water, MultiPolygon):
    water = max(water.geoms, key=lambda g: g.area)
holes = [h for h in water.interiors if Polygon(h).area >= island_min]
water = Polygon(water.exterior, holes)
print(f'   kept {len(holes)} islands larger than {island_min} km2')

#----------------------------------------------------------------------
# 3. Mesh size map (on the bathymetry grid)
#----------------------------------------------------------------------
print('.........Computing mesh size map..................')
dx_km = np.deg2rad(np.mean(np.diff(blon))) * R_EARTH * coslat0
dy_km = np.deg2rad(np.mean(np.diff(blat))) * R_EARTH
landmask = ~(depth > 0)
dist = distance_transform_edt(~landmask, sampling=(dy_km, dx_km))
dep = np.where(np.isnan(depth), 0., np.maximum(depth, 0.))
h_depth = hmin + (hmax - hmin) * np.clip(dep / dref, 0., 1.)
h_coast = hcoast + (hmax - hcoast) * np.clip(dist / dcoast, 0., 1.)
H = np.minimum(h_depth, h_coast)
LON, LAT = np.meshgrid(blon, blat)
X, Y = ll2xy(LON, LAT)
points = read_points('points.list')
for plon, plat, pname in points:
    px, py = ll2xy(plon, plat)
    r = np.hypot(X - px, Y - py)
    h_site = hsite + (hmax - hsite) * np.clip((r - rsite) / (4. * rsite), 0., 1.)
    H = np.minimum(H, h_site)
H = np.clip(H, min(hmin, hsite), hmax)
print(f'   size range {H.min():.3f} - {H.max():.3f} km, {len(points)} refinement points')
#
# fast bilinear lookup used by the gmsh size callback
#
xg = ll2xy(blon, lat0)[0]
yg = ll2xy(lon0, blat)[1]
x0g, dxg, nxg = xg[0], xg[1] - xg[0], len(xg)
y0g, dyg, nyg = yg[0], yg[1] - yg[0], len(yg)
Hl = H.tolist()


def size_callback(dim, tag, x, y, z, lc):
    fi = min(max((x - x0g) / dxg, 0.), nxg - 1.001)
    fj = min(max((y - y0g) / dyg, 0.), nyg - 1.001)
    i, j = int(fi), int(fj)
    a, b = fi - i, fj - j
    r0, r1 = Hl[j], Hl[j + 1]
    h = (1 - b) * ((1 - a) * r0[i] + a * r0[i + 1]) + b * ((1 - a) * r1[i] + a * r1[i + 1])
    return min(lc, h)


#----------------------------------------------------------------------
# 4. gmsh meshing
#----------------------------------------------------------------------
print('.........Meshing with gmsh..................')
gmsh.initialize()
gmsh.option.setNumber('General.Terminal', 1)
gmsh.model.add(fname)
geo = gmsh.model.geo


def add_ring(coords):
    coords = list(coords)[:-1]           # drop closing point
    pt = [geo.addPoint(x, y, 0.) for x, y in coords]
    ln = [geo.addLine(pt[k], pt[(k + 1) % len(pt)]) for k in range(len(pt))]
    return geo.addCurveLoop(ln)


loops = [add_ring(water.exterior.coords)]
for h in water.interiors:
    loops.append(add_ring(h.coords))
surf = geo.addPlaneSurface(loops)
geo.synchronize()
gmsh.model.addPhysicalGroup(2, [surf], 1)

gmsh.option.setNumber('Mesh.MeshSizeExtendFromBoundary', 0)
gmsh.option.setNumber('Mesh.MeshSizeFromPoints', 0)
gmsh.option.setNumber('Mesh.MeshSizeFromCurvature', 0)
gmsh.option.setNumber('Mesh.MeshSizeMin', min(hmin, hsite))
gmsh.option.setNumber('Mesh.MeshSizeMax', hmax)
gmsh.option.setNumber('Mesh.Algorithm', 6)          # Frontal-Delaunay
gmsh.model.mesh.setSizeCallback(size_callback)
gmsh.model.mesh.generate(2)
gmsh.model.mesh.optimize('Laplace2D')

ntags, ncoord, _ = gmsh.model.mesh.getNodes()
etypes, etags, enodes = gmsh.model.mesh.getElements(2)
tri = np.array(enodes[list(etypes).index(2)], dtype=np.int64).reshape(-1, 3)
gmsh.finalize()

xyz = ncoord.reshape(-1, 3)
tag2row = {t: k for k, t in enumerate(ntags)}
#
# keep only the nodes used by triangles, renumber 1..N
#
used = np.unique(tri)
new_id = {t: k + 1 for k, t in enumerate(used)}
xn = np.array([xyz[tag2row[t], 0] for t in used])
yn = np.array([xyz[tag2row[t], 1] for t in used])
tri = np.vectorize(new_id.get)(tri)
lon, lat = xy2ll(xn, yn)
#
# counter-clockwise orientation
#
i1, i2, i3 = tri[:, 0] - 1, tri[:, 1] - 1, tri[:, 2] - 1
area = (lon[i2] - lon[i1]) * (lat[i3] - lat[i1]) - (lon[i3] - lon[i1]) * (lat[i2] - lat[i1])
tri[area < 0] = tri[area < 0][:, [0, 2, 1]]

#----------------------------------------------------------------------
# 5. Depth at nodes
#----------------------------------------------------------------------
interp = RegularGridInterpolator((blat, blon), np.where(np.isnan(depth), -1., depth),
                                 bounds_error=False, fill_value=None)
dnode = interp(np.c_[lat, lon])
nshallow = int((dnode < dmin).sum())
dnode = np.maximum(dnode, dmin)
print(f'   {len(lon)} nodes, {len(tri)} triangles, {nshallow} nodes set to DMIN={dmin} m')

#----------------------------------------------------------------------
# 6. Open boundary nodes (boundary edges lying on the domain box)
#----------------------------------------------------------------------
edges = np.sort(np.vstack([tri[:, [0, 1]], tri[:, [1, 2]], tri[:, [2, 0]]]), axis=1)
uniq, cnt = np.unique(edges, axis=0, return_counts=True)
bnodes = np.unique(uniq[cnt == 1]) - 1
eps = 1e-6
onbox = (np.abs(lon[bnodes] - lonmin) < eps) | (np.abs(lon[bnodes] - lonmax) < eps) | \
        (np.abs(lat[bnodes] - latmin) < eps) | (np.abs(lat[bnodes] - latmax) < eps)
obc = bnodes[onbox]
print(f'   {len(obc)} open boundary nodes')

#----------------------------------------------------------------------
# 7. Output files
#----------------------------------------------------------------------
with open(f'{fname}.msh', 'w') as f:
    f.write('$MeshFormat\n2 0 8\n$EndMeshFormat\n')  # WW3 reads the version as an integer
    f.write(f'$Nodes\n{len(lon)}\n')
    for k in range(len(lon)):
        f.write(f'{k + 1} {lon[k]:.7f} {lat[k]:.7f} {dnode[k]:.3f}\n')
    f.write('$EndNodes\n')
    f.write(f'$Elements\n{len(tri)}\n')
    for k, (a, b, c) in enumerate(tri):
        f.write(f'{k + 1} 2 3 0 {k + 1} 0 {a} {b} {c}\n')
    f.write('$EndElements\n')
with open(f'{fname}.obc', 'w') as f:
    for n in obc:
        f.write(f'  {n + 1:7d}    1   F\n')
with open(f'{fname}_obc_lonlat.txt', 'w') as f:
    for n in obc:
        f.write(f'{lon[n]:.6f} {lat[n]:.6f}\n')
print(f' ... wrote {fname}.msh, {fname}.obc, {fname}_obc_lonlat.txt')

if plotgrid:
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    import matplotlib.tri as mtri
    T = mtri.Triangulation(lon, lat, tri - 1)
    fig, ax = plt.subplots(figsize=(12, 10))
    tc = ax.tripcolor(T, dnode, cmap='viridis_r', shading='gouraud')
    ax.triplot(T, color='k', lw=0.1)
    ax.plot(lon[obc], lat[obc], 'r.', ms=3, label='open boundary')
    for plon, plat, pname in points:
        ax.plot(plon, plat, 'w^', mec='k')
        ax.annotate(pname, (plon, plat), xytext=(4, 4), textcoords='offset points', fontsize=8)
    ax.set_aspect(1. / coslat0)
    plt.colorbar(tc, ax=ax, label='Depth [m]')
    ax.set_title(f'{fname}: {len(lon)} nodes, {len(tri)} triangles')
    ax.legend(loc='lower right')
    fig.savefig(f'{fname}_grid.png', dpi=150, bbox_inches='tight')
    print(f' ... wrote {fname}_grid.png')
