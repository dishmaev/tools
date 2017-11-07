#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Boost C++ Libraries on the local OS'

##private consts
readonly CONST_BOOST_URL='https://dl.bintray.com/boostorg/release/@PRM_LIB_VERSION@/source/boost_@VAR_LIB_VERSION@.tar.gz'
readonly CONST_TOOLSET='gcc'

##private vars
PRM_INCLUDE_SHARED=$COMMON_CONST_FALSE #also install shared Libraries
PRM_LIB_VERSION='' #lib version
PRM_TOOLSET='' #toolSet for build specific version of boost
VAR_LINUX_BASED='' #for checking supported OS
VAR_LIB_VERSION='' #lib version wth '_' instead '.'
VAR_FILE_URL='' #url specific version of boost for download


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '[includeShared=0] [libVersion=$COMMON_CONST_DEFAULT_VERSION] \
[toolSet=$COMMON_CONST_DEFAULT_VERSION]' \
"$COMMON_CONST_DEFAULT_VERSION 0 $COMMON_CONST_DEFAULT_VERSION" "Boost C++ Libraries version format 'X.XX.X'"

###check commands

PRM_INCLUDE_SHARED=${1:-$COMMON_CONST_FALSE}
PRM_LIB_VERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}
PRM_TOOLSET=${3:-$CONST_TOOLSET}

checkCommandExist 'includeShared' "$PRM_INCLUDE_SHARED" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'libVersion' "$PRM_LIB_VERSION" ''
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

if [ "$PRM_LIB_VERSION" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
  if isAPTLinux "$VAR_LINUX_BASED"; then
    apt -y install libboost-all-dev
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    yum -y install libboost-all-dev
  fi
  if ! isRetValOK; then exitError; fi
else
  VAR_LIB_VERSION=$(echo "$PRM_LIB_VERSION" | sed 's/[.]/_/g') || exitChildError "$VAR_LIB_VERSION"
  VAR_FILE_URL=$(echo "$CONST_BOOST_URL" | sed -e "s#@PRM_LIB_VERSION@#$PRM_LIB_VERSION#;s#@VAR_LIB_VERSION@#$VAR_LIB_VERSION#") || exitChildError "$VAR_FILE_URL"
  VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
  VAR_ORIG_FILE_PATH=$COMMON_CONST_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
  wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
  if ! isRetValOK; then exitError; fi
fi

doneFinalStage
exitOK
