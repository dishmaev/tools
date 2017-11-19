#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Atom on the local OS x64'

##private consts
readonly CONST_FILE_DEB_URL='https://github.com/atom/atom/releases/download/v@PRM_VERSION@/atom-amd64.deb' #APT-based Linux url for download
readonly CONST_FILE_RPM_URL='https://github.com/atom/atom/releases/download/v@PRM_VERSION@/atom.x86_64.rpm' #RPM-based Linux url for download
readonly CONST_FILE_VERSION='1.22.1'

##private vars
PRM_VERSION='' #IDE version
VAR_LINUX_BASED='' #for checking supported OS
VAR_VERSION='' #lib short version format MAJOR.MINOR

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $CONST_TOOLSET" "Version format 'X.X[X].X'. Atom text editor url https://atom.io/"

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

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
#if already deployed, exit OK
if isCommandExist 'atom'; then
  echoResult "Already deployed"
  atom --version
  doneFinalStage
  exitOK
fi

if isAPTLinux "$VAR_LINUX_BASED"; then
  VAR_FILE_URL=$CONST_FILE_APT_URL
elif isRPMLinux "$VAR_LINUX_BASED"; then
  VAR_FILE_URL=$CONST_FILE_RPM_URL
fi
VAR_FILE_URL=$(echo "$VAR_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  if ! isRetValOK; then exitError; fi
fi
if isAPTLinux "$VAR_LINUX_BASED"; then
  sudo apt -y install $VAR_ORIG_FILE_PATH
  if ! isRetValOK; then exitError; fi
  sudo apt -y install -f
  if ! isRetValOK; then exitError; fi
elif isRPMLinux "$VAR_LINUX_BASED"; then
  sudo yum -y install $VAR_ORIG_FILE_PATH
  if ! isRetValOK; then exitError; fi
fi
apm install atom-ide-ui
if ! isRetValOK; then exitError; fi
apm install ide-java
if ! isRetValOK; then exitError; fi
apm install git-plus
if ! isRetValOK; then exitError; fi
apt install tree-view-git-status
if ! isRetValOK; then exitError; fi
apt install terminator
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
