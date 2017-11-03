
#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Power off esxi hosts pool'

##private vars
PRM_HOSTS_POOL='' # esxi hosts pool
CUR_HOST='' #current esxi host
RET_VAL='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[hostsPool=$COMMON_CONST_ESXI_HOSTS_POOL]' "'$COMMON_CONST_ESXI_HOSTS_POOL'" ''

###check commands

PRM_HOSTS_POOL=${1:-$COMMON_CONST_ESXI_HOSTS_POOL}

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

for CUR_HOST in $PRM_HOSTS_POOL; do
  echo "Esxi host:" $CUR_HOST
  RET_VAL=$($SSH_CLIENT $CUR_HOST "echo $COMMON_CONST_TRUE;poweroff") || exitChildError "$RET_VAL"
  if ! isTrue "$RET_VAL"; then exitError; fi
done

doneFinalStage
exitOK
