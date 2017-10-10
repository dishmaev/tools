#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Create new power on VM on remote esxi host'

##private consts


##private vars
PRM_VMNAME='' #vm name
PRM_OVA_PACKAGE_URL='' #url for download os photon ova package if it not exist in $COMMON_CONST_DOWNLOAD_PATH
PRM_HOST='' #host
PRM_DATASTOREVM='' #datastore for vm
OVA_FILE_NAME='' # ova package name
OVA_FILE_PATH='' # ova package name with local path
RET_VAL='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmname> [ovaPackageUrl=$COMMON_CONST_PHOTON_OVA_URL] [host=$COMMON_CONST_HVHOST] [dataStoreVm=$COMMON_CONST_HV_DATASTORE_VM]' \
    "myvm $COMMON_CONST_PHOTON_OVA_URL $COMMON_CONST_HVHOST $COMMON_CONST_HV_DATASTORE_VM" \
    "If OVF Tool required, download and install url https://www.vmware.com/support/developer/ovf/"

###check commands

PRM_VMNAME=$1
PRM_OVA_PACKAGE_URL=${2:-$COMMON_CONST_PHOTON_OVA_URL}
PRM_HOST=${3:-$COMMON_CONST_HVHOST}
PRM_DATASTOREVM=${4:-$COMMON_CONST_HV_DATASTORE_VM}

checkCommandExist 'vmname' "$PRM_VMNAME" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'ssh scp'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check ovftool on remote esxi host
RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "if [ -x $COMMON_CONST_HV_OVFTOOL_PATH/ovftool ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isRetValOK
then
  exitError
fi
if ! isTrue "$RET_VAL"
then #if not exist, put ovftool on remote esxi host
  checkDependencies 'ovftool'
  checkDirectoryForExist "$COMMON_CONST_LOCAL_OVFTOOL_PATH" 'ovftool source '
  scp -r $COMMON_CONST_LOCAL_OVFTOOL_PATH $COMMON_CONST_USER@$PRM_HOST:/vmfs/volumes/$COMMON_CONST_HV_DATASTORE_BASE
  if ! isRetValOK
  then
    exitError
  fi
  ssh $COMMON_CONST_USER@$PRM_HOST "sed -i 's@^#!/bin/bash@#!/bin/sh@' $COMMON_CONST_HV_OVFTOOL_PATH/ovftool"
fi

#check required ova package on remote esxi host
OVA_FILE_NAME=$(getFileNameFromUrlString $PRM_OVA_PACKAGE_URL) || exitChildError "$OVA_FILE_NAME"
RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isRetValOK
then
  exitError
fi
if ! isTrue "$RET_VAL"
then #if not exist, find it localy, or download package and put it on remote esxi host
  OVA_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME
  if ! isFileExistAndRead "$OVA_FILE_PATH"
  then
    wget -O $OVA_FILE_PATH $PRM_OVA_PACKAGE_URL
    if ! isRetValOK
    then
      exitError
    fi
    if ! isFileExistAndRead "$OVA_FILE_PATH"
    then
      exitError
    fi
  fi
  scp "$OVA_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME
  if ! isRetValOK
  then
    exitError
  fi
fi

#create new vm on remote esxi host
ssh $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_HV_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM --acceptAllEulas \
    --noSSLVerify --powerOn -n=$PRM_VMNAME $COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME vi://$COMMON_CONST_USER@$PRM_HOST"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
