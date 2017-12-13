#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Create VM of project $ENV_PROJECT_NAME"

##private consts
CONST_MAKE_OUTPUT=$(echo $ENV_PROJECT_NAME | tr '[A-Z]' '[a-z]')

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_SUITES_POOL='' #suite pool
PRM_VM_ROLES_POOL='' #roles for create VM pool
PRM_VM_TYPES_POOL='' #vm types pool
VAR_VM_TYPE='' #vm type
VAR_CUR_VM_ROLE='' #role for create VM
PRM_OVERRIDE_CONFIG=$COMMON_CONST_FALSE #override config if exist
VAR_RESULT='' #child return value
VAR_SCRIPT_RESULT='' #script return value
VAR_SCRIPT_START='' #script start time
VAR_SCRIPT_STOP='' #script stop time
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
VAR_LOG_TAR_FILE_NAME='' #log archive file name
VAR_LOG_TAR_FILE_PATH='' #log archive file name with local path
VAR_CUR_SUITE='' #current suite
VAR_CUR_VM_ROLE='' #current role for create VM
VAR_CUR_VM='' #vm exp
VAR_TIME_STRING='' #time as standard string

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '[vmTemplate=ENV_DEFAULT_VM_TEMPLATE] [suitesPool=$COMMON_CONST_RUNNER_SUITE & $COMMON_CONST_DEVELOP_SUITE] [vmRolesPool=$COMMON_CONST_DEFAULT_VM_ROLE] [vmTypesPool=$ENV_VM_TYPES_POOL]' \
"$COMMON_CONST_DEFAULT_VM_TEMPLATE '$COMMON_CONST_RUNNER_SUITE $COMMON_CONST_DEVELOP_SUITE' $COMMON_CONST_DEFAULT_VM_ROLE '$ENV_VM_TYPES_POOL'" \
"Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $COMMON_CONST_SUITES_POOL. Available VM types: $ENV_VM_TYPES_POOL"

###check commands

PRM_VM_TEMPLATE=${1:-$ENV_DEFAULT_VM_TEMPLATE}
PRM_SUITES_POOL=${2:-"$COMMON_CONST_RUNNER_SUITE $COMMON_CONST_DEVELOP_SUITE"}
PRM_VM_ROLES_POOL=${3:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VM_TYPES_POOL=${4:-$ENV_VM_TYPES_POOL}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'suitesPool' "$PRM_SUITES_POOL" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRolesPool' "$PRM_VM_ROLES_POOL" ''
checkCommandExist 'vmTypesPool' "$PRM_VM_TYPES_POOL" "$ENV_VM_TYPES_POOL"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

###start prompt

startPrompt

###body

#remove known_hosts file to prevent future script errors
removeKnownHosts

VAR_VM_TYPE=$(getAvailableVMType "$PRM_VM_TYPES_POOL") || exitChildError "$VAR_VM_TYPE"
if ! isEmpty "$VAR_VM_TYPE"; then
  echoInfo "use available VM type $VAR_VM_TYPE"
else
  exitError "not available any VM types"
fi

for VAR_CUR_SUITE in $PRM_SUITES_POOL; do
  for VAR_CUR_VM_ROLE in $PRM_VM_ROLES_POOL; do
    VAR_SCRIPT_FILE_NAME=${PRM_VM_TEMPLATE}_${VAR_CUR_VM_ROLE}_${COMMON_CONST_PROJECT_ACTION_CREATE}
    VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh

    VAR_LOG_TAR_FILE_NAME=${CONST_MAKE_OUTPUT}_${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}_log.tar.gz
    VAR_LOG_TAR_FILE_PATH=$COMMON_CONST_LOCAL_BUILD_PATH/$VAR_LOG_TAR_FILE_NAME
    #remove old files
    rm -f "$VAR_LOG_TAR_FILE_PATH"

    if [ "$VAR_CUR_VM_ROLE" = "$COMMON_CONST_DEFAULT_VM_ROLE" ]; then
      checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"
    fi
    if ! isFileExistAndRead "$VAR_SCRIPT_FILE_PATH"; then
      VAR_SCRIPT_FILE_NAME=${PRM_VM_TEMPLATE}_${COMMON_CONST_DEFAULT_VM_ROLE}_${COMMON_CONST_PROJECT_ACTION_CREATE}
      VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
      echoWarning "trigger script for role $VAR_CUR_VM_ROLE not found, try to use script for role $COMMON_CONST_DEFAULT_VM_ROLE"
      checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"
    fi
    VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
    VAR_FOUND=$COMMON_CONST_FALSE
    VAR_CONFIG_FILE_NAME=${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}.cfg
    VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
    if isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
      VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH | grep -E "^$VAR_VM_TYPE" | wc -l) || exitChildError "$VAR_RESULT"
      if [ $VAR_RESULT -ne 0 ]; then
        echoWarning "project VM suite $VAR_CUR_SUITE role $VAR_CUR_VM_ROLE already exist, skip create"
        continue
      fi
    fi
    echoInfo "start to create project VM suite $VAR_CUR_SUITE"
    if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
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
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/create_${VAR_VM_TYPE}_vm.sh -y $PRM_VM_TEMPLATE $VAR_HOST) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_VM_NAME=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_VM_ID=$(echo "$VAR_RESULT" | grep 'vmname:esxihost:vmid' | awk '{print $2}' | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
        if isEmpty "$VAR_VM_NAME" || isEmpty "$VAR_VM_ID"; then exitError; fi
        echoInfo "new VM name $VAR_VM_NAME"
      else
        echoInfo "restore VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME on $VAR_HOST host"
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
      fi
      VAR_RESULT=$(powerOnVMEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
      #copy create script on vm
      $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
      checkRetValOK
      #exec trigger script
      VAR_SCRIPT_START="$(getTime)"
      VAR_TIME_STRING=$(getTimeAsString "$VAR_SCRIPT_START")
      echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host at $VAR_TIME_STRING"
      VAR_SCRIPT_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $VAR_CUR_SUITE; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_SCRIPT_RESULT"
      VAR_SCRIPT_STOP="$(getTime)"
      packLogFiles "$VAR_VM_IP" "$COMMON_CONST_DEFAULT_SSH_PORT" "$VAR_REMOTE_SCRIPT_FILE_NAME" "$VAR_LOG_TAR_FILE_PATH"
      checkRetValOK
      if ! isTrue "$VAR_SCRIPT_RESULT"; then
        #add history log
        if isTrue "$COMMON_CONST_HISTORY_LOG"; then
          echoInfo "add history log"
          addHistoryLog "$COMMON_CONST_PROJECT_ACTION_CREATE" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' '' "$VAR_LOG_TAR_FILE_PATH"
          checkRetValOK
        fi
        exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host, details in $VAR_LOG_TAR_FILE_PATH"
      else
        echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
      fi
      #take project snapshot
      echoInfo "create VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
      VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/take_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME "${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}" $VAR_HOST $COMMON_CONST_TRUE) || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      #save vm config file
      echoInfo "save config file $VAR_CONFIG_FILE_PATH"
      echo $VAR_VM_TYPE$COMMON_CONST_DATA_CFG_SEPARATOR\
$PRM_VM_TEMPLATE$COMMON_CONST_DATA_CFG_SEPARATOR\
$VAR_VM_NAME$COMMON_CONST_DATA_CFG_SEPARATOR$VAR_HOST >> $VAR_CONFIG_FILE_PATH
    elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
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
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/create_${VAR_VM_TYPE}_vm.sh -y $PRM_VM_TEMPLATE) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_VM_NAME=$(echo "$VAR_RESULT" | grep 'vmname:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
        VAR_VM_ID=$(echo "$VAR_RESULT" | grep 'vmname:vmid' | awk '{print $2}' | awk -F: '{print $2}') || exitChildError "$VAR_VM_ID"
        if isEmpty "$VAR_VM_NAME" || isEmpty "$VAR_VM_ID"; then exitError; fi
        echoInfo "new VM name $VAR_VM_NAME"
      else
        echoInfo "current VM name $VAR_VM_NAME"
        VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
      fi
      VAR_RESULT=$(powerOnVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
      #copy create script on vm
      $SCP_CLIENT -P $VAR_VM_PORT $VAR_SCRIPT_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
      checkRetValOK
      #exec trigger script
      VAR_SCRIPT_START="$(getTime)"
      VAR_TIME_STRING=$(getTimeAsString "$VAR_SCRIPT_START")
      echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT at $VAR_TIME_STRING"
      VAR_SCRIPT_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $VAR_CUR_SUITE; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_SCRIPT_RESULT"
      VAR_SCRIPT_STOP="$(getTime)"
      packLogFiles "$COMMON_CONST_VAGRANT_IP_ADDRESS" "$VAR_VM_PORT" "$VAR_REMOTE_SCRIPT_FILE_NAME" "$VAR_LOG_TAR_FILE_PATH"
      checkRetValOK
      if ! isTrue "$VAR_SCRIPT_RESULT"; then
        #add history log
        if isTrue "$COMMON_CONST_HISTORY_LOG"; then
          echoInfo "add history log"
          addHistoryLog "$COMMON_CONST_PROJECT_ACTION_CREATE" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' '' "$VAR_LOG_TAR_FILE_PATH"
          checkRetValOK
        fi
        exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT, details in $VAR_LOG_TAR_FILE_PATH"
      else
        echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
      fi
      #take project snapshot
      echoInfo "create VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
      VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/take_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME "${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}" $COMMON_CONST_TRUE) || exitChildError "$VAR_RESULT"
      echoResult "$VAR_RESULT"
      #save vm config file
      echoInfo "save config file $VAR_CONFIG_FILE_PATH"
      echo $VAR_VM_TYPE$COMMON_CONST_DATA_CFG_SEPARATOR\
$PRM_VM_TEMPLATE$COMMON_CONST_DATA_CFG_SEPARATOR\
$VAR_VM_NAME >> $VAR_CONFIG_FILE_PATH
    elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
      echoWarning "TO-DO support Docker containers"
    elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
      echoWarning "TO-DO support Kubernetes containers"
    fi
    #add history log
    if isTrue "$COMMON_CONST_HISTORY_LOG"; then
      echoInfo "add history log"
      addHistoryLog "$COMMON_CONST_PROJECT_ACTION_CREATE" "$VAR_SCRIPT_START" "$VAR_SCRIPT_STOP" "$VAR_SCRIPT_RESULT" '' '' "$VAR_LOG_TAR_FILE_PATH"
      checkRetValOK
    fi
  done
done

doneFinalStage
exitOK
