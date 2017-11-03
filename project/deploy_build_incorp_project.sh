#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file on incorp project $COMMON_CONST_PROJECTNAME"

##private consts


##private vars
PRM_FILENAME='' #build file name
PRM_SUITE='' #suite
PRM_SCRIPTVERSION='' #version script for deploy VM
RET_VAL='' #child return value
CONFIG_FILENAME='' #vm config file name
CONFIG_FILEPATH='' #vm config file path
SCRIPT_FILENAME='' #create script file name
SCRIPT_FILEPATH='' #create script file path
VM_TYPE='' #vm type
VM_TEMPLATE='' #vm template
VM_NAME='' #vm name
ESXI_HOST='' #esxi host
VM_ID='' #vm id

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<fileName> [suite=$COMMON_CONST_DEVELOP_SUITE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"myfile $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VERSION" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_FILENAME=$1
PRM_SCRIPTVERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'fileName' "$PRM_FILENAME" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

CONFIG_FILENAME=${PRM_SUITE}_${PRM_SCRIPTVERSION}
CONFIG_FILEPATH=$COMMON_CONST_SCRIPT_DIRNAME/data/${CONFIG_FILENAME}.txt
SCRIPT_FILENAME=${PRM_VMTEMPLATE}_${PRM_SCRIPTVERSION}_deploy
SCRIPT_FILEPATH=$COMMON_CONST_SCRIPT_DIRNAME/triggers/${SCRIPT_FILENAME}.sh

checkRequiredFiles "$PRM_FILENAME $CONFIG_FILEPATH $SCRIPT_FILEPATH"

###start prompt

startPrompt

###body

RET_VAL=$(cat $CONFIG_FILEPATH) || exitChildError "$RET_VAL"
VM_TYPE=$(echo $RET_VAL | awk -F:: '{print $1}')
VM_TEMPLATE=$(echo $RET_VAL | awk -F:: '{print $2}')
VM_NAME=$(echo $RET_VAL | awk -F:: '{print $3}')

if [ "$VM_TYPE" = "$COMMON_CONST_VMWARE_VMTYPE" ]; then
  ESXI_HOST=$(echo $RET_VAL | awk -F:: '{print $4}')
  RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../vmware/restore_vm_snapshot.sh -y $VM_NAME $COMMON_CONST_PROJECTNAME $ESXI_HOST) || exitChildError "$RET_VAL"

  $SCP_CLIENT $PRM_FILENAME $VM_IP:${REMOTE_SCRIPT_FILENAME}.sh
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
