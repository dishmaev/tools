#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 script name without extenstion, $2 suite, $3 make output, $4 build tar.gz file name'

if [ -r ${1}.ok ]; then rm ${1}.ok; fi
exec 1>${1}.log
exec 2>${1}.err
exec 3>${1}.tst
if [ "$#" != "3" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi

###function

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

checkDpkgUnlock(){
  local CONST_LOCK_FILE='/var/lib/dpkg/lock'
  local VAR_COUNT=10
  local VAR_TRY=3
  echo "Check /var/lib/dpkg/lock"
  while sudo fuser $CONST_LOCK_FILE >/dev/null 2>&1; do
    echo -n '.'
    sleep 3
    VAR_COUNT=$((VAR_COUNT-1))
    if [ $VAR_COUNT -eq 0 ]; then
      VAR_TRY=$((VAR_TRY-1))
      if [ $VAR_TRY -eq 0 ]; then  #still not powered on, force kill vm
        echo "failed wait while unlock $CONST_LOCK_FILE. Check another long process using it"
        exit 1
      else
        echo ''
        echo "Still locked $CONST_LOCK_FILE, left $VAR_TRY attempts"
      fi;
      VAR_COUNT=3
    fi
  done
  echo ''
  return 0
}

###body

echo "Current deploy suite: $2"

uname -a

checkDpkgUnlock
if [ "$2" = "rel" ]; then
  #install packages from personal repository
#  sudo apt -y update
#  checkRetValOK
  sudo apt -y install $3
  checkRetValOK
else # tst,dev
  mkdir deploy
  checkRetValOK
  tar -xvf $4 -C deploy/
  checkRetValOK
  cd deploy
  checkRetValOK
  #manually install packages
  for VAR_CUR_PACKAGE in ./*.deb; do
    if [ ! -r "$VAR_CUR_PACKAGE" ]; then continue; fi
    sudo apt -y install $VAR_CUR_PACKAGE
#    checkRetValOK
  done
  #check all dependences
  sudo apt -y install -f
  checkRetValOK

  cd $HOME
fi

##test

$3 --version >&3
checkRetValOK

###finish

echo 1 > ${1}.ok
exit 0
