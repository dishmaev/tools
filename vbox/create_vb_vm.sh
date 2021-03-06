#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Create VM type $COMMON_CONST_VBOX_VM_TYPE"

##private consts
readonly CONST_LOCAL_VMS_PATH=$COMMON_CONST_LOCAL_VMS_PATH/$COMMON_CONST_VBOX_VM_TYPE

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_NAME='' #vm name
VAR_RESULT='' #child return value
VAR_VM_VER='' #current vm version
VAR_VM_NUM='' #current number of vm
VAR_VM_NAME='' #new vm name
VAR_VM_ID='' #vm VMID
VAR_BOX_FILE_NAME='' #box package name
VAR_BOX_FILE_PATH='' #box package name with local path
VAR_DOWNLOAD_PATH='' #local download path for templates
VAR_CUR_DIR_PATH='' #current directory name
VAR_COUNTER_FILE_NAME='' # counter file name
VAR_COUNTER_FILE_PATH='' # counter file name with local esxi host path


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmTemplate> [vmName=$COMMON_CONST_DEFAULT_VM_NAME]' \
    "$COMMON_CONST_CENTOSMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VM_NAME" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_NAME=${2:-$COMMON_CONST_DEFAULT_VM_NAME}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmName' "$PRM_VM_NAME" ''

###check body dependencies

checkDependencies "$SED"

###check required files

###start prompt

startPrompt

###body

#remove known_hosts file to prevent future script errors
removeKnownHosts

#check virtual box deploy
if ! isCommandExist 'vboxmanage'; then
  exitError "missing command vboxmanage. Try to exec $ENV_ROOT_DIR/vbox/deploy_vbox.sh"
fi
#check vagrant deploy
if ! isCommandExist 'vagrant'; then
  exitError "missing command vagrant. Try to exec $ENV_ROOT_DIR/vbox/deploy_vagrant.sh"
fi
#get vm template current version
VAR_VM_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE" "$COMMON_CONST_VBOX_VM_TYPE") || exitChildError "$VAR_VM_VER"
VAR_BOX_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_VER}.box"
VAR_COUNTER_FILE_NAME="${PRM_VM_TEMPLATE}_${COMMON_CONST_VBOX_VM_TYPE}_num.cfg"
VAR_COUNTER_FILE_PATH="$COMMON_CONST_LOCAL_DATA_PATH/$VAR_COUNTER_FILE_NAME"
VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VBOX_VM_TYPE
VAR_BOX_FILE_PATH=$VAR_DOWNLOAD_PATH/$VAR_BOX_FILE_NAME
#check required ova package on remote esxi host
if ! isFileExistAndRead "$VAR_BOX_FILE_PATH"; then
  exitError "VM template package $VAR_BOX_FILE_PATH not found. Try to exec '$ENV_ROOT_DIR/vbox/create_${COMMON_CONST_VBOX_VM_TYPE}_template.sh $PRM_VM_TEMPLATE'"
fi
#check vm name
if [ "$PRM_VM_NAME" = "$COMMON_CONST_DEFAULT_VM_NAME" ]; then
  #get vm number
  if ! isFileExistAndRead "$VAR_COUNTER_FILE_PATH"; then
    echo 0 > $VAR_COUNTER_FILE_PATH
  fi
  echo $(($(cat $VAR_COUNTER_FILE_PATH)+1)) > $VAR_COUNTER_FILE_PATH
  VAR_VM_NUM=$(cat $VAR_COUNTER_FILE_PATH)
  #set new vm name
  VAR_VM_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_NUM}"
else
  VAR_VM_NAME=$PRM_VM_NAME
fi
if isVMExistVb "$VAR_VM_NAME"; then
  exitError "VM with name $VAR_VM_NAME already exist"
fi
if isDirectoryExist "$CONST_LOCAL_VMS_PATH/$VAR_VM_NAME"; then
  rm -fR "$CONST_LOCAL_VMS_PATH/$VAR_VM_NAME"
  checkRetValOK
fi
mkdir -p "$CONST_LOCAL_VMS_PATH/$VAR_VM_NAME"
checkRetValOK
VAR_CUR_DIR_PATH=$PWD
cd "$CONST_LOCAL_VMS_PATH/$VAR_VM_NAME"
checkRetValOK
vagrant init $PRM_VM_TEMPLATE $VAR_BOX_FILE_PATH
checkRetValOK
$SED -i Vagrantfile -e "/config.vm.box = \"$PRM_VM_TEMPLATE\"/ a\ \n\  config.ssh.private_key_path = \"$ENV_SSH_IDENTITY_FILE_NAME\"\n  config.vm.provider :virtualbox do |vb|\n    vb.name = \"$VAR_VM_NAME\"\n  end"
checkRetValOK
vagrant up
checkRetValOK
vagrant halt
checkRetValOK
cd $VAR_CUR_DIR_PATH
checkRetValOK
#take base template snapshot
echoInfo "create VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/take_${COMMON_CONST_VBOX_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME $VAR_BOX_FILE_NAME) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
VAR_VM_ID=$(getVMIDByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_ID"
#echo result
echo 'vmname:vmid' $VAR_VM_NAME:$VAR_VM_ID

doneFinalStage
exitOK
