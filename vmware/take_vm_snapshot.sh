#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Take vm snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_SNAPSHOTNAME='' #snapshotName
PRM_INCLUDEMEMORY=0 #includeMemory
PRM_QUIESCED=0 #quiesced
PRM_HOST='' #host
TARGET_VMID='' #vmid target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmname> <snapshotname> [includememory=0] [quiesced=0] [host=$COMMON_CONST_HVHOST]' \
      "myvm snapshot1 1 0 'description' $COMMON_CONST_HVHOST" \
      "Required allowing SSH access on the remote host"

###check commands

PRM_VMNAME=$1
PRM_SNAPSHOTNAME=$2
PRM_INCLUDEMEMORY=${3:-$COMMON_CONST_FALSE}
PRM_QUIESCED=${4:-$COMMON_CONST_FALSE}
PRM_HOST=${5:-$COMMON_CONST_HVHOST}

checkCommandExist 'vmname' "$PRM_VMNAME" ''
checkCommandExist 'snapshotname' "$PRM_SNAPSHOTNAME" ''
checkCommandValue 'includememory' "$PRM_INCLUDEMEMORY" "$COMMON_CONST_BOOL_VALUES"
checkCommandValue 'quiesced' "$PRM_QUIESCED" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

TARGET_VMID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$TARGET_VMID"
if isEmpty "$TARGET_VMID"
then
  exitError "vm $PRM_VMNAME not found on $PRM_HOST host"
fi

ssh $COMMON_CONST_USER@$PRM_HOST "vim-cmd vmsvc/snapshot.create $TARGET_VMID $PRM_SNAPSHOTNAME '' $PRM_INCLUDEMEMORY $PRM_QUIESCED"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
