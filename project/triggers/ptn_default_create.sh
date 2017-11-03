#!/bin/sh

#$1 script name without extenstion

if [ "$#" != "1" ]; then exit 1; fi
if [ -f ${1}.result ]; then rm ${1}.result; fi
exec 1>${1}.log
exec 2>${1}.err

###body

uname -a

###finish

echo 1 > ${1}.result
