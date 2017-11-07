#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Make gitflow branch model for remote repository, with tools submodule in develop branch'

##private consts
readonly CONST_STAGE_COUNT=5 #stage count

##private vars
PRM_SOURCE_DIR_NAME='' #source directory name
PRM_REMOTE_REPO='' #remote repository
PRM_TOOLS_REPO='' #remote repository
VAR_CUR_DIR_NAME='' #current directory name
VAR_TMP_DIR_NAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 3 '<sourceDirectory> <remoteRepository> [toolsRepository=$ENV_TOOLS_REPO]' \
      ". git@github.com:$ENV_GIT_USER_NAME/newrepo.git $ENV_TOOLS_REPO" \
      "Remote repository possible empty, not initialized yet. Required git-flow package. Branch model details http://nvie.com/posts/a-successful-git-branching-model/"

###check commands

PRM_SOURCE_DIR_NAME=$1
PRM_REMOTE_REPO=$2
PRM_TOOLS_REPO=${3:-$ENV_TOOLS_REPO}

checkCommandExist 'sourceDirectory' "$PRM_SOURCE_DIR_NAME" ''
checkCommandExist 'remoteRepository' "$PRM_REMOTE_REPO" ''
checkCommandExist 'toolsRepository' "$PRM_TOOLS_REPO" ''

checkDirectoryForExist "$PRM_SOURCE_DIR_NAME" ''

###check body dependencies

checkDependencies 'mktemp git'

###start prompt

startPrompt

###body

#new stage
beginStage $CONST_STAGE_COUNT 'Clone remote repository to temporary directory'
VAR_TMP_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_NAME"
git clone $PRM_REMOTE_REPO $VAR_TMP_DIR_NAME
VAR_CUR_DIR_NAME=$PWD
cd $VAR_TMP_DIR_NAME
if ! isRetValOK; then exitError; fi
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Init gitflow branching model with default settings'
#init gitflow repository with default settings
git flow init -d
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Add tools submodule'
#add tools submodule
git submodule add $PRM_TOOLS_REPO
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Commit changes and push to remote'
git commit -m 'add gitflow branching model, submodule tools'
git push --all
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Delete temporary directory'
rm -fR $VAR_TMP_DIR_NAME
cd $VAR_CUR_DIR_NAME
doneFinalStage

echo ''
echo 'Now clone repository by command below and start to work:'
echo "git clone -b develop --recursive $PRM_REMOTE_REPO"
echo ''
echo 'Update tools submodule from master branch orinal repository by command:'
echo 'git submodule update --remote tools'
echo 'If you need to change submodule update branch, change setting by command:'
echo 'git config -f .gitmodules submodule.tools.branch <newBranch>'

exitOK
