#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Restore target VM standard snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOTNAME='' #snapshotName
PRM_HOST='' #host
PRM_REMOVECHILD='' #remove child target snapshot
VM_ID='' #VMID target virtual machine
SS_ID='' #snapshot ID
CHILD_SNAPSHOTS_POOL='' #SS_ID child snapshots_pool, IDs with space delimiter
CUR_CHILD_ID='' #current SS_ID child snapshot

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 "<vmName> <snapshotName=\$COMMON_CONST_PROJECTNAME | \
\$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME> [host=\$COMMON_CONST_ESXI_HOST] [removeChildren=1]" \
"myvm $COMMON_CONST_PROJECTNAME $COMMON_CONST_ESXI_HOST 1" \
"Required allowing SSH access on the remote host. Available standard snapshotName: $COMMON_CONST_PROJECTNAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_REMOVECHILD=${4:-$COMMON_CONST_TRUE}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOTNAME" "$COMMON_CONST_PROJECTNAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'removeChildren' "$PRM_REMOVECHILD" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'ssh'

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

#remove SS_ID child snapshots
if isTrue "$PRM_REMOVECHILD"; then
  CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPool "$VM_ID" "$PRM_SNAPSHOTNAME" "$SS_ID" "$PRM_HOST") || exitChildError "$CHILD_SNAPSHOTS_POOL"
  for CUR_CHILD_ID in $CHILD_SNAPSHOTS_POOL; do
    echo "Delete child snapshot:" $CUR_CHILD_ID
    $SSH_CLIENT $PRM_HOST "vim-cmd vmsvc/snapshot.remove $VM_ID $CUR_CHILD_ID 1"
    if ! isRetValOK; then exitError; fi
  done
fi

#revert SS_ID snapshot
$SSH_CLIENT $PRM_HOST "vim-cmd vmsvc/snapshot.revert $VM_ID $SS_ID 1"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
