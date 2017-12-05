#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Build of project $ENV_PROJECT_NAME"

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_PROJECT_ACTION='build'
CONST_MAKE_OUTPUT=$(echo $ENV_PROJECT_NAME | tr '[A-Z]' '[a-z]')

##private vars
PRM_VERSION='' #version
PRM_SUITE='' #suite
PRM_VM_ROLE='' #role for create VM
PRM_ADD_TO_DISTRIB_REPOSITORY='' #add package to repository
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_IP='' #vm ip address
VAR_SRC_TAR_FILE_NAME='' #source archive file name
VAR_SRC_TAR_FILE_PATH='' #source archive file name with local path
VAR_BIN_TAR_FILE_NAME='' #binary archive file name
VAR_BIN_TAR_FILE_PATH='' #binary archive file name with local path
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vbox vm by ssh
VAR_LOG='' #log execute script

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 4 '[suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE] [version=$COMMON_CONST_DEFAULT_VERSION] [addToDistribRepository=$COMMON_CONST_FALSE]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_FALSE" \
"Version $COMMON_CONST_DEFAULT_VERSION is HEAD of develop branch, otherwise is tag or branch name. Available suites: $CONST_SUITES_POOL. Distrib repository: $ENV_DISTRIB_REPO"

###check commands

PRM_SUITE=${1:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_VERSION=${3:-$COMMON_CONST_DEFAULT_VERSION}
PRM_ADD_TO_DISTRIB_REPOSITORY=${4:-$COMMON_CONST_FALSE}

checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''
checkCommandExist 'version' "$PRM_VERSION" ''
checkCommandExist 'addToDistribRepotory' "$PRM_ADD_TO_DISTRIB_REPOSITORY" "$COMMON_CONST_BOOL_VALUES"

###check body dependencies

checkDependencies 'git tar'
checkProjectRepository

###check required files

###start prompt

startPrompt

###body

#$1 $VAR_BIN_TAR_FILE_PATH, $2 $VAR_VM_TEMPLATE, $3 $PRM_SUITE
addToDistribRepotory(){
  local VAR_RESULT=''
  local VAR_TMP_DIR_PATH='' #temporary directory name
  local VAR_PACKAGE_EXT='' #extention package
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  tar -xvf ${1} -C $VAR_TMP_DIR_PATH/
  checkRetValOK
  for VAR_CUR_PACKAGE in $VAR_TMP_DIR_PATH/*.deb; do
    if [ ! -r "$VAR_CUR_PACKAGE" ]; then continue; fi
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../distrib/add_package.sh -y $VAR_CUR_PACKAGE $COMMON_CONST_DEBIANMINI_VM_TEMPLATE $3) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
  done
  for VAR_CUR_PACKAGE in $VAR_TMP_DIR_PATH/*.rpm; do
    if [ ! -r "$VAR_CUR_PACKAGE" ]; then continue; fi
    VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../distrib/add_package.sh -y $VAR_CUR_PACKAGE $COMMON_CONST_CENTOSMINI_VM_TEMPLATE $3) || exitChildError "$VAR_RESULT"
    echoResult "$VAR_RESULT"
  done
  echoWarning "TO-DO add Oracle Solaris packages"
  echoWarning "TO-DO add FreeBSD packages"
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
  return $COMMON_CONST_EXIT_SUCCESS
}

#$1 $PRM_VERSION, $2 $VAR_SRC_TAR_FILE_PATH
packSourceFiles(){
  local VAR_TMP_DIR_PATH='' #temporary directory name
  local VAR_CUR_DIR_PATH='' #current directory name
  VAR_TMP_DIR_PATH=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_PATH"
  if [ "$1" = "$COMMON_CONST_DEFAULT_VERSION" ]; then
    git clone -b develop $ENV_PROJECT_REPO $VAR_TMP_DIR_PATH
  else
    git clone -b $1 $ENV_PROJECT_REPO $VAR_TMP_DIR_PATH
  fi
  checkRetValOK
  VAR_CUR_DIR_PATH=$PWD
  cd $VAR_TMP_DIR_PATH
  checkRetValOK
  #make archive
  git archive --format=tar.gz -o $2 HEAD
  checkRetValOK
  #remote temporary directory
  cd $VAR_CUR_DIR_PATH
  checkRetValOK
  rm -fR $VAR_TMP_DIR_PATH
  checkRetValOK
  return $COMMON_CONST_EXIT_SUCCESS
}

VAR_CONFIG_FILE_NAME=${COMMON_CONST_RUNNER_SUITE}_${PRM_VM_ROLE}.cfg
VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
if ! isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
  echoWarning "config file $VAR_CONFIG_FILE_PATH not found, required new project VM"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/create_vm_project.sh -y $ENV_DEFAULT_VM_TEMPLATE $COMMON_CONST_RUNNER_SUITE $PRM_VM_ROLE) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  checkRequiredFiles "$VAR_CONFIG_FILE_PATH"
fi

VAR_RESULT=$(getProjectVMForAction "$CONST_PROJECT_ACTION" "$COMMON_CONST_RUNNER_SUITE" "$PRM_VM_ROLE") || exitChildError "$VAR_RESULT"
if isEmpty "$VAR_RESULT"; then
  exitError "not available any VM for project action $CONST_PROJECT_ACTION suite $COMMON_CONST_RUNNER_SUITE role $PRM_VM_ROLE"
fi
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_VM_TYPE"
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"

VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${PRM_VM_ROLE}_${CONST_PROJECT_ACTION}
VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
if [ "$PRM_VM_ROLE" != "$COMMON_CONST_DEFAULT_VM_ROLE" ] && ! isFileExistAndRead "$VAR_SCRIPT_FILE_PATH"; then
  VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${COMMON_CONST_DEFAULT_VM_ROLE}_${CONST_PROJECT_ACTION}
  VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh
  echoWarning "trigger script for role $PRM_VM_ROLE not found, try to use script for role $COMMON_CONST_DEFAULT_VM_ROLE"
fi
checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"

#add package file name extention
VAR_SRC_TAR_FILE_NAME=${CONST_MAKE_OUTPUT}-${PRM_SUITE}-${PRM_VM_ROLE}-src.tar.gz
VAR_SRC_TAR_FILE_PATH=$COMMON_CONST_LOCAL_BUILDS_PATH/$VAR_SRC_TAR_FILE_NAME
VAR_BIN_TAR_FILE_NAME=${CONST_MAKE_OUTPUT}-${PRM_SUITE}-${PRM_VM_ROLE}-bin.tar.gz
VAR_BIN_TAR_FILE_PATH=$COMMON_CONST_LOCAL_BUILDS_PATH/$VAR_BIN_TAR_FILE_NAME
#remove old files
rm -f "$VAR_SRC_TAR_FILE_PATH" "$VAR_BIN_TAR_FILE_PATH"

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
  checkSSHKeyExistEsxi "$VAR_HOST"
  #restore project snapshot
  echoInfo "restore VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME on $VAR_HOST host"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVMEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  echoInfo "create the archive file $VAR_SRC_TAR_FILE_PATH with sources"
  packSourceFiles "$PRM_VERSION" "$VAR_SRC_TAR_FILE_PATH"
  checkRetValOK
  #copy git archive on vm
  VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_FALSE") || exitChildError "$VAR_VM_IP"
  $SCP_CLIENT $VAR_SRC_TAR_FILE_PATH $VAR_VM_IP:$VAR_SRC_TAR_FILE_NAME
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BIN_TAR_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echoInfo "stdout\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stderr\n$VAR_LOG"; fi
  VAR_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stdtst\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  else
    echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
    VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "if [ -r $VAR_BIN_TAR_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi")
    if isTrue "$VAR_RESULT"; then
      echoInfo "get build file from VM $VAR_VM_NAME ip $VAR_VM_IP and put it in $VAR_BIN_TAR_FILE_PATH"
      $SCP_CLIENT $VAR_VM_IP:$VAR_BIN_TAR_FILE_NAME $VAR_BIN_TAR_FILE_PATH
      checkRetValOK
    else
      echoWarning "Build file $VAR_BIN_TAR_FILE_NAME on VM $VAR_VM_NAME ip $VAR_VM_IP not found"
    fi
   fi
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
  #restore project snapshot
  VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoInfo "restore VM $VAR_VM_NAME snapshot $ENV_PROJECT_NAME"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  echoInfo "create the archive file $VAR_SRC_TAR_FILE_PATH with sources"
  packSourceFiles "$PRM_VERSION" "$VAR_SRC_TAR_FILE_PATH"
  checkRetValOK
  #copy git archive on vm
  VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_SRC_TAR_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:$VAR_SRC_TAR_FILE_NAME
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT -P $VAR_VM_PORT $VAR_SCRIPT_FILE_PATH $COMMON_CONST_VAGRANT_IP_ADDRESS:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  checkRetValOK
  #exec trigger script
  echoInfo "start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  VAR_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $CONST_MAKE_OUTPUT $VAR_BIN_TAR_FILE_NAME; \
if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  if isTrue "$COMMON_CONST_SHOW_DEBUG"; then
    VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$VAR_LOG"
    if ! isEmpty "$VAR_LOG"; then echoInfo "stdout\n$VAR_LOG"; fi
  fi
  VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stderr\n$VAR_LOG"; fi
  VAR_LOG=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.tst; fi") || exitChildError "$VAR_LOG"
  if ! isEmpty "$VAR_LOG"; then echoInfo "stdtst\n$VAR_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
  else
    echoInfo "finish execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT"
    VAR_RESULT=$($SSH_CLIENT -p $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS "if [ -r $VAR_BIN_TAR_FILE_NAME ]; then echo $COMMON_CONST_TRUE; fi")
    if isTrue "$VAR_RESULT"; then
      echoInfo "get build file from VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT and put it in $VAR_BIN_TAR_FILE_PATH"
      $SCP_CLIENT -P $VAR_VM_PORT $COMMON_CONST_VAGRANT_IP_ADDRESS:$VAR_BIN_TAR_FILE_NAME $VAR_BIN_TAR_FILE_PATH
      checkRetValOK
    else
      echoWarning "Build file $VAR_BIN_TAR_FILE_NAME on VM $VAR_VM_NAME ip $COMMON_CONST_VAGRANT_IP_ADDRESS port $VAR_VM_PORT not found"
    fi
  fi
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
  echoWarning "TO-DO support Docker containers"
elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
  echoWarning "TO-DO support Kubernetes containers"
fi
#add to distrib repository if required
if isTrue "$PRM_ADD_TO_DISTRIB_REPOSITORY" && isFileExistAndRead "$VAR_BIN_TAR_FILE_PATH"; then
  echoInfo "add build packages to distrib repository"
  addToDistribRepotory "$VAR_BIN_TAR_FILE_PATH" "$VAR_VM_TEMPLATE" "$PRM_SUITE"
  checkRetValOK
fi

doneFinalStage
exitOK
