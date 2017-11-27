#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create virtual box VM template' "$COMMON_CONST_FALSE"

##private consts
readonly CONST_VBOX_GUESTADD_URL='http://download.virtualbox.org/virtualbox/@PRM_VERSION@/VBoxGuestAdditions_@PRM_VERSION@.iso' #url for download

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm version
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

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION]' \
    "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''

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

VAR_VBOX_VERSION=$(vboxmanage --version | awk -Fr '{print $1}')
VAR_FILE_URL=$(echo "$CONST_VBOX_GUESTADD_URL" | sed -e "s#@PRM_VERSION@#$VAR_VBOX_VERSION#g") || exitChildError "$VAR_FILE_URL"
VAR_VBOX_GUESTADD_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_VBOX_GUESTADD_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  checkRetValOK
fi

#get url for current vm template version
VAR_FILE_URL=$(getVMUrl "$PRM_VM_TEMPLATE" "$COMMON_CONST_VIRTUALBOX_VM_TYPE" "$VAR_VM_TEMPLATE_VER") || exitChildError "$VAR_FILE_URL"
VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_TEMPLATE_VER}.ova"

VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VIRTUALBOX_VM_TYPE
if ! isDirectoryExist "$VAR_DOWNLOAD_PATH"; then mkdir -p "$VAR_DOWNLOAD_PATH"; fi
VAR_OVA_FILE_PATH=$VAR_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME

if ! isFileExistAndRead "$VAR_OVA_FILE_PATH"; then
  VAR_VAGRANT_FILE_PATH=$ENV_SCRIPT_DIR_NAME/template/${COMMON_CONST_VAGRANT_FILE_NAME}_${PRM_VM_TEMPLATE}
  if ! isFileExistAndRead "$VAR_VAGRANT_FILE_PATH"; then
    printf "Vagrant.configure("2") do |config|\n  config.vm.box = \"@VAR_FILE_URL@\"\n  config.vm.provider :virtualbox do |vb|\n    vb.name = \"@PRM_VM_TEMPLATE@\"\n    vb.memory = \"$COMMON_CONST_DEFAULT_MEMORY_SIZE\"\n  end\nend\n" > $VAR_VAGRANT_FILE_PATH
  fi
  #create temporary directory
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  cat $VAR_VAGRANT_FILE_PATH | sed -e "s#@VAR_FILE_URL@#$VAR_FILE_URL#;s#@PRM_VM_TEMPLATE@#$PRM_VM_TEMPLATE#" > $VAR_TMP_DIR_PATH/$COMMON_CONST_VAGRANT_FILE_NAME
  checkRetValOK
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #create new vm
  vagrant up
  checkRetValOK
  vagrant halt
  checkRetValOK
  #export ova
  vboxmanage export --ovf10 --manifest --options manifest $PRM_VM_TEMPLATE -o $VAR_OVA_FILE_PATH
  checkRetValOK
  #destroy and remove
  vagrant destroy -f
  checkRetValOK
#  vagrant box remove --force $PRM_VM_TEMPLATE
#  checkRetValOK
  #remove temporary directory
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
fi

doneFinalStage
exitOK
