#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription "List of VMs project $ENV_PROJECT_NAME"


##private consts


##private vars
PRM_FILTER_REGEX='' #build file name
VAR_RESULT='' #child return value
VAR_CONFIG_FILE_NAME='' #vm config file name
VAR_CONFIG_FILE_PATH='' #vm config file path
VAR_CUR_VM='' #vm exp
VAR_SUITE='' #suite
VAR_VM_ROLE='' #role for create VM
VAR_VM_TYPE='' #vm type
VAR_VM_TEMPLATE='' #vm template
VAR_VM_NAME='' #vm name
VAR_HOST='' #esxi host
VAR_VM_ID='' #VMID target virtual machine
VAR_VM_IP='' #vm ip address, <unset> if off line
VAR_VM_PORT='' #$COMMON_CONST_VAGRANT_IP_ADDRESS port address for access to vm by ssh

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[filterRegex=$COMMON_CONST_ALL]' "'$COMMON_CONST_ALL'" ''

###check commands

PRM_FILTER_REGEX=${1:-$COMMON_CONST_ALL}

checkCommandExist 'filterRegex' "$PRM_FILTER_REGEX" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#comments

for VAR_CONFIG_FILE_PATH in $ENV_PROJECT_DATA_PATH/*.cfg; do
  if [ ! -r "$VAR_CONFIG_FILE_PATH" ]; then continue; fi
  VAR_CONFIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_CONFIG_FILE_PATH") || exitChildError "$VAR_CONFIG_FILE_NAME"
  VAR_SUITE=$(echo $VAR_CONFIG_FILE_NAME | awk -F_ '{print $1}')
  VAR_VM_ROLE=$(echo $VAR_CONFIG_FILE_NAME | awk -F_ '{print $2}' | awk -F. '{print $1}')
  while read VAR_CUR_VM; do
    VAR_VM_TYPE=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $1}') || exitChildError "$VAR_VM_TYPE"
    VAR_VM_TEMPLATE=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $2}') || exitChildError "$VAR_VM_TEMPLATE"
    VAR_VM_NAME=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $3}') || exitChildError "$VAR_VM_NAME"
    if [ "$VAR_VM_TYPE" = "$COMMON_CONST_VMWARE_VM_TYPE" ]; then
      VAR_HOST=$(echo $VAR_CUR_VM | awk -F$COMMON_CONST_DATA_CFG_SEPARATOR '{print $4}') || exitChildError "$VAR_HOST"
      if isHostAvailableEx "$VAR_HOST"; then
        VAR_VM_ID=$(getVMIDByVMNameEx "$VAR_VM_NAME" "$VAR_HOST") || exitChildError "$VAR_VM_ID"
        VAR_VM_IP=$(getIpAddressByVMNameEx "$VAR_VM_NAME" "$VAR_HOST" "$COMMON_CONST_TRUE") || exitChildError "$VAR_VM_IP"
        if isEmpty "$VAR_VM_IP"; then VAR_VM_IP="<unset>"; fi
      else
        VAR_VM_ID="<unavailable>"
        VAR_VM_IP="<unavailable>"
      fi
      if ! isEmpty "$VAR_RESULT"; then
        VAR_RESULT="${VAR_RESULT}\n"
      fi
      VAR_RESULT="${VAR_RESULT}$VAR_SUITE|$VAR_VM_ROLE|$VAR_VM_TYPE|$VAR_VM_NAME|$VAR_HOST|$VAR_VM_ID|$VAR_VM_IP"
    elif [ "$VAR_VM_TYPE" = "$COMMON_CONST_VBOX_VM_TYPE" ]; then
      VAR_VM_ID=$(getVMIDByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_ID"
      VAR_VM_PORT=$(getPortAddressByVMNameVb "$VAR_VM_NAME") || exitChildError "$VAR_VM_PORT"
      if isEmpty "$VAR_VM_PORT"; then VAR_VM_PORT="<unset>"; fi
      if ! isEmpty "$VAR_RESULT"; then
        VAR_RESULT="${VAR_RESULT}\n"
      fi
      VAR_RESULT="${VAR_RESULT}$VAR_SUITE|$VAR_VM_ROLE|$VAR_VM_TYPE|$VAR_VM_NAME|$VAR_VM_ID|$VAR_VM_PORT"
    fi
  done < "$VAR_CONFIG_FILE_PATH"
done

echoInfo "begin list"
echoResult "$VAR_RESULT"
echoInfo "end list"

doneFinalStage
exitOK
