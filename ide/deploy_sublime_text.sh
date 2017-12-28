#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Sublime Text with Go plugin on the local OS x86_64'

##private consts
readonly CONST_FILE_LINUX_URL='https://download.sublimetext.com/sublime_text_3_build_@PRM_VERSION@_x64.tar.bz2' #Linux url for download
readonly CONST_FILE_MACOS_URL='https://download.sublimetext.com/Sublime%20Text%20Build%20@PRM_VERSION@.dmg' #MacOS url for download
readonly CONST_FILE_VERSION='3143'
readonly CONST_SUBLIM_NAME='subl'
readonly CONST_SUBLIM_PATH="$HOME/$CONST_SUBLIM_NAME"

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version for download

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION" "Version as build number, for example $CONST_FILE_VERSION. Sublime Text url https://www.sublimetext.com/"

###check commands

PRM_VERSION=${1:-$COMMON_CONST_DEFAULT_VERSION}

if isMacOS && [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  PRM_VERSION=$CONST_FILE_VERSION
fi

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

if isCommandExist 'subl'; then
  echoInfo "already deployed"
  $CONST_SUBLIM_NAME --version
  checkRetValOK

  doneFinalStage
  exitOK
fi
#check supported OS
if isLinuxOS; then
  checkDependencies 'wget'
  VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
  if isAPTLinux "$VAR_LINUX_BASED" || isRPMLinux "$VAR_LINUX_BASED"; then
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
      sudo apt -y install apt-transport-https
      checkRetValOK
      wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
      checkRetValOK
      echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
      checkRetValOK
      sudo apt -y update
      checkRetValOK
      sudo apt -y install sublime-text
      checkRetValOK
    elif isRPMLinux "$VAR_LINUX_BASED"; then
      sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
      checkRetValOK
      sudo yum -y install yum-utils
      checkRetValOK
      sudo yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
      checkRetValOK
      sudo yum -y install sublime-text
      checkRetValOK
    fi
  fi
else
  checkDependencies 'tar'
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
  if isLinuxOS; then
    mkdir -p "${CONST_SUBLIM_PATH}-$PRM_VERSION"
    checkRetValOK
    tar --strip-component=1 -C "${CONST_SUBLIM_PATH}-$PRM_VERSION" -xvf "$VAR_ORIG_FILE_PATH"
    checkRetValOK
    ln -s "${CONST_SUBLIM_PATH}-$PRM_VERSION/sublime_text" "${CONST_SUBLIM_PATH}-$PRM_VERSION/subl"
    checkRetValOK
    echo "export PATH=\$PATH:${CONST_SUBLIM_PATH}-$PRM_VERSION" | tee -a "$HOME/.profile"
    checkRetValOK
    export PATH=$PATH:${CONST_SUBLIM_PATH}-$PRM_VERSION
    checkRetValOK
    if isCommandExist "source"; then
      source "$HOME/.profile"
      checkRetValOK
    fi
  elif isMacOS; then
    hdiutil attach $VAR_ORIG_FILE_PATH
    checkRetValOK
    cp -R '/Volumes/Sublime Text/Sublime Text.app' $HOME/Applications/
    checkRetValOK
    hdiutil unmount '/Volumes/Sublime Text'
    checkRetValOK
    ln -s "$HOME/Applications/Sublime Text.app/Contents/MacOS/Sublime Text" "$HOME/Applications/Sublime Text.app/Contents/MacOS/subl"
    checkRetValOK
    echo "export $PATH:$HOME/Applications/Sublime\ Text.app/Contents/MacOS" | tee -a "$HOME/.bash_profile"
    checkRetValOK
    PATH="$PATH:\$HOME/Applications/Sublime\ Text.app/Contents/MacOS"
    checkRetValOK
    if isCommandExist "source"; then
      source "$HOME/.bash_profile"
      checkRetValOK
    fi
  fi
fi

if ! isMacOS; then
  $CONST_SUBLIM_NAME --version
  checkRetValOK
else
  "$HOME/Applications/Sublime Text.app/Contents/MacOS/subl" --version
  checkRetValOK
fi

doneFinalStage

echo ''
echo "Now start Sublime Text and make some final things: "
echo "-set \"spell_check\": true in 'Preferences=>Settings - Syntax Specific'"
echo "-install Package Control in Tools"
echo "-install Package GoSublime"
echo "-install Package GitGutter"
echo "-install Package BracketHighlighter"
echo "Another useful plugins describe url https://proglib.io/p/15-sublime-text-plugins/"

exitOK
