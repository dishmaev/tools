
#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Power off esxi hosts pool'

##private vars
PRM_ESXI_HOSTS_POOL='' # esxi hosts pool
VAR_HOST='' #current esxi host
VAR_RESULT='' #child return value

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[esxiHostsPool=$COMMON_CONST_ALL]' "$COMMON_CONST_ALL" \
"Available esxi hosts: $COMMON_CONST_ESXI_HOSTS_POOL"

###check commands

PRM_ESXI_HOSTS_POOL=${1:-$COMMON_CONST_ALL}

if ! isEmpty "$1"; then
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" "$COMMON_CONST_ESXI_HOSTS_POOL"
else
  checkCommandExist 'esxiHostsPool' "$PRM_ESXI_HOSTS_POOL" ''
fi

###check body dependencies

#checkDependencies 'ssh'

###start prompt

startPrompt

###body

if [ "$PRM_ESXI_HOSTS_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_ESXI_HOSTS_POOL=$COMMON_CONST_ESXI_HOSTS_POOL
fi

for VAR_HOST in $PRM_ESXI_HOSTS_POOL; do
  echo "Esxi host:" $VAR_HOST
  checkSSHKeyExistEsxi "$VAR_HOST"
  VAR_RESULT=$($SSH_CLIENT $VAR_HOST "echo $COMMON_CONST_TRUE; poweroff") || exitChildError "$VAR_RESULT"
#  VAR_RESULT=$($SSH_CLIENT $VAR_HOST "esxcli system maintenanceMode set --enable true; echo $COMMON_CONST_TRUE; esxcli system shutdown poweroff --reason='by $ENV_SSH_USER_NAME'") || exitChildError "$VAR_RESULT"

  #esxcli system shutdown poweroff. You must specify the --reason
  if ! isTrue "$VAR_RESULT"; then exitError; fi
done

doneFinalStage
exitOK
