#!/bin/sh

if [ ! -x "$(command -v git)" ]; then
  echo 'Error: Must install git previously'
fi

echo 'Initialize general environment variables of the tools'

PRM_SSH_USER_NAME=$(eval 'if [ -r $(dirname "$0")/username.txt ]; then cat $(dirname "$0")/username.txt; else echo $(whoami); fi')
PRM_SSH_USER_PASS=$(eval 'if [ -r $(dirname "$0")/sshpwd.txt ]; then cat $(dirname "$0")/sshpwd.txt; fi')
PRM_OVFTOOL_USER_PASS=$(eval 'if [ -r $(dirname "$0")/ovftoolpwd.txt ]; then cat $(dirname "$0")/ovftoolpwd.txt; fi')
PRM_GIT_USER_NAME=$(git config user.name)
PRM_GIT_USER_EMAIL=$(git config user.email)
VAR_INPUT=''

read -r -p "User name? [$PRM_SSH_USER_NAME] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_NAME}
if [ "$VAR_INPUT" != "$PRM_SSH_USER_NAME" ]; then
  echo "Save changes to $(dirname "$0")/username.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/username.txt
  chmod u=rw,g=,o= $(dirname "$0")/username.txt
  PRM_SSH_USER_NAME=$VAR_INPUT
fi

read -r -p "User name '$PRM_SSH_USER_NAME' password? [$PRM_SSH_USER_PASS] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_SSH_USER_PASS}
if [ "$VAR_INPUT" != "$PRM_SSH_USER_PASS" ]; then
  echo "Save changes to $(dirname "$0")/sshpwd.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/sshpwd.txt
  chmod u=rw,g=,o= $(dirname "$0")/sshpwd.txt
fi

read -r -p "User name '$PRM_SSH_USER_NAME' OVFTool password? [$PRM_OVFTOOL_USER_PASS] " VAR_INPUT
VAR_INPUT=${VAR_INPUT:-$PRM_OVFTOOL_USER_PASS}
if [ "$VAR_INPUT" != "$PRM_OVFTOOL_USER_PASS" ]; then
  echo "Save changes to $(dirname "$0")/ovftoolpwd.txt"
  echo "$VAR_INPUT" > $(dirname "$0")/ovftoolpwd.txt
  chmod u=rw,g=,o= $(dirname "$0")/ovftoolpwd.txt
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

echo 'Check available you secret ssh key on current system. It must be shown below:'
ssh-add -l

echo 'Enjoy!'
