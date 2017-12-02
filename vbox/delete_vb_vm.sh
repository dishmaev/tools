#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM type $COMMON_CONST_VBOX_VM_TYPE"

##private consts
readonly CONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VBOX_VM_TYPE

##private vars
PRM_VMS_POOL='' # vms pool
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_CUR_DIR_PATH='' #current directory name
VAR_CUR_VM_NAME='' #vm name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<vmsPool>' "myvm" "VM names must be selected without '*'"

###check commands

PRM_VMS_POOL=$1

checkCommandExist 'vmsPool' "$PRM_VMS_POOL" ''

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

for VAR_CUR_VM_NAME in $PRM_VMS_POOL; do
  #check vm name
  VAR_VM_ID=$(getVMIDByVMNameVb "$VAR_CUR_VM_NAME") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_CUR_VM_NAME not found"
  fi
  #power off
  VAR_RESULT=$(powerOffVMVb "$VAR_CUR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #delete vm
  VAR_CUR_DIR_PATH=$PWD
  cd "$CONST_LOCAL_VMS_PATH/$VAR_CUR_VM_NAME"
  checkRetValOK
  vagrant destroy -f
  checkRetValOK
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
  rm -fR "$CONST_LOCAL_VMS_PATH/$VAR_CUR_VM_NAME"
  checkRetValOK
done

doneFinalStage
exitOK
