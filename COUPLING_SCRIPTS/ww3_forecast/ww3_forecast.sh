#!/bin/bash
#======================================================================
#
#  WW3 forecast script for a single domain
#  Orkney Islands - unstructured (gmsh) grid
#  forced by GFS winds, Copernicus Marine currents and sea level
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
#  Patrick Marchesiello  - September 2011
#  Copyright (c) 2011-2012 by Patrick Marchesiello
#  e-mail:patrick.marchesiello@ird.fr
#
#  Updated November 2026 by Andres Sepulveda:
#    - Orkney Islands domain, unstructured grid built with gmsh
#    - GFS 0.25 deg hourly winds from NOMADS (ww3_prnc, netCDF)
#    - Copernicus Marine hourly currents and sea level forecast
#    - Matlab/Octave scripts replaced by Python scripts
#    - WW3 v6.07 input files (UNST grid, netCDF outputs with
#      ww3_ounf / ww3_ounp), spectral output at EMEC test sites
#    - Restart chaining between consecutive forecasts
#    - Stop when ww3_grid fails (no mod_def.ww3)
#
#======================================================================
#
# Environment for Crontab
#
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
#
export F_UFMTENDIAN=big
ulimit -s unlimited
export KMP_STACKSIZE=50m
export OMP_NUM_THREADS=4
#
PATH=$PATH:/bin:/usr/local/bin:./
PATH=$PATH:/home/hda_user/WW3-main/model/bin:/home/hda_user/WW3-main/model/exe_serial
export PATH
#
# Specific environment variables
#
export CP=/bin/cp
export MV=/bin/mv
export RM=/bin/rm
export PYTHON=/home/hda_user/miniconda3/envs/croco_pyenv/bin/python
export CMEMS=copernicusmarine        # Copernicus Marine Toolbox (v2) CLI
#
#=========================================================
# USER DEFINED PARAMETERS
#=========================================================
export WW3DIR=/ocean/WW3
export RUNDIR=/home/hda_user/Forecast_WW3
export TOOLSDIR=$RUNDIR              # location of the Python scripts
export OUTDIR=$RUNDIR/OUTPUT
export RESTDIR=$RUNDIR/RESTART
export ARCHDIR=$RUNDIR/ARCHIVE
export WEBDIR=                       # optional: copy figures there
#
# Area of interest
#
export WW3_title="'Orkney Islands - unstructured gmsh grid'"
export WW3_config=Orkney   # No blank spaces
#
# Domain Lower Left and Upper Rigth corners:
# (includes the Pentland Firth and the Caithness coast)
#
export LLLON=-4.20
export LLLAT=58.45
export URLON=-1.80
export URLAT=59.55
#
# Unstructured grid (gmsh) : sources and element sizes
#   COASTFILE : GSHHG shapefile, full resolution, level 1
#   BATHYFILE : GEBCO / EMODnet netCDF (elevation < 0 at sea)
#   sizes in km, depths in m
#
export COASTFILE=${HOME}/gridgen-main/reference_data/GSHHS_shp/f/GSHHS_f_L1.shp
export BATHYFILE=${HOME}/gridgen-main/reference_data/OrkneyTopo50.nc
#export BATHYFILE=${HOME}/gridgen-main/reference_data/etopo1.nc
export HMIN=0.4        # element size in shallow water
export HMAX=4.0        # element size offshore
export HCOAST=0.5      # element size at the coastline
export DCOAST=10.      # distance from coast where HMAX is reached
export HSITE=0.25      # element size at the output points
export RSITE=2.0       # radius of the HSITE refinement
export DREF=100.       # depth where the depth criterion reaches HMAX
export DMIN=2.0        # minimum depth of wet nodes
export ISLAND_MIN=0.1  # smallest island kept [km2]
#
# Propagation scheme on the unstructured grid
#   EXPLICIT : N scheme, works with any UNST build
#   IMPLICIT : fully implicit scheme, needs WW3 compiled with PDLIB
#
export UG_SCHEME=EXPLICIT
#
# Output spectral points (EMEC test sites and Pentland Firth)
# lon  lat  'NAME' (10 characters max.)
# Coordinates are approximate (WGS84): check them against the EMEC
# berth coordinates before operational use.
#
POINTS="
 -2.9300  58.9020  'ScapaFlow '
 -2.8930  58.9930  'ShapinsayS'
 -3.4094  58.9920  'BilliaCroo'
 -3.3790  58.9705  'BilliaC_NS'
 -2.8250  59.1500  'FallWarnes'
 -3.1000  58.7120  'PentlandF '
 -3.1350  58.6600  'InnerSound'
"
#
# Time zone of study area
#
export TZONE=0
#
# Forecast dates (start, end)
#
export TODAY=$(date -u +%Y%m%d)
export DAY_STR=$(date -u +%Y%m%d --date='1 day ago')
export DAY_END=$(date -u +%Y%m%d --date='4 day')

export DINI=$(date -u +%Y-%m-%d --date='1 day ago')
export DFIN=$(date -u +%Y-%m-%d --date='4 day')
#
# GFS cycle used for the forecast and last forecast hour
#
export GFS_CYCLE=00
export FHMAX=$(( ( $(date -u -d $DAY_END +%s) - $(date -u -d $TODAY +%s) ) / 3600 ))
#
# Copernicus Marine (NWSHELF_ANALYSISFORECAST_PHY_004_013, 1.5 km, tides)
# Credentials: run "copernicusmarine login" once on this machine, or
# export COPERNICUSMARINE_SERVICE_USERNAME / _PASSWORD in the crontab.
#
export CMEMS_CUR_ID=cmems_mod_nws_phy-cur_anfc_1.5km-2D_PT1H-i
export CMEMS_SSH_ID=cmems_mod_nws_phy-ssh_anfc_1.5km-2D_PT1H-i
export CMEMS_UVAR=uo
export CMEMS_VVAR=vo
export CMEMS_ZVAR=zos
#
# Boundary spectra from a parent grid (e.g. North Atlantic run):
# nest.ww3 written by the parent with output boundary points
# from ${WW3_config}_obc_lonlat.txt
#
export NESTFILE=$WW3DIR/NAtlantic/nest_Orkney.ww3
#
# output parameters (interval [s])
#
export OUTINT=3600      # fields
export PNTINT=3600      # spectra at points
export PLOTINT=6        # hours between maps
#
# Schedule parameters
#
export GRID=1
   export PLOTGRID=1
export INITIAL=0
export RESTART=0
export FORCING=0
  export GET_GFS=0
   export DOWNLOADGFS=0
  export CURRENTS=0
   export GET_CMEMS=0
    export DOWNLOADCMEMS=0
export LEVELS=0
export NEST=0
export RUN=0
  #export EXEC="mpirun -np 4"
  export EXEC=
export OUT=0
export OUTPNT=0
export PLOTOUT=0
export CLEAN=0
#
#===========================================================
#              END USER DEFINED PARAMETERS
#===========================================================
#
cd $RUNDIR
mkdir -p $OUTDIR $RESTDIR $ARCHDIR
#
# Output point list (used by the grid, ww3_shel and the plots)
#
echo "$POINTS" | sed -e '/^ *$/d' > points.list
#
# Time step setting for each scheme
#
if [ $UG_SCHEME = IMPLICIT ] ; then
  DTMAX=600. ; DTXY=600. ; DTKTH=600. ; DTMIN=30.
  UNST_NML="EXPFSN = F, IMPTOTAL = T, IMPREFRACTION = T, IMPFREQSHIFT = T, IMPSOURCE = T, JGS_USE_JACOBI = T, JGS_TERMINATE_DIFFERENCE = T, JGS_DIFF_THR = 1.E-6, JGS_MAXITER = 200"
else
  DTMAX=600. ; DTXY=300. ; DTKTH=300. ; DTMIN=15.
  UNST_NML="EXPFSN = T"
fi
#
# Run ww3_grid
# ------------
#
if [ $GRID = 1 ] ; then
#
# run create_grid_gmsh.py
#
  echo "... preparing grid "
  echo "... creating unstructured grid with gmsh"
  $PYTHON $TOOLSDIR/create_grid_gmsh.py > create_grid_gmsh.out 2>&1 || \
     { echo "ERROR in create_grid_gmsh.py (see create_grid_gmsh.out)" ; exit 1 ; }
#
# creating ww3_grid.inp
#
  echo "... making grid "
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_grid.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Grid preprocessor input file                           $
$ -------------------------------------------------------------------- $
$
  $WW3_title
$
$ Frequency increment factor, first frequency (Hz), number of
$ frequencies (wavenumbers) and directions, relative offset of
$ first direction in terms of the directional increment
$
  1.1  0.0373  32  36  0.
$
$ Flags: dry run, x-y propagation, refraction, k-shift (currents),
$        source terms
$
   F T T T T T
$
$ Time steps: global, CFL x-y, CFL k-theta, minimum source time step
$
   $DTMAX $DTXY $DTKTH $DTMIN
$
&UNST UGOBCAUTO = F, UGOBCDEPTH = -10., $UNST_NML /
END OF NAMELISTS
$
$ Define grid -------------------------------------------------------- $
$
  'UNST' T 'NONE'
$
$ ZLIM DMIN unit scale IDLA IDFM format FROM filename (depth in .msh)
$
  -0.1 $DMIN 20 -1. 4 1 '(....)' 'NAME' '$WW3_config.msh'
$
  10 3 1 '(....)' 'PART' 'mapsta.inp'
$
$ Input boundary points (open boundary nodes from create_grid_gmsh.py)
$
EOF
cat $WW3_config.obc >> ./ww3_grid.inp.exp
cat << EOF | sed -e 's/#.*//; s/  *$//' >> ./ww3_grid.inp.exp
      0   0   F
$
$ Excluded points
$
      0   0   F
      0   0
$
$ Output boundary points
$
     0.    0.    0.    0.       0
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ww3_grid.inp.exp ww3_grid.inp
  $RM -f mod_def.ww3
  ww3_grid > ww3_grid.out 2>&1
  if [ ! -s mod_def.ww3 ] ; then
    echo "ERROR in ww3_grid (see ww3_grid.out)" ; tail -5 ww3_grid.out ; exit 1
  fi
  $CP mod_def.ww3 mod_def.input
fi
if [ ! -s mod_def.input ] ; then
  echo "ERROR: mod_def.input not found, run once with GRID=1" ; exit 1
fi
$CP mod_def.input mod_def.ww3
#
# Restart files
# -------------
# use the restart file written by the previous forecast at 00 UTC
# of its own day (= DAY_STR of this forecast)
#
if [ $RESTART = 1 ] ; then
  if [ -s $RESTDIR/restart_${DAY_STR}.ww3 ] ; then
    echo "... copying restart file restart_${DAY_STR}.ww3"
    $CP $RESTDIR/restart_${DAY_STR}.ww3 restart.ww3
    INITIAL=0
  else
    echo "... no restart file for $DAY_STR: starting from calm"
  fi
fi
#
# Run ww3_strt
# ------------
# File preparation:
# Using all zero as IC
if [ $INITIAL = 1 ] ; then
  echo "... making initial"
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_strt.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Initial conditions input file                          $
$ -------------------------------------------------------------------- $
$ ITYPE (5 = starting from calm conditions)
    5
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
 $MV ww3_strt.inp.exp ww3_strt.inp
  ww3_strt > ww3_strt.out
fi
#
# Run ww3_prnc (winds)
# --------------------
# ww3_prnc does the preprocessing of the netCDF forcing data
# created by make_GFS_WW3.py
#
WNDFLAG=F
if [ $FORCING = 1 ] ; then
# Run make_GFS_WW3.py
# -------------------
#
  echo "... making wind forcing file"
if [ $GET_GFS = 1 ] ; then
  cd $RUNDIR

 if [ $DOWNLOADGFS = 1 ] ; then
  $RM -f wind.nc GFS/*.grib2
  echo "Downloading GFS files"
  GLON0=$(echo "$LLLON" | awk '{x=$1-0.5; if (x<0) x+=360; print x}')
  GLON1=$(echo "$URLON" | awk '{x=$1+0.5; if (x<0) x+=360; print x}')
  GLAT0=$(echo "$LLLAT" | awk '{print $1-0.5}')
  GLAT1=$(echo "$URLAT" | awk '{print $1+0.5}')
  sed -e 's/LLLAT/'"$GLAT0"'/' -e 's/LLLON/'"$GLON0"'/' -e 's/URLAT/'"$GLAT1"'/' -e 's/URLON/'"$GLON1"'/' \
      -e 's/DAYSTR/'"$DAY_STR"'/' -e 's/TODAY/'"$TODAY"'/' -e 's/CYC/'"$GFS_CYCLE"'/' -e 's/FHMAX/'"$FHMAX"'/' \
      < $TOOLSDIR/trae_gen.csh > trae_WWW_GFS.sh
  chmod u+x ./trae_WWW_GFS.sh
 ./trae_WWW_GFS.sh > trae_WWW_GFS.out 2>&1
 fi
 $PYTHON $TOOLSDIR/make_GFS_WW3.py > make_GFS_WW3.out 2>&1 || \
    { echo "ERROR in make_GFS_WW3.py (see make_GFS_WW3.out)" ; exit 1 ; }
fi
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_prnc.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Field preprocessor input file                          $
$ -------------------------------------------------------------------- $
$ Mayor types of field and time flag
$
   'WND' 'LL' T T
$
$ Name of dimensions
$
   longitude latitude
$
$ Variables to use
$
   u10 v10
$
$ Define data files
$
   'wind.nc'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ./ww3_prnc.inp.exp ./ww3_prnc.inp
  ww3_prnc > ww3_prnc_wnd.out
  [ -s wind.ww3 ] && WNDFLAG=T
fi
#
# Copernicus Marine currents and sea level
# ----------------------------------------
# hourly forecast downloaded with the Copernicus Marine Toolbox
# and converted by make_CMEMS_WW3.py
#
CURFLAG=F
LEVFLAG=F
if [ $CURRENTS = 1 ] || [ $LEVELS = 1 ] ; then
  cd $RUNDIR
if [ $GET_CMEMS = 1 ] ; then
 CLON0=$(echo "$LLLON" | awk '{print $1-0.1}')
 CLON1=$(echo "$URLON" | awk '{print $1+0.1}')
 CLAT0=$(echo "$LLLAT" | awk '{print $1-0.1}')
 CLAT1=$(echo "$URLAT" | awk '{print $1+0.1}')
 if [ $DOWNLOADCMEMS = 1 ] ; then
  if [ $CURRENTS = 1 ] ; then
   echo "Downloading Copernicus Marine hourly currents"
   $RM -f CMEMS_cur.nc
   $CMEMS subset --dataset-id $CMEMS_CUR_ID \
     --variable $CMEMS_UVAR --variable $CMEMS_VVAR \
     --minimum-longitude $CLON0 --maximum-longitude $CLON1 \
     --minimum-latitude $CLAT0 --maximum-latitude $CLAT1 \
     --start-datetime ${DINI}T00:00:00 --end-datetime ${DFIN}T00:00:00 \
     --output-directory $RUNDIR --output-filename CMEMS_cur.nc \
     --overwrite > cmems_cur.out 2>&1
  fi
  if [ $LEVELS = 1 ] ; then
   echo "Downloading Copernicus Marine hourly sea level"
   $RM -f CMEMS_ssh.nc
   $CMEMS subset --dataset-id $CMEMS_SSH_ID \
     --variable $CMEMS_ZVAR \
     --minimum-longitude $CLON0 --maximum-longitude $CLON1 \
     --minimum-latitude $CLAT0 --maximum-latitude $CLAT1 \
     --start-datetime ${DINI}T00:00:00 --end-datetime ${DFIN}T00:00:00 \
     --output-directory $RUNDIR --output-filename CMEMS_ssh.nc \
     --overwrite > cmems_ssh.out 2>&1
  fi
 fi
 WHAT=""
 [ $CURRENTS = 1 ] && [ -s CMEMS_cur.nc ] && WHAT="$WHAT cur"
 [ $LEVELS = 1 ]   && [ -s CMEMS_ssh.nc ] && WHAT="$WHAT lev"
 [ -n "$WHAT" ] && $PYTHON $TOOLSDIR/make_CMEMS_WW3.py $WHAT > make_CMEMS_WW3.out 2>&1
fi
if [ $CURRENTS = 1 ] && [ -s current.nc ] ; then
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_prnc.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Field preprocessor input file                          $
$ -------------------------------------------------------------------- $
   'CUR' 'LL' T T
$
   longitude latitude
$
   ucur vcur
$
   'current.nc'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ./ww3_prnc.inp.exp ./ww3_prnc.inp
  ww3_prnc > ww3_prnc_cur.out
  [ -s current.ww3 ] && CURFLAG=T
fi
if [ $LEVELS = 1 ] && [ -s level.nc ] ; then
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_prnc.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Field preprocessor input file                          $
$ -------------------------------------------------------------------- $
   'LEV' 'LL' T T
$
   longitude latitude
$
   wlv
$
   'level.nc'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ./ww3_prnc.inp.exp ./ww3_prnc.inp
  ww3_prnc > ww3_prnc_lev.out
  [ -s level.ww3 ] && LEVFLAG=T
fi
 [ $CURFLAG = F ] && [ $CURRENTS = 1 ] && echo "WARNING: running without currents"
 [ $LEVFLAG = F ] && [ $LEVELS = 1 ]   && echo "WARNING: running without water levels"
fi
#
# Boundary spectra from the parent grid
# -------------------------------------
#
if [ $NEST = 1 ] ; then
  if [ -s $NESTFILE ] ; then
    echo "... copying boundary spectra nest.ww3"
    $CP $NESTFILE nest.ww3
  else
    echo "WARNING: $NESTFILE not found, open boundaries without incoming spectra"
  fi
fi
#
# Run ww3_shel
# -------------
# note: if "source points cannot be found" error occurs
# check the open boundary nodes of the child grid against the
# output boundary points of the parent grid.
#
if [ $RUN = 1 ] ; then
  echo "... running WW3"
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_shel.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III shell input file                                       $
$ -------------------------------------------------------------------- $
$
   $LEVFLAG F     Water levels
   $CURFLAG F     Currents
   $WNDFLAG F     Winds
   F       Ice concentrations
   F       Assimilation data : Mean parameters
   F       Assimilation data : 1-D spectra
   F       Assimilation data : 2-D spectra.
$
$ Time frame of calculations ----------------------------------------- $
$
   $DAY_STR 000000
   $DAY_END 000000
$
$ Define output data ------------------------------------------------- $
$
   1
$
$ Type 1 : Fields of mean wave parameters
$
   $DAY_STR 000000   $OUTINT  $DAY_END 000000
   N
   DPT CUR WND WLV HS T02 T0M1 FP DIR SPR DP PHS PTP PDIR
$
$ Type 2 : Point output
$
   $DAY_STR 000000   $PNTINT  $DAY_END 000000
$
EOF
awk '{printf "   %9.4f %9.4f  %c%-10s%c\n", $1, $2, 39, substr($3,2,length($3)-2), 39}' points.list \
    >> ./ww3_shel.inp.exp
cat << EOF | sed -e 's/#.*//; s/  *$//' >> ./ww3_shel.inp.exp
$
     0.0   0.0  'STOPSTRING'
$
$ Type 3 : Output along  track.
$
   $DAY_STR 000000      0  $DAY_END 000000
$
$ Type 4 : Restart files (start of the next forecast)
$
   $TODAY 000000  86400  $TODAY 000000
$
$ Type 5 : Boundary data
$
   $DAY_STR 000000      0  $DAY_END 000000
$
$ Type 6 : Separated wave field data
$
   $DAY_STR 000000      0  $DAY_END 000000
$
$ Homogeneous field data --------------------------------------------- $
$
   'STP'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
 $MV ww3_shel.inp.exp ww3_shel.inp
date
 $EXEC ww3_shel > ww3_shel.out
date
 RST=$(ls -t restart0*.ww3 2>/dev/null | head -1)
 [ -n "$RST" ] && $MV $RST $RESTDIR/restart_${TODAY}.ww3
 find $RESTDIR -name 'restart_*.ww3' -mtime +7 -exec $RM -f {} \;
fi
#
# Run ww3_ounf
# ------------
# ww3_ounf creates netCDF output files for selected variables
#
NTOUT=$(( ( $(date -u -d $DAY_END +%s) - $(date -u -d $DAY_STR +%s) ) / $OUTINT + 1 ))
NTPNT=$(( ( $(date -u -d $DAY_END +%s) - $(date -u -d $DAY_STR +%s) ) / $PNTINT + 1 ))
if [ $OUT = 1 ] ; then
  echo "... creating netCDF field output files"
  $RM -f $OUTDIR/ww3.??????.nc
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_ounf.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Grid output post-processing                            $
$ -------------------------------------------------------------------- $
$ Time, time increment and number of outputs
$
   $DAY_STR 000000 $OUTINT $NTOUT
$
$ Fields requested (namelist selection)
$
 N
 DPT CUR WND WLV HS T02 T0M1 FP DIR SPR DP PHS PTP PDIR
$
$ netCDF version, variable type, swell partitions, same file
$
 4 4
 0 1 2
 T
$
$ File prefix, date characters, IP range (unstructured: 1 NP 1 1)
$
 ww3.
 6
 1 1000000 1 1
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ww3_ounf.inp.exp ww3_ounf.inp
  ww3_ounf > ww3_ounf.out
  $MV ww3.??????.nc $OUTDIR/
fi
#
# Run ww3_ounp
# ------------
# spectra (ITYPE=1) and tables of mean parameters (ITYPE=2)
# at the EMEC test sites
#
if [ $OUTPNT = 1 ] ; then
  echo "... creating netCDF point output files"
  $RM -f $OUTDIR/ww3.*_spec.nc $OUTDIR/ww3.*_tab.nc
for ITYPE in 1 2 ; do
  if [ $ITYPE = 1 ] ; then OTYPE="  3  1  0" ; else OTYPE="  2" ; fi
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_ounp.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III NETCDF Point output post-processing                    $
$ -------------------------------------------------------------------- $
$ Time, time increment and number of outputs
$
   $DAY_STR 000000 $PNTINT $NTPNT
$
$ Points requested (all)
$
 -1
$
$ prefix, date characters, netCDF version, points in same file,
$ output type, global attributes, dimension order
$
 ww3.
 6
 4
 T 150
 $ITYPE
 0
 T
$
$OTYPE
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ww3_ounp.inp.exp ww3_ounp.inp
  ww3_ounp > ww3_ounp_$ITYPE.out
done
  $MV ww3.*_spec.nc ww3.*_tab.nc $OUTDIR/ 2>/dev/null
fi
#
# Run plot_forecast_WW3.py
# ------------------------
# Python script to plot WW3 solutions and store the maps
# in a location accessible by the web site
#
if [ $PLOTOUT = 1 ] ; then
  echo "... making figures with Python"
  $PYTHON $TOOLSDIR/plot_forecast_WW3.py > plot_forecast_WW3.out 2>&1
fi
#
# Archive and clean
#
mkdir -p $ARCHDIR/$TODAY
$CP $OUTDIR/ww3.*.nc *.inp *.out points.list $ARCHDIR/$TODAY/ 2>/dev/null
if [ $CLEAN = 1 ] ; then
 $RM -f *.inp
 $RM -f out_grd.ww3 out_pnt.ww3 wind.ww3 current.ww3 level.ww3 restart.ww3 nest.ww3
fi
echo "... WW3 forecast $TODAY done"
