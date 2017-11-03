#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Deploy build file for incorp project $COMMON_CONST_PROJECTNAME"

##private consts


##private vars
PRM_FILENAME='' #build file name
PRM_SUITE='' #suite
PRM_SCRIPTVERSION='' #version script for deploy VM

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<fileName> [suite=$COMMON_CONST_DEVELOP_SUITE] [scriptVersion=$COMMON_CONST_DEFAULT_VERSION]' \
"myfile $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VERSION" \
"Available suites: $COMMON_CONST_SUITES_POOL"

###check commands

PRM_FILENAME=$1
PRM_SCRIPTVERSION=${2:-$COMMON_CONST_DEFAULT_VERSION}

checkCommandExist 'fileName' "$PRM_FILENAME" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#comments

doneFinalStage
exitOK
