#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription "Trigger for $COMMON_CONST_VMTYPE_ORACLELINUX type template VM"

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address
PRM_HOSTNAME='' #host name for vm

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<ipAddressVM> [hostNameVM=$COMMON_CONST_VMTYPE_ORACLELINUX]' "192.168.0.100 $COMMON_CONST_VMTYPE_ORACLELINUX" ""

###check commands

PRM_IPADDRESS=$1
PRM_HOSTNAME=${2:-$COMMON_CONST_VMTYPE_ORACLELINUX}

checkCommandExist 'ipAddressVM' "$PRM_IPADDRESS" ''


###check body dependencies

checkDependencies 'ssh scp'

###check required files

checkRequiredFiles "$COMMON_CONST_SSH_PASS_FILE"

###start prompt

startPrompt

###body

$SSH_CLIENT root@$PRM_IPADDRESS "mkdir -m u=rwx,g=,o= /root/.ssh; cat > \$HOME/.ssh/authorized_keys" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "useradd --create-home $COMMON_CONST_USER; groupadd sudo; usermod -aG sudo $COMMON_CONST_USER; \
hostnamectl set-hostname $PRM_HOSTNAME; mkdir -m u=rwx,g=,o= /home/$COMMON_CONST_USER/.ssh; chown $COMMON_CONST_USER:users /home/$COMMON_CONST_USER/.ssh; \
cp /root/.ssh/authorized_keys /home/$COMMON_CONST_USER/.ssh; chown $COMMON_CONST_USER:$COMMON_CONST_USER /home/$COMMON_CONST_USER/.ssh/authorized_keys; \
chmod u=rw,g=,o= /home/$COMMON_CONST_USER/.ssh/authorized_keys"
if ! isRetValOK; then exitError; fi
$SSH_CLIENT root@$PRM_IPADDRESS "cat > pass1; cp pass1 pass2; cat pass1 >> pass2; cat pass2 | passwd toolsuser; rm pass1 pass2; chmod u+w /etc/sudoers; echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; chmod u-w /etc/sudoers;" < $COMMON_CONST_SSH_PASS_FILE
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
