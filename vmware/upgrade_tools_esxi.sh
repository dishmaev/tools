#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Upgrade tools on esxi hosts pool'

##private consts
CONST_HV_SSHKEYS_DIRNAME="/etc/ssh/keys-$COMMON_CONST_SCRIPT_USER"
CONST_TOOLSVER_FILENAME='toolsversion.txt'

##private vars
PRM_HOSTS_POOL='' # esxi hosts pool
CUR_HOST='' #current esxi host
RET_VAL='' #child return value
LOCAL_TOOLS_VER='' #local tools version
REMOTE_TOOLS_VER='' #remote tools version
LOCAL_OVFTOOLS_VER='' #local ovftools version
REMOTE_OVFTOOLS_VER='' #remote ovftools version

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 "[hostsPool=\$COMMON_CONST_ESXI_HOSTS_POOL]" \
      "'$COMMON_CONST_ESXI_HOSTS_POOL'" \
      "Required allowing ssh access on the remote esxi host, \
details https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866. \
Required OVF Tool https://www.vmware.com/support/developer/ovf/. Required $COMMON_CONST_VMTOOLS_FILE https://my.vmware.com/web/vmware/details?productId=614&downloadGroup=VMTOOLS10110"

###check commands

PRM_HOSTS_POOL=${1:-$COMMON_CONST_ESXI_HOSTS_POOL}

###check body dependencies

checkDependencies 'ovftool ssh'
checkDirectoryForExist "$COMMON_CONST_LOCAL_OVFTOOL_PATH" 'ovftool source '

###check required files

checkRequiredFiles "$HOME/.ssh/$COMMON_CONST_SSH_KEYID"
checkRequiredFiles "$HOME/.ssh/$COMMON_CONST_SSH_KEYID.pub"
checkRequiredFiles "$COMMON_CONST_LOCAL_VMTOOLS_PATH"

###start prompt

startPrompt

###body

#create version file if not exist
if ! isFileExistAndRead "$COMMON_CONST_SCRIPT_DIRNAME/data/$CONST_TOOLSVER_FILENAME"; then
  echo 1 > "$COMMON_CONST_SCRIPT_DIRNAME/data/$CONST_TOOLSVER_FILENAME"
fi
#remove known_hosts file to prevent future script errors
if isFileExistAndRead "$HOME/.ssh/known_hosts"; then
  rm $HOME/.ssh/known_hosts
fi

for CUR_HOST in $PRM_HOSTS_POOL; do
  echo "esxi host:" $CUR_HOST
  #check default user ssh key exist
  RET_VAL=$($SSH_CLIENT $CUR_HOST "if [ ! -d $CONST_HV_SSHKEYS_DIRNAME ]; then mkdir $CONST_HV_SSHKEYS_DIRNAME; cat > $CONST_HV_SSHKEYS_DIRNAME/authorized_keys; else cat > /dev/null; fi; echo $COMMON_CONST_TRUE" < $HOME/.ssh/$COMMON_CONST_SSH_KEYID.pub) || exitChildError "$RET_VAL"
  if ! isTrue "$RET_VAL"; then exitError; fi
  #get local tools version
  LOCAL_TOOLS_VER=$(cat $COMMON_CONST_SCRIPT_DIRNAME/data/$CONST_TOOLSVER_FILENAME)
  #get local ovftools version
  LOCAL_OVFTOOLS_VER=$(ovftool --version | awk '{print $3}')
  #check tools exist
  RET_VAL=$($SSH_CLIENT $CUR_HOST "if [ -d $COMMON_CONST_ESXI_TOOLS_PATH ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
  if ! isTrue "$RET_VAL"
  then #first install
    echo "New tools install on $CUR_HOST host"
    $SSH_CLIENT $CUR_HOST "mkdir $COMMON_CONST_ESXI_TOOLS_PATH; \
mkdir $COMMON_CONST_ESXI_PATCHES_PATH; \
mkdir $COMMON_CONST_ESXI_IMAGES_PATH;
mkdir $COMMON_CONST_ESXI_VMTOOLS_PATH;
mkdir $COMMON_CONST_ESXI_DATA_PATH"
    if ! isRetValOK; then exitError; fi
    #copy version tag
    $SCP_CLIENT $COMMON_CONST_SCRIPT_DIRNAME/data/$CONST_TOOLSVER_FILENAME $CUR_HOST:$COMMON_CONST_ESXI_DATA_PATH/
    if ! isRetValOK; then exitError; fi
    #put templates
    put_template_tools_to_esxi "$CUR_HOST"
    #put vmtools
    put_vmtools_to_esxi "$CUR_HOST"
    #put ofvtool
    put_ovftool_to_esxi "$CUR_HOST"
  else
    #get remote template tools version
    REMOTE_TOOLS_VER=$($SSH_CLIENT $CUR_HOST "cat $COMMON_CONST_ESXI_DATA_PATH/$CONST_TOOLSVER_FILENAME") || exitChildError "$REMOTE_TOOLS_VER"
    #get remote ovftools version
    REMOTE_OVFTOOLS_VER=$($SSH_CLIENT $CUR_HOST "$COMMON_CONST_ESXI_OVFTOOL_PATH/ovftool --version | awk '{print \$3}'") || exitChildError "$REMOTE_TOOLS_VER"
    if isNewLocalVersion "$LOCAL_TOOLS_VER" "$REMOTE_TOOLS_VER"
    then
      echo "Upgrade template tools on $CUR_HOST host"
      #remove old version templates
      $SSH_CLIENT $CUR_HOST "rm -fR $COMMON_CONST_ESXI_TEMPLATES_PATH"
      if ! isRetValOK; then exitError; fi
      #put new version templates
      put_template_tools_to_esxi "$CUR_HOST"
      #put new version tag
      $SCP_CLIENT $COMMON_CONST_SCRIPT_DIRNAME/data/$CONST_TOOLSVER_FILENAME $CUR_HOST:$COMMON_CONST_ESXI_DATA_PATH/
      if ! isRetValOK; then exitError; fi
    else
      echo "Newest template tools version on $CUR_HOST host, skip upgrade"
    fi
    if isNewLocalVersion "$LOCAL_OVFTOOLS_VER" "$REMOTE_OVFTOOLS_VER"
    then
      echo "Upgrade OVF Tool on $CUR_HOST host"
      #remove old version ofvtool
      $SSH_CLIENT $CUR_HOST "rm -fR $COMMON_CONST_ESXI_TOOLS_PATH"
      if ! isRetValOK; then exitError; fi
      #put new version ofvtool
      put_ovftool_to_esxi "$CUR_HOST"
    else
      echo "Newest OVF Tool version on $CUR_HOST host, skip upgrade"
    fi
  fi
done

doneFinalStage
exitOK
