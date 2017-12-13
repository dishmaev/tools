#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy GNU sed ($COMMON_CONST_MACOS_SED) from source on the local OS"

##private consts
readonly CONST_FILE_URL='http://ftp.gnu.org/gnu/sed/sed-@PRM_VERSION@.tar.xz' #Source url for download
readonly CONST_SEDPATH="$HOME/sed"
readonly CONST_FILE_VERSION='4.4'

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version of boost for download
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' "$CONST_FILE_VERSION" \
"Version format 'X.X'. GNU sed url https://www.gnu.org/software/sed/"

###check commands

PRM_VERSION=${1:-$CONST_FILE_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

checkDependencies 'make'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

if isCommandExist "$COMMON_CONST_MACOS_SED"; then
  echoInfo "already deployed"
  $COMMON_CONST_MACOS_SED --version
  checkRetValOK

  doneFinalStage
  exitOK
fi
#check supported OS
if isLinuxOS; then
  checkDependencies 'wget'
  VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
  if isAPTLinux "$VAR_LINUX_BASED" || isRPMLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_URL"
  else
    exitError "unknown Linux based package system"
  fi
elif isMacOS; then
  VAR_FILE_URL="$CONST_FILE_URL"
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

mkdir -p "${CONST_SEDPATH}-$PRM_VERSION/src"
checkRetValOK
tar --strip-component=1 -C "${CONST_SEDPATH}-$PRM_VERSION/src" -xvf "$VAR_ORIG_FILE_PATH"
checkRetValOK
VAR_CUR_DIR_PATH=$PWD
cd "${CONST_SEDPATH}-$PRM_VERSION/src"
checkRetValOK
./configure --prefix="${CONST_SEDPATH}-$PRM_VERSION" --program-prefix=g #see $COMMON_CONST_MACOS_SED
checkRetValOK
make
checkRetValOK
make install
checkRetValOK
cd $VAR_CUR_DIR_PATH
checkRetValOK

$COMMON_CONST_MACOS_SED --version
checkRetValOK

doneFinalStage
exitOK
