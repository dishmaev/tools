#!/bin/sh

##using files: consts.sh, function.sh

#set correct path before using this tools
readonly ENV_ROOT_DIR=$(cd $(dirname "$0")/..; pwd)
if isEmpty "$ENV_ROOT_DIR"; then checkNotEmptyEnvironment "ENV_ROOT_DIR"; fi
#script file name
readonly ENV_SCRIPT_FILE_NAME=$(basename "$0")
if isEmpty "$ENV_SCRIPT_FILE_NAME"; then checkNotEmptyEnvironment "ENV_SCRIPT_FILE_NAME"; fi
 #script directory name
readonly ENV_SCRIPT_DIR_NAME=$(dirname "$0")
if isEmpty "$ENV_SCRIPT_DIR_NAME"; then checkNotEmptyEnvironment "ENV_SCRIPT_DIR_NAME"; fi
#submodule mode
readonly ENV_SUBMODULE_MODE=$(if [ -r $ENV_ROOT_DIR/../../.gitmodules ] && [ $(grep "url = $ENV_TOOLS_REPO" $ENV_ROOT_DIR/../../.gitmodules | wc -l) = 1 ]; then echo $COMMON_CONST_TRUE; else echo $COMMON_CONST_FALSE; fi)
if isEmpty "$ENV_SUBMODULE_MODE"; then checkNotEmptyEnvironment "ENV_SUBMODULE_MODE"; fi
#project name
readonly ENV_PROJECT_NAME=$(VP=$ENV_ROOT_DIR; VL=$(if [ "$ENV_SUBMODULE_MODE" = "$COMMON_CONST_TRUE" ]; then VP=$VP/../..; fi; if [ -x "$(command -v git)" ]; then cd $VP; git config remote.origin.url | awk -F/ '{print $(NF)}' | tr '[a-z]' '[A-Z]' | sed  -E 's/([.]GIT)$//' ; fi); if [ -z "$VL" ]; then VL=$(getFileNameFromUrlString "$ENV_ROOT_DIR" | tr '[a-z]' '[A-Z]'); fi; echo $VL)
if isEmpty "$ENV_PROJECT_NAME"; then checkNotEmptyEnvironment "ENV_PROJECT_NAME"; fi
#project repository
readonly ENV_PROJECT_REPO=$(VP=$ENV_ROOT_DIR; if [ "$ENV_SUBMODULE_MODE" = "$COMMON_CONST_TRUE" ]; then VP=$VP/../..; fi; if [ -x "$(command -v git)" ]; then cd $VP; git config remote.origin.url; fi)
#default username for connect to hosts, run scripts, etc.
readonly ENV_SSH_USER_NAME=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/user.txt; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; else echo $(whoami); fi')
if isEmpty "$ENV_SSH_USER_NAME"; then checkNotEmptyEnvironment "ENV_SSH_USER_NAME"; fi
#file with default password for $ENV_SSH_USER_NAME
readonly ENV_SSH_USER_PASS=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/ssh_pwd.txt; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; fi')
#ssh public keyID
readonly ENV_SSH_KEYID=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/ssh_keyid.pub; if [ -r $VAR_FILE_NAME ]; then echo $VAR_FILE_NAME; fi')
if isEmpty "$ENV_SSH_KEYID"; then checkNotEmptyEnvironment "ENV_SSH_KEYID"; fi
#ssh identity file name
readonly ENV_SSH_IDENTITY_FILE_NAME=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/ssh_id_file.txt; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; fi')
if isEmpty "$ENV_SSH_IDENTITY_FILE_NAME"; then checkNotEmptyEnvironment "ENV_SSH_IDENTITY_FILE_NAME"; fi
#default git user
readonly ENV_GIT_USER_NAME=$(if [ -x "$(command -v git)" ]; then git config user.name; fi)
#default git email
readonly ENV_GIT_USER_EMAIL=$(if [ -x "$(command -v git)" ]; then git config user.email; fi)
#distrib repository
readonly ENV_DISTRIB_REPO="git@github.com:$ENV_GIT_USER_NAME/$ENV_GIT_USER_NAME.github.io.git"
if isEmpty "$ENV_DISTRIB_REPO"; then checkNotEmptyEnvironment "ENV_DISTRIB_REPO"; fi
#for add tools submodule
readonly ENV_TOOLS_REPO=$(if [ -x "$(command -v git)" ]; then git config remote.origin.url; fi)
#default password, used by ovftool, password with escaped special characters using %, for instance %40 = @, %5c = \
readonly ENV_OVFTOOL_USER_PASS=$(getOVFToolPassword "$ENV_SSH_USER_PASS")
#local directory to save downloads
readonly ENV_DOWNLOAD_PATH=$(if [ ! -d "$HOME/Downloads/tools" ]; then mkdir -p "$HOME/Downloads/tools"; fi; echo "$HOME/Downloads/tools")
if isEmpty "$ENV_DOWNLOAD_PATH"; then checkNotEmptyEnvironment "ENV_DOWNLOAD_PATH"; fi
#directory for project data
readonly ENV_PROJECT_DATA_PATH=$(if [ "$ENV_SUBMODULE_MODE" = "$COMMON_CONST_TRUE" ]; then echo $(getParentDirectoryPath $ENV_ROOT_DIR)/data; else echo ${ENV_ROOT_DIR}/project/data; fi;)
if isEmpty "$ENV_PROJECT_DATA_PATH"; then checkNotEmptyEnvironment "ENV_PROJECT_DATA_PATH"; fi
#directory for project triggers
readonly ENV_PROJECT_TRIGGER_PATH=$(if [ "$ENV_SUBMODULE_MODE" = "$COMMON_CONST_TRUE" ]; then echo $(getParentDirectoryPath $ENV_ROOT_DIR)/trigger; else echo ${ENV_ROOT_DIR}/project/trigger; fi;)
if isEmpty "$ENV_PROJECT_TRIGGER_PATH"; then checkNotEmptyEnvironment "ENV_PROJECT_TRIGGER_PATH"; fi
readonly ENV_TOOLS_HIDDEN_PATH="$HOME/.tools"
if isEmpty "$ENV_TOOLS_HIDDEN_PATH"; then checkNotEmptyEnvironment "ENV_TOOLS_HIDDEN_PATH"; fi
readonly ENV_SHELL_WITH_ESC=$(eval 'VAR_COUNT=$(echo "a\nb" | wc -l); if [ $VAR_COUNT -eq 1 ]; then echo '$COMMON_CONST_FALSE'; else echo '$COMMON_CONST_TRUE'; fi')
if isEmpty "$ENV_SHELL_WITH_ESC"; then checkNotEmptyEnvironment "ENV_SHELL_WITH_ESC"; fi
readonly ENV_DEFAULT_VM_TEMPLATE=$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/vm_template.cfg; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; else echo '$COMMON_CONST_DEBIANMINI_VM_TEMPLATE'; fi')
if isEmpty "$ENV_DEFAULT_VM_TEMPLATE"; then checkNotEmptyEnvironment "ENV_DEFAULT_VM_TEMPLATE"; fi
readonly ENV_VM_TYPES_POOL="$(eval 'VAR_FILE_NAME='$ENV_ROOT_DIR'/common/data/vm_types.cfg; if [ -r $VAR_FILE_NAME ]; then cat $VAR_FILE_NAME; else echo '"$COMMON_CONST_VM_TYPES_POOL"'; fi')"
if isEmpty "$ENV_VM_TYPES_POOL"; then checkNotEmptyEnvironment "ENV_VM_TYPES_POOL"; fi
readonly ENV_DEFAULT_VM_TYPE=$(echo $ENV_VM_TYPES_POOL | awk '{print $(NF)}')
if isEmpty "$ENV_DEFAULT_VM_TYPE"; then checkNotEmptyEnvironment "ENV_DEFAULT_VM_TYPE"; fi

#vmware tools local directory
readonly COMMON_CONST_LOCAL_VMTOOLS_PATH="$ENV_DOWNLOAD_PATH/$COMMON_CONST_VMTOOLS_FILE_NAME"
readonly COMMON_CONST_LOCAL_VMS_PATH="$ENV_TOOLS_HIDDEN_PATH/vms"
readonly COMMON_CONST_LOCAL_DATA_PATH="$ENV_TOOLS_HIDDEN_PATH/data"
readonly COMMON_CONST_LOCAL_BUILDS_PATH="$ENV_TOOLS_HIDDEN_PATH/builds"
readonly COMMON_CONST_LOCAL_LOGS_PATH="$ENV_TOOLS_HIDDEN_PATH/logs"

#aliases
readonly SSH_CLIENT="ssh -o PreferredAuthentications=publickey -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SSHP_CLIENT="ssh -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SSHX_CLIENT="ssh -X -o PreferredAuthentications=publickey -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SCP_CLIENT="scp -o PreferredAuthentications=publickey -o StrictHostKeyChecking=no -o User=$ENV_SSH_USER_NAME"
readonly SSH_COPY_ID="ssh-copy-id -o StrictHostKeyChecking=no -f -i $ENV_SSH_KEYID"

#create directories if not exist
if [ ! -d "$ENV_PROJECT_DATA_PATH" ]; then mkdir $ENV_PROJECT_DATA_PATH; fi
if [ ! -d "$ENV_PROJECT_TRIGGER_PATH" ]; then mkdir $ENV_PROJECT_TRIGGER_PATH; fi
if [ ! -d "$COMMON_CONST_LOCAL_VMS_PATH" ]; then mkdir -p $COMMON_CONST_LOCAL_VMS_PATH; fi
if [ ! -d "$COMMON_CONST_LOCAL_DATA_PATH" ]; then mkdir -p $COMMON_CONST_LOCAL_DATA_PATH; fi
if [ ! -d "$COMMON_CONST_LOCAL_BUILDS_PATH" ]; then mkdir -p $COMMON_CONST_LOCAL_BUILDS_PATH; fi
if [ ! -d "$COMMON_CONST_LOCAL_LOGS_PATH" ]; then mkdir -p $COMMON_CONST_LOCAL_LOGS_PATH; fi
