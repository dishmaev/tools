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

echoHelp $# 2 '<vmname> [host=$COMMON_CONST_HVHOST]' "myvm $COMMON_CONST_HVHOST" ""

###check commands

PRM_VMNAME=$1
PRM_HOST=${2:-$COMMON_CONST_HVHOST}

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
ssh $COMMON_CONST_USER@$PRM_HOST "if [ \"\$(vim-cmd vmsvc/power.getstate $TARGET_VMID | sed -e '1d')\" != 'Power off' ]; then vim-cmd vmsvc/power.off $TARGET_VMID; fi; sleep 2"
if ! isRetValOK; then exitError; fi
#check running
RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "vmdumper -l | grep -i 'displayName=\"$PRM_VMNAME\"' | awk '{print \$1}' | awk -F'/|=' '{print \$(NF)}'") || exitChildError "$RET_VAL"
if ! isEmpty "$RET_VAL"
then #still running, force kill vm
  ssh $COMMON_CONST_USER@$PRM_HOST "esxcli vm process kill --type force --world-id $RET_VAL"
  if ! isRetValOK; then exitError; fi
fi
#delete vm
ssh $COMMON_CONST_USER@$PRM_HOST "vim-cmd vmsvc/destroy $TARGET_VMID"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
