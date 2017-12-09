#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy VirtualBox on the local OS amd64'

##private consts
readonly CONST_LIBVPX3_URL='http://archive.ubuntu.com/ubuntu/pool/main/libv/libvpx/libvpx3_1.5.0-2ubuntu1_amd64.deb' #url for download
readonly CONST_LIBSSL_URL='http://ftp.ru.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u6_amd64.deb' #url for download
readonly CONST_VBOX_VERSION='5.2'
readonly CONST_VBOX_REPO='deb http://download.virtualbox.org/virtualbox/debian yakkety contrib'
readonly CONST_SOURCE_FILE_PATH_APT='/etc/apt/sources.list.d/virtualbox.list'
readonly CONST_SOURCE_FILE_PATH_RPM='/etc/yum.repos.d/virtualbox.repo'

##private vars
PRM_VERSION='' #vbox version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version of boost for download

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_VBOX_VERSION]' "$CONST_VBOX_VERSION" "Version format 'X.X'. While tested only on APT-based Linux. VBoxManage url https://www.virtualbox.org/wiki/Linux_Downloads"

###check commands

PRM_VERSION=${1:-$CONST_VBOX_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

#checkDependencies 'wget'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
#if already deployed, exit OK
if isCommandExist 'vboxmanage'; then
  echoInfo "already deployed"
  vboxmanage --version
  doneFinalStage
  exitOK
fi
if isAPTLinux "$VAR_LINUX_BASED"; then
  checkDependencies 'wget apt apt-key dirmngr'
  #check for vbox repo
  if ! isFileExistAndRead "$CONST_SOURCE_FILE_PATH_APT"; then
    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    checkRetValOK
    echo "$CONST_VBOX_REPO" | sudo tee $CONST_SOURCE_FILE_PATH_APT
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
elif isRPMLinux "$VAR_LINUX_BASED"; then
  #check for vbox repo
  if ! isFileExistAndRead "$CONST_SOURCE_FILE_PATH_RPM"; then
    sudo rpm --import https://www.virtualbox.org/download/oracle_vbox.asc
    checkRetValOK
    sudo yum -y install yum-utils
    checkRetValOK
    sudo yum-config-manager --add-repo http://download.virtualbox.org/virtualbox/rpm/el/virtualbox.repo
    checkRetValOK
  fi
  sudo yum -y install VirtualBox-${PRM_VERSION}
  checkRetValOK
fi

vboxmanage --version

doneFinalStage
exitOK
