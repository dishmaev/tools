#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Create VM for incorp project $COMMON_CONST_PROJECTNAME"

##private consts


##private vars
PRM_VMTEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_VMTYPE='' #vm name
PRM_SCRIPTVERSION='' #version script for create VM
PRM_OVERRIDE_CONFIG=$COMMON_CONST_FALSE #override config if exist
RET_VAL='' #child return value
VMS_POOL='' #vms pool
FOUND=$COMMON_CONST_FALSE #found flag
VM_NAME='' #vm name
ESXI_HOST='' #esxi host
VM_ID='' #vm id
VM_IP='' #vm ip address
SS_ID='' #snapshot id
CHILD_SNAPSHOTS_POOL='' #SS_ID child snapshots_pool, IDs with space delimiter
SCRIPT_FILENAME='' #create script file name
REMOTE_SCRIPT_FILENAME='' #create script file name on remote vm
CONFIG_FILENAME='' #vm config file name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4  '<vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [vmType=$COMMON_CONST_VMWARE_VMTYPE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_VMWARE_VMTYPE $COMMON_CONST_DEFAULT_VERSION" \
"Available VM templates: $COMMON_CONST_VMTEMPLATES_POOL. Available suites: $COMMON_CONST_SUITES_POOL. Available VM types: $COMMON_CONST_VMTYPES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VMTYPE=${3:-$COMMON_CONST_VMWARE_VMTYPE}
PRM_SCRIPTVERSION=${4:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VMTEMPLATES_POOL"
checkCommandExist 'suite' "$PRM_SUITE" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmType' "$PRM_VMTYPE" "$COMMON_CONST_VMTYPES_POOL"
checkCommandExist 'scriptVersion' "$PRM_SCRIPTVERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

SCRIPT_FILENAME=${PRM_VMTEMPLATE}_${PRM_SCRIPTVERSION}_create
checkRequiredFiles "$COMMON_CONST_SCRIPT_DIRNAME/triggers/${SCRIPT_FILENAME}.sh"

CONFIG_FILENAME=${PRM_SUITE}_${PRM_SCRIPTVERSION}
checkFileForNotExist "$COMMON_CONST_SCRIPT_DIRNAME/data/${CONFIG_FILENAME}.txt" 'config '

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

if [ "$PRM_VMTYPE" = "$COMMON_CONST_VMWARE_VMTYPE" ]; then
  echo "Try to find a free VM"
  VMS_POOL=$(getVmsPool "$PRM_VMTEMPLATE") || exitChildError "$VMS_POOL"
  for CUR_VM in $VMS_POOL; do
    VM_NAME=$(echo "$CUR_VM" | awk -F: '{print $1}')
    ESXI_HOST=$(echo "$CUR_VM" | awk -F: '{print $2}')
    VM_ID=$(echo "$CUR_VM" | awk -F: '{print $3}')
    SS_ID=$(getVMSnapshotIDByName "$VM_ID" "$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME" "$ESXI_HOST") || exitChildError "$SS_ID"
    #check snapshotName
    if isEmpty "$SS_ID"
    then
      exitError "snapshot $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME not found for VM $VM_NAME on $ESXI_HOST host"
    fi
    CHILD_SNAPSHOTS_POOL=$(getChildSnapshotsPool "$VM_ID" "$COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME" "$SS_ID" "$ESXI_HOST") || exitChildError "$CHILD_SNAPSHOTS_POOL"
    if isEmpty "$CHILD_SNAPSHOTS_POOL"; then
      FOUND=$COMMON_CONST_TRUE
    fi
  done
  #create new vm required type
  if ! isTrue "$FOUND"; then
    echo "Not found, required new VM"
    ESXI_HOST=$COMMON_CONST_ESXI_HOST
    RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../vmware/create_vm.sh -y $PRM_VMTEMPLATE $ESXI_HOST) || exitChildError "$RET_VAL"
    echo "$RET_VAL"
    VM_NAME=$(echo "$RET_VAL" | grep 'vmname:host:vmid' | awk '{print $2}' | awk -F: '{print $1}') || exitChildError "$VM_NAME"
    VM_ID=$(echo "$RET_VAL" | grep 'vmname:host:vmid' | awk '{print $2}' | awk -F: '{print $3}') || exitChildError "$VM_ID"
    if isEmpty "$VM_NAME" || isEmpty "$VM_ID"; then exitError; fi
  fi
  echo "Current VM name: $VM_NAME"
  RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../vmware/restore_vm_snapshot.sh -y $VM_NAME $COMMON_CONST_ESXI_SNAPSHOT_TEMPLATE_NAME $ESXI_HOST) || exitChildError "$RET_VAL"
  echo "$RET_VAL"
  powerOnVM "$VM_ID" "$ESXI_HOST"
  VM_IP=$(getIpAddressByVMName "$VM_NAME" "$ESXI_HOST") || exitChildError "$VM_IP"
  #copy create script on vm
  REMOTE_SCRIPT_FILENAME=${COMMON_CONST_PROJECTNAME}_$SCRIPT_FILENAME
  $SCP_CLIENT $COMMON_CONST_SCRIPT_DIRNAME/triggers/${SCRIPT_FILENAME}.sh $VM_IP:${REMOTE_SCRIPT_FILENAME}.sh
  if ! isRetValOK; then exitError; fi
  echo "Start ${REMOTE_SCRIPT_FILENAME}.sh executing on VM $VM_NAME ip $VM_IP on $ESXI_HOST host"
  RET_VAL=$($SSH_CLIENT $VM_IP "chmod u+x ${REMOTE_SCRIPT_FILENAME}.sh;./${REMOTE_SCRIPT_FILENAME}.sh $REMOTE_SCRIPT_FILENAME; \
if [ -f ${REMOTE_SCRIPT_FILENAME}.result ]; then cat ${REMOTE_SCRIPT_FILENAME}.result; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$RET_VAL"
  RET_LOG=$($SSH_CLIENT $VM_IP "if [ -f ${REMOTE_SCRIPT_FILENAME}.log ]; then cat ${REMOTE_SCRIPT_FILENAME}.log; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$VAR_LOG"; then echo "$VAR_LOG"; fi
  RET_LOG=$($SSH_CLIENT $VM_IP "if [ -f ${REMOTE_SCRIPT_FILENAME}.err ]; then cat ${REMOTE_SCRIPT_FILENAME}.err; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$VAR_LOG"; then echo "$VAR_LOG"; fi
  if ! isTrue "$RET_VAL"; then
    exitError "failed execute ${REMOTE_SCRIPT_FILENAME}.sh on VM $VM_NAME ip $VM_IP on $ESXI_HOST host"
  fi
  powerOffVM "$VM_ID" "$ESXI_HOST"
  #take project snapshot
  RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../vmware/take_vm_snapshot.sh -y $VM_NAME $COMMON_CONST_PROJECTNAME "$PRM_SCRIPTVERSION" $ESXI_HOST) || exitChildError "$RET_VAL"
  echo "$RET_VAL"
  #save vm config file
  echo $PRM_VMTYPE$COMMON_CONST_DATA_TXT_SEPARATOR\
$PRM_VMTEMPLATE$COMMON_CONST_DATA_TXT_SEPARATOR\
$VM_NAME$COMMON_CONST_DATA_TXT_SEPARATOR$ESXI_HOST > \
$COMMON_CONST_SCRIPT_DIRNAME/data/${CONFIG_FILENAME}.txt
fi

doneFinalStage
exitOK
