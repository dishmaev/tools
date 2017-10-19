#!/bin/sh

###header
. $(dirname "$0")/../../common/define_trigger.sh #include common defines, like $COMMON_...
showDescription "Trigger for $COMMON_CONST_VMTYPE_FREEBSD type template VM"

##private consts


##private vars
PRM_IPADDRESS='' #ptn vm ip address
PRM_HOSTNAME='' #host name for vm

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 2 '<ipAddressVM> [hostNameVM=$COMMON_CONST_VMTYPE_FREEBSD]' "192.168.0.100 $COMMON_CONST_VMTYPE_FREEBSD" ""

###check commands

PRM_IPADDRESS=$1
PRM_HOSTNAME=${2:-$COMMON_CONST_VMTYPE_FREEBSD}

checkCommandExist 'ipAddressVM' "$PRM_IPADDRESS" ''


###check body dependencies

checkDependencies 'ssh scp'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

ssh -o StrictHostKeyChecking=no root@$PRM_IPADDRESS "mkdir -m u=rwx,g=,o= /root/.ssh; cat > /root/.ssh/authorized_keys" < $HOME/.ssh/$COMMON_CONST_SSHKEYID.pub
if ! isRetValOK; then exitError; fi
ssh root@$PRM_IPADDRESS "echo 'hostname \"$PRM_HOSTNAME\"' >> /etc/rc.conf; setenv ASSUME_ALWAYS_YES yes; pkg install sudo; setenv ASSUME_ALWAYS_YES; \
pw useradd -m -d /home/$COMMON_CONST_USER -n $COMMON_CONST_USER; pw groupadd sudo; pw groupmod sudo -m $COMMON_CONST_USER; \
mkdir /home/$COMMON_CONST_USER/.ssh; chown $COMMON_CONST_USER:$COMMON_CONST_USER /home/$COMMON_CONST_USER/.ssh; \
cp /root/.ssh/authorized_keys /home/$COMMON_CONST_USER/.ssh; chown $COMMON_CONST_USER /home/$COMMON_CONST_USER/.ssh/authorized_keys; \
chmod u=rw,g=,o= /home/$COMMON_CONST_USER/.ssh/authorized_keys"
if ! isRetValOK; then exitError; fi
ssh root@$PRM_IPADDRESS "cat | pw mod user $COMMON_CONST_USER -h 0; chmod u+w /usr/local/etc/sudoers; echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /usr/local/etc/sudoers; chmod u-w /usr/local/etc/sudoers" < $COMMON_CONST_SSH_PASS_FILE
if ! isRetValOK; then exitError; fi

doneFinalStage
exitOK
