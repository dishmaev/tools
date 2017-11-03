#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy VirtualBox on the system'

##private consts
LIBVPX3_URL='http://archive.ubuntu.com/ubuntu/pool/main/libv/libvpx/libvpx3_1.5.0-2ubuntu1_amd64.deb' #url for download
LIBSSL_URL='http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u6_amd64.deb' #url for download
VBOX_VERSION='5.1'
VBOX_REPO='deb http://download.virtualbox.org/virtualbox/debian yakkety contrib'
APT_SOURCE_FILE='/etc/apt/sources.list'

##private vars
LINUX_BASED='' #for checking supported OS
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested only on APT-based Linux. VBoxManage url https://www.virtualbox.org/wiki/Linux_Downloads"

###check commands

#comments

###check body dependencies

checkDependencies 'wget apt dpkg apt-key dirmngr'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#if already deployed, exit OK
if isCommandExist 'vboxmanage'; then
  doneFinalStage
  exitOK
fi
#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$LINUX_BASED"
if ! isAPTLinux $LINUX_BASED; then exitError 'not supported OS'; fi
#check for vbox repo
if ! grep -qF "$VBOX_REPO" "$APT_SOURCE_FILE"; then
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  if ! isRetValOK; then exitError; fi
  echo "$VBOX_REPO" | sudo tee -a $APT_SOURCE_FILE
  if ! isRetValOK; then exitError; fi
  sudo apt update
  if ! isRetValOK; then exitError; fi
fi
#libvpx3
ORIG_FILE_NAME=$(getFileNameFromUrlString "$LIBVPX3_URL")
ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
  wget -O $ORIG_FILE_PATH $LIBVPX3_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi
#libssl 1.0.0
ORIG_FILE_NAME=$(getFileNameFromUrlString "$LIBSSL_URL")
ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
  wget -O $ORIG_FILE_PATH $LIBSSL_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi
#install vbox
if ! isAutoYesMode; then
  sudo apt install virtualbox-$VBOX_VERSION
  if ! isRetValOK; then exitError; fi
else
  sudo apt -y install virtualbox-$VBOX_VERSION
  if ! isRetValOK; then exitError; fi
fi
sudo apt -y install -f
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
