#!/bin/sh

##using files: consts.sh

#check local directory to save downloads, make if not exist
if [ ! -d "$COMMON_CONST_DOWNLOAD_PATH" ]; then
  mkdir "$COMMON_CONST_DOWNLOAD_PATH";
  #git config --local user.name "'$COMMON_CONST_GIT_USER'"
  #git config --local user.email "'$COMMON_CONST_GIT_EMAIL'"
  #git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
fi;

if [ ! -f $COMMON_CONST_OVFTOOL_PASS_FILE ]; then
  echo 'changeme' > $COMMON_CONST_OVFTOOL_PASS_FILE
fi

if [ ! -f $COMMON_CONST_SSH_PASS_FILE ]; then
  echo 'changeme' > $COMMON_CONST_SSH_PASS_FILE
fi
