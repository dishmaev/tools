#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create esxi VM'

##private consts

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_NAME='' #vm name
PRM_ESXI_HOST='' #host
PRM_AUTOSTART=$COMMON_CONST_FALSE #enable autostart
PRM_VM_DATASTORE='' #datastore for vm
VAR_RESULT='' #child return value
VAR_VM_VER='' #current vm version
VAR_VM_NUM='' #current number of vm
VAR_VM_NAME='' #new vm name
VAR_VM_ID='' #vm VMID
VAR_OVA_FILE_NAME='' # ova package name
VAR_COUNTER_FILE_NAME='' # counter file name
VAR_COUNTER_FILE_PATH='' # counter file name with local esxi host path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 5 '<vmTemplate> [esxiHost=$COMMON_CONST_ESXI_HOST] [vmName=$COMMON_CONST_DEFAULT_VM_NAME] [autoStart=$COMMON_CONST_FALSE] [vmDataStore=$COMMON_CONST_ESXI_VM_DATASTORE]' \
    "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE $COMMON_CONST_ESXI_HOST $COMMON_CONST_DEFAULT_VM_NAME $COMMON_CONST_FALSE $COMMON_CONST_ESXI_VM_DATASTORE" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_ESXI_HOST=${2:-$COMMON_CONST_ESXI_HOST}
PRM_VM_NAME=${3:-$COMMON_CONST_DEFAULT_VM_NAME}
PRM_AUTOSTART=${4:-$COMMON_CONST_FALSE}
PRM_VM_DATASTORE=${5:-$COMMON_CONST_ESXI_VM_DATASTORE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'esxiHost' "$PRM_ESXI_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'autoStart' "$PRM_AUTOSTART" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'vmDataStore' "$PRM_VM_DATASTORE" ''

###check body dependencies

checkDependencies 'ovftool'
checkUserPassword

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#remove known_hosts file to prevent future script errors
removeKnownHosts

#get vm template current version
VAR_VM_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE" "$COMMON_CONST_VMWARE_VM_TYPE") || exitChildError "$VAR_VM_VER"
VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_VER}.ova"
VAR_COUNTER_FILE_NAME="${PRM_VM_TEMPLATE}_${COMMON_CONST_VMWARE_VM_TYPE}_num.cfg"
VAR_COUNTER_FILE_PATH="$COMMON_CONST_ESXI_DATA_PATH/$VAR_COUNTER_FILE_NAME"
#check tools exist
echoInfo "checking exist tools on $PRM_ESXI_HOST host"
VAR_RESULT=$($SSH_CLIENT $PRM_ESXI_HOST "if [ -d $COMMON_CONST_ESXI_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if ! isTrue "$VAR_RESULT"; then
  exitError "directory $COMMON_CONST_ESXI_TOOLS_PATH not found on $PRM_ESXI_HOST host. Exec 'upgrade_tools_esxi.sh $PRM_ESXI_HOST' previously"
fi
#check required ova package on remote esxi host
VAR_RESULT=$($SSH_CLIENT $PRM_ESXI_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if ! isTrue "$VAR_RESULT"; then
  exitError "VM template package $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME not found on $PRM_ESXI_HOST host. Exec 'create_${COMMON_CONST_VMWARE_VM_TYPE}_template.sh $PRM_VM_TEMPLATE $PRM_ESXI_HOST' previously"
fi
#check vm name
if [ "$PRM_VM_NAME" = "$COMMON_CONST_DEFAULT_VM_NAME" ]; then
  #get vm number
  VAR_VM_NUM=$($SSH_CLIENT $PRM_ESXI_HOST "if [ ! -f $VAR_COUNTER_FILE_PATH ]; \
then echo 0 > $VAR_COUNTER_FILE_PATH; fi; \
echo \$((\$(cat $VAR_COUNTER_FILE_PATH)+1)) > $VAR_COUNTER_FILE_PATH; \
cat $VAR_COUNTER_FILE_PATH") || exitChildError "$VAR_VM_NUM"
  #set new vm name
  VAR_VM_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_NUM}"
else
  VAR_VM_NAME=$PRM_VM_NAME
fi
if isVMExistEx "$VAR_VM_NAME" "$PRM_ESXI_HOST"; then
  exitError "VM with name $VAR_VM_NAME already exist on $PRM_ESXI_HOST host"
fi
#create new vm on remote esxi host
$SSH_CLIENT $PRM_ESXI_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_VM_DATASTORE -dm=thin --acceptAllEulas \
    --noSSLVerify -n=$VAR_VM_NAME $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_ESXI_HOST"
checkRetValOK
#take base template snapshot
echoInfo "create VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/take_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME $VAR_OVA_FILE_NAME $PRM_ESXI_HOST) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
VAR_VM_ID=$(getVMIDByVMNameEx "$VAR_VM_NAME" "$PRM_ESXI_HOST") || exitChildError "$VAR_VM_ID"
#set autostart new vm
if isTrue "$PRM_AUTOSTART"; then
  $SSH_CLIENT $PRM_ESXI_HOST "vim-cmd hostsvc/autostartmanager/update_autostartentry $VAR_VM_ID powerOn 120 1 systemDefault 120 systemDefault"
  checkRetValOK
fi
#echo result
echo 'vmname:esxihost:vmid' $VAR_VM_NAME:$PRM_ESXI_HOST:$VAR_VM_ID

doneFinalStage
exitOK
