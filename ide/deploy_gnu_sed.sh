#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy GNU sed ($COMMON_CONST_MACOS_SED) from source on the local OS"

##private consts
readonly CONST_FILE_URL='http://ftp.gnu.org/gnu/sed/sed-@PRM_VERSION@.tar.xz' #Source url for download
readonly CONST_SED_PATH="$HOME/sed"
readonly CONST_FILE_VERSION='4.4'

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version for download
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

VAR_FILE_URL=$(echo "$VAR_FILE_URL" | $SED -e "s#@PRM_VERSION@#$PRM_VERSION#") || exitChildError "$VAR_FILE_URL"
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

mkdir -p "${CONST_SED_PATH}-$PRM_VERSION/src"
checkRetValOK
tar --strip-component=1 -C "${CONST_SED_PATH}-$PRM_VERSION/src" -xvf "$VAR_ORIG_FILE_PATH"
checkRetValOK
VAR_CUR_DIR_PATH=$PWD
cd "${CONST_SED_PATH}-$PRM_VERSION/src"
checkRetValOK
./configure --prefix="${CONST_SED_PATH}-$PRM_VERSION" --program-prefix=g #see $COMMON_CONST_MACOS_SED
checkRetValOK
make
checkRetValOK
make install
checkRetValOK
cd $VAR_CUR_DIR_PATH
checkRetValOK

if isLinuxOS; then
  echo "export PATH=$PATH:${CONST_SED_PATH}-$PRM_VERSION/bin" | tee -a "$HOME/.bashrc"
  checkRetValOK
  PATH=$PATH:${CONST_SED_PATH}-$PRM_VERSION/bin
  checkRetValOK
  if isCommandExist "source"; then
    source "$HOME/.bashrc"
    checkRetValOK
  fi
elif isMacOS; then
  echo "export PATH=$PATH:${CONST_SED_PATH}-$PRM_VERSION/bin" | tee -a "$HOME/.bash_profile"
  checkRetValOK
  PATH=$PATH:${CONST_SED_PATH}-$PRM_VERSION/bin
  checkRetValOK
  if isCommandExist "source"; then
    source "$HOME/.bash_profile"
    checkRetValOK
  fi
fi

$COMMON_CONST_MACOS_SED --version
checkRetValOK

doneFinalStage
exitOK
