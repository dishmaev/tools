#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "Delete VM of project $ENV_PROJECT_NAME"

##private consts


##private vars
PRM_SUITES_POOL='' #suite pool
PRM_VM_ROLES_POOL='' #roles for create VM pool
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #vm id
VAR_CUR_SUITE='' #current suite
VAR_CUR_VM_ROLE='' #current role for create VM
VAR_CUR_SUITE='' #current suite
VAR_CUR_VM='' #vm exp

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<suitesPool> [vmRolesPool=$COMMON_CONST_DEFAULT_VM_ROLE]' \
"$COMMON_CONST_DEVELOP_SUITE $COMMON_CONST_DEFAULT_VM_ROLE" \
"Available suites: $COMMON_CONST_SUITES_POOL. Suites and roles must be selected without '*'"

###check commands

PRM_SUITES_POOL=$1
PRM_VM_ROLES_POOL=${2:-$COMMON_CONST_DEFAULT_VM_ROLE}

checkCommandExist 'suitesPool' "$PRM_SUITES_POOL" "$COMMON_CONST_SUITES_POOL"
checkCommandExist 'vmRolesPool' "$PRM_VM_ROLES_POOL" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

###start prompt

startPrompt

###body

if [ "$PRM_SUITES_POOL" = "$COMMON_CONST_ALL" ]; then
  PRM_SUITES_POOL=$COMMON_CONST_SUITES_POOL
fi

for VAR_CUR_SUITE in $PRM_SUITES_POOL; do
  for VAR_CUR_VM_ROLE in $PRM_VM_ROLES_POOL; do
    VAR_CONFIG_FILE_NAME=${VAR_CUR_SUITE}_${VAR_CUR_VM_ROLE}.cfg
    VAR_CONFIG_FILE_PATH=$ENV_PROJECT_DATA_PATH/${VAR_CONFIG_FILE_NAME}
    if ! isFileExistAndRead "$VAR_CONFIG_FILE_PATH"; then
      echoWarning "project VM suite $VAR_CUR_SUITE role $VAR_CUR_VM_ROLE not exist, skip delete"
      continue
    fi
    while read VAR_CUR_VM; do
      VAR_VM_TYPE=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_VM_TYPE"
      VAR_VM_TEMPLATE=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
      VAR_VM_NAME=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"
      #delete project vm
      if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
        VAR_HOST=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
        if isExHostAvailable "$VAR_HOST"; then
          checkSSHKeyExistEsxi "$VAR_HOST"
          if isVMExistEx "$VAR_VM_NAME" "$VAR_HOST"; then
            echoInfo "restore VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME on $VAR_HOST host"
            VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vmware/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME $VAR_HOST) || exitChildError "$VAR_RESULT"
            echoResult "$VAR_RESULT"
          else
            echoWarning "VM $VAR_VM_NAME not found on $VAR_HOST host, skip snapshot restore"
        else
          echoWarning "host $VAR_HOST unavailable, skip snapshot restore"
        fi
      elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
        if isVMExistVb "$VAR_VM_NAME"; then
          VAR_RESULT=$(powerOffVMVb "$VAR_VM_NAME") || exitChildError "$VAR_RESULT"
          echoInfo "restore VM $VAR_VM_NAME snapshot $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME"
          VAR_RESULT=$($ENV_SCRIPT_DIR_NAME/../vbox/restore_${VAR_VM_TYPE}_vm_snapshot.sh -y $VAR_VM_NAME $COMMON_CONST_SNAPSHOT_TEMPLATE_NAME) || exitChildError "$VAR_RESULT"
          echoResult "$VAR_RESULT"
        else
          echoWarning "VM $VAR_VM_NAME not found, skip snapshot restore"
        fi
      elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_DOCKER_VM_TYPE" ]; then
        echoWarning "TO-DO support Docker containers"
      elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_KUBERNETES_VM_TYPE" ]; then
        echoWarning "TO-DO support Kubernetes containers"
      fi
    done < "$VAR_CONFIG_FILE_PATH"
    echoInfo "remove config file $VAR_CONFIG_FILE_PATH"
    rm $VAR_CONFIG_FILE_PATH
    checkRetValOK
  done
done

doneFinalStage
exitOK
