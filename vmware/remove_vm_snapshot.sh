#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Remove target VM snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOTNAME='' #snapshotName
PRM_HOST='' #host
VM_ID='' #VMID target virtual machine
SS_ID='' #snapshot ID

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmName> <snapshotName> [host=$COMMON_CONST_ESXI_HOST]' \
      "myvm snapshot1 $COMMON_CONST_ESXI_HOST" \
      "Required allowing SSH access on the remote host"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOTNAME" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

VM_ID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$VM_ID"
#check vm name
if isEmpty "$VM_ID"
then
  exitError "VM $PRM_VMNAME not found on $PRM_HOST host"
fi

SS_ID=$(getVMSnapshotIDByName "$VM_ID" "$PRM_SNAPSHOTNAME" "$PRM_HOST") || exitChildError "$SS_ID"
#check snapshotName
if isEmpty "$SS_ID"
then
  exitError "snapshot $PRM_SNAPSHOTNAME not found for VM $PRM_VMNAME on $PRM_HOST host"
fi

$SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd vmsvc/snapshot.remove $VM_ID $SS_ID"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
