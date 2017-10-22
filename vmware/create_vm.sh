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
RET_VAL='' #child return value
CUR_NUM='' #current number of vm
VM_IP='' #new vm ip address
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path
DISK_FILE_PATH='' #vmdk file name with local esxi host path
DISK_DIR_PATH='' #local esxi host path for template vm
TMP_FILE_PATH='' #extracted file name with local esxi host path
PAUSE_MESSAGE='' #for show message before paused
CURRENT_DIRNAME='' #current directory name
TMP_DIRNAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<vmType> [host=$COMMON_CONST_ESXI_HOST] [dataStoreVm=$COMMON_CONST_ESXI_DATASTORE_VM]' \
    "VMwarePhoton $COMMON_CONST_ESXI_HOST $COMMON_CONST_ESXI_DATASTORE_VM" \
    "Support vm types: $COMMON_CONST_VM_TYPES"

###check commands

PRM_VMTYPE=$1
PRM_HOST=${2:-$COMMON_CONST_ESXI_HOST}
PRM_DATASTOREVM=${3:-$COMMON_CONST_ESXI_DATASTORE_VM}

checkCommandValue 'vmType' "$PRM_VMTYPE" "$COMMON_CONST_VM_TYPES"

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'ssh scp xz'

###check required files

checkRequiredFiles "$COMMON_CONST_OVFTOOL_PASS_FILE $COMMON_CONST_SCRIPT_DIRNAME/../common/sshpwd"

###start prompt

startPrompt

###body

DISK_DIR_PATH="/vmfs/volumes/$PRM_DATASTOREVM/$PRM_VMTYPE"
DISK_FILE_PATH="$DISK_DIR_PATH/$PRM_VMTYPE.vmdk"
if [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_PHOTON" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_PHOTON'-'$COMMON_CONST_PHOTON_VERSION.ova
  FILE_URL=$COMMON_CONST_PHOTON_OVA_URL
  PAUSE_MESSAGE="Manualy must be:\n\
-set root not empty password by 'passwd', default is 'changeme'\n\
-reboot vm, check that ssh and vm tools are working"
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_DEBIAN" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_DEBIAN'-'$COMMON_CONST_DEBIAN_VERSION.ova
  FILE_URL=$COMMON_CONST_DEBIAN_VMDK_URL
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_ORACLELINUX" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_ORACLELINUX'-'$COMMON_CONST_ORACLELINUX_VERSION.ova
  FILE_URL=$COMMON_CONST_ORACLELINUX_BOX_URL
  PAUSE_MESSAGE="Manualy must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-set 'PasswordAuthentication yes' in /etc/ssh/sshd_config\n\
-yum -y install open-vm-tools\n\
-reboot vm, check that ssh and vm tools are working"
elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_FREEBSD" ]; then
  OVA_FILE_NAME=$COMMON_CONST_VMTYPE_FREEBSD'-'$COMMON_CONST_FREEBSD_VERSION.ova
  FILE_URL=$COMMON_CONST_FREEBSD_VMDKXZ_URL
  PAUSE_MESSAGE="Manualy must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-echo sshd_enable=\"YES\" >> in /etc/rc.conf\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-setenv ASSUME_ALWAYS_YES yes\n\
-pkg install open-vm-tools-nox11\n\
-reboot vm, check that ssh and vm tools are working"
fi

#update tools
RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/upgrade_tools_esxi.sh -y $PRM_HOST) || exitChildError "$RET_VAL"
echo "$RET_VAL"
#check required ova package on remote esxi host
RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"
then #if not exist, find it localy, or download package and put it on remote esxi host
  OVA_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME
  if ! isFileExistAndRead "$OVA_FILE_PATH"
  then
    ORIG_FILE_NAME=$(getFileNameFromUrlString "$FILE_URL")
    ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
    if [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_PHOTON" ]; then
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        wget -O $ORIG_FILE_PATH $FILE_URL
        if ! isRetValOK; then exitError; fi
      fi
      #check exist base ova package on esxi host in the images directory
      RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
      if ! isTrue "$RET_VAL"; then #put if not exist
        scp "$ORIG_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
        if ! isRetValOK; then exitError; fi
      fi
      #register template vm
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
          --noSSLVerify -n=$PRM_VMTYPE $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME vi://$COMMON_CONST_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
      if ! isRetValOK; then exitError; fi
    elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_DEBIAN" ]; then
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        exitError "file \'$ORIG_FILE_PATH\' not found, need manualy download and unpack url http://www.osboxes.org/debian/"
      fi
      RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ -r '$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
      #check exist base vmdk disk on esxi host in the images directory
      if ! isTrue "$RET_VAL"; then #put if not exist
        scp "$ORIG_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH
        if ! isRetValOK; then exitError; fi
      fi
      #make vm template directory, copy vmdk disk
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "mkdir /vmfs/volumes/$PRM_DATASTOREVM/$PRM_VMTYPE; cp $COMMON_CONST_ESXI_SCRIPTS_PATH/$PRM_VMTYPE.vmx $DISK_DIR_PATH/; vmkfstools -i '$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME' -d thin $DISK_FILE_PATH"
      if ! isRetValOK; then exitError; fi
      #register template vm
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/$PRM_VMTYPE.vmx"
      if ! isRetValOK; then exitError; fi
    elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_ORACLELINUX" ]; then
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        wget -O $ORIG_FILE_PATH $FILE_URL
        if ! isRetValOK; then exitError; fi
      fi
      #check virtual box deploy
      RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../virtualbox/deploy_vbox.sh -y) || exitChildError "$RET_VAL"
      echo "$RET_VAL"

      TMP_DIRNAME=$(mktemp -d) || exitChildError "$TMP_DIRNAME"
#      rm -fR ~/Downloads/test
#      mkdir ~/Downloads/test
#      TMP_DIRNAME=~/Downloads/test

      TMP_FILE_PATH=$TMP_DIRNAME/$PRM_VMTYPE.ova
      CURRENT_DIRNAME=$PWD
      cd $TMP_DIRNAME

      #add vm box file
      vagrant init $PRM_VMTYPE $ORIG_FILE_PATH
      sed -i Vagrantfile -e "/config.vm.box = \"$PRM_VMTYPE\"/ a\ \n\  config.vm.provider :virtualbox do |vb|\n    vb.name = \"$PRM_VMTYPE\"\n  end"
      vagrant up
      vagrant halt
      #export ova
      vboxmanage export --ovf10 --options manifest $PRM_VMTYPE -o ${PRM_VMTYPE}_tmp.ova
      #destroy and remove
      vagrant destroy -f $PRM_VMTYPE
      vagrant box remove $PRM_VMTYPE
      #fix any format error
      ovftool --lax ${PRM_VMTYPE}_tmp.ova $PRM_VMTYPE.vmx
      #make target vm template ova package
      ovftool $PRM_VMTYPE.vmx $TMP_FILE_PATH
      #put base ova package on esxi host
      scp "$TMP_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$PRM_VMTYPE.ova

      rm -fR $TMP_DIRNAME
      cd $CURRENT_DIRNAME

      #register template vm
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
          --noSSLVerify -n=$PRM_VMTYPE $COMMON_CONST_ESXI_IMAGES_PATH/$PRM_VMTYPE.ova vi://$COMMON_CONST_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
      if ! isRetValOK; then exitError; fi
    elif [ "$PRM_VMTYPE" = "$COMMON_CONST_VMTYPE_FREEBSD" ]; then
      if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
        wget -O $ORIG_FILE_PATH $FILE_URL
        if ! isRetValOK; then exitError; fi
      fi
      #check exist base vmdk disk on esxi host in the images directory
      RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
      if ! isTrue "$RET_VAL"; then #put if not exist
        scp "$ORIG_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
        if ! isRetValOK; then exitError; fi
      fi
      # unpack xz archive with vmdk disk, specialy for osboxes debian image
      TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$PRM_VMTYPE.vmdk
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "xz -dc $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME > $TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
      #make vm template directory, copy vmdk disk
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "mkdir /vmfs/volumes/$PRM_DATASTOREVM/$PRM_VMTYPE; cp $COMMON_CONST_ESXI_SCRIPTS_PATH/$PRM_VMTYPE.vmx $DISK_DIR_PATH/; vmkfstools -i $TMP_FILE_PATH -d thin $DISK_FILE_PATH"
      if ! isRetValOK; then exitError; fi
      #register template vm
      $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/$PRM_VMTYPE.vmx"
      if ! isRetValOK; then exitError; fi
    fi
    #execute triggres when exist
    checkTriggerTemplateVM "$PRM_VMTYPE" "$PRM_HOST" "$PAUSE_MESSAGE"
    #make ova package
    ovftool --noSSLVerify "vi://$COMMON_CONST_USER@$PRM_HOST/$PRM_VMTYPE" $OVA_FILE_PATH < $COMMON_CONST_OVFTOOL_PASS_FILE
    if ! isRetValOK; then exitError; fi
    #delete template vm
    RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/delete_vm.sh -y $PRM_VMTYPE $PRM_HOST) || exitChildError "$RET_VAL"
    echo "$RET_VAL"
    if ! isFileExistAndRead "$OVA_FILE_PATH"
    then #can't make/download ova package
      exitError
    fi
  fi
  #put vm ova packages on esxi host
  scp "$OVA_FILE_PATH" $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME
  if ! isRetValOK; then exitError; fi
  CUR_NUM=1
else
  #get vm number
  CUR_NUM=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "cat $COMMON_CONST_ESXI_DATA_PATH/$PRM_VMTYPE") || exitChildError "$CUR_NUM"
fi
#put next vm number
$SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "echo \$(($CUR_NUM+1)) > $COMMON_CONST_ESXI_DATA_PATH/$PRM_VMTYPE"
if ! isRetValOK; then exitError; fi
#create new vm on remote esxi host
$SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
    --noSSLVerify --powerOn -n=$PRM_VMTYPE-$CUR_NUM $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME vi://$COMMON_CONST_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
if isRetValOK
then
  VM_IP=$(getVMIDByVMName "$PRM_VMTYPE-$CUR_NUM" "$PRM_HOST") || exitChildError "$VM_IP"
  VM_IP=$(getIpAddressByVMID "$VM_IP" "$PRM_HOST") || exitChildError "$VM_IP"
  echo 'New VM name / ip:' $PRM_VMTYPE-$CUR_NUM / $VM_IP
  doneFinalStage
  exitOK
else
  exitError
fi
