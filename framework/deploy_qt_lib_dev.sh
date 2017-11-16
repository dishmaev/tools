#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Qt5 on the local OS x64'

##private consts
readonly CONST_FILE_URL='https://download.qt.io/official_releases/qt/@VAR_VERSION@/@PRM_VERSION@/qt-opensource-linux-x64-@PRM_VERSION@.run' #url for download

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS
VAR_VERSION='' #lib short version format MAJOR.MINOR

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '[version=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $CONST_TOOLSET" "Version format 'X.X.X'. Qt Libraries url https://download.qt.io/official_releases/qt/"

###check commands

PRM_VERSION=${1:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

checkDependencies ''

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi

if [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  if isAPTLinux "$VAR_LINUX_BASED"; then
    sudo apt -y install qt5-default
    if ! isRetValOK; then exitError; fi
    sudo apt -y install qt5-doc
    if ! isRetValOK; then exitError; fi
    sudo apt -y install qt5-doc-html
    if ! isRetValOK; then exitError; fi
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    #sudo yum -y install boost-devel
    #if ! isRetValOK; then exitError; fi
    :
  fi
else
  VAR_VERSION=$(echo "$PRM_VERSION" | awk -F. '{print $1"."$2}') || exitChildError "$VAR_VERSION"
  VAR_FILE_URL=$(echo "$CONST_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#g;s#@VAR_VERSION@#$VAR_VERSION#") || exitChildError "$VAR_FILE_URL"
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  if ! isRetValOK; then exitError; fi
  echo "TO-DO custom version install, downgrade or make from sources"
fi

doneFinalStage
exitOK
