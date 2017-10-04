#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Take vm snapshot on esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_HOST='' #host
TARGET_VMID='' #vmid target virtual machine

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmname> [host=$COMMON_CONST_HVHOST]' \
      "myvm $COMMON_CONST_HVHOST" \
      "Required allowing SSH access on the remote host"

###check commands

PRM_VMNAME=$1
PRM_HOST=${2:-$COMMON_CONST_HVHOST}

checkCommandExist 'vmname' "$PRM_VMNAME" ''

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

TARGET_VMID=$(getVMIDbyVMName "$PRM_VMNAME" "$PRM_HOST") || exitChildError "$TARGET_VMID"
if isEmpty $TARGET_VMID
then
  exitError "vm $PRM_VMNAME not found on $PRM_HOST host"
fi

doneFinalStage
exitOK
