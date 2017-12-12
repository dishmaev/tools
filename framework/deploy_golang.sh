#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Golang packages on the local OS'

##private consts
readonly CONST_FILE_LINUX_URL='https://redirector.gvt1.com/edgedl/go/go@PRM_VERSION@.linux-amd64.tar.gz' #Linux url for download
readonly CONST_FILE_MACOS_URL='https://redirector.gvt1.com/edgedl/go/go@PRM_VERSION@.darwin-amd64.pkg' #MacOS url for download

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
  VAR_FILE_URL=$(echo "$VAR_FILE_URL" | sed -e "s#@PRM_VERSION@#$PRM_VERSION#g") || exitChildError "$VAR_FILE_URL"
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
  if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
    if isLinuxOS; then
      wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      checkRetValOK
      if ! isDirectoryExist "\$HOME/go${PRM_VERSION}"
        mkdir "${HOME}/go${PRM_VERSION}"
        tar --strip-component=1 -C "${HOME}/go${PRM_VERSION}" -xvf "$VAR_ORIG_FILE_PATH"
        checkRetValOK
        echo "export PATH=$PATH:$HOME/go${PRM_VERSION}/bin:$GOPATH/bin" | tee -a "$HOME/.bashrc"
        checkRetValOK
        export PATH=$PATH:$HOME/go${PRM_VERSION}/bin:$GOPATH/bin
        checkRetValOK
      fi
    elif isMacOS; then
      curl -o $VAR_ORIG_FILE_PATH $VAR_FILE_URL
      checkRetValOK
      echoWarning "TO-DO custom version install for MacOS"
    fi
  fi
fi

doneFinalStage
exitOK
