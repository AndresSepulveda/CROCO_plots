#!/bin/bash
set -e
#source ../../myenv_mypath.sh
##########################
# python
# ======
#   python version >= 3.9 & <3.12
#
# motuclient
# ==========
# 1- Use copernicusmarine client ...
#### USER INFORMATIONS ####
# Credentials are NOT kept here any more. Run once:
#     copernicusmarine login
# which stores them in ~/.copernicusmarine/.copernicusmarine-credentials,
# or export COPERNICUSMARINE_SERVICE_USERNAME / ..._PASSWORD before running.
# Leave these empty to use the stored credentials.
user=''
password=''
###
### Copernicus marine client ###
# this is the pathCMC (described on the readme file Copernicus_Marine_Toolbox_installation.md)
path_to_cmt="/home/hda_user/miniconda3/envs/croco_pyenv/bin/copernicusmarine" 
### 
YEAR_START=2024
MONTH_START=2
DAY_START=1

YEAR_END=2024
MONTH_END=3
DAY_END=1

DT_TIME=   # Value in days. Default value when empty is 1 month. 
           # If dataset is to big adjust this value. 
           # Cannot handle values bigger than a month
           # Automaticaly adjust for 1 month
#
### KIND OF DATA ###
kdata="DAILY" # DAILY, MONTHLY or HOURLY  (see the product table below)
####################
READ_GRD=1 # read croco_grid to find lon/lat min-max
#INPUT_GRD="${OCE_FILES_DIR}/croco_grd.nc"
INPUT_GRD="../../../CROCO_FILES/croco_grd.nc"
# In case you don't want to read croco_grd
# Please use -180/180 -90/90 format
lon_min="-90"
lon_max="0"
lat_min="0"
lat_max="40"
####################
OUTDIR="../../../CROCO_FILES" # where to put data
PREFIX="mercator" # prefix for raw data

DRY_RUN=0  # 1 = ask the server for the size of each request and download
           #     nothing. Useful to check the dates and the product cover
           #     the period before pulling gigabytes.

###################################################################
########## END USER CHANGES #######################################
###################################################################

if [[ -z ${path_to_cmt} ]]; then
	echo "You need to define your path_to_cmt variable ..."
	exit 12
else
    command_line=${path_to_cmt}" "
fi

# only pass --username/--password when they are set here
creds=""
[[ -n ${user} ]]     && creds="${creds} --username ${user}"
[[ -n ${password} ]] && creds="${creds} --password ${password}"

# --force-download no longer does anything in copernicusmarine v2 (it only
# prints a deprecation warning); --overwrite is what replaces it
extra="--overwrite"
[[ ${DRY_RUN} == 1 ]] && extra="${extra} --dry-run"

## cmt info
#
# DAILY and MONTHLY use the GLORYS reanalysis (GLOBAL_MULTIYEAR_PHY_001_030),
# 1/12 deg, 50 levels, 1993 onwards. These are 3D, which is what CROCO needs
# for its initial and boundary conditions.
#
# HOURLY: the reanalysis has NO hourly dataset. The hourly fields come from
# the analysis-forecast product GLOBAL_ANALYSISFORECAST_PHY_001_024, and that
# changes two things:
#   - it starts on 2022-06-01, so it cannot be used for earlier periods;
#   - cmems_mod_glo_phy_anfc_0.083deg_PT1H-m holds hourly mean SURFACE
#     fields (sea level, temperature, currents), not the water column, so
#     no depth range is requested and the result is NOT a substitute for 3D
#     boundary conditions. It is meant for surface forcing.
#
# For 3D sub-daily the finest the catalogue offers is 6-hourly, and split in
# one dataset per variable, which this script does not handle in a single
# request:
#   cmems_mod_glo_phy-cur_anfc_0.083deg_PT6H-i     (uo, vo)
#   cmems_mod_glo_phy-so_anfc_0.083deg_PT6H-i      (so)
#   cmems_mod_glo_phy-thetao_anfc_0.083deg_PT6H-i  (thetao)
#
# Hourly surface currents including wave and tidal drift (SMOC) are in
#   cmems_mod_glo_phy_anfc_merged-uv_PT1H-i        (from 2020-11-01)
# which is the one to use to force waves or drift with surface currents.
#
TSTA=""; TEND=""          # time of day appended to -t / -T
if [[ ${kdata} == "DAILY" ]]; then
    product_id_reana='cmems_mod_glo_phy_my_0.083deg_P1D-m'
    depth_opt="-z 0.493 -Z 5727.918"
    vars="zos uo vo thetao so"
elif [[ ${kdata} == "MONTHLY" ]]; then
    product_id_reana='cmems_mod_glo_phy_my_0.083deg_P1M-m'
    depth_opt="-z 0.493 -Z 5727.918"
    vars="zos uo vo thetao so"
elif [[ ${kdata} == "HOURLY" ]]; then
    product_id_reana='cmems_mod_glo_phy_anfc_0.083deg_PT1H-m'
    depth_opt=""                      # 2D dataset: asking for depths fails
    vars="zos uo vo thetao so"
    # a date alone means 00:00, which on an hourly dataset would bring back
    # the first hour of the last day only
    TSTA="T00:00:00"; TEND="T23:59:59"
else
    echo "Please specify what kind of data you want (DAILY, MONTHLY or HOURLY), exit...."; exit 1
fi
###

### vars to download ###
variables=""
for field in ${vars}; do
    variables="${variables} -v ${field} "
done
###

#### READ GRID data #####
if [[ ${READ_GRD} == 1 ]]; then
    ncap2 -O -v -s 'latmin=lat_rho.min();latmax=lat_rho.max();lonmin=lon_rho.min();lonmax=lon_rho.max()' ${INPUT_GRD} tmp.nc
    ncap2 -O -s 'where(lonmin >= 180) lonmin=lonmin-360; where(lonmax >= 180) lonmax=lonmax-360;' tmp.nc tmp.nc
    lon_min=$( ncdump -v lonmin tmp.nc  | grep "lonmin =" | cut -d ' ' -f 4)
    lat_min=$( ncdump -v latmin tmp.nc  | grep "latmin =" | cut -d ' ' -f 4)
    lon_max=$( ncdump -v lonmax tmp.nc  | grep "lonmax =" | cut -d ' ' -f 4)
    lat_max=$( ncdump -v latmax tmp.nc  | grep "latmax =" | cut -d ' ' -f 4)
    rm -f tmp.nc
    lon_min=`echo "scale=4; ${lon_min} - 1" | bc `
    lat_min=`echo "scale=4; ${lat_min} - 1" | bc `
    lon_max=`echo "scale=4; ${lon_max} + 1" | bc `
    lat_max=`echo "scale=4; ${lat_max} + 1" | bc `
    echo "Data will be download on W:${lon_min} E:${lon_max} S:${lat_min} N:${lat_max}"
fi
###

### loop ###
for YEAR in `seq ${YEAR_START} ${YEAR_END}`; do
    [[ ${YEAR} == ${YEAR_START} ]] && mstart=${MONTH_START} || mstart=1 
    [[ ${YEAR} == ${YEAR_END} ]] && mend=${MONTH_END} || mend=12
    for MONTH in `seq ${mstart} ${mend}`; do
## last day of this month, straight from date(1): leap years included
        maxendday=$( date +%d -d "$( printf '%04d-%02d-01' $YEAR $MONTH ) +1 month -1 day" )
        maxendday=$((10#${maxendday}))
        [[ $YEAR == ${YEAR_START} && $MONTH == ${MONTH_START} ]] && { dstart=${DAY_START} ;} || { dstart=1 ;}
        [[ $YEAR == ${YEAR_END} && $MONTH == ${MONTH_END} ]] && { dend=${DAY_END} ;} || { dend=$maxendday ;}
##
        if [[ ${kdata} == "MONTHLY" ]]; then
            start_date=$( printf "%04d-%02d-01" $YEAR $MONTH )
            end_date=$( date +"%Y-%m-%d" -d "${start_date} +1 month - 1 day" )
            OUTNAME="raw_${PREFIX}_Y${YEAR}M${MONTH}.nc"
            echo "${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t ${start_date}${TSTA} -T ${end_date}${TEND} ${depth_opt} ${variables} -o ${OUTDIR} -f ${OUTNAME} ${extra}"
            ${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t "${start_date}${TSTA}" -T "${end_date}${TEND}" ${depth_opt} ${variables} -o "${OUTDIR}" -f "${OUTNAME}" ${creds} ${extra}

        elif [[ ${kdata} == "DAILY" || ${kdata} == "HOURLY" ]]; then
            if [ -z "${DT_TIME}" ]; then
                # dstart/dend are already worked out above and honour
                # DAY_START, DAY_END and the length of the month. The old
                # code used $daystrt, which is never set on this branch, so
                # the day came out as 00 and date(1) rejected the result.
                start_date=$( printf "%04d-%02d-%02d" $YEAR $MONTH $dstart )
                end_date=$(   printf "%04d-%02d-%02d" $YEAR $MONTH $dend )
                OUTNAME="raw_${PREFIX}_Y${YEAR}M${MONTH}.nc"
                echo "${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t ${start_date}${TSTA} -T ${end_date}${TEND} ${depth_opt} ${variables} -o ${OUTDIR} -f ${OUTNAME} ${extra}"
                ${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t "${start_date}${TSTA}" -T "${end_date}${TEND}" ${depth_opt} ${variables} -o "${OUTDIR}" -f "${OUTNAME}" ${creds} ${extra}
            else
                for DAY in `seq ${dstart} ${DT_TIME} ${dend}`; do
                    tmpoutname="raw_${PREFIX}_Y${YEAR}M${MONTH}D${DAY}.nc"
                    start_date=$( printf "%04d-%02d-%02d" $YEAR $MONTH $DAY )
                    end_date=$( date +"%Y-%m-%d" -d "${start_date} +${DT_TIME} day - 1 day" )
                    tmpsdate=$( echo `date -d ${start_date} +"%Y%m"` )
                    tmpedate=$( echo `date -d ${end_date} +"%Y%m"` )
                    if [[ ${tmpedate} > ${tmpsdate} ]]; then
                        # compute time dist to month end
                        tmpdate=$( printf "%04d-%02d-01" $YEAR $MONTH )
                        first_date=$( date +%s -d "${tmpdate} +1 month - 1 day" )
                        second_date=$( date +%s -d "${end_date}" ) 
                        nbdays=$(( (${second_date} - ${first_date})/86400 ))
                        end_date=$( date +"%Y-%m-%d" -d "${end_date} - ${nbdays} day" )
                    fi
                    echo "${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t ${start_date}${TSTA} -T ${end_date}${TEND} ${depth_opt} ${variables} -o ${OUTDIR} -f ${tmpoutname} ${extra}"
                    ${command_line} subset -i ${product_id_reana} -x ${lon_min} -X ${lon_max} -y ${lat_min} -Y ${lat_max} -t "${start_date}${TSTA}" -T "${end_date}${TEND}" ${depth_opt} ${variables} -o "${OUTDIR}" -f "${tmpoutname}" ${creds} ${extra}
                    [[ ${DRY_RUN} == 1 ]] || ncks -O -F --mk_rec_dmn time "${OUTDIR}/${tmpoutname}" "${OUTDIR}/${tmpoutname}"
                done
                if [[ ${DRY_RUN} != 1 ]]; then
                    cd ${OUTDIR}
                    ncrcat -O raw_${PREFIX}_Y${YEAR}M${MONTH}D*.nc raw_${PREFIX}_Y${YEAR}M${MONTH}.nc
                    rm -f raw_${PREFIX}_Y${YEAR}M${MONTH}D*.nc
                    cd -
                fi
            fi
        fi  
    done 
done
