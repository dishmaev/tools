#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Put gpg secret key to remote host'

##private vars
PRM_HOST='' #host
PRM_KEYID='' #keyid
TMP_FILEPATH='' #temporary file full path
TMP_FILENAME='' #temporary file name
RET_VAL='' #child return value

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
RET_VAL=$($SSH_CLIENT $PRM_HOST "if [ -x $(command -v gpg) ]; then echo $COMMON_CONST_TRUE; fi;") || exitChildError "$RET_VAL"
if ! isTrue "$RET_VAL"; then
  exitError "not found gpg on $PRM_HOST host"
fi

TMP_FILEPATH=$(mktemp -u) || exitChildError "$TMP_FILEPATH"
TMP_FILENAME=$(basename $TMP_FILEPATH) || exitChildError "$TMP_FILENAME"
gpg -q --export-secret-keys --output $TMP_FILEPATH $PRM_KEYID
$SCP_CLIENT $TMP_FILEPATH $PRM_HOST:
$SSH_CLIENT $PRM_HOST "gpg --import" $TMP_FILENAME ";rm" $TMP_FILENAME
rm $TMP_FILEPATH

doneFinalStage
exitOK
