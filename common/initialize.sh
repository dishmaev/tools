#!/bin/sh

###header

echo 'Description: Initialize general environment variables of the tools'
echo ''

##private consts
readonly CONST_SSH_IDENTITY_FILE_NAME=$HOME/.ssh/id_rsa
readonly CONST_SCRIPT_DIR_NAME=$(dirname "$0")
readonly CONST_DEFAULT_VM_TEMPLATE='dbn'

##private vars
PRM_SSH_KEYID=$(eval 'if [ -r $(dirname "$0")/data/ssh_keyid.pub ]; then echo "$(ssh-keygen -lf $(dirname "$0")/data/ssh_keyid.pub))"; fi')
PRM_SSH_USER_NAME=$(eval 'if [ -r $(dirname "$0")/data/user.txt ]; then cat $(dirname "$0")/data/user.txt; else echo $(whoami); fi')
PRM_SSH_USER_PASS=$(eval 'if [ -r $(dirname "$0")/data/ssh_pwd.txt ]; then cat $(dirname "$0")/data/ssh_pwd.txt; fi')
PRM_SSH_IDENTITY_FILE_NAME=$(eval 'if [ -r $(dirname "$0")/data/ssh_id_file.txt ]; then cat $(dirname "$0")/data/ssh_id_file.txt; fi')
PRM_DEFAULT_VM_TEMPLATE=$(eval 'if [ -r $(dirname "$0")/data/vm_template.cfg ]; then cat $(dirname "$0")/data/ssh_pwd.txt; else echo '$CONST_DEFAULT_VM_TEMPLATE' fi')
VAR_INPUT=''
VAR_COUNT=''
VAR_SSH_AGENT=''
VAR_AUTO_YES=0
VAR_SSH_FILE_NAME=''

###function

#$1 message
checkRetValOK(){
  if [ "$?" != "0" ]; then exitError "$1"; fi
}

exitOK(){
  if [ ! -z "$VAR_SSH_AGENT" ]; then
    ssh-agent -k
  fi
  echo ''
  echo 'Enjoy!'
  exit 0;
}
#$1 message
exitError(){
  if [ ! -z "$1" ]; then
    echo "Error:" $1
  fi
  if [ ! -z "$VAR_SSH_AGENT" ]; then
    ssh-agent -k
  fi
  echo ''
  echo 'Exit with error!'
  exit 1;
}
#$1 command
checkCommand(){
  if [ ! -x "$(command -v $1)" ]; then
    exitError "Must install $1 previously"
    exit 1
  fi
}

checkAutoYes() {
  if [ "$1" = "-y" ]; then
    VAR_AUTO_YES=1
    return 1
  elif [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    echo "Usage: $(basename "$0") [-y] [userName] [userPassword] [defaultVmTemplate]"
    echo "Tooltip: -y batch mode with yes answer"
    exit 0
  fi
}

isAutoYesMode(){
  [ "$VAR_AUTO_YES" = '1' ]
}

###check autoyes

checkAutoYes "$1" || shift

###check commands

if [ -n "$1" ]; then
  PRM_SSH_USER_NAME=$1
fi

checkCommand "ssh-keygen"
checkCommand "ssh-add"

###body

if [ ! -d $(dirname "$0")/data ]; then mkdir $(dirname "$0")/data; fi

if [ -z "$SSH_AGENT_PID" ]; then
  echo 'Start ssh-agent'
  eval "$(ssh-agent -s)"
  VAR_SSH_AGENT=$SSH_AGENT_PID
  ssh-add
  ssh-add -l
fi

if [ -z "$PRM_SSH_KEYID" ]; then
  VAR_SSH_FILE_NAME=${PRM_SSH_IDENTITY_FILE_NAME:-$CONST_SSH_IDENTITY_FILE_NAME}
  if ! isAutoYesMode; then
    read -r -p "SSH private key file? [$VAR_SSH_FILE_NAME] " VAR_INPUT
  else
    VAR_INPUT=''
  fi
  VAR_SSH_FILE_NAME=${VAR_INPUT:-$CONST_SSH_IDENTITY_FILE_NAME}
  if [ ! -r $VAR_SSH_FILE_NAME ]; then
    if ! isAutoYesMode; then
      read -r -p "Start generate SSH pair key? [Y/n] " VAR_INPUT
    else
      VAR_INPUT=''
    fi
    VAR_INPUT=${VAR_INPUT:-'y'}
    if [ "$VAR_INPUT" != "Y" ] && [ "$VAR_INPUT" != "y" ]; then exitError "SSH private key file $VAR_SSH_FILE_NAME not found"; fi
    ssh-keygen -t rsa -N "" -f $VAR_SSH_FILE_NAME
    checkRetValOK "Must generate or install SSH private key"
  fi
  echo "Save changes to $(dirname "$0")/data/ssh_keyid.pub"
  ssh-keygen -y -f $VAR_SSH_FILE_NAME > $(dirname "$0")/data/ssh_keyid.pub
  chmod u=rw,g=,o= $(dirname "$0")/data/ssh_keyid.pub
  ssh-add $VAR_SSH_FILE_NAME
  checkRetValOK "Must be load SSH private key to the ssh-agent, try to load the required SSH private key using the 'ssh-add $VAR_SSH_FILE_NAME' command manually"
  PRM_SSH_KEYID=$(ssh-keygen -lf $(dirname "$0")/data/ssh_keyid.pub)
  echo "$VAR_SSH_FILE_NAME" > $(dirname "$0")/data/ssh_id_file.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/ssh_id_file.txt
fi

PRM_SSH_KEYID=$(echo $PRM_SSH_KEYID | awk '{print $1" "$2}')
VAR_COUNT=$(ssh-add -l | awk '{print $1" "$2}' | grep "$PRM_SSH_KEYID" | wc -l)

if [ "$VAR_COUNT" = "0" ]; then
  exitError "SSH private key with fingerprint '$PRM_SSH_KEYID' not loaded to the ssh-agent, repeat exec 'eval \"\$(ssh-agent -s)\"', and load the required SSH private key using the 'ssh-add' command manually";
fi

if ! isAutoYesMode; then
  read -r -p "User name? [$PRM_SSH_USER_NAME] " VAR_INPUT
else
  VAR_INPUT=''
fi
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_NAME}
if [ "$VAR_INPUT" != "$PRM_SSH_USER_NAME" ]; then
  echo "Save changes to $(dirname "$0")/data/user.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/data/user.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/user.txt
  PRM_SSH_USER_NAME=$VAR_INPUT
else
  echo "User name: $VAR_INPUT"
fi

if ! isAutoYesMode; then
  read -r -p "User '$PRM_SSH_USER_NAME' password? [$PRM_SSH_USER_PASS] " VAR_INPUT
else
  VAR_INPUT=''
fi
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_PASS}
if isAutoYesMode; then
  VAR_INPUT=${VAR_INPUT:-$2}
fi
if [ "$VAR_INPUT" != "$PRM_SSH_USER_PASS" ]; then
  echo "Save changes to $(dirname "$0")/data/ssh_pwd.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/data/ssh_pwd.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/ssh_pwd.txt
else
  echo "User $PRM_SSH_USER_NAME password: $VAR_INPUT"
fi

if ! isAutoYesMode; then
  read -r -p "Default VM template? [$PRM_DEFAULT_VM_TEMPLATE] " VAR_INPUT
else
  VAR_INPUT=''
fi
VAR_INPUT=${VAR_INPUT:-$CONST_DEFAULT_VM_TEMPLATE}
if isAutoYesMode; then
  VAR_INPUT=${VAR_INPUT:-$3}
fi
if [ "$VAR_INPUT" != "$PRM_DEFAULT_VM_TEMPLATE" ]; then
  echo "Save changes to $(dirname "$0")/data/vm_template.cfg"
  echo "$VAR_INPUT" > $(dirname "$0")/data/vm_template.cfg
  chmod u=rw,g=,o= $(dirname "$0")/data/vm_template.cfg
else
  echo "Default VM template: $VAR_INPUT"
fi

echo "TO-DO reset ENV_INTERNAL_VM_TYPE when Docker and Kubernetes will be working on local system, just only Virtual Box" 
echo "TO-DO reset ENV_VM_TYPES_POOL, из списка COMMON_CONST_VM_TYPES_POOL убрать платформу которая будет внутренней ENV_INTERNAL_VM_TYPE"

exitOK
