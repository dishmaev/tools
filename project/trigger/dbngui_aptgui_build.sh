#!/bin/sh

###header

readonly VAR_PARAMETERS='$1 script name without extenstion, $2 suite, $3 build version, $4 output tar.gz file name'

if [ "$#" != "4" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -r ${1}.ok ]; then rm ${1}.ok; fi
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
cd build/common
checkRetVal
./initialize.sh -y
checkRetVal

cd ../framework
checkRetVal

#./deploy_qt_lib_dev.sh -y
#checkRetVal

cd ../ide
checkRetVal

#./deploy_netbeans.sh -y
#checkRetVal

#./deploy_netbeans.sh -y
#checkRetVal

#./deploy_qt_creator.sh -y
#checkRetVal

#./deploy_netbeans.sh -y
#checkRetVal

#./deploy_sublime_text.sh -y
#checkRetVal

cd $HOME

##test

if [ ! -x "$(command -v atom)" ]; then
#  echo "Command atom not found"
#  exit 1
  :
fi

###finish

echo 1 > ${1}.ok
exit 0