#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Remove package to a distrib repository'

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_RELEASE_CODE_NAME_APT='stable'
CONST_TEST_CODE_NAME_APT='testing'
CONST_DEVELOP_CODE_NAME_APT='unstable'
CONST_RELEASE_CODE_NAME_RPM='release'
CONST_TEST_CODE_NAME_RPM='test'
CONST_DEVELOP_CODE_NAME_RPM='develop'

##private vars
PRM_PACKAGE_NAME='' #package name
PRM_VM_TEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository
VAR_CODE_NAME='' #code name
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name
VAR_DISTRIB_REPO_DIR_PATH='' #local path of distrib repository
VAR_CUR_FILE_PATH='' #file name
VAR_SHORT_FILE_NAME='' #short file name of $PRM_PACKAGE_NAME
VAR_FOUND=$COMMON_CONST_FALSE #found flag

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<package=name | file> <vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [distribRepository=$ENV_DISTRIB_REPO]' \
"myPackage $COMMON_CONST_DEBIANMINI_VM_TEMPLATE $COMMON_CONST_DEVELOP_SUITE $ENV_DISTRIB_REPO" \
"For APT-based Linux repository select package name, for RPM-based Linux repository select package file. Required gpg secret keyID $COMMON_CONST_GPG_KEYID. Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_PACKAGE_NAME=$1
PRM_VM_TEMPLATE=$2
PRM_SUITE=${3:-$COMMON_CONST_DEVELOP_SUITE}
PRM_DISTRIB_REPO=${4:-$ENV_DISTRIB_REPO}

checkCommandExist 'package' "$PRM_PACKAGE_NAME" ''
checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

checkDependencies 'git'
checkGitUserAndEmail

###check required files

#checkRequiredFiles "$PRM_PACKAGE_NAME"

###start prompt

startPrompt

###body

if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTONFULL_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_CENTOSMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_CENTOSGUI_VM_TEMPLATE" ] || \
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
  VAR_SHORT_FILE_NAME=$(getFileNameFromUrlString "$PRM_PACKAGE_NAME") || exitChildError "$VAR_CUR_FILE_NAME"
  VAR_DISTRIB_REPO_DIR_PATH=$VAR_TMP_DIR_PATH/repos/linux/rpm/$VAR_CODE_NAME/RPMS
  if isFileExistAndRead "$VAR_DISTRIB_REPO_DIR_PATH/x86_64/$VAR_SHORT_FILE_NAME"; then
    rm "$VAR_DISTRIB_REPO_DIR_PATH/x86_64/$VAR_SHORT_FILE_NAME"
    VAR_DISTRIB_REPO_DIR_PATH=$VAR_DISTRIB_REPO_DIR_PATH/x86_64
    VAR_FOUND=$COMMON_CONST_TRUE
  else
    if isFileExistAndRead "$VAR_DISTRIB_REPO_DIR_PATH/noarch/$VAR_SHORT_FILE_NAME"; then
      rm "$VAR_DISTRIB_REPO_DIR_PATH/noarch/$VAR_SHORT_FILE_NAME"
      VAR_DISTRIB_REPO_DIR_PATH=$VAR_DISTRIB_REPO_DIR_PATH/noarch
      VAR_FOUND=$COMMON_CONST_TRUE
    fi
  fi
  if ! isTrue "$VAR_FOUND"; then
    rm -fR $VAR_TMP_DIR_PATH
    checkRetValOK
    exitError "file $VAR_SHORT_FILE_NAME not found on the repository"
  else
    createrepo --update $VAR_DISTRIB_REPO_DIR_PATH
    checkRetValOK
    rm $VAR_DISTRIB_REPO_DIR_PATH/repodata/repomd.xml.asc
    checkRetValOK
    gpg --detach-sign --armor $VAR_DISTRIB_REPO_DIR_PATH/repodata/repomd.xml
    checkRetValOK
  fi
  #remove package
  echoInfo "remove package $PRM_PACKAGE_NAME from $VAR_CODE_NAME CODENAME"
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #git add and commit
  git add *
  git commit -m "remove package $PRM_PACKAGE_NAME from $PRM_SUITE suite of distrib repository"
  checkRetValOK
  git push --all
  checkRetValOK
  #remote temporary directory
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
elif [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ] || \
[ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_DEBIANGUI_VM_TEMPLATE" ] || \
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
  #add package
  echoInfo "remove package $PRM_PACKAGE_NAME from $VAR_CODE_NAME CODENAME"
  reprepro -b $VAR_TMP_DIR_PATH/repos/linux/apt remove $VAR_CODE_NAME $PRM_PACKAGE_NAME
  checkRetValOK
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  #git add and commit
  git add *
  git commit -m "remove package $PRM_PACKAGE_NAME from $PRM_SUITE suite of distrib repository"
  checkRetValOK
  git push --all
  checkRetValOK
  #remote temporary directory
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
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
