#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Vagrant on the local OS'

##private consts
CONST_FILE_URL='https://releases.hashicorp.com/vagrant/2.0.0/vagrant_2.0.0_x86_64.deb' #url for download

##private vars
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested only on APT-based Linux. Vagrant url https://www.vagrantup.com/downloads.html"

###check commands

#comments

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

VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_FILE_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $VAR_ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
