#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Delete VM on remote esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_HOST='' #host
RET_VAL='' #child return value
VM_ID='' #VMID target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmName> [host=$COMMON_CONST_ESXI_HOST]' "myvm $COMMON_CONST_ESXI_HOST" ""

###check commands

PRM_VMNAME=$1
PRM_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmName' "$PRM_VMNAME" ''

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

VM_ID=$(getVMIDByVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$VM_ID"
#check vm name
if isEmpty "$VM_ID"
then
  exitError "VM $PRM_VMNAME not found on $PRM_HOST host"
fi
#try standard power off if vm running
powerOffVM "$VM_ID" "$PRM_HOST"
if ! isRetValOK; then exitError; fi
#delete vm
$SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd vmsvc/destroy $VM_ID"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
