#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Take standard snapshot of VM type $COMMON_CONST_VMWARE_VM_TYPE"

##private consts


##private vars
PRM_VM_NAME='' #vm name
PRM_SNAPSHOT_NAME='' #snapshotName
PRM_ESXI_HOST='' #host
PRM_SNAPSHOT_DESCRIPTION='' #snapshotDescription
PRM_INCLUDE_MEMORY=$COMMON_CONST_FALSE #includeMemory
PRM_QUIESCED=$COMMON_CONST_FALSE #quiesced
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 6 '<vmName> <snapshotName> [snapshotDescription] [esxiHost=$COMMON_CONST_ESXI_HOST] [includeMemory=0] [quiesced=0]' \
      "myvm snapshot1 'my description' $COMMON_CONST_ESXI_HOST 0 0" \
      "Required allowing SSH access on the remote host. Available standard snapshotName: $ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VM_NAME=$1
PRM_SNAPSHOT_NAME=$2
PRM_SNAPSHOT_DESCRIPTION=${3:-'text'}
PRM_ESXI_HOST=${4:-$COMMON_CONST_ESXI_HOST}
PRM_INCLUDE_MEMORY=${5:-$COMMON_CONST_FALSE}
PRM_QUIESCED=${6:-$COMMON_CONST_FALSE}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOT_NAME" "$ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'snapshotDescription' "$PRM_SNAPSHOT_DESCRIPTION" ''
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'includeMemory' "$PRM_INCLUDE_MEMORY" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'quiesced' "$PRM_QUIESCED" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

checkSSHKeyExistEsxi "$PRM_ESXI_HOST"
checkRetValOK

#check vm name
VAR_VM_ID=$(getVMIDByVMNameEx "$PRM_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VM_NAME not found on $PRM_ESXI_HOST host"
fi
#check snapshotName
if isSnapshotVMExistEx "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME" "$PRM_ESXI_HOST"; then
  exitError "snapshot $PRM_SNAPSHOT_NAME already exist for VM $PRM_VM_NAME on $PRM_ESXI_HOST host"
fi
#power off
if ! isTrue "$PRM_INCLUDE_MEMORY"; then
  VAR_RESULT=$(powerOffVMEx "$PRM_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
fi
$SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/snapshot.create $VAR_VM_ID $PRM_SNAPSHOT_NAME \"$PRM_SNAPSHOT_DESCRIPTION\" $PRM_INCLUDE_MEMORY $PRM_QUIESCED"
checkRetValOK

doneFinalStage
exitOK
