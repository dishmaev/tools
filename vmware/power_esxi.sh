#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Power on/off remote esxi host'

##private vars
PRM_ACTION='' #power command enum {on,off}
PRM_HV='' #mac or host name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<action=on | off> [MAC=$COMMON_CONST_ESXI_MAC | host=$COMMON_CONST_ESXI_HOST]' \
      "on $COMMON_CONST_ESXI_MAC" 'On action need MAC, off action need host'

###check commands

PRM_ACTION=$1
PRM_HV=$2

checkCommandExist 'action' "$PRM_ACTION" 'on off'

if [ -z "$PRM_HV" ]
then
  if [ "$PRM_ACTION" = "on" ]
  then
    PRM_HV=$COMMON_CONST_ESXI_MAC
  else
    PRM_HV=$COMMON_CONST_ESXI_HOST
  fi
fi

###check body dependencies

checkDependencies 'ssh wakeonlan'

###start prompt

startPrompt

###body

if [ "$PRM_ACTION" = "off" ]
then
  ssh $COMMON_CONST_USER@$PRM_HV "poweroff"
else
  wakeonlan $PRM_HV
fi

doneFinalStage
exitOK
