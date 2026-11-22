#!/bin/bash
#======================================================================
#
#  trae_gen.csh : template to download the GFS 0.25 deg HOURLY 10 m
#  wind (UGRD, VGRD) over the forecast domain from the NOMADS grib
#  filter. ww3_forecast.sh replaces the keywords LLLAT LLLON URLAT
#  URLON (0-360), DAYSTR, TODAY, CYC and FHMAX with sed and runs the
#  resulting trae_WWW_GFS.sh. Files are written to GFS/ as
#      gfs_YYYYMMDDCC_fFFF.grib2
#  (the file keeps its old .csh name but is a bash script).
#
#  Time series:  day -1 -> cycles 00 06 12 18 of DAYSTR, f000-f005
#                forecast -> cycle CYC of TODAY, f000-fFHMAX
#
#  NOMADS blocks clients making more than ~120 requests per minute,
#  hence the pause between requests.
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
#    - HIOOS THREDDS (discontinued) replaced by NOMADS GFS 0.25 deg
#      hourly grib filter for the Orkney forecast
#
#======================================================================
URL="https://nomads.ncep.noaa.gov/cgi-bin/filter_gfs_0p25_1hr.pl"
VARS="var_UGRD=on&var_VGRD=on&lev_10_m_above_ground=on"
BOX="subregion=&toplat=URLAT&bottomlat=LLLAT&leftlon=LLLON&rightlon=URLON"
mkdir -p GFS

get_gfs () {   # $1=yyyymmdd $2=cycle $3=forecast hour
  local file=$(printf "gfs.t%sz.pgrb2.0p25.f%03d" $2 $3)
  local out=$(printf "GFS/gfs_%s%s_f%03d.grib2" $1 $2 $3)
  [ -s $out ] && return 0
  for try in 1 2 3 ; do
    wget -q -O $out "${URL}?dir=%2Fgfs.$1%2F$2%2Fatmos&file=${file}&${VARS}&${BOX}"
    if [ -s $out ] ; then sleep 1 ; return 0 ; fi
    sleep 30
  done
  rm -f $out
  echo "WARNING: could not download $file for $1"
  return 1
}
#
# Day -1 : first 6 hours of each cycle
#
for cyc in 00 06 12 18 ; do
  for fh in 0 1 2 3 4 5 ; do
    get_gfs DAYSTR $cyc $fh
  done
done
#
# Forecast : cycle CYC of today
#
for fh in $(seq 0 FHMAX) ; do
  get_gfs TODAY CYC $fh
done
echo "GFS download done: $(ls GFS/*.grib2 | wc -l) files"
