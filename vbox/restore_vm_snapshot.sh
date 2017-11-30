#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Restore VM standard snapshot'

##private consts


##private vars
PRM_VM_NAME='' #vm name
PRM_SNAPSHOT_NAME='' #snapshotName
PRM_REMOVE_CHILD=$COMMON_CONST_TRUE #remove child target snapshot
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_SS_ID='' #snapshot ID
VAR_CHILD_SNAPSHOTS_POOL='' #VAR_SS_ID child snapshots_pool, IDs with space delimiter
VAR_CHILD_SNAPSHOT_ID='' #current VAR_SS_ID child snapshot

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 "<vmName> <snapshotName=\$ENV_PROJECT_NAME | \$COMMON_CONST_SNAPSHOT_TEMPLATE_NAME> [removeChildren=1]" \
"myvm $ENV_PROJECT_NAME 1" \
"Required allowing SSH access on the remote host. Available standard snapshotName: $ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VM_NAME=$1
PRM_SNAPSHOT_NAME=$2
PRM_REMOVE_CHILD=${3:-$COMMON_CONST_TRUE}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOT_NAME" "$ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'removeChildren' "$PRM_REMOVE_CHILD" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

#check vm name
VAR_VM_ID=$(getVMIDByVMNameVb "$PRM_VM_NAME") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VM_NAME not found"
fi
#check snapshotName
VAR_SS_ID=$(getVMSnapshotIDByNameVb "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME") || exitChildError "$VAR_SS_ID"
if isEmpty "$VAR_SS_ID"; then
  exitError "snapshot $PRM_SNAPSHOT_NAME not found for VM $PRM_VM_NAME"
fi
#remove VAR_SS_ID child snapshots
if isTrue "$PRM_REMOVE_CHILD"; then
  VAR_CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPoolVb "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME" "$VAR_SS_ID") || exitChildError "$VAR_CHILD_SNAPSHOTS_POOL"
  for VAR_CHILD_SNAPSHOT_ID in $VAR_CHILD_SNAPSHOTS_POOL; do
    echoInfo "delete child snapshot $VAR_CHILD_SNAPSHOT_ID"
    vboxmanage snapshot $VAR_VM_ID delete $VAR_CHILD_SNAPSHOT_ID
    checkRetValOK
  done
fi
#revert VAR_SS_ID snapshot
vboxmanage snapshot $VAR_VM_ID restore $VAR_SS_ID
checkRetValOK

doneFinalStage
exitOK
