#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Deploy OS VMware Photon OVA package to esxi host, and power on it'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_PHOTON_OVA_URL='' #url for download os photon ova package if it not exist in $COMMON_CONST_DOWNLOAD_PATH
PRM_HOST='' #host
PRM_DATASTOREVM='' #datastore for vm
OVA_FILE_NAME='' # photon ova package name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmname> [photonOvaUrl=$COMMON_CONST_PHOTON_OVA_URL] [host=$COMMON_CONST_HVHOST] [dataStoreVm=$COMMON_CONST_HV_DATASTORE_VM]' "ptn-svr01 $COMMON_CONST_PHOTON_OVA_URL $COMMON_CONST_HVHOST $COMMON_CONST_HV_DATASTORE_VM" "Download OVFTool url https://www.vmware.com/support/developer/ovf/"

###check commands

PRM_VMNAME=$1
PRM_PHOTON_OVA_URL=${2:-$COMMON_CONST_PHOTON_OVA_URL}
PRM_HOST=${3:-$COMMON_CONST_HVHOST}
PRM_DATASTOREVM=${4:-$COMMON_CONST_HV_DATASTORE_VM}

checkCommandExist 'vmname' "$PRM_VMNAME" ''

###check body dependencies

checkDependencies 'ovftool wget ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

OVA_FILE_NAME=$(getFileNameFromUrlString $PRM_PHOTON_OVA_URL) || exitChildError $OVA_FILE_NAME
OVA_FILE_NAME=$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME
if ! isFileExistAndRead $OVA_FILE_NAME
then
  wget -O $OVA_FILE_NAME $PRM_PHOTON_OVA_URL
fi
if ! isFileExistAndRead $OVA_FILE_NAME
then
  exitError
fi

ovftool -ds=$PRM_DATASTOREVM --acceptAllEulas --noSSLVerify --powerOn --name=$PRM_VMNAME $OVA_FILE_NAME vi://$COMMON_CONST_USER@$PRM_HOST
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
