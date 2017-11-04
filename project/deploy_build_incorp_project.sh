#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file on incorp project $COMMON_CONST_PROJECT_NAME"

##private consts


##private vars
PRM_FILE_NAME='' #build file name
PRM_SUITE='' #suite
PRM_SCRIPT_VERSION='' #version script for deploy VM
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<fileName> [suite=$COMMON_CONST_DEVELOP_SUITE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"myfile $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VERSION" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_FILE_NAME=$1
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_SCRIPT_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'fileName' "$PRM_FILE_NAME" ''
checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'scriptVersion' "$PRM_SCRIPT_VERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_SCRIPT_VERSION}
VAR_CONFIG_FILE_PATH=$COMMON_CONST_SCRIPT_DIR_NAME/data/${VAR_CONFIG_FILE_NAME}.txt
VAR_SCRIPT_FILE_NAME=${PRM_VMTEMPLATE}_${PRM_SCRIPT_VERSION}_deploy
VAR_SCRIPT_FILE_PATH=$COMMON_CONST_SCRIPT_DIR_NAME/triggers/${VAR_SCRIPT_FILE_NAME}.sh

checkRequiredFiles "$PRM_FILE_NAME $VAR_CONFIG_FILE_PATH $VAR_SCRIPT_FILE_PATH"

###start prompt

startPrompt

###body

VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH) || exitChildError "$VAR_RESULT"
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F:: '{print $1}')
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F:: '{print $2}')
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F:: '{print $3}')

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F:: '{print $4}')
  VAR_RESULT=$($COMMON_CONST_SCRIPT_DIR_NAME/../vmware/restore_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"

  $SCP_CLIENT $PRM_FILE_NAME $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
