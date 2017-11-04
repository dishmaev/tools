#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Restore target VM standard snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOTNAME='' #snapshotName
PRM_HOST='' #host
PRM_REMOVECHILD='' #remove child target snapshot
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_SS_ID='' #snapshot ID
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_CHILD_SNAPSHOT_ID='' #current VAR_SS_ID child snapshot

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 "<vmName> <snapshotName=\$COMMON_CONST_PROJECT_NAME | \
\$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME> [host=\$COMMON_CONST_ESXI_HOST] [removeChildren=1]" \
"myvm $COMMON_CONST_PROJECT_NAME $COMMON_CONST_ESXI_HOST 1" \
"Required allowing SSH access on the remote host. Available standard snapshotName: $COMMON_CONST_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_REMOVECHILD=${4:-$COMMON_CONST_TRUE}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOTNAME" "$COMMON_CONST_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'removeChildren' "$PRM_REMOVECHILD" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

#check vm name
VAR_VM_ID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VMNAME not found on $PRM_HOST host"
fi
#check snapshotName
VAR_SS_ID=$(getVMSnapshotIDByName "$VAR_VM_ID" "$PRM_SNAPSHOTNAME" "$PRM_HOST") || exitChildError "$VAR_SS_ID"
if isEmpty "$VAR_SS_ID"; then
  exitError "snapshot $PRM_SNAPSHOTNAME not found for VM $PRM_VMNAME on $PRM_HOST host"
fi
#power off
VAR_RESULT=$(powerOffVM "$VAR_VM_ID" "$PRM_HOST") || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#remove VAR_SS_ID child snapshots
if isTrue "$PRM_REMOVECHILD"; then
  VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPool "$VAR_VM_ID" "$PRM_SNAPSHOTNAME" "$VAR_SS_ID" "$PRM_HOST") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
  for VAR_CHILD_SNAPSHOT_ID in $VAR_CHILD_SNAPSHOTS_POOL; do
    echo "Delete child snapshot:" $VAR_CHILD_SNAPSHOT_ID
    $SSH_CLIENT $PRM_HOST "vim-cmd vmsvc/snapshot.remove $VAR_VM_ID $VAR_CHILD_SNAPSHOT_ID 1"
    if ! isRetValOK; then exitError; fi
  done
fi
#revert VAR_SS_ID snapshot
$SSH_CLIENT $PRM_HOST "vim-cmd vmsvc/snapshot.revert $VAR_VM_ID $VAR_SS_ID 1"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
