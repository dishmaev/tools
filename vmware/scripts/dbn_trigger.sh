#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription 'Trigger for dbn type template VM'

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<ipAddressVMPtn>' "192.168.0.100" ""

###check commands

PRM_IPADDRESS=$1
checkCommandExist 'ipAddressVMPtn' "$PRM_IPADDRESS" ''


###check body dependencies

checkDependencies 'ssh scp'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

ssh -o StrictHostKeyChecking=no root@$PRM_IPADDRESS "cat > \$HOME/.ssh/authorized_keys" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
ssh root@$PRM_IPADDRESS "uname -a"
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
