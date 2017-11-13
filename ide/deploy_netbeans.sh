#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy NetBeans Java SE on the local OS x86_64'

##private consts
readonly CONST_FILE_URL='http://download.netbeans.org/netbeans/@PRM_VERSION@/final/bundles/netbeans-@PRM_VERSION@-javase-linux.sh' #url for download
readonly CONST_FILE_VERSION='8.2'

##private vars
PRM_VERSION='' #ide version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version of boost for download

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' "$CONST_FILE_VERSION" "Version format 'X.X'. While tested only on APT-based Linux. NetBeans IDE url https://netbeans.org/"

###check commands

#comments

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi
#if already deployed, exit OK
if isCommandExist 'netbeans'; then
  doneFinalStage
  exitOK
fi

VAR_FILE_URL=$(echo "$CONST_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#g") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
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

doneFinalStage

echo ''
echo 'Now start IDE and make some final things:'
echo '-Tools->Options->Appearance->Look & Feel set Metal instead GTK+, because last one is distort tab names'
echo '-If you need change default project directory, in file ~/.netbeans/8.2/config/Preferences/org/netbeans/modules/projectui.properties set projectsFolder=/Users/<your username>/<MyProjectsFolder>'
echo '-If you want to use IDE with alternative interface language, in file ~/netbeans-8.2/etc/netbeans.conf add value "-J-Duser.language=en -J-Duser.region=US" for setting netbeans_default_options'

exitOK
