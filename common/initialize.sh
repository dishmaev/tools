#!/bin/sh

###header

echo 'Initialize general environment variables of the tools'

###function

#$1 command
checkCommand(){
  if [ ! -x "$(command -v $1)" ]; then
    echo "Error: Must install $1 previously"
    exit 1
  fi
}

##private consts
CONST_SSH_FILE_NAME=$HOME/.ssh/id_rsa

##private vars
PRM_SSH_KEYID=$(eval 'if [ -r $(dirname "$0")/data/ssh_keyid.pub ]; then echo "$(ssh-keygen -lf $(dirname "$0")/data/ssh_keyid.pub))"; fi')
PRM_SSH_USER_NAME=$(eval 'if [ -r $(dirname "$0")/data/user.txt ]; then cat $(dirname "$0")/data/user.txt; else echo $(whoami); fi')
PRM_SSH_USER_PASS=$(eval 'if [ -r $(dirname "$0")/data/ssh_pwd.txt ]; then cat $(dirname "$0")/data/ssh_pwd.txt; fi')
PRM_OVFTOOL_USER_PASS=$(eval 'if [ -r $(dirname "$0")/data/ovftool_pwd.txt ]; then cat $(dirname "$0")/data/ovftool_pwd.txt; fi')
PRM_GIT_USER_NAME=$(git config user.name)
PRM_GIT_USER_EMAIL=$(git config user.email)
VAR_INPUT=''
VAR_COUNT=''

###check commands

checkCommand "git"
checkCommand "ssh-keygen"
checkCommand "ssh-add"

###body

if [ "$PRM_SSH_KEYID" = "" ]; then
  if [ ! -r $CONST_SSH_FILE_NAME ]; then
    read -r -p "Start generate SSH pair key? [Y/n] " VAR_INPUT
    if [ $VAR_INPUT != "Y" ] && [ $VAR_INPUT != "y" ]; then echo "Error: SSH private key file $CONST_SSH_FILE_NAME not found"; exit 1; fi
    ssh-keygen
    if [ "$?" != "0" ]; then echo "Error: Must generate or install SSH private key"; exit 1; fi
  fi
  read -r -p "SSH private key file? [$CONST_SSH_FILE_NAME] " VAR_INPUT
  VAR_INPUT=${VAR_INPUT:-$CONST_SSH_FILE_NAME}
  if [ ! -r $VAR_INPUT ]; then echo "Error: SSH private key file $VAR_INPUT not found"; exit 1; fi
  echo "Save changes to $(dirname "$0")/data/ssh_keyid.pub"
  ssh-keygen -y -f $VAR_INPUT > $(dirname "$0")/data/ssh_keyid.pub
  chmod u=r,g=,o= $(dirname "$0")/data/ssh_keyid.pub
  eval "$(ssh-agent -s)"
  ssh-add $VAR_INPUT
  if [ "$?" != "0" ]; then echo "Error: Must be load SSH private key to the ssh-agent, try to load the required SSH private key using the 'ssh-add $VAR_INPUT' command manually"; exit 1; fi
  PRM_SSH_KEYID=$(ssh-keygen -lf $(dirname "$0")/data/ssh_keyid.pub)
fi

VAR_COUNT=$(ssh-add -l | grep "'$PRM_SSH_KEYID'" | wc -l)

if [ "$VAR_COUNT" = "0" ]; then echo "Error: SSH private key with fingerprint '$PRM_SSH_KEYID' not loaded to the ssh-agent, repeat exec '"eval "\"\$(ssh-agent -s)\"', and load the required SSH private key using the 'ssh-add' command manually"; exit 1; fi

read -r -p "User name? [$PRM_SSH_USER_NAME] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_NAME}
if [ "$VAR_INPUT" != "$PRM_SSH_USER_NAME" ]; then
  echo "Save changes to $(dirname "$0")/data/user.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/data/user.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/user.txt
  PRM_SSH_USER_NAME=$VAR_INPUT
fi

read -r -p "User name '$PRM_SSH_USER_NAME' password? [$PRM_SSH_USER_PASS] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_PASS}
if [ "$VAR_INPUT" != "$PRM_SSH_USER_PASS" ]; then
  echo "Save changes to $(dirname "$0")/data/ssh_pwd.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/data/ssh_pwd.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/ssh_pwd.txt
fi

read -r -p "User name '$PRM_SSH_USER_NAME' OVFTool password? [$PRM_OVFTOOL_USER_PASS] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_OVFTOOL_USER_PASS}
if [ "$VAR_INPUT" != "$PRM_OVFTOOL_USER_PASS" ]; then
  echo "Save changes to $(dirname "$0")/data/ovftool_pwd.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/data/ovftool_pwd.txt
  chmod u=rw,g=,o= $(dirname "$0")/data/ovftool_pwd.txt
fi

read -r -p "Git user name? [$PRM_GIT_USER_NAME] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_GIT_USER_NAME}
if [ "$VAR_INPUT" != "$PRM_GIT_USER_NAME" ]; then
  echo "Exec 'git config user.name $VAR_INPUT'"
  git config user.name $VAR_INPUT
fi

read -r -p "Git user email? [$PRM_GIT_USER_EMAIL] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_GIT_USER_EMAIL}
if [ "$VAR_INPUT" != "$PRM_GIT_USER_EMAIL" ]; then
  echo "Exec 'git config user.email $VAR_INPUT'"
  git config user.email $VAR_INPUT
fi

echo 'Enjoy!'
