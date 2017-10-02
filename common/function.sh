#!/bin/sh

##using files: consts.sh, var.sh

##private vars
AUTO_YES='n' #non-interactively mode enum {n,y}

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
    PRM_TOOLTIP=$5
    if [ -z "$PRM_TOOLTIP" ]
    then
      PRM_TOOLTIP=$COMMON_CONST_TOOLTIPY
    fi
    echo "Tooltip: $PRM_TOOLTIP"
    exitOK
  fi
}

startPrompt(){
  if [ "$AUTO_YES" != "y" ]
  then
    read -p 'Do you want to continue? [y/N] ' AUTO_YES
    if [ "$AUTO_YES" != "y" ]
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

isCommandExist(){
  [ -x "$(command -v $1)" ]
}
