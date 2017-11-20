#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Oracle JDK on the local OS'

##private consts
readonly CONST_ORACLE_JDK_DEB_REPO='deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
readonly CONST_ORACLE_JDK_DEB_SRC_REPO='deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
readonly CONST_ORACLE_JDK_DEB_KEY='hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886'
readonly CONST_ORACLE_JDK_VERSION='8'
readonly CONST_APT_SOURCE_FILE_PATH='/etc/apt/sources.list.d/oraclejdk.list'


##private vars
VAR_LINUX_BASED='' #for checking supported OS


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_ORACLE_JDK_VERSION]' "$CONST_ORACLE_JDK_VERSION" "Version format 'X'. While tested only on APT-based Linux. Oracle JDK url http://www.oracle.com/technetwork/java/javase/downloads/index.html"

###check commands

PRM_VERSION=${1:-$CONST_ORACLE_JDK_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

checkDependencies 'wget apt-key grep debconf-set-selections dirmngr'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux "$VAR_LINUX_BASED"; then exitError 'not supported OS'; fi
#if already deployed, exit OK
if isCommandExist 'java'; then
  java -version 2>&1 | grep "Java HotSpot"
  if [ "$?" = "0" ]; then
    echoResult "Already deployed"
    java -version
    doneFinalStage
    exitOK
  fi
fi

if isAPTLinux "$VAR_LINUX_BASED"; then
  #check for oracle JDK repo
  if ! isFileExistAndRead "$CONST_APT_SOURCE_FILE_PATH"; then
    sudo apt-key adv --keyserver $CONST_ORACLE_JDK_DEB_KEY
    if ! isRetValOK; then exitError; fi
    echo "$CONST_ORACLE_JDK_DEB_REPO" | sudo tee $CONST_APT_SOURCE_FILE_PATH
    if ! isRetValOK; then exitError; fi
    echo "$CONST_ORACLE_JDK_DEB_SRC_REPO" | sudo tee -a $CONST_APT_SOURCE_FILE_PATH
    if ! isRetValOK; then exitError; fi
    sudo apt -y update
    if ! isRetValOK; then exitError; fi
  fi
  #accepted license
  sudo echo "oracle-java${PRM_VERSION}-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
  if ! isRetValOK; then exitError; fi
  sudo apt -y install oracle-java${PRM_VERSION}-installer
  if ! isRetValOK; then exitError; fi
elif isRPMLinux "$VAR_LINUX_BASED"; then
  :
fi

doneFinalStage
exitOK
