#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Delete VM template from repository and local directory'

##private consts


##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm version
PRM_RESET_COUNTER='' # reset counter for vm name generate
VAR_RESULT='' #child return value
VAR_VBOX_VERSION='' #vbox version without build number
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_OVA_FILE_NAME='' # ova package name
VAR_OVA_FILE_PATH='' # ova package name with local path
VAR_FILE_URL='' # url for download
VAR_DOWNLOAD_PATH='' #local download path for templates

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION] [resetCounter=$COMMON_CONST_FALSE]' \
    "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}
PRM_RESET_COUNTER=${3:-$COMMON_CONST_FALSE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''
checkCommandExist 'resetCounter' "$PRM_RESET_COUNTER" "$COMMON_CONST_BOOL_VALUES"

if [ "$PRM_VM_TEMPLATE_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  VAR_VM_TEMPLATE_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE" "$COMMON_CONST_VIRTUALBOX_VM_TYPE") || exitChildError "$VAR_VM_TEMPLATE_VER"
else
  VAR_VM_TEMPLATE_VER=$(getAvailableVMTemplateVersions "$PRM_VM_TEMPLATE" "$COMMON_CONST_VIRTUALBOX_VM_TYPE") || exitChildError "$VAR_VM_TEMPLATE_VER"
  checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" "$VAR_VM_TEMPLATE_VER"
  VAR_VM_TEMPLATE_VER=$PRM_VM_TEMPLATE_VERSION
fi

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "$ENV_SCRIPT_DIR_NAME/trigger/${PRM_VM_TEMPLATE}_create.sh"

###start prompt

startPrompt

###body

VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_TEMPLATE_VER}.ova"

VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VIRTUALBOX_VM_TYPE
if isFileExistAndRead "$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"; then
  echo "Deleting local file $VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
  rm "$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME"
fi

doneFinalStage
exitOK
