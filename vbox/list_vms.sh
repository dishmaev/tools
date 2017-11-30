#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'VMs list'

##private consts

##private vars
PRM_FILTER_REGEX='' #build file name
VAR_RESULT='' #child return value
VAR_VMS_POOL='' # temp vms pool
VAR_VM_NAME='' #current vm
VAR_VM_ID='' #VMID target virtual machine
VAR_VM_SS='' #vm snapshot, <unknown> is not found template snapshot
VAR_SS_ID='' #snapshot id
VAR_SS_NAME='' #snapshot name
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_CHECK_REGEX='' #check regex package name
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vm by ssh
VAR_CUR_VM='' #vm exp

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[filterRegex=$COMMON_CONST_ALL]' "'$COMMON_CONST_ESXI_HOSTS_POOL'" ''

###check commands

PRM_FILTER_REGEX=${1:-$COMMON_CONST_ALL}

checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

VAR_VMS_POOL=$(getVmsPoolVb "$COMMON_CONST_ALL") || exitChildError "$VAR_VMS_POOL"
for VAR_CUR_VM in $VAR_VMS_POOL; do
  if [ "$PRM_FILTER_REGEX" != "$COMMON_CONST_ALL" ]; then
    VAR_CHECK_REGEX=$(echo "$VAR_CUR_VM" | grep -E "$PRM_FILTER_REGEX" | cat) || exitChildError "$VAR_CHECK_REGEX"
    if isEmpty "$VAR_CHECK_REGEX"; then continue; fi
  fi
  VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
  VAR_VM_ID=$(echo "$VAR_CUR_VM" | awk -F: '{print $2}') || exitChildError "$VAR_VM_ID"
  #get port address
  VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
  if isEmpty "$VAR_VM_PORT"; then VAR_VM_PORT="<unset>"; fi
  VAR_SS_ID=$(getVMSnapshotIDByNameVb "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME") || exitChildError "$VAR_SS_ID"
  #check snapshotName
  if isEmpty "$VAR_SS_ID"
  then
    VAR_VM_SS="<unknown>"
  else
    VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPoolVb "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_SS_ID") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
    VAR_VM_SS="$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
    for VAR_CHILD_SNAPSHOT_ID in $VAR_CHILD_SNAPSHOTS_POOL; do
      VAR_SS_NAME=$(getVMSnapshotNameByIDVb "$VAR_VM_ID" "$VAR_CHILD_SNAPSHOT_ID") || exitChildError "$VAR_SS_NAME"
      if ! isEmpty "$VAR_VM_SS"; then
        VAR_VM_SS="${VAR_VM_SS},"
      fi
      VAR_VM_SS=${VAR_VM_SS}$VAR_SS_NAME
    done
  fi
  if ! isEmpty "$VAR_RESULT"; then
    VAR_RESULT="${VAR_RESULT}\n"
  fi
  VAR_RESULT="${VAR_RESULT}$VAR_VM_NAME|$VAR_VM_ID|$VAR_VM_PORT|$VAR_VM_SS"
done

echoInfo "begin list"
echoResult "$VAR_RESULT"
echoInfo "end list"

doneFinalStage
exitOK
