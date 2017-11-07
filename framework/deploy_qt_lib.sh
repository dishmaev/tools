#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Qt5 on the local OS'

##private consts


##private vars
VAR_LINUX_BASED='' #for checking supported OS


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '' "" ""

###check commands

#comments

###check body dependencies

checkDependencies ''

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#check supported OS
if ! isLinuxOS; then exitError 'not supported OS'; fi
VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
if ! isAPTLinux $VAR_LINUX_BASED; then exitError 'not supported OS'; fi

doneFinalStage
exitOK
