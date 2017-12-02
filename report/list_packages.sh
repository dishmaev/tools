#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Get packages list from a personal distrib repository'

##private consts
readonly CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
readonly CONST_RELEASE_CODE_NAME_APT='stable'
readonly CONST_TEST_CODE_NAME_APT='testing'
readonly CONST_DEVELOP_CODE_NAME_APT='unstable'
readonly CONST_RELEASE_CODE_NAME_RPM='release'
readonly CONST_TEST_CODE_NAME_RPM='test'
readonly CONST_DEVELOP_CODE_NAME_RPM='develop'

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_FILTER_REGEX='' #build file name
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository
VAR_CODE_NAME='' #code name
VAR_TMP_DIR_PATH='' #temporary directory name
VAR_DISTRIB_REPO_DIR_PATH='' #local path of distrib repository
VAR_PACKAGE_NAME='' #package name
VAR_PACKAGE_VERSION='' #package version
VAR_PACKAGE_RELEASE='' #package release
VAR_PACKAGE_ARCH='' #package architecture
VAR_CHECK_REGEX='' #check regex package name
VAR_CUR_FILE_PATH='' #file name
VAR_CUR_FILE_NAME='' #file name with local path

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4  '<vmTemplate> [filterRegex=$COMMON_CONST_ALL] [suite=$COMMON_CONST_DEVELOP_SUITE] [distribRepository=$ENV_DISTRIB_REPO]' \
"$COMMON_CONST_DEBIANMINI_VM_TEMPLATE $COMMON_CONST_ALL $COMMON_CONST_DEVELOP_SUITE $ENV_DISTRIB_REPO" \
"Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_FILTER_REGEX=${2:-$COMMON_CONST_ALL}
PRM_SUITE=${3:-$COMMON_CONST_DEVELOP_SUITE}
PRM_DISTRIB_REPO=${4:-$ENV_DISTRIB_REPO}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''
checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

checkDependencies 'git'

###check required files

#checkRequiredFiles "$PRM_FILTER_REGEX"

###start prompt

startPrompt

###body

if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTONFULL_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_CENTOSMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_CENTOSOSB_VM_TEMPLATE" ]; then
  echoInfo "RPM-based Linux repository"
  checkDependencies 'createrepo'
  #get target code name
  if [ "$PRM_SUITE" = "$COMMON_CONST_DEVELOP_SUITE" ]; then
    VAR_CODE_NAME=$CONST_DEVELOP_CODE_NAME_RPM
  elif [ "$PRM_SUITE" = "$COMMON_CONST_TEST_SUITE" ]; then
    VAR_CODE_NAME=$CONST_TEST_CODE_NAME_RPM
  elif [ "$PRM_SUITE" = "$COMMON_CONST_RELEASE_SUITE" ]; then
    VAR_CODE_NAME=$CONST_RELEASE_CODE_NAME_RPM
  fi
  #make temporary directory
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  git clone $PRM_DISTRIB_REPO $VAR_TMP_DIR_PATH
  checkRetValOK
  VAR_DISTRIB_REPO_DIR_PATH=$VAR_TMP_DIR_PATH/repos/linux/rpm/$VAR_CODE_NAME/RPMS
  #list packages
  echoInfo "begin list"
  for VAR_CUR_FILE_PATH in $VAR_DISTRIB_REPO_DIR_PATH/x86_64/*.rpm; do
    if [ ! -r "$VAR_CUR_FILE_PATH" ]; then continue; fi
    VAR_CUR_FILE_NAME=$(getFileNameFromUrlString "$VAR_CUR_FILE_PATH") || exitChildError "$VAR_CUR_FILE_NAME"
    if [ "$PRM_FILTER_REGEX" != "$COMMON_CONST_ALL" ]; then
      VAR_CHECK_REGEX=$(echo "$VAR_CUR_FILE_NAME" | grep -E "$PRM_FILTER_REGEX" | cat) || exitChildError "$VAR_CHECK_REGEX"
      if isEmpty "$VAR_CHECK_REGEX"; then continue; fi
    fi
    VAR_PACKAGE_NAME=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E '^Name[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_VERSION=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E '^Version[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_RELEASE=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E '^Release[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_ARCH=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E '^Architecture[ *:]' | awk '{print $2}') || exitChildError "$VAR_PACKAGE_ARCH"
    if ! isEmpty "$VAR_PACKAGE_RELEASE"; then
      VAR_PACKAGE_VERSION=$VAR_PACKAGE_VERSION-$VAR_PACKAGE_RELEASE
    fi
    echo "${VAR_CODE_NAME}|RPMS|${VAR_PACKAGE_ARCH}: $VAR_PACKAGE_NAME $VAR_PACKAGE_VERSION $VAR_CUR_FILE_NAME"
  done
  for VAR_CUR_FILE_PATH in $VAR_DISTRIB_REPO_DIR_PATH/noarch/*.rpm; do
    if [ ! -r "$VAR_CUR_FILE_PATH" ]; then continue; fi
    VAR_CUR_FILE_NAME=$(getFileNameFromUrlString "$VAR_CUR_FILE_PATH") || exitChildError "$VAR_CUR_FILE_NAME"
    if [ "$PRM_FILTER_REGEX" != "$COMMON_CONST_ALL" ]; then
      VAR_CHECK_REGEX=$(echo "$VAR_CUR_FILE_NAME" | grep -E "$PRM_FILTER_REGEX" | cat) || exitChildError "$VAR_CHECK_REGEX"
      if isEmpty "$VAR_CHECK_REGEX"; then continue; fi
    fi
    VAR_PACKAGE_NAME=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E 'Name[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_VERSION=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E 'Version[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_RELEASE=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E 'Release[ *:]' | awk '{print $3}') || exitChildError "$VAR_PACKAGE_ARCH"
    VAR_PACKAGE_ARCH=$(rpm -qip $VAR_CUR_FILE_PATH | grep -E 'Architecture[ *:]' | awk '{print $2}') || exitChildError "$VAR_PACKAGE_ARCH"
    if ! isEmpty "$VAR_PACKAGE_RELEASE"; then
      VAR_PACKAGE_VERSION=$VAR_PACKAGE_VERSION-$VAR_PACKAGE_RELEASE
    fi
    echo "${VAR_CODE_NAME}|RPMS|${VAR_PACKAGE_ARCH}: $VAR_PACKAGE_NAME $VAR_PACKAGE_VERSION $VAR_CUR_FILE_NAME"
  done
  echoInfo "end list"
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
  echoInfo "APT-based Linux repository"
  checkDependencies 'reprepro'
  #get target code name
  if [ "$PRM_SUITE" = "$COMMON_CONST_DEVELOP_SUITE" ]; then
    VAR_CODE_NAME=$CONST_DEVELOP_CODE_NAME_APT
  elif [ "$PRM_SUITE" = "$COMMON_CONST_TEST_SUITE" ]; then
    VAR_CODE_NAME=$CONST_TEST_CODE_NAME_APT
  elif [ "$PRM_SUITE" = "$COMMON_CONST_RELEASE_SUITE" ]; then
    VAR_CODE_NAME=$CONST_RELEASE_CODE_NAME_APT
  fi
  #make temporary directory
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  git clone $PRM_DISTRIB_REPO $VAR_TMP_DIR_PATH
  checkRetValOK
  #list packages
  echoInfo "begin list"
  reprepro -b $VAR_TMP_DIR_PATH/repos/linux/apt list $VAR_CODE_NAME | grep -E "$PRM_FILTER_REGEX" | cat
  checkRetValOK
  echoInfo "end list"
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE" ]; then
  echoWarning "TO-DO Oracle Solaris repository"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
  echoWarning "TO-DO FreeBSD repository"
fi
doneFinalStage
exitOK
