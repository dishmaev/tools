#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Vagrant on the local OS'

##private consts
CONST_FILE_URL='https://releases.hashicorp.com/vagrant/2.0.0/vagrant_2.0.0_x86_64.deb' #url for download

##private vars
PRM_FILE_URL='' #URL file for download
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[fileUrl=$CONST_FILE_URL]' "$CONST_FILE_URL" "While tested only on APT-based Linux. Vagrant url https://www.vagrantup.com/downloads.html"

###check commands

PRM_FILE_URL=${1:-$CONST_FILE_URL}

checkCommandExist 'fileUrl' "$PRM_FILE_URL" ''

###check body dependencies

checkDependencies 'wget dpkg'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#if already deployed, exit OK
if isCommandExist 'vagrant'; then
  doneFinalStage
  exitOK
fi
#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi

VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$PRM_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $PRM_FILE_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $VAR_ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
