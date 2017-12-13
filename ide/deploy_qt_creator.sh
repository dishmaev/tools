#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Qt Creator on the local OS x64'

##private consts
readonly CONST_FILE_URL='https://download.qt.io/official_releases/qt/@VAR_VERSION@/@PRM_VERSION@/qt-opensource-linux-x64-@PRM_VERSION@.run' #url for download
readonly CONST_FILE_VERSION='5.9.2'

##private vars
PRM_VERSION='' #lib version
VAR_VERSION='' #lib short version format MAJOR.MINOR

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION" "Version format 'X.X.X'. Qt Creator url https://download.qt.io/official_releases/qt/"

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

VAR_VERSION=$(echo "$PRM_VERSION" | awk -F. '{print $1"."$2}') || exitChildError "$VAR_VERSION"
VAR_FILE_URL=$(echo "$CONST_FILE_URL" | $SED -e "s#@PRM_VERSION@#$PRM_VERSION#g;s#@VAR_VERSION@#$VAR_VERSION#") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  checkRetValOK
  chmod u+x $VAR_ORIG_FILE_PATH
  checkRetValOK
fi

doneFinalStage

echo ''
echo "Now start IDE setup $VAR_ORIG_FILE_PATH. Required Qt Forum account url https://forum.qt.io/"

exitOK
