#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM on incorp project $COMMON_CONST_PROJECTNAME"

##private consts


##private vars
PRM_SUITE='' #suite
PRM_SCRIPTVERSION='' #version script for create VM
RET_VAL='' #child return value
CONFIG_FILENAME='' #vm config file name
CONFIG_FILEPATH='' #vm config file path
VM_TYPE='' #vm type
VM_TEMPLATE='' #vm template
VM_NAME='' #vm name
ESXI_HOST='' #esxi host
VM_ID='' #vm id

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[suite=$COMMON_CONST_DEVELOP_SUITE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VERSION" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_SUITE=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_SCRIPTVERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'scriptVersion' "$PRM_SCRIPTVERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

CONFIG_FILENAME=${PRM_SUITE}_${PRM_SCRIPTVERSION}
CONFIG_FILEPATH=$COMMON_CONST_SCRIPT_DIRNAME/data/${CONFIG_FILENAME}.txt
checkRequiredFiles "$CONFIG_FILEPATH"

###start prompt

startPrompt

###body

RET_VAL=$(cat $CONFIG_FILEPATH) || exitChildError "$RET_VAL"
VM_TYPE=$(echo $RET_VAL | awk -F:: '{print $1}')
VM_TEMPLATE=$(echo $RET_VAL | awk -F:: '{print $2}')
VM_NAME=$(echo $RET_VAL | awk -F:: '{print $3}')

if [ "$VM_TYPE" = "$COMMON_CONST_VMWARE_VMTYPE" ]; then
  ESXI_HOST=$(echo $RET_VAL | awk -F:: '{print $4}')
  RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../vmware/remove_vm_snapshot.sh -y $VM_NAME $COMMON_CONST_PROJECTNAME $ESXI_HOST) || exitChildError "$RET_VAL"
  echo "$RET_VAL"
  echo "Remove config file $CONFIG_FILEPATH"
  rm $CONFIG_FILEPATH
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
