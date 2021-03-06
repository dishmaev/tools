#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 script name without extenstion, $2 suite'

if [ -r ${1}.ok ]; then rm ${1}.ok; fi
exec 1>${1}.log
exec 2>${1}.err
exec 3>${1}.tst
if [ "$#" != "2" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi

###function

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

#$1 suite
activeSuiteRepository(){
  local VAR_REPO_FILE=/etc/yum.repos.d/public-yum-dishmaev.repo
  #deactivate default repository
  sudo sed 's/enabled=1/enabled=0/' -i $VAR_REPO_FILE
  checkRetValOK
  #sudo yum-config-manager --disable dish_release_rpms
  #activate required repository
  if [ "$1" = "rel" ]; then
    sed -n '/enabled=0/=' $VAR_REPO_FILE | sed 's:.*:&s/enabled=0/enabled=1/:' | sed -n 1p | sed -f - $VAR_REPO_FILE | sudo tee $VAR_REPO_FILE
    checkRetValOK
    #sudo yum-config-manager --enable dish_release_rpms
  elif [ "$1" = "tst" ]; then
    sed -n '/enabled=0/=' $VAR_REPO_FILE | sed 's:.*:&s/enabled=0/enabled=1/:' | sed -n 2p | sed -f - $VAR_REPO_FILE | sudo tee $VAR_REPO_FILE
    checkRetValOK
    #sudo yum-config-manager --enable dish_test_rpms
  elif [ "$1" = "dev" ]; then
    sed -n '/enabled=0/=' $VAR_REPO_FILE | sed 's:.*:&s/enabled=0/enabled=1/:' | sed -n 3p | sed -f - $VAR_REPO_FILE | sudo tee $VAR_REPO_FILE
    checkRetValOK
    #sudo yum-config-manager --enable dish_develop_rpms
  else #run suite
    return
  fi
}

###body

echo "Current create suite: $2"

uname -a

#install packages
if [ "$2" = "run" ]; then
  sudo yum -y install rpm-build
  checkRetValOK
  sudo yum -y install golang
  checkRetValOK
fi

#active suite repository
activeSuiteRepository "$2"

##test

if [ "$2" = "run" ]; then
  go version >&3
  checkRetValOK
fi

###finish

echo 1 > ${1}.ok
exit 0
