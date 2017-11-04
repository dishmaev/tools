#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM on incorp project $COMMON_CONST_PROJECT_NAME"

##private consts


##private vars
PRM_SUITE='' #suite
PRM_SCRIPT_VERSION='' #version script for create VM
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[suite=$COMMON_CONST_DEVELOP_SUITE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VERSION" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_SUITE=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_SCRIPT_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'scriptVersion' "$PRM_SCRIPT_VERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_SCRIPT_VERSION}
VAR_CONFIG_FILE_PATH=$COMMON_CONST_SCRIPT_DIR_NAME/data/${VAR_CONFIG_FILE_NAME}.txt
checkRequiredFiles "$VAR_CONFIG_FILE_PATH"

###start prompt

startPrompt

###body

VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH) || exitChildError "$VAR_RESULT"
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F:: '{print $1}')
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F:: '{print $2}')
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F:: '{print $3}')

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F:: '{print $4}')
  VAR_RESULT=$($COMMON_CONST_SCRIPT_DIR_NAME/../vmware/remove_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echo "$VAR_RESULT"
  echo "Remove config file $VAR_CONFIG_FILE_PATH"
  rm $VAR_CONFIG_FILE_PATH
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
