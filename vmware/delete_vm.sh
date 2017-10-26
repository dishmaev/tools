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
if ! isRetValOK; then exitError; fi
#delete vm
$SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd vmsvc/destroy $TARGET_VMID"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
