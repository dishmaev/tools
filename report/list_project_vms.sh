#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "List of VMs project $ENV_PROJECT_NAME"


##private consts


##private vars
PRM_FILTER_REGEX='' #build file name
VAR_RESULT='' #child return value


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[filterRegex=$COMMON_CONST_ALL]' "$COMMON_CONST_ALL" ''

###check commands

PRM_FILTER_REGEX=${1:-$COMMON_CONST_ALL}

checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#comments

echoInfo "begin list"
echoResult "$VAR_RESULT"
echoInfo "end list"

doneFinalStage
exitOK
