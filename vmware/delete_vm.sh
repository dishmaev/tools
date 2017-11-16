#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
##private consts


##private vars
PRM_VM_NAME='' #vm name
PRM_ESXI_HOST='' #host
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmName> [esxiHost=$COMMON_CONST_ESXI_HOST]' "myvm $COMMON_CONST_ESXI_HOST" ""

###check commands

PRM_VM_NAME=$1
PRM_ESXI_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

checkSSHKeyExistEsxi "$PRM_ESXI_HOST"

#check vm name
VAR_VM_ID=$(getVMIDByVMName "$PRM_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VM_NAME not found on $PRM_ESXI_HOST host"
fi
#power off
VAR_RESULT=$(powerOffVM "$VAR_VM_ID" "$PRM_ESXI_HOST") || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#delete vm
$SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/destroy $VAR_VM_ID"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
