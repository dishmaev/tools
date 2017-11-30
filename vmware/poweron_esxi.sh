#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Power on esxi hosts pool'

##private vars
PRM_MACS_POOL='' # esxi MACs pool
VAR_MAC='' #MAC

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[MACsPool=$COMMON_CONST_ALL]' "$COMMON_CONST_ALL" \
"Available MAC addresses: $COMMON_CONST_ESXI_MACS_POOL"

###check commands

PRM_MACS_POOL=${1:-$COMMON_CONST_ALL}

if ! isEmpty "$1"; then
  checkCommandExist 'MACsPool' "$PRM_MACS_POOL" "$COMMON_CONST_ESXI_MACS_POOL"
else
  checkCommandExist 'MACsPool' "$PRM_MACS_POOL" ''
fi

###check body dependencies

checkDependencies 'wakeonlan'

###start prompt

startPrompt

###body

if [ "$PRM_MACS_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_MACS_POOL=$COMMON_CONST_ESXI_MACS_POOL
fi

for VAR_MAC in $PRM_MACS_POOL; do
  echoInfo "MAC host $VAR_MAC"
  wakeonlan $VAR_MAC
  checkRetValOK
done

doneFinalStage
exitOK
