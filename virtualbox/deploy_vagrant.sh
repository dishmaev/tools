#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Deploy Vagrant on the system'

##private consts
FILE_URL='https://releases.hashicorp.com/vagrant/2.0.0/vagrant_2.0.0_x86_64.deb' #url for download

##private vars
LINUX_BASED='' #for checking supported OS
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested on APT-based Linux. Vagrant url https://www.vagrantup.com/downloads.html"

###check commands

#comments

###check body dependencies

checkDependencies 'wget'

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
LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$LINUX_BASED"
if ! isAPTLinux $LINUX_BASED; then exitError 'not supported OS'; fi

ORIG_FILE_NAME=$(getFileNameFromUrlString "$FILE_URL")
ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$ORIG_FILE_NAME
if ! isFileExistAndRead "$ORIG_FILE_PATH"; then
  wget -O $ORIG_FILE_PATH $FILE_URL
  if ! isRetValOK; then exitError; fi
fi
sudo dpkg -i $ORIG_FILE_PATH
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
