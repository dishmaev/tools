#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Delete VM on remote esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_HOST='' #host
TARGET_VMID='' #vmid target virtual machine
RET_VAL='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmname> [host=$COMMON_CONST_ESXI_HOST]' "myvm $COMMON_CONST_ESXI_HOST" ""

###check commands

PRM_VMNAME=$1
PRM_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmname' "$PRM_VMNAME" ''

###check body dependencies

checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

TARGET_VMID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$TARGET_VMID"
if isEmpty "$TARGET_VMID"
then
  exitError "vm $PRM_VMNAME not found on $PRM_HOST host"
fi
#try standard power off if vm running
powerOffVM "$TARGET_VMID" "$PRM_HOST"
#check running
RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$RET_VAL"
if ! isEmpty "$RET_VAL"
then #still running, force kill vm
  $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "esxcli vm process kill --type force --world-id $RET_VAL"
  if ! isRetValOK; then exitError; fi
fi
#delete vm
$SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "vim-cmd vmsvc/destroy $TARGET_VMID"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
