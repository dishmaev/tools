#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create VM template' "$COMMON_CONST_FALSE"

##private consts

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm version
PRM_HOST='' #host
PRM_VM_DATASTORE='' #datastore for vm
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_OVA_FILE_NAME='' # ova package name
VAR_OVA_FILE_PATH='' # ova package name with local path
VAR_FILE_URL='' # url for download
VAR_RESULT='' #child return value
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_DISC_FILE_PATH='' #vmdk file name with local esxi host path
VAR_DISC_DIR_PATH='' #local esxi host path for template vm
VAR_TMP_FILE_NAME='' #extracted file name
VAR_TMP_FILE_PATH='' #extracted file name with local esxi host path
VAR_TMP_FILE_PATH2='' #extracted file name with local path
VAR_PAUSE_MESSAGE='' #for show message before paused
VAR_CUR_DIR_NAME='' #current directory name
VAR_TMP_DIR_NAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION] [host=$COMMON_CONST_ESXI_HOST] [vmDataStore=$COMMON_CONST_ESXI_VM_DATASTORE]' \
    "$COMMON_CONST_PHOTON_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_ESXI_HOST $COMMON_CONST_ESXI_VM_DATASTORE" \
    "Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_VM_TEMPLATE_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}
PRM_HOST=${3:-$COMMON_CONST_ESXI_HOST}
PRM_VM_DATASTORE=${4:-$COMMON_CONST_ESXI_VM_DATASTORE}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" ''
checkCommandExist 'host' "$PRM_HOST" "$COMMON_CONST_ESXI_HOSTS_POOL"
checkCommandExist 'vmDataStore' "$PRM_VM_DATASTORE" ''

if [ "$PRM_VM_TEMPLATE_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  VAR_VM_TEMPLATE_VER=$(getDefaultVMTemplateVersion "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
else
  VAR_VM_TEMPLATE_VER=$(getAvailableVMTemplateVersions "$PRM_VM_TEMPLATE") || exitChildError "$VAR_VM_TEMPLATE_VER"
  checkCommandExist 'vmTemplateVersion' "$PRM_VM_TEMPLATE_VERSION" "$VAR_VM_TEMPLATE_VER"
  VAR_VM_TEMPLATE_VER=$PRM_VM_TEMPLATE_VERSION
fi

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'ovftool xz p7zip ssh-copy-id dirmngr'

###check required files

###start prompt

startPrompt

###body

#get url for current vm template version
VAR_FILE_URL=$(getVMUrl "$PRM_VM_TEMPLATE" "$VAR_VM_TEMPLATE_VER") || exitChildError "$VAR_FILE_URL"
VAR_OVA_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_TEMPLATE_VER}.ova"
VAR_DISC_DIR_PATH="/vmfs/volumes/$PRM_VM_DATASTORE/$PRM_VM_TEMPLATE"
VAR_DISC_FILE_PATH="$VAR_DISC_DIR_PATH/$PRM_VM_TEMPLATE.vmdk"
#set paused text
if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTON_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-clear default notes from general information\n\
-set root not empty password by 'passwd', default is 'changeme'\n\
-check that ssh and vm tools are correct working, by connect and ping from outside"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is 'osboxes.org'\n\
-rm /etc/apt/trusted.gpg.d/*\n\
-apt-key add /usr/share/keyrings/debian-archive-keyring.gpg\n\
-echo 'deb http://deb.debian.org/debian/ stretch main' >> /etc/apt/sources.list\n\
-apt update\n\
-apt -y install open-vm-tools\n\
-apt -y install openssh-server\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-reboot, check that ssh and vm tools are working"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-install OS in minimal version, without a desktop\n\
-apt -y install open-vm-tools\n\
-apt -y install openssh-server\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-shutdown (not power off!)\n\
-disconnect all CD-ROM images\n\
-power on, check that ssh and vm tools are working"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-install OS in minimal version, without a desktop\n\
-shutdown (not power off!)\n\
-disconnect all CD-ROM images\n\
-power on, check that ssh and vm tools are working"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-set 'PasswordAuthentication yes' in /etc/ssh/sshd_config\n\
-yum -y install open-vm-tools\n\
-reboot, check that ssh and vm tools are working"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
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
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-set root not empty password by 'passwd', default is ''\n\
-change root shell by 'chsh -s /bin/sh'\n\
-echo sshd_enable=\"YES\" >> in /etc/rc.conf\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-export ASSUME_ALWAYS_YES=yes\n\
-pkg install open-vm-tools-nox11\n\
-reboot, check that ssh and vm tools are working"
fi

#update tools
echo "Checking tools version on $PRM_HOST host"
VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/upgrade_tools_esxi.sh -y $PRM_HOST) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"
#check required ova package on remote esxi host
VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if isTrue "$VAR_RESULT"; then
  doneFinalStage
  exitOK
fi
VAR_OVA_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_OVA_FILE_NAME
if ! isFileExistAndRead "$VAR_OVA_FILE_PATH"; then
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
#ptn
  if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTON_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist base ova package on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      $SCP_CLIENT "$VAR_ORIG_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_VM_DATASTORE -dm=thin --acceptAllEulas \
        --noSSLVerify -n=$PRM_VM_TEMPLATE $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_HOST"
    if ! isRetValOK; then exitError; fi
#dbnosb
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      exitError "file '$VAR_ORIG_FILE_PATH' not found, need manually download url http://www.osboxes.org/debian/"
    fi
    VAR_TMP_FILE_NAME=$PRM_VM_TEMPLATE-${VAR_VM_TEMPLATE_VER}.vmdk
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_TMP_FILE_NAME
    #check exist base vmdk disk on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r '$VAR_TMP_FILE_PATH' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      VAR_TMP_FILE_PATH2=$ENV_DOWNLOAD_PATH/$VAR_TMP_FILE_NAME
      if ! isFileExistAndRead "${VAR_TMP_FILE_PATH2}.xz"; then
        echo "Unpack archive $VAR_ORIG_FILE_PATH"
        p7zip -f -c -d "$VAR_ORIG_FILE_PATH" > "$VAR_TMP_FILE_PATH2"
        if ! isRetValOK; then exitError; fi
        echo "Pack archive ${VAR_TMP_FILE_PATH2}.xz"
        xz -2fz $VAR_TMP_FILE_PATH2
        if ! isRetValOK; then exitError; fi
        if ! isFileExistAndRead "${VAR_TMP_FILE_PATH2}.xz"; then
          exitError
        fi
      fi
      $SCP_CLIENT "${VAR_TMP_FILE_PATH2}.xz" $PRM_HOST:${VAR_TMP_FILE_PATH}.xz
      if ! isRetValOK; then exitError; fi
      # unpack xz archive with vmdk disk
      echo "Unpack archive ${VAR_TMP_FILE_PATH}.xz on $PRM_HOST host"
      $SSH_CLIENT $PRM_HOST "xz -dc '${VAR_TMP_FILE_PATH}.xz' > $VAR_TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
    fi
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $PRM_HOST "mkdir $VAR_DISC_DIR_PATH; cp $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VM_TEMPLATE}.vmx $VAR_DISC_DIR_PATH/; vmkfstools -i $VAR_TMP_FILE_PATH -d thin $VAR_DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "vim-cmd solo/registervm $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#dbn
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist source image on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      $SCP_CLIENT "$VAR_ORIG_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $PRM_HOST "mkdir $VAR_DISC_DIR_PATH; vmkfstools -c $COMMON_CONST_ESXI_DEFAULT_HDD_SIZE -d thin $VAR_DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VM_TEMPLATE}.vmx | sed -e \"s#@VAR_DISC_FILE_PATH@#$VAR_TMP_FILE_PATH#\" > $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "vim-cmd solo/registervm $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orl
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    #check exist source image on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      $SCP_CLIENT "$VAR_ORIG_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $PRM_HOST "mkdir $VAR_DISC_DIR_PATH; vmkfstools -c $COMMON_CONST_ESXI_DEFAULT_HDD_SIZE -d thin $VAR_DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VM_TEMPLATE}.vmx | sed -e \"s#@VAR_DISC_FILE_PATH@#$VAR_TMP_FILE_PATH#\" > $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "vim-cmd solo/registervm $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orlbox
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    VAR_TMP_FILE_NAME=$PRM_VM_TEMPLATE$(echo $VAR_VM_TEMPLATE_VER | sed 's/[.-]//g').ova
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_TMP_FILE_NAME
    #check exist base ova on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r '$VAR_TMP_FILE_PATH' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      VAR_TMP_FILE_PATH2=$ENV_DOWNLOAD_PATH/$VAR_TMP_FILE_NAME
      if ! isFileExistAndRead "$VAR_TMP_FILE_PATH2"; then
        #check virtual box deploy
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../virtualbox/deploy_vbox.sh -y) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        #check vagrant deploy
        VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../virtualbox/deploy_vagrant.sh -y) || exitChildError "$VAR_RESULT"
        echoResult "$VAR_RESULT"
        #create temporary directory
        VAR_TMP_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_NAME"
        VAR_CUR_DIR_NAME=$PWD
        cd $VAR_TMP_DIR_NAME
        #add vm box file
        vagrant init $PRM_VM_TEMPLATE $VAR_ORIG_FILE_PATH
        if ! isRetValOK; then exitError; fi
        sed -i Vagrantfile -e "/config.vm.box = \"$PRM_VM_TEMPLATE\"/ a\ \n\  config.vm.provider :virtualbox do |vb|\n    vb.name = \"$PRM_VM_TEMPLATE\"\n  end"
        if ! isRetValOK; then exitError; fi
        vagrant up
        if ! isRetValOK; then exitError; fi
        vagrant halt
        if ! isRetValOK; then exitError; fi
        #export ova
        vboxmanage export --ovf10 --manifest --options manifest $PRM_VM_TEMPLATE -o ${PRM_VM_TEMPLATE}_tmp.ova
        if ! isRetValOK; then exitError; fi
        #destroy and remove
        vagrant destroy -f
        if ! isRetValOK; then exitError; fi
        vagrant box remove --force $PRM_VM_TEMPLATE
        if ! isRetValOK; then exitError; fi
        #fix any format error
        ovftool --lax ${PRM_VM_TEMPLATE}_tmp.ova $PRM_VM_TEMPLATE.vmx
        if ! isRetValOK; then exitError; fi
        #make target vm template ova package
        ovftool $PRM_VM_TEMPLATE.vmx $VAR_TMP_FILE_PATH2
        if ! isRetValOK; then exitError; fi
        #remove temporary directory
        cd $VAR_CUR_DIR_NAME
        if ! isRetValOK; then exitError; fi
        rm -fR $VAR_TMP_DIR_NAME
        if ! isRetValOK; then exitError; fi
      fi
      $SCP_CLIENT "$VAR_TMP_FILE_PATH2" $PRM_HOST:$VAR_TMP_FILE_PATH
      if ! isRetValOK; then exitError; fi
    fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_VM_DATASTORE -dm=thin --acceptAllEulas \
--noSSLVerify -n=$PRM_VM_TEMPLATE $VAR_TMP_FILE_PATH vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_HOST"
    if ! isRetValOK; then exitError; fi
#ors
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      exitError "file '$VAR_ORIG_FILE_PATH' not found, need manually download url http://www.oracle.com/technetwork/server-storage/solaris11/downloads/install-2245079.html"
    fi
    #check exist source image on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r $COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      $SCP_CLIENT "$VAR_ORIG_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
    fi
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $PRM_HOST "mkdir $VAR_DISC_DIR_PATH; vmkfstools -c $COMMON_CONST_ESXI_DEFAULT_HDD_SIZE -d thin $VAR_DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    $SSH_CLIENT $PRM_HOST "cat $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VM_TEMPLATE}.vmx | sed -e \"s#@VAR_DISC_FILE_PATH@#$VAR_TMP_FILE_PATH#;s#@DISC_VMTOOLS_FILE_PATH@#$COMMON_CONST_ESXI_VMTOOLS_PATH/solaris.iso#\" > $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "vim-cmd solo/registervm $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
#orsbox
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      exitError "file '$VAR_ORIG_FILE_PATH' not found, need manually download url http://www.oracle.com/technetwork/server-storage/solaris11/downloads/vm-templates-2245495.html/"
    fi
    #check virtual box deploy
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../virtualbox/deploy_vbox.sh -y) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
    #create temporary directory
    VAR_TMP_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_NAME"
    VAR_TMP_FILE_PATH=$VAR_TMP_DIR_NAME/${PRM_VM_TEMPLATE}.ova
    VAR_CUR_DIR_NAME=$PWD
    cd $VAR_TMP_DIR_NAME
    #import primary ova
    vboxmanage import $VAR_ORIG_FILE_PATH --vsys 0 --vmname $PRM_VM_TEMPLATE
    if ! isRetValOK; then exitError; fi
    #power on
    vboxmanage startvm $PRM_VM_TEMPLATE
    if ! isRetValOK; then exitError; fi
    pausePrompt "Pause: Manually open Virtual Box, install OS on VM $PRM_VM_TEMPLATE, and shutdown it"
    #export
    vboxmanage export --ovf10 --manifest --options manifest $PRM_VM_TEMPLATE -o ${PRM_VM_TEMPLATE}_tmp.ova
    if ! isRetValOK; then exitError; fi
    #unregister
    vboxmanage unregistervm $PRM_VM_TEMPLATE --delete
    if ! isRetValOK; then exitError; fi
    #fix any format error
    ovftool --lax ${PRM_VM_TEMPLATE}_tmp.ova $PRM_VM_TEMPLATE.vmx
    if ! isRetValOK; then exitError; fi
    #make target vm template ova package
    ovftool $PRM_VM_TEMPLATE.vmx $VAR_TMP_FILE_PATH
    if ! isRetValOK; then exitError; fi
    #put base ova package on esxi host
    $SCP_CLIENT "$VAR_TMP_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VM_TEMPLATE}.ova
    #remove temporary directory
    cd $VAR_CUR_DIR_NAME
    if ! isRetValOK; then exitError; fi
    rm -fR $VAR_TMP_DIR_NAME
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool -ds=$PRM_VM_DATASTORE -dm=thin --acceptAllEulas \
        --noSSLVerify -n=$PRM_VM_TEMPLATE $COMMON_CONST_ESXI_IMAGES_PATH/${PRM_VM_TEMPLATE}.ova vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_HOST"
    if ! isRetValOK; then exitError; fi
#fbd
  elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
    if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      if ! isRetValOK; then exitError; fi
    fi
    VAR_TMP_FILE_NAME=$PRM_VM_TEMPLATE-${VAR_VM_TEMPLATE_VER}.vmdk
    VAR_TMP_FILE_PATH=$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_TMP_FILE_NAME
    #check exist base vmdk disk on esxi host in the images directory
    VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -r '$VAR_TMP_FILE_PATH' ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
    if ! isTrue "$VAR_RESULT"; then #put if not exist
      $SCP_CLIENT "$VAR_ORIG_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME
      if ! isRetValOK; then exitError; fi
      echo "Unpack archive $VAR_ORIG_FILE_NAME on $PRM_HOST host"
      $SSH_CLIENT $PRM_HOST "xz -dc '$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_ORIG_FILE_NAME' > $VAR_TMP_FILE_PATH"
      if ! isRetValOK; then exitError; fi
    fi
    #make vm template directory, copy vmdk disk
    $SSH_CLIENT $PRM_HOST "mkdir $VAR_DISC_DIR_PATH; cp $COMMON_CONST_ESXI_TEMPLATES_PATH/${PRM_VM_TEMPLATE}.vmx $VAR_DISC_DIR_PATH/; vmkfstools -i $VAR_TMP_FILE_PATH -d thin $VAR_DISC_FILE_PATH"
    if ! isRetValOK; then exitError; fi
    #register template vm
    $SSH_CLIENT $PRM_HOST "vim-cmd solo/registervm $VAR_DISC_DIR_PATH/${PRM_VM_TEMPLATE}.vmx"
    if ! isRetValOK; then exitError; fi
  fi
  #execute trigger when exist
  checkTriggerTemplateVM "$PRM_VM_TEMPLATE" "$PRM_HOST" "$VAR_VM_TEMPLATE_VER" "$VAR_PAUSE_MESSAGE"
  #make ova package
  ovftool --noSSLVerify "vi://$ENV_SSH_USER_NAME:$ENV_OVFTOOL_USER_PASS@$PRM_HOST/$PRM_VM_TEMPLATE" $VAR_OVA_FILE_PATH
  if ! isRetValOK; then exitError; fi
  #delete template vm
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/delete_vm.sh -y $PRM_VM_TEMPLATE $PRM_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  if ! isFileExistAndRead "$VAR_OVA_FILE_PATH"
  then #can't make ova package
    exitError
  fi
fi
#put vm ova packages on esxi host
$SCP_CLIENT "$VAR_OVA_FILE_PATH" $PRM_HOST:$COMMON_CONST_ESXI_IMAGES_PATH/$VAR_OVA_FILE_NAME
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
