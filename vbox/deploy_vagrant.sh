#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Vagrant on the local OS x86_64'

##private consts
readonly CONST_FILE_APT_URL='https://releases.hashicorp.com/vagrant/@PRM_VERSION@/vagrant_@PRM_VERSION@_x86_64.deb' #url for download
readonly CONST_FILE_RPM_URL='https://releases.hashicorp.com/vagrant/@PRM_VERSION@/vagrant_@PRM_VERSION@_x86_64.rpm' #RPM-based Linux url for download
readonly CONST_FILE_VERSION='2.0.1'

##private vars
PRM_VERSION='' #vagrant version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version of boost for download
VAR_VERSION='' #current version

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' \
"$CONST_FILE_VERSION" \
"Version format 'X.X.X'. While tested only on APT-based Linux. Vagrant url https://www.vagrantup.com/downloads.html"

###check commands

PRM_VERSION=${1:-$CONST_FILE_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

checkDependencies 'wget'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#if already deployed, exit OK
if isCommandExist 'vagrant'; then
  VAR_VERSION=$(vagrant --version | cut -d " " -f 2)
  if isNewLocalVersion "$PRM_VERSION" "$VAR_VERSION"; then
    echoWarning "older version $VAR_VERSION is found, skip deploy"
  else
    echoInfo "already deployed"
    vagrant --version
  fi
  doneFinalStage
  exitOK
fi
#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"

if isAPTLinux "$VAR_LINUX_BASED"; then
  VAR_FILE_URL="$CONST_FILE_APT_URL"
elif isRPMLinux "$VAR_LINUX_BASED"; then
  VAR_FILE_URL="$CONST_FILE_RPM_URL"
else
  exitError "unknown Linux based package system"
fi
VAR_FILE_URL=$(echo "$VAR_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#g") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  checkRetValOK
fi
if isAPTLinux "$VAR_LINUX_BASED"; then
  checkDpkgUnlock
  sudo apt -y install $VAR_ORIG_FILE_PATH
  checkRetValOK
elif isRPMLinux "$VAR_LINUX_BASED"; then
  sudo yum -y install $VAR_ORIG_FILE_PATH
  checkRetValOK
fi

vagrant --version

doneFinalStage
exitOK
