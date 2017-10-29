#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Purge VM template on esxi hosts pool'

##private consts


##private vars
PRM_VMTEMPLATE='' #vm template
PRM_VMVERSION='' #vm version
PRM_HOSTS_POOL='' # esxi hosts pool
RET_VAL='' #child return value
CUR_HOST='' #current esxi host
CUR_VMVER='' #current vp version
OVA_FILE_NAME='' # ova package name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmTemplate> [vmVersion=$COMMON_CONST_DEFAULT_VMVERSION] [hostsPool=\$COMMON_CONST_ESXI_HOSTS_POOL]' \
    "$COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_DEFAULT_VMVERSION '$COMMON_CONST_ESXI_HOSTS_POOL'" \
    "Available VM templates: $COMMON_CONST_VMTEMPLATES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_VMVERSION=${2:-$COMMON_CONST_DEFAULT_VMVERSION}
PRM_HOSTS_POOL=${3:-$COMMON_CONST_ESXI_HOSTS_POOL}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VMTEMPLATES_POOL"

if [ "$PRM_VMVERSION" = "$COMMON_CONST_DEFAULT_VMVERSION" ]; then
  CUR_VMVER=$(getDefaultVMVersion "$PRM_VMTEMPLATE") || exitChildError "$CUR_VMVER"
else
  CUR_VMVER=$(getAvailableVMVersions "$PRM_VMTEMPLATE") || exitChildError "$CUR_VMVER"
  checkCommandExist 'vmVersion' "$PRM_VMVERSION" "$CUR_VMVER"
  CUR_VMVER=$PRM_VMVERSION
fi

###check body dependencies

checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

OVA_FILE_NAME="${PRM_VMTEMPLATE}-${CUR_VMVER}.ova"

for CUR_HOST in $PRM_HOSTS_POOL; do
  echo "Target esxi host:" $CUR_HOST
  RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$CUR_HOST "if [ -f $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME ]; then rm $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME; fi; echo $COMMON_CONST_TRUE") || exitChildError "$RET_VAL"
  if ! isTrue "$RET_VAL"; then exitError; fi
done

if [ -f "$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME" ]; then
  echo "Deleting local file $COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME"
  rm "$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME"
fi

doneFinalStage
exitOK
