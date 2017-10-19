#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription "Trigger for $COMMON_CONST_VMTYPE_DEBIAN type template VM"

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address
PRM_HOSTNAME='' #host name for vm

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<ipAddressVM> [hostNameVM=$COMMON_CONST_VMTYPE_DEBIAN]' "192.168.0.100 $COMMON_CONST_VMTYPE_DEBIAN" ""

###check commands

PRM_IPADDRESS=$1
PRM_HOSTNAME=${2:-$COMMON_CONST_VMTYPE_DEBIAN}

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
