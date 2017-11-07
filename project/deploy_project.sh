#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file of project $ENV_PROJECT_NAME"

##private consts


##private vars
PRM_BUILD_FILE='' #build file name
PRM_SUITE='' #suite
PRM_VM_ROLE='' #role for create VM
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
VAR_VM_IP='' #vm ip address
VAR_SHORT_FILE_NAME='' #short file name of $PRM_BUILD_FILE

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<buildFile> [suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE]' \
"myfile $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_BUILD_FILE=$1
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}

checkCommandExist 'buildFile' "$PRM_BUILD_FILE" ''
checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_VM_ROLE}
VAR_CONFIG_FILE_PATH=$COMMON_CONST_SCRIPT_DIR_NAME/data/${VAR_CONFIG_FILE_NAME}.txt
VAR_SCRIPT_FILE_NAME=${PRM_VMTEMPLATE}_${PRM_VM_ROLE}_deploy
VAR_SCRIPT_FILE_PATH=$COMMON_CONST_SCRIPT_DIR_NAME/trigger/${VAR_SCRIPT_FILE_NAME}.sh

checkRequiredFiles "$PRM_BUILD_FILE $VAR_CONFIG_FILE_PATH $VAR_SCRIPT_FILE_PATH"

###start prompt

startPrompt

###body

VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH) || exitChildError "$VAR_RESULT"
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F:: '{print $1}') || exitChildError "$VAR_VM_TYPE"
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F:: '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F:: '{print $3}') || exitChildError "$VAR_VM_NAME"

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F:: '{print $4}') || exitChildError "$VAR_HOST"
  VAR_RESULT=$($COMMON_CONST_SCRIPT_DIR_NAME/../vmware/restore_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power off
  VAR_RESULT=$(powerOnVM "$VAR_VM_ID" "$PRM_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  VAR_VM_IP=$(getIpAddressByVMName "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_VM_IP"
  #copy build file on vm
  VAR_SCRIPT_FILE_NAME=$(getFileNameFromUrlString "$PRM_BUILD_FILE") || exitChildError "$VAR_SCRIPT_FILE_NAME"
  $SCP_CLIENT $PRM_BUILD_FILE $VAR_VM_IP:$VAR_SCRIPT_FILE_NAME
  if ! isRetValOK; then exitError; fi
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  if ! isRetValOK; then exitError; fi
  #exec trigger script
  echo "Start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $VAR_SCRIPT_FILE_NAME; \
if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.result ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.result; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$RET_LOG"; then echo "Stdout:\n$RET_LOG"; fi
  RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$RET_LOG"; then echo "Stderr:\n$RET_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  fi
fi

doneFinalStage
exitOK
