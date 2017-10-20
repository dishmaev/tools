#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Upgrade tools on remote esxi host'

##private consts
CONST_HV_SSHKEYS_DIRNAME="/etc/ssh/keys-$COMMON_CONST_USER"

##private vars
PRM_HOST='' #host
RET_VAL='' #child return value
LOCAL_TOOLS_VER='' #local tools version
REMOTE_TOOLS_VER='' #remote tools version
LOCAL_OVFTOOLS_VER='' #local ovftools version
REMOTE_OVFTOOLS_VER='' #remote ovftools version

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[host=$COMMON_CONST_ESXI_HOST]' \
      "$COMMON_CONST_ESXI_HOST" \
      "Required allowing ssh access on the remote esxi host, \
details https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866. \
Required OVF Tool https://www.vmware.com/support/developer/ovf/"

###check commands

PRM_HOST=${1:-$COMMON_CONST_ESXI_HOST}

###check body dependencies

checkDependencies 'ovftool ssh scp'
checkDirectoryForExist "$COMMON_CONST_LOCAL_OVFTOOL_PATH" 'ovftool source '

###check required files

checkRequiredFiles "$HOME/.ssh/$COMMON_CONST_SSHKEYID"
checkRequiredFiles "$HOME/.ssh/$COMMON_CONST_SSHKEYID.pub"

###start prompt

startPrompt

###body

#create version file if not exist
if ! isFileExistAndRead "$COMMON_CONST_SCRIPT_DIRNAME/data/version";then
  echo 1 > "$COMMON_CONST_SCRIPT_DIRNAME/data/version"
fi
#remove known_hosts file to prevent future script errors
rm ~/.ssh/known_hosts

#check default user ssh key exist
$SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ ! -d $CONST_HV_SSHKEYS_DIRNAME ]; then mkdir $CONST_HV_SSHKEYS_DIRNAME; cat > $CONST_HV_SSHKEYS_DIRNAME/authorized_keys; else cat > /dev/null;fi" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
#get local tools version
LOCAL_TOOLS_VER=$(cat $COMMON_CONST_SCRIPT_DIRNAME/data/version)
#get local ovftools version
LOCAL_OVFTOOLS_VER=$(ovftool --version | awk '{print $3}')
#check tools exist
RET_VAL=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "if [ -d $COMMON_CONST_ESXI_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"
then #first install
  $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "mkdir $COMMON_CONST_ESXI_TOOLS_PATH; mkdir $COMMON_CONST_ESXI_PATCHES_PATH; mkdir $COMMON_CONST_ESXI_IMAGES_PATH"
  if ! isRetValOK; then exitError; fi
  #copy tools
  scp -r $COMMON_CONST_SCRIPT_DIRNAME/data $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_TOOLS_PATH
  if ! isRetValOK; then exitError; fi
  #put scripts
  put_script_tools_to_esxi "$PRM_HOST"
  #put ofvtool
  put_ovftool_to_esxi "$PRM_HOST"
else
  #get remote tools version
  REMOTE_TOOLS_VER=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "cat $COMMON_CONST_ESXI_DATA_PATH/version") || exitChildError "$REMOTE_TOOLS_VER"
  #get remote ovftools version
  REMOTE_OVFTOOLS_VER=$($SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool --version | awk '{print \$3}'") || exitChildError "$REMOTE_TOOLS_VER"
  if isNewLocalVersion "$LOCAL_TOOLS_VER" "$REMOTE_TOOLS_VER"
  then
    #remove old version scripts
    $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "rm -fR $COMMON_CONST_ESXI_SCRIPTS_PATH"
    if ! isRetValOK; then exitError; fi
    #put new version scripts
    put_script_tools_to_esxi "$PRM_HOST"
    #put new version tag
    scp -r $COMMON_CONST_SCRIPT_DIRNAME/data/version $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_ESXI_TOOLS_PATH/data/
    if ! isRetValOK; then exitError; fi
  fi
  if isNewLocalVersion "$LOCAL_OVFTOOLS_VER" "$REMOTE_OVFTOOLS_VER"
  then
    #remove old version ofvtool
    $SSH_CLIENT $COMMON_CONST_USER@$PRM_HOST "rm -fR $COMMON_CONST_ESXI_TOOLS_PATH"
    if ! isRetValOK; then exitError; fi
    #put new version ofvtool
    put_ovftool_to_esxi "$PRM_HOST"
  fi
fi

doneFinalStage
exitOK
