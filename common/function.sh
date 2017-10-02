#!/bin/sh

##using files: consts.sh, var.sh

##private vars
AUTO_YES='n' #non-interactively mode enum {n,y}

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
  if [ $1 -eq 0 ] || [ $1 -gt $2 ]
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
    read -p 'Do you want to continue? [y/N] ' AUTO_YES
    if ! isAutoYesMode
    then
      exitOK 'Good bye!'
    fi
  fi
}

checkAutoYes() {
  if [ "$1" = "-y" ]
  then
    AUTO_YES='y'
    return $COMMON_CONST_TRUE
  fi
}

isAutoYesMode(){
  [ "$AUTO_YES" = "y" ]
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
