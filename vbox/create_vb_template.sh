#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create virtual box VM template' "$COMMON_CONST_FALSE"

##private consts


##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm version
VAR_RESULT='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION]' \
    "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION" "tooltip"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''

if [ "$PRM_VM_TEMPLATE_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  VAR_VM_TEMPLATE_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
else
  VAR_VM_TEMPLATE_VER=$(getAvailableVMTemplateVersions "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
  checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" "$VAR_VM_TEMPLATE_VER"
  VAR_VM_TEMPLATE_VER=$PRM_VM_TEMPLATE_VERSION
fi

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

checkRequiredFiles "$ENV_SCRIPT_DIR_NAME/trigger/${PRM_VM_TEMPLATE}_create.sh"

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

doneFinalStage
exitOK
