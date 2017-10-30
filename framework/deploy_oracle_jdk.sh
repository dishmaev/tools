#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Deploy Oracle JDK on the system'

##private consts
ORACLE_JDK_DEB_REPO='deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
ORACLE_JDK_DEB_SRC_REPO='deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main'
ORACLE_JDK_DEB_KEY='hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886'
APT_SOURCE_FILE='/etc/apt/sources.list'


##private vars
LINUX_BASED='' #for checking supported OS


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" "While tested only on APT-based Linux. Oracle JDK url http://www.oracle.com/technetwork/java/javase/downloads/index.html"

###check commands

#comments

###check body dependencies

checkDependencies 'wget apt-key grep debconf-set-selections'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#if already deployed, exit OK
if isCommandExist 'java' && ! [ $(java -version 2>&1 | grep "OpenJDK Runtime") ]; then
  doneFinalStage
  exitOK
fi
#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$LINUX_BASED"
if ! isAPTLinux $LINUX_BASED; then exitError 'not supported OS'; fi

#check for oracle JDK repo
if ! grep -qF "$ORACLE_JDK_DEB_REPO" "$APT_SOURCE_FILE"; then
  sudo apt-key adv --keyserver $ORACLE_JDK_DEB_KEY
  if ! isRetValOK; then exitError; fi
  echo "$ORACLE_JDK_DEB_REPO" | sudo tee -a $APT_SOURCE_FILE
  if ! isRetValOK; then exitError; fi
  echo "$ORACLE_JDK_DEB_SRC_REPO" | sudo tee -a $APT_SOURCE_FILE
  if ! isRetValOK; then exitError; fi
  sudo apt update
  if ! isRetValOK; then exitError; fi
fi

sudo echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections
if ! isRetValOK; then exitError; fi
sudo apt -y install oracle-java8-installer
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
