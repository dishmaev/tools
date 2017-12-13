#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Atom on the local OS x64'

##private consts
readonly CONST_FILE_APT_URL='https://github.com/atom/atom/releases/download/v@PRM_VERSION@/atom-amd64.deb' #APT-based Linux url for download
readonly CONST_FILE_RPM_URL='https://github.com/atom/atom/releases/download/v@PRM_VERSION@/atom.x86_64.rpm' #RPM-based Linux url for download
readonly CONST_FILE_MACOS_URL='https://github.com/atom/atom/releases/download/v@PRM_VERSION@/atom-mac.zip' #MacOS url for download
readonly CONST_FILE_VERSION='1.23.0'

##private vars
PRM_VERSION='' #IDE version
VAR_LINUX_BASED='' #for checking supported OS
VAR_VERSION='' #lib short version format MAJOR.MINOR
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version of boost for download

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $CONST_TOOLSET" "Version format 'X.X[X].X'. Atom text editor url https://atom.io/"

###check commands

PRM_VERSION=${1:-$CONST_FILE_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies


###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

if isCommandExist 'atom'; then
  echoInfo "already deployed"
  atom --version
  checkRetValOK

  doneFinalStage
  exitOK
fi
#check supported OS
if isLinuxOS; then
  checkDependencies 'wget'
  VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
  if isAPTLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_APT_URL"
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_RPM_URL"
  else
    exitError "unknown Linux based package system"
  fi
elif isMacOS; then
  VAR_FILE_URL="$CONST_FILE_MACOS_URL"
else
  exitError 'not supported OS'
fi

VAR_FILE_URL=$(echo "$VAR_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  if isLinuxOS; then
    wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
    checkRetValOK
  elif isMacOS; then
    curl -L -o $VAR_ORIG_FILE_PATH $VAR_FILE_URL
    checkRetValOK
  fi
fi
if isLinuxOS; then
  if isAPTLinux "$VAR_LINUX_BASED"; then
    checkDpkgUnlock
    sudo apt -y install $VAR_ORIG_FILE_PATH
    checkRetValOK
    sudo apt -y install -f
    checkRetValOK
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    sudo yum -y install $VAR_ORIG_FILE_PATH
    checkRetValOK
  fi
elif isMacOS; then
  exitOK
fi
apm install atom-ide-ui
checkRetValOK
apm install ide-java
checkRetValOK
apm install go-plus
checkRetValOK
apm install go-debug
checkRetValOK
apm install git-plus
checkRetValOK
apm install tree-view-git-status
checkRetValOK
apm install termination
checkRetValOK

atom --version
checkRetValOK

doneFinalStage
exitOK
