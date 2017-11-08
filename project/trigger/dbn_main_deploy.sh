#!/bin/sh

VAR_PARAMETERS='$1 script name without extenstion, $2 suite, $3 build file name'

if [ "$#" != "3" ]; then echo "Call syntax: $(basename "$0") $VAR_PARAMETERS"; exit 1; fi
if [ -f ${1}.result ]; then rm ${1}.result; fi
exec 1>${1}.log
exec 2>${1}.err

###body

echo "Current deploy suite: $2"

uname -a

###finish

echo 1 > ${1}.result
exit 0

###function
checkRetVal(){
  if [ "$?" != "0" ]; then exit 1; fi
}
