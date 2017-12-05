#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file of project $ENV_PROJECT_NAME"

##private consts
CONST_PROJECT_ACTION='deploy'
CONST_MAKE_OUTPUT=$(echo $ENV_PROJECT_NAME | tr '[A-Z]' '[a-z]')

##private vars
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
VAR_VM_IP='' #vm ip address
VAR_BUILD_FILE_NAME='' #build file name
VAR_BUILD_FILE_PATH='' #build file name with local path
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vbox vm by ssh
VAR_LOG='' #log execute script

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_SUITE=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}

checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

VAR_BUILD_FILE_PATH="$COMMON_CONST_LOCAL_BUILDS_PATH/${CONST_MAKE_OUTPUT}-${PRM_SUITE}-${PRM_VM_ROLE}-bin.tar.gz"
checkRequiredFiles "$VAR_BUILD_FILE_PATH"

###start prompt

startPrompt

###body

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_VM_ROLE}.cfg
VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
if ! isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
  echoWarning "config file $VAR_CONFIG_FILE_PATH not found, required new project VM"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/create_vm_project.sh -y $ENV_DEFAULT_VM_TEMPLATE $PRM_SUITE $PRM_VM_ROLE) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  checkRequiredFiles "$VAR_CONFIG_FILE_PATH"
fi

VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH) || exitChildError "$VAR_RESULT"
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_VM_TYPE"
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"

VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${PRM_VM_ROLE}_${CONST_PROJECT_ACTION}
VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
if [ "$PRM_VM_ROLE" != "$COMMON_CONST_DEFAULT_VM_ROLE" ] && ! isFileExistAndRead "$VAR_SCRIPT_FILE_PATH"; then
  VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${COMMON_CONST_DEFAULT_VM_ROLE}_${CONST_PROJECT_ACTION}
  VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
  echoWarning "trigger script for role $PRM_VM_ROLE not found, try to use script for role $COMMON_CONST_DEFAULT_VM_ROLE"
fi
checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
  checkSSHKeyExistEsxi "$VAR_HOST"
  #restore project snapshot
  echoInfo "restore VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME on $VAR_HOST host"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVMEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #copy build file on vm
  VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  VAR_BUILD_FILE_NAME=$(getFileNameFromUrlString "$VAR_BUILD_FILE_PATH") || exitChildError "$VAR_BUILD_FILE_NAME"
  $SCP_CLIENT $VAR_BUILD_FILE_PATH $VAR_VM_IP:$VAR_BUILD_FILE_NAME
  checkRetValOK
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BUILD_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echoInfo "stdout\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stderr\n$VAR_LOG"; fi
  VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stdtst\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  else
    echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  fi
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
  #restore project snapshot
  VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoInfo "restore VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #copy build file on vm
  VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
  VAR_BUILD_FILE_NAME=$(getFileNameFromUrlString "$VAR_BUILD_FILE_PATH") || exitChildError "$VAR_BUILD_FILE_NAME"
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_BUILD_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:$VAR_BUILD_FILE_NAME
  checkRetValOK
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_SCRIPT_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  VAR_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BUILD_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echoInfo "stdout\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stderr\n$VAR_LOG"; fi
  VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stdtst\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  else
    echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  fi
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
  echoWarning "TO-DO support Docker containers"
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
  echoWarning "TO-DO support Kubernetes containers"
fi

doneFinalStage
exitOK
