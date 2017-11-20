#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Oracle JDK on the local OS'

##private consts
readonly CONST_ORACLE_JDK_VERSION='8'

readonly CONST_ORACLE_JDK_REPO_APT='deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
readonly CONST_ORACLE_JDK_SRC_REPO_APT='deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
readonly CONST_ORACLE_JDK_KEY_APT='hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886'
readonly CONST_SOURCE_FILE_PATH_APT='/etc/apt/sources.list.d/oraclejdk.list'

readonly CONST_FILE_RPM_URL='http://download.oracle.com/otn-pub/java/jdk/8u151-b12/e758a0de34e24606bca991d704f6dcbf/jdk-8u151-linux-x64.rpm'


##private vars
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path

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
  if ! isFileExistAndRead "$CONST_SOURCE_FILE_PATH_APT"; then
    sudo apt-key adv --keyserver $CONST_ORACLE_JDK_KEY_APT
    if ! isRetValOK; then exitError; fi
    echo "$CONST_ORACLE_JDK_REPO_APT" | sudo tee $CONST_SOURCE_FILE_PATH_APT
    if ! isRetValOK; then exitError; fi
    echo "$CONST_ORACLE_JDK_SRC_REPO_APT" | sudo tee -a $CONST_SOURCE_FILE_PATH_APT
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
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$CONST_FILE_RPM_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
  if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
    wget -O $VAR_ORIG_FILE_PATH --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" $CONST_FILE_RPM_URL
    if ! isRetValOK; then exitError; fi
  fi
  sudo yum -y install $VAR_ORIG_FILE_PATH
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
