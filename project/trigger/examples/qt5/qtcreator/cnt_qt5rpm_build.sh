#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 script name without extenstion, $2 suite, $3 build version, $4 output tar.gz file name'

if [ "$#" != "4" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -r ${1}.ok ]; then rm ${1}.ok; fi
exec 1>${1}.log
exec 2>${1}.err

###function

checkRetValOK(){
  if [ "$?" != "0" ]; then exit 1; fi
}

#$1 suite
getConfigName(){
    if [ "$1" = "dev" ] || [ "$1" = "tst" ]; then
      echo 'Debug'
    elif [ "$1" = "rel" ]; then
      echo 'Release'
    else #error
      exit 1
    fi
}

###body

echo "Current build suite: $2"

uname -a

VAR_SUITE=$(getConfigName "$2") || exit 1
mkdir build
checkRetValOK
tar -xvf *.tar.gz -C build/
checkRetValOK
cd build
checkRetValOK

sudo ln -s /usr/bin/qmake-qt5 /usr/bin/qmake
checkRetValOK

mkdir $VAR_SUITE
checkRetValOK
cd $VAR_SUITE
checkRetValOK
if [ "$VAR_SUITE" = "Debug" ]; then
  qmake ../cppqt5.pro -spec linux-g++-64 CONFIG+=debug CONFIG+=qml_debug
  checkRetValOK
elif [ "$VAR_SUITE" = "Release" ]; then
  qmake cppqt5.pro -spec linux-g++-64
  checkRetValOK
fi
make
checkRetValOK
cd ..

bash -x package-rpm.bash $VAR_SUITE 'cppqt5'
checkRetValOK

tar -cvf $HOME/$4 -C ${VAR_SUITE}/package .
checkRetValOK

cd $HOME

##test

if [ ! -f "$4" ]; then echo "Output file $4 not found"; exit 1; fi
for VAR_CUR_PACKAGE in $HOME/build/${VAR_SUITE}/package/*.rpm; do
  if [ ! -r "$VAR_CUR_PACKAGE" ]; then continue; fi
  rpm -qip $VAR_CUR_PACKAGE
  checkRetValOK
done

###finish

echo 1 > ${1}.ok
exit 0