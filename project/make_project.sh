#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Build and deploy of project $ENV_PROJECT_NAME"

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
#CONST_PROJECT_ACTION='build'

##private vars
PRM_VERSION='' #version
PRM_SUITE='' #suite
PRM_VM_ROLE='' #role for create VM
PRM_ADD_TO_DISTRIB_REPOSITORY='' #add package to repository
PRM_DISTRIB_REPO='' #distrib repository
VAR_RESULT='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 5 '[suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE] [version=$COMMON_CONST_DEFAULT_VERSION] [addToDistribRepository=$COMMON_CONST_FALSE] [distribRepository=$ENV_DISTRIB_REPO]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_FALSE $ENV_DISTRIB_REPO" \
"Version $COMMON_CONST_DEFAULT_VERSION is HEAD of develop branch, otherwise is tag or branch name. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_SUITE=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VERSION=${3:-$COMMON_CONST_DEFAULT_VERSION}
PRM_ADD_TO_DISTRIB_REPOSITORY=${4:-$COMMON_CONST_FALSE}
PRM_DISTRIB_REPO=${5:-$ENV_DISTRIB_REPO}

checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''
checkCommandExist 'version' "$PRM_VERSION" ''
checkCommandExist 'addToDistribRepotory' "$PRM_ADD_TO_DISTRIB_REPOSITORY" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

checkDependencies 'git'
checkProjectRepository

###check required files

###start prompt

startPrompt

###body

echoInfo "start build project $ENV_PROJECT_NAME"
VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/build_project.sh -y $PRM_SUITE $PRM_VM_ROLE $PRM_VERSION $PRM_ADD_TO_DISTRIB_REPOSITORY $PRM_DISTRIB_REPO) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"

echoInfo "start deploy project $ENV_PROJECT_NAME"
VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/deploy_project.sh -y $PRM_SUITE $PRM_VM_ROLE) || exitChildError "$VAR_RESULT"
echoResult "$VAR_RESULT"

doneFinalStage
exitOK
