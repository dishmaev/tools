#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file of project $ENV_PROJECT_NAME"

##private consts
CONST_MAKE_OUTPUT=$(echo $ENV_PROJECT_NAME | tr '[A-Z]' '[a-z]')

##private vars
PRM_SUITE='' #suite
PRM_VM_ROLE='' #role for create VM
VAR_RESULT='' #child return value
VAR_SCRIPT_RESULT='' #script return value
VAR_SCRIPT_START='' #script start time
VAR_SCRIPT_STOP='' #script stop time
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_IP='' #vm ip address
VAR_BIN_TAR_FILE_NAME='' #binary archive file name
VAR_BIN_TAR_FILE_PATH='' #binary archive file name with local path
VAR_LOG_TAR_FILE_NAME='' #log archive file name
VAR_LOG_TAR_FILE_PATH='' #log archive file name with local path
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vbox vm by ssh
VAR_TIME_STRING='' #time as standard string

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

VAR_BIN_TAR_FILE_PATH="$ENV_PROJECT_TMP_PATH/${CONST_MAKE_OUTPUT}_${PRM_SUITE}_${PRM_VM_ROLE}_bin.tar.gz"
checkRequiredFiles "$VAR_BIN_TAR_FILE_PATH"

###start prompt

startPrompt

###body

#remove known_hosts file to prevent future script errors
removeKnownHosts

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_VM_ROLE}.cfg
VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
if ! isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
  echoWarning "config file $VAR_CONFIG_FILE_PATH not found, required new project VM"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/create_vm_project.sh -y $ENV_DEFAULT_VM_TEMPLATE $PRM_SUITE $PRM_VM_ROLE) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  checkRequiredFiles "$VAR_CONFIG_FILE_PATH"
fi

VAR_RESULT=$(getProjectVMForAction "$COMMON_CONST_PROJECT_ACTION_DEPLOY" "$PRM_SUITE" "$PRM_VM_ROLE") || exitChildError "$VAR_RESULT"
if isEmpty "$VAR_RESULT"; then
  exitError "not available any VM for project action $COMMON_CONST_PROJECT_ACTION_DEPLOY suite $PRM_SUITE role $PRM_VM_ROLE"
fi
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_VM_TYPE"
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"

VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${PRM_VM_ROLE}_${COMMON_CONST_PROJECT_ACTION_DEPLOY}
VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
if [ "$PRM_VM_ROLE" != "$COMMON_CONST_DEFAULT_VM_ROLE" ] && ! isFileExistAndRead "$VAR_SCRIPT_FILE_PATH"; then
  VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${COMMON_CONST_DEFAULT_VM_ROLE}_${COMMON_CONST_PROJECT_ACTION_DEPLOY}
  VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
  echoWarning "trigger script for role $PRM_VM_ROLE not found, try to use script for role $COMMON_CONST_DEFAULT_VM_ROLE"
fi
checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"

VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME

VAR_LOG_TAR_FILE_NAME=${CONST_MAKE_OUTPUT}_${PRM_SUITE}_${PRM_VM_ROLE}_log.tar.gz
VAR_LOG_TAR_FILE_PATH=$ENV_PROJECT_TMP_PATH/$VAR_LOG_TAR_FILE_NAME
#remove old files
rm -f "$VAR_LOG_TAR_FILE_PATH"

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
  #restore project snapshot
  echoInfo "restore VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME on $VAR_HOST host"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVMEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #copy build file on vm
  VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  VAR_BIN_TAR_FILE_NAME=$(getFileNameFromUrlString "$VAR_BIN_TAR_FILE_PATH") || exitChildError "$VAR_BIN_TAR_FILE_NAME"
  echoInfo "put build file $VAR_BIN_TAR_FILE_PATH on VM $VAR_VM_NAME ip $VAR_VM_IP"
  $SCP_CLIENT $VAR_BIN_TAR_FILE_PATH $VAR_VM_IP:$VAR_BIN_TAR_FILE_NAME
  checkRetValOK
  #copy create script on vm
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  VAR_SCRIPT_START="$(getTime)"
  VAR_TIME_STRING=$(getTimeAsString "$VAR_SCRIPT_START" "$COMMON_CONST_TIME_FORMAT_LONG")
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host at $VAR_TIME_STRING"
  VAR_SCRIPT_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BIN_TAR_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_SCRIPT_RESULT"
  VAR_SCRIPT_STOP="$(getTime)"
  packLogFiles "$VAR_VM_IP" "$COMMON_CONST_DEFAULT_SSH_PORT" "$VAR_REMOTE_SCRIPT_FILE_NAME" "$VAR_LOG_TAR_FILE_PATH"
  checkRetValOK
  if ! isTrue "$VAR_SCRIPT_RESULT"; then
    #add history log
    if isTrue "$COMMON_CONST_HISTORY_LOG"; then
      addHistoryLog "$COMMON_CONST_PROJECT_ACTION_DEPLOY" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' "$VAR_BIN_TAR_FILE_PATH" "$VAR_LOG_TAR_FILE_PATH"
      checkRetValOK
    fi
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host, details in $VAR_LOG_TAR_FILE_PATH"
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
  VAR_BIN_TAR_FILE_NAME=$(getFileNameFromUrlString "$VAR_BIN_TAR_FILE_PATH") || exitChildError "$VAR_BIN_TAR_FILE_NAME"
  echoInfo "put build file $VAR_BIN_TAR_FILE_PATH on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_BIN_TAR_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:$VAR_BIN_TAR_FILE_NAME
  checkRetValOK
  #copy create script on vm
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_SCRIPT_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  VAR_SCRIPT_START="$(getTime)"
  VAR_TIME_STRING=$(getTimeAsString "$VAR_SCRIPT_START" "$COMMON_CONST_TIME_FORMAT_LONG")
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT at $VAR_TIME_STRING"
  VAR_SCRIPT_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BIN_TAR_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_SCRIPT_RESULT"
  VAR_SCRIPT_STOP="$(getTime)"
  packLogFiles "$COMMON_CONST_VAGRANT_IP_ADDRESS" "$VAR_VM_PORT" "$VAR_REMOTE_SCRIPT_FILE_NAME" "$VAR_LOG_TAR_FILE_PATH"
  checkRetValOK
  if ! isTrue "$VAR_SCRIPT_RESULT"; then
    #add history log
    if isTrue "$COMMON_CONST_HISTORY_LOG"; then
      addHistoryLog "$COMMON_CONST_PROJECT_ACTION_DEPLOY" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' "$VAR_BIN_TAR_FILE_PATH" "$VAR_LOG_TAR_FILE_PATH"
      checkRetValOK
    fi
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT, details in $VAR_LOG_TAR_FILE_PATH"
  else
    echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  fi
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
  echoWarning "TO-DO support Docker containers"
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
  echoWarning "TO-DO support Kubernetes containers"
fi
#add history log
if isTrue "$COMMON_CONST_HISTORY_LOG"; then
  addHistoryLog "$COMMON_CONST_PROJECT_ACTION_DEPLOY" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' "$VAR_BIN_TAR_FILE_PATH" "$VAR_LOG_TAR_FILE_PATH"
  checkRetValOK
fi

doneFinalStage
exitOK
