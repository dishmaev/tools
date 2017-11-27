#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Create VM of project $ENV_PROJECT_NAME"

##private consts
CONST_PROJECT_ACTION='create'

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_VM_TYPE='' #vm name
PRM_VM_ROLE='' #role for create VM
PRM_OVERRIDE_CONFIG=$COMMON_CONST_FALSE #override config if exist
VAR_RESULT='' #child return value
VAR_VMS_POOL='' #vms pool
VAR_FOUND=$COMMON_CONST_FALSE #found flag
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id
VAR_VM_IP='' #vm ip address
VAR_SS_ID='' #snapshot id
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_REMOTE_SCRIPT_FILE_NAME='' #create script file name on remote vm
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE] [vmType=$COMMON_CONST_VMWARE_VM_TYPE]' \
"$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_VMWARE_VM_TYPE" \
"Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $COMMON_CONST_SUITES_POOL. Available VM types: $COMMON_CONST_VMTYPES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${3:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VM_TYPE=${4:-$COMMON_CONST_VMWARE_VM_TYPE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''
checkCommandExist 'vmType' "$PRM_VM_TYPE" "$COMMON_CONST_VMTYPES_POOL"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

VAR_SCRIPT_FILE_NAME=${PRM_VM_TEMPLATE}_${PRM_VM_ROLE}_${CONST_PROJECT_ACTION}
VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh

checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"

VAR_CONFIG_FILE_NAME=${PRM_SUITE}_${PRM_VM_ROLE}
VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}.cfg

checkFileForNotExist "$VAR_CONFIG_FILE_PATH" 'config '

###start prompt

startPrompt

###body

if [ "$PRM_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  echo "Try to find a free VM"
  VAR_VMS_POOL=$(getVmsPoolEsxi "$PRM_VM_TEMPLATE" "$COMMON_CONST_ALL") || exitChildError "$VAR_VMS_POOL"
  for CUR_VM in $VAR_VMS_POOL; do
    VAR_VM_NAME=$(echo "$CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    VAR_HOST=$(echo "$CUR_VM" | awk -F: '{print $2}') || exitChildError "$VAR_HOST"
    VAR_VM_ID=$(echo "$CUR_VM" | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
    VAR_SS_ID=$(getVMSnapshotIDByName "$VAR_VM_ID" "$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME" "$VAR_HOST") || exitChildError "$VAR_SS_ID"
    #check snapshotName
    if isEmpty "$VAR_SS_ID"
    then
      exitError "snapshot $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME not found for VM $VAR_VM_NAME on $VAR_HOST host"
    fi
    VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPool "$VAR_VM_ID" "$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME" "$VAR_SS_ID" "$VAR_HOST") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
    if isEmpty "$VAR_CHILD_SNAPSHOTS_POOL"; then
      VAR_FOUND=$COMMON_CONST_TRUE
      break
    fi
  done
  if ! isTrue "$VAR_FOUND"; then
    echo "Not found, required new VM"
    VAR_HOST=$COMMON_CONST_ESXI_HOST
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/create_${COMMON_CONST_VMWARE_VM_TYPE}_vm.sh -y $PRM_VM_TEMPLATE $VAR_HOST) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
    VAR_VM_NAME=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    VAR_VM_ID=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
    if isEmpty "$VAR_VM_NAME" || isEmpty "$VAR_VM_ID"; then exitError; fi
    echo "New VM name: $VAR_VM_NAME"
  else
    echo "Current VM name: $VAR_VM_NAME"
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
  fi
  VAR_RESULT=$(powerOnVM "$VAR_VM_ID" "$VAR_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  VAR_VM_IP=$(getIpAddressByVMName "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  echo "Start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  #exec trigger script
  VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$RET_LOG"
    if ! isEmpty "$RET_LOG"; then echo "Stdout:\n$RET_LOG"; fi
  fi
  RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$RET_LOG"; then echo "Stderr:\n$RET_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  fi
  #take project snapshot
  echo "Create VM $VAR_VM_NAME snapshot: $ENV_PROJECT_NAME"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/take_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME "$PRM_VM_ROLE" $VAR_HOST $COMMON_CONST_TRUE) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #save vm config file
  echo "Save config file $VAR_CONFIG_FILE_PATH"
  echo $PRM_VM_TYPE$COMMON_CONST_DATA_CFG_SEPARATOR\
$PRM_VM_TEMPLATE$COMMON_CONST_DATA_CFG_SEPARATOR\
$VAR_VM_NAME$COMMON_CONST_DATA_CFG_SEPARATOR$VAR_HOST > \
$VAR_CONFIG_FILE_PATH
fi

doneFinalStage
exitOK
