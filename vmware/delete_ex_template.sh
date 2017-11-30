#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Delete VM template on esxi hosts pool and from local directory'

##private consts


##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm template version
PRM_RESET_COUNTER='' # reset counter for vm name generate
PRM_ESXI_HOSTS_POOL='' # esxi hosts pool
VAR_RESULT='' #child return value
VAR_HOST='' #current esxi host
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_OVA_FILE_NAME='' # ova package name
VAR_DOWNLOAD_PATH='' #local download path for templates
VAR_COUNTER_FILE_NAME='' # counter file name
VAR_COUNTER_FILE_PATH='' # counter file name with local esxi host path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION] [resetCounter=$COMMON_CONST_FALSE] [esxiHostsPool=$COMMON_CONST_ALL]' \
    "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_FALSE $COMMON_CONST_ALL" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available esxi hosts: $COMMON_CONST_ESXI_HOSTS_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}
PRM_RESET_COUNTER=${3:-$COMMON_CONST_FALSE}
PRM_ESXI_HOSTS_POOL=${4:-$COMMON_CONST_ALL}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''
checkCommandExist 'resetCounter' "$PRM_RESET_COUNTER" "$COMMON_CONST_BOOL_VALUES"
if ! isEmpty "$4"; then
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" "$COMMON_CONST_ESXI_HOSTS_POOL"
else
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" ''
fi

if [ "$PRM_VM_TEMPLATE_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  VAR_VM_TEMPLATE_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE" "$COMMON_CONST_VMWARE_VM_TYPE") || exitChildError "$VAR_VM_TEMPLATE_VER"
else
  VAR_VM_TEMPLATE_VER=$(getAvailableVMTemplateVersions "$PRM_VM_TEMPLATE" "$COMMON_CONST_VMWARE_VM_TYPE") || exitChildError "$VAR_VM_TEMPLATE_VER"
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

VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_TEMPLATE_VER}.ova"
VAR_COUNTER_FILE_NAME="${PRM_VM_TEMPLATE}_${COMMON_CONST_VMWARE_VM_TYPE}_num.cfg"
VAR_COUNTER_FILE_PATH="$COMMON_CONST_ESXI_DATA_PATH/$VAR_COUNTER_FILE_NAME"

if [ "$PRM_ESXI_HOSTS_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_ESXI_HOSTS_POOL=$COMMON_CONST_ESXI_HOSTS_POOL
fi

for VAR_HOST in $PRM_ESXI_HOSTS_POOL; do
  echo "Esxi host:" $VAR_HOST
  checkSSHKeyExistEsxi "$VAR_HOST"
  VAR_RESULT=$($SSH_CLIENT $VAR_HOST "if [ -f $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME ]; \
then rm $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME; fi; if [ "$PRM_RESET_COUNTER" = "$COMMON_CONST_TRUE" ] && \
[ -r "$VAR_COUNTER_FILE_PATH" ]; then rm $VAR_COUNTER_FILE_PATH; fi; echo $COMMON_CONST_TRUE") || exitChildError "$VAR_RESULT"
  if ! isTrue "$VAR_RESULT"; then exitError; fi
done

VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VMWARE_VM_TYPE
if isFileExistAndRead "$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"; then
  echo "Deleting local package file $VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
  rm "$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
fi

doneFinalStage
exitOK
