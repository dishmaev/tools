#!/bin/sh

##using files: consts.sh, var.sh

##private vars
AUTO_YES=$COMMON_CONST_FALSE #non-interactively mode enum {n,y}
NEED_HELP=$COMMON_CONST_FALSE #show help and exit

checkParmExist() {
  if [ -z "$2" ]
  then
    exitError "$1 missing!"
  fi
}

checkDirectoryForExist() {
  if [ -z "$1" ] || [ ! -d $1 ]
  then
    exitError "$2directory $1 missing or not exist!"
  fi
}

checkDirectoryForNotExist() {
  if [ -n "$1" ] && [ -d $1 ]
  then
    exitError "$2directory $1 already exist!"
  fi
}

checkGpgSecKeyExist() {
  checkDependencies 'gpg grep'
  if [ -z "$1" ] || [ -z  "$(gpg -K | grep $1)" ]
  then
    exitError "gpg secret key $1 not found!"
  fi
}

checkDependencies(){
  for CUR_DEP in $1
  do
    if ! isCommandExist $CUR_DEP
    then
      if isAutoYesMode
      then
        if isLinuxOS
        then
          LINUX_BASED=$(checkAptOrRpmLinux)
          if [ "$LINUX_BASED" = "apt" ]
          then
            sudo apt -y install $CUR_DEP
          elif [ "$LINUX_BASED" = "rpm" ]
          then
            sudo yum -y install $CUR_DEP
          fi
        elif isFreeBSDOS
        then
          echo 'TO-DO FreeBSD'
        fi
        #repeat check for availability dependence
        if ! isCommandExist $CUR_DEP
        then
          exitError "dependence $CUR_DEP not found!"
        fi
      else
        exitError "dependence $CUR_DEP not found!"
      fi
    fi
  done
}

checkRequiredFiles() {
  for CUR_FILE in $1
  do
    if [ ! -f $CUR_FILE ]
    then
      exitError "file $CUR_FILE not found!"
    fi
  done
}

checkAptOrRpmLinux(){
  if [ -f /etc/debian_version ]; then
      echo 'apt'
  elif [ -f /etc/redhat-release ]; then
    echo 'rpm'
  else
      echo 'unknown'
  fi
}

showDescription(){
  echo $1
}

beginStage(){
  echo -n "Stage $1 of $2: $3..."
}

doneStage(){
  echo ' Done'
}

doneFinalStage(){
  doneStage
  echo 'Success!'
  echo ''
}

exitOK(){
  if [ -n "$1" ]
  then
    echo $1
  fi
  exit 0
}

exitError(){
  if [ -n "$1" ]
  then
    echo 'Error:' $1
  else
    echo 'Error: Some problem occured while execute last command, see output for details'
  fi
  exit 1
}

echoHelp(){
  if [ $2 -gt 0 ] && [ $1 -eq 0 ] || [ $1 -gt $2 ] || isTrue $NEED_HELP
  then
    echo "Usage: $COMMON_CONST_SCRIPT_FILENAME [-y] $3"
    echo "Sample: $COMMON_CONST_SCRIPT_FILENAME $4"
    if [ -n "$5" ]
    then
      PRM_TOOLTIP="$COMMON_CONST_TOOLTIP. $5"
    else
      PRM_TOOLTIP=$COMMON_CONST_TOOLTIP
    fi
    echo "Tooltip: $PRM_TOOLTIP"
    exitOK
  fi
}

startPrompt(){
  if ! isAutoYesMode
  then
    VAR_INPUT=''
    DO_FLAG=$COMMON_CONST_TRUE
    while [ "$DO_FLAG" = "$COMMON_CONST_TRUE" ]
    do
      read -r -p 'Do you want to continue? [y/N] ' VAR_INPUT
      if [ -z "$VAR_INPUT" ]
      then
        DO_FLAG=$COMMON_CONST_FALSE
      else
        case $VAR_INPUT in
          [yY])
            AUTO_YES=$COMMON_CONST_TRUE
            DO_FLAG=$COMMON_CONST_FALSE
            ;;
          [nN])
            DO_FLAG=$COMMON_CONST_FALSE
            ;;
          *)
            echo 'Invalid input'
            ;;
        esac
      fi
    done
    if ! isAutoYesMode
    then
      exitOK 'Good bye!'
    fi
  fi
}

checkAutoYes() {
  if [ "$1" = "-y" ]
  then
    AUTO_YES=$COMMON_CONST_TRUE
    return $AUTO_YES
  elif [ "$1" = "--help" ]
  then
    NEED_HELP=$COMMON_CONST_TRUE
  fi
}

isTrue(){
  [ "$1" = "$COMMON_CONST_TRUE" ]
}

isAutoYesMode(){
  isTrue $AUTO_YES
}

isCommandExist(){
  [ -x "$(command -v $1)" ]
}

isLinuxOS(){
  [ "$(uname)" = "Linux" ]
}

isFreeBSDOS(){
  [ "$(uname)" = "FreeBSD" ]
}
