#!/bin/sh

###header

VAR_PARAMETERS='$1 script name without extenstion, $2 suite'

if [ "$#" != "2" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -f ${1}.ok ]; then rm ${1}.ok; fi
exec 1>${1}.log
exec 2>${1}.err

###function

checkRetVal(){
  if [ "$?" != "0" ]; then exit 1; fi
}

activeSuiteRepository(){
  #deactivate default repository
  sudo sed '1s/^/# /' -i public-apt-dishmaev.list
  #activate required repository
  if [ "$1" = "rel" ]; then
    cat public-apt-dishmaev.list | grep 'apt stable main' | sed 's/# //' | sudo tee public-apt-dishmaev-stable.list
  elif [ "$1" = "tst" ]; then
    cat public-apt-dishmaev.list | grep 'apt testing main' | sed 's/# //' | sudo tee public-apt-dishmaev-testing.list
  elif [ "$1" = "dev" ]; then
    cat public-apt-dishmaev.list | grep 'apt unstable main' | sed 's/# //' | sudo tee public-apt-dishmaev-unstable.list
  else
    return
  fi
}

###body

echo "Current create suite: $2"

uname -a

#active suite repository
activeSuiteRepository "$2"

##test

###finish

echo 1 > ${1}.ok
exit 0
