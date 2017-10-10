#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Put ssh public access key to remote esxi host'

##private consts


##private vars
PRM_KEYID='' #keyid
PRM_HOST='' #host
TARGET_DIRNAME='' #target directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '[keyID=$COMMON_CONST_SSHKEYID] [host=$COMMON_CONST_HVHOST]' \
      "$COMMON_CONST_SSHKEYID $COMMON_CONST_HVHOST" \
      "Required allowing ssh access on the remote host, details https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866"

###check commands

PRM_KEYID=${1:-$COMMON_CONST_SSHKEYID}
PRM_HOST=${2:-$COMMON_CONST_HVHOST}

###check body dependencies

checkDependencies 'ssh'

###check required files

checkRequiredFiles "$HOME/.ssh/$PRM_KEYID.pub"

###start prompt

startPrompt

###body

TARGET_DIRNAME="/etc/ssh/keys-$COMMON_CONST_USER"

ssh $COMMON_CONST_USER@$PRM_HOST "if [ ! -d $TARGET_DIRNAME ]; then mkdir $TARGET_DIRNAME; fi; cat >> $TARGET_DIRNAME/authorized_keys" < $HOME/.ssh/$PRM_KEYID.pub
if isRetValOK
then
  doneFinalStage
  exitOK
else
  exitError
fi
