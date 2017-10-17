#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription 'Trigger for fbd type template VM'

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '<ipAddressVMPtn>' "192.168.0.100" "Before execute trigger, must be installed: \
open-vm-tools-nox11. Also must enabled sshd service, by set sshd_enable='YES' in /etc/rc.conf. \
And permit root login through ssh, by set PermitRootLogin yes in /etc/ssh/sshd_config."

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

cat ./../$COMMON_CONST_SSH_PASS_FILE
exitOK

ssh -o StrictHostKeyChecking=no root@$PRM_IPADDRESS "cat > \$HOME/.ssh/authorized_keys" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
ssh root@$PRM_IPADDRESS "export ASSUME_ALWAYS_YES=yes; pkg install sudo; export ASSUME_ALWAYS_YES=; pw useradd $COMMON_CONST_USER, pw groupadd sudo; pw groupmod sudo -m $COMMON_CONST_USER"
if ! isRetValOK; then exitError; fi
ssh root@$PRM_IPADDRESS "cat | pw mod user $COMMON_CONST_USER -h 0" < $COMMON_CONST_SCRIPT_DIRNAME


doneFinalStage
exitOK
