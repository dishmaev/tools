#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Sublime Text on the local OS x86_64'

##private consts

##private vars

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "Sublime Text url https://www.sublimetext.com/"

###check commands

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
if isCommandExist 'subl'; then
  echoResult "Already deployed"
  subl --version
  doneFinalStage
  exitOK
fi

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

subl --version

doneFinalStage
exitOK
