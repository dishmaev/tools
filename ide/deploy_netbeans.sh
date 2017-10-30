#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Deploy NetBeans on the system'

##private consts
FILE_URL='http://download.netbeans.org/netbeans/8.2/final/bundles/netbeans-8.2-javase-linux.sh' #url for download

##private vars
LINUX_BASED='' #for checking supported OS
ORIG_FILE_NAME='' #original file name
ORIG_FILE_PATH='' #original file name with local path


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested only on APT-based Linux. Oracle JDK url https://netbeans.org/downloads/"

###check commands

#comments

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'
checkDependencies 'ssh'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#if already deployed, exit OK
if isCommandExist 'netbeans'; then
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
#for prevent Gtk-Message: Failed to load module "canberra-gtk-module"
if ! apt list --installed | grep -qF "libcanberra-gtk-module"; then
  sudo apt -y install libcanberra-gtk-module
fi
if ! isRetValOK; then exitError; fi
#if gcc not exist, install it
if ! isCommandExist 'gcc'; then
  sudo apt -y install build-essential
  if ! isRetValOK; then exitError; fi
fi
#if gdb not exist, install it
if ! isCommandExist 'gdb'; then
  sudo apt -y install gdb
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
