#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
showDescription 'Power on esxi hosts pool'

##private vars
PRM_MACS_POOL='' # esxi MACs pool
CUR_MAC='' #MAC

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[MACsPool=$COMMON_CONST_ESXI_MACS_POOL]' "'$COMMON_CONST_ESXI_MACS_POOL'" ''

###check commands

PRM_MACS_POOL=${1:-$COMMON_CONST_ESXI_MACS_POOL}

###check body dependencies

checkDependencies 'ssh wakeonlan'

###start prompt

startPrompt

###body

for CUR_MAC in $PRM_MACS_POOL; do
  echo "Target MAC host:" $CUR_MAC
  wakeonlan $CUR_MAC
  if ! isRetValOK; then exitError; fi
done

doneFinalStage
exitOK
