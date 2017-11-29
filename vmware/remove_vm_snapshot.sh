#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Remove target VM snapshot on esxi host'

##private consts


##private vars
PRM_VM_NAME='' #vm name
PRM_SNAPSHOT_NAME='' #snapshotName
PRM_ESXI_HOST='' #host
PRM_REMOVE_CHILD=$COMMON_CONST_TRUE #remove child target snapshot
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_SS_ID='' #snapshot ID

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmName> <snapshotName> [esxiHost=$COMMON_CONST_ESXI_HOST] [removeChildren=1]' \
      "myvm snapshot1 $COMMON_CONST_ESXI_HOST 1" \
      "Required allowing SSH access on the remote host"

###check commands

PRM_VM_NAME=$1
PRM_SNAPSHOT_NAME=$2
PRM_ESXI_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_REMOVE_CHILD=${4:-$COMMON_CONST_TRUE}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOT_NAME" ''
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'removeChildren' "$PRM_REMOVE_CHILD" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

#check vm name
VAR_VM_ID=$(getVMIDByVMNameEx "$PRM_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VM_NAME not found on $PRM_ESXI_HOST host"
fi
#check snapshotName
VAR_SS_ID=$(getVMSnapshotIDByNameEx "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_SS_ID"
if isEmpty "$VAR_SS_ID"; then
  exitError "snapshot $PRM_SNAPSHOT_NAME not found for VM $PRM_VM_NAME on $PRM_ESXI_HOST host"
fi
#power off
VAR_RESULT=$(powerOffVMEx "$PRM_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#remove vm
$SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/snapshot.remove $VAR_VM_ID $VAR_SS_ID $PRM_REMOVE_CHILD"
checkRetValOK

doneFinalStage
exitOK
