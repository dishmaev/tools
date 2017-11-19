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

git clone https://github.com/dishmaev/tools.git
checkRetVal
cd tools/common
checkRetVal
./initialize.sh -y 'O@nXmRZ' dishmaev idax@rambler.ru
checkRetVal

cd ../ide
checkRetVal

./deploy_atom.sh -y
checkRetVal

cd $HOME

##test

###finish

echo 1 > ${1}.ok
exit 0
