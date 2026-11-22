#!/bin/bash
#
# Update S. Jullien : Oct 2021
# Update : Apr. 2020
# G. Cambon : Sept. 2016
#
#set -x
#set -e
#==========================================================================================
# BEGIN USER MODIFICATIONS

# Machine you are working on (used with oce-prod, all-prod only)
# Known machines: Linux DATARMOR IRENE JEANZAY LEFTRARU
# If your machine is not already known, you can add it by creating a few files (hearder, myenv, launch) 
# in a dedicated directory under: SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/ and add a case in 
# SCRIPTS/SCRIPTS_COUPLING/myjob.sh (after l.95)
# ---------------------------------------------
MACHINE="Linux"

# General architecture when using CROCO can be one of these: 
#
#  - dev architecture: 
#    -----------------
#       - croco
#           - OCEAN
#           - AGRIF
#           - ...
#           - Run
#               - *.in
#               - *.h
#               - *.bash
#               - CROCO_FILES 
#               - ...
#       - croco_tools
#
#  - prod architecture:
#    ------------------
#       - croco
#           - OCEAN
#           - AGRIF
#           - ...
#       - croco_tools
#       - CONFIGS
#           - BENGUELA
#               - PREPRO
#               - CROCO_IN
#                   - *.in
#                   - *.h
#                   - ...
#               - CROCO_FILES
#               - SCRATCH
#               - *.bash
#               - ...
#
# Define the paths for your architecture and your dev or prod choice
# ------------------------------------------------------------------

# croco source directory
# ---------------------
CROCO_DIR=$HOME/CPL/croco

# croco_tools directory 
# ---------------------
TOOLS_DIR=$HOME/CPL/croco_tools

# croco_pytools directory 
# ---------------------
PYTOOLS_DIR=${HOME}/CPL/croco_pytools

# Configuration name
# ------------------
MY_CONFIG_NAME=test

# Home and Work configuration directories
# ---------------------------------------
MY_CONFIG_HOME=$HOME/CONFIGS
MY_CONFIG_WORK=$HOME/CONFIGS

# Options of your configuration
# ------------------------------
## default option : all-dev for the usual ("all-in") architecture, for forced croco run and/or dev.
options=( all-prod-cpl )

## example for production run architecture
#options=( all-prod )

## example for production run architecture and coupling with external models:
#options=( all-prod-cpl )

## examples for specified options:
#options=( oce-prod agrif pytools inter )
#options=( oce-prod test_cases )
#options=( oce-prod agrif mattools pytools cpl wav atm toy )

# List of known options: 
LIST_OPTIONS=$(cat << EOF

 # -- CROCO built-in codes -- #
 oce-dev    : croco all-in (classic) architecture
 oce-prod   : croco production architecture => croco files and namelists in CROCO_IN directory
 pisces     : pisces inputs
 agrif      : inputs for nests
 sediment   : inputs for sediment 
 mustang    : mustang model
 xios       : xios server and xml files

 # -- CROCO built-in scripts and toolboxes -- # 
 mattools   : for getting matlab scripts for CROCO preprocessing
 pytools    : for getting python scripts for CROCO preprocessing
 inter      : for running interannual runs           ( cpl cannot be defined) 
 forc       : for using forecast scripts
 test_cases : for running test cases
 runcpl     : scripts for running interannual runs compatible with coupling
 cpl        : scripts for coupling with OASIS        ( oce-prod needed )
 toy        : scripts for coupling with a toy model  ( oce-prod needed )
 atm        : scripts for coupling with WRF          ( oce-prod needed )
 wav        : scripts for coupling with WW3          ( oce-prod needed )

 # -- All options :
 # all-dev      => equivalent to a (oce-dev  xios test_cases agrif inter forc pisces sediment mustang oanalysis mattools pytools)
 # all-prod     => equivalent to a (oce-prod xios test_cases agrif inter forc pisces sediment mustang oanalysis mattools pytools)
 # all-prod-cpl => equivalent to a (oce-prod xios test_cases agrif runcpl pisces sediment mustang oanalysis mattools pytools cpl wav atm toy)

EOF
	    )

# END USER MODIFICATIONS
#==========================================================================================

allmodels_incroco_dev=( oce-dev xios test_cases agrif inter forc pisces sediment mustang oanalysis mattools pytools )
allmodels_incroco_prod=( oce-prod xios test_cases agrif inter forc pisces sediment mustang oanalysis mattools pytools )
allmodels_cpl=( oce-prod xios test_cases agrif runcpl pisces sediment mustang oanalysis mattools pytools cpl wav atm toy )

x_f=0

while getopts :hfd:w:s:t:n:o: V
do
  case $V in
    ('h') cat << EOF

Script to setup your own configuration:

  - Create a configuration directory
  - Copy useful croco files in this directory depending on your chosen options
    
    Usage:

  - Use the command line:
    ./create_config.bash -d MY_CONFIG_HOME -w MY_CONFIG_WORK -n MY_CONFIG_NAME -s CROCO_DIR -t TOOLS_DIR -o OPTS

  - OR edit the USER SECTION of the script to define the following variables :

     - CROCO_DIR       : location of  croco sources directory
     - TOOLS_DIR       : location of  croco_tools directory
     - MY_CONFIG_NAME  : name of the configuration
     - MY_CONFIG_HOME  : location of the repository to store the configuration
     - MY_CONFIG_WORK  : location of the repository to store the configuration large input files, and where it will be run
     - OPTS            : options for your configuration, comma separated (-o OPT1,OPT2,OPT3 ...), with keywords in :
$LIST_OPTIONS  

EOF
    exit 0;;
    ('f')  x_f=1;;
    ('d')  x_d=${OPTARG};;
    ('w')  x_w=${OPTARG};;
    ('s')  x_s=${OPTARG};;
    ('t')  x_t=${OPTARG};;
    ('n')  x_n=${OPTARG};;
    ('o')  x_o=${OPTARG/,/ };;
  esac
done
#shift $(($OPTIND-1));

CROCO_DIR="${x_s-$CROCO_DIR}"
TOOLS_DIR="${x_t-$TOOLS_DIR}"
MY_CONFIG_NAME=${x_n-$MY_CONFIG_NAME}
MY_CONFIG_HOME=${x_d-$MY_CONFIG_HOME}/${MY_CONFIG_NAME}
MY_CONFIG_WORK=${x_w-$MY_CONFIG_WORK}/${MY_CONFIG_NAME}
options=( ${x_o[@]-${options[@]}} )

if [ "$options" == "all-dev" ]; then
    options=${allmodels_incroco_dev[@]}
elif [ "$options" == "all-prod" ]; then
    options=${allmodels_incroco_prod[@]}
fi
if [ "$options" == "all-prod-cpl" ]; then
    options=${allmodels_cpl[@]}
fi

# some check
if [[ ${options[@]} =~ "oce-dev" ]] ; then
    echo "oce-dev is defined. all-in architecture and no external codes considered"
elif [[ ${options[@]} =~ "oce-prod" ]] ; then
    echo "oce-prod is defined. architecture for production and/or coupled run"
fi

echo ""
echo "Your choices :"
echo " - CROCO_DIR        : ${CROCO_DIR}"
echo " - TOOLS_DIR        : ${TOOLS_DIR}"
echo " - PYTOOLS_DIR      : ${PYTOOLS_DIR}"
echo " - CONFIG_HOME_DIR  : ${MY_CONFIG_HOME%$MY_CONFIG_NAME}"
echo " - CONFIG_WORK_DIR  : ${MY_CONFIG_WORK%$MY_CONFIG_NAME}"
echo " - CONFIG_NAME      : ${MY_CONFIG_NAME}"
echo " - OPTIONS          : ${options[@]}"

if [ $x_f -eq 0 ]; then
echo -n " Do you want to proceed ? [Y/n] "
read answer
answer=`echo $answer | sed 's/^[yY].*$/y/'`
if [  -z "$answer" -o "x$answer" = "xy" ]; then
      echo " Creating configuration ..."
      echo "  "
   else
      echo " Exiting..."
      echo "  "
      exit
fi
unset -v answer
fi

# Check if source are there
if [ ! -d ${CROCO_DIR} ]; then 
	echo 'Directory for croco not found ...'
	echo 'Check the CROCO_DIR variable ...'
	echo 'Exiting ...'
   exit 1
fi

# Check if tools are there
copy_tools=1
if [[ ! -d "$TOOLS_DIR" && $x_f -eq 0 ]]; then
    echo "WARNING: croco_tools directory not found."
    echo -n "Do you want to proceed without MATLAB tools? [Y/n] "
    read -r answer
    case "$answer" in
        [nN]*) 
        echo "Exiting..."
        exit 1
        ;;
        *) 
        echo "Creating configuration ..."
        echo "Proceeding without MATLAB tools ..."
        echo "  "
        copy_tools=0
        ;;
    esac
fi

# Check if pytools are there
copy_pytools=1
if [[ ! -d "$PYTOOLS_DIR" && $x_f -eq 0 ]]; then
    echo "WARNING: croco_pytools directory not found."
    echo -n "Do you want to proceed without PYTHON tools? [Y/n] "
    read -r answer
    case "$answer" in
        [nN]*) 
        echo "Exiting..."
        exit 1
        ;;
        *) 
        echo "Creating configuration ..."
        echo "Proceeding without PYTHON tools ..."
        echo "  "
        copy_pytools=0
        ;;
    esac
fi
 
# Create the directory
if [ ! -d $MY_CONFIG_HOME ]; then 
    mkdir -p $MY_CONFIG_HOME
else
    if [[ $x_f -eq 0 ]]; then
        echo 'Already a configuration exists ...'
        echo 'You should check the configuration directory ' $MY_CONFIG_HOME
        echo -n " Do you want to proceed anyway (risk of overwriting) ? [N/y] "
        read answer
        answer=`echo $answer | sed 's/^[nN].*$/n/'`
        if [  -z "$answer" -o "x$answer" = "xn" ]; then
            echo " Exiting..."
            echo "  "
            exit
        else
            echo " Proceed..."
            echo "  "
        fi
    fi
fi

if [ "$MY_CONFIG_WORK" != "$MY_CONFIG_HOME" ]; then
    if [ ! -d $MY_CONFIG_WORK ]; then
        mkdir -p $MY_CONFIG_WORK
    else
        echo 'Already a configuration exists ...'
        echo 'You chould check the configuration directory ' $MY_CONFIG_WORK
        echo -n " Do you want to proceed anyway (risk of overwriting) ? [N/y] "
        read answer
        answer=`echo $answer | sed 's/^[nN].*$/n/'`
        if [  -z "$answer" -o "x$answer" = "xn" ]; then
            echo " Exiting..."
            echo "  "
            exit
        else
            echo " Proceed..."
            echo "  "
        fi
    fi
fi

cp $0 $MY_CONFIG_HOME/create_config.bash.bck

if [[ ${options[@]} =~ "oce-dev" ]] || [[ ${options[@]} =~ "oce-prod" ]] ; then
    echo 'Copy CROCO useful scripts and input files'
    echo '-----------------------------------------'
    # CROCO general
    if [[ ${options[@]} =~ "oce-prod" ]] ; then
	# Create directories
	mkdir -p $MY_CONFIG_HOME/CROCO_IN
	mkdir -p $MY_CONFIG_WORK/CROCO_FILES
	mkdir -p $MY_CONFIG_WORK/DATA
	MY_CROCO_DIR=$MY_CONFIG_HOME/CROCO_IN/
        MY_PREPRO_DIR=$MY_CONFIG_HOME/PREPRO/CROCO/
	MY_XIOS_DIR=$MY_CONFIG_HOME/XIOS_IN/
	
    elif [[ ${options[@]} =~ "oce-dev" ]] ; then
	# Create directories
	mkdir -p $MY_CONFIG_HOME
	mkdir -p $MY_CONFIG_WORK/CROCO_FILES
	mkdir -p $MY_CONFIG_WORK/DATA
	MY_CROCO_DIR=$MY_CONFIG_HOME/
        MY_PREPRO_DIR=$MY_CONFIG_HOME/
	MY_XIOS_DIR=$MY_CONFIG_HOME/
    fi
    cp -f ${CROCO_DIR}/OCEAN/cppdefs.h $MY_CROCO_DIR.
    cp -f ${CROCO_DIR}/OCEAN/cppdefs_dev.h $MY_CROCO_DIR.
    cp -f ${CROCO_DIR}/OCEAN/param.h $MY_CROCO_DIR.
    
    PAT=$(grep ^SOURCE1 ${CROCO_DIR}/OCEAN/jobcomp)
    sed -e "s!${PAT}!SOURCE1=${CROCO_DIR}/OCEAN!g" $CROCO_DIR/OCEAN/jobcomp > $MY_CROCO_DIR/jobcomp
    chmod +x $MY_CROCO_DIR/jobcomp

    if [[ ${options[@]} =~ "runcpl" ]]; then
        cp -r ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/CROCO_IN/* $MY_CROCO_DIR.        
    else
        cp -f ${CROCO_DIR}/OCEAN/croco.in $MY_CROCO_DIR.
    fi
    cp -f ${CROCO_DIR}/OCEAN/croco_stations.in $MY_CROCO_DIR.
    # TEST_CASES
    if [[ ${options[@]} =~ "test_cases" ]] ; then
	cp -Rf ${CROCO_DIR}/TEST_CASES $MY_CROCO_DIR.
    fi
    # AGRIF
    if [[ ${options[@]} =~ "agrif" ]] ; then
	cp -f ${CROCO_DIR}/OCEAN/croco.in.1 $MY_CROCO_DIR.
	cp -f ${CROCO_DIR}/OCEAN/AGRIF_FixedGrids.in $MY_CROCO_DIR.
    fi
    # INTER
    if [[ ${options[@]} =~ "inter" ]] ; then
	cp -f ${CROCO_DIR}/OCEAN/croco_inter.in* $MY_CROCO_DIR.
    fi
    # FORECAST
    if [[ ${options[@]} =~ "forc" ]] ; then
	cp -f ${CROCO_DIR}/OCEAN/croco_forecast.in $MY_CROCO_DIR.
    fi
    # PISCES
    if [[ ${options[@]} =~ "pisces" ]] ; then
	cp -f ${CROCO_DIR}/PISCES/*namelist* $MY_CROCO_DIR.
	cp -f ${CROCO_DIR}/PISCES/SED/*namelist* $MY_CROCO_DIR.
    fi
    # SEDIMENT
    if [[ ${options[@]} =~ "sediment" ]] ; then
	cp -f ${CROCO_DIR}/OCEAN/sediment.in $MY_CROCO_DIR.
    fi
    # MUSTANG
    if [[ ${options[@]} =~ "mustang" ]] ; then
	mkdir -p $MY_CROCO_DIR/MUSTANG_NAMELIST
	cp -f ${CROCO_DIR}/MUSTANG/MUSTANG_NAMELIST/*txt $MY_CROCO_DIR/MUSTANG_NAMELIST/.
    fi
    # OANALYSIS
    if [[ ${options[@]} =~ "oanalysis" ]] ; then
	cp -Rf ${CROCO_DIR}/SCRIPTS/NAMELIST_OANALYSIS $MY_CROCO_DIR.
    fi
    # XIOS
    if [[ ${options[@]} =~ "xios" ]] ; then
	cp -Rf ${CROCO_DIR}/XIOS/process_xios_xml.sh $MY_CROCO_DIR.
	#     cp -Rf ${CROCO_DIR}/XIOS/xios_launch.file $MY_CROCO_DIR.
	#     cp -Rf ${CROCO_DIR}/XIOS/README_XIOS $MY_CROCO_DIR.
    fi
    # PREPROCESSING
    if [[ ${options[@]} =~ "mattools" && ${copy_tools} == 1 ]] ; then
        mkdir -p $MY_PREPRO_DIR/croco_tools
	cp -Rf $TOOLS_DIR/start.m $MY_PREPRO_DIR/croco_tools/.
	cp -Rf $TOOLS_DIR/oct_start.m $MY_PREPRO_DIR/croco_tools/.
	cp -Rf $TOOLS_DIR/crocotools_param.m $MY_PREPRO_DIR/croco_tools/.
	cp -Rf $TOOLS_DIR/Town/town.dat $MY_PREPRO_DIR/croco_tools/.
	cp -Rf $TOOLS_DIR/Oforc_OGCM/download_glorys_data.sh $MY_PREPRO_DIR/croco_tools/.
	# Edit start.m
	sed -e "s|tools_path=.*|tools_path=\'${TOOLS_DIR}/\';|g" \
            -e "s|croco_path=.*|croco_path=\'${CROCO_DIR}/\';|g" \
            $MY_PREPRO_DIR/croco_tools/start.m > $MY_PREPRO_DIR/croco_tools/start.m.tmp
	mv $MY_PREPRO_DIR/croco_tools/start.m.tmp $MY_PREPRO_DIR/croco_tools/start.m
	# Edit oct_start.m
	sed -e "s|tools_path=.*|tools_path=\'${TOOLS_DIR}/\';|g" \
            -e "s|croco_path=.*|croco_path=\'${CROCO_DIR}/\';|g" \
            $MY_PREPRO_DIR/croco_tools/oct_start.m > $MY_PREPRO_DIR/croco_tools/oct_start.m.tmp
	mv $MY_PREPRO_DIR/croco_tools/oct_start.m.tmp $MY_PREPRO_DIR/croco_tools/oct_start.m
	# Edit crocotools_param.h
	sed -e "s|CROCOTOOLS_dir = .*|CROCOTOOLS_dir = \'${TOOLS_DIR}/\';|g" \
            -e "s|RUN_dir=.*|RUN_dir=\'${MY_CONFIG_WORK}/\';|g" \
            -e "s|DATADIR=.*|DATADIR=\'${TOOLS_DIR}/DATASETS_CROCOTOOLS/\';|g" \
            $MY_PREPRO_DIR/croco_tools/crocotools_param.m > $MY_PREPRO_DIR/croco_tools/crocotools_param.m.tmp
	mv $MY_PREPRO_DIR/croco_tools/crocotools_param.m.tmp $MY_PREPRO_DIR/croco_tools/crocotools_param.m
    fi
    if [[ ${options[@]} =~ "pytools" && ${copy_pytools} == 1 ]] ; then
        mkdir -p $MY_PREPRO_DIR
        cp -Rf $PYTOOLS_DIR $MY_PREPRO_DIR.
    fi
    # SCRIPTS FOR RUNNING
    if [[ ${options[@]} =~ "inter" ]] ; then
	cp -Rf ${CROCO_DIR}/SCRIPTS/Plurimonths_scripts/*.bash $MY_CONFIG_HOME/
        cp -Rf ${CROCO_DIR}/SCRIPTS/example_job* $MY_CONFIG_HOME/
    fi
fi

### Preprocessing scripts
if [[ ${options[@]} =~ "mattools" && ${options[@]} =~ "cpl" ]] ; then
    if [[ ${copy_tools} == 1 ]] ; then
        cp -r $TOOLS_DIR/Coupling_tools/CROCO/* $MY_CONFIG_HOME/PREPRO/CROCO/croco_tools/.
    fi
fi

# OASIS
if [[ ${options[@]} =~ "cpl" ]] ; then
    echo 'Copy OASIS useful scripts and input files'
    echo '-----------------------------------------'
    mkdir -p $MY_CONFIG_HOME/OASIS_IN
    mkdir -p $MY_CONFIG_WORK/OASIS_FILES
    cp -r ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/OASIS_IN/* $MY_CONFIG_HOME/OASIS_IN/.
fi

# WW3
if [[ ${options[@]} =~ "wav" ]] ; then
    echo 'Copy WW3 useful scripts and input files'
    echo '-----------------------------------------'
    mkdir -p $MY_CONFIG_HOME/WW3_IN
    mkdir -p $MY_CONFIG_WORK/WW3_FILES
    cp -r ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/WW3_IN/* $MY_CONFIG_HOME/WW3_IN/.
    if [[ ${options[@]} =~ "mattools" ]] ; then
        cp -r $TOOLS_DIR/Coupling_tools/WW3 $MY_CONFIG_HOME/PREPRO/.
    fi
fi

# WRF
if [[ ${options[@]} =~ "atm" ]] ; then
    echo 'Copy WRF useful scripts and input files'
    echo '-----------------------------------------'
    mkdir -p $MY_CONFIG_HOME/WRF_IN
    mkdir -p $MY_CONFIG_WORK/WRF_FILES
    cp -r ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/WRF_IN/* $MY_CONFIG_HOME/WRF_IN/.
    if [[ ${options[@]} =~ "mattools" ]] ; then
        cp -r $TOOLS_DIR/Coupling_tools/WRF_WPS $MY_CONFIG_HOME/PREPRO/.
    fi
fi

# TOY
if [[ ${options[@]} =~ "toy" ]] ; then
    echo 'Copy TOY sources, useful scripts and input files'
    echo '------------------------------------------------'
    mkdir -p $MY_CONFIG_HOME/TOY_IN
    mkdir -p $MY_CONFIG_WORK/TOY_FILES
    cp -r ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/TOY_IN/* $MY_CONFIG_HOME/TOY_IN/.
fi

# XIOS
if [[ ${options[@]} =~ "xios" ]] ; then
    if [[ ${options[@]} =~ "oce-prod" ]]; then
        mkdir -p  $MY_CONFIG_HOME/PREPRO/XIOS
        mv $MY_CROCO_DIR/process_xios_xml.sh $MY_CONFIG_HOME/PREPRO/XIOS
        sed -e "s|XIOS_NAM_DIR=.*|\source ../../myenv_mypath.sh|g" \
            -e "s|ROOT_DIR=.*|ROOT_DIR=\${OCE}/..|g" \
            -e "s|RUNDIR=.*|RUNDIR=$( echo ${MY_CROCO_DIR%?})|g" \
            $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.sh > $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp
        chmod 755 $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp
        if [[ ${options[@]} =~ "atm" ]]; then
            sed -e "s|set -e|\set -e \n\n###### USER DEFINITION ######\nOCE_XIOS=\"TRUE\"\nATM_XIOS=\"TRUE\"\nUSE_OASIS=\"TRUE\"\n##### END USER DEFINITION #####|" \
                $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp > $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.sh
            rm -f $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp
        fi
        [[ -f $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp ]] && mv $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.tmp $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.sh
        chmod 755 $MY_CONFIG_HOME/PREPRO/XIOS/process_xios_xml.sh
    elif [[ ${options[@]} =~ "oce-dev" ]]; then
        sed -e "s|XIOS_NAM_DIR=.*|XIOS_NAM_DIR=$( echo ${MY_XIOS_DIR%?} )|g"\
            -e "s|ROOT_DIR=.*|ROOT_DIR=${CROCO_DIR}|g" \
            -e "s|RUNDIR=.*|RUNDIR=$( echo ${MY_CROCO_DIR%?})|g" \
            $MY_CROCO_DIR/process_xios_xml.sh > $MY_CROCO_DIR/process_xios_xml.tmp
        mv $MY_CROCO_DIR/process_xios_xml.tmp $MY_CROCO_DIR/process_xios_xml.sh
        chmod 755 $MY_CROCO_DIR/process_xios_xml.sh
    fi
fi

# Using the SCRIPT_TOOLBOX scripts (cpl-like architecture)
# Copy and edit the relevant scripts
#if [[ ${options[@]} =~ "cpl" ]] || [[ ${options[@]} =~ "wav" ]] || [[ ${options[@]} =~ "atm" ]] || [[ ${options[@]} =~ "toy" ]] ; then
if [[ ${options[@]} =~ "runcpl" ]] ; then
    echo 'Copy scripts production runs'
    echo '-----------------------------'
    cp -Rf ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/*.sh $MY_CONFIG_HOME/
    cp -Rf ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/README* $MY_CONFIG_HOME/
    
    # Edit myjob.sh to add CPU lines for each model
    cd $MY_CONFIG_HOME/
    [ -f myjob.tmp ] && rm -Rf myjob.tmp
    [[ ${options[@]} =~ "oce-prod" ]] && printf "export NP_OCEX=1 \nexport NP_OCEY=2 \nexport NP_OCE=2 # ONLY used if MPI_NOLAND is TRUE. It replaces NP_OCEX*NP_OCEY \n" >> myjob.tmp
    [[ ${options[@]} =~ "wav" ]] && printf "export NP_WAV=14 \n" >> myjob.tmp
    [[ ${options[@]} =~ "atm" ]] && printf "export NP_ATM=12 \n" >> myjob.tmp
    [[ ${options[@]} =~ "toy" ]] && printf "export NP_TOY=2 \n" >> myjob.tmp
    [[ ${options[@]} =~ "xios" ]] && printf "export NP_XIOS_ATM=1\nexport NP_XIOS_OCE=1\n" >> myjob.tmp
    
    if [[ ${options[@]} =~ "atm" ]] ; then
        printf "\n# additional MPI Settings for ATM (WRF)\n" >> myjob.tmp
        printf "export atm_nprocX=-1      # -1 for automatic settings\n" >> myjob.tmp
        printf "export atm_nprocY=-1      # -1 for automatic settings\n" >> myjob.tmp
        printf "export atm_niotaskpg=0    # 0 for default settings\n" >> myjob.tmp
        printf "export atm_niogp=1        # 1 for default settings\n\n" >> myjob.tmp
    fi

    sed -e "/< insert here CPU >/r myjob.tmp" \
        myjob.sh > myjob_tmp
    mv myjob_tmp myjob.sh
    chmod 755 myjob.sh
    rm -Rf myjob.tmp
    
    # Create the path file
    cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_base.sh >> tmppath

    # add sections for each model
    [[ ${options[@]} =~ "cpl" ]] && printf "export CPL=\"\${HOME}/CPL/oasis3-mct/compile_oasis3-mct_gfortran_hda\"\n" >> tmppath
    [[ ${options[@]} =~ "cpl" ]] && printf "export OASISDIR=\"\${CPL}\"   # used by the WW3 compilation (HDA)\n" >> tmppath
    [[ ${options[@]} =~ "oce-prod" ]] && printf "export OCE=\"${CROCO_DIR}/OCEAN\"\n" >> tmppath
    [[ ${options[@]} =~ "atm" ]] && printf "export ATM=\"\${HOME}/CPL/WRF\"\n" >> tmppath
    [[ ${options[@]} =~ "wav" ]] && printf "export WAV=\"\${HOME}/CPL/ww3/model\"\n" >> tmppath
    [[ ${options[@]} =~ "toy" ]] && printf "export TOY=\"\${CHOME}/TOY_IN\"\n" >> tmppath
    [[ ${options[@]} =~ "xios" ]] && printf "export XIOS=\"\${HOME}/XIOS\"\n" >> tmppath
    printf "\n" >> tmppath

    [[ ${options[@]} =~ "cpl" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_cpl.sh >> tmppath
    [[ ${options[@]} =~ "oce-prod" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_oce.sh >> tmppath
    [[ ${options[@]} =~ "atm" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_atm.sh >> tmppath
    [[ ${options[@]} =~ "wav" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_wav.sh >> tmppath
    [[ ${options[@]} =~ "toy" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_toy.sh >> tmppath
    [[ ${options[@]} =~ "xios" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/PATHS/path_xios.sh>> tmppath

    # replace environment variables in path file
    sed -e "s|export MACHINE=.*|export MACHINE=\"${MACHINE}\"|g" \
        -e "s|export CONFIG=.*|export CONFIG=${MY_CONFIG_NAME}|g" \
        -e "s|export CHOME=.*|export CHOME=${MY_CONFIG_HOME}|g" \
        -e "s|export CWORK=.*|export CWORK=${MY_CONFIG_WORK}|g" \
        -e "s|export SCRIPTDIR=.*|export SCRIPTDIR=${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX|g" \
        tmppath > tmppath1
    mv tmppath1 tmppath

    # Create the env file
    [ -d ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/${MACHINE} ] && cp ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/${MACHINE}/myenv.${MACHINE} tmpenv || { echo "No environement for ${MACHINE} in ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/${MACHINE}"; exit ;}

    [[ ${options[@]} =~ "atm" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/${MACHINE}/myenv.${MACHINE}.wrf >> tmpenv 
    [[ ${options[@]} =~ "wav" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/MACHINE/${MACHINE}/myenv.${MACHINE}.ww3 >> tmpenv

    # HDA server: clean environment, written at the top of myenv_mypath.sh
    cat > tmphda << 'EOB'
#-------------------------------------------------------------------------------
# HDA server: clean environment for the coupled system
#-------------------------------------------------------------------------------
command -v conda >/dev/null && conda deactivate 2>/dev/null
unset LD_LIBRARY_PATH                       # Delft3D paths break mpicc/mpif90
module() { :; }; export -f module           # no environment modules on this machine

EOB

    # concatenate path and env file
    cat tmphda tmpenv tmppath > myenv_mypath.sh
    chmod 755 myenv_mypath.sh
    rm -rf tmppath tmpenv tmphda

    # Create the namelist file
    cp ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_head.sh mynamelist.sh

    if [[ ${options[@]} =~ "cpl" ]]; then
        if [[ ${options[@]} =~ "oce-prod" ]] && [[ ${options[@]} =~ "wav" ]] && [[ ${options[@]} =~ "atm" ]] ; then
            sed "s/export RUNtype=.*/export RUNtype=owa/g" mynamelist.sh > mynamelist.sh.tmp
            mv mynamelist.sh.tmp mynamelist.sh
        elif [[ ${options[@]} =~ "oce-prod" ]] && [[ ${options[@]} =~ "wav" ]] ; then
            sed "s/export RUNtype=.*/export RUNtype=ow/g" mynamelist.sh > mynamelist.sh.tmp
            mv mynamelist.sh.tmp mynamelist.sh
        elif [[ ${options[@]} =~ "oce-prod" ]] && [[ ${options[@]} =~ "atm" ]]; then
            sed "s/export RUNtype=.*/export RUNtype=oa/g" mynamelist.sh > mynamelist.sh.tmp
            mv mynamelist.sh.tmp mynamelist.sh
        elif [[ ${options[@]} =~ "wav" ]] && [[ ${options[@]} =~ "atm" ]]; then
            sed "s/export RUNtype=.*/export RUNtype=aw/g" mynamelist.sh > mynamelist.sh.tmp
            mv mynamelist.sh.tmp mynamelist.sh
        else 
            sed "s/export RUNtype=.*/export RUNtype=/g" mynamelist.sh > mynamelist.sh.tmp
            mv mynamelist.sh.tmp mynamelist.sh
        fi
    else
        sed "s/export RUNtype=.*/export RUNtype=frc/g" mynamelist.sh > mynamelist.sh.tmp
        mv mynamelist.sh.tmp mynamelist.sh
    fi

    sed "s/export CEXPER=BENGUELA/export CEXPER=${MY_CONFIG_NAME}/g" mynamelist.sh > mynamelist.sh.tmp
    mv mynamelist.sh.tmp mynamelist.sh

    [[ ${options[@]} =~ "cpl" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_cpl.sh >> mynamelist.sh
    [[ ${options[@]} =~ "oce-prod" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_oce.sh >> mynamelist.sh
    [[ ${options[@]} =~ "atm" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_atm.sh >> mynamelist.sh
    [[ ${options[@]} =~ "wav" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_wav.sh >> mynamelist.sh
    [[ ${options[@]} =~ "toy" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_toy.sh >> mynamelist.sh
    [[ ${options[@]} =~ "xios" ]] && cat ${CROCO_DIR}/SCRIPTS/SCRIPTS_COUPLING/SCRIPTS_TOOLBOX/NAMELISTS/namelist_xios.sh >> mynamelist.sh

    chmod 755 mynamelist.sh

    # Edit jobcomp in CROCO_IN
    if [[ ${options[@]} =~ "oce-prod" ]]; then
        cd ${MY_CONFIG_HOME}/CROCO_IN
	sed -e 's|SOURCE1=.*|source ../myenv_mypath.sh\nSOURCE1=${OCE}|g' \
	    -e 's|FC=gfortran|FC=\${FC}|' \
	    -e 's|MPIF90=.*|MPIF90=\${MPIF90}|' \
	    jobcomp > jobcomp.tmp
	mv jobcomp.tmp jobcomp
	if [[ ${options[@]} =~ "cpl" ]]; then
	    sed -e 's|PRISM_ROOT_DIR=.*|PRISM_ROOT_DIR=\${CPL}|' \
		jobcomp > jobcomp.tmp
            mv jobcomp.tmp jobcomp
	fi
        if [[ ${options[@]} =~ "xios" ]]; then
            sed -e 's|XIOS_ROOT_DIR=.*|XIOS_ROOT_DIR=\${XIOS}|' \
                jobcomp > jobcomp.tmp
            mv jobcomp.tmp jobcomp
        fi
	chmod 755 jobcomp
    fi
    # 
    cp -f ${MY_CROCO_DIR}/cppdefs.h ${MY_CROCO_DIR}/cppdefs.h.base
    cp -f ${MY_CROCO_DIR}/param.h ${MY_CROCO_DIR}/param.h.base
fi

