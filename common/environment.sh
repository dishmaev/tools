#!/bin/sh

##using files: consts.sh

#set correct path before using this tools
readonly ENV_ROOT_DIR=$(pwd | rev | sed 's!/!:!' | rev | awk -F: '{print $1}')
if isEmpty "$ENV_ROOT_DIR"; then checkNotEmptyEnvironment "ENV_ROOT_DIR"; fi
#script file name
readonly ENV_SCRIPT_FILE_NAME=$(basename "$0")
if isEmpty "$ENV_SCRIPT_FILE_NAME"; then checkNotEmptyEnvironment "ENV_SCRIPT_FILE_NAME"; fi
 #script directory name
readonly ENV_SCRIPT_DIR_NAME=$(dirname "$0")
if isEmpty "$ENV_SCRIPT_DIR_NAME"; then checkNotEmptyEnvironment "ENV_SCRIPT_DIR_NAME"; fi
#project name
readonly ENV_PROJECT_NAME=$(VP=$ENV_ROOT_DIR; if [ -f $ENV_ROOT_DIR/../../.gitmodules ] && [ $(grep "url = $ENV_TOOLS_REPO" $ENV_ROOT_DIR/../../.gitmodules | wc -l) = 1 ]; then VP=$VP/../..; fi; git -C $VP config remote.origin.url | awk -F/ '{print $(NF)}' | tr '[a-z]' '[A-Z]' | sed  -r 's/([.]GIT)$//')
if isEmpty "$ENV_PROJECT_NAME"; then checkNotEmptyEnvironment "ENV_PROJECT_NAME"; fi
#default git user
readonly ENV_GIT_USER_NAME=$(git config user.name)
if isEmpty "$ENV_GIT_USER_NAME"; then checkNotEmptyEnvironment "ENV_GIT_USER_NAME"; fi
#default git email
readonly ENV_GIT_USER_EMAIL=$(git config user.email)
if isEmpty "$ENV_GIT_USER_EMAIL"; then checkNotEmptyEnvironment "ENV_GIT_USER_EMAIL"; fi
#default username for connect to hosts, run scripts, etc.
readonly ENV_SSH_USER_NAME='toolsuser' #$(whoami)
if isEmpty "$ENV_SSH_USER_NAME"; then checkNotEmptyEnvironment "ENV_SSH_USER_NAME"; fi
#file with default password for $ENV_SSH_USER_NAME
readonly ENV_SSH_USER_PASS=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/sshpwd.txt; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; fi')
if isEmpty "$ENV_SSH_USER_PASS"; then checkNotEmptyEnvironment "ENV_SSH_USER_PASS"; fi
#ssh keyID, also key file name in ~/.ssh/
readonly ENV_SSH_KEYID=$(eval 'VAR_FILE_NAME=id_idax_rsa; if [ -r $HOME/.ssh/$VAR_FILE_NAME ]; then echo $VAR_FILE_NAME; fi')
if isEmpty "$ENV_SSH_KEYID"; then checkNotEmptyEnvironment "ENV_SSH_KEYID"; fi
#for add tools submodule
readonly ENV_TOOLS_REPO=$(git config remote.origin.url)
if isEmpty "$ENV_TOOLS_REPO"; then checkNotEmptyEnvironment "ENV_TOOLS_REPO"; fi
#default password, used by ovftool, password with escaped special characters using %, for instance %40 = @, %5c = \
readonly ENV_OVFTOOL_USER_PASS=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/ovftoolpwd.txt; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; fi')
if isEmpty "$ENV_OVFTOOL_USER_PASS"; then checkNotEmptyEnvironment "ENV_OVFTOOL_USER_PASS"; fi
#local directory to save downloads
readonly ENV_DOWNLOAD_PATH=$(if [ -d "$HOME/Downloads" ]; then echo "$HOME/Downloads"; fi)
if isEmpty "$ENV_DOWNLOAD_PATH"; then checkNotEmptyEnvironment "ENV_DOWNLOAD_PATH"; fi
#directory for project data
readonly ENV_PROJECT_DATA_PATH=$(if [ -f $ENV_ROOT_DIR/../../.gitmodules ] && [ $(grep "url = $ENV_TOOLS_REPO" $ENV_ROOT_DIR/../../.gitmodules | wc -l) = 1 ]; then echo $ENV_ROOT_DIR/../data; else echo ${ENV_ROOT_DIR}/project/data; fi;)
if isEmpty "$ENV_PROJECT_DATA_PATH"; then checkNotEmptyEnvironment "ENV_PROJECT_DATA_PATH"; fi
#directory for project triggers
readonly ENV_PROJECT_TRIGGER_PATH=$(if [ -f $ENV_ROOT_DIR/../../.gitmodules ] && [ $(grep "url = $ENV_TOOLS_REPO" $ENV_ROOT_DIR/../../.gitmodules | wc -l) = 1 ]; then echo $ENV_ROOT_DIR/../trigger; else echo ${ENV_ROOT_DIR}/project/trigger; fi;)
if isEmpty "$ENV_PROJECT_TRIGGER_PATH"; then checkNotEmptyEnvironment "ENV_PROJECT_TRIGGER_PATH"; fi

#vmware tools local directory
readonly COMMON_CONST_LOCAL_VMTOOLS_PATH="$ENV_DOWNLOAD_PATH/$COMMON_CONST_VMTOOLS_FILE_NAME"

#aliases
readonly SSH_CLIENT="ssh -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SCP_CLIENT="scp -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SSH_COPY_ID="ssh-copy-id -o StrictHostKeyChecking=no -i $HOME/.ssh/${ENV_SSH_KEYID}.pub"

#create project directories if not exist
if [ ! -d "$ENV_PROJECT_DATA_PATH" ]; then mkdir $ENV_PROJECT_DATA_PATH; fi
if [ ! -d "$ENV_PROJECT_TRIGGER_PATH" ]; then mkdir $ENV_PROJECT_TRIGGER_PATH; fi
