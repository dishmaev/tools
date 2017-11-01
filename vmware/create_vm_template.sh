#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Create VM template on remote esxi host'

##private consts

##private vars
PRM_VMTEMPLATE='' #vm template
PRM_VMVERSION='' #vm version
PRM_HOST='' #host
PRM_DATASTOREVM='' #datastore for vm
CUR_VMVER='' #current vp version
OVA_FILE_NAME='' # ova package name
OVA_FILE_PATH='' # ova package name with local path
FILE_URL='' # url for download
RET_VAL='' #child return value
INPUT_VAL='' #read input value
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path
DISC_FILE_PATH='' #vmdk file name with local esxi host path
DISK_DIR_PATH='' #local esxi host path for template vm
TMP_FILE_PATH='' #extracted file name with local esxi host path
PAUSE_MESSAGE='' #for show message before paused
CURRENT_DIRNAME='' #current directory name
TMP_DIRNAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [vmVersion=$COMMON_CONST_DEFAULT_VMVERSION] [host=$COMMON_CONST_ESXI_HOST] [dataStoreVm=$COMMON_CONST_ESXI_DATASTORE_VM]' \
    "$COMMON_CONST_PHOTON_VMTEMPLATE $COMMON_CONST_DEFAULT_VMVERSION $COMMON_CONST_ESXI_HOST $COMMON_CONST_ESXI_DATASTORE_VM" \
    "Available VM templates: $COMMON_CONST_VMTEMPLATES_POOL"

###check commands

PRM_VMTEMPLATE=$1
PRM_VMVERSION=${2:-$COMMON_CONST_DEFAULT_VMVERSION}
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_DATASTOREVM=${4:-$COMMON_CONST_ESXI_DATASTORE_VM}

checkCommandExist 'vmTemplate' "$PRM_VMTEMPLATE" "$COMMON_CONST_VMTEMPLATES_POOL"

if [ "$PRM_VMVERSION" = "$COMMON_CONST_DEFAULT_VMVERSION" ]; then
  CUR_VMVER=$(getDefaultVMVersion "$PRM_VMTEMPLATE") || exitChildError "$CUR_VMVER"
else
  CUR_VMVER=$(getAvailableVMVersions "$PRM_VMTEMPLATE") || exitChildError "$CUR_VMVER"
  checkCommandExist 'vmVersion' "$PRM_VMVERSION" "$CUR_VMVER"
  CUR_VMVER=$PRM_VMVERSION
fi

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'xz p7zip ssh-copy-id dirmngr'

###check required files

###start prompt

startPrompt

###body

#get url for current vm type version
FILE_URL=$(getVMUrl "$PRM_VMTEMPLATE" "$CUR_VMVER") || exitChildError "$FILE_URL"
OVA_FILE_NAME="${PRM_VMTEMPLATE}-${CUR_VMVER}.ova"
DISK_DIR_PATH="/vmfs/volumes/$PRM_DATASTOREVM/$PRM_VMTEMPLATE"
DISC_FILE_PATH="$DISK_DIR_PATH/$PRM_VMTEMPLATE.vmdk"
#set paused text
if [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_PHOTON_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is 'changeme'\n\
-reboot, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_DEBIANOSB_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is 'osboxes.org'\n\
-rm /etc/apt/trusted.gpg.d/*\n\
-apt-key add /usr/share/keyrings/debian-archive-keyring.gpg\n\
-echo 'deb http://deb.debian.org/debian/ stretch main' >> /etc/apt/sources.list\n\
-apt update\n\
-apt -y install open-vm-tools\n\
-apt -y install openssh-server\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-reboot, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_DEBIANMINI_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-install OS in minimal version, without a desktop\n\
-rm /etc/apt/trusted.gpg.d/*\n\
-apt-key add /usr/share/keyrings/debian-archive-keyring.gpg\n\
-apt update\n\
-apt -y install open-vm-tools\n\
-apt -y install openssh-server\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-shutdown (not power off!)\n\
-disconnect all CD-ROM images\n\
-power on, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-install OS in minimal version, without a desktop\n\
-shutdown (not power off!)\n\
-disconnect all CD-ROM images\n\
-power on, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-set 'PasswordAuthentication yes' in /etc/ssh/sshd_config\n\
-yum -y install open-vm-tools\n\
-reboot, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-install OS in minimal version, gui is not installed by default for Solaris 11\n\
-bootadm set-menu timeout=10\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config, svcadm refresh network/ssh\n\
-cd /tmp\n\
-gunzip -c /cdrom/vmwaretools/vmware-solaris-tools.tar.gz | tar xf -\n\
-cd vmware-tools-distrib\n\
-./vmware-install.pl, accept default value\n\
-shutdown (not power off!)\n\
-disconnect all CD-ROM images\n\
-power on, check that ssh and vm tools are working"
elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_FREEBSD_VMTEMPLATE" ]; then
  PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-change root shell by 'chsh -s /bin/sh'\n\
-echo sshd_enable=\"YES\" >> in /etc/rc.conf\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-export ASSUME_ALWAYS_YES=yes\n\
-pkg install open-vm-tools-nox11\n\
-reboot, check that ssh and vm tools are working"
fi

#update tools
RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/upgrade_tools_esxi.sh -y $PRM_HOST) || exitChildError "$RET_VAL"
echo "$RET_VAL"
#check required ova package on remote esxi host
RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if isTrue "$RET_VAL"; then
  doneFinalStage
  exitOK
fi
OVA_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$OVA_FILE_NAME
if ! isFileExistAndRead "$OVA_FILE_PATH"; then
  ORIG_FILE_NAME=$(getFileNameFromUrlString "$FILE_URL")
  ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
#ptn
  if [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_PHOTON_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      wget -O $ORIG_FILE_PATH $FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist base ova package on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      $SCP_CLIENT "$ORIG_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
        --noSSLVerify -n=$PRM_VMTEMPLATE $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME vi://$COMMON_CONST_SCRIPT_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
    if ! isRetValOK; then exitError; fi
#dbnosb
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_DEBIANOSB_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      exitError "file '$ORIG_FILE_PATH' not found, need manually download url http://www.osboxes.org/debian/"
    fi
    TMP_FILE_NAME=$PRM_VMTEMPLATE-${CUR_VMVER}.vmdk
    TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$TMP_FILE_NAME
    #check exist base vmdk disk on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r '$TMP_FILE_PATH' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      TMP_FILE_PATH2=$COMMON_CONST_DOWNLOAD_PATH/$TMP_FILE_NAME
      if ! isFileExistAndRead "${TMP_FILE_PATH2}.xz"; then
        echo "Unpack archive $ORIG_FILE_PATH"
        p7zip -f -c -d "$ORIG_FILE_PATH" > "$TMP_FILE_PATH2"
        if ! isRetValOK; then exitError; fi
        echo "Pack archive ${TMP_FILE_PATH2}.xz"
        xz -2fz $TMP_FILE_PATH2
        if ! isRetValOK; then exitError; fi
        if ! isFileExistAndRead "${TMP_FILE_PATH2}.xz"; then
          exitError
        fi
      fi
      $SCP_CLIENT "${TMP_FILE_PATH2}.xz" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:${TMP_FILE_PATH}.xz
      if ! isRetValOK; then exitError; fi
      # unpack xz archive with vmdk disk
      echo "Unpack archive ${TMP_FILE_PATH}.xz on $PRM_HOST host"
      $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "xz -dc '${TMP_FILE_PATH}.xz' > $TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
    fi
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "mkdir $DISK_DIR_PATH; cp $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VMTEMPLATE}.vmx $DISK_DIR_PATH/; vmkfstools -i $TMP_FILE_PATH -d thin $DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#dbn
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_DEBIANMINI_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      wget -O $ORIG_FILE_PATH $FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist source image on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      $SCP_CLIENT "$ORIG_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "mkdir $DISK_DIR_PATH; vmkfstools -c 50G -d thin $DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VMTEMPLATE}.vmx | sed -e \"s#@DISC_FILE_PATH@#$TMP_FILE_PATH#\" > $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orl
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      wget -O $ORIG_FILE_PATH $FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist source image on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      $SCP_CLIENT "$ORIG_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "mkdir $DISK_DIR_PATH; vmkfstools -c 50G -d thin $DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VMTEMPLATE}.vmx | sed -e \"s#@DISC_FILE_PATH@#$TMP_FILE_PATH#\" > $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orlbox
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      wget -O $ORIG_FILE_PATH $FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check virtual box deploy
    RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../virtualbox/deploy_vbox.sh -y) || exitChildError "$RET_VAL"
    echo "$RET_VAL"
    #check vagrant deploy
    RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../virtualbox/deploy_vagrant.sh -y) || exitChildError "$RET_VAL"
    echo "$RET_VAL"
    #create temporary directory
    TMP_DIRNAME=$(mktemp -d) || exitChildError "$TMP_DIRNAME"
    TMP_FILE_PATH=$TMP_DIRNAME/${PRM_VMTEMPLATE}.ova
    CURRENT_DIRNAME=$PWD
    cd $TMP_DIRNAME
    #add vm box file
    vagrant init $PRM_VMTEMPLATE $ORIG_FILE_PATH
    if ! isRetValOK; then exitError; fi
    sed -i Vagrantfile -e "/config.vm.box = \"$PRM_VMTEMPLATE\"/ a\ \n\  config.vm.provider :virtualbox do |vb|\n    vb.name = \"$PRM_VMTEMPLATE\"\n  end"
    if ! isRetValOK; then exitError; fi
    vagrant up
    if ! isRetValOK; then exitError; fi
    vagrant halt
    if ! isRetValOK; then exitError; fi
    #export ova
    vboxmanage export --ovf10 --manifest --options manifest $PRM_VMTEMPLATE -o ${PRM_VMTEMPLATE}_tmp.ova
    if ! isRetValOK; then exitError; fi
    #destroy and remove
    vagrant destroy -f
    if ! isRetValOK; then exitError; fi
    vagrant box remove --force $PRM_VMTEMPLATE
    if ! isRetValOK; then exitError; fi
    #fix any format error
    ovftool --lax ${PRM_VMTEMPLATE}_tmp.ova $PRM_VMTEMPLATE.vmx
    if ! isRetValOK; then exitError; fi
    #make target vm template ova package
    ovftool $PRM_VMTEMPLATE.vmx $TMP_FILE_PATH
    if ! isRetValOK; then exitError; fi
    #put base ova package on esxi host
    $SCP_CLIENT "$TMP_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VMTEMPLATE}.ova
    if ! isRetValOK; then exitError; fi
    #remove temporary directory
    cd $CURRENT_DIRNAME
    if ! isRetValOK; then exitError; fi
    rm -fR $TMP_DIRNAME
    if ! isRetValOK; then exitError; fi

    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
        --noSSLVerify -n=$PRM_VMTEMPLATE $COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VMTEMPLATE}.ova vi://$COMMON_CONST_SCRIPT_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
    if ! isRetValOK; then exitError; fi
#ors
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      exitError "file '$ORIG_FILE_PATH' not found, need manually download url http://www.oracle.com/technetwork/server-storage/solaris11/downloads/install-2245079.html"
    fi
    #check exist source image on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      $SCP_CLIENT "$ORIG_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "mkdir $DISK_DIR_PATH; vmkfstools -c 50G -d thin $DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VMTEMPLATE}.vmx | sed -e \"s#@DISC_FILE_PATH@#$TMP_FILE_PATH#;s#@DISC_VMTOOLS_FILE_PATH@#$COMMON_CONST_ESXI_VMTOOLS_PATH/solaris.iso#\" > $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orsbox
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      exitError "file '$ORIG_FILE_PATH' not found, need manually download url http://www.oracle.com/technetwork/server-storage/solaris11/downloads/vm-templates-2245495.html/"
    fi
    #check virtual box deploy
    RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/../virtualbox/deploy_vbox.sh -y) || exitChildError "$RET_VAL"
    echo "$RET_VAL"
    #create temporary directory
    TMP_DIRNAME=$(mktemp -d) || exitChildError "$TMP_DIRNAME"
    TMP_FILE_PATH=$TMP_DIRNAME/${PRM_VMTEMPLATE}.ova
    CURRENT_DIRNAME=$PWD
    cd $TMP_DIRNAME
    #import primary ova
    vboxmanage import $ORIG_FILE_PATH --vsys 0 --vmname $PRM_VMTEMPLATE
    if ! isRetValOK; then exitError; fi
    #power on
    vboxmanage startvm $PRM_VMTEMPLATE
    if ! isRetValOK; then exitError; fi
    read -r -p "Pause: Manually open Virtual Box, install OS on VM $PRM_VMTEMPLATE, and shutdown it. When you are done, press Enter for resume procedure " INPUT_VAL
    #export
    vboxmanage export --ovf10 --manifest --options manifest $PRM_VMTEMPLATE -o ${PRM_VMTEMPLATE}_tmp.ova
    if ! isRetValOK; then exitError; fi
    #unregister
    vboxmanage unregistervm $PRM_VMTEMPLATE --delete
    if ! isRetValOK; then exitError; fi
    #fix any format error
    ovftool --lax ${PRM_VMTEMPLATE}_tmp.ova $PRM_VMTEMPLATE.vmx
    if ! isRetValOK; then exitError; fi
    #make target vm template ova package
    ovftool $PRM_VMTEMPLATE.vmx $TMP_FILE_PATH
    if ! isRetValOK; then exitError; fi
    #put base ova package on esxi host
    $SCP_CLIENT "$TMP_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VMTEMPLATE}.ova
    #remove temporary directory
    cd $CURRENT_DIRNAME
    if ! isRetValOK; then exitError; fi
    rm -fR $TMP_DIRNAME
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_DATASTOREVM -dm=thin --acceptAllEulas \
        --noSSLVerify -n=$PRM_VMTEMPLATE $COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VMTEMPLATE}.ova vi://$COMMON_CONST_SCRIPT_USER@$PRM_HOST" < $COMMON_CONST_OVFTOOL_PASS_FILE
    if ! isRetValOK; then exitError; fi
#fbd
  elif [ "$PRM_VMTEMPLATE" = "$COMMON_CONST_FREEBSD_VMTEMPLATE" ]; then
    if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
      wget -O $ORIG_FILE_PATH $FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    TMP_FILE_NAME=$PRM_VMTEMPLATE-${CUR_VMVER}.vmdk
    TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$TMP_FILE_NAME
    #check exist base vmdk disk on esxi host in the images directory
    RET_VAL=$($SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "if [ -r '$TMP_FILE_PATH' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
    if ! isTrue "$RET_VAL"; then #put if not exist
      $SCP_CLIENT "$ORIG_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
      echo "Unpack archive $ORIG_FILE_NAME on $PRM_HOST host"
      $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "xz -dc '$COMMON_CONST_ESXI_IMAGES_PATH/$ORIG_FILE_NAME' > $TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
    fi
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "mkdir $DISK_DIR_PATH; cp $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VMTEMPLATE}.vmx $DISK_DIR_PATH/; vmkfstools -i $TMP_FILE_PATH -d thin $DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $COMMON_CONST_SCRIPT_USER@$PRM_HOST "vim-cmd solo/registervm $DISK_DIR_PATH/${PRM_VMTEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
  fi
  #execute trigger when exist
  checkTriggerTemplateVM "$PRM_VMTEMPLATE" "$PRM_HOST" "$CUR_VMVER" "$PAUSE_MESSAGE"
  #make ova package
  ovftool --noSSLVerify "vi://$COMMON_CONST_SCRIPT_USER@$PRM_HOST/$PRM_VMTEMPLATE" $OVA_FILE_PATH < $COMMON_CONST_OVFTOOL_PASS_FILE
  if ! isRetValOK; then exitError; fi
  #delete template vm
  RET_VAL=$($COMMON_CONST_SCRIPT_DIRNAME/delete_vm.sh -y $PRM_VMTEMPLATE $PRM_HOST) || exitChildError "$RET_VAL"
  echo "$RET_VAL"
  if ! isFileExistAndRead "$OVA_FILE_PATH"
  then #can't make ova package
    exitError
  fi
fi
#put vm ova packages on esxi host
$SCP_CLIENT "$OVA_FILE_PATH" $COMMON_CONST_SCRIPT_USER@$PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$OVA_FILE_NAME
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
