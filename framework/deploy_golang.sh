#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Golang packages on the local OS'

##private consts
readonly CONST_FILE_LINUX_URL='https://storage.googleapis.com/golang/go@PRM_VERSION@.linux-amd64.tar.gz' #Linux url for download
readonly CONST_FILE_MACOS_URL='https://storage.googleapis.com/golang/go@PRM_VERSION@.darwin-amd64.pkg' #MacOS url for download
readonly CONST_GO_PATH="$HOME/go"
readonly CONST_MACOS_VERSION='1.12.7'

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION" "Version format 'X.X.X'. Golang packages url https://golang.org/pkg/"

###check commands

PRM_VERSION=${1:-$COMMON_CONST_DEFAULT_VERSION}

if isMacOS && [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  PRM_VERSION=$CONST_MACOS_VERSION
fi

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

if isCommandExist 'go'; then
  echoInfo "already deployed"
  go version
  checkRetValOK

  doneFinalStage
  exitOK
fi
#check supported OS
if isLinuxOS; then
  checkDependencies 'wget'
  VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
  if isAPTLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_LINUX_URL"
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_LINUX_URL"
  else
    exitError "unknown Linux based package system"
  fi
elif isMacOS; then
  VAR_FILE_URL="$CONST_FILE_MACOS_URL"
else
  exitError 'not supported OS'
fi

if [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  if isLinuxOS; then
    if isAPTLinux "$VAR_LINUX_BASED"; then
      checkDpkgUnlock
      sudo apt -y install golang
    elif isRPMLinux "$VAR_LINUX_BASED"; then
      sudo yum -y install golang
    fi
  elif isMacOS; then
    echoWarning "TO-DO default version install for MacOS"
  fi
  checkRetValOK
else
  VAR_FILE_URL=$(echo "$VAR_FILE_URL" | $SED -e "s#@PRM_VERSION@#$PRM_VERSION#g") || exitChildError "$VAR_FILE_URL"
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
    mkdir "${HOME}/go${PRM_VERSION}"
    tar --strip-component=1 -C "${HOME}/go${PRM_VERSION}" -xvf "$VAR_ORIG_FILE_PATH"
    checkRetValOK
    echo "export PATH=\$PATH:$CONST_GO_PATH${PRM_VERSION}/bin:$CONST_GO_PATH/bin" | tee -a "$HOME/.profile"
    checkRetValOK
    echo "export GOBIN=$CONST_GO_PATH/bin" | tee -a "$HOME/.profile"
    checkRetValOK
    export PATH=$PATH:${CONST_GO_PATH}${PRM_VERSION}/bin:$CONST_GO_PATH/bin
    checkRetValOK
    export GOBIN=$CONST_GO_PATH/bin
    checkRetValOK
    if isCommandExist "source"; then
      source "$HOME/.profile"
      checkRetValOK
    fi
  elif isMacOS; then
    sudo installer -verbose -pkg $VAR_ORIG_FILE_PATH -target /
    checkRetValOK
    echo "export PATH=\$PATH:/usr/local/go/bin:$CONST_GO_PATH/bin" | tee -a "$HOME/.bash_profile"
    checkRetValOK
    echo "export GOBIN=$CONST_GO_PATH/bin" | tee -a "$HOME/.bash_profile"
    checkRetValOK
    PATH=$PATH:/usr/local/go/bin:$CONST_GO_PATH/bin
    checkRetValOK
    GOBIN=$CONST_GO_PATH/bin
    checkRetValOK
    if isCommandExist "source"; then
      source "$HOME/.bash_profile"
      checkRetValOK
    fi
  fi
  if ! isDirectoryExist "$CONST_GO_PATH"; then
    mkdir "$CONST_GO_PATH"
    checkRetValOK
  fi
fi

go version
checkRetValOK

doneFinalStage
exitOK
