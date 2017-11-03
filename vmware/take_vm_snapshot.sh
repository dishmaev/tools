#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Take VM standard snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOTNAME='' #snapshotName
PRM_HOST='' #host
PRM_SNAPSHOTDESCRIPTION='' #snapshotDescription
PRM_INCLUDEMEMORY=0 #includeMemory
PRM_QUIESCED=0 #quiesced
VM_ID='' #VMID target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 6 '<vmName> <snapshotName> [snapshotDescription] [host=$COMMON_CONST_ESXI_HOST] [includeMemory=0] [quiesced=0]' \
      "myvm snapshot1 'my description' $COMMON_CONST_ESXI_HOST 0 0" \
      "Required allowing SSH access on the remote host. Available standard snapshotName: $COMMON_CONST_PROJECTNAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_SNAPSHOTDESCRIPTION=$3
PRM_HOST=${4:-$COMMON_CONST_ESXI_HOST}
PRM_INCLUDEMEMORY=${5:-$COMMON_CONST_FALSE}
PRM_QUIESCED=${6:-$COMMON_CONST_FALSE}

checkCommandExist 'vmName' "$PRM_VMNAME" ''
checkCommandExist 'snapshotName' "$PRM_SNAPSHOTNAME" "$COMMON_CONST_PROJECTNAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME"
checkCommandExist 'includeMemory' "$PRM_INCLUDEMEMORY" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'quiesced' "$PRM_QUIESCED" "$COMMON_CONST_BOOL_VALUES"

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
#check snapshotName
if isSnapshotVMExist "$VM_ID" "$PRM_SNAPSHOTNAME" "$PRM_HOST"; then
  exitError "snapshot $PRM_SNAPSHOTNAME already exist for VM $PRM_VMNAME on $PRM_HOST host"
fi

$SSH_CLIENT $PRM_HOST "vim-cmd vmsvc/snapshot.create $VM_ID $PRM_SNAPSHOTNAME \"$PRM_SNAPSHOTDESCRIPTION\" $PRM_INCLUDEMEMORY $PRM_QUIESCED"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
