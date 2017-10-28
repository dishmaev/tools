#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Restore target VM snapshot on esxi host'

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

echoHelp $# 3 "<vmName> <snapshotName=\$COMMON_CONST_ESXI_SNAPSHOT_PROJECT_NAME | \
\$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME> [host=\$COMMON_CONST_ESXI_HOST]" \
"myvm $COMMON_CONST_ESXI_SNAPSHOT_PROJECT_NAME $COMMON_CONST_ESXI_HOST" \
"Required allowing SSH access on the remote host. Available snapshotName: $COMMON_CONST_ESXI_SNAPSHOT_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOTNAME" "$COMMON_CONST_ESXI_SNAPSHOT_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check body dependencies

checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

VM_ID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$VM_ID"
#check vm name
if isEmpty "$VM_ID"; then
  exitError "VM $PRM_VMNAME not found on $PRM_HOST host"
fi

SS_ID=$(getVMSnapshotIDByName "$VM_ID" "$PRM_SNAPSHOTNAME" "$PRM_HOST") || exitChildError "$SS_ID"
#check snapshotName
if isEmpty "$SS_ID"
then
  exitError "snapshot $PRM_SNAPSHOTNAME not found for VM $PRM_VMNAME on $PRM_HOST host"
fi



doneFinalStage
exitOK
