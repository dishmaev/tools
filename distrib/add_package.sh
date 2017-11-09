#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Add package file to a distrib repository'

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"

##private vars
PRM_PACKAGE_FILE='' #build file name
PRM_VM_TEMPLATE='' #vm template
PRM_SUITE='' #suite
PRM_DISTRIB_REPO='' #distrib repository

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '<packageFile> <vmTemplate> [suite=$COMMON_CONST_DEVELOP_SUITE] [distribRepository=$ENV_DISTRIB_REPO]' \
"myFile $COMMON_CONST_PHOTON_VM_TEMPLATE $COMMON_CONST_DEVELOP_SUITE $ENV_DISTRIB_REPO" \
"Required gpg secret keyID $COMMON_CONST_GPG_KEYID. Available VM templates: $COMMON_CONST_VM_TEMPLATES_POOL. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_PACKAGE_FILE=$1
PRM_VM_TEMPLATE=$2
PRM_SUITE=${3:-$COMMON_CONST_DEVELOP_SUITE}
PRM_DISTRIB_REPO=${4:-$ENV_DISTRIB_REPO}

checkCommandExist 'packageFile' "$PRM_BUILD_FILE" ''
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

#comments

doneFinalStage
exitOK
