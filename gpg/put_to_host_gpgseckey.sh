#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Put gpg secret key to remote host'

##private vars
PRM_HOST='' #host
PRM_KEYID='' #keyid
VAR_TMP_FILE_NAME='' #temporary file name
VAR_TMP_FILE_PATH='' #temporary file full path
VAR_RESULT='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<host> [keyID=$COMMON_CONST_GPG_KEYID]' \
            "host $COMMON_CONST_GPG_KEYID" 'Required gpg secret keyID'

###check commands

PRM_HOST=$1
PRM_KEYID=${2:-$COMMON_CONST_GPG_KEYID}

checkCommandExist 'host' "$PRM_HOST" ''

###check body dependencies

checkDependencies 'mktemp basename gpg ssh rm'

#check availability gpg sec key
checkGpgSecKeyExist $PRM_KEYID

###start prompt

startPrompt

###body

#check gpg exist on remote host
VAR_RESULT=$($SSH_CLIENT $PRM_HOST "if [ -x $(command -v gpg) ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$VAR_RESULT"
if ! isTrue "$VAR_RESULT"; then
  exitError "not found gpg on $PRM_HOST host"
fi

VAR_TMP_FILE_PATH=$(mktemp -u) || exitChildError "$VAR_TMP_FILE_PATH"
VAR_TMP_FILE_NAME=$(basename $VAR_TMP_FILE_PATH) || exitChildError "$VAR_TMP_FILE_NAME"
gpg -q --export-secret-keys --output $VAR_TMP_FILE_PATH $PRM_KEYID
$SCP_CLIENT $VAR_TMP_FILE_PATH $PRM_HOST:
$SSH_CLIENT $PRM_HOST "gpg --import" $VAR_TMP_FILE_NAME ";rm" $VAR_TMP_FILE_NAME
rm $VAR_TMP_FILE_PATH

doneFinalStage
exitOK
