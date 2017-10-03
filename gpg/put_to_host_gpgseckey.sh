#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Put gpg secret key to remote host'

##private vars
PRM_HOST='' #host
PRM_KEYID='' #keyid
TMP_FILEPATH='' #temporary file full path
TMP_FILENAME='' #temporary file name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '$COMMON_CONST_USER@<host> [keyID=$COMMON_CONST_GPGKEYID]' \
            "host $COMMON_CONST_GPGKEYID" 'Required gpg secret keyID'

###check commands

PRM_HOST=$1
PRM_KEYID=$2

checkCommandExist 'host' $PRM_HOST

if [ -z "$PRM_KEYID" ]
then
  PRM_KEYID=$COMMON_CONST_GPGKEYID
fi

###check body dependencies

checkDependencies 'mktemp basename gpg scp ssh rm'

#check availability gpg sec key
checkGpgSecKeyExist $PRM_KEYID

###start prompt

startPrompt

###body

TMP_FILEPATH=$(mktemp -u)
TMP_FILENAME=$(basename $TMP_FILEPATH)
gpg -q --export-secret-keys --output $TMP_FILEPATH $PRM_KEYID
scp -q $TMP_FILEPATH $COMMON_CONST_USER@$PRM_HOST:~/$TMP_FILENAME
ssh $COMMON_CONST_USER@$PRM_HOST "gpg --import" $TMP_FILENAME ";rm" $TMP_FILENAME
rm $TMP_FILEPATH

doneStage

exitOK
