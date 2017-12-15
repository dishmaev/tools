#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Boost C++ Libraries dev on the local OS'

##private consts
readonly CONST_FILE_URL='https://dl.bintray.com/boostorg/release/@PRM_VERSION@/source/boost_@VAR_VERSION@.tar.gz'
readonly CONST_TOOLSET='gcc'

##private vars
PRM_INCLUDE_SHARED=$COMMON_CONST_FALSE #also install shared Libraries
PRM_VERSION='' #lib version
PRM_TOOLSET='' #toolSet for build specific version of boost
VAR_LINUX_BASED='' #for checking supported OS
VAR_VERSION='' #lib version wth '_' instead '.'
VAR_FILE_URL='' #url specific version for download


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '[version=$COMMON_CONST_DEFAULT_VERSION] [includeShared=0] [toolSet=$CONST_TOOLSET]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $CONST_TOOLSET" "Version format 'X.XX.X'. Boost C++ Libraries url http://www.boost.org/"

###check commands

PRM_VERSION=${1:-$COMMON_CONST_DEFAULT_VERSION}
PRM_INCLUDE_SHARED=${2:-$COMMON_CONST_FALSE}
PRM_TOOLSET=${3:-$CONST_TOOLSET}

checkCommandExist 'version' "$PRM_VERSION" ''
checkCommandExist 'includeShared' "$PRM_INCLUDE_SHARED" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'toolSet' "$PRM_TOOLSET" ''

###check body dependencies

checkDependencies 'wget tar'

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
    sudo apt -y install libboost-all-dev
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    sudo yum -y install boost-devel
  fi
  checkRetValOK
else
  VAR_VERSION=$(echo "$PRM_VERSION" | $SED 's/[.]/_/g') || exitChildError "$VAR_VERSION"
  VAR_FILE_URL=$(echo "$CONST_FILE_URL" | $SED -e "s#@PRM_VERSION@#$PRM_VERSION#;s#@VAR_VERSION@#$VAR_VERSION#") || exitChildError "$VAR_FILE_URL"
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
  if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
    wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
    checkRetValOK
  fi
  echoWarning "TO-DO custom version install, downgrade or make from sources"
fi

doneFinalStage
exitOK
