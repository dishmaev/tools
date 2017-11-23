#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy VirtualBox on the local OS amd64'

##private consts
readonly CONST_LIBVPX3_URL='http://archive.ubuntu.com/ubuntu/pool/main/libv/libvpx/libvpx3_1.5.0-2ubuntu1_amd64.deb' #url for download
readonly CONST_LIBSSL_URL='http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u6_amd64.deb' #url for download
readonly CONST_VBOX_VERSION='5.1'
readonly CONST_VBOX_REPO='deb http://download.virtualbox.org/virtualbox/debian yakkety contrib'
readonly CONST_APT_SOURCE_FILE_PATH='/etc/apt/sources.list.d/virtualbox.list'

##private vars
PRM_VERSION='' #vbox version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_VBOX_VERSION]' "$CONST_VBOX_VERSION" "Version format 'X.X'. While tested only on APT-based Linux. VBoxManage url https://www.virtualbox.org/wiki/Linux_Downloads"

###check commands

PRM_VERSION=${1:-$CONST_VBOX_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

checkDependencies 'wget apt apt-key dirmngr'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux "$VAR_LINUX_BASED"; then exitError 'not supported OS'; fi
#if already deployed, exit OK
if isCommandExist 'vboxmanage'; then
  echoResult "Already deployed"
  vboxmanage --version
  doneFinalStage
  exitOK
fi
#check for vbox repo
if ! isFileExistAndRead "$CONST_APT_SOURCE_FILE_PATH"; then
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  checkRetValOK
  echo "$CONST_VBOX_REPO" | sudo tee $CONST_APT_SOURCE_FILE_PATH
  checkRetValOK
  sudo apt update
  checkRetValOK
fi
#libvpx3
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_LIBVPX3_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_LIBVPX3_URL
  checkRetValOK
fi
checkDpkgUnlock
sudo apt -y install $VAR_ORIG_FILE_PATH
checkRetValOK
#libssl 1.0.0
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_LIBSSL_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_LIBSSL_URL
  checkRetValOK
  checkDpkgUnlock
fi
sudo apt -y install $VAR_ORIG_FILE_PATH
checkRetValOK
#install vbox
sudo apt -y install virtualbox-$PRM_VERSION
checkRetValOK
sudo apt -y install -f
checkRetValOK

doneFinalStage
exitOK
