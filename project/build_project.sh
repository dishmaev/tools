#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Build of project $ENV_PROJECT_NAME"

##private consts
CONST_SUITES_POOL="$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_TEST_SUITE $COMMON_CONST_RELEASE_SUITE"
CONST_PROJECT_ACTION='build'

##private vars
PRM_VERSION='' #version
PRM_SUITE='' #suite
PRM_VM_ROLE='' #role for create VM
PRM_ADD_TO_DISTRIB_REPOSITORY='' #add package to repository
PRM_DISTRIB_REPO='' #distrib repository
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_SCRIPT_FILE_NAME='' #create script file name
VAR_SCRIPT_FILE_PATH='' #create script file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id
VAR_VM_IP='' #vm ip address
VAR_BUILD_FILE_NAME='' #build file name
VAR_BUILD_FILE_PATH='' #build file path
VAR_TAR_FILE_PATH='' #source archive file path
VAR_CUR_DIR_NAME='' #current directory name
VAR_TMP_DIR_NAME='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 5 '[version=$COMMON_CONST_DEFAULT_VERSION] [suite=$COMMON_CONST_DEVELOP_SUITE] [vmRole=$COMMON_CONST_DEFAULT_VM_ROLE] [addToDistribRepository=$COMMON_CONST_FALSE] [distribRepository=$ENV_DISTRIB_REPO]' \
"$COMMON_CONST_DEFAULT_VERSION $COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE $COMMON_CONST_FALSE $ENV_DISTRIB_REPO" \
"Version '$COMMON_CONST_DEFAULT_VERSION' is 'HEAD' of develop branch. Available suites: $CONST_SUITES_POOL"

###check commands

PRM_VERSION=${1:-$COMMON_CONST_DEFAULT_VERSION}
PRM_SUITE=${2:-$COMMON_CONST_DEVELOP_SUITE}
PRM_VM_ROLE=${3:-$COMMON_CONST_DEFAULT_VM_ROLE}
PRM_ADD_TO_DISTRIB_REPOSITORY=${4:-$COMMON_CONST_FALSE}
PRM_DISTRIB_REPO=${5:-$ENV_DISTRIB_REPO}

checkCommandExist 'version' "$PRM_VERSION" ''
checkCommandExist 'suite' "$PRM_SUITE" "$CONST_SUITES_POOL"
checkCommandExist 'vmRole' "$PRM_VM_ROLE" ''
checkCommandExist 'addToDistribRepotory' "$PRM_ADD_TO_DISTRIB_REPOSITORY" "$COMMON_CONST_BOOL_VALUES"
checkCommandExist 'distribRepository' "$PRM_DISTRIB_REPO" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

checkRequiredFiles "$PRM_BUILD_FILE"

###start prompt

startPrompt

###body

VAR_CONFIG_FILE_NAME=${COMMON_CONST_RUNNER_SUITE}_${PRM_VM_ROLE}
VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}.cfg
if ! isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
  exitError "not found $VAR_CONFIG_FILE_PATH. Exec 'create_vm_project.sh' previously"
fi

VAR_RESULT=$(cat $VAR_CONFIG_FILE_PATH) || exitChildError "$VAR_RESULT"
VAR_VM_TYPE=$(echo $VAR_RESULT | awk -F:: '{print $1}') || exitChildError "$VAR_VM_TYPE"
VAR_VM_TEMPLATE=$(echo $VAR_RESULT | awk -F:: '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
VAR_VM_NAME=$(echo $VAR_RESULT | awk -F:: '{print $3}') || exitChildError "$VAR_VM_NAME"

VAR_SCRIPT_FILE_NAME=${VAR_VM_TEMPLATE}_${PRM_VM_ROLE}_${CONST_PROJECT_ACTION}
VAR_SCRIPT_FILE_PATH=$ENV_PROJECT_TRIGGER_PATH/${VAR_SCRIPT_FILE_NAME}.sh

checkRequiredFiles "$VAR_SCRIPT_FILE_PATH"

#add package file name extention
VAR_BUILD_FILE_NAME=$(echo $ENV_PROJECT_NAME | tr '[A-Z]' '[a-z]')
VAR_TAR_FILE_PATH=$ENV_DOWNLOAD_PATH/${VAR_BUILD_FILE_NAME}.tar.gz
if [ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_PHOTONMINI_VM_TEMPLATE" ] || \
[ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXMINI_VM_TEMPLATE" ] || \
[ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ] || \
[ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_ORACLELINUXBOX_VM_TEMPLATE" ]; then
  VAR_BUILD_FILE_NAME=${VAR_BUILD_FILE_NAME}.rpm
elif [ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_DEBIANMINI_VM_TEMPLATE" ] || \
[ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_DEBIANOSB_VM_TEMPLATE" ]; then
  VAR_BUILD_FILE_NAME=${VAR_BUILD_FILE_NAME}.deb
elif [ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISMINI_VM_TEMPLATE" ] || \
[ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_ORACLESOLARISBOX_VM_TEMPLATE" ]; then
  echo "Oracle Solaris package extention"
elif [ "$VAR_VM_TEMPLATE" = "$COMMON_CONST_FREEBSD_VM_TEMPLATE" ]; then
  echo "FreeBSD package extention"
fi
VAR_BUILD_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_BUILD_FILE_NAME

if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
  VAR_HOST=$(echo $VAR_RESULT | awk -F:: '{print $4}') || exitChildError "$VAR_HOST"
  checkSSHKeyExistEsxi "$VAR_HOST"
  #get vm id
  VAR_VM_ID=$(getVMIDByVMName "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_VM_ID"
  if isEmpty "$VAR_VM_ID"; then
    exitError "VM $VAR_VM_NAME not found on $VAR_HOST host"
  fi
  #restore project snapshot
  echo "Restore VM $VAR_VM_NAME snapshot: $ENV_PROJECT_NAME"
  VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_vm_snapshot.sh -y $VAR_VM_NAME $ENV_PROJECT_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  #power on
  VAR_RESULT=$(powerOnVM "$VAR_VM_ID" "$VAR_HOST") || exitChildError "$VAR_RESULT"
  echoResult "$VAR_RESULT"
  VAR_VM_IP=$(getIpAddressByVMName "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_VM_IP"
  #make temporary directory
  VAR_TMP_DIR_NAME=$(mktemp -d) || exitChildError "$VAR_TMP_DIR_NAME"
  if [ "$PRM_VERSION" = "$COMMON_CONST_DEFAULT_VERSION"]; then
    git clone -b develop $ENV_PROJECT_REPO $VAR_TMP_DIR_NAME
  else
    git clone -b $PRM_VERSION $ENV_PROJECT_REPO $VAR_TMP_DIR_NAME
  fi
  if ! isRetValOK; then rm -fR $VAR_TMP_DIR_NAME; exitError; fi
  VAR_CUR_DIR_NAME=$PWD
  cd $VAR_TMP_DIR_NAME
  if ! isRetValOK; then rm -fR $VAR_TMP_DIR_NAME; exitError; fi
  #make archive
  git archive --format=tar.gz -o $VAR_TAR_FILE_PATH HEAD
  if ! isRetValOK; then cd $VAR_CUR_DIR_NAME; rm -fR $VAR_TMP_DIR_NAME; exitError; fi
  #remote temporary directory
  cd $VAR_CUR_DIR_NAME
  if ! isRetValOK; then exitError; fi
  rm -fR $VAR_TMP_DIR_NAME
  if ! isRetValOK; then exitError; fi
  #copy git archive on vm
  $SCP_CLIENT $VAR_TAR_FILE_PATH $VAR_VM_IP:
  #copy create script on vm
  VAR_REMOTE_SCRIPT_FILE_NAME=${ENV_PROJECT_NAME}_$VAR_SCRIPT_FILE_NAME
  $SCP_CLIENT $VAR_SCRIPT_FILE_PATH $VAR_VM_IP:${VAR_REMOTE_SCRIPT_FILE_NAME}.sh
  if ! isRetValOK; then exitError; fi
  #exec trigger script
  echo "Start ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh executing on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  VAR_RESULT=$($SSH_CLIENT $VAR_VM_IP "chmod u+x ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh;./${VAR_REMOTE_SCRIPT_FILE_NAME}.sh $VAR_REMOTE_SCRIPT_FILE_NAME $PRM_SUITE $PRM_VERSION $VAR_BUILD_FILE_NAME; \
if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.ok; else echo $COMMON_CONST_FALSE; fi") || exitChildError "$VAR_RESULT"
  RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.log ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.log; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$RET_LOG"; then echo "Stdout:\n$RET_LOG"; fi
  RET_LOG=$($SSH_CLIENT $VAR_VM_IP "if [ -f ${VAR_REMOTE_SCRIPT_FILE_NAME}.err ]; then cat ${VAR_REMOTE_SCRIPT_FILE_NAME}.err; fi") || exitChildError "$RET_LOG"
  if ! isEmpty "$RET_LOG"; then echo "Stderr:\n$RET_LOG"; fi
  if ! isTrue "$VAR_RESULT"; then
    exitError "failed execute ${VAR_REMOTE_SCRIPT_FILE_NAME}.sh on VM $VAR_VM_NAME ip $VAR_VM_IP on $VAR_HOST host"
  else
    echo "Get necessary file from VM"
    $SCP_CLIENT $VAR_VM_IP:$VAR_BUILD_FILE_NAME $VAR_BUILD_FILE_PATH
    if ! isRetValOK; then exitError; fi
   fi
fi

doneFinalStage
exitOK
