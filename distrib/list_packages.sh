#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Get packages list from a distrib repository'

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_APT_CODE_NAME_STABLE='stable'
CONST_APT_CODE_NAME_TESTING='testing'
CONST_APT_CODE_NAME_UNSTABLE='unstable'
CONST_SHOW_ALL='*'

##private vars
PRM_VM_TEMPLATE='' #vm template
PRM_FILTER_REGEX='' #build file name
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository
VAR_TMP_DIR_NAME='' #temporary directory name
VAR_CODE_NAME=$CONST_APT_CODE_NAME_UNSTABLE #code name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4  '<vmTemplate> [filterRegex=$CONST_SHOW_ALL] [suite=$COMMON_CONST_DEVELOP_SUITE] [distribRepository=$ENV_DISTRIB_REPO]' \
"$COMMON_CONST_PHOTON_VM_TEMPLATE '$CONST_SHOW_ALL' $COMMON_CONST_DEVELOP_SUITE $ENV_DISTRIB_REPO" \
"Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_VM_TEMPLATE=$1
PRM_FILTER_REGEX=${2:-$CONST_SHOW_ALL}
PRM_SUITE=${3:-$COMMON_CONST_DEVELOP_SUITE}
PRM_DISTRIB_REPO=${4:-$ENV_DISTRIB_REPO}

checkCommandExist 'vmTemplate' "$PRM_VM_TEMPLATE" "$COMMON_CONST_VM_TEMPLATES_POOL"
checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''
checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "$PRM_FILTER_REGEX"

###start prompt

startPrompt

###body

if [ "$PRM_VM_TEMPLATE" = "$COMMON_CONST_PHOTON_VM_TEMPLATE" ] || \
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
  echo "Begin list"
  reprepro -b $VAR_TMP_DIR_NAME/repos/linux/apt list $VAR_CODE_NAME | grep -E "$PRM_FILTER_REGEX"
  if ! isRetValOK; then exitError; fi
  echo "End list"
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
