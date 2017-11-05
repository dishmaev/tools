#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy NetBeans on the local OS'

##private consts
readonly CONST_FILE_URL='http://download.netbeans.org/netbeans/8.2/final/bundles/netbeans-8.2-javase-linux.sh' #url for download

##private vars
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested only on APT-based Linux. Oracle JDK url https://netbeans.org/downloads/"

###check commands

#comments

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

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
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi

VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_FILE_URL")
VAR_ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $CONST_FILE_URL
  if ! isRetValOK; then exitError; fi
  chmod u+x $VAR_ORIG_FILE_PATH
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

echo 'Important! When install NetBeans, in the appropriate dialog set JDK full path directory, for JDK 8 default is /usr/lib/jvm/java-8-oracle'

$VAR_ORIG_FILE_PATH

doneFinalStage

echo ''
echo 'Now start IDE and make some final things:'
echo '-Tools->Options->Appearance->Look & Feel set Metal instead GTK+, because last one is distort tab names'
echo '-If you need change default project directory, in file ~/.netbeans/8.2/config/Preferences/org/netbeans/modules/projectui.properties set projectsFolder=/Users/<your username>/<MyProjectsFolder>'
echo '-If you want to use IDE with alternative interface language, in file ~/netbeans-8.2/etc/netbeans.conf add value "-J-Duser.language=en -J-Duser.region=US" for setting netbeans_default_options'

exitOK
