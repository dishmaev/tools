#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy VirtualBox on the local OS'

##private consts
readonly CONST_LIBVPX3_URL='http://archive.ubuntu.com/ubuntu/pool/main/libv/libvpx/libvpx3_1.5.0-2ubuntu1_amd64.deb' #url for download
readonly CONST_LIBSSL_URL='http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u6_amd64.deb' #url for download
readonly CONST_VBOX_VERSION='5.1'
readonly CONST_VBOX_REPO='deb http://download.virtualbox.org/virtualbox/debian yakkety contrib'
readonly CONST_APT_SOURCE_FILE='/etc/apt/sources.list'

##private vars
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path

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
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi
#check for vbox repo
if ! grep -qF "$CONST_VBOX_REPO" "$CONST_APT_SOURCE_FILE"; then
  wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
  if ! isRetValOK; then exitError; fi
  echo "$CONST_VBOX_REPO" | sudo tee -a $CONST_APT_SOURCE_FILE
  if ! isRetValOK; then exitError; fi
  sudo apt update
  if ! isRetValOK; then exitError; fi
fi
#libvpx3
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_LIBVPX3_URL")
VAR_ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_LIBVPX3_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $VAR_ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi
#libssl 1.0.0
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_LIBSSL_URL")
VAR_ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_LIBSSL_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $VAR_ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi
#install vbox
if ! isAutoYesMode; then
  sudo apt install virtualbox-$CONST_VBOX_VERSION
  if ! isRetValOK; then exitError; fi
else
  sudo apt -y install virtualbox-$CONST_VBOX_VERSION
  if ! isRetValOK; then exitError; fi
fi
sudo apt -y install -f
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
