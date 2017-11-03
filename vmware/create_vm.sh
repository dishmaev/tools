#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create new VM on remote esxi host'

##private consts

##private vars
PRM_VMTEMPLATE='' #vm template
PRM_VMNAME='' #vm name
PRM_HOST='' #host
PRM_DATASTOREVM='' #datastore for vm
RET_VAL='' #child return value
CUR_VMVER='' #current vp version
CUR_NUM='' #current number of vm
VM_NAME='' #new vm name
VM_ID='' #vm VMID
OVA_FILE_NAME='' # ova package name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [host=$COMMON_CONST_ESXI_HOST] [vmName=$COMMON_CONST_DEFAULT_VMNAME] [dataStoreVm=$COMMON_CONST_ESXI_DATASTORE_VM]' \
    "$COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_ESXI_HOST $COMMON_CONST_DEFAULT_VMNAME $COMMON_CONST_ESXI_DATASTORE_VM" \
    "Available VM templates: $COMMON_CONST_VMTEMPLATES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_HOST=${2:-$COMMON_CONST_ESXI_HOST}
PRM_VMNAME=${3:-$COMMON_CONST_DEFAULT_VMNAME}
PRM_DATASTOREVM=${4:-$COMMON_CONST_ESXI_DATASTORE_VM}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VMTEMPLATES_POOL"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#get vm template current version
CUR_VMVER=$(getDefaultVMVersion "$PRM_VMTEMPLATE") || exitChildError "$CUR_VMVER"
OVA_FILE_NAME="${PRM_VMTEMPLATE}-${CUR_VMVER}.ova"
#check tools exist
echo "Checking exist tools on $PRM_HOST host"
RET_VAL=$($SSH_CLIENT $PRM_HOST "if [ -d $COMMON_CONST_ESXI_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"; then
  exitError "not found $COMMON_CONST_ESXI_TOOLS_PATH on $PRM_HOST host. Exec '$COMMON_CONST_ROOT_DIR/vmware/create_vm_template.sh $PRM_VMTEMPLATE $PRM_HOST' previously"
fi
#check required ova package on remote esxi host
RET_VAL=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"; then
  exitError "not found VM template ova package $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME on $PRM_HOST host. Exec '$COMMON_CONST_ROOT_DIR/vmware/create_vm_template.sh $PRM_VMTEMPLATE $PRM_HOST' previously"
fi
#check vm name
if [ "$PRM_VMNAME"="$COMMON_CONST_DEFAULT_VMNAME" ]; then
  #get vm number
  CUR_NUM=$($SSH_CLIENT $PRM_HOST "if [ ! -f $COMMON_CONST_ESXI_DATA_PATH/${PRM_VMTEMPLATE}.txt ]; \
  then echo 0 > $COMMON_CONST_ESXI_DATA_PATH/${PRM_VMTEMPLATE}.txt; fi; \
  echo \$((\$(cat $COMMON_CONST_ESXI_DATA_PATH/${PRM_VMTEMPLATE}.txt)+1)) > $COMMON_CONST_ESXI_DATA_PATH/${PRM_VMTEMPLATE}.txt; \
  cat $COMMON_CONST_ESXI_DATA_PATH/${PRM_VMTEMPLATE}.txt") || exitChildError "$CUR_NUM"
  #set new vm name
  VM_NAME="${PRM_VMTEMPLATE}-${CUR_NUM}"
else
  VM_NAME=$PRM_VMNAME
fi
if isVMExist "$VM_NAME" "$PRM_HOST"; then
  exitError "VM with name $VM_NAME already exist on $PRM_HOST host"
fi
#create new vm on remote esxi host
$SSH_CLIENT $PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
    --noSSLVerify -n=$VM_NAME $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME vi://$COMMON_CONST_SCRIPT_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
if ! isRetValOK; then exitError; fi
#take base template snapshot
RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/take_vm_snapshot.sh -y $VM_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME "$OVA_FILE_NAME" $PRM_HOST) || exitChildError "$RET_VAL"
echo "$RET_VAL"
#set autostart new vm
VM_ID=$(getVMIDByVMName "$VM_NAME" "$PRM_HOST") || exitChildError "$VM_ID"
$SSH_CLIENT $PRM_HOST "vim-cmd hostsvc/autostartmanager/update_autostartentry $VM_ID powerOn 120 1 systemDefault 120 systemDefault"
if ! isRetValOK; then exitError; fi
#echo result
echo 'vmname:host:vmid' $VM_NAME:$PRM_HOST:$VM_ID
doneFinalStage
exitOK
