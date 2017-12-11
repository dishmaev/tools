#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Build and deploy of project $ENV_PROJECT_NAME"

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
#CONST_PROJECT_ACTION='build'

##private vars
PRM_SUITES_POOL='' #suite pool
PRM_VM_ROLES_POOL='' #roles for create VM pool
PRM_VERSION='' #version
PRM_ADD_TO_DISTRIB_REPOSITORY='' #add package to repository
VAR_RESULT='' #child return value
VAR_CUR_SUITE='' #current suite
VAR_CUR_VM_ROLE='' #current role for create VM

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '[suitesPool=$COMMON_CONST_DEVELOP_SUITE] [vmRolesPool=$COMMON_CONST_DEFAULT_VM_ROLE] [version=$COMMON_CONST_LOCAL_HEAD | $COMMON_CONST_REMOTE_DEVELOP_HEAD | tag/branch ] [addToDistribRepository=$COMMON_CONST_FALSE]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_LOCAL_HEAD $COMMON_CONST_FALSE" \
"Suites and roles must be selected without '*'. Version $COMMON_CONST_LOCAL_HEAD is HEAD of current branch on local git repository, version $COMMON_CONST_REMOTE_DEVELOP_HEAD is HEAD of develop branch on remote git repository, otherwise is tag or branch name. Available suites: $CONST_SUITES_POOL. Distrib repository: $ENV_DISTRIB_REPO"

###check commands

PRM_SUITES_POOL=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLES_POOL=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VERSION=${3:-$COMMON_CONST_LOCAL_HEAD}
PRM_ADD_TO_DISTRIB_REPOSITORY=${4:-$COMMON_CONST_FALSE}

checkCommandExist 'suitesPool' "$PRM_SUITES_POOL" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRolesPool' "$PRM_VM_ROLES_POOL" ''
checkCommandExist 'version' "$PRM_VERSION" ''
checkCommandExist 'addToDistribRepotory' "$PRM_ADD_TO_DISTRIB_REPOSITORY" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

checkDependencies 'git'
checkProjectRepository

###check required files

###start prompt

startPrompt

###body

for VAR_CUR_SUITE in $PRM_SUITES_POOL; do
  for VAR_CUR_VM_ROLE in $PRM_VM_ROLES_POOL; do
    echoInfo "start build project $ENV_PROJECT_NAME suite $VAR_CUR_SUITE role $VAR_CUR_VM_ROLE"
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/build_project.sh -y $VAR_CUR_SUITE $VAR_CUR_VM_ROLE $PRM_VERSION $PRM_ADD_TO_DISTRIB_REPOSITORY) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
    echoInfo "start deploy project $ENV_PROJECT_NAME suite $VAR_CUR_SUITE role $VAR_CUR_VM_ROLE"
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/deploy_project.sh -y $VAR_CUR_SUITE $VAR_CUR_VM_ROLE) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
  done
done

doneFinalStage
exitOK
