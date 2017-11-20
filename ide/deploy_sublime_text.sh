#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Sublime Text on the local OS'

##private consts

##private vars

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "Sublime Text url https://www.sublimetext.com/"

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
if isCommandExist 'sublime'; then
  echoResult "Already deployed"
  sublime --version
  doneFinalStage
  exitOK
fi

if isAPTLinux "$VAR_LINUX_BASED"; then
  sudo apt -y install apt-transport-https
  if ! isRetValOK; then exitError; fi
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  if ! isRetValOK; then exitError; fi
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  if ! isRetValOK; then exitError; fi
  sudo apt -y update
  if ! isRetValOK; then exitError; fi
  sudo apt -y install sublime-text
  if ! isRetValOK; then exitError; fi
elif isRPMLinux "$VAR_LINUX_BASED"; then
  sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
  if ! isRetValOK; then exitError; fi
  sudo yum -y install yum-utils
  if ! isRetValOK; then exitError; fi
  sudo yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
  if ! isRetValOK; then exitError; fi
  sudo yum -y install sublime-text
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
