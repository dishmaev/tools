#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create new VM on remote esxi host'

##private consts

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_NAME='' #vm name
PRM_HOST='' #host
PRM_VM_DATASTORE='' #datastore for vm
VAR_RESULT='' #child return value
VAR_VM_VER='' #current vm version
VAR_VM_NUM='' #current number of vm
VAR_VM_NAME='' #new vm name
VAR_VM_ID='' #vm VMID
VAR_OVA_FILE_NAME='' # ova package name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [host=$COMMON_CONST_ESXI_HOST] [vmName=$COMMON_CONST_DEFAULT_VM_NAME] [vmDataStore=$COMMON_CONST_ESXI_VM_DATASTORE]' \
    "$COMMON_CONST_PHOTON_VM_TEMPLATE $COMMON_CONST_ESXI_HOST $COMMON_CONST_DEFAULT_VM_NAME $COMMON_CONST_ESXI_VM_DATASTORE" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_HOST=${2:-$COMMON_CONST_ESXI_HOST}
PRM_VM_NAME=${3:-$COMMON_CONST_DEFAULT_VM_NAME}
PRM_VM_DATASTORE=${4:-$COMMON_CONST_ESXI_VM_DATASTORE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'host' "$PRM_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'vmName' "$PRM_VM_NAME" ''
checkCommandExist 'vmDataStore' "$PRM_VM_DATASTORE" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#get vm template current version
VAR_VM_VER=$(getDefaultVMVersion "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VM_VER"
VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_VER}.ova"
#check tools exist
echo "Checking exist tools on $PRM_HOST host"
VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -d $COMMON_CONST_ESXI_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if ! isTrue "$VAR_RESULT"; then
  exitError "not found $COMMON_CONST_ESXI_TOOLS_PATH on $PRM_HOST host. Exec 'upgrade_tools_esxi.sh $PRM_HOST' previously"
fi
#check required ova package on remote esxi host
VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if ! isTrue "$VAR_RESULT"; then
  exitError "not found VM template ova package $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME on $PRM_HOST host. Exec 'create_vm_template.sh $PRM_VM_TEMPLATE $PRM_HOST' previously"
fi
#check vm name
if [ "$PRM_VM_NAME"="$COMMON_CONST_DEFAULT_VM_NAME" ]; then
  #get vm number
  VAR_VM_NUM=$($SSH_CLIENT $PRM_HOST "if [ ! -f $COMMON_CONST_ESXI_DATA_PATH/${PRM_VM_TEMPLATE}.txt ]; \
  then echo 0 > $COMMON_CONST_ESXI_DATA_PATH/${PRM_VM_TEMPLATE}.txt; fi; \
  echo \$((\$(cat $COMMON_CONST_ESXI_DATA_PATH/${PRM_VM_TEMPLATE}.txt)+1)) > $COMMON_CONST_ESXI_DATA_PATH/${PRM_VM_TEMPLATE}.txt; \
  cat $COMMON_CONST_ESXI_DATA_PATH/${PRM_VM_TEMPLATE}.txt") || exitChildError "$VAR_VM_NUM"
  #set new vm name
  VAR_VM_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_NUM}"
else
  VAR_VM_NAME=$PRM_VM_NAME
fi
if isVMExist "$VAR_VM_NAME" "$PRM_HOST"; then
  exitError "VM with name $VAR_VM_NAME already exist on $PRM_HOST host"
fi
#create new vm on remote esxi host
$SSH_CLIENT $PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_VM_DATASTORE -dm=thin --acceptAllEulas \
    --noSSLVerify -n=$VAR_VM_NAME $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_HOST"
if ! isRetValOK; then exitError; fi
#take base template snapshot
VAR_RESULT=$($COMMON_CONST_SCRIPT_DIR_NAME/take_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME "$VAR_OVA_FILE_NAME" $PRM_HOST) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#set autostart new vm
VAR_VM_ID=$(getVMIDByVMName "$VAR_VM_NAME" "$PRM_HOST") || exitChildError "$VAR_VM_ID"
$SSH_CLIENT $PRM_HOST "vim-cmd hostsvc/autostartmanager/update_autostartentry $VAR_VM_ID powerOn 120 1 systemDefault 120 systemDefault"
if ! isRetValOK; then exitError; fi
#echo result
echo 'vmname:host:vmid' $VAR_VM_NAME:$PRM_HOST:$VAR_VM_ID
doneFinalStage
exitOK
