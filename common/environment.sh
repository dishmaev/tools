#!/bin/sh

##using files: consts.sh

#aliases
readonly SSH_CLIENT="ssh -o StrictHostKeyChecking=no -o User=$COMMON_CONST_SSH_USER_NAME"
readonly SCP_CLIENT="scp -o StrictHostKeyChecking=no -o User=$COMMON_CONST_SSH_USER_NAME"
readonly SSH_COPY_ID="ssh-copy-id -o StrictHostKeyChecking=no -i $HOME/.ssh/${COMMON_CONST_SSH_KEYID}.pub"

#user name, user emailreadonly COMMON_CONST_GIT_USER_NAME='dishmaev' #default git user
readonly GIT_USER_NAME=$(git config user.name) #default git user
readonly GIT_USER_EMAIL=$(git config user.email) #default git email


#check local directory to save downloads, make if not exist
if [ ! -d "$COMMON_CONST_DOWNLOAD_PATH" ]; then
  mkdir "$COMMON_CONST_DOWNLOAD_PATH";
  #git config --local user.name "'$COMMON_CONST_GIT_USER_NAME'"
  #git config --local user.email "'$COMMON_CONST_GIT_USER_EMAIL'"
  #git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
fi;

if [ ! -f $COMMON_CONST_OVFTOOL_USER_PASS ]; then
  echo 'changeme' > $COMMON_CONST_OVFTOOL_USER_PASS
fi

if [ ! -f $COMMON_CONST_SSH_USER_PASS ]; then
  echo 'changeme' > $COMMON_CONST_SSH_USER_PASS
fi
