#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Add package file to a distrib repository'

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_APT_CODE_NAME_STABLE='stable'
CONST_APT_CODE_NAME_TESTING='testing'
CONST_APT_CODE_NAME_UNSTABLE='unstable'

##private vars
PRM_PACKAGE_FILE='' #build file name
PRM_VM_TEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository
VAR_CUR_DIR_NAME='' #current directory name
VAR_TMP_DIR_NAME='' #temporary directory name
VAR_CODE_NAME=$CONST_APT_CODE_NAME_UNSTABLE #code name
VAR_SHORT_FILE_NAME='' #short file name of $PRM_BUILD_FILE

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<packageFile> <vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [distribRepository=$ENV_DISTRIB_REPO]' \
"myFile $COMMON_CONST_PHOTONMINI_VM_TEMPLATE $COMMON_CONST_DEVELOP_SUITE $ENV_DISTRIB_REPO" \
"Required gpg secret keyID $COMMON_CONST_GPG_KEYID. Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_PACKAGE_FILE=$1
PRM_VM_TEMPLATE=$2
PRM_SUITE=${3:-$COMMON_CONST_DEVELOP_SUITE}
PRM_DISTRIB_REPO=${4:-$ENV_DISTRIB_REPO}

checkCommandExist 'packageFile' "$PRM_PACKAGE_FILE" ''
checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

checkRequiredFiles "$PRM_PACKAGE_FILE"

###start prompt

startPrompt

###body

VAR_SHORT_FILE_NAME=$(getFileNameFromUrlString "$PRM_PACKAGE_FILE") || exitChildError "$VAR_SHORT_FILE_NAME"

if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ]; then
  echo "RPM-based Linux repository"
  checkDependencies 'createrepo'
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
  echo "APT-based Linux repository"
  checkDependencies 'reprepro'
  #make temporary directory
  VAR_TMP_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_NAME"
  git clone $PRM_DISTRIB_REPO $VAR_TMP_DIR_NAME
  if ! isRetValOK; then exitError; fi
  #get target code name
  if [ "$PRM_SUITE" = "$COMMON_CONST_TEST_SUITE" ]; then
    VAR_CODE_NAME=$CONST_APT_CODE_NAME_TESTING
  elif [ "$PRM_SUITE" = "$COMMON_CONST_RELEASE_SUITE" ]; then
    VAR_CODE_NAME=$CONST_APT_CODE_NAME_STABLE
  fi
  #add package
  echo "Add package $VAR_SHORT_FILE_NAME to $VAR_CODE_NAME CODENAME"
  reprepro -b $VAR_TMP_DIR_NAME/repos/linux/apt includedeb $VAR_CODE_NAME $PRM_PACKAGE_FILE
  if ! isRetValOK; then exitError; fi
  VAR_CUR_DIR_NAME=$PWD
  cd $VAR_TMP_DIR_NAME
  #git add and commit
  git add *
  git commit -m "add package $VAR_SHORT_FILE_NAME to $PRM_SUITE suite of distrib repository"
  if ! isRetValOK; then exitError; fi
  git push --all
  if ! isRetValOK; then exitError; fi
  #remote temporary directory
  cd $VAR_CUR_DIR_NAME
  if ! isRetValOK; then exitError; fi
  rm -fR $VAR_TMP_DIR_NAME
  if ! isRetValOK; then exitError; fi
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE" ]; then
  echo "Oracle Solaris repository"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
  echo "FreeBSD repository"
fi
doneFinalStage
exitOK
