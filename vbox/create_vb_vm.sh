#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create new virtual box VM'

##private consts

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_NAME='' #vm name
PRM_AUTOSTART=$COMMON_CONST_FALSE #enable autostart
VAR_RESULT='' #child return value
VAR_VBOX_VERSION='' #vbox version without build number
VAR_VBOX_GUESTADD_FILE_NAME='' #vbox guest add file name
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_OVA_FILE_NAME='' #ova package name
VAR_OVA_FILE_PATH='' #ova package name with local path
VAR_FILE_URL='' #url for download
VAR_DOWNLOAD_PATH='' #local download path for templates
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name
VAR_VAGRANT_FILE_PATH='' #vagrant config file name with local path

VAR_COUNTER_FILE_NAME='' # counter file name
VAR_COUNTER_FILE_PATH='' # counter file name with local esxi host path


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmTemplate> [vmName=$COMMON_CONST_DEFAULT_VM_NAME] [autoStart=$COMMON_CONST_FALSE]' \
    "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VM_NAME $COMMON_CONST_FALSE" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_NAME=${2:-$COMMON_CONST_DEFAULT_VM_NAME}
PRM_AUTOSTART=${3:-$COMMON_CONST_FALSE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'autoStart' "$PRM_AUTOSTART" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

###start prompt

startPrompt

###body

#check virtual box deploy
if ! isCommandExist 'vboxmanage'; then
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/deploy_vbox.sh -y) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
fi
#check vagrant deploy
if ! isCommandExist 'vagrant'; then
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/deploy_vagrant.sh -y) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
fi

#get vm template current version
VAR_VM_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE" "$COMMON_CONST_VIRTUALBOX_VM_TYPE") || exitChildError "$VAR_VM_VER"
VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_VER}.ova"
VAR_COUNTER_FILE_NAME="${PRM_VM_TEMPLATE}_${COMMON_CONST_VIRTUALBOX_VM_TYPE}_num.cfg"
VAR_COUNTER_FILE_PATH="$COMMON_CONST_ESXI_DATA_PATH/$VAR_COUNTER_FILE_NAME"

VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VIRTUALBOX_VM_TYPE
VAR_OVA_FILE_PATH=$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME

if ! isFileExistAndRead "$VAR_OVA_FILE_PATH"; then
  exitError "VM template ova package $VAR_OVA_FILE_PATH not found. Exec 'create_${COMMON_CONST_VMWARE_VM_TYPE}_template.sh $PRM_VM_TEMPLATE' previously"
fi

doneFinalStage
exitOK
