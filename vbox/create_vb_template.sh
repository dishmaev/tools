#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Create virtual box VM template' "$COMMON_CONST_FALSE"

#https://forums.virtualbox.org/viewtopic.php?f=7&t=39967 error locked VM
#https://stackoverflow.com/questions/35169724/vm-in-virtualbox-is-already-locked-for-a-session-or-being-unlocked

#https://www.freshports.org/emulators/virtualbox-ose-additions on FreeBSD

#https://www.sitepoint.com/create-share-vagrant-base-box/ how create base box
#https://www.vagrantup.com/docs/virtualbox/boxes.html creating base box with Debian

#https://unix.stackexchange.com/questions/176687/set-storage-size-on-creation-of-vm-virtualbox resize hdd

#https://eax.me/vboxmanage/
#https://www.virtualbox.org/manual/ch07.html
#https://www.virtualbox.org/manual/ch08.html#vboxmanage-registervm
#https://superuser.com/questions/741734/virtualbox-how-can-i-add-mount-a-iso-image-file-from-command-line

##private consts
readonly CONST_VBOX_GUESTADD_URL='http://download.virtualbox.org/virtualbox/@PRM_VERSION@/VBoxGuestAdditions_@PRM_VERSION@.iso' #url for download
readonly CONST_VBOX_GUESTADD_SCRIPT='install_guest_add.sh'

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_VM_TEMPLATE_VERSION='' #vm version
VAR_RESULT='' #child return value
VAR_VBOX_VERSION='' #vbox version without build number
VAR_DISC_FILE_NAME='' #vbox guest add file name
VAR_DISC_FILE_PATH='' #vbox guest add file name with local path
VAR_VM_TEMPLATE_VER='' #current vm template version
VAR_BOX_FILE_NAME='' #box package name
VAR_BOX_FILE_PATH='' #box package name with local path
VAR_FILE_URL='' #url for download
VAR_DOWNLOAD_PATH='' #local download path for templates
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name
VAR_VAGRANT_FILE_PATH='' #vagrant config file name with local path
VAR_PAUSE_MESSAGE='' #for show message before paused
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vm by ssh
VAR_CONTROLLER_NAME='' #storage controller name
VAR_SCRIPT_FILE_PATH='' #install guest add script file name with local path
VAR_LOG='' #log execute script

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<vmTemplate> [vmTemplateVersion=$COMMON_CONST_DEFAULT_VERSION]' \
    "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE $COMMON_CONST_DEFAULT_VERSION" \
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

checkRequiredFiles "$ENV_SCRIPT_DIR_NAME/../common/trigger/${PRM_VM_TEMPLATE}_create.sh"

###start prompt

startPrompt

###body

if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_CENTOSMINI_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-set $COMMON_CONST_VAGRANT_BASE_USER_NAME not empty password by 'passwd', default is 'vagrant'\n\
-set 'PasswordAuthentication yes' in /etc/ssh/sshd_config\n\
-sudo systemctl reload sshd\n\
-check that ssh and vm tools are correct working, by connect and ping from outside"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ]; then
  VAR_PAUSE_MESSAGE="Manually must be:\n\
-set $COMMON_CONST_VAGRANT_BASE_USER_NAME not empty password by 'sudo passwd $COMMON_CONST_VAGRANT_BASE_USER_NAME'\n\
-set 'PermitRootLogin yes' in /etc/ssh/sshd_config\n\
-set 'PasswordAuthentication yes' in /etc/ssh/sshd_config\n\
-sudo systemctl reload sshd\n\
-set '127.0.0.1       $COMMON_CONST_DEBIANMINI_VM_TEMPLATE' in /etc/hosts\n\
-check that ssh and vm tools are correct working, by connect and ping from outside"
fi

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
VAR_DISC_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_DISC_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_DISC_FILE_NAME
VAR_SCRIPT_FILE_PATH="$ENV_ROOT_DIR/vbox/template/$CONST_VBOX_GUESTADD_SCRIPT"
if ! isFileExistAndRead "$VAR_DISC_FILE_PATH"; then
  wget -O $VAR_DISC_FILE_PATH $VAR_FILE_URL
  checkRetValOK
fi

#get url for current vm template version
VAR_FILE_URL=$(getVMUrl "$PRM_VM_TEMPLATE" "$COMMON_CONST_VIRTUALBOX_VM_TYPE" "$VAR_VM_TEMPLATE_VER") || exitChildError "$VAR_FILE_URL"
VAR_BOX_FILE_NAME="${PRM_VM_TEMPLATE}-${VAR_VM_TEMPLATE_VER}.box"

VAR_DOWNLOAD_PATH=$ENV_DOWNLOAD_PATH/$COMMON_CONST_VIRTUALBOX_VM_TYPE
if ! isDirectoryExist "$VAR_DOWNLOAD_PATH"; then mkdir -p "$VAR_DOWNLOAD_PATH"; fi
VAR_BOX_FILE_PATH=$VAR_DOWNLOAD_PATH/$VAR_BOX_FILE_NAME

if ! isFileExistAndRead "$VAR_BOX_FILE_PATH"; then
  VAR_VAGRANT_FILE_PATH=$ENV_SCRIPT_DIR_NAME/template/${COMMON_CONST_VAGRANT_FILE_NAME}_${PRM_VM_TEMPLATE}
  if ! isFileExistAndRead "$VAR_VAGRANT_FILE_PATH"; then
    printf "Vagrant.configure("2") do |config|\n  config.vm.box = \"@VAR_FILE_URL@\"\n  \
config.vm.provider :virtualbox do |vb|\n    vb.name = \"@PRM_VM_TEMPLATE@\"\n    \
vb.memory = \"$COMMON_CONST_DEFAULT_MEMORY_SIZE\"\n    vb.cpus = \"$COMMON_CONST_DEFAULT_VCPU_COUNT\"\n  end\n  \
config.vm.provision :shell, :path => \"@VAR_SCRIPT_FILE_PATH@\"\n\
end\n" > $VAR_VAGRANT_FILE_PATH
#config.ssh.private_key_path = \"$ENV_SSH_IDENTITY_FILE_NAME\"\n  \
  fi
  #create temporary directory
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  cat $VAR_VAGRANT_FILE_PATH | sed -e "s#@VAR_FILE_URL@#$VAR_FILE_URL#;s#@PRM_VM_TEMPLATE@#$PRM_VM_TEMPLATE#;s#@VAR_SCRIPT_FILE_PATH@#$VAR_SCRIPT_FILE_PATH#" > $VAR_TMP_DIR_PATH/$COMMON_CONST_VAGRANT_FILE_NAME
  checkRetValOK
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #create new vm
  vagrant up --no-provision
  checkRetValOK
  vboxmanage controlvm "$PRM_VM_TEMPLATE" acpipowerbutton
  checkRetValOK
  pausePrompt "Pause 1 of 3: Check guest OS type, virtual hardware on template VM ${PRM_VM_TEMPLATE}. Typically for Linux without GUI: \
vCPUs - $COMMON_CONST_DEFAULT_VCPU_COUNT, Memory - ${COMMON_CONST_DEFAULT_MEMORY_SIZE}MB, HDD - ${COMMON_CONST_DEFAULT_HDD_SIZE}G"
  VAR_CONTROLLER_NAME=$(vboxmanage showvminfo "$PRM_VM_TEMPLATE" | grep -i 'storage controller name' | sed -n 1p | awk -F: '{print $2}' | sed 's/^[ \t]*//') || exitChildError "$VAR_CONTROLLER_NAME"
  if isEmpty "$VAR_CONTROLLER_NAME"; then exitError "storage controller VM ${PRM_VM_TEMPLATE} not found"; fi
  sleep $COMMON_CONST_SLEEP_LONG
  echo "Set VM $PRM_VM_TEMPLATE portcount=2 in storage controller '$VAR_CONTROLLER_NAME' for ISO image file with VirtualBox Guest Additions"
  vboxmanage storagectl "$PRM_VM_TEMPLATE" --name "$VAR_CONTROLLER_NAME" --portcount 2
  checkRetValOK
  sleep $COMMON_CONST_SLEEP_LONG
  echo "Attach $VAR_DISC_FILE_PATH on VM $PRM_VM_TEMPLATE"
  vboxmanage storageattach "$PRM_VM_TEMPLATE" --storagectl "$VAR_CONTROLLER_NAME" --port 1 --device 0 --type dvddrive --medium "$VAR_DISC_FILE_PATH"
  checkRetValOK
  vagrant up --provision-with shell
  checkRetValOK
  vagrant halt
  checkRetValOK
  echo "Detach $VAR_DISC_FILE_PATH on VM $PRM_VM_TEMPLATE"
  vboxmanage storageattach "$PRM_VM_TEMPLATE" --storagectl "$VAR_CONTROLLER_NAME" --port 1 --device 0 --type dvddrive --medium "none"
  checkRetValOK
  vagrant up --no-provision
  checkRetValOK
  echoResult "$VAR_PAUSE_MESSAGE"
  pausePrompt "Pause 2 of 3: Manually make changes on template VM ${PRM_VM_TEMPLATE}"
  VAR_VM_PORT=$(vagrant port --guest $COMMON_CONST_DEFAULT_SSH_PORT) || exitChildError "$VAR_VM_PORT"
  if isEmpty "$VAR_VM_PORT"; then exitError "host machine port, mapped to the guest port $COMMON_CONST_DEFAULT_SSH_PORT of VM ${PRM_VM_TEMPLATE}, not found"; fi
  echo "VM ${PRM_VM_TEMPLATE} ip address: $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  $SSH_COPY_ID -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_BASE_USER_NAME@$COMMON_CONST_VAGRANT_IP_ADDRESS
  checkRetValOK
  $SCP_CLIENT -P $VAR_VM_PORT "$ENV_ROOT_DIR/common/trigger/${PRM_VM_TEMPLATE}_create.sh" $COMMON_CONST_VAGRANT_BASE_USER_NAME@$COMMON_CONST_VAGRANT_IP_ADDRESS:
  checkRetValOK
  echo "Start ${PRM_VM_TEMPLATE}_create.sh executing on template VM ${PRM_VM_TEMPLATE} ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  #exec trigger script
  VAR_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_BASE_USER_NAME@$COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${PRM_VM_TEMPLATE}_create.sh;./${PRM_VM_TEMPLATE}_create.sh $ENV_SSH_USER_NAME $ENV_SSH_USER_PASS $PRM_VM_TEMPLATE $VAR_VM_TEMPLATE_VER; \
if [ -r ${PRM_VM_TEMPLATE}_create.ok ]; then cat ${PRM_VM_TEMPLATE}_create.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_BASE_USER_NAME@$COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${PRM_VM_TEMPLATE}_create.log ]; then cat ${PRM_VM_TEMPLATE}_create.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echo "Stdout:\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_BASE_USER_NAME@$COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${PRM_VM_TEMPLATE}_create.err ]; then cat ${PRM_VM_TEMPLATE}_create.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echo "Stderr:\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${PRM_VM_TEMPLATE}_create.sh on template VM ${PRM_VM_TEMPLATE} ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  fi
  pausePrompt "Pause 3 of 3: Last check template VM ${PRM_VM_TEMPLATE} ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  vagrant halt
  checkRetValOK
  #export box
  vagrant package --base $PRM_VM_TEMPLATE --output $VAR_BOX_FILE_PATH
  checkRetValOK
  vagrant destroy -f
  checkRetValOK
  #remove temporary directory
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
fi

doneFinalStage
exitOK
