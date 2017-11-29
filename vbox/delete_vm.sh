#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Delete VM from the virtual box'

##private consts
readonly CONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VIRTUALBOX_VM_TYPE

##private vars
PRM_VM_NAME='' #vm name
VAR_RESULT='' #child return value
VAR_VM_ID='' #VMID target virtual machine
VAR_CUR_DIR_PATH='' #current directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<vmName>' "myvm" ""

###check commands

PRM_VM_NAME=$1
PRM_ESXI_HOST=${2:-$COMMON_CONST_ESXI_HOST}

checkCommandExist 'vmName' "$PRM_VM_NAME" ''

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check vm name
VAR_VM_ID=$(getVMIDByVMNameVb "$PRM_VM_NAME") || exitChildError "$VAR_VM_ID"
if isEmpty "$VAR_VM_ID"; then
  exitError "VM $PRM_VM_NAME not found"
fi
#power off
VAR_RESULT=$(powerOffVMVb "$PRM_VM_NAME") || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#delete vm
VAR_CUR_DIR_PATH=$PWD
cd "$CONST_LOCAL_VMS_PATH/$PRM_VM_NAME"
checkRetValOK
vagrant destroy -f
checkRetValOK
cd $VAR_CUR_DIR_PATH
checkRetValOK
rm -fR "$CONST_LOCAL_VMS_PATH/$PRM_VM_NAME"
checkRetValOK

doneFinalStage
exitOK
