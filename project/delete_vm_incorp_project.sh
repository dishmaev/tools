#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM from incorp project $COMMON_CONST_PROJECTNAME"

##private consts


##private vars
PRM_VMTEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_VMTYPE='' #vm name
PRM_SCRIPTVERSION='' #version script for create VM

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4  '<vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [vmType=$COMMON_CONST_VMWARE_VMTYPE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_VMWARE_VMTYPE $COMMON_CONST_DEFAULT_VERSION" \
"Available VM templates: $COMMON_CONST_VMTEMPLATES_POOL. Available suites: $COMMON_CONST_SUITES_POOL. Available VM types: $COMMON_CONST_VMTYPES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VMTYPE=${3:-$COMMON_CONST_VMWARE_VMTYPE}
PRM_SCRIPTVERSION=${4:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VMTEMPLATES_POOL"
checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmType' "$PRM_VMTYPE" "$COMMON_CONST_VMTYPES_POOL"
checkCommandExist 'scriptVersion' "$PRM_SCRIPTVERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body



doneFinalStage
exitOK
