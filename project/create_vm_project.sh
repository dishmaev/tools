#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Create VM of project $ENV_PROJECT_NAME"

##private consts
CONST_PROJECT_ACTION='create'

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_SUITES_POOL='' #suite pool
PRM_VM_ROLES_POOL='' #roles for create VM pool
PRM_VM_TYPE='' #vm name
VAR_CUR_VM_ROLE='' #role for create VM
PRM_OVERRIDE_CONFIG=$COMMON_CONST_FALSE #override config if exist
VAR_RESULT='' #child return value
VAR_VMS_POOL='' #vms pool
VAR_FOUND=$COMMON_CONST_FALSE #found flag
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id
VAR_VM_IP='' #vm ip address
VAR_SS_ID='' #snapshot id
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vbox vm by ssh
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_REMOTE_SCRIPT_FILE_NAME='' #create script file name on remote vm
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_CUR_SUITE='' #current suite
VAR_CUR_VM_ROLE='' #current role for create VM
VAR_CUR_VM='' #vm exp
VAR_LOG='' #log execute script

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '[vmTemplate=ENV_DEFAULT_VM_TEMPLATE] [suitesPool=$COMMON_CONST_ALL] [vmRolesPool=$COMMON_CONST_DEFAULT_VM_ROLE] [vmType=$ENV_DEFAULT_VM_TYPE]' \
"$COMMON_CONST_DEFAULT_VM_TEMPLATE $COMMON_CONST_ALL $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_VBOX_VM_TYPE" \
"Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $COMMON_CONST_SUITES_POOL. Available VM types: $COMMON_CONST_VM_TYPES_POOL"

###check commands

PRM_VM_TEMPLATE=${1:-$ENV_DEFAULT_VM_TEMPLATE}
PRM_SUITES_POOL=${2:-$COMMON_CONST_ALL}
PRM_VM_ROLES_POOL=${3:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VM_TYPE=${4:-$ENV_DEFAULT_VM_TYPE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
if ! isEmpty "$2"; then
  checkCommandExist 'suitesPool' "$PRM_SUITES_POOL" "$COMMON_CONST_SUITES_POOL"
else
  checkCommandExist 'suitesPool' "$PRM_SUITES_POOL" ''
fi
checkCommandExist 'vmRolesPool' "$PRM_VM_ROLES_POOL" ''
checkCommandExist 'vmType' "$PRM_VM_TYPE" "$COMMON_CONST_VM_TYPES_POOL"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

###start prompt

startPrompt

###body

#remove known_hosts file to prevent future script errors
removeKnownHosts

if [ "$PRM_SUITES_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_SUITES_POOL=$COMMON_CONST_SUITES_POOL
fi

for VAR_CUR_SUITE in $PRM_SUITES_POOL; do
  for VAR_CUR_VM_ROLE in $PRM_VM_ROLES_POOL; do
    VAR_SCRIPT_FILE_NAME=${PRM_VM_TEMPLATE}_${VAR_CUR_VM_ROLE}_${CONST_PROJECT_ACTION}
    VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
    if [ "$VAR_CUR_VM_ROLE" = "$COMMON_CONST_DEFAULT_VM_ROLE" ]; then
      checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"
    fi
    if ! isFileExistAndRead "$VAR_SCRIPT_FILE_PATH"; then
      VAR_SCRIPT_FILE_NAME=${PRM_VM_TEMPLATE}_${COMMON_CONST_DEFAULT_VM_ROLE}_${CONST_PROJECT_ACTION}
      VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
      echoWarning "trigger script for role $VAR_CUR_VM_ROLE not found, try to use script for role $COMMON_CONST_DEFAULT_VM_ROLE"
      checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"
    fi
    VAR_FOUND=$COMMON_CONST_FALSE
    VAR_CONFIG_FILE_NAME=${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}.cfg
    VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
    if isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
      VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH | grep -E "^$PRM_VM_TYPE" | wc -l) || exitChildError "$VAR_RESULT"
      if [ "$VAR_RESULT" != "0" ]; then
        echoWarning "project VM suite $VAR_CUR_SUITE role $VAR_CUR_VM_ROLE already exist, skip create"
        continue
      fi
    fi
    echoInfo "start to create project VM suite $VAR_CUR_SUITE"
    if [ "$PRM_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
      echoInfo "try to find a free VM"
      VAR_VMS_POOL=$(getVmsPoolEx "$PRM_VM_TEMPLATE" "$COMMON_CONST_ALL") || exitChildError "$VAR_VMS_POOL"
      for VAR_CUR_VM in $VAR_VMS_POOL; do
        VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_HOST=$(echo "$VAR_CUR_VM" | awk -F: '{print $2}') || exitChildError "$VAR_HOST"
        VAR_VM_ID=$(echo "$VAR_CUR_VM" | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
        VAR_SS_ID=$(getVMSnapshotIDByNameEx "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_HOST") || exitChildError "$VAR_SS_ID"
        #check snapshotName
        if isEmpty "$VAR_SS_ID"; then
          exitError "snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME not found for VM $VAR_VM_NAME on $VAR_HOST host"
        fi
        VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPoolEx "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_SS_ID" "$VAR_HOST") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
        if isEmpty "$VAR_CHILD_SNAPSHOTS_POOL"; then
          VAR_FOUND=$COMMON_CONST_TRUE
          break
        fi
      done
      if ! isTrue "$VAR_FOUND"; then
        echoInfo "not found, required new VM"
        VAR_HOST=$COMMON_CONST_ESXI_HOST
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/create_${PRM_VM_TYPE}_vm.sh -y $PRM_VM_TEMPLATE $VAR_HOST) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_VM_NAME=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_VM_ID=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
        if isEmpty "$VAR_VM_NAME" || isEmpty "$VAR_VM_ID"; then exitError; fi
        echoInfo "new VM name $VAR_VM_NAME"
      else
        echoInfo "restore VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME on $VAR_HOST host"
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${PRM_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
      fi
      VAR_RESULT=$(powerOnVMEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
      #copy create script on vm
      VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
      $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
      checkRetValOK
      echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
      #exec trigger script
      VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $VAR_CUR_SUITE; \
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
      #take project snapshot
      echoInfo "create VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
      VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/take_${PRM_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME "${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}" $VAR_HOST $COMMON_CONST_TRUE) || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      #save vm config file
      echoInfo "save config file $VAR_CONFIG_FILE_PATH"
      echo $PRM_VM_TYPE$COMMON_CONST_DATA_CFG_SEPARATOR\
$PRM_VM_TEMPLATE$COMMON_CONST_DATA_CFG_SEPARATOR\
$VAR_VM_NAME$COMMON_CONST_DATA_CFG_SEPARATOR$VAR_HOST > $VAR_CONFIG_FILE_PATH
    elif [ "$PRM_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
      echoInfo "try to find a free VM"
      VAR_VMS_POOL=$(getVmsPoolVb "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VMS_POOL"
      for VAR_CUR_VM in $VAR_VMS_POOL; do
        VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_VM_ID=$(echo "$VAR_CUR_VM" | awk -F: '{print $2}') || exitChildError "$VAR_VM_ID"
        VAR_SS_ID=$(getVMSnapshotIDByNameVb "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME") || exitChildError "$VAR_SS_ID"
        #check snapshotName
        if isEmpty "$VAR_SS_ID"; then
          exitError "snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME not found for VM $VAR_VM_NAME"
        fi
        VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPoolVb "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_SS_ID") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
        if isEmpty "$VAR_CHILD_SNAPSHOTS_POOL"; then
          VAR_FOUND=$COMMON_CONST_TRUE
          break
        fi
      done
      if ! isTrue "$VAR_FOUND"; then
        echoInfo "not found, required new VM"
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/create_${PRM_VM_TYPE}_vm.sh -y $PRM_VM_TEMPLATE) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_VM_NAME=$(echo "$VAR_RESULT" | grep 'vmname:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_VM_ID=$(echo "$VAR_RESULT" | grep 'vmname:vmid' | awk '{print $2}' | awk -F: '{print $2}') || exitChildError "$VAR_VM_ID"
        if isEmpty "$VAR_VM_NAME" || isEmpty "$VAR_VM_ID"; then exitError; fi
        echoInfo "new VM name $VAR_VM_NAME"
      else
        echoInfo "current VM name $VAR_VM_NAME"
        VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/restore_${PRM_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
      fi
      VAR_RESULT=$(powerOnVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
      #copy create script on vm
      VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
      $SCP_CLIENT -P $VAR_VM_PORT $VAR_SCRIPT_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
      checkRetValOK
      echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
      #exec trigger script
      VAR_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $VAR_CUR_SUITE; \
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
      #take project snapshot
      echoInfo "create VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
      VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/take_${PRM_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME "${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}" $COMMON_CONST_TRUE) || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      #save vm config file
      echoInfo "save config file $VAR_CONFIG_FILE_PATH"
      echo $PRM_VM_TYPE$COMMON_CONST_DATA_CFG_SEPARATOR\
$PRM_VM_TEMPLATE$COMMON_CONST_DATA_CFG_SEPARATOR\
$VAR_VM_NAME >> $VAR_CONFIG_FILE_PATH
    elif [ "$PRM_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
      echoWarning "TO-DO support Docker containers"
    elif [ "$PRM_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
      echoWarning "TO-DO support Kubernetes containers"
    fi
  done
done

doneFinalStage
exitOK
