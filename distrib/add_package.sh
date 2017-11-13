#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Add package file to a distrib repository'

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_RELEASE_CODE_NAME_APT='stable'
CONST_TEST_CODE_NAME_APT='testing'
CONST_DEVELOP_CODE_NAME_APT='unstable'
CONST_RELEASE_CODE_NAME_RPM='release'
CONST_TEST_CODE_NAME_RPM='test'
CONST_DEVELOP_CODE_NAME_RPM='develop'

##private vars
PRM_PACKAGE_FILE='' #build file name
PRM_VM_TEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository
VAR_CODE_NAME='' #code name
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name
VAR_DISTRIB_REPO_DIR_PATH='' #local path of distrib repository
VAR_SHORT_FILE_NAME='' #short file name of $PRM_PACKAGE_FILE
VAR_CHECK_SIGN_ERROR='' #check error sign package
VAR_PACKAGE_ARCH='' #package architecture

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

checkDependencies 'mktemp'

#check availability gpg sec key
checkGpgSecKeyExist $COMMON_CONST_GPG_KEYID

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
  checkDependencies 'createrepo rpm'
  #get target code name
  if [ "$PRM_SUITE" = "$COMMON_CONST_DEVELOP_SUITE" ]; then
    VAR_CODE_NAME=$CONST_DEVELOP_CODE_NAME_RPM
  elif [ "$PRM_SUITE" = "$COMMON_CONST_TEST_SUITE" ]; then
    VAR_CODE_NAME=$CONST_TEST_CODE_NAME_RPM
  elif [ "$PRM_SUITE" = "$COMMON_CONST_RELEASE_SUITE" ]; then
    VAR_CODE_NAME=$CONST_RELEASE_CODE_NAME_RPM
  fi
  #sign package
  rpm --addsign $PRM_PACKAGE_FILE
  if ! isRetValOK; then exitError; fi
  #check sign
  VAR_CHECK_SIGN_ERROR=$(rpm --checksig $PRM_PACKAGE_FILE | grep 'NOT OK' | wc -l) || exitChildError "$VAR_CHECK_SIGN_ERROR"
  if [ "$VAR_CHECK_SIGN_ERROR" != "$COMMON_CONST_FALSE" ]; then
    exitError "$VAR_CHECK_SIGN_ERROR"
  fi
  #make temporary directory
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  git clone $PRM_DISTRIB_REPO $VAR_TMP_DIR_PATH
  if ! isRetValOK; then exitError; fi
  #add package
  echo "Add package $VAR_SHORT_FILE_NAME to $VAR_CODE_NAME CODENAME"
  VAR_PACKAGE_ARCH=$(rpm -qip $PRM_PACKAGE_FILE | grep -E 'Architecture[ *:]' | awk '{print $2}') || exitChildError "$VAR_PACKAGE_ARCH"
  VAR_DISTRIB_REPO_DIR_PATH=$VAR_TMP_DIR_PATH/repos/linux/rpm/$VAR_CODE_NAME/RPMS/$VAR_PACKAGE_ARCH
  cp $PRM_PACKAGE_FILE $VAR_DISTRIB_REPO_DIR_PATH/
  if ! isRetValOK; then exitError; fi
  createrepo --update $VAR_DISTRIB_REPO_DIR_PATH/
  if ! isRetValOK; then exitError; fi
  rm $VAR_DISTRIB_REPO_DIR_PATH/repodata/repomd.xml.asc
  if ! isRetValOK; then exitError; fi
  gpg --detach-sign --armor $VAR_DISTRIB_REPO_DIR_PATH/repodata/repomd.xml
  if ! isRetValOK; then exitError; fi
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #git add and commit
  git add *
  git commit -m "add package $VAR_SHORT_FILE_NAME to $PRM_SUITE suite of distrib repository"
  if ! isRetValOK; then exitError; fi
  git push --all
  if ! isRetValOK; then exitError; fi
  #remove temporary directory
  cd $VAR_CUR_DIR_PATH
  if ! isRetValOK; then exitError; fi
  rm -fR $VAR_TMP_DIR_PATH
  if ! isRetValOK; then exitError; fi
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
  echo "APT-based Linux repository"
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
  if ! isRetValOK; then exitError; fi
  #add package
  echo "Add package $VAR_SHORT_FILE_NAME to $VAR_CODE_NAME CODENAME"
  reprepro -b $VAR_TMP_DIR_PATH/repos/linux/apt includedeb $VAR_CODE_NAME $PRM_PACKAGE_FILE
  if ! isRetValOK; then exitError; fi
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #git add and commit
  git add *
  git commit -m "add package $VAR_SHORT_FILE_NAME to $PRM_SUITE suite of distrib repository"
  if ! isRetValOK; then exitError; fi
  git push --all
  if ! isRetValOK; then exitError; fi
  #remove temporary directory
  cd $VAR_CUR_DIR_PATH
  if ! isRetValOK; then exitError; fi
  rm -fR $VAR_TMP_DIR_PATH
  if ! isRetValOK; then exitError; fi
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE" ]; then
  echo "Oracle Solaris repository"
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
  echo "FreeBSD repository"
fi
doneFinalStage
exitOK
