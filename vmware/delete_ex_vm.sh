#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM type $COMMON_CONST_VMWARE_VM_TYPE"

##private consts


##private vars
PRM_VMS_POOL='' # vms pool
PRM_ESXI_HOST='' #host
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_CUR_VM_NAME='' #vm name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmsPool> [esxiHost=$COMMON_CONST_ESXI_HOST]' \
"myvm $COMMON_CONST_ESXI_HOST" "VM names must be selected without '*'"

###check commands

PRM_VMS_POOL=$1
PRM_ESXI_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmsPool' "$PRM_VMS_POOL" ''
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

checkSSHKeyExistEsxi "$PRM_ESXI_HOST"

for VAR_CUR_VM_NAME in $PRM_VMS_POOL; do
  #check vm name
  VAR_VM_ID=$(getVMIDByVMNameEx "$VAR_CUR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_CUR_VM_NAME not found on $PRM_ESXI_HOST host"
  fi
  #power off
  VAR_RESULT=$(powerOffVMEx "$VAR_CUR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #delete vm
  $SSH_CLIENT $PRM_ESXI_HOST "vim-cmd vmsvc/destroy $VAR_VM_ID"
  checkRetValOK
done

doneFinalStage
exitOK
