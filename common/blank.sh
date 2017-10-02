#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'My short operation script description'

##private consts


##private vars


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<parm>' "parmValue" "tooltip"

###check parms

#comments

###check dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles 'file1 file2 file3'

###start prompt

startPrompt

###body

#comments


exitOK
