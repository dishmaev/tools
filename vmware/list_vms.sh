#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'VMs list'

##private consts

##private vars
PRM_ESXI_HOSTS_POOL='' # esxi hosts pool
PRM_FILTER_REGEX='' #build file name
VAR_HOST='' #current esxi host
VAR_RESULT='' #child return value
VAR_VMS_POOL='' # temp vms pool
VAR_VM_NAME='' #current vm
VAR_VM_ID='' #VMID target virtual machine
VAR_VM_IP='' #vm ip address, <unset> if off line
VAR_VM_SS='' #vm snapshot, <unknown> is not found template snapshot
VAR_SS_ID='' #snapshot id
VAR_SS_NAME='' #snapshot name
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_CHECK_REGEX='' #check regex package name
VAR_CUR_VM='' #vm exp

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[esxiHostsPool=$COMMON_CONST_ALL] [filterRegex=$COMMON_CONST_ALL]' \
"$COMMON_CONST_ALL $COMMON_CONST_ALL" \
"Available esxi hosts: $COMMON_CONST_ESXI_HOSTS_POOL"

###check commands

PRM_ESXI_HOSTS_POOL=${1:-$COMMON_CONST_ALL}
PRM_FILTER_REGEX=${2:-$COMMON_CONST_ALL}

if ! isEmpty "$1"; then
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" "$COMMON_CONST_ESXI_HOSTS_POOL"
else
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" ''
fi
checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

if [ "$PRM_ESXI_HOSTS_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_ESXI_HOSTS_POOL=$COMMON_CONST_ESXI_HOSTS_POOL
fi

for VAR_HOST in $PRM_ESXI_HOSTS_POOL; do
  checkSSHKeyExistEsxi "$VAR_HOST"
  VAR_VMS_POOL=$(getVmsPoolEx "$COMMON_CONST_ALL" "$VAR_HOST") || exitChildError "$VAR_VMS_POOL"
  for VAR_CUR_VM in $VAR_VMS_POOL; do
    if [ "$PRM_FILTER_REGEX" != "$COMMON_CONST_ALL" ]; then
      VAR_CHECK_REGEX=$(echo "$VAR_CUR_VM" | grep -E "$PRM_FILTER_REGEX" | cat) || exitChildError "$VAR_CHECK_REGEX"
      if isEmpty "$VAR_CHECK_REGEX"; then continue; fi
    fi
    VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    VAR_VM_ID=$(echo "$VAR_CUR_VM" | awk -F: '{print $3}') || exitChildError "$VAR_VM_ID"
    VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_TRUE") || exitChildError "$VAR_VM_IP"
    if isEmpty "$VAR_VM_IP"; then VAR_VM_IP="<unset>"; fi
    VAR_SS_ID=$(getVMSnapshotIDByNameEx "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_HOST") || exitChildError "$VAR_SS_ID"
    #check snapshotName
    if isEmpty "$VAR_SS_ID"
    then
      VAR_VM_SS="<unknown>"
    else
      VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPoolEx "$VAR_VM_ID" "$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME" "$VAR_SS_ID" "$VAR_HOST") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
      VAR_VM_SS="$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
      for VAR_CHILD_SNAPSHOT_ID in $VAR_CHILD_SNAPSHOTS_POOL; do
        VAR_SS_NAME=$(getVMSnapshotNameByIDEx "$VAR_VM_ID" "$VAR_CHILD_SNAPSHOT_ID" "$VAR_HOST") || exitChildError "$VAR_SS_NAME"
        if ! isEmpty "$VAR_VM_SS"; then
          VAR_VM_SS="${VAR_VM_SS},"
        fi
        VAR_VM_SS=${VAR_VM_SS}$VAR_SS_NAME
      done
    fi
    if ! isEmpty "$VAR_RESULT"; then
      VAR_RESULT="${VAR_RESULT}\n"
    fi
    VAR_RESULT="${VAR_RESULT}$VAR_VM_NAME|$VAR_HOST|$VAR_VM_ID|$VAR_VM_IP|$VAR_VM_SS"
  done
done

echoInfo "begin list"
echoResult "$VAR_RESULT"
echoInfo "end list"

doneFinalStage
exitOK
