#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Delete VM template on esxi hosts pool and from local directory'

##private consts


##private vars
PRM_VMTEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm template version
PRM_HOSTS_POOL='' # esxi hosts pool
VAR_RESULT='' #child return value
VAR_HOST='' #current esxi host
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_OVA_FILE_NAME='' # ova package name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION] [hostsPool=$COMMON_CONST_ESXI_HOSTS_POOL]' \
    "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION '$COMMON_CONST_ESXI_HOSTS_POOL'" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}
PRM_HOSTS_POOL=${3:-$COMMON_CONST_ESXI_HOSTS_POOL}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''
checkCommandExist 'hostsPool' "$PRM_HOSTS_POOL" ''

if [ "$PRM_VM_TEMPLATE_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  VAR_VM_TEMPLATE_VER=$(getDefaultVMTemplateVersion "$PRM_VMTEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
else
  VAR_VM_TEMPLATE_VER=$(getAvailableVMTemplateVersions "$PRM_VMTEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
  checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" "$VAR_VM_TEMPLATE_VER"
  VAR_VM_TEMPLATE_VER=$PRM_VM_TEMPLATE_VERSION
fi

###check body dependencies

#checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

VAR_OVA_FILE_NAME="${PRM_VMTEMPLATE}-${VAR_VM_TEMPLATE_VER}.ova"

for VAR_HOST in $PRM_HOSTS_POOL; do
  echo "Esxi host:" $VAR_HOST
  checkSSHKeyExistEsxi "$VAR_HOST"
  VAR_RESULT=$($SSH_CLIENT $VAR_HOST "if [ -f $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME ]; then rm $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME; fi; echo $COMMON_CONST_TRUE") || exitChildError "$VAR_RESULT"
  if ! isTrue "$VAR_RESULT"; then exitError; fi
done

if isFileExistAndRead "$ENV_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"; then
  echo "Deleting local file $ENV_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
  rm "$ENV_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
fi

doneFinalStage
exitOK
