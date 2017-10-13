#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Create new power on VM on remote esxi host'

##private consts


##private vars
PRM_VMTYPE='' #vm type
PRM_HOST='' #host
PRM_DATASTOREVM='' #datastore for vm
OVA_FILE_NAME='' # ova package name
OVA_FILE_PATH='' # ova package name with local path
FILE_URL='' # url for download
FILE_NUM='' #vm number for name generation
RET_VAL='' #child return value
CUR_NUM='' #current number of vm
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path
DISK_FILE_PATH='' #vmdk file name with local esxi host path
DISK_DIR_PATH='' #local esxi host path for template vm
TMP_FILE_PATH='' #extracted file name with local esxi host path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmType> [host=$COMMON_CONST_HVHOST] [dataStoreVm=$COMMON_CONST_HV_DATASTORE_VM]' \
    "VMwarePhoton $COMMON_CONST_HVHOST $COMMON_CONST_HV_DATASTORE_VM" \
    "Support vm types: $COMMON_CONST_VM_TYPES"

###check commands

PRM_VMTYPE=$1
PRM_HOST=${2:-$COMMON_CONST_HVHOST}
PRM_DATASTOREVM=${3:-$COMMON_CONST_HV_DATASTORE_VM}

checkCommandValue 'vmType' "$PRM_VMTYPE" "$COMMON_CONST_VM_TYPES"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'ssh scp xz'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

if [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_PHOTON" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_PHOTON'-'$COMMON_CONST_PHOTON_VERSION.ova
  FILE_NUM=$COMMON_CONST_VMTYPE_PHOTON
  FILE_URL=$COMMON_CONST_PHOTON_OVA_URL
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_DEBIAN" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_DEBIAN'-'$COMMON_CONST_DEBIAN_VERSION.ova
  FILE_NUM=$COMMON_CONST_VMTYPE_DEBIAN
  FILE_URL=$COMMON_CONST_DEBIAN_VMDK_URL
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_ORACLELINUX" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_ORACLELINUX'-'$COMMON_CONST_ORACLELINUX_VERSION.ova
  FILE_NUM=$COMMON_CONST_VMTYPE_ORACLELINUX
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_FREEBSD" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_FREEBSD'-'$COMMON_CONST_FREEBSD_VERSION.ova
  FILE_NUM=$COMMON_CONST_VMTYPE_FREEBSD
  FILE_URL=$COMMON_CONST_FREEBSD_VMDKXZ_URL
fi

#update tools
$COMMON_CONST_SCRIPT_DIRNAME/upgrade_tools_hv.sh -y $PRM_HOST
if ! isRetValOK; then exitError; fi
#check required ova package on remote esxi host
RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"
then #if not exist, find it localy, or download package and put it on remote esxi host
  OVA_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME
  if ! isFileExistAndRead "$OVA_FILE_PATH"
  then
    if [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_PHOTON" ]; then
      wget -O $OVA_FILE_PATH $FILE_URL
    elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_FREEBSD" ]; then
      ORIG_FILE_NAME=$(getFileNameFromUrlString "$FILE_URL")
      ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        wget -O $ORIG_FILE_PATH $FILE_URL
        if ! isRetValOK; then exitError; fi
      fi
      RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_HV_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
      if ! isTrue "$RET_VAL"; then
        scp "$ORIG_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_HV_IMAGES_PATH/$ORIG_FILE_NAME
        if ! isRetValOK; then exitError; fi
      fi
      DISK_DIR_PATH="/vmfs/volumes/$PRM_DATASTOREVM/$COMMON_CONST_VMTYPE_FREEBSD"
      DISK_FILE_PATH="$DISK_DIR_PATH/$COMMON_CONST_VMTYPE_FREEBSD.vmdk"
      TMP_FILE_PATH=$COMMON_CONST_HV_IMAGES_PATH/$COMMON_CONST_VMTYPE_FREEBSD.vmdk
      ssh $COMMON_CONST_USER@$PRM_HOST "xz -dc $COMMON_CONST_HV_IMAGES_PATH/$ORIG_FILE_NAME > $TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
      ssh $COMMON_CONST_USER@$PRM_HOST "mkdir /vmfs/volumes/$PRM_DATASTOREVM/$COMMON_CONST_VMTYPE_FREEBSD; cp $COMMON_CONST_HV_SCRIPTS_PATH/$COMMON_CONST_VMTYPE_FREEBSD.vmx $DISK_DIR_PATH/; vmkfstools -i $TMP_FILE_PATH $DISK_FILE_PATH"
      if ! isRetValOK; then exitError; fi
      #register template vm
      ssh $COMMON_CONST_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/$COMMON_CONST_VMTYPE_FREEBSD.vmx"
      if ! isRetValOK; then exitError; fi
      #make ova package
      ovftool --noSSLVerify "vi://$COMMON_CONST_OVF_USERPASSWORD@$PRM_HOST/$COMMON_CONST_VMTYPE_FREEBSD" $OVA_FILE_PATH
      if ! isRetValOK; then exitError; fi
      #delete template vm
      $COMMON_CONST_SCRIPT_DIRNAME/delete_vm.sh -y $COMMON_CONST_VMTYPE_FREEBSD $PRM_HOST
    elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_DEBIAN" ]; then
      ORIG_FILE_NAME=$(getFileNameFromUrlString "$FILE_URL")
      ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        exitError "file $ORIG_FILE_PATH not found, need manualy download and unpack url http://www.osboxes.org/debian/"
      fi
      exitOK
    fi
    if ! isRetValOK; then exitError; fi
    if ! isFileExistAndRead "$OVA_FILE_PATH"
    then #can't make/download ova package
      exitError
    fi
  fi
  #put vm ova packages on esxi host
  scp "$OVA_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME
  if ! isRetValOK; then exitError; fi
  #put start number for new vm type
  ssh $COMMON_CONST_USER@$PRM_HOST "echo 1 > $COMMON_CONST_HV_DATA_PATH/$FILE_NUM"
  if ! isRetValOK; then exitError; fi
  CUR_NUM=1
else
  #get vm number
  CUR_NUM=$(ssh $COMMON_CONST_USER@$PRM_HOST "cat $COMMON_CONST_HV_DATA_PATH/$FILE_NUM") || exitChildError "$CUR_NUM"
fi
#put next vm number
ssh $COMMON_CONST_USER@$PRM_HOST "echo \$(($CUR_NUM+1)) > $COMMON_CONST_HV_DATA_PATH/$FILE_NUM"
if ! isRetValOK; then exitError; fi
#create new vm on remote esxi host
ssh $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_HV_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM --acceptAllEulas \
    --noSSLVerify --powerOn -n=$FILE_NUM-$CUR_NUM $COMMON_CONST_HV_IMAGES_PATH/$OVA_FILE_NAME vi://$COMMON_CONST_OVF_USERPASSWORD@$PRM_HOST"
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
