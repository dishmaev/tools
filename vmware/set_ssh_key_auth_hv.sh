#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Set SSH access to remote esxi host with public key authentication'

##private consts


##private vars
TARGET_DIRNAME='' #target directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '<> [keyID=$COMMON_CONST_SSHKEYID] [host=$COMMON_CONST_HVHOST]' \
      "$COMMON_CONST_SSHKEYID $COMMON_CONST_HVHOST" \
      "Required allowing SSH access on the remote host, details https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1002866" \

###check parms

PRM_KEYID='' #keyid
PRM_HOST='' #host

if [ -z "$PRM_KEYID" ]
then
  PRM_KEYID=$COMMON_CONST_SSHKEYID
fi

if [ -z "$PRM_HOST" ]
then
  PRM_HOST=$COMMON_CONST_HVHOST
fi

###check body dependencies

checkDependencies 'ssh'

###check required files

checkRequiredFiles "$HOME/.ssh/$PRM_KEYID.pub"

###start prompt

startPrompt

###body

TARGET_DIRNAME="/etc/ssh/keys-$COMMON_CONST_USER"

ssh $COMMON_CONST_USER@$PRM_HOST "if [ ! -d $TARGET_DIRNAME ]; then mkdir $TARGET_DIRNAME; fi; cat >> $TARGET_DIRNAME/authorized_keys" < $HOME/.ssh/$PRM_KEYID.pub

doneStage

exitOK
