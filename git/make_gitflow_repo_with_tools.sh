#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Make gitflow branch model for remote repository, with tools submodule in develop branch'

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

echoHelp $# 3 '<source directory> <remote repository> [tools repository=$COMMON_CONST_TOOLSREPO]' \
      ". git@github.com:dishmaev/newrepo.git $COMMON_CONST_TOOLSREPO" \
      "Remote repository possible empty, not initialized yet. Required git-flow package"

###check commands

PRM_SOURCE_DIRNAME=$1
#PRM_REMOTEREPO=$2
PRM_REMOTEREPO='' #git@github.com:dishmaev/newrepo.git
PRM_TOOLSREPO=$3

checkDirectoryForExist "$PRM_SOURCE_DIRNAME"

checkCommandExist 'remote repository' $PRM_REMOTEREPO

if [ -z "$PRM_TOOLSREPO" ]
then
  PRM_TOOLSREPO=$COMMON_CONST_TOOLSREPO
fi

###check body dependencies

checkDependencies 'mktemp git'

###start prompt

startPrompt

###body

beginStage 1 $CONST_STAGE_COUNT 'Clone remote repository to temporary directory'
TMP_DIRNAME=$(mktemp -d)
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
echo "git clone -b develop --recursive $PRM_REMOTEREPO"
echo ''
echo 'Update tools submodule from master branch orinal repository by command:'
echo 'git submodule update --remote tools'
echo 'If need to change submodule update branch, change setting by command:'
echo 'git config -f .gitmodules submodule.tools.branch <branch>'

exitOK
