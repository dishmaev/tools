#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'My short operation script description'

##using files: none
##dependencies: none

##private consts


##private vars


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<parm>' "parmValue" "tooltip"

###check parms

#comments


###start prompt

startPrompt

###body

#comments


exitOK
