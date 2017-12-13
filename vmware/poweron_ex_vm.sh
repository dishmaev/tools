#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Power on VMs type $COMMON_CONST_VMWARE_VM_TYPE"

##private vars
PRM_VMS_POOL='' # vms pool
PRM_ESXI_HOST='' #host
VAR_RESULT='' #child return value
VAR_VM_NAME='' #current vm
VAR_VM_ID='' #VMID target virtual machine
VAR_VM_IP='' #vm ip address
VAR_TMP_VMS_POOL='' #temp vms pool
VAR_CUR_VM='' #vm exp

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[vmsPool=$COMMON_CONST_ALL] [esxiHost=$COMMON_CONST_ESXI_HOST]' \
"'$COMMON_CONST_ALL' $COMMON_CONST_ESXI_HOST" "Use '*' or VM names with space delimiter"

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
checkRetValOK

if [ "$PRM_VMS_POOL" = "$COMMON_CONST_ALL" ]; then
  VAR_TMP_VMS_POOL=$(getVmsPoolEx "$COMMON_CONST_ALL" "$PRM_ESXI_HOST") || exitChildError "$PRM_VMS_POOL"
  PRM_VMS_POOL=''
  for VAR_CUR_VM in $VAR_TMP_VMS_POOL; do
    VAR_VM_NAME=$(echo "$VAR_CUR_VM" | awk -F: '{print $1}') || exitChildError "$VAR_VM_NAME"
    PRM_VMS_POOL="$PRM_VMS_POOL $VAR_VM_NAME"
  done
fi

for VAR_VM_NAME in $PRM_VMS_POOL; do
  #check vm name
  VAR_VM_ID=$(getVMIDByVMNameEx "$VAR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_VM_NAME not found on $PRM_ESXI_HOST host"
  fi
  #power on
  VAR_TMP_VMS_POOL=$(powerOnVMEx "$VAR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_TMP_VMS_POOL"
  echoResult "$VAR_TMP_VMS_POOL"
  #get ip address
  VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$PRM_ESXI_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  if ! isEmpty "$VAR_RESULT"; then
    VAR_RESULT="${VAR_RESULT}\n"
  fi
  VAR_RESULT="${VAR_RESULT}vmname:esxihost:vmid:ip $VAR_VM_NAME:$PRM_ESXI_HOST:$VAR_VM_ID:$VAR_VM_IP"
done
#echo result
echoResult "$VAR_RESULT"

doneFinalStage
exitOK
