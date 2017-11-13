#!/bin/sh

###header

VAR_PARAMETERS='$1 script name without extenstion, $2 suite, $3 build version, $4 output package file name'

if [ "$#" != "4" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -f ${1}.ok ]; then rm ${1}.ok; fi
exec 1>${1}.log
exec 2>${1}.err

###function

checkRetVal(){
  if [ "$?" != "0" ]; then exit 1; fi
}

###body

echo "Current build suite: $2"

uname -a

mkdir build
checkRetVal
tar -xvf *.tar.gz -C build/
checkRetVal
cd build
checkRetVal
make -f Makefile CONF=${VAR_SUITE}_RPM clean
checkRetVal
make -f Makefile CONF=${VAR_SUITE}_RPM
checkRetVal
bash -x nbproject/Package-Debug_RPM.bash
checkRetVal
cp dist/${VAR_SUITE}_RPM/GNU-Linux/package/*.deb $HOME/
checkRetVal

cd $HOME

##test

if [ ! -f "$4" ]; then echo "Output file $4 not found"; exit 1; fi
rpm -qip $4

###finish

echo 1 > ${1}.ok
exit 0