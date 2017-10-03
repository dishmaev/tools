#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Set SSH access to remote esxi host with public key authentication'

##private consts


##private vars


###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 0 '<> [keyID=$COMMON_CONST_SSHKEYID] [host=$COMMON_CONST_HVHOST]' "$COMMON_CONST_SSHKEYID $COMMON_CONST_HVHOST" "Required allowing SSH access on the remote host"

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

ssh root@$PRM_HOST "cat >> /etc/ssh/keys-root/authorized_keys" < $HOME/.ssh/$PRM_KEYID.pub

doneStage

exitOK
