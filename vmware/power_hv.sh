#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Power on/off esxi host'

##using files: none
##dependencies: wakeonlan

##private vars
PRM_COMMAND='on' #power operation enum {on,off}
PRM_HV='' #mac or host name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<on | off> [mac=$COMMON_CONST_HVMAC | host=$COMMON_CONST_HVHOST]' "on $COMMON_CONST_HVHOST $COMMON_CONST_HVMAC" 'On need mac, off need host'

###check parms

PRM_COMMAND=$1
PRM_HV=$2

if [ -z "$PRM_COMMAND" ] || [ "$PRM_COMMAND" != "on" ] && [ "$PRM_COMMAND" != "off" ]
then
  exitError 'Operation missing or invalid!'
fi

if [ -z "$PRM_HV" ]
then
  if [ "$PRM_COMMAND" = "on" ]
  then
    PRM_HV=$COMMON_CONST_HVMAC
    #check availability wakeonlan
    checkDependencies 'wakeonlan'
#    if ! isCommandExist 'wakeonlan'
#    then
#      exitError 'Wakeonlan not found!'
#    fi
  else
    PRM_HV=$COMMON_CONST_HVHOST
  fi
fi

###start prompt

startPrompt

###body

if [ "$PRM_COMMAND" = "off" ]
then
#  ssh root@$PRM_HV "poweroff"
  echo 'off operation'
else
#  wakeonlan $PRM_HV
  echo 'on operation'
fi

doneStage

exitOK
