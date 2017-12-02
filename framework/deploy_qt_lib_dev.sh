#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Qt5 on the local OS x64'

##private consts

##private vars
PRM_VERSION='' #lib version
VAR_LINUX_BASED='' #for checking supported OS

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $CONST_TOOLSET" "Version format 'X.X.X'. Qt Library url https://www.qt.io/"

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

if [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  if isAPTLinux "$VAR_LINUX_BASED"; then
    checkDpkgUnlock
    sudo apt -y install qt5-default
    checkRetValOK
    sudo apt -y install qt5-doc
    checkRetValOK
    sudo apt -y install qt5-doc-html
    checkRetValOK
    sudo apt -y install qttools5-dev-tools
    checkRetValOK
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    sudo yum -y install qt5-qtbase-devel
    checkRetValOK
    sudo yum -y install qt5-qtbase-doc
    checkRetValOK
    sudo yum -y install qt5-qtbase-examples
    checkRetValOK
    sudo yum -y install qt5-qttools-devel
    checkRetValOK
    sudo yum -y install qt5-qttools-doc
    checkRetValOK
    sudo yum -y install qt5-qttools-examples
    checkRetValOK
  fi
else
  echoWarning "TO-DO custom version install with downgrade"
fi

doneFinalStage
exitOK
