#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Power on/off esxi host'

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
  exitError 'operation missing or invalid!'
fi

if [ -z "$PRM_HV" ]
then
  if [ "$PRM_COMMAND" = "on" ]
  then
    PRM_HV=$COMMON_CONST_HVMAC
    checkDependencies 'wakeonlan'
  else
    PRM_HV=$COMMON_CONST_HVHOST
  fi
fi

###check dependencies

checkDependencies 'ssh'

###start prompt

startPrompt

###body

if [ "$PRM_COMMAND" = "off" ]
then
  ssh root@$PRM_HV "poweroff"
else
  wakeonlan $PRM_HV
fi

doneStage

exitOK
