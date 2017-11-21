#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Make gitflow branch model for remote repository, with tools submodule in develop branch'

##private consts
readonly CONST_STAGE_COUNT=5 #stage count
readonly CONST_GITFLOW_FILE='/usr/lib/git-core/git-flow' #for check git-flow exist

##private vars
PRM_REMOTE_REPO='' #target remote repository
PRM_TOOLS_REPO='' #tools repository
VAR_CUR_DIR_PATH='' #current directory name
VAR_TMP_DIR_PATH='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<remoteRepository> [toolsRepository=$ENV_TOOLS_REPO]' \
      ". git@github.com:$ENV_GIT_USER_NAME/newrepo.git $ENV_TOOLS_REPO" \
      "Remote repository possible empty, not initialized yet. Required git-flow package. Gitflow branch model details http://nvie.com/posts/a-successful-git-branching-model/"

###check commands

PRM_REMOTE_REPO=$1
PRM_TOOLS_REPO=${2:-$ENV_TOOLS_REPO}

checkCommandExist 'remoteRepository' "$PRM_REMOTE_REPO" ''
checkCommandExist 'toolsRepository' "$PRM_TOOLS_REPO" ''

checkRequiredFiles "$CONST_GITFLOW_FILE"

###check body dependencies

checkDependencies 'git mktemp'
checkGitUserAndEmail

###start prompt

startPrompt

###body

#new stage
beginStage $CONST_STAGE_COUNT 'Clone remote repository to temporary directory'
VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
git clone $PRM_REMOTE_REPO $VAR_TMP_DIR_PATH
checkRetValOK
VAR_CUR_DIR_PATH=$PWD
cd $VAR_TMP_DIR_PATH
checkRetValOK
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Init gitflow branching model with default settings'
#init gitflow repository with default settings
git flow init -d
checkRetValOK
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Add tools submodule'
#add tools submodule
mkdir tools
checkRetValOK
cd tools
checkRetValOK
git submodule add --name tools $PRM_TOOLS_REPO bin
checkRetValOK
#mkdir data
#checkRetValOK
#mkdir trigger
#checkRetValOK
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Commit changes and push to remote'
git commit -m 'add gitflow branching model, tools submodule'
checkRetValOK
git push --all
checkRetValOK
doneStage
#new stage
beginStage $CONST_STAGE_COUNT 'Delete temporary directory'
cd $VAR_CUR_DIR_PATH
checkRetValOK
rm -fR $VAR_TMP_DIR_PATH
checkRetValOK
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
