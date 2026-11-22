#!/bin/bash
#=======================================================
# WW3 forecast script for a singe domain
# Patrick Marchesiello  - September 2011
#=======================================================
#
# Environment for Crontab
#
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
#
export F_UFMTENDIAN=big
ulimit -s 131072
export KMP_STACKSIZE=50m
export OMP_NUM_THREADS=4
#
PATH=$PATH:/bin:/opt/bin:/opt/opendap/bin:/opt/opendap/lib:/usr/local/bin:./
PATH=$PATH:/ocean/WW3/bin:/ocean/WW3/exe
export PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/opendap/lib
#
# Specific environment variables
#
export CP=/bin/cp
export MV=/bin/mv
export RM=/bin/rm
export OCTAVE=/usr/local/bin/octave
#
#=========================================================
# USER DEFINED PARAMETERS
#=========================================================
export WW3DIR=/ocean/WW3
export GFSDIR=$WW3DIR/Forecast_tools
export RUNDIR=/ocean/WW3/Pronostico_Chile
export OUTDIR=$RUNDIR/OUTPUT
#
# Area of interest
#
export WW3_title="'Pacific Domain 1/2 degree'"
export WW3_config=ChileForecast   # No blank spaces
#
# Domain Lower Left and Upper Rigth corners:
#
export LLLON=-130
export LLLAT=-75  
export URLON=-55
export URLAT=-15   
#
# Grid resolution [degree]
#
export DLX=0.5
export DLY=0.5
#
# Time zone of study area
#
export TZONE=0
#
# Forecast dates (start, end)
#
TODAY=$(date +%Y%m%d)
DAY_STR=$(date +%Y%m%d --date='1 day ago')
DAY_END=$(date +%Y%m%d --date='4 day')

DINI=$(date +%Y-%m-%d --date='1 day ago')
DFIN=$(date +%Y-%m-%d --date='5 day')

#
# output parameters (interval, number)
#
export OUTINT=21600
export OUTNB=24
#
# Schedule parameters
#
export GRID=0
   export PLOTGRID=0
export INITIAL=1
export RESTART=0
export FORCING=1
  export GET_GFS=1
   export DOWNLOADGFS=1
export RUN=0
  #export EXEC="mpirun -np 4"
  export EXEC=
export OUT=0
export PLOTOUT=0
export OUTGRADS=0
export PLOTGRADS=0
#
#===========================================================
#              END USER DEFINED PARAMETERS
#===========================================================
#
# Run ww3_grid
# ------------
#
if [ $GRID = 1 ] ; then
cd $RUNDIR
#
# run create_grid_regional
# 
  echo "... preparing grid "
  sed -e 's/DLY/'"$DLY"'/' -e 's/DLX/'"$DLX"'/' -e 's/LLLAT/'"$LLLAT"'/' -e 's/LLLON/'"$LLLON"'/' -e 's/URLAT/'"$URLAT"'/' -e 's/URLON/'"$URLON"'/' -e 's/WW3CONFIG/'"$WW3_config"'/' -e 's/PLOTGRID/'"$PLOTGRID"'/' < create_grid_regional_gen.m > create_grid_regional_batch.m
  echo "... creating grid files with Octave"
 $OCTAVE create_grid_regional_batch.m 
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
$ 1.1  0.035  29  24  0.5
  1.1  0.04118  25  24  0.
   F T T T F T
   1800. 900. 900. 200.
   &MISC FLAGTR = 2 /
END OF NAMELISTS
EOF
cat $WW3_config.meta >> ./ww3_grid.inp.exp
cat << EOF | sed -e 's/#.*//; s/  *$//' >> ./ww3_grid.inp.exp  
 
     0.    0.    0.    0.       0
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ww3_grid.inp.exp ww3_grid.inp
  ww3_grid > ww3_grid.out
  $CP mod_def.ww3 mod_def.input
fi
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
$ ITYPE 
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
# Restart files
# -------------
# use restart files of previous forecast (day 0)
# to initialize the new forecast (starting at day -1)
#
if [ $RESTART = 1 ] ; then
  echo "... copying restart file grd"
  $CP restart.grd restart.grd
fi
#
# Run ww3_prep
# ------------
# ww3_prep does the preprocessing of forcing data
# It reads data from ascii files created by make_GFS
# file infos are in ww3_prep.inp files
#
if [ $FORCING = 1 ] ; then
# Run make_GFS_WW3
# ------------
#
  echo "... making forcing file grd"
if [ $GET_GFS = 1 ] ; then
  cd $RUNDIR

 if [ $DOWNLOADGFS = 1 ] ; then
  rm WW3_GFS.nc
  echo "Downloading GFS files"
  sed -e 's/LLLAT/'"$LLLAT"'/' -e 's/LLLON/'"$LLLON"'/' -e 's/URLAT/'"$URLAT"'/' -e 's/URLON/'"$URLON"'/'  -e 's/DINI/'"$DINI"'/' -e 's/DFIN/'"$DFIN"'/'  < trae_gen.csh > trae_WWW_GFS.sh
  chmod u+x ./trae_WWW_GFS.sh
 ./trae_WWW_GFS.sh
 fi
##
## Remove dependency on ww3tools_param.m
##
  sed -e 's/DLX/'"$DLX"'/' -e 's/LLLAT/'"$LLLAT"'/' -e 's/LLLON/'"$LLLON"'/' -e 's/URLAT/'"$URLAT"'/' -e 's/URLON/'"$URLON"'/' -e 's/DWNLD/'"$DOWNLOADGFS"'/' < make_GFS_WW3_gen.m > make_GFS_WW3.m  
 $OCTAVE  ./make_GFS_WW3.m > make_GFS_WW3.out
fi
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_prep.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Field preprocessor input file                          $
$ -------------------------------------------------------------------- $
$ Mayor types of field and time flag
$
   'WND' 'LL' T T
$
$ Additional input format type 'LL' ---------------------------------- $
$
$  $LLLON $LLLAT length(lon) $URLON  $URLAT length(lat)
  $LLLON $LLLAT 105 $URLON  $URLAT 101
$
$
  'NAME' 1 1 '(....)' '(....)' 
  20 'GFS_WW3.ascii'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ./ww3_prep.inp.exp ./ww3_prep.inp
  ww3_prep > ww3_prep.out
#  cp -f wind.ww3 wind.input
fi
# Run ww3_shel
# -------------
# note: if "source points cannot be found" error occurs
# mask the listed source points (missing from parent grid)
# in the child grid gridgen routine.
#
if [ $RUN = 1 ] ; then
  echo "... running WW3"
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_shel.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III shell input file                                       $
$ -------------------------------------------------------------------- $
$
   F F     Water levels
   F F     Currents
   T F     Winds
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
   3600
$
$ Type 1 : Fields of mean wave parameters
$
   $DAY_STR 000000   3600  $DAY_END 000000
     T T T T T  T T T T T  T T T T T  T T T T T  T T T T T
     T T T T T  T
$
$ Type 2 : Point output
$
   $DAY_STR 000000    900  $DAY_END 000000
$
   -74.0 -37.0  'Point_1   '
$
     0.0   0.0  'STOPSTRING'
$
$ Type 3 : Output along  track.
$
   $DAY_STR 000000   3600  $DAY_END 000000
     F
$
$ Type 4 : Restart files (no additional data required).
$
   $DAY_STR 030000      3600  $DAY_END 030000
$
$ Type 5 : Boundary data (no additional data required).
$
   $DAY_STR 000000   3600  $DAY_END 000000
$
$ Type 6 : Separated wave field data (dummy for now).
$
   $DAY_STR 000000   3600  $DAY_END 000000
      0 999 1 0 999 1 T
$
$ Homogeneous field data --------------------------------------------- $
$
   'LEV' 19680606 010000    1.0
   'CUR' 19680606 073125    2.0    25.
   'WND' 19680606 000000   20.    145.    2.0
   'MOV' 19680606 013000    4.0    25.
   'STP'
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
 $MV ww3_shel.inp.exp ww3_shel.inp
date
 $EXEC ww3_shel > ww3_shel.out
 cd $RUNDIR
 mkdir $TODAY
 cp * $TODAY
date
fi
#
# Run ww3_outf
# ------------
# ww3_outf creates output files for selected variables
# dates in ww3_outf.inp files have to be changed first
#
if [ $OUT = 1 ] ; then
  echo "... creating ascii output files grd"
  $RM *hs *dir *fp *dp
  $RM $OUTDIR/GRID/* 
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./ww3_outf.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Grid output post-processing                            $
$ -------------------------------------------------------------------- $
$ Time, time increment and number of outputs
$
   $TODAY 000000 $OUTINT $OUTNB
$
$ Request flags identifying fields as in ww3_shel input
$
 F F F F F  T F F T F  T T F F F  F F F F F  F F F F F  F F F F F  F
$
$ Output type ITYPE [0,1,2,3], and IPART [ 0,...,NOSWLL ]
$
 3  2   
$ -------------------------------------------------------------------- $
$ ITYPE = 3, transfer files.
$            IX, IY range, IDLA and IDFM as in ww3_grid.inp.
$
 1 111 1 112 3 1
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV ww3_outf.inp.exp ww3_outf.inp
  ww3_outf > ww3_outf.out
  $MV ww3.*.hs $OUTDIR/GRID
  $MV ww3.*.dir $OUTDIR/GRID
  $MV ww3.*.fp $OUTDIR/GRID
  $MV ww3.*.dp $OUTDIR/GRID
fi
#
# Run plot_forecast_WW3.m
# -----------------------
# matlab script to plot WW3 solutions and store the maps
# in a location accessible by the web site
#
if [ $PLOTOUT = 1 ] ; then
  echo "... making figures with Octave"
  $OCTAVE  -batch -nodisplay < plot_forecast_WW3.m > plot_forecast_WW3.out
fi
if [ $OUTGRADS = 1 ] ; then
  echo "... creating output files for GRADS"
cat << EOF | sed -e 's/#.*//; s/  *$//' > ./gx_outf.inp.exp
$ -------------------------------------------------------------------- $
$ WAVEWATCH III Grid output post-processing                            $
$ -------------------------------------------------------------------- $
$ Time, time increment and number of outputs
$
   $DAY_STR 000000 $OUTINT $OUTNB
$
$ Request flags identifying fields as in ww3_shel input
$
 F F F F F  T F F T F  T T F F F  F F F F F  F F F F F  F F F F F  F
$ -------------------------------------------------------------------- $
$ ITYPE = 3, transfer files.
$            IX, IY range, IDLA and IDFM as in ww3_grid.inp.
$
 1 111 1 112 T T
$
$ -------------------------------------------------------------------- $
$ End of input file                                                    $
$ -------------------------------------------------------------------- $
EOF
  $MV gx_outf.inp.exp gx_outf.inp
  gx_outf > gx_outf.out
fi


 rm *.inp
 rm out_grd.ww3 out_inp.ww3 wind.ww3
