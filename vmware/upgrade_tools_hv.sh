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

echoHelp $# 1 '[host=$COMMON_CONST_HVHOST]' \
      "$COMMON_CONST_HVHOST" \
      "Required allowing ssh access on the remote esxi host, details https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866. Required OVF Tool https://www.vmware.com/support/developer/ovf/. Required vSphere CLI https://code.vmware.com/tool/vsphere-cli/"

###check commands

PRM_HOST=${1:-$COMMON_CONST_HVHOST}

###check body dependencies

checkDependencies 'ovftool vmkfstools ssh scp'
checkDirectoryForExist "$COMMON_CONST_LOCAL_OVFTOOL_PATH" 'ovftool source '

###check required files

checkRequiredFiles "$HOME/.ssh/$COMMON_CONST_SSHKEYID.pub"
checkRequiredFiles "$COMMON_CONST_SCRIPT_DIRNAME/data/version"

###start prompt

startPrompt

###body

#check default user ssh key exist
ssh $COMMON_CONST_USER@$PRM_HOST "if [ ! -d $CONST_HV_SSHKEYS_DIRNAME ]; then mkdir $CONST_HV_SSHKEYS_DIRNAME; cat > $CONST_HV_SSHKEYS_DIRNAME/authorized_keys; else cat > /dev/null;fi" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
#get local tools version
LOCAL_TOOLS_VER=$(cat $COMMON_CONST_SCRIPT_DIRNAME/data/version)
#get local ovftools version
LOCAL_OVFTOOLS_VER=$(ovftool --version | awk '{print $3}')
#check tools exist
RET_VAL=$(ssh $COMMON_CONST_USER@$PRM_HOST "if [ -d $COMMON_CONST_HV_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"
then #first install
  ssh $COMMON_CONST_USER@$PRM_HOST "mkdir $COMMON_CONST_HV_TOOLS_PATH; mkdir $COMMON_CONST_HV_PATCHES_PATH; mkdir $COMMON_CONST_HV_IMAGES_PATH"
  if ! isRetValOK; then exitError; fi
  #copy tools
  scp -r $COMMON_CONST_SCRIPT_DIRNAME/data $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_HV_TOOLS_PATH
  if ! isRetValOK; then exitError; fi
  #put scripts
  put_script_tools_to_hv "$PRM_HOST"
  #put ofvtool
  put_ovftool_to_hv "$PRM_HOST"
else
  #get remote tools version
  REMOTE_TOOLS_VER=$(ssh $COMMON_CONST_USER@$PRM_HOST "cat $COMMON_CONST_HV_DATA_PATH/version") || exitChildError "$REMOTE_TOOLS_VER"
  #get remote ovftools version
  REMOTE_OVFTOOLS_VER=$(ssh $COMMON_CONST_USER@$PRM_HOST "$COMMON_CONST_HV_OVFTOOL_PATH/ovftool --version | awk '{print \$3}'") || exitChildError "$REMOTE_TOOLS_VER"
  if isNewLocalVersion "$LOCAL_TOOLS_VER" "$REMOTE_TOOLS_VER"
  then
    #remove old version scripts
    ssh $COMMON_CONST_USER@$PRM_HOST "rm -fR $COMMON_CONST_HV_SCRIPTS_PATH"
    if ! isRetValOK; then exitError; fi
    #put new version scripts
    put_script_tools_to_hv "$PRM_HOST"
    #put new version tag
    scp -r $COMMON_CONST_SCRIPT_DIRNAME/data/version $COMMON_CONST_USER@$PRM_HOST:$COMMON_CONST_HV_TOOLS_PATH/data/
    if ! isRetValOK; then exitError; fi
  fi
  if isNewLocalVersion "$LOCAL_OVFTOOLS_VER" "$REMOTE_OVFTOOLS_VER"
  then
    #remove old version ofvtool
    ssh $COMMON_CONST_USER@$PRM_HOST "rm -fR $COMMON_CONST_HV_TOOLS_PATH"
    if ! isRetValOK; then exitError; fi
    #put new version ofvtool
    put_ovftool_to_hv "$PRM_HOST"
  fi
fi

doneFinalStage
exitOK
