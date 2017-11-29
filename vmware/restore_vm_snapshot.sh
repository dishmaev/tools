#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Restore target VM standard snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOT_NAME='' #snapshotName
PRM_ESXI_HOST='' #host
PRM_REMOVE_CHILD='' #remove child target snapshot
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_SS_ID='' #snapshot ID
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_CHILD_SNAPSHOT_ID='' #current VAR_SS_ID child snapshot

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 "<vmName> <snapshotName=\$ENV_PROJECT_NAME | \$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME> \[esxiHost=$COMMON_CONST_ESXI_HOST] [removeChildren=1]" \
"myvm $ENV_PROJECT_NAME $COMMON_CONST_ESXI_HOST 1" \
"Required allowing SSH access on the remote host. Available standard snapshotName: $ENV_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOT_NAME=$2
PRM_ESXI_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_REMOVE_CHILD=${4:-$COMMON_CONST_TRUE}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOT_NAME" "$ENV_PROJECT_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'removeChildren' "$PRM_REMOVE_CHILD" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

#check vm name
VAR_VM_ID=$(getVMIDByVMNameEx "$PRM_VMNAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VMNAME not found on $PRM_ESXI_HOST host"
fi
#check snapshotName
VAR_SS_ID=$(getVMSnapshotIDByName "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_SS_ID"
if isEmpty "$VAR_SS_ID"; then
  exitError "snapshot $PRM_SNAPSHOT_NAME not found for VM $PRM_VMNAME on $PRM_ESXI_HOST host"
fi
#remove VAR_SS_ID child snapshots
if isTrue "$PRM_REMOVE_CHILD"; then
  VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPool "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME" "$VAR_SS_ID" "$PRM_ESXI_HOST") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
  for VAR_CHILD_SNAPSHOT_ID in $VAR_CHILD_SNAPSHOTS_POOL; do
    echo "Delete child snapshot:" $VAR_CHILD_SNAPSHOT_ID
    $SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/snapshot.remove $VAR_VM_ID $VAR_CHILD_SNAPSHOT_ID 1"
    checkRetValOK
  done
fi
#revert VAR_SS_ID snapshot
$SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/snapshot.revert $VAR_VM_ID $VAR_SS_ID 0"
checkRetValOK

doneFinalStage
exitOK
