#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Power on VMs pool'

##private vars
PRM_VMS_POOL='' # vms pool
PRM_ESXI_HOST='' #host
VAR_RESULT='' #child return value
VAR_VM_NAME='' #current vm
VAR_VM_ID='' #VMID target virtual machine
VAR_TMP_VMS_POOL='' # temp vms pool

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[vmsPool=$COMMON_CONST_ALL] [esxiHost=$COMMON_CONST_ESXI_HOST]' "$COMMON_CONST_ALL $COMMON_CONST_ESXI_HOST" ""

###check commands

PRM_VMS_POOL=${1:-$COMMON_CONST_ALL}
PRM_ESXI_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmsPool' "$PRM_VMS_POOL" ''
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

checkSSHKeyExistEsxi "$PRM_ESXI_HOST"

if [ "$PRM_VMS_POOL" = "$COMMON_CONST_ALL" ]; then
  VAR_TMP_VMS_POOL=$(getVmsPoolEsxi "$COMMON_CONST_ALL" "$PRM_ESXI_HOST") || exitChildError "$VAR_TMP_VMS_POOL"
  PRM_VMS_POOL=''
  for CUR_VM in $VAR_TMP_VMS_POOL; do
    VAR_VM_NAME=$(echo "$CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    PRM_VMS_POOL="$PRM_VMS_POOL $VAR_VM_NAME"
  done
fi

for VAR_VM_NAME in $PRM_VMS_POOL; do
  #check vm name
  VAR_VM_ID=$(getVMIDByVMName "$VAR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_VM_NAME not found on $PRM_ESXI_HOST host"
  fi
  #power off
  VAR_RESULT=$(powerOffVM "$VAR_VM_ID" "$PRM_ESXI_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
done

doneFinalStage
exitOK
