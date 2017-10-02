#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Make gitflow remote repository with tools submodule in develop branch'

##using files: none
##dependencies: git, git-flow AVH Edition

##private consts
CONST_STAGE_COUNT=5 #stage count

##private vars
PRM_SOURCE_DIRNAME='' #source directory name
PRM_REMOTEREPO='' #remote repository
PRM_TOOLSREPO='' #remote repository
CURRENT_DIRNAME='' #current directory name
TMP_DIRNAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<source directory> <remote repository> [tools repository=$COMMON_CONST_TOOLSREPO]' ". git@github.com:dishmaev/newrepo.git $COMMON_CONST_TOOLSREPO" "Remote repository possible empty, not initialized yet"

###check parms

PRM_SOURCE_DIRNAME=$1
#PRM_REMOTEREPO=$2
PRM_REMOTEREPO=git@github.com:dishmaev/newrepo.git
PRM_TOOLSREPO=$3

if [ -z "$PRM_SOURCE_DIRNAME" ] || [ ! -d $1 ]
then
  exitError "Source directory $1 missing or not exist!"
fi

if [ -z $PRM_REMOTEREPO ]
then
  exitError "Remote repository missing!"
fi

if ! isCommandExist 'git'
then
  exitError 'Git not found!'
fi

TMP_DIRNAME=$(mktemp -d)

if [ -z "$PRM_TOOLSREPO" ]
then
  PRM_TOOLSREPO=$COMMON_CONST_TOOLSREPO
fi

###start prompt

startPrompt

###body

beginStage 1 $CONST_STAGE_COUNT 'Clone remote repository to temporary directory'
git clone $PRM_REMOTEREPO $TMP_DIRNAME
CURRENT_DIRNAME=$PWD
cd $TMP_DIRNAME
if [ "$?" != "0" ]
then
  exitError
fi
doneStage

beginStage 2 $CONST_STAGE_COUNT 'Init gitflow branching model with default settings'
#init gitflow repository with default settings
git flow init -d
doneStage

beginStage 3 $CONST_STAGE_COUNT 'Add tools submodule'
#add tools submodule
git submodule add $PRM_TOOLSREPO
doneStage

beginStage 4 $CONST_STAGE_COUNT 'Commit changes and push to remote'
git commit -m 'add gitflow branching model, submodule tools'
git push --all
doneStage

beginStage 5 $CONST_STAGE_COUNT 'Delete temporary directory'
rm -fR $TMP_DIRNAME
cd $CURRENT_DIRNAME
doneFinalStage

echo 'Now clone repository by command below and start to work:'
echo 'git clone -b develop --recursive git@github.com:dishmaev/newrepo.git'
echo ''
echo 'Update tools submodule from master branch orinal repository by command:'
echo 'git submodule update --remote tools'
echo 'If need to change submodule update branch, change setting by command:'
echo 'git config -f .gitmodules submodule.tools.branch stable'


exitOK
