#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Power off VMs type $COMMON_CONST_VIRTUALBOX_VM_TYPE"

##private vars
PRM_VMS_POOL='' # vms pool
VAR_RESULT='' #child return value
VAR_VM_NAME='' #current vm
VAR_VM_ID='' #VMID target virtual machine
VAR_TMP_VMS_POOL='' # temp vms pool
VAR_CHECK_RUN_VM='' #check running vm
VAR_CUR_VM='' #vm exp

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[vmsPool=$COMMON_CONST_ALL]' "$COMMON_CONST_ALL" ""

###check commands

PRM_VMS_POOL=${1:-$COMMON_CONST_ALL}

checkCommandExist 'vmsPool' "$PRM_VMS_POOL" ''

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

if [ "$PRM_VMS_POOL" = "$COMMON_CONST_ALL" ]; then
  VAR_TMP_VMS_POOL=$(getVmsPoolVb "$COMMON_CONST_ALL") || exitChildError "$VAR_TMP_VMS_POOL"
  PRM_VMS_POOL=''
  for VAR_CUR_VM in $VAR_TMP_VMS_POOL; do
    VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    PRM_VMS_POOL="$PRM_VMS_POOL $VAR_VM_NAME"
  done
fi

for VAR_VM_NAME in $PRM_VMS_POOL; do
  #check vm name
  VAR_VM_ID=$(getVMIDByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_VM_NAME not found"
  fi
  #power off
  VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
done

doneFinalStage
exitOK
