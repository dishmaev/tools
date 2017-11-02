#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Create project snapshot on VMs esxi hosts pool'

##private consts


##private vars


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<command>' "commandValue" "tooltip"

###check commands

#comments

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
