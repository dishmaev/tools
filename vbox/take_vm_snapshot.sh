#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Take VM standard snapshot'

##private consts


##private vars
PRM_VM_NAME='' #vm name
PRM_SNAPSHOT_NAME='' #snapshotName
PRM_SNAPSHOT_DESCRIPTION='' #snapshotDescription
PRM_INCLUDE_MEMORY=$COMMON_CONST_FALSE #includeMemory
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmName> <snapshotName> [snapshotDescription] [includeMemory=0]' \
      "myvm snapshot1 'my description' 0" \
      "Required allowing SSH access on the remote host. Available standard snapshotName: $ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VM_NAME=$1
PRM_SNAPSHOT_NAME=$2
PRM_SNAPSHOT_DESCRIPTION=${3:-'text'}
PRM_INCLUDE_MEMORY=${3:-$COMMON_CONST_FALSE}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOT_NAME" "$ENV_PROJECT_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'snapshotDescription' "$PRM_SNAPSHOT_DESCRIPTION" ''
checkCommandExist 'includeMemory' "$PRM_INCLUDE_MEMORY" "$COMMON_CONST_BOOL_VALUES"

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
if isSnapshotVMExistVb "$VAR_VM_ID" "$PRM_SNAPSHOT_NAME"; then
  exitError "snapshot $PRM_SNAPSHOT_NAME already exist for VM $PRM_VM_NAME"
fi
#power off
if ! isTrue "$PRM_INCLUDE_MEMORY"; then
  VAR_RESULT=$(powerOffVMVb "$PRM_VM_NAME") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  vboxmanage snapshot $VAR_VM_ID take $PRM_SNAPSHOT_NAME --description \"$PRM_SNAPSHOT_DESCRIPTION\"
  checkRetValOK
else
  vboxmanage snapshot $VAR_VM_ID take $PRM_SNAPSHOT_NAME --description \"$PRM_SNAPSHOT_DESCRIPTION\" --live
  checkRetValOK
fi

doneFinalStage
exitOK
